# NAS vs rented server — fallback hosting options and costs — 2026-10-22

**Status:** Complete — research snapshot; prices must be re-checked before any purchase
**Last updated:** 2026-10-22
**Related issues:** [KNG-241](https://linear.app/kngpandi/issue/KNG-241) (this fallback plan),
[KNG-232](https://linear.app/kngpandi/issue/KNG-232) (measurements and the NAS-vs-cloud decision),
[KNG-225](https://linear.app/kngpandi/issue/KNG-225) (Minecraft container on the NAS)
**Related docs:** [performance metrics, capacity and the NAS-vs-cloud decision](../guides/performance-metrics-and-capacity.md)
(§ 7 says when to move and deliberately lists no prices), [closed-alpha runbook](../guides/closed-alpha-deployment-runbook.md),
[infrastructure progress report](2026-10-11-closed-alpha-infrastructure-progress.md) § 2 (host capacity)

Developer question (2026-10-22): the empty Minecraft container already used about 4 of its 5 GB on the 16 GB NAS,
which also runs an NVR with four constantly streaming cameras. What are the options and costs for renting a server
for the API, web app and Minecraft server if the NAS cannot carry about 8 players? This report answers the
options and cost half. **It is not a recommendation to move.** The decision belongs to the KNG-232 measurements.

## 1. Summary

- **Do not rent anything yet.** The "4/5 GB on an empty server" reading is not yet evidence of a capacity problem
  (§ 2). Run the KNG-232 procedure first (reduced view/simulation distance, one load ladder, then read the verdict).
- **If the verdict is "move", the cheapest credible target is an OVH VPS-3 or VPS-4** (about $12–23/month), with the
  caveat that shared vCPUs may tick *slower* than the NAS CPU (§ 2). The **guaranteed-performance target is a Hetzner
  dedicated server** (AX42, €79–99/month plus a one-off €49 setup).
- A rented box can be bought for one month to test: the Hetzner AX page lists no minimum contract period and
  immediate cancellation. For AX42 the one-off €49 setup fee applies; AX41 has none.
- Every figure below is a vendor "from" price read on 2026-10-22, excluding VAT, and none was tested with the KnK
  stack. They move often: Hetzner repriced its cloud lines on 2026-04-01 and 2026-06-15 (third-party reports), and
  its cloud plans showed "unavailable" when read.

## 2. Is the NAS actually the limit? (what to check before paying)

Facts from the repo ([infrastructure report § 2](2026-10-11-closed-alpha-infrastructure-progress.md)): the host is an
**AMD Ryzen 7 5700G** (8 cores / 16 threads, boost to 4.67 GHz), 14.92 GiB usable RAM, 8 GiB swap, with Frigate using
about 2.3 GiB RAM and about 190% CPU during samples. The runbook sets Minecraft to `MEMORY=4G` with a container limit of
about 5 GiB, and the dev server's view distance 25 / simulation distance 10 was already flagged as too aggressive.

What this means for the fallback decision (analysis, not measurement):

1. **A JVM that reaches its limit early is not by itself a problem.** `MEMORY=4G` makes `Xmx` 4 GiB, and a Java
   heap fills before the garbage collector reclaims it; page cache and direct memory also count against a container
   limit. The KNG-232 guide § 2 explains how to tell working set from cache. Check that before concluding RAM is short.
2. **The Minecraft main thread is single-threaded**, so single-core speed matters more than core count. The 5700G is a
   fast Zen 3 core. A **shared** vCPU on a budget VPS is often slower and less consistent, and the cheapest providers
   oversubscribe cores. A rented box can therefore fix *contention* (Frigate competing for the CPU) but may do nothing, or make
   things worse, if the real limit is the main thread. KNG-232 § 7 step 3 distinguishes the two cases.
3. **A dedicated AX41 is not clearly faster per core than the NAS.** Its Ryzen 5 3600 (Zen 2, 6 cores) is an older
   core than the 5700G (Zen 3). The AX42 (Ryzen 7 8700GE, Zen 4) is the first Hetzner option I would expect to be
   faster per core; confirm with a test month and a load ladder rather than relying on this.

## 3. What the full stack needs

My estimate for API + web + Minecraft + MySQL on one machine, to be replaced by the KNG-232 curve:

| Component | RAM (estimate) |
|---|---|
| Minecraft (heap 4 GiB + overhead) | 5–6 GB |
| MySQL 9.6 | 0.5–1 GB |
| knk-web-api | 0.3–0.6 GB |
| Web app, nginx, cloudflared | under 0.5 GB |
| OS and page cache | 1–2 GB |

That totals roughly 7–10 GB, so an **8 GB machine is too small, 12 GB is the practical minimum and 16 GB or more is
comfortable.** KNG-232 § 7 step 4 gives the sizing rule (heap + about 2 GiB overhead + OS/page-cache headroom).

## 4. Options and prices

All prices excl. VAT. "Verified" means read from the vendor's own page on 2026-10-22.

### 4.1 Virtual servers

| Option | Spec | Price / month | Per year | Status of the figure |
|---|---|---|---|---|
| OVHcloud VPS-2 | 4 vCPU, 8 GB, 75 GB NVMe | from $8.50 | $102 | Verified; **too little RAM** |
| OVHcloud VPS-3 | 6 vCPU, 12 GB, 100 GB NVMe | from $12.32 | $148 | Verified; minimum viable |
| OVHcloud VPS-4 | 8 vCPU, 24 GB, 200 GB NVMe | from $23.37 | $280 | Verified; unlimited traffic, 3 Gbps, anti-DDoS and previous-24-h backup included. CPU model not listed |
| Contabo VPS | 4 vCPU, 8 GB | about $7 | about $84 | **Unverified** (third-party index; the vendor page returned 403). Heavily oversubscribed cores; not recommended |
| Hetzner Cloud CPX32 | 4 vCPU, 8 GB, 160 GB | €35.99 | €432 | Verified, but **8 GB is too small** and the plan showed "currently unavailable" |
| Hetzner Cloud CPX42 | 8 vCPU, 16 GB, 320 GB | €69.99 | €840 | Verified; showed "currently unavailable" |
| Hetzner Cloud CCX23 (dedicated vCPU) | 4 vCPU, 16 GB, 160 GB | €86.49 | €1,038 | Verified; poor value after the 2026 repricing |

OVH "from" prices may assume a commitment term, region or option set that I could not see; confirm at checkout. The OVH
page lists no regions in the text I could read.

### 4.2 Dedicated servers (Hetzner, 1 Gbit/s, unlimited traffic, IPv4 included)

| Option | Spec | Price / month | One-off setup | First year |
|---|---|---|---|---|
| AX41 | Ryzen 5 3600 (6 cores), 64 GB DDR4, 2×512 GB NVMe | €59 | €0 | €708 |
| AX42 | Ryzen 7 8700GE (8 cores, Zen 4), 64 GB DDR5 ECC, 2×1.92 TB (up to 2×7.68 TB) | €79–99 | €49 | €997–1,237 |
| Server auction | varies | from about €68 | €0 | about €816+ |

The auction listings could not be read (the page did not expose offers); check the hardware before buying. The AX41
and AX42 have far more RAM than this stack needs, and that headroom is the main thing the extra money buys.

### 4.3 Other options considered

- **Managed Minecraft host (about $20–40/month, an unresearched guess):** ruled out. It cannot run the API, the web
  app or MySQL, and it would have to support Paper 26.3 / Java 25 and the KnK plugin.
- **Hybrid (Minecraft on a VPS, API and MySQL on the NAS):** not recommended. The plugin calls `http://api:5000/api`
  over Docker DNS and the API calls the plugin on `http://minecraft:8081`
  ([runbook Phase 4](../guides/closed-alpha-deployment-runbook.md)). Splitting them needs a private tunnel (Tailscale was
  removed on 2026-10-18) and adds a network hop to every plugin-to-API call. Move the whole stack or none of it.

### 4.4 VAT

All prices exclude VAT. The domains in the docs (`knightsandkings.net`, `oldenzeelit.nl`) suggest the developer is in
the Netherlands, in which case Dutch VAT of 21% would apply to consumer purchases (×1.21). That is an assumption, not
something the repo states; check with the provider's checkout.

## 5. What a move would involve

The stack is Docker Compose with pinned images, file-based secrets and Cloudflare Tunnel ingress, so moving is
mostly copying state:

1. Copy the Compose files, the secret files (re-created, not copied through chat) and the plugin config.
2. Restore the MySQL dump and the world data (converted worlds cannot be downgraded; the 1.21.10 staging sources stay
   the rollback, per the runbook).
3. **Ingress:** a rented box has a public IP, so playit.gg (Phase 5) is not needed. Point
   `play.knightsandkings.net` at the server and open only TCP 25565 and a restricted SSH. Keep the web app behind the
   Cloudflare Tunnel and Access (Phase 6); MySQL, RCON and the API stay unpublished.
4. Keep backups flowing to the NAS (Phase 7); the first restore rehearsal doubles as the migration drill.
5. Re-run the KNG-232 load ladder on the new host and compare it with the NAS rows before cutting over.

The drill is not built; it is tracked in [KNG-241](https://linear.app/kngpandi/issue/KNG-241).

## 6. Recommended path (reversible, in order)

1. **Now, free:** reduce view/simulation distance (for example 8–10 / 5–6), keep `MEMORY=4G` or try 3G, and run the
   KNG-232 diagnosis and one load ladder with Frigate running.
2. **If the verdict says the shared host is the limit:** rent a test month of the AX42 (about €128–148 including setup, excl. VAT),
   or an OVH VPS-4 (about $23) if a cheaper first try is wanted, run the same ladder, then decide. An OVH test
   is cheap but may not answer the single-core question (§ 2.2).
3. **If the main thread is the limit with the host mostly idle:** profile the plugin with spark first. More cores
   will not help.
4. **Cost frame:** about $150–280 a year (OVH VPS-3/4) or about €700–1,240 in the first year (Hetzner dedicated),
   against €0 extra on the NAS.

## 7. Caveats and open items

- Prices are vendor "from" prices read 2026-10-22 by an automated page fetch. They were not checked in an account or at
  checkout, and the Hetzner cloud pages showed every plan as unavailable.
- Two sources reported conflicting Hetzner cloud prices (CX33/CAX21 at €6.49–8.99 / €7.99–10.99); I did not use them
  because those lines showed as unavailable and I could not confirm them. Third-party summaries of the 2026 Hetzner
  repricing disagree with each other.
- No provider has been tested with the KnK stack; per-core speed claims in § 2 are reasoning from CPU generation, not benchmarks.
- Open decision for the developer: whether to rent a test month at all, which depends on the KNG-232 verdict.

## Sources

- [Hetzner Cloud](https://www.hetzner.com/cloud/), [Regular Performance](https://www.hetzner.com/cloud/regular-performance/),
  [General Purpose](https://www.hetzner.com/cloud/general-purpose/)
- [Hetzner AX dedicated servers](https://www.hetzner.com/dedicated-rootserver/matrix-ax/),
  [server auction](https://www.hetzner.com/sb)
- [OVHcloud VPS](https://www.ovhcloud.com/en/vps/), [VPS comparison](https://www.ovhcloud.com/en/vps/compare/)
- Third-party, used only for context and the unverified Contabo figure:
  [Hetzner June 2026 repricing](https://privatedevops.com/news/hetzner-june-2026-cloud-price-increase-what-to-do),
  [Hetzner 2026 price increase](https://findstack.com/resources/hetzner-price-increase-2026),
  [cheapest VPS by price per GB](https://findstack.com/resources/cheapest-vps-hosting),
  [VPS price comparison](https://getdeploying.com/reference/compute-prices)
