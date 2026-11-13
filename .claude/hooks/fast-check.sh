#!/usr/bin/env bash
# Stop hook: fast compile checks for the component repos that have changes.
# Guide: docs/guides/developer/agent-tooling.md (what it does, settings, how to turn it off).
#
# 1. Finds knk-web-app, knk-web-api and knk-plugin under Repository/ in this workspace and next to it.
# 2. A repo is checked only when it has source changes against its base (origin/next if it exists, else the
#    default branch through origin/HEAD, origin/main or origin/master), committed or not, and the same state
#    has not already passed or been skipped.
# 3. Checks (never a task that deploys): web app `npx tsc --noEmit`, API `dotnet build --no-restore -v q`,
#    plugin `./gradlew compileJava compileTestJava -q`. A repo whose toolchain or dependencies are missing is
#    skipped with a note.
# 4. Errors block the stop (exit 2, errors on stderr). Timeouts and skips are reported, not blocking.
#    With stop_hook_active true the hook returns at once, so it cannot loop.
#
# Environment: KNK_FAST_CHECK=off turns it off; KNK_FAST_CHECK_TIMEOUT (seconds per check, default 300);
# KNK_FAST_CHECK_BUDGET (seconds for all checks, default 540; keep it below the hook timeout in settings.json).

set -u

case "${KNK_FAST_CHECK:-on}" in off|0|false|no) exit 0 ;; esac

input=$(cat 2>/dev/null || true)
if printf '%s' "$input" | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

per_check=${KNK_FAST_CHECK_TIMEOUT:-300}
budget=${KNK_FAST_CHECK_BUDGET:-540}
max_lines=60

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ws=$(cd "$script_dir/../.." && pwd)
parent=$(cd "$ws/.." && pwd)

timeout_cmd=""
if command -v timeout >/dev/null 2>&1; then timeout_cmd=timeout
elif command -v gtimeout >/dev/null 2>&1; then timeout_cmd=gtimeout
fi

failures=""
notes=""
note() { notes="${notes:+$notes; }$1"; }

base_ref() {
  local r
  for r in origin/next origin/HEAD origin/main origin/master; do
    if git -C "$1" rev-parse -q --verify "$r^{commit}" >/dev/null 2>&1; then echo "$r"; return; fi
  done
}

