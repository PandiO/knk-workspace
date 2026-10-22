# Performance metrics, capacity and the NAS-vs-cloud decision

**Status:** Draft v1 (2026-10-22) — written for review, **not yet followed on the NAS**. The in-game/API metric
endpoints it relies on are being built under [KNG-232](https://linear.app/kngpandi/issue/KNG-232) and are **not on
trunk**; § 5 says how to use the guide before they land.
**Last updated:** 2026-10-22
**Applies to:** the closed-alpha NAS stack ([runbook](closed-alpha-deployment-runbook.md)): Paper 26.3 in a Docker
container, knk-web-api, MySQL, all on one shared host (Ryzen 7 5700G, ~15 GiB RAM, Frigate also running; see the
[infrastructure report](../reports/2026-10-11-closed-alpha-infrastructure-progress.md) § 2).
**Sources:** code audit of knk-plugin `main` `857d4b1e` and knk-web-api `master` `2d71155` on 2026-10-22 (what is
and is not measured, § 1); the production guide's [monitoring section](production-installation.md#123-monitoring-minimum-viable)
and finding G10.

Goal: collect enough data during the alpha to (1) decide **quickly** whether the Minecraft server must leave the
NAS, and (2) build **scaling curves** (resource use and tick time against players online) and **acceptance
thresholds** that later sizing decisions can reuse.

---

## 1. What is measured today (audit, 2026-10-22)

| Layer | Measured now | Gap |
|---|---|---|
| Paper server | Nothing is exported. The plugin reads `Bukkit.getTPS()` only to throttle its own work (`utils/TickBudget.java`, `gates/GateAnimationTask.java`) | No TPS/MSPT history, no heap/GC/off-heap, no per-world chunks/entities |
| knk-plugin | `telemetry:` and `world-analytics:` are *behavioural* (events, heatmaps, funnels). No API latency, no task timings | Cannot tell which plugin feature costs tick time |
| knk-web-api | OpenTelemetry: ASP.NET Core request count/duration + custom meters (lootbox, currency, statistics, telemetry queue) | No runtime/GC/thread-pool, no process memory/CPU, no outbound HTTP, no DB command timing. `Telemetry:Prometheus:Endpoint` (`/metrics`) is configured but **no exporter is wired** (G10 in the production guide; the API `CLAUDE.md` was wrong). OTLP goes to `localhost:4317` where nothing listens |
| MySQL | Nothing | Connections, slow queries, buffer pool |
| Container / host | Portainer's live stats only (no history) | No history, no per-container CPU/RAM over time, no view of Frigate's share of the host |

## 2. Why "the container hit its max RAM" needs diagnosing first

A container limit (the plan was `Xmx=4G` and a ~5 GiB cgroup limit) counts more than the Java heap. Which of these
is growing decides whether you need a bigger box, a different configuration, or neither:

| Consumer | Counted in the container? | Typical cause | How to see it |
|---|---|---|---|
| Java heap | yes | `Xms`/`Xmx`, `-XX:+AlwaysPreTouch` commits it all at start | `knk_jvm_memory_bytes{area="heap"}` or `jcmd <pid> GC.heap_info` |
| Metaspace, code cache, thread stacks | yes | many plugins/classes | JVM memory pools, NMT (below) |
| **Direct/native memory** (Netty buffers, Paper chunk I/O, compression) | yes | grows with players and chunk loading; **not limited by `Xmx`** | `knk_jvm_buffer_pool_bytes{pool="direct"}`, NMT |
| **Page cache** (the 6.5 GiB world files read from disk) | **yes, but reclaimable** | cgroup usage counts file cache; the kernel drops it under pressure | `memory.stat`: `file`/`inactive_file` vs `anon` |

Rule of thumb: **judge the container by its working set** (usage minus `inactive_file`, what cAdvisor reports as
`container_memory_working_set_bytes`), not by raw `memory.current`. A container sitting at 100% "usage" that is
mostly cache is healthy; one whose `anon` memory reaches the limit gets OOM-killed. Quick check on the NAS, today,
no code needed:

```bash
# per-container snapshot (docker stats already subtracts the cache on current Docker versions)
docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.PIDs}}'

# inside the Minecraft container: cgroup v2 breakdown (anon = real, file = cache)
docker exec <mc-container> sh -c 'cat /sys/fs/cgroup/memory.current /sys/fs/cgroup/memory.max; grep -E "^(anon|file|inactive_file|kernel|sock) " /sys/fs/cgroup/memory.stat'

# JVM native-memory breakdown (needs -XX:NativeMemoryTracking=summary at start, see § 3.3)
docker exec <mc-container> jcmd $(docker exec <mc-container> pgrep -f paper | head -1) VM.native_memory summary
```

## 3. Quick wins that need no code (do these first, today)

### 3.1 Paper's own tools
- `/tps` and `/mspt` in the console: 1/5/15-minute TPS and tick-duration percentiles. Note them with the player
  count every time you look.
- **spark** (the profiler plugin; install the Paper build for 26.3 from its project page and check it supports
  your build): `/spark profiler start`, play for 5–10 minutes, `/spark profiler stop` gives a web report showing
  *which plugin or system* eats the tick. `/spark healthreport` summarises TPS, CPU, memory and disk.
  Use it after every load test — it answers "what is slow", which the metrics below only localise to a feature.

### 3.2 A zero-install history for the container
Until Prometheus is up, log the container's stats to CSV so you have data when you decide:

```bash
# run in tmux/screen on the NAS; one line per 15 s per container
while true; do
  docker stats --no-stream --format '{{.Name}},{{.CPUPerc}},{{.MemUsage}},{{.PIDs}}' |
    sed "s/^/$(date -Is),/" >> /srv/knk-metrics/docker-stats.csv
  sleep 15
done
```
Also write down the **player count** (`/list`) at the start and end of each session — without it the CSV cannot
become a scaling curve.

### 3.3 JVM flags worth adding to the Minecraft container now
Add to the container's Java flags (the exact variable depends on the image, e.g. `JVM_OPTS`/`JAVA_OPTS`; **change
the flags in the Portainer stack, not by hand on the host — see the [A6 finding](../reports/2026-10-18-nas-ops-access-and-alpha-check.md)
about two copies of the compose definition**):

