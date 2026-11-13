#!/usr/bin/env bash
# Stop hook: fast compile checks for the component repos that have changes.
# Guide: docs/guides/developer/agent-tooling.md (what it does, settings, how to turn it off).
#
# 1. Which clones: the paths in KNK_FAST_CHECK_REPOS when it is set, and nothing else. Otherwise clones of
#    knk-web-app, knk-web-api and knk-plugin, recognised by their origin URL (.../PandiO/<name>), found under
#    Repository/ in this workspace, next to it, and up to three folders deep under the workspace's parent folder
#    and under $HOME. When a repo has several clones, only the most recently active one is checked (newest of
#    its index, its HEAD log and its changed files); the output names the checked and the ignored paths.
# 2. A repo is checked only when it has source changes against its base (origin/next if it exists, else the
#    default branch through origin/HEAD, origin/main or origin/master), committed or not, and the same state
#    has not already passed. Only passes are remembered; skips and timeouts are tried again at the next stop.
# 3. Checks (never a task that deploys): web app `npx tsc --noEmit`, API `dotnet build --no-restore -v q`,
#    plugin `./gradlew compileJava compileTestJava -q`. For the plugin the hook looks for a JDK of the build's
#    toolchain version (KNK_JDK25_HOME, JAVA_HOME, /usr/lib/jvm, /opt, ~/.gradle/jdks, SDKMAN, ...) and passes
#    it to Gradle with -Porg.gradle.java.installations.paths. A repo whose toolchain or dependencies are missing
#    is skipped with a note that says what is missing and how to fix it.
# 4. Errors block the stop (exit 2, errors on stderr). Timeouts and skips are reported, not blocking.
#    With stop_hook_active true the hook returns at once, so it cannot loop.
#
# Environment: KNK_FAST_CHECK=off turns it off; KNK_FAST_CHECK_REPOS (colon-separated clone paths, or
# semicolon-separated on Windows, to check exactly those); KNK_JDK25_HOME (a JDK 25 folder for the plugin);
# KNK_FAST_CHECK_TIMEOUT (seconds per check, default 300); KNK_FAST_CHECK_BUDGET (seconds for all checks,
# default 540; keep it below the hook timeout in settings.json).

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
skip_hint=""

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
  picked=$(printf '%s\n' "$out" | grep -v -E '^(Picked up |npm notice)' | grep -E -i -A2 '(^|[^a-z])error([^a-z]|$)|what went wrong' \
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
    # Only passes are remembered (the fingerprint includes the command, so also the JDK passed to Gradle).
    # Skips and timeouts are never cached, so a toolchain installed later is used at the next stop.
    prev=$(cat "$sf" 2>/dev/null)
    [ "$prev" = "$fp" ] && return 0
  fi

  if [ -n "${missing:-}" ]; then
    note "$name skipped ($missing)"
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
    local why
    why=$(printf '%s\n' "$out" | grep -E -m1 "$skip_pattern" | sed 's/^[[:space:]>]*//' | cut -c1-120)
    if [ -n "$skip_hint" ]; then
      note "$name skipped ($skip_hint. Gradle said: $why)"
    else
      note "$name skipped (toolchain or packages missing: $why)"
    fi
    [ -n "$sf" ] && rm -f "$sf"
  else
    failures="${failures}
## $name: \`$*\` failed (exit $rc, base ${base:-none}, ${took}s)
$(error_lines "$out" "$dir")
"
    [ -n "$sf" ] && rm -f "$sf"
  fi
}

# ---------------------------------------------------------------------------------------------------------
# Which clones to check.

repo_names="knk-web-app knk-web-api knk-plugin"

# The component repo a clone belongs to, from its origin URL (.../PandiO/<name>[.git], any letter case).
origin_name() {
  local url n
  url=$(git -C "$1" config --get remote.origin.url 2>/dev/null) || return 0
  url=$(printf '%s' "$url" | tr '[:upper:]' '[:lower:]')
  url=${url%/}; url=${url%.git}
  for n in $repo_names; do
    case "$url" in */pandio/"$n"|*:pandio/"$n") echo "$n"; return 0 ;; esac
  done
}

