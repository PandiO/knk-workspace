# Bedrock console access — feasibility and smooth onboarding

**Status:** Research documented; recommendation proposed; no deployment or console validation performed  
**Last updated:** 2026-10-06  
**Owner:** Pandi  
**Scope:** Console access to the existing Java/Paper KnK server through Geyser/Floodgate  
**Branch:** `codex/bedrock-console-access`  
**Related issue:** None created for this documentation task

## 1. Confirmed requirement and decision boundary

Pandi explicitly requires a smooth, as-close-to-native-as-possible join-and-play experience. Asking ordinary players to change DNS settings is not an acceptable primary onboarding route. KnK will use a public domain; the example supplied was `play.knightsanskings.net`. Preserve this as an example, not a verified registered domain or deployed endpoint; confirm its intended spelling before configuration.

KnK remains Java/Paper-first. The development constraint is one developer assisted by AI agents, with a possible standalone game in the longer term. Avoid creating a second Bedrock gameplay implementation merely to solve console discovery.

**Recommendation, not an approved deployment decision:** test a KnK-owned Microsoft/Xbox friend-session broadcaster alongside Geyser/Floodgate. If its unofficial status or operational reliability is unacceptable, investigate official featured-server distribution. Do not advertise effortless console support before real-device validation.

This refines the earlier feasibility recommendation: protocol compatibility alone does not satisfy the console UX requirement. The initial discussion also omitted the server-operated Friends-menu route; DNS changes and player-side companion apps are not the only possibilities.

## 2. Separate the three problems

1. **Game compatibility:** Geyser translates Bedrock clients into the existing Java runtime; Floodgate supports Bedrock authentication without a second Java licence.
2. **Console discovery/connection:** the console must offer a way to initiate a connection to the Geyser endpoint.
3. **Gameplay usability:** menus, identity, inventory, gates, combat and presentation still require Bedrock/controller tests after joining.

A public domain addresses naming/routing, not the missing arbitrary-server entry interface on consoles. Running native Bedrock Dedicated Server would not itself grant a featured listing or remove that interface restriction. [S1–S4]

## 3. Options compared

| Route | First visit | Returning visit | Operator work | Assessment |
|---|---|---|---|---|
| KnK-owned friend-session broadcaster | Add the designated KnK Microsoft/Xbox account; find its session | Select the joinable KnK session from Friends | Operate Geyser/Floodgate and broadcaster; manage account health/friends | Best practical candidate for a pilot; unofficial and unverified on KnK |
| Official featured-server distribution | Find KnK inside the Servers tab | Select and join | Establish official commercial/technical relationship | Best native distribution fit; acceptance and terms unknown |
| Existing featured partner hosts/distributes KnK | Depends on the partner's lobby and integration | Enter through partner experience | Negotiate hosting, identity, economics and content integration | Business hypothesis only; no willing partner or agreement identified |
| Phone companion application | Install/configure app; follow console-specific steps | Use app to expose connection, then join | Maintain instructions and support external app behaviour | Optional fallback; recurring friction |
| DNS/BedrockConnect | Change console DNS and enter redirected server list | Reuse redirected entry/list | Support DNS/network troubleshooting | Does not meet the primary UX requirement |
| Bedrock Realm | Realm invitation/native entry | Select Realm | Different hosted game environment | Not a host for the current Paper plugin; not an established gateway solution here |

The external routes and their actual limitations are documented by their maintainers, not guaranteed by this report. [S2–S6]

## 4. Candidate A: KnK-owned Friends-menu broadcaster