```text
-Xms4G -Xmx4G                       # fixed heap: no resize noise in the curves. Size from § 6, not from habit.
-XX:MaxDirectMemorySize=1G          # a cap that fails loudly instead of eating the container (tune from the data)
-XX:NativeMemoryTracking=summary    # enables `jcmd ... VM.native_memory`; ~5-10% overhead, drop it later
-Xlog:gc*:file=/data/logs/gc.log:time,uptime,level,tags:filecount=5,filesize=10m
-XX:StartFlightRecording=maxage=6h,disk=true,dumponexit=true,filename=/data/logs/knk.jfr   # low-overhead flight recorder
```
The container memory limit should be `Xmx` + ~1 GiB direct + ~0.5–1 GiB metaspace/threads/code, i.e. roughly
`Xmx + 2 GiB` for a start; the GC log and NMT then show where that is wrong. If heap *live set after GC* stays far
below `Xmx`, lower `Xmx` — a smaller heap leaves room for the page cache the world files want.

## 4. The measurement stack

```
 Paper+knk-plugin ──:9225/metrics──┐
 knk-web-api ──────:5294/metrics───┤
 cAdvisor (per container) ─────────┼──► Prometheus (15 s scrape, 30 d) ──► Grafana
 node-exporter (host: CPU/RAM/disk)┤
 mysqld-exporter (optional) ───────┘
```

Put the stack on the **NAS** if you want one place (Prometheus ~200–400 MiB RAM at this size, Grafana ~150 MiB;
include them in the budget you are measuring) or on your **PC** scraping the NAS over the LAN to keep the NAS
clean. Never publish these ports to the internet; the NAS's Cloudflare/nginx ingress must not route `/metrics`.

### 4.1 Compose sketch (a separate Portainer stack, e.g. `knk-monitoring`)

```yaml
services:
  prometheus:
    image: prom/prometheus:latest        # pin a version when you commit this
    command: ["--config.file=/etc/prometheus/prometheus.yml", "--storage.tsdb.retention.time=30d"]
    volumes: ["./prometheus.yml:/etc/prometheus/prometheus.yml:ro", "prom_data:/prometheus"]
    ports: ["127.0.0.1:9090:9090"]
    restart: unless-stopped
  grafana:
    image: grafana/grafana:latest
    volumes: ["grafana_data:/var/lib/grafana"]
    ports: ["127.0.0.1:3000:3000"]       # reach it over the existing SSH/Tailscale/LAN route
    restart: unless-stopped
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    volumes: ["/:/rootfs:ro", "/var/run:/var/run:ro", "/sys:/sys:ro", "/var/lib/docker/:/var/lib/docker:ro"]
    restart: unless-stopped
  node-exporter:
    image: prom/node-exporter:latest
    pid: host
    volumes: ["/:/host:ro,rslave"]
    command: ["--path.rootfs=/host"]
    restart: unless-stopped
volumes: { prom_data: {}, grafana_data: {} }
```

`prometheus.yml`:

```yaml
global: { scrape_interval: 15s }
scrape_configs:
  - job_name: cadvisor
    static_configs: [{ targets: ["cadvisor:8080"] }]
  - job_name: node
    static_configs: [{ targets: ["node-exporter:9100"] }]
  - job_name: knk-plugin            # KNG-232, § 5.1
    metrics_path: /metrics
    authorization: { type: Bearer, credentials_file: /etc/prometheus/plugin.token }
    static_configs: [{ targets: ["<docker-host-ip>:9225"], labels: { server: "main" } }]
  - job_name: knk-api               # KNG-232, § 5.2
    metrics_path: /metrics
    authorization: { type: Bearer, credentials_file: /etc/prometheus/api.token }
    static_configs: [{ targets: ["<api-container>:8080"] }]
```
The target hosts/ports above are placeholders: use the networks and ports of your actual Portainer stacks.

### 4.2 Panels to build first (PromQL)

| Panel | Query | Why |
|---|---|---|
| Players online | `knk_mc_players_online` | the x-axis of every curve |
| TPS | `knk_mc_tps{window="1m"}` | acceptance: ≥ 19.5 |
| Tick time p95 / max | `knk_mc_tick_duration_seconds{stat=~"p95\|max"}` | the real headroom (50 ms budget) |
| Heap after GC | `knk_jvm_memory_bytes{area="heap",type="used"}` (look at the troughs) | live set → sizing `Xmx` |
| Off-heap | `knk_jvm_buffer_pool_bytes{pool="direct",type="used"}` + non-heap | the part `Xmx` does not cap |
| Container working set | `container_memory_working_set_bytes{name="<mc-container>"}` | what the limit really sees |
| Cores used by Minecraft | `rate(container_cpu_usage_seconds_total{name="<mc-container>"}[1m])` | CPU cost; also see the main-thread line below |
| Host contention | `1 - avg(rate(node_cpu_seconds_total{mode="idle"}[1m]))` and Frigate's container CPU | proves/disproves "the NAS is the problem" |
| API latency p95 | `histogram_quantile(0.95, sum by (le)(rate(http_server_request_duration_seconds_bucket[5m])))` | API health vs load |
| Plugin → API latency | `histogram_quantile(0.95, sum by (le,route)(rate(knk_api_call_duration_seconds_bucket[5m])))` | slow endpoints that stall features |
| Plugin task cost | `rate(knk_task_duration_seconds_sum[1m])` per `task` | seconds of work per second = share of one tick thread |
| GC pause share | `rate(knk_jvm_gc_seconds_total[1m])` | GC stalls show up as tick spikes |

## 5. What KNG-232 adds (and how to use the guide before it lands)

### 5.1 knk-plugin — `metrics:` section (default **off**)
A Prometheus text endpoint on its own port (not the region-callback server, which is for the API and uses the
plugin API key). Config, as built — see the plugin's `config.yml`:
`metrics.enabled`, `metrics.bind-address` (default `127.0.0.1`; use the Docker host/bridge IP for a scraper in
another container, never `0.0.0.0` on a public server), `metrics.port` (default `9225`), `metrics.token` (bearer
token; required whenever the address is not loopback), `metrics.sample-seconds`.
Collected: TPS (1/5/15 min), tick duration avg/p95/max, players, loaded chunks and entities per world, JVM
heap/non-heap/pools/direct buffers/GC/threads, process and system CPU, load average, **process RSS and cgroup
memory (usage, working set, limit, CPU throttling)**, API-call duration histograms by method + route template
and outcome, and duration histograms for the plugin's own recurring tasks.

### 5.2 knk-web-api — real `/metrics`
`Telemetry:Prometheus:Enabled` now actually maps a scrape endpoint (default off; requires a bearer token outside
Development) and the meters gain .NET runtime (GC, heap, thread pool), process CPU/memory + cgroup limit,
outbound HttpClient, and DB command duration. See `knk-web-api/OBSERVABILITY.md`.

### 5.3 Before those branches are deployed
Use § 3 plus cAdvisor/node-exporter from § 4 (they need no KnK code) and record players online by hand. That is
already enough for the NAS-vs-cloud decision in § 7.

## 6. Turning data into scaling curves and acceptance thresholds

### 6.1 Collect on a schedule, not by accident
Per session record: date, build (plugin/API commits), `view-distance`/`simulation-distance`, players online
(Prometheus has it), and what was going on (siege running? gate animations? teleport storm? world-task
processing?). Tag sessions with Grafana annotations.

