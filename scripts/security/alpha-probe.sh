#!/usr/bin/env bash
# alpha-probe.sh — live security checks for knk-web-api (KNG-64, alpha hardening plan § 9).
#
# Usage:
#   scripts/security/alpha-probe.sh <base-url> [--player <login>:<password>] [--cf-id <id> --cf-secret <secret>]
#
#   <base-url>   the API origin WITHOUT /api, e.g. http://127.0.0.1:5000 or https://app.knightsandkings.net
#   --player     a NON-staff test account (email or Minecraft name). Enables the token, session and 403 checks.
#                Use a throwaway account: the script logs it out everywhere.
#   --cf-id/--cf-secret  a Cloudflare Access service token, when the host is behind Access.
#
# Every check prints PASS or FAIL; the exit code is the number of failures. The checks only use ids that
# don't exist, or the test account's own data, so they never change real data on a HARDENED API. On an
# unpatched API the anonymous create check really creates a Category named 'alpha-probe': delete it after. The rate-limit check runs
# last because it trips the per-IP auth limiter for about a minute.
set -uo pipefail

BASE="${1:?usage: alpha-probe.sh <base-url> [--player login:password] [--cf-id id --cf-secret secret]}"
BASE="${BASE%/}"
shift
PLAYER=""; CF_ID=""; CF_SECRET=""
while [ $# -gt 0 ]; do
  case "$1" in
    --player) PLAYER="$2"; shift 2 ;;
    --cf-id) CF_ID="$2"; shift 2 ;;
    --cf-secret) CF_SECRET="$2"; shift 2 ;;
    *) echo "unknown option $1"; exit 64 ;;
  esac
done

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
FAILS=0
CF=()
[ -n "$CF_ID" ] && CF=(-H "CF-Access-Client-Id: $CF_ID" -H "CF-Access-Client-Secret: $CF_SECRET")

# req <method> <path> [extra curl args...] → sets CODE and BODY
req() {
  local m="$1" p="$2"; shift 2
  : > "$TMP/body"
  CODE=$(curl -sS -o "$TMP/body" -w '%{http_code}' -X "$m" "${CF[@]}" "$@" "$BASE$p" 2>/dev/null) || true
  [ -z "$CODE" ] && CODE=000
  BODY=$(cat "$TMP/body" 2>/dev/null || true)
}
check() { # check <description> <condition-result 0/1> <detail>
  if [ "$2" -eq 0 ]; then echo "PASS  $1"; else echo "FAIL  $1  ($3)"; FAILS=$((FAILS+1)); fi
}
expect_code() { # expect_code <description> <expected codes regex> <method> <path> [curl args]
  local d="$1" want="$2"; shift 2
  req "$@"
  [[ "$CODE" =~ ^($want)$ ]]; check "$d" $? "got $CODE: ${BODY:0:120}"
}
JSON=(-H 'Content-Type: application/json')
# json_str <field> / json_num <field>: the first string or number value of that field in stdin. grep/sed only, so
# the script also runs in Git Bash on Windows, where python3 is often missing or the Store placeholder.
json_str() { grep -o "\"$1\" *: *\"[^\"]*\"" | head -1 | sed 's/^[^:]*: *"//; s/"$//'; }
json_num() { grep -o "\"$1\" *: *[0-9][0-9]*" | head -1 | sed 's/^[^:]*: *//'; }

req GET /api/health
if [ "$CODE" = 000 ]; then echo "FAIL  API unreachable at $BASE"; exit 99; fi
if [[ "$CODE" =~ ^30[1278]$ ]] || grep -qi 'cloudflareaccess' <<<"$BODY"; then
  echo "FAIL  $BASE answers $CODE (a Cloudflare Access login redirect?): pass --cf-id/--cf-secret of a service token"
  echo "      that a Service Auth policy on the Access application accepts"; exit 98
fi
echo "== anonymous"
expect_code "health is public"                               "200"     GET    /api/health
expect_code "user list needs login"                          "401"     GET    /api/Users
expect_code "single user needs login"                        "401"     GET    /api/Users/1
expect_code "permission grants need login"                   "401"     GET    /api/PermissionGrants
expect_code "effective permissions need login"               "401"     GET    /api/Users/1/permissions/effective
expect_code "game settings write needs login"                "401"     PUT    /api/GameSettings "${JSON[@]}" -d '{}'
expect_code "content create needs login"                     "401"     POST   /api/Categories "${JSON[@]}" -d '{"name":"alpha-probe"}'
expect_code "world delete needs login"                       "401"     DELETE /api/Locations/999999999
expect_code "form config delete needs login"                 "401"     DELETE /api/FormConfigurations/999999999
expect_code "web-first user create refused"                  "401|403" POST   /api/Users "${JSON[@]}" -d '{"username":"alpha-probe","email":"probe@example.invalid","password":"Kq7!vR2#pLx9-wT4","passwordConfirmation":"Kq7!vR2#pLx9-wT4"}'
expect_code "test controller removed"                        "401|404" DELETE /api/TestDisplay/cleanup
req GET "/api/Users/check-duplicate?email=probe%40example.invalid"
[[ "$CODE" =~ ^[24] ]] && ! grep -qi 'conflictingUserId' <<<"$BODY"; check "check-duplicate exposes no user id" $? "$CODE ${BODY:0:120}"
req POST /api/Users/validate-link-code/ZZZZZZZZ
[[ "$CODE" =~ ^[24] ]] && ! grep -qi '"email"' <<<"$BODY"; check "validate-link-code exposes no email" $? "$CODE ${BODY:0:120}"
req GET /api/Towns/not-a-number
[[ "$CODE" =~ ^[24] ]] && ! grep -qiE 'exception|stack|at knkwebapi|MySql' <<<"$BODY"; check "errors carry no exception text" $? "$CODE ${BODY:0:160}"

