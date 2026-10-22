# Kickoff prompt: set up the closed-alpha stack on the VPS

**Created:** 2026-10-22
**Status:** **Shelved (2026-10-22)** — do not run; the NAS stays the alpha host for the current test round. Kept for a later move: re-verify the facts and build refs it names first. Originally Draft v1.
**Linear:** [KNG-241](https://linear.app/kngpandi/issue/KNG-241)
**Plan:** [VPS bootstrap runbook](../../guides/vps-bootstrap-runbook.md)
**Where it runs:** Claude Code on the VPS, as the user `knk-agent`, inside `tmux`, started in the cloned
`knk-workspace` checkout. Not a cloud session; there is no Linear or GitHub MCP, only the shell and a read-only GitHub token.

Fill in the `<…>` values from the checklist (never a secret), then paste everything inside the fence.

```text
You are setting up the Knights & Kings closed-alpha stack on THIS server, a fresh OVH VPS running Ubuntu 24.04. You
run unattended as the user knk-agent with passwordless sudo. The developer checks in occasionally; they have a full-time
job and little time, so make reversible decisions yourself and stop only where the runbook says to.

Read these completely before acting, in this order:
1. AGENTS.md, then docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md
2. docs/guides/vps-bootstrap-runbook.md   <- your plan and your rules (§ 4 and § 5 especially)
3. docs/guides/vps-preflight-checklist.md <- what the developer already provided
4. As needed: docs/guides/production-installation.md (§ 3-7), docs/guides/closed-alpha-deployment-runbook.md,
   docs/guides/alpha-go-live.md, docs/guides/performance-metrics-and-capacity.md
5. Files that exist only on the invitations branch, read with
   `git show origin/claude/player-signup-invitation-flow-f4v7ul:<path>`: docs/guides/alpha-go-live.md (§ 4.1, § 5.1, § 6,
   § 11.1), docs/guides/email.md, docs/guides/invitations-smoke-test.md

Facts you must use (from the developer's pre-flight):
- Build refs:      api=<sha>  app=<sha>  plugin=<sha>
- Web host:        <app.knightsandkings.net>     Minecraft host: <play.knightsandkings.net>
- ACME address:    <address>
- Starting values: view distance <10>, simulation distance <6>, MEMORY=<6G>
- Whitelisted testers: <names>       First admin (Minecraft name): <name>
- Seed schema_version: <value, or "not delivered yet">
- Files already on this server: <list the paths from checklist section E>
- GitHub token: /home/knk-agent/.config/knk/github_token (read-only; use it only to clone/fetch the four repos)

Your job: do runbook phases V1 to V9 without asking, in order, recording every result in /home/knk-agent/PROGRESS.md.
Then STOP at hold point H1 (before the seed import) if the seed is not here yet; at H2 (before publishing 25565 / go-live);
and at H3 (teardown). At a hold point, write a short status summary into PROGRESS.md and into your reply, say exactly what
you need, and wait.

Hard rules (the runbook § 4 has the full list):
- Never print, echo, log, commit or paste a secret. Generate with openssl, write straight to the root-only files under
  /etc/knk/, check with stat/test, not cat. If a value is shown by accident, note THAT it happened in PROGRESS.md.
- Publish no ports except Caddy 80/443. Do not publish 25565 until H2. UFW does not control Docker-published ports.
- Everything before H1 runs against the scratch database and scratch world copy. Do not create users in the real
  knightsandkings_alpha database and do not start the real API before the seed import.
- Never accept the Minecraft EULA. When the server needs it, stop and ask the developer to set EULA=TRUE.
- No actions outside this host: no pushes, no DNS, no Cloudflare, no contact with the NAS, no email other than the relay test.
- Stop and ask (with your recommendation) before: a new open port, software the runbook does not name, deleting a volume,
  backup, dump or world, using a ref other than the ones above, or a failed acceptance check that one reasoned fix did not repair.
- Anything outside the scope you notice goes under "To file in Linear" in PROGRESS.md. Do not fix it silently.
- Do not install Claude Code plugins, MCP servers or other tools on this host.

The runbook is a plan, not an oracle. Where it is wrong or a command fails, work out the correct step from the sources it
cites, say so in PROGRESS.md, and carry on if the fix is small and reversible; otherwise stop and ask. Prefer the smallest
change that meets the acceptance checks. Check every claim you rely on (image names, flags, ports, healthchecks) against
the real image or tool before you use it.

Definition of done for this session: V1-V9 complete and accepted, the stack running healthy against the scratch data (or the
real data if the seed arrived), the backup restore rehearsal recorded, and H1/H2/H3 clearly stated as the developer's
next actions. Begin with `git status`, `lscpu`, `free -h`, `df -h`, and the current ufw/ss state, and record them.
```

## Notes for the developer

- **Start it** as `knk-agent` on the VPS: `tmux new -s knk`, `cd ~/knk-workspace`, start Claude Code, paste the prompt. To
  check in later: `ssh knk-agent@<ip>`, `tmux attach -t knk`. Detaching (`Ctrl-b d`) leaves it running.
- **Repository state:** this prompt and the runbook live on the branch `claude/festive-maxwell-nqhvwe` until you merge it. Either
  merge to `main` first or clone that branch (`git clone -b claude/festive-maxwell-nqhvwe …`) and say so in the prompt.
- **Choose the permission mode deliberately.** A mode that never prompts lets the agent run any command; the rules above are
  then the only guard. The box holds no personal data and has no write access to GitHub, no DNS or Cloudflare token, and
  no route to the NAS, which is why this is acceptable here. It would not be acceptable on your PC.
- **Check-ins that need you:** the EULA, the Gmail app password file, DNS records, the seed (H1), go-live (H2), teardown (H3).
- **If it stalls:** read `PROGRESS.md` first. The agent writes there before and after every phase.