[MCXboxBroadcast](https://github.com/MCXboxBroadcast/Broadcaster) advertises an existing Geyser/Bedrock endpoint through an authenticated Microsoft/Xbox account as a joinable session. It can run as a Geyser extension or separately; the project documents Docker support, automatic friend management and multiple accounts. [S3]

### Intended player journey

1. Follow KnK's short console onboarding page.
2. Add KnK's designated account as a friend. A name such as “KnK Join” is illustrative; no account or gamertag has been registered.
3. Open Minecraft's Friends menu and select the advertised KnK session.
4. Enter the same KnK world and matches as Java players through Geyser.

The broadcaster runs on KnK infrastructure. Players should not need DNS changes, a companion phone application or a personal PC for this route. Exact menu labels, friendship behaviour and availability must be tested per console. Xbox Live here is the cross-platform Microsoft account/session mechanism, not proof that the approach is limited to Xbox hardware.

### Material limitations

- The project warns that it emulates client features, may conflict with terms and may expose its broadcasting account to a ban. No official platform approval was established.
- Public BedrockConnect friend bots were disabled according to its README, citing scaling and security concerns. Do not depend on those public bots for KnK.
- A privately operated broadcaster is a candidate, not proof that these concerns disappear.
- Authentication expiry, session visibility, friendship processing, account limits and service changes can affect joining. Exact capacity/rate limits were not verified; do not invent a supported player count.
- Platform multiplayer permissions, parental controls and any required online subscription remain relevant.
- If the broadcaster is unavailable, Java and directly connected Bedrock clients may still work while new console joins fail. Test this explicitly rather than assuming its effect on established sessions.

These qualifications distinguish a native-looking player interface from an officially supported distribution mechanism. [S3, S4]

### Proposed operating design

Use a designated server-owned broadcasting account, with credentials/session tokens kept out of source control. Advertise KnK's own Geyser endpoint directly; a generic third-party server-selection menu is unnecessary for a single-server journey.

Choose either the Geyser extension for a simple pilot or a separate service for operational isolation. Monitor account authentication, advertised session visibility and real join success. Only introduce multiple broadcaster accounts if measured demand and platform constraints require it; account proliferation should not be treated as a way around enforcement.

## 5. Candidate B: official featured-server distribution

Minecraft documents partner/featured servers inside Bedrock's Servers tab. This supplies the desired discoverability and native entry point. [S6]

What was **not** established:

- A guaranteed public application route or acceptance timeline for KnK.
- Minimum audience, staffing, moderation or uptime requirements.
- Whether the proposed Geyser architecture would be accepted.
- Fees, revenue shares, permitted payment methods or Minecoin arrangements.
- Whether KnK can be distributed through an existing partner while retaining the current backend and branding.

The public Minecraft Partner Program page describes Marketplace content sales and reviewed submissions; it must not be presented as a guaranteed featured-server application. [S7]

If pursued, prepare a product demonstration and ask the appropriate Minecraft partnership contact about server eligibility, console reach, technical certification, operational duties and commercial terms. A distribution agreement with an existing featured server is another commercial avenue to investigate, not a confirmed technical shortcut.

## 6. Fallbacks and console differences

| Console family | Friends-session route | Companion route documented by provider | Validation status |
|---|---|---|---|
| Xbox One / Series | Candidate for testing | Phone exposes server as LAN game | Not tested for KnK |
| PlayStation 4 / 5 | Candidate for testing with linked Microsoft account and appropriate permissions | Phone exposes server as LAN game | Not tested for KnK |
| Nintendo Switch | Candidate for testing; do not assume LAN parity | BedrockTogether documents Xbox Live broadcasting rather than the Xbox/PlayStation LAN method | Not tested for KnK |

This matrix is a test plan, not a compatibility certification; do not extend it to other models without testing.

Companion apps avoid DNS changes but require external setup and often recurring user action. DNS-based BedrockConnect redirects selected featured-server destinations to a server list; Geyser's console documentation notes blocking of some public DNS endpoints. Both should remain optional fallback instructions rather than the advertised KnK onboarding flow. [S2, S4, S5]

Realms are a separate hosting product. This study establishes neither Paper compatibility nor a reliable Realm-to-KnK transfer gateway. Do not promise that purchasing a Realm solves access to the existing Java game.

## 7. Public-domain and endpoint design

The same hostname can identify the Java server and Geyser if the networking is configured accordingly:

| Client/path | Illustrative destination | Purpose |
|---|---|---|
| Java | `play.knightsanskings.net`, usually TCP 25565 | Existing Paper connection |
| Bedrock direct | Same hostname, Geyser UDP port, commonly 19132 | Windows/mobile connection and underlying console destination |
| Console friend session | Advertised KnK Geyser destination | Avoid requiring a player to enter an address on console |

Defaults are examples, not deployed settings. Confirm DNS resolution, public reachability and UDP allocation in the firewall/container/hosting configuration. A Java-only TCP endpoint is insufficient. A domain record or Java SRV configuration does not create a console server-list button. The broadcaster advertises a session; it does not replace Geyser's protocol translation. [S1, S3]

## 8. Relationship to the broader feasibility and gap analysis

The preferred gameplay architecture remains one Paper server plus Geyser/Floodgate, sharing KnK rules, API and persistence. Separate native Bedrock codebases would multiply runtime work without independently resolving distribution.

Carried-forward gaps from the earlier 2026-10-06 static assessment:

- Canonical identity and Java/Bedrock linking, including paid entitlements and inventory mapping.
- Controller/touch alternatives for Java-specific menu gestures and chat confirmations.
- Mixed-client Siege, gate collision, combat, respawn and inventory restoration.
- Bedrock presentation/resource mappings where necessary.
- Supported protocol versions, update regression checks and rollback.
- Real-money checkout/fulfilment and catalogue review before sales.

These are previous assessment findings, not newly tested implementation results. The current task documents console access and changes no gameplay code.

Independent server monetization, official featured-server distribution and Marketplace content sales are different routes. A working friend broadcaster supplies neither official endorsement nor automatic commercial clearance. Review current Minecraft server monetization rules and any distribution contract before launch. [S7, S8]

## 9. Bounded pilot and acceptance criteria

### Suggested sequence

1. Configure an isolated staging Paper/Geyser/Floodgate server and verified public UDP endpoint.
2. Configure one KnK-owned broadcaster using supported project instructions.
3. Recruit a tester for each console family KnK intends to advertise.
4. Run first-visit and returning-user tests with no previously configured custom DNS or companion app.
5. Evaluate technical reliability and whether the unofficial dependency is acceptable before declaring support.

### Required evidence

- A new user can add KnK and join with brief written instructions and no network-setting changes.
- Returning users can find and join from the normal Friends interface.
- Repeat joins succeed after client, broadcaster and game-server restarts.
- Friendship/session discovery delay is recorded; authentication recovery is documented.
- Test two different home networks and relevant account/privacy settings.
- Verify concurrent joins and measure scaling before publishing a capacity claim.
- Complete a controller-driven core KnK journey: menu, kit, Siege entry, gate/objective interaction, death/respawn and rewards.
- Confirm nobody is granted a different KnK identity, inventory or purchase entitlement accidentally.
- Record exact console model, Minecraft build, Geyser/Floodgate/broadcaster versions, steps and outcome.

Proposed UX target for review: once ordinary Minecraft sign-in/multiplayer prerequisites are satisfied, first setup should require only adding the KnK account and selecting Join; future visits should require only selecting the visible session. No timing or success-rate promise is made before measurement.

**Stop condition:** if a target console consistently needs DNS/app assistance, or the broadcaster's risk is unacceptable, do not label that platform smooth/native-access supported. Continue Java and direct Bedrock access while pursuing official distribution.

## 10. Open decisions and handoff

| Decision | Current state |
|---|---|
| Is a native-looking but unofficial Friends route acceptable? | User requires smooth UX; acceptance of this dependency remains open |
| Which console models are launch requirements? | Not selected |
| Exact domain spelling and endpoint ownership | User example retained; not verified |
| Extension versus standalone broadcaster | Proposed pilot implementation choice |
| Account ownership, recovery and support responsibility | Must be assigned before deployment |
| Official partnership outreach | Research option only; no contact made |
| Deployment / implementation authorization | This task authorizes documentation and repository push only |

**Verification performed:** source documentation reviewed earlier in this conversation on 2026-10-06; report reviewed for distinction between user requirements, recommendations and unverified claims. No console, network or gameplay test performed.

**Next concrete step:** a small real-device broadcaster pilot, followed by a decision on whether its reliability and unofficial status satisfy the user requirement. Preserve one Java gameplay implementation while evaluating access.

## Sources

Reviewed 2026-10-06. Recheck changing platform behaviour before implementation.

- **S1:** [Geyser FAQ](https://geysermc.org/wiki/geyser/faq/) — protocol direction, hostname/Bedrock port and UDP.
- **S2:** [Geyser console guide](https://geysermc.org/wiki/geyser/using-geyser-with-consoles/) — console workarounds and DNS limitations.
- **S3:** [MCXboxBroadcast/Broadcaster](https://github.com/MCXboxBroadcast/Broadcaster) — friend sessions, extension/standalone setup, account management and explicit risk disclaimer.
- **S4:** [Pugmatt/BedrockConnect](https://github.com/Pugmatt/BedrockConnect) — DNS and friend methods; public bot suspension.
- **S5:** [BedrockTogether](https://bedrocktogether.net/) and [Switch instructions](https://bedrocktogether.net/how-to-join-minecraft-server-nintendo-switch/) — companion methods and console differences.
- **S6:** [Minecraft servers](https://www.minecraft.net/en-us/servers) — in-game featured server discovery.
- **S7:** [Minecraft Partner Program](https://www.minecraft.net/en-us/partner) — Marketplace programme, not guaranteed server placement.
- **S8:** [Minecraft Usage Guidelines](https://www.minecraft.net/en-us/usage-guidelines) — server monetization conditions.