if [ -n "$PLAYER" ]; then
  echo "== player (${PLAYER%%:*})"
  LOGIN="${PLAYER%%:*}"; PASS="${PLAYER#*:}"
  login() {
    req POST /api/Auth/login "${JSON[@]}" -c "$TMP/jar" -D "$TMP/hdr" -d "{\"login\":\"$LOGIN\",\"password\":\"$PASS\",\"rememberMe\":false}"
    AT=$(json_str accessToken <<<"$BODY")
    RT=$(awk '$6=="refreshToken"{print $7}' "$TMP/jar" 2>/dev/null | tail -1)
    # Over plain http curl drops a Secure cookie (as a browser would): read it from the Set-Cookie header instead.
    COOKIE_HDR=$(grep -i '^set-cookie: *refreshToken=' "$TMP/hdr" 2>/dev/null | tail -1 | tr -d '\r')
    [ -z "$RT" ] && RT=$(sed -n 's/^[Ss]et-[Cc]ookie: *refreshToken=\([^;]*\).*/\1/p' <<<"$COOKIE_HDR")
  }
  login
  [ "$CODE" = "200" ] && [ -n "$AT" ]; check "player can log in with login=<name or email>" $? "got $CODE: ${BODY:0:120}"
  if [ -z "$AT" ]; then echo "SKIP  remaining player checks (login failed)"; PLAYER=""; fi
fi
if [ -n "$PLAYER" ]; then
  [ -z "$(json_str refreshToken <<<"$BODY")" ]
  check "refresh token not in the response body" $? "body has refreshToken"
  [ -n "$RT" ] && grep -qi 'httponly' <<<"$COOKIE_HDR"; check "refresh token set as HttpOnly cookie" $? "no HttpOnly refreshToken Set-Cookie (behind a proxy? check Path=/api/Auth)"
  if [[ "$BASE" == https://* ]]; then
    grep -qi 'secure' <<<"$COOKIE_HDR"; check "refresh cookie is Secure" $? "Set-Cookie without Secure"
  fi
  AUTH=(-H "Authorization: Bearer $AT")
  UID_=$(curl -sS "${CF[@]}" "${AUTH[@]}" "$BASE/api/Auth/me" 2>/dev/null | json_num id)
  expect_code "player reads own profile"                     "200"     GET    "/api/Users/$UID_" "${AUTH[@]}"
  expect_code "player can't list users"                      "403"     GET    /api/Users "${AUTH[@]}"
  expect_code "player can't read another user"               "403"     GET    "/api/Users/$((UID_ == 1 ? 2 : 1))" "${AUTH[@]}"
  expect_code "player can't write game settings"             "403"     PUT    /api/GameSettings "${AUTH[@]}" "${JSON[@]}" -d '{}'
  expect_code "player can't create content"                  "403"     POST   /api/Categories "${AUTH[@]}" "${JSON[@]}" -d '{"name":"alpha-probe"}'
  expect_code "player can't grant themselves *"              "403"     POST   "/api/Users/$UID_/grants" "${AUTH[@]}" "${JSON[@]}" -d '{"node":"*","value":true}'
  if [ -n "$RT" ]; then
    expect_code "refresh token is not accepted as bearer"    "401"     GET    /api/Auth/me -H "Authorization: Bearer $RT"
  fi
  expect_code "logout"                                       "200|204" POST   /api/Auth/logout -H "Cookie: refreshToken=$RT"
  if [ -n "$RT" ]; then
    expect_code "refresh after logout is refused"            "401"     POST   /api/Auth/refresh -H "Cookie: refreshToken=$RT"
  fi
  login
  AUTH=(-H "Authorization: Bearer $AT")
  expect_code "logout-all"                                   "200|204" POST   /api/Auth/logout-all "${AUTH[@]}"
  expect_code "access token dead after logout-all"           "401"     GET    /api/Auth/me "${AUTH[@]}"
fi

echo "== rate limiting (trips the auth limiter for ~1 minute)"
GOT429=1
for i in $(seq 1 15); do
  req POST /api/Auth/login "${JSON[@]}" -d "{\"login\":\"alpha-probe-$RANDOM@example.invalid\",\"password\":\"wrong\"}"
  [ "$CODE" = "429" ] && { GOT429=0; break; }
done
check "repeated failed logins are rate-limited (429)" $GOT429 "no 429 after 15 attempts"

echo
[ "$FAILS" -eq 0 ] && echo "ALL CHECKS PASSED" || echo "$FAILS CHECK(S) FAILED"
exit "$FAILS"
