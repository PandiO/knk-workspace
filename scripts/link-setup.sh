#!/usr/bin/env bash
# link-setup.sh: the set-up of a K&K chain link (knk-link skill § 1) in one run.
#
# Per repo it does the attach check, the branch from the base (merge, never rebase, when the branch already exists),
# the push dry run and the baseline tests, then prints one summary. It never pushes, never rebases and never deletes
# anything.
#
# Usage:
#   scripts/link-setup.sh --branch <branch> [options] <repo>...
#
# Options:
#   --branch <name>     The link's feature branch (required).
#   --base <name>       Base branch (default: next). Agent workflow links pass --base main.
#   --root <dir>        Directory that holds the clones (default: the parent of the knk-workspace clone this script
#                       belongs to, also when it runs from a worktree).
#   --worktree <dir>    Work in worktrees at <dir>/<repo> instead of in the clones (a link run as a subagent, whose
#                       clones belong to the coordinator). Without it the branch is checked out in the clone itself.
#   --depth <n>         Fetch depth for shallow clones (default: 50).
#   --skip-tests        Skip the baseline tests.
#   --parallel          Run the repos' baselines at the same time. Faster on a large machine; on 4 cores the web
#                       app's Jest tests time out under the load, so the default is one repo after the other.
#   --log-dir <dir>     Where the step logs go (default: a new directory under ${TMPDIR:-/tmp}).
#   -h, --help          Show this help.
#
# Repos: knk-web-api, knk-web-app, knk-plugin, knk-workspace (docs only: no baseline tests).
#
# Exit code: 0 when every repo is attached, branched and passes the push dry run (red baseline tests are reported,
# they may be known reds); 1 when any of those is a blocker; 2 on a usage error.
set -u

usage() { sed -n '2,/^set -u/p' "$0" | sed -e '/^set -u/d' -e 's/^# \{0,1\}//'; }

BRANCH="" BASE="next" ROOT="" WT="" DEPTH=50 SKIP_TESTS=0 PARALLEL=0 LOG_DIR=""
REPOS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --branch) BRANCH="${2:-}"; shift 2 ;;
    --base) BASE="${2:-}"; shift 2 ;;
    --root) ROOT="${2:-}"; shift 2 ;;
    --worktree) WT="${2:-}"; shift 2 ;;
    --depth) DEPTH="${2:-}"; shift 2 ;;
    --skip-tests) SKIP_TESTS=1; shift ;;
    --parallel) PARALLEL=1; shift ;;
    --log-dir) LOG_DIR="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) REPOS+=("$1"); shift ;;
  esac
done
if [ -z "$BRANCH" ] || [ -z "$BASE" ] || [ ${#REPOS[@]} -eq 0 ]; then
  echo "Need --branch and at least one repo." >&2; usage >&2; exit 2
fi
case "$DEPTH" in ''|*[!0-9]*) echo "--depth needs a number" >&2; exit 2 ;; esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -z "$ROOT" ]; then
  # The parent of the knk-workspace clone; from a worktree, the parent of the clone it belongs to.
  common="$(git -C "$SCRIPT_DIR" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"
  if [ -n "$common" ]; then ROOT="$(dirname "$(dirname "$common")")"; else ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"; fi
fi
[ -n "$LOG_DIR" ] || LOG_DIR="$(mktemp -d "${TMPDIR:-/tmp}/link-setup.XXXXXX")"
mkdir -p "$LOG_DIR"
[ -z "$WT" ] || mkdir -p "$WT"

# Result fields per repo, filled by the steps below.
declare -A R_ATTACH R_BRANCH R_HEAD R_PUSH R_TESTS R_TIME R_DIR R_BLOCK

now() { date +%s; }

# fetch_ref <git dir> <branch>: fetch origin/<branch> into its remote-tracking ref, shallow when the clone is shallow.
fetch_ref() {
  local g="$1" b="$2" depth=()
  [ "$(git -C "$g" rev-parse --is-shallow-repository)" = "true" ] && depth=(--depth "$DEPTH")
  git -C "$g" fetch -q "${depth[@]}" origin "+refs/heads/$b:refs/remotes/origin/$b"
}