### 6.2 Load steps
Real alpha numbers will be small, so add **synthetic** steps on a *staging copy* (a restored DB backup on a
separate DB, never the alpha DB): 5 → 10 → 20 → 40 → 60 players, 10 minutes each, holding constant behaviour
(walk/fly along set routes, open menus, run commands), then one **event step** (siege or mass teleport). Bots
(for example a Mineflayer-style scripted client — pick a tool that supports your protocol version) need accounts
the server accepts; the plugin's account-link/admission flow will treat them like strangers. **Open decision:**
whether a load-test mode (allow-list or bypass) is wanted or the staging server runs with admission off.
No such mode exists today; file it before building bots.

### 6.3 Reading the results
For each step take the steady last 5 minutes and write one row:

| Players | TPS 1m | Tick p95 | Tick max | Heap live (post-GC trough) | Off-heap | Container working set | MC cores | Host idle % | API p95 |
|---|---|---|---|---|---|---|---|---|---|

Per-player cost = the slope of a linear fit of each column against players (slope = marginal cost, intercept =
fixed cost of the world, plugins and JVM). The **intercept matters as much as the slope** here: a 6.5 GiB world
and ~dozens of plugins have a high fixed cost, and a small alpha shows mostly that.

### 6.4 Acceptance thresholds (proposed; adjust after the first runs)
| Metric | Green | Amber | Red |
|---|---|---|---|
| TPS (1 m) | ≥ 19.8 | 19–19.8 | < 19 |
| Tick time p95 | < 35 ms | 35–45 ms | > 45 ms (50 ms is the whole budget) |
| Tick time max | < 100 ms | 100–500 ms | > 500 ms (players see a freeze) |
| Heap live set after GC | < 60% of `Xmx` | 60–75% | > 75% (GC thrash risk) |
| Container working set | < 80% of limit | 80–90% | > 90% |
| Minecraft main thread | < 60% of one core | 60–80% | > 80% (the tick loop is single-threaded) |
| Host CPU idle (shared host) | > 30% | 15–30% | < 15% |
| Plugin→API p95 | < 200 ms | 200–500 ms | > 500 ms (features that wait on the API) |

The first three are what players feel; the rest tell you *why*. These numbers are starting points, not measured
facts — replace them with the alpha's own once you have runs.

## 7. NAS vs cloud VM — a quick, informed decision

**The question the data must answer:** is the NAS limited by the box (CPU/RAM contention, no headroom) or by our
configuration (heap too large, view/simulation distance, a runaway plugin task)? Moving a mis-configured server to
a cloud VM only moves the problem and adds a bill.

Decision procedure (about one evening of data):
1. **Diagnose the RAM event** (§ 2). Working set vs limit, heap trough, direct memory. If `anon` is far below the
   limit and the "usage" was cache → not a capacity problem.
2. **Set the plan's reduced settings** first (the infra report already flags view 25 / simulation 10 as too high for
   a shared NAS): e.g. view 8–10, simulation 5–6, then run § 3 and one § 6.2 ladder.
3. **Read the verdict:**
   - Tick p95 green and host idle > 30% at your expected alpha size → stay on the NAS, keep the monitoring.
   - Tick p95 amber/red *and* host CPU idle low while Frigate is busy → the shared host is the limit: move.
   - Tick p95 red with the host mostly idle → the main thread is the limit (single core speed or a heavy
     plugin task): `/spark` the plugin, and a faster-clocked VM helps, more vCPUs do not.
   - Working set near the limit with `anon` growing steadily → leak or undersized limit: fix/raise, then re-test.
4. **If moving, size from the curve:** RAM ≈ `Xmx` + ~2 GiB overhead + headroom for the OS/page cache (plan on the
   world size for the hot part); CPU: prefer **few fast cores** (high single-thread clock, dedicated rather than
   burstable vCPUs) over many slow ones; keep MySQL and the API either on the VM with their own limits or remote
   (then include the network hop in the plugin→API latency). Compare current provider prices for 4–8 GiB / 2–4
   fast vCPU instances against the NAS's value — this guide deliberately gives no prices; they change.
5. Re-run the ladder on the VM before cutting over and compare rows from § 6.3 side by side.

## 8. Open items

- [KNG-232](https://linear.app/kngpandi/issue/KNG-232): build the plugin and API endpoints (this guide's § 5). Both
  branches are unmerged and need a live check on the dev server and the NAS.
- Load-test mode for bots (§ 6.2): not designed, not filed.
- Dashboards-as-code and alert rules (disk, working set > 90%, TPS < 18 for 5 min): out of scope for KNG-232.
- The `knk-web-api/CLAUDE.md` `/metrics` claim and `production-installation.md` G10/§ 12.3 are corrected once the
  API branch merges.