real_dir() { (cd "$1" 2>/dev/null && pwd -P); }

file_mtimes() {
  # mtime in epoch seconds of each existing argument (GNU stat, else BSD stat).
  [ "$#" -gt 0 ] || return 0
  stat -c %Y -- "$@" 2>/dev/null || stat -f %m -- "$@" 2>/dev/null
}

# Last activity of a clone: newest of its index, its HEAD log and its changed files (first 200). Read-only:
# GIT_OPTIONAL_LOCKS=0 keeps git status from refreshing (and so touching) the index of the clones it looks at.
activity() {
  local d="$1" gd rec f files=()
  gd=$(git -C "$d" rev-parse --absolute-git-dir 2>/dev/null) || { echo 0; return; }
  for f in "$gd/index" "$gd/logs/HEAD"; do [ -e "$f" ] && files+=("$f"); done
  while IFS= read -r -d '' rec; do
    f="$d/${rec:3}"
    [ -e "$f" ] && files+=("$f")
    [ "${#files[@]}" -ge 202 ] && break
  done < <(cd "$d" && GIT_OPTIONAL_LOCKS=0 git status --porcelain -z 2>/dev/null)
  { echo 0; file_mtimes ${files[@]+"${files[@]}"}; } | sort -n | tail -n 1
}

# Folders that may hold a .git, up to three levels below each root, without dependency, build and hidden folders.
find_git_dirs() {
  local root
  for root in "$@"; do
    [ -d "$root" ] || continue
    ${timeout_cmd:+$timeout_cmd 3} find "$root" -mindepth 1 -maxdepth 4 \
      \( -name .git -print -prune \) -o \
      \( -type d \( -name '.*' -o -name node_modules -o -name .gradle -o -name bin -o -name obj -o -name build \
         -o -name AppData -o -name Library \) -prune \) 2>/dev/null
  done
}

# Sets selected ("name<TAB>path" lines, one per clone to check) and pick_note (which clones were checked and
# which ignored). Runs in the main shell so its notes reach the output.
selected=""
pick_note=""
select_repos() {
  local list d n real seen="" sep=":" entries=()
  if [ -n "${KNK_FAST_CHECK_REPOS:-}" ]; then
    case "$KNK_FAST_CHECK_REPOS" in *";"*) sep=";" ;; esac
    IFS="$sep" read -r -a entries <<< "$KNK_FAST_CHECK_REPOS"
    for d in ${entries[@]+"${entries[@]}"}; do
      [ -n "$d" ] || continue
      case "$d" in /*|[A-Za-z]:*) ;; *) d="$ws/$d" ;; esac
      if [ ! -e "$d/.git" ]; then note "KNK_FAST_CHECK_REPOS: $d is not a git clone, ignored"; continue; fi
      real=$(real_dir "$d")
      case " $seen " in *" $real "*) continue ;; esac
      seen="$seen $real"
      n=$(origin_name "$d")
      if [ -z "$n" ]; then
        case " $repo_names " in *" $(basename "$real") "*) n=$(basename "$real") ;; esac
      fi
      if [ -z "$n" ]; then note "KNK_FAST_CHECK_REPOS: $d is not a clone of $repo_names, ignored"; continue; fi
      selected="$selected$n	$d
"
      pick_note="${pick_note:+$pick_note, }$d"
    done
    pick_note="only KNK_FAST_CHECK_REPOS is checked: ${pick_note:-none of its paths}"
    return 0
  fi

  list=$(
    for d in "$ws"/Repository/*/ "$parent"/*/; do [ -e "${d%/}/.git" ] && echo "${d%/}"; done
    find_git_dirs "$parent" "${HOME:-}" | sed 's|/\.git$||'
  )
  local cands="" a
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    real=$(real_dir "$d") || continue
    case " $seen " in *" $real "*) continue ;; esac
    seen="$seen $real"
    n=$(origin_name "$real")
    [ -n "$n" ] || continue
    cands="$cands$n	$real
"
  done <<< "$list"

  local best best_t t others
  for n in $repo_names; do
    best="" best_t=-1 others=""
    while IFS='	' read -r a d; do
      [ "$a" = "$n" ] || continue
      t=$(activity "$d")
      if [ "$t" -gt "$best_t" ]; then
        [ -n "$best" ] && others="${others:+$others, }$best"
        best=$d best_t=$t
      else
        others="${others:+$others, }$d"
      fi
    done <<< "$cands"
    [ -n "$best" ] || continue
    selected="$selected$n	$best
"
    [ -n "$others" ] && pick_note="${pick_note:+$pick_note; }$n: checked $best (most recently active), ignored $others"
  done
  return 0
}

# ---------------------------------------------------------------------------------------------------------
# JDK for the plugin's Gradle toolchain.

jdk_major() {
  [ -f "$1/release" ] || return 1
  sed -n 's/^JAVA_VERSION="\([0-9][0-9]*\).*/\1/p' "$1/release" | head -n 1
}

