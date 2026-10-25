#!/usr/bin/env bash
# knk-release.sh: prepare and upload a trunk build for knk-deploy (Stage B). Runs on the developer PC (Git Bash).
#
#   knk-release.sh api    [commit]   git archive of knk-web-api  -> ssh knk-deploy upload api-src <commit>
#   knk-release.sh web    [commit]   git archive of knk-web-app  -> ssh knk-deploy upload web-src <commit>
#   knk-release.sh plugin [commit]   :knk-paper:shadowJar of knk-plugin in a clean worktree -> upload plugin-jar
#
# Without a commit it takes the trunk head (origin/master for the API, origin/main otherwise). Any commit must be on
# that trunk: the NAS can't check this itself (it has no GitHub access), so this script is where it's enforced.
# It only uploads; the deploy itself is a separate `ssh knk-deploy deploy-<x> <commit>`, which Claude Code asks
# before running. Repos are looked up in $KNK_REPOS (default ~/Documents/Werk/KnightsAndKings/Repository).
set -euo pipefail

kind="${1:-}"; want="${2:-}"
REPOS="${KNK_REPOS:-$HOME/Documents/Werk/KnightsAndKings/Repository}"
case "$kind" in
  api)    repo=knk-web-api; trunk=master; up=api-src ;;
  web)    repo=knk-web-app; trunk=main;   up=web-src ;;
  plugin) repo=knk-plugin;  trunk=main;   up=plugin-jar ;;
  *) echo "usage: $0 api|web|plugin [commit]" >&2; exit 64 ;;
esac
dir="$REPOS/$repo"
[ -d "$dir/.git" ] || { echo "no git repo at $dir (set KNK_REPOS)" >&2; exit 66; }

git -C "$dir" fetch -q origin "$trunk"
if [ -z "$want" ]; then want=$(git -C "$dir" rev-parse "origin/$trunk"); fi
commit=$(git -C "$dir" rev-parse --verify "${want}^{commit}")
if ! git -C "$dir" merge-base --is-ancestor "$commit" "origin/$trunk"; then
  echo "REFUSED: $repo $commit is not on origin/$trunk" >&2; exit 65
fi
echo "$repo $commit (on origin/$trunk: $(git -C "$dir" log -1 --format='%ci %s' "$commit" | cut -c1-100))"

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
if [ "$kind" = plugin ]; then
  wt="$tmp/wt"
  git -C "$dir" worktree add -q --detach "$wt" "$commit"
  trap 'git -C "$dir" worktree remove --force "$wt" >/dev/null 2>&1; rm -rf "$tmp"' EXIT
  # shadowJar only: a plain `build` also runs deployToDevServer.
  if [ -f "$wt/gradlew.bat" ] && command -v cmd.exe >/dev/null; then
    (cd "$wt" && cmd.exe //c "gradlew.bat :knk-paper:shadowJar -q") >"$tmp/gradle.log" 2>&1 || { tail -20 "$tmp/gradle.log"; exit 1; }
  else
    (cd "$wt" && ./gradlew :knk-paper:shadowJar -q) >"$tmp/gradle.log" 2>&1 || { tail -20 "$tmp/gradle.log"; exit 1; }
  fi
  file="$wt/knk-paper/build/libs/knk-paper-0.1.0-SNAPSHOT.jar"
else
  file="$tmp/$repo-${commit:0:8}.tar.gz"
  git -C "$dir" -c core.autocrlf=false archive --format=tar.gz --prefix=source/ -o "$file" "$commit"
fi
echo "sha256 $(sha256sum "$file" | cut -c1-64)  $(du -h "$file" | cut -f1)"
# shellcheck disable=SC2029  # the arguments are meant to expand here
ssh knk-deploy upload "$up" "$commit" < "$file"
echo "next: ssh knk-deploy deploy-$kind $commit"
