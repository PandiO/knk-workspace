# Agent tooling: MCP servers and the fast-check hook

**Status:** Active · **Last updated:** 2026-11-13 (fast-check: which clones, JDK 25 detection, only passes cached, § 3.1, § 3.6, § 3.7, trial findings of [#331](https://github.com/PandiO/knk-workspace/issues/331)); 2026-11-12 (`add_repo` guard hook, § 4.2, developer decision 2026-11-12); 2026-11-12 (permission rule for `add_repo`, § 4, developer decision 2026-11-12); 2026-11-12 (first version, [PandiO/knk-workspace#331](https://github.com/PandiO/knk-workspace/issues/331), [DESIGN § 10](../../specs/ai-agent-workflow/DESIGN.md#10-tooling-mcp-servers-and-hooks))

What knk-workspace configures for Claude Code sessions started in it: three MCP servers in `.mcp.json`, and in
`.claude/settings.json` a Stop hook that compiles the component repos an agent changed, a permission rule that lets
sessions attach repositories and a PreToolUse hook that limits those attaches to the knk repositories. None of the
files holds a secret.

## 1. What is configured

| File | What it does |
|---|---|
| `.mcp.json` | MCP servers `github`, `playwright` and `context7` (§ 2) |
| `.claude/settings.json` | One `Stop` hook: `bash "${CLAUDE_PROJECT_DIR}/.claude/hooks/fast-check.sh"`, timeout 600 s (§ 3); `permissions.allow` for `add_repo` and `register_repo_root` (§ 4.1); one `PreToolUse` hook for `add_repo`: `bash "${CLAUDE_PROJECT_DIR}/.claude/hooks/add-repo-guard.sh"`, timeout 30 s (§ 4.2) |
| `.claude/hooks/fast-check.sh` | The fast checks (§ 3) |
| `.claude/hooks/add-repo-guard.sh` | The `add_repo` guard: only the knk repositories may be attached (§ 4.2) |
| `.gitattributes` | Keeps `*.sh` at LF line endings, so the hook also runs from a Windows checkout (Git Bash) |

Project skills live next to these under `.claude/skills/`; they need no settings entry.

## 2. MCP servers (`.mcp.json`)

1. **Local Claude Code only.** `.mcp.json` is read by Claude Code on the developer's PC (CLI, desktop app, IDE
   extensions) when a session starts in knk-workspace. Claude Code asks once per server before it uses a project server;
   approve them, or reset the choices with `claude mcp reset-project-choices`. Check the connection with `/mcp`.
2. **Cloud sessions on claude.ai** get their GitHub tools from the platform (its own `github` server for the
   repositories attached to the session, plus the claude-code-remote tools); they don't need `GITHUB_PAT`. Tested
   2026-11-12 with Claude Code 2.1.322 in knk-workspace: a `github` server passed to the session by the host
   (`--mcp-config`, source `dynamic`) replaces the project's `github` entry of the same name, and without `GITHUB_PAT`
   the project entry only shows as `failed` in `/mcp`; the other servers still connect. Playwright needs a browser on
   the machine, so it is mainly for local sessions. Context7 works in both when its host is reachable.
3. Servers:

| Server | Use | Config (from the official docs, 2026-11-12) | Environment variable |
|---|---|---|---|
| `github` | Issues, pull requests, labels, CI runs in `PandiO/*` | Remote server `https://api.githubcopilot.com/mcp/` over HTTP, `Authorization: Bearer ${GITHUB_PAT}`, toolsets `context,repos,issues,pull_requests,actions,labels` (header `X-MCP-Toolsets`) ([install guide](https://github.com/github/github-mcp-server/blob/main/docs/installation-guides/install-claude.md), [remote server headers](https://github.com/github/github-mcp-server/blob/main/docs/remote-server.md)) | `GITHUB_PAT` (required) |
| `playwright` | Drive a browser against the web app (`npm start` on `http://localhost:3000`) for checks and screenshots | `npx -y @playwright/mcp@0.0.85 --isolated` (stdio; [playwright-mcp](https://github.com/microsoft/playwright-mcp)). `--isolated` keeps the browser profile in memory, so no login state is left behind | none |
| `context7` | Current library docs (Paper, React, EF Core, …) | Remote server `https://mcp.context7.com/mcp` over HTTP, `Authorization: Bearer ${CONTEXT7_API_KEY:-}` ([Context7 clients](https://context7.com/docs/resources/all-clients)) | `CONTEXT7_API_KEY` (optional; without it the server works with lower rate limits) |

4. **Variables.** Claude Code expands `${VAR}` and `${VAR:-default}` in `.mcp.json` from the environment it was started
   in ([MCP docs, environment variable expansion](https://code.claude.com/docs/en/mcp)). Set them in your shell profile
   (`export GITHUB_PAT=...`) or on Windows with `setx GITHUB_PAT ...`, then start a new terminal. Never put a token in
   `.mcp.json` or a committed settings file.
5. **GitHub token.** A fine-grained personal access token for the four `PandiO/knk-*` repositories with: Contents
   read/write, Issues read/write, Pull requests read/write, Actions read, Metadata read. Give it an expiry date.
6. **Playwright version.** The package is pinned (`0.0.85`, the current release on 2026-11-12) so a new release does not
   run unreviewed; bump it in `.mcp.json` when needed. The first start downloads it, and a browser has to be installed
   once (`npx playwright install chromium`) if Playwright has none.
7. **Turn one server off** without editing the file: toggle it in `/mcp`, or add it to `disabledMcpjsonServers` in your
   own `~/.claude/settings.json` or the untracked `.claude/settings.local.json`, for example
   `{"disabledMcpjsonServers": ["playwright"]}`.
8. **Later** (DESIGN § 10.1.2): a MySQL MCP with a read-only user for the dev database, and a Docker MCP for the homelab.

## 3. The fast-check Stop hook

### 3.1 What it does

1. Runs when the agent finishes a reply (the `Stop` event), not after every edit.
2. Finds the clones of `knk-web-app`, `knk-web-api` and `knk-plugin` to check, by their `origin` URL, in both layouts
   and elsewhere on the machine; when a repo has several clones it checks only the most recently active one, and
   `KNK_FAST_CHECK_REPOS` names the clones by hand (§ 3.6).
3. **Base.** A repo is checked only when it has source changes against `origin/next` if that exists, else the default
   branch (`origin/HEAD`, `origin/main`, `origin/master`): commits since the merge base, staged, unstaged and untracked
   files all count. `next` is the integration branch feature branches start from (DESIGN § 2.2), so a branch's own
   work is what counts. The hook does not fetch; it uses the remote branches as they are locally.
4. Only files that can break the build count: `.ts/.tsx/.js/.jsx/.json` (web app), `.cs/.csproj/.props/.targets/.sln`
   (API), `.java/.kts/.gradle/.properties/.toml` (plugin).
5. **Only passes are remembered.** A state that passed is stored in the repo's git directory (`knk-fast-check`), so the
   next stop without new changes costs nothing. Skips and timeouts are never stored: the next stop tries again, so a
   toolchain installed or made findable later is used at once, without a code change. The stored state includes the
   check command, and with it the JDK folder passed to Gradle (§ 3.7), so a pass with another JDK counts as new. In a
   workspace-only session the hook only runs a few `git` commands and the clone search (about half a second).
6. Checks, run one after the other in the repo's folder. None of them deploys; the plugin's `./gradlew build` and
   `:knk-paper:dev` copy a jar to the dev server and are never used.

| Repo | Check | Skipped (with a note) when |
|---|---|---|
| knk-web-app | `npx tsc --noEmit` | `npx` missing, or no `node_modules` (run `npx npm@11 ci`) |
| knk-web-api | `dotnet build --no-restore -v q -nologo` (the solution: API and test project) | `dotnet` missing, packages not restored (run `dotnet restore`), or the SDK can't build the project |
| knk-plugin | `sh ./gradlew compileJava compileTestJava -q`, plus `-Porg.gradle.java.installations.paths=<dir>` when the hook finds a JDK 25 (§ 3.7) | no Java, or Gradle finds no Java 25 toolchain; the note says what is missing and how to fix it |

### 3.2 Results

1. **Errors:** the hook exits with code 2 and writes the errors (per repo, trimmed to 60 lines, warnings left out) to
   stderr. Claude Code then keeps the agent working with that text as the reason. The agent fixes the errors, or says
   why they are expected (for example, they were already in the checkout before the session).
2. **Passed, skipped or timed out:** not blocking. The hook prints `{"systemMessage": "knk fast check: ..."}`, which
   Claude Code shows to the user.
3. **Nothing changed:** no output.
4. **No loops:** when the input has `"stop_hook_active": true` (the agent is already continuing because of a Stop hook),
   the hook returns at once without checks. Claude Code also ends a turn after eight blocks in a row. The fix the agent
   makes after a block is therefore checked at the next stop of a later turn, not in the same turn.
5. **Time limits:** each check has `KNK_FAST_CHECK_TIMEOUT` seconds (default 300) and all checks together
   `KNK_FAST_CHECK_BUDGET` seconds (default 540); `timeout` in settings.json (600 s) is Claude Code's hard limit. A check
   that times out is reported, not blocking. Measured in a cloud container on 2026-11-12: web app 25-30 s, API 20 s
   warm / 72 s cold, plugin 6-23 s warm / 100 s cold.

### 3.3 Turning it off

| Scope | How |
|---|---|
| Only this hook, one session | Start Claude Code with `KNK_FAST_CHECK=off` in the environment |
| Only this hook, always on this machine | `{"env": {"KNK_FAST_CHECK": "off"}}` in the untracked `.claude/settings.local.json` (or `~/.claude/settings.json`) |
| All hooks | `{"disableAllHooks": true}` in `.claude/settings.local.json`, or `claude --settings '{"disableAllHooks": true}'` for one run |
| Look at what is configured | `/hooks` in Claude Code |

Claude Code has no switch for one hook while keeping it configured, hence `KNK_FAST_CHECK`
([hooks reference, disable or remove hooks](https://code.claude.com/docs/en/hooks)).

### 3.4 Hook contract used

From the [hooks reference](https://code.claude.com/docs/en/hooks), read 2026-11-12:

1. Configuration: `hooks.Stop[].hooks[]` with `type: "command"`, `command` and `timeout` in seconds; Stop takes no
   matcher. `${CLAUDE_PROJECT_DIR}` is the project root where the session started.
2. Input on stdin: the common fields plus `stop_hook_active`, `last_assistant_message`, `background_tasks` and
   `session_crons`. The hook reads only `stop_hook_active`, with `grep`, so it needs no `jq`.
3. Blocking: exit code 2 with the reason on stderr ("Prevents Claude from stopping, continues the conversation"). The
   JSON form `{"decision": "block", "reason": "..."}` does the same; exit 2 was chosen because it needs no JSON
   escaping of compiler output.
4. Non-blocking notes: exit 0 with JSON `systemMessage` ("Warning message shown to the user").

### 3.5 Requirements and limits

1. Bash with `git`, `grep`, `sed`, `awk`, `find`, `stat` and `timeout` (Linux, macOS with coreutils `gtimeout`, Git Bash
   on Windows). Without `timeout` the checks run without their own limit and only Claude Code's 600 s applies.
2. The hook is configured in knk-workspace, so it runs for sessions started there (coordinators, links, docs sessions).
   A session started inside a component repo does not load it.
3. It blocks on errors that were already in a checkout, not only on the session's own changes; the message lets the
   agent say so instead of fixing unrelated work.

### 3.6 Which clones are checked

1. **`KNK_FAST_CHECK_REPOS` set:** exactly the clones it lists, and nothing else. Separate paths with `:`, or with `;`
   on Windows (`C:/...` paths contain a colon). A relative path counts from the workspace. A path that is not a git
   clone, or not a clone of the three component repos (by `origin` URL, else by folder name), is ignored with a note.
   Set it in the environment the session starts with, or in the untracked `.claude/settings.local.json`:
   `{"env": {"KNK_FAST_CHECK_REPOS": "/home/user/pandio/knk-plugin"}}`.
2. **Otherwise the hook searches**, and recognises a clone by its `origin` remote URL ending in `PandiO/<name>` or
   `PandiO/<name>.git` (any letter case), not by its folder name:
    1. `Repository/*` in the workspace and the folders next to the workspace (both layouts);
    2. up to three folders deep under the workspace's parent folder and under `$HOME`, skipping `node_modules`,
       `.gradle`, `bin`, `obj`, `build`, `AppData`, `Library` and hidden folders (the search is capped at 3 s; it takes
       a few milliseconds in a cloud container);
    3. a clone found more than once (a symlink, both layouts) counts once, by its real path.
3. **Several clones of one repo:** only the most recently active one is checked: the newest of its `index` file, its
   `logs/HEAD` and its changed files (up to 200, from `git status`, which the hook runs without refreshing the index so
   it does not make a clone look active). Clones without changes against their base are still picked this way; the
   picked one is then checked only if it has changes.
4. **What the hook says:** whenever it has output, and once each time the pick changes, the note names the checked
   clone and the ignored ones, for example `clones: knk-plugin: checked /home/user/pandio/knk-plugin (most recently
   active), ignored /home/user/knk-plugin (set KNK_FAST_CHECK_REPOS to choose)`. If the pick is wrong, set
   `KNK_FAST_CHECK_REPOS`. The last pick is kept in the workspace's git directory (`knk-fast-check-pick`).
5. **Why one clone and not all:** a stale clone on another branch can hold errors that have nothing to do with the
   session, and blocking on them would stop the agent for someone else's work; checking every clone would also multiply
   the time (Gradle and `tsc` take 25 s to 100 s each). The trial on 2026-11-13 had exactly that case: an old sibling
   clone of knk-plugin next to the workspace, and the session's real clone in `/home/user/pandio/knk-plugin`.

### 3.7 JDK 25 for the plugin check

knk-plugin compiles with a Java 25 toolchain (`JavaLanguageVersion.of(25)` in `build.gradle.kts`), while Gradle itself
runs on Java 21. Gradle finds a toolchain only in the folders it scans on its own (on Linux `/usr/lib/jvm`, SDKMAN,
`~/.gradle/jdks`, ...) or in `org.gradle.java.installations.paths`. So before the plugin check the hook:

1. reads the toolchain version from the build files (25 today);
2. looks for a JDK of that version, by its `release` file and `bin/javac`, in this order: `$KNK_JDK25_HOME`,
   `$JAVA_HOME`, `/usr/lib/jvm/*25*`, `/usr/lib64/jvm/*25*`, `/opt/jdk-25*`, `/opt/*jdk*25*`, `/opt/java/*25*`,
   `~/.gradle/jdks/*25*` (or under `$GRADLE_USER_HOME`), `~/.sdkman/candidates/java/25*`, `~/.jdks/*25*`, macOS
   `/Library/Java/JavaVirtualMachines/*25*`, and on Windows `C:/Program Files/{Java,Eclipse Adoptium,Microsoft}/*25*`,
   each also one folder deeper;
3. passes the first one found as `-Porg.gradle.java.installations.paths=<dir>` on the Gradle command line. It never
   edits `~/.gradle/gradle.properties`. If `org.gradle.java.installations.paths` is already set in that file or in
   the plugin's `gradle.properties`, the hook leaves it alone;
4. if Gradle still finds no toolchain, the check is skipped with a note that says what is missing and the fix, for
   example `knk-plugin skipped (Gradle needs a Java 25 toolchain and the hook found none in KNK_JDK25_HOME, JAVA_HOME,
   /usr/lib/jvm, /opt, ~/.gradle/jdks, ~/.sdkman or ~/.jdks; install one (Debian/Ubuntu: apt-get install -y
   openjdk-25-jdk-headless) or set KNK_JDK25_HOME to its folder. Gradle said: Cannot find a Java installation ...)`.
   Skips are not remembered (§ 3.1 item 5), so the next stop checks as soon as the JDK is there.

**Fix a skip** in one of these ways:

1. Install a JDK 25 where the hook looks, for example `apt-get install -y openjdk-25-jdk-headless` (it lands in
   `/usr/lib/jvm`).
2. Set `KNK_JDK25_HOME` to a JDK 25 folder you already have (environment, or `env` in `.claude/settings.local.json`).
3. On your own machine you can also put `org.gradle.java.installations.paths=<dir>` in `~/.gradle/gradle.properties`,
   which helps every Gradle run, not only the hook.

**Cloud environment (suggestion; the developer decides).** Cloud containers may start without a JDK 25. A line for the
environment's setup script (claude.ai, the environment's settings), which installs one only when none is there:

```bash
ls -d /usr/lib/jvm/*25* >/dev/null 2>&1 || { apt-get update -qq && apt-get install -y -qq openjdk-25-jdk-headless; }
```

If the JDK comes from somewhere else (a tarball in `/opt`, for example), set `KNK_JDK25_HOME` to its folder in the
environment's variables instead; the hook also finds `/opt/jdk-25*` on its own.

## 4. Attaching repositories in link sessions

### 4.1 Permission rule

Developer decision 2026-11-12 (setup chain, [PandiO/knk-workspace#327](https://github.com/PandiO/knk-workspace/issues/327)):
chain links start with `create_session` and attach the knk repositories they need themselves, so the developer does
not have to approve each attach. `.claude/settings.json` therefore has:

```json
"permissions": {
  "allow": [
    "mcp__claude-code-remote__add_repo",
    "mcp__claude-code-remote__register_repo_root"
  ]
}
```

1. **What it allows.** `add_repo` attaches a GitHub repository to the cloud session; `register_repo_root` tells the
   session that the clone is done so its `CLAUDE.md` and skills load. Both come from the `claude-code-remote` tools of
   cloud sessions on claude.ai; on the developer PC the server does not exist and the rule does nothing.
2. **The rule itself does not limit which repositories.** Claude Code matches an MCP allow rule on the tool name only:
   `mcp__<server>__<tool>` or `mcp__<server>__*`, with no specifier. A rule with parentheses (for example one naming
   the `owner` or `repo` argument) is skipped when the settings file loads, and a specifier on an allow rule would match
   no call ([permissions, MCP and "Match by input parameter"](https://code.claude.com/docs/en/permissions), read
   2026-11-12). The limit comes from two places: the guard hook in § 4.2, and the cloud session's GitHub access, the
   repositories the Claude GitHub App is installed on for the `PandiO` account (GitHub, Settings, Applications,
   Installed GitHub Apps, Claude, Repository access); `add_repo` refuses a repository the app cannot reach. Keep that
   list to the repositories sessions should reach. The permissions block in each link prompt also names only the
   repositories the developer authorized for the chain.
3. **Where it applies.** Only in sessions whose project is knk-workspace: a cloud session reads the repository's
   `.claude/settings.json` when it starts with that one repository, which is how coordinators start links
   (`source_url` knk-workspace). A session started in a component repo does not get the rule. The rule exists only
   once this file is on the branch the session starts from (`main`, and `next` after the next merge of `main`).
4. **Remove it** by deleting the two lines (or the whole `permissions` block) from `.claude/settings.json` and
   merging that; sessions started afterwards ask again before attaching. To refuse attaches outright, add the same
   names to `permissions.deny` instead (deny wins over allow). To turn it off on one machine only, put
   `{"permissions": {"deny": ["mcp__claude-code-remote__add_repo"]}}` in the untracked `.claude/settings.local.json`.
   `/permissions` in Claude Code shows the rules in force and where each comes from.

### 4.2 The `add_repo` guard hook

Developer decision 2026-11-12 (setup chain follow-up L3c, [PandiO/knk-workspace#331](https://github.com/PandiO/knk-workspace/issues/331)):
a `PreToolUse` hook with the matcher `mcp__claude-code-remote__add_repo` runs `.claude/hooks/add-repo-guard.sh`
before every `add_repo` call.

1. **What it allows.** Owner `PandiO` and one of `knk-workspace`, `knk-web-api`, `knk-web-app`, `knk-plugin`,
   `knk-v1-archive`, `knk-v2-archive`, `knk-dev-db-seed`, both compared case-insensitively, with any `access`. Every
   other call is denied: another owner, another repository, an `owner/repo` value in the `repo` field, and input the
   script cannot read (missing or non-string `owner`/`repo`, a duplicate key, characters a GitHub name cannot have,
   input that is not JSON). An allowed call gets no output and exit 0, so the permission rule of § 4.1 lets it through
   without a prompt; a denied call gets exit 2 and a reason that names the allowed list and says that only the
   developer changes it.
2. **How it reads the input.** With `python3` (present in cloud sessions) it parses the JSON; without it, a strict
   `grep`/`sed` parse of the flat `tool_input` object that accepts exactly one `owner` and one `repo` string without
   escapes. No `jq`. It never uses `set -e` or `set -u`, because any exit code other than 0 and 2 would let the call
   through.
3. **Add a repository** by adding its name to `ALLOWED_REPOS` at the top of the script (a space-separated list, the
   one place it is defined), and merging that. Sessions pick it up at their next start. Also give the Claude GitHub
   App access to it (§ 4.1 item 2), or `add_repo` still refuses it.
4. **Turn it off.** Remove the `PreToolUse` entry from `.claude/settings.json` and merge that; `add_repo` is then
   limited only by the GitHub App (§ 4.1 item 2). For one machine or one run, `{"disableAllHooks": true}` in the
   untracked `.claude/settings.local.json` or `claude --settings '{"disableAllHooks": true}'` also turns off the Stop
   hook (§ 3.3). There is no per-hook environment switch, on purpose: a switch an agent could set would weaken the
   guard.
5. **Hook contract used**, from the [hooks reference](https://code.claude.com/docs/en/hooks), read 2026-11-12:
    1. MCP tools appear in tool events as `mcp__<server>__<tool>`; a matcher of only letters, digits, `_` and `-` is
       compared as an exact string ("Match MCP tools", "Matcher patterns").
    2. Input on stdin: the common fields plus `tool_name`, `tool_input` and `tool_use_id` ("PreToolUse").
    3. Exit 2 blocks the tool call and Claude sees stderr as the denial reason, the same as
       `hookSpecificOutput.permissionDecision: "deny"` with `permissionDecisionReason` ("PreToolUse decision control",
       "Exit code 2 behavior per event"). Exit 2 was chosen because it needs no JSON on stdout.
    4. A blocking hook takes precedence over allow rules: "A hook that exits with code 2 stops the tool call before
       permission rules are evaluated, so the block applies even when an allow rule would otherwise let the call
       proceed" ([permissions, "Extend permissions with hooks"](https://code.claude.com/docs/en/permissions)).
    5. A hook that times out or fails with another exit code does not block (the call continues through the normal
       permission flow), so the script keeps its work small (timeout 30 s; it runs in well under a second).
6. **Tested** 2026-11-12: fifteen sample inputs with and without `python3` (allowed, mixed case, pretty-printed,
   disallowed repository, wrong owner, `owner/repo` in `repo`, a prefix such as `knk-plugin-x`, missing or non-string
   `repo`, escaped quote, duplicate key, garbage, empty, no `tool_input`), and end to end with headless Claude Code
   2.1.322 and a stand-in `claude-code-remote` server: allowed calls reached the server, the others were blocked with
   the reason shown to the agent, also when `add_repo` was allowed on the command line.
7. **Where it applies:** the same as the permission rule (§ 4.1 item 3): sessions whose project is knk-workspace. On
   the developer PC `add_repo` does not exist and the hook never runs.