is_jdk() { [ "$(jdk_major "$1")" = "$2" ] && { [ -x "$1/bin/javac" ] || [ -f "$1/bin/javac.exe" ]; }; }

# The first JDK of major version $1 in the usual places (KNK_JDK25_HOME first); prints its folder.
find_jdk() {
  local v="$1" d sub gh="${GRADLE_USER_HOME:-${HOME:-}/.gradle}" h="${HOME:-/nonexistent}"
  for d in "${KNK_JDK25_HOME:-}" "${JAVA_HOME:-}" /usr/lib/jvm/*"$v"* /usr/lib64/jvm/*"$v"* /opt/jdk-"$v"* \
      /opt/*jdk*"$v"* /opt/java/*"$v"* "$gh"/jdks/*"$v"* "$h"/.sdkman/candidates/java/"$v"* "$h"/.jdks/*"$v"* \
      /Library/Java/JavaVirtualMachines/*"$v"*/Contents/Home "/c/Program Files/Java/"*"$v"* \
      "/c/Program Files/Eclipse Adoptium/"*"$v"* "/c/Program Files/Microsoft/"*"$v"*; do
    [ -n "$d" ] && [ -d "$d" ] || continue
    for sub in "$d" "$d"/*/ "$d/Contents/Home"; do
      sub=${sub%/}
      [ -d "$sub" ] && is_jdk "$sub" "$v" && { real_dir "$sub"; return 0; }
    done
  done
  return 1
}

# Sets gradle_jdk_args (extra Gradle arguments) and skip_hint for the plugin clone in $1.
plugin_toolchain() {
  local dir="$1" v jdk gh="${GRADLE_USER_HOME:-${HOME:-}/.gradle}" set_in="" fix
  gradle_jdk_args=()
  v=$(cat "$dir"/build.gradle.kts "$dir"/*/build.gradle.kts "$dir"/build.gradle 2>/dev/null \
    | grep -oE 'JavaLanguageVersion\.of\([0-9]+\)' | grep -oE '[0-9]+' | sort -n | tail -n 1)
  [ -n "$v" ] || { skip_hint=""; return 0; }
  case "$(uname -s 2>/dev/null)" in
    Linux) fix="install one (Debian/Ubuntu: apt-get install -y openjdk-$v-jdk-headless) or set KNK_JDK25_HOME to its folder" ;;
    *) fix="install one (for example Temurin $v from adoptium.net) or set KNK_JDK25_HOME to its folder" ;;
  esac
  for f in "$gh/gradle.properties" "$dir/gradle.properties"; do
    grep -Eqs '^[[:space:]]*org\.gradle\.java\.installations\.paths[[:space:]]*[=:]' "$f" && set_in="$f"
  done
  if [ -n "$set_in" ]; then
    skip_hint="Gradle needs a Java $v toolchain; org.gradle.java.installations.paths is set in $set_in, so the hook leaves it alone: point it at a JDK $v or remove it"
    return 0
  fi
  if jdk=$(find_jdk "$v"); then
    gradle_jdk_args=("-Porg.gradle.java.installations.paths=$jdk")
    skip_hint="Gradle did not accept the JDK $v the hook found at $jdk; set KNK_JDK25_HOME to another JDK $v folder"
  else
    skip_hint="Gradle needs a Java $v toolchain and the hook found none in KNK_JDK25_HOME, JAVA_HOME, /usr/lib/jvm, /opt, ~/.gradle/jdks, ~/.sdkman or ~/.jdks; $fix${KNK_JDK25_HOME:+; KNK_JDK25_HOME=$KNK_JDK25_HOME is not a JDK $v}"
  fi
}