state_file() {
  local p
  p=$(git -C "$1" rev-parse --git-path knk-fast-check 2>/dev/null) || return 1
  case "$p" in /*|[A-Za-z]:*) echo "$p" ;; *) echo "$1/$p" ;; esac
}

# Current state of the repo: HEAD, uncommitted diff and untracked files, plus the check command.
fingerprint() {
  {
    echo "$2"
    git -C "$1" rev-parse HEAD
    git -C "$1" diff HEAD --binary
    (cd "$1" && git ls-files -o --exclude-standard | git hash-object --stdin-paths)
  } 2>/dev/null | git hash-object --stdin
}

# Keep the lines that matter: errors with a little context, without JVM/proxy chatter or repo paths.
error_lines() {
  local out="$1" dir="$2" picked
  picked=$(printf '%s\n' "$out" | grep -v '^Picked up ' | grep -E -i -A2 '(^|[^a-z])error([^a-z]|$)|what went wrong' \
    | grep -E -v '^--$|: warning |Warning\(s\)|Time Elapsed|^\* Try:|^> (Run with|Get more help|Check your code)' \
    | awk '!seen[$0]++')
  [ -n "$picked" ] || picked=$(printf '%s\n' "$out" | grep -v '^Picked up ' | tail -n 30)
  printf '%s\n' "$picked" | sed "s|$dir/||g" | head -n "$max_lines"
}

check_repo() {
  local name="$1" dir="$2" label="$3" pattern="$4" skip_pattern="$5"
  shift 5
  local base mb changed fp sf prev elapsed left out rc start

  base=$(base_ref "$dir")
  mb=""
  [ -n "$base" ] && mb=$(git -C "$dir" merge-base HEAD "$base" 2>/dev/null)
  [ -n "$mb" ] || mb=HEAD
  changed=$({ git -C "$dir" diff --name-only "$mb" 2>/dev/null; git -C "$dir" ls-files -o --exclude-standard 2>/dev/null; } \
    | grep -E "$pattern" | head -n 1)
  [ -n "$changed" ] || return 0

  fp=$(fingerprint "$dir" "$*")
  sf=$(state_file "$dir") || sf=""
  if [ -n "$sf" ] && [ -f "$sf" ]; then
    # Same state already passed, or skipped for the same reason: nothing to do.
    prev=$(cat "$sf" 2>/dev/null)
    [ "$prev" = "$fp" ] && return 0
    [ -n "${missing:-}" ] && [ "$prev" = "$fp skip:$missing" ] && return 0
    [ -z "${missing:-}" ] && [ "$prev" = "$fp skip:toolchain" ] && return 0
  fi

  if [ -n "${missing:-}" ]; then
    note "$name skipped ($missing)"
    [ -n "$sf" ] && echo "$fp skip:$missing" > "$sf"
    return 0
  fi

  elapsed=$((SECONDS - started))
  left=$((budget - elapsed))
  if [ "$left" -lt 20 ]; then
    note "$name not checked (overall limit of ${budget}s reached)"
    return 0
  fi
  [ "$left" -gt "$per_check" ] && left=$per_check

  start=$SECONDS
  if [ -n "$timeout_cmd" ]; then
    out=$(cd "$dir" && "$timeout_cmd" -k 10 "$left" "$@" 2>&1 </dev/null); rc=$?
  else
    out=$(cd "$dir" && "$@" 2>&1 </dev/null); rc=$?
  fi
  local took=$((SECONDS - start))

  if [ "$rc" -eq 0 ]; then
    note "$name $label passed (${took}s)"
    [ -n "$sf" ] && echo "$fp" > "$sf"
  elif [ "$rc" -eq 124 ] || [ "$rc" -eq 137 ]; then
    note "$name $label timed out after ${left}s (not blocking; run it yourself)"
    [ -n "$sf" ] && rm -f "$sf"
  elif [ -n "$skip_pattern" ] && printf '%s\n' "$out" | grep -Eq "$skip_pattern"; then
    note "$name skipped (toolchain or packages missing: $(printf '%s\n' "$out" | grep -E -m1 "$skip_pattern" | cut -c1-160))"
    [ -n "$sf" ] && echo "$fp skip:toolchain" > "$sf"
  else
    failures="${failures}
## $name: \`$*\` failed (exit $rc, base ${base:-none}, ${took}s)
$(error_lines "$out" "$dir")
"
    [ -n "$sf" ] && rm -f "$sf"
  fi
}

# Every existing checkout of a repo, in both layouts, once each.
repo_dirs() {
  local d real seen=""
  for d in "$ws/Repository/$1" "$parent/$1"; do
    [ -e "$d/.git" ] || continue
    real=$(cd "$d" && pwd -P)
    case " $seen " in *" $real "*) continue ;; esac
    seen="$seen $real"
    echo "$d"
  done
}

started=$SECONDS

while IFS= read -r dir; do
  [ -n "$dir" ] || continue
  missing=""
  if ! command -v npx >/dev/null 2>&1; then missing="node/npx not found"
  elif [ ! -f "$dir/node_modules/typescript/bin/tsc" ]; then missing="no node_modules; run npx npm@11 ci"
  fi
  check_repo knk-web-app "$dir" tsc '\.(ts|tsx|js|jsx|mts|cts|json)$' '' npx tsc --noEmit
done < <(repo_dirs knk-web-app)

while IFS= read -r dir; do
  [ -n "$dir" ] || continue
  missing=""
  if ! command -v dotnet >/dev/null 2>&1; then missing="dotnet not found"
  elif [ ! -f "$dir/obj/project.assets.json" ]; then missing="packages not restored; run dotnet restore"
  fi
  check_repo knk-web-api "$dir" build '\.(cs|csproj|props|targets|sln)$' \
    'NETSDK1004|NETSDK1045|compatible \.NET SDK was not found|No \.NET SDKs were found' \
    dotnet build --no-restore -v q -nologo
done < <(repo_dirs knk-web-api)

while IFS= read -r dir; do
  [ -n "$dir" ] || continue
  missing=""
  if [ ! -f "$dir/gradlew" ]; then missing="no gradlew"
  elif [ -z "${JAVA_HOME:-}" ] && ! command -v java >/dev/null 2>&1; then missing="java not found"
  fi
  check_repo knk-plugin "$dir" compile '\.(java|kts|gradle|properties|toml)$' \
    'No matching toolchains? found|Cannot find a Java installation|No locally installed toolchains|Unsupported class file major version' \
    sh ./gradlew compileJava compileTestJava -q
done < <(repo_dirs knk-plugin)

if [ -n "$failures" ]; then
  {
    echo "Fast checks failed in the changed component repos. Fix these errors before you finish, or say why they are expected."
    printf '%s\n' "$failures"
    [ -n "$notes" ] && echo "Other checks: $notes."
    echo "(knk-workspace .claude/hooks/fast-check.sh; KNK_FAST_CHECK=off turns it off.)"
  } >&2
  exit 2
fi

if [ -n "$notes" ]; then
  msg=$(printf 'knk fast check: %s.' "$notes" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr -d '\000-\037')
  printf '{"systemMessage": "%s"}\n' "$msg"
fi
exit 0
