#!/usr/bin/env bash
# PreToolUse guard for mcp__claude-code-remote__add_repo (PandiO/knk-workspace#331).
#
# Lets a cloud session attach only the Knights and Kings repositories below and denies every
# other add_repo call, including calls whose input it cannot read (fail closed). Registered in
# .claude/settings.json under hooks.PreToolUse with the matcher mcp__claude-code-remote__add_repo.
# Guide: docs/guides/developer/agent-tooling.md § 4.
#
# Contract (https://code.claude.com/docs/en/hooks, PreToolUse): the hook input arrives as JSON on
# stdin with tool_name and tool_input ({"owner": ..., "repo": ..., "access": ...}). Allowed: exit 0
# with no output, so the normal permission flow (the allow rule) decides. Denied: exit 2 with the
# reason on stderr, which blocks the call even when an allow rule would permit it and shows the
# reason to Claude. Any other exit code would let the call through, so this script never uses
# `set -e`/`set -u` and only exits 0 on the one allowed path.

# ---- Allowed repositories: change only this block (compared case-insensitively) --------------
ALLOWED_OWNER="PandiO"
ALLOWED_REPOS="knk-workspace knk-web-api knk-web-app knk-plugin knk-v1-archive knk-v2-archive knk-dev-db-seed"
# -----------------------------------------------------------------------------------------------

deny() {
  echo "add_repo guard: $1 Allowed: ${ALLOWED_OWNER}/{$(echo "$ALLOWED_REPOS" | tr ' ' ',')}." \
    "Only the developer changes this list (.claude/hooks/add-repo-guard.sh); ask them to attach" \
    "the repository or to add it there." >&2
  exit 2
}

lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

input=$(cat 2>/dev/null)
[ -n "$input" ] || deny "empty hook input, so the call was denied."

owner=""
repo=""
parsed=""

# 1. Python 3, if present and working (a Windows Store stub prints something else and is ignored).
if command -v python3 >/dev/null 2>&1; then
  py_out=$(printf '%s' "$input" | python3 -I -c '
import json, re, sys
def no_duplicates(pairs):
    keys = [k for k, _ in pairs]
    if len(keys) != len(set(keys)):
        raise ValueError("duplicate key")
    return dict(pairs)
try:
    data = json.loads(sys.stdin.read(), object_pairs_hook=no_duplicates)
except Exception as exc:
    print("ERR\tinput is not valid JSON (%s)." % (str(exc)[:80] or type(exc).__name__)); sys.exit(0)
ti = data.get("tool_input") if isinstance(data, dict) else None
if not isinstance(ti, dict):
    print("ERR\tinput has no tool_input object."); sys.exit(0)
owner, repo = ti.get("owner"), ti.get("repo")
if not isinstance(owner, str) or not isinstance(repo, str):
    print("ERR\ttool_input.owner or tool_input.repo is missing or not a string."); sys.exit(0)
if not re.fullmatch(r"[A-Za-z0-9-]{1,39}", owner) or not re.fullmatch(r"[A-Za-z0-9._-]{1,100}", repo):
    print("ERR\towner or repo has characters a GitHub name cannot have."); sys.exit(0)
print("OK\t%s\t%s" % (owner, repo))
' 2>/dev/null)
  TAB=$'\t'
  case "$py_out" in
    "OK${TAB}"*)
      owner=$(printf '%s' "$py_out" | cut -f2)
      repo=$(printf '%s' "$py_out" | cut -f3)
      parsed="python3"
      ;;
    "ERR${TAB}"*)
      deny "could not read the call: ${py_out#ERR${TAB}} The call was denied."
      ;;
  esac
fi

# 2. Fallback without Python: a strict grep/sed parse of the flat tool_input object.
if [ -z "$parsed" ]; then
  flat=$(printf '%s' "$input" | tr '\r\n\t' '   ')
  case "$flat" in
    *'"tool_input"'*) ;;
    *) deny "input has no tool_input object, so the call was denied." ;;
  esac
  rest=${flat#*'"tool_input"'}
  obj=${rest%%\}*}
  get_field() {
    local matches
    matches=$(printf '%s' "$obj" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"\\\\]*\"")
    [ "$(printf '%s\n' "$matches" | grep -c .)" = "1" ] || return 1
    printf '%s' "$matches" | sed 's/.*:[[:space:]]*"\(.*\)"$/\1/'
  }
  owner=$(get_field owner) || deny "could not read tool_input.owner, so the call was denied."
  repo=$(get_field repo) || deny "could not read tool_input.repo, so the call was denied."
  printf '%s' "$owner" | grep -Eq '^[A-Za-z0-9-]{1,39}$' \
    || deny "owner has characters a GitHub name cannot have, so the call was denied."
  printf '%s' "$repo" | grep -Eq '^[A-Za-z0-9._-]{1,100}$' \
    || deny "repo has characters a GitHub name cannot have, so the call was denied."
  parsed="sed"
fi

[ -n "$owner" ] && [ -n "$repo" ] || deny "could not read owner and repo, so the call was denied."

if [ "$(lower "$owner")" != "$(lower "$ALLOWED_OWNER")" ]; then
  deny "${owner}/${repo} is not allowed: the owner must be ${ALLOWED_OWNER}."
fi

repo_lc=$(lower "$repo")
for allowed in $ALLOWED_REPOS; do
  if [ "$repo_lc" = "$(lower "$allowed")" ]; then
    exit 0
  fi
done

deny "${owner}/${repo} is not on the allowed list."