started=$SECONDS
select_repos

while IFS='	' read -r name dir; do
  [ -n "$dir" ] || continue
  missing=""
  skip_hint=""
  case "$name" in
    knk-web-app)
      if ! command -v npx >/dev/null 2>&1; then missing="node/npx not found"
      elif [ ! -f "$dir/node_modules/typescript/bin/tsc" ]; then missing="no node_modules; run npx npm@11 ci"
      fi
      check_repo knk-web-app "$dir" tsc '\.(ts|tsx|js|jsx|mts|cts|json)$' '' npx tsc --noEmit
      ;;
    knk-web-api)
      if ! command -v dotnet >/dev/null 2>&1; then missing="dotnet not found"
      elif [ ! -f "$dir/obj/project.assets.json" ]; then missing="packages not restored; run dotnet restore"
      fi
      check_repo knk-web-api "$dir" build '\.(cs|csproj|props|targets|sln)$' \
        'NETSDK1004|NETSDK1045|compatible \.NET SDK was not found|No \.NET SDKs were found' \
        dotnet build --no-restore -v q -nologo
      ;;
    knk-plugin)
      gradle_jdk_args=()
      if [ ! -f "$dir/gradlew" ]; then missing="no gradlew"
      elif [ -z "${JAVA_HOME:-}" ] && ! command -v java >/dev/null 2>&1; then missing="java not found"
      else plugin_toolchain "$dir"
      fi
      check_repo knk-plugin "$dir" compile '\.(java|kts|gradle|properties|toml)$' \
        'No matching toolchains? found|Cannot find a Java installation|No locally installed toolchains|Unsupported class file major version' \
        sh ./gradlew compileJava compileTestJava -q ${gradle_jdk_args[@]+"${gradle_jdk_args[@]}"}
      ;;
  esac
done <<< "$selected"

# Name the checked and ignored clones whenever there is output, and once whenever the pick changes.
if [ -n "$pick_note" ]; then
  pick_state=$(git -C "$ws" rev-parse --git-path knk-fast-check-pick 2>/dev/null) || pick_state=""
  case "$pick_state" in ""|/*|[A-Za-z]:*) ;; *) pick_state="$ws/$pick_state" ;; esac
  prev_pick=""
  [ -n "$pick_state" ] && [ -f "$pick_state" ] && prev_pick=$(cat "$pick_state" 2>/dev/null)
  if [ -n "$failures" ] || [ -n "$notes" ] || [ "$prev_pick" != "$pick_note" ]; then
    case "$pick_note" in
      "only KNK_FAST_CHECK_REPOS"*) note "$pick_note" ;;
      *) note "clones: $pick_note (set KNK_FAST_CHECK_REPOS to choose)" ;;
    esac
  fi
  [ -n "$pick_state" ] && printf '%s\n' "$pick_note" > "$pick_state" 2>/dev/null
fi

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