# merge_base_in <dir>: merge origin/$BASE into the checked-out branch (never a rebase). Deepens a shallow clone once
# when the merge base is missing.
merge_base_in() {
  local d="$1" log="$2"
  if ! git -C "$d" merge-base HEAD "origin/$BASE" >/dev/null 2>&1 \
     && [ "$(git -C "$d" rev-parse --is-shallow-repository)" = "true" ]; then
    git -C "$d" fetch -q --deepen 500 origin "+refs/heads/$BASE:refs/remotes/origin/$BASE" \
      "+refs/heads/$BRANCH:refs/remotes/origin/$BRANCH" >>"$log" 2>&1 || true
  fi
  if git -C "$d" merge-base --is-ancestor "origin/$BASE" HEAD 2>/dev/null; then
    echo "up to date with $BASE"; return 0
  fi
  if git -C "$d" merge --no-edit "origin/$BASE" >>"$log" 2>&1; then
    echo "merged $BASE (not pushed)"; return 0
  fi
  git -C "$d" merge --abort >>"$log" 2>&1 || true
  echo "MERGE CONFLICT with $BASE"; return 1
}

setup_repo() {
  local repo="$1" log="$LOG_DIR/$repo-setup.log" g="$ROOT/$repo" d st
  : >"$log"

  # 1. Attach check: the clone exists, origin is the PandiO repo, the base is reachable.
  if [ ! -d "$g/.git" ] && [ ! -f "$g/.git" ]; then
    R_ATTACH[$repo]="MISSING ($g)"; R_BLOCK[$repo]=1; return
  fi
  local url; url="$(git -C "$g" remote get-url origin 2>/dev/null)"
  case "$url" in
    *PandiO/"$repo"|*PandiO/"$repo".git) ;;
    *) R_ATTACH[$repo]="WRONG ORIGIN ($url)"; R_BLOCK[$repo]=1; return ;;
  esac
  if ! fetch_ref "$g" "$BASE" >>"$log" 2>&1; then
    R_ATTACH[$repo]="FETCH FAILED ($BASE)"; R_BLOCK[$repo]=1; return
  fi
  R_ATTACH[$repo]="ok"

  # 2. Branch: create it from origin/<base>, or check out the existing one and merge origin/<base> into it.
  local remote_has=0 local_has=0
  if git -C "$g" ls-remote --exit-code --heads origin "$BRANCH" >/dev/null 2>&1; then
    remote_has=1; fetch_ref "$g" "$BRANCH" >>"$log" 2>&1
  fi
  git -C "$g" show-ref --verify -q "refs/heads/$BRANCH" && local_has=1

  if [ -n "$WT" ]; then
    d="$WT/$repo"
    if [ -e "$d" ]; then
      [ "$(git -C "$d" rev-parse --abbrev-ref HEAD 2>/dev/null)" = "$BRANCH" ] \
        || { R_BRANCH[$repo]="$d exists on another branch"; R_BLOCK[$repo]=1; return; }
    elif [ $local_has = 1 ]; then
      git -C "$g" worktree add -q "$d" "$BRANCH" >>"$log" 2>&1
    elif [ $remote_has = 1 ]; then
      git -C "$g" worktree add -q --track -b "$BRANCH" "$d" "origin/$BRANCH" >>"$log" 2>&1
    else
      git -C "$g" worktree add -q --no-track -b "$BRANCH" "$d" "origin/$BASE" >>"$log" 2>&1
    fi
    [ -e "$d" ] || { R_BRANCH[$repo]="WORKTREE FAILED"; R_BLOCK[$repo]=1; return; }
  else
    d="$g"
    if [ -n "$(git -C "$d" status --porcelain --untracked-files=no)" ]; then
      R_BRANCH[$repo]="DIRTY CLONE (commit or stash first)"; R_BLOCK[$repo]=1; return
    fi
    if [ $local_has = 1 ]; then
      git -C "$d" checkout -q "$BRANCH" >>"$log" 2>&1
    elif [ $remote_has = 1 ]; then
      git -C "$d" checkout -q --track -b "$BRANCH" "origin/$BRANCH" >>"$log" 2>&1
    else
      git -C "$d" checkout -q --no-track -b "$BRANCH" "origin/$BASE" >>"$log" 2>&1
    fi
    [ "$(git -C "$d" rev-parse --abbrev-ref HEAD)" = "$BRANCH" ] \
      || { R_BRANCH[$repo]="CHECKOUT FAILED"; R_BLOCK[$repo]=1; return; }
  fi
  R_DIR[$repo]="$d"

  if [ $remote_has = 1 ] || [ $local_has = 1 ]; then
    # An existing branch: pull (fast-forward only) from its remote, then merge the base.
    local pulled=""
    if [ $remote_has = 1 ] && ! git -C "$d" merge -q --ff-only "origin/$BRANCH" >>"$log" 2>&1; then
      pulled=", local differs from origin/$BRANCH (not pulled, check it)"
    fi
    if st="$(merge_base_in "$d" "$log")"; then R_BRANCH[$repo]="existing, $st$pulled"
    else R_BRANCH[$repo]="existing, $st$pulled"; R_BLOCK[$repo]=1; fi
  else
    R_BRANCH[$repo]="new from origin/$BASE"
  fi
  R_HEAD[$repo]="$(git -C "$d" rev-parse --short HEAD)"

  # 3. Push dry run.
  if git -C "$d" push --dry-run origin "$BRANCH" >>"$log" 2>&1; then R_PUSH[$repo]="ok"
  else R_PUSH[$repo]="FAILED"; R_BLOCK[$repo]=1; fi
}

