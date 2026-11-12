# Agent tooling: MCP servers and the fast-check hook

**Status:** Active · **Last updated:** 2026-11-12 (permission rule for `add_repo`, § 4, developer decision 2026-11-12); 2026-11-12 (first version, [PandiO/knk-workspace#331](https://github.com/PandiO/knk-workspace/issues/331), [DESIGN § 10](../../specs/ai-agent-workflow/DESIGN.md#10-tooling-mcp-servers-and-hooks))

What knk-workspace configures for Claude Code sessions started in it: three MCP servers in `.mcp.json`, and in
`.claude/settings.json` a Stop hook that compiles the component repos an agent changed and a permission rule that lets
sessions attach repositories. None of the files holds a secret.

## 1. What is configured

| File | What it does |
|---|---|
| `.mcp.json` | MCP servers `github`, `playwright` and `context7` (§ 2) |
| `.claude/settings.json` | One `Stop` hook: `bash "${CLAUDE_PROJECT_DIR}/.claude/hooks/fast-check.sh"`, timeout 600 s (§ 3); `permissions.allow` for `add_repo` and `register_repo_root` (§ 4) |
| `.claude/hooks/fast-check.sh` | The fast checks (§ 3) |
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
2. Looks for `knk-web-app`, `knk-web-api` and `knk-plugin` in both layouts: under `Repository/` in the workspace and
   next to the workspace. A checkout found both ways is checked once.
3. **Base.** A repo is checked only when it has source changes against `origin/next` if that exists, else the default
   branch (`origin/HEAD`, `origin/main`, `origin/master`): commits since the merge base, staged, unstaged and untracked
   files all count. `next` is the integration branch feature branches start from (DESIGN § 2.2), so a branch's own
   work is what counts. The hook does not fetch; it uses the remote branches as they are locally.
4. Only files that can break the build count: `.ts/.tsx/.js/.jsx/.json` (web app), `.cs/.csproj/.props/.targets/.sln`
   (API), `.java/.kts/.gradle/.properties/.toml` (plugin).
5. A state that passed (or was skipped for the same reason) is remembered in the repo's git directory
   (`knk-fast-check`), so the next stop without new changes costs nothing. In a workspace-only session the hook only
   runs a few `git` commands (well under a second).
6. Checks, run one after the other in the repo's folder. None of them deploys; the plugin's `./gradlew build` and
   `:knk-paper:dev` copy a jar to the dev server and are never used.

| Repo | Check | Skipped (with a note) when |
|---|---|---|
| knk-web-app | `npx tsc --noEmit` | `npx` missing, or no `node_modules` (run `npx npm@11 ci`) |
| knk-web-api | `dotnet build --no-restore -v q -nologo` (the solution: API and test project) | `dotnet` missing, packages not restored (run `dotnet restore`), or the SDK can't build the project |
| knk-plugin | `sh ./gradlew compileJava compileTestJava -q` | no Java, or Gradle finds no Java 25 toolchain |

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

1. Bash with `git`, `grep`, `sed`, `awk` and `timeout` (Linux, macOS with coreutils `gtimeout`, Git Bash on Windows).
   Without `timeout` the checks run without their own limit and only Claude Code's 600 s applies.
2. The hook is configured in knk-workspace, so it runs for sessions started there (coordinators, links, docs sessions).
   A session started inside a component repo does not load it.
3. It blocks on errors that were already in a checkout, not only on the session's own changes; the message lets the
   agent say so instead of fixing unrelated work.

## 4. Permission rule: attaching repositories in link sessions

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
2. **The rule does not limit which repositories.** Claude Code matches an MCP allow rule on the tool name only:
   `mcp__<server>__<tool>` or `mcp__<server>__*`, with no specifier. A rule with parentheses (for example one naming
   the `owner` or `repo` argument) is skipped when the settings file loads, and a specifier on an allow rule would match
   no call ([permissions, MCP and "Match by input parameter"](https://code.claude.com/docs/en/permissions), read
   2026-11-12). The developer asked for the rule to be limited to the four knk repositories; the limit therefore
   comes from the cloud session's GitHub access, not from the rule: the repositories the Claude GitHub App is
   installed on for the `PandiO` account (GitHub, Settings, Applications, Installed GitHub Apps, Claude, Repository
   access). `add_repo` refuses a repository the app cannot reach. Keep that list to the repositories sessions should
   reach (the four knk repositories, plus read-only ones such as `knk-dev-db-seed`). The permissions block in each
   link prompt also names only the repositories the developer authorized for the chain.
3. **Where it applies.** Only in sessions whose project is knk-workspace: a cloud session reads the repository's
   `.claude/settings.json` when it starts with that one repository, which is how coordinators start links
   (`source_url` knk-workspace). A session started in a component repo does not get the rule. The rule exists only
   once this file is on the branch the session starts from (`main`, and `next` after the next merge of `main`).
4. **Remove it** by deleting the two lines (or the whole `permissions` block) from `.claude/settings.json` and
   merging that; sessions started afterwards ask again before attaching. To refuse attaches outright, add the same
   names to `permissions.deny` instead (deny wins over allow). To turn it off on one machine only, put
   `{"permissions": {"deny": ["mcp__claude-code-remote__add_repo"]}}` in the untracked `.claude/settings.local.json`.
   `/permissions` in Claude Code shows the rules in force and where each comes from.