# run_step <log> <label> <command...>: run one baseline command, append "label rc=N Ns" to the repo's step list.
run_step() {
  local log="$1" label="$2"; shift 2
  local s rc; s=$(now)
  { echo "### $label: $*"; } >>"$log"
  "$@" >>"$log" 2>&1; rc=$?
  echo "$label $([ $rc = 0 ] && echo ok || echo "FAILED(rc=$rc)") $(( $(now) - s ))s"
}

# Baseline tests: the knk-link skill § 1.7 table. Prints one line "<steps> | <counts>".
baseline_repo() {
  local repo="$1" d="${R_DIR[$1]}" log="$LOG_DIR/$1-tests.log" steps=() counts=""
  : >"$log"
  case "$repo" in
    knk-web-api)
      steps+=("$(cd "$d" && run_step "$log" build dotnet build -nologo -v q)")
      steps+=("$(cd "$d" && run_step "$log" test dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj -nologo)")
      counts="$(grep -E '(Passed|Failed)! +- Failed: ' "$log" | tail -1 \
        | sed -E 's/.*Failed: +([0-9]+), Passed: +([0-9]+), Skipped: +([0-9]+), Total: +([0-9]+).*/\2 passed, \1 failed, \3 skipped/')"
      [ -n "${KNK_TEST_MYSQL:-}" ] || counts="$counts (MySQL tests skip: KNK_TEST_MYSQL unset)"
      ;;
    knk-web-app)
      steps+=("$(cd "$d" && run_step "$log" npm-ci npx -y npm@11 ci --no-audit --no-fund)")
      steps+=("$(cd "$d" && CI=true run_step "$log" test:ci npm run test:ci)")
      steps+=("$(cd "$d" && run_step "$log" tsc npx tsc --noEmit)")
      steps+=("$(cd "$d" && CI=true run_step "$log" build npm run build)")
      counts="$(grep -E '^Tests: ' "$log" | tail -1 | sed -E 's/^Tests: +//')"
      ;;
    knk-plugin)
      local gopts=() mark="$LOG_DIR/$repo.start"
      touch "$mark"
      [ -d /opt/jdk-25 ] && gopts=(-Porg.gradle.java.installations.paths=/opt/jdk-25)
      # Gradle's own retries with a longer backoff ride out most of Maven Central's 429s.
      gopts+=(-Dorg.gradle.internal.repository.max.retries=8 -Dorg.gradle.internal.repository.initial.backoff=1000)
      steps+=("$(cd "$d" && run_step "$log" build ./gradlew --console=plain "${gopts[@]}" build -x deployToDevServer)")
      # Maven Central answers bursts with 429; one retry once the downloads that did arrive are cached.
      if [[ "${steps[-1]}" == *FAILED* ]] && grep -q -E 'status code 429|Could not download' "$log"; then
        steps+=("$(cd "$d" && run_step "$log" build-retry ./gradlew --console=plain "${gopts[@]}" build -x deployToDevServer)")
      fi
      counts="$(find "$d" -path '*/build/test-results/test/*.xml' -newer "$mark" -print0 2>/dev/null \
        | xargs -0 -r cat | grep -o '<testsuite [^>]*>' \
        | awk '{ for (i = 1; i <= NF; i++) { split($i, kv, "=");
                   gsub(/"/, "", kv[2]); if (kv[1] == "tests") t += kv[2]; if (kv[1] == "failures") f += kv[2];
                   if (kv[1] == "errors") f += kv[2]; if (kv[1] == "skipped") s += kv[2] } }
               END { printf "%d passed, %d failed, %d skipped", t - f - s, f, s }')"
      ;;
    knk-workspace)
      echo "docs only (check the markdown links you add) | -"; return ;;
    *)
      echo "no baseline known for $repo | -"; return ;;
  esac
  echo "${steps[*]} | ${counts:-no counts found, see $log}"
}

T0=$(now)
for repo in "${REPOS[@]}"; do
  s=$(now); R_BLOCK[$repo]=0
  setup_repo "$repo"
  R_TIME[$repo]="setup $(( $(now) - s ))s"
done

# Baseline tests, one repo after the other (or one background job per repo with --parallel); results go to files.
if [ $SKIP_TESTS = 0 ]; then
  for repo in "${REPOS[@]}"; do
    [ -n "${R_DIR[$repo]:-}" ] || continue
    if [ $PARALLEL = 1 ]; then
      ( s=$(now); baseline_repo "$repo" >"$LOG_DIR/$repo.result"; echo "$(( $(now) - s ))" >"$LOG_DIR/$repo.secs" ) &
    else
      s=$(now); baseline_repo "$repo" >"$LOG_DIR/$repo.result"; echo "$(( $(now) - s ))" >"$LOG_DIR/$repo.secs"
    fi
  done
  wait
fi

echo
echo "== link-setup summary: branch $BRANCH from $BASE, $(( $(now) - T0 ))s, logs in $LOG_DIR"
echo
echo "| Repo | Attach | Branch | Head | Push dry run | Baseline steps | Baseline tests | Time |"
echo "|---|---|---|---|---|---|---|---|"
BLOCKED=0
for repo in "${REPOS[@]}"; do
  tests_steps="skipped" tests_counts="-"
  if [ $SKIP_TESTS = 0 ] && [ -f "$LOG_DIR/$repo.result" ]; then
    tests_steps="$(cut -d'|' -f1 "$LOG_DIR/$repo.result" | sed 's/ *$//')"
    tests_counts="$(cut -d'|' -f2- "$LOG_DIR/$repo.result" | sed 's/^ *//')"
    R_TIME[$repo]="${R_TIME[$repo]}, tests $(cat "$LOG_DIR/$repo.secs")s"
  fi
  echo "| $repo | ${R_ATTACH[$repo]:--} | ${R_BRANCH[$repo]:--} | ${R_HEAD[$repo]:--} | ${R_PUSH[$repo]:--} | $tests_steps | $tests_counts | ${R_TIME[$repo]} |"
  [ "${R_BLOCK[$repo]}" = 1 ] && BLOCKED=1
done
echo
for repo in "${REPOS[@]}"; do
  [ -n "${R_DIR[$repo]:-}" ] && echo "$repo: work in ${R_DIR[$repo]}"
done
if [ $BLOCKED = 1 ]; then
  echo "BLOCKER: see the rows above and $LOG_DIR/<repo>-setup.log (knk-link skill § 4)."
  exit 1
fi
echo "Set-up done. Red baseline tests that are also red on $BASE are known reds, not blockers."
