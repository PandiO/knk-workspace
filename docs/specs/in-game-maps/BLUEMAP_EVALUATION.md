# In-game maps — BlueMap evaluation (Dynmap vs BlueMap)

**Status:** Evaluated and test-rendered on the NAS (2026-11-10). **BlueMap replaces Dynmap as the map renderer**, confirmed by the developer 2026-11-12 (decisions M2–M4 in [DESIGN.md](DESIGN.md)); follow-ups in §8. No code.
**Last updated:** 2026-11-12 (cave-culling fix for shadowed builds, run 4; first version 2026-11-10)
**Issue:** [PandiO/knk-workspace#224](https://github.com/PandiO/knk-workspace/issues/224)
**Related:** [DESIGN.md](DESIGN.md) (battle map tables), #254 (painted resource map over the web map), #32 (VPS hosting), #41 / #23 (siege), #78, #65, #124, #53 (other map uses)

**Authority:** the developer's conversation of 2026-11-10 and a test render of the alpha world (`world_KNK-DEV`, Minecraft 26.3) on the NAS the same evening. Community storage figures and plugin facts come from public sources checked the same day. Full-world numbers are extrapolated from a 2,000 × 2,000 block sample.

## 1. Problem

A high-res Dynmap render of the 22,000 × 17,000 block world was estimated at **150–300 GB**. The world will grow (the developer wants it larger, possibly split over several worlds), and several planned features need a full web map: siege targeting tables, taxes and trade routes, and the town civ simulator UI.

Rough Dynmap maths: high-res is about 16 × 16 pixels per block, so one 128 px tile covers about 8 × 8 blocks. That gives about 6 million tiles at full zoom, plus about a third more for the zoom-out levels.

- PNG tiles: about 200–300 GB per view angle
- JPG tiles: about 100 GB per view angle
- Each extra view angle (e.g. 4 directions so towns behind hills are visible) multiplies this
- Millions of small files also waste space through filesystem block size

Dynmap cannot mix levels of detail within one map; separate detail levels mean separate map definitions and a page switch. Splitting the world over several worlds doesn't reduce the total either: storage scales with the rendered area.

## 2. Options considered

1. **Trim Dynmap:** one angle, WebP/JPG tiles. Saves space, but loses the view from other directions.
2. **BlueMap:** real 3D with free rotation, tilt and a flat top-down mode. Built-in level of detail. **Chosen candidate, tested.**
3. **Pl3xMap / squaremap:** flat top-down, about 1 pixel per block, very small. Fallback if 3D is not needed.
4. **Render on demand:** low-res for the whole world, high-res only for active areas such as a running siege, discarded later.
5. **Own WebGL viewer:** store only height and top block per column (a few GB) and draw in the browser. Essentially what BlueMap already does.

## 3. How BlueMap works

- **High-res:** compressed 3D model tiles near the camera. The browser builds the geometry, so there's no separate image per zoom level or angle.
- **Low-res:** small images holding colour and height per column, at several detail levels, for the distance. The browser switches levels smoothly, with no reload.
- **Standalone/CLI (Docker):** reads world files from disk. It renders and hosts the web app without a Minecraft server running. It does not show live players.
- **Plugin (Paper):** hooks into the running server for live player positions and markers.
- **Storage:** compressed files in `web/maps` by default, or a database. Files can be served as static files by Nginx.
- **Customisation:** per-map render mask, high-res view distance, lighting and sky. The web app is open source and accepts custom scripts and styles. A marker API covers territories, trade routes and siege zones (shape and extruded markers, lines, POIs).

## 4. Dynmap vs BlueMap

### 4.1 Pros and cons

| Aspect | Dynmap | BlueMap |
|---|---|---|
| Storage, full 22k × 17k world | 100–300 GB per view angle (estimate) | **about 40 GB measured/extrapolated**, all angles included |
| Viewing | Fixed angle per map; more angles multiply storage | Free 3D rotation, tilt and flat top-down in one map |
| Level of detail | None within one map; separate maps need a page switch | Built in: high-res near, low-res far, smooth switching |
| Offline rendering | No standalone renderer; needs a (Paper) server running, which can itself be dockerised | Standalone CLI in Docker reads world files directly; no server needed (confirmed) |
| Live players and markers | Yes, via plugin | Yes, via plugin |
| Weak phones and laptops | Light: plain images | WebGL; fine on iPhone 13 and 16 Pro Max; budget Android untested |
| In-game 2D tables (headless Chromium) | Flat images, cheap | Needs a custom 2D page on the low-res tiles (to verify) |
| Customisation | Mature web UI and marker API; existing targeting page already built on it | Open-source web app, scripts, styles and marker API; targeting page must be ported |
| Maturity and risk | Long-established, well known | Active, popular; one community report of runaway disk use, so watch storage |

### 4.2 Decision matrix

Scores 1 (poor) to 5 (excellent). Weights reflect the developer's priorities: render size at scale first, then LOD/quality control and web UI extensibility (custom tooltips, region overlays, clickable structures, siege targeting). Performance matters, but trading some detail or quality on weak devices is acceptable.

| Criterion | Weight | Dynmap | BlueMap |
|---|---|---|---|
| Storage at scale (worlds larger than 22k × 17k) | 35% | 1 | 4 (measured: about 40 GB) |
| LOD and render quality control in the web UI | 20% | 2 | 5 |
| Web UI extensibility | 20% | 4 | 4 |
| Performance on weak devices, after tuning | 10% | 5 | 4 (good on iPhone 13) |
| Offline / standalone render pipeline | 5% | 2 | 5 (confirmed) |
| In-game 2D tables | 5% | 5 | 3 |
| Maturity and risk | 5% | 5 | 4 |
| **Weighted total** | 100% | **2.65** | **4.20** |

Decision rule: go BlueMap if it leads by at least 0.5 after the test and measured storage stays well under 100 GB for the full world. **Both are met.**

### 4.3 Other considerations

- **Hosting cost:** VPS plans charge for disk. About 40 GB for BlueMap versus 150–300 GB for Dynmap, for one 22k × 17k world, is a large monthly difference, and it grows with world size. This is the main reason Dynmap ranks last.
- **Bandwidth:** serving tens of GB of tiles to many players adds up, for either renderer (Dynmap's larger tiles cost more). Put Cloudflare caching in front of Nginx (the Cloudflare Tunnel is already in place). BlueMap 5.25+ has an `additional-headers` webserver option for cache headers.
- **WorldGuard regions:** BlueMap supports shape and extruded markers. On the live server, a small plugin (or an existing community add-on) reads WorldGuard regions and pushes them through the marker API. The standalone render can't see WorldGuard, so a first test uses a hand-made marker in the map config.
- **Version lag:** BlueMap must support each new Minecraft version; check before upgrading the server. 26.3 is supported since BlueMap 5.24.
- **Cave culling and shadowed builds:** BlueMap skips blocks it treats as caves: no sky light, below `remove-caves-below-y` (default 55) and at least 5 blocks below the highest block in that column. Builds under overhangs or arches below that height get holes (seen at the plaza under the cliff arch near X 1433, Z -519, about Y 35). K&K uses `remove-caves-below-y: 30`, just under the lowest shadowed build. Everything above Y 30 renders, including any caves there; caves below stay hidden. Lower it if a shadowed build sits deeper. Cost measured: about +1% storage.
- **Custom textures:** add any resource pack or custom blocks to BlueMap's config so the render matches the game.
- **Render time:** a full first render takes about 20 hours on 4 threads (§6); later updates only touch changed chunks.
- **Licence:** BlueMap is MIT; Dynmap is Apache 2.0. Both are permissive and allow commercial use, modification and forks, as long as copyright and licence notices are kept. Dynmap's team adds its own policies for anyone using the code beyond contributions, and "Dynmap" is a registered name, so a fork needs a different name. For monetising K&K, Mojang's EULA and Minecraft Usage Guidelines are the real limit, not these licences. Not legal advice.
- **Laby App (LabyMod):** its phone live map is a client-side minimap streamed from the player's loaded chunks, not BlueMap. Not a replacement, but an idea worth keeping: let clients do the work.

## 5. Impact on DESIGN.md

- **M2 / M3 / M4:** read "BlueMap" where they say Dynmap. The web-based targeting page is ported to BlueMap's web app and marker API.
- **In-game tables:** BlueMap's 3D viewer needs WebGL, which a GPU-less VPS running MapBrowser would software-render at high CPU cost. The tables are 2D anyway, so they use a **custom 2D page drawing BlueMap's low-res tiles** (colour + height, about 1 px per block at the finest level) on a plain canvas. Fit depends on how much area a table covers: a few hundred blocks wide fits the finest level; a few thousand blocks drops to several blocks per pixel. The number and step of low-res levels are configurable.
- **Snapshot pipeline (M5, §7):** unchanged in spirit and easier: the standalone BlueMap container renders a world copy offline; the Paper plugin on production runs with auto-render off or limited, mainly for live players and markers. Config and map ids must match on both sides.
- **Tile storage (§7):** flat files under `/mnt/fast/knk-alpha/bluemap/web`, served statically (Nginx) — not on the system NVMe.

## 6. Test render results (NAS, 2026-11-10 and 2026-11-12)

Setup: standalone BlueMap (`ghcr.io/bluemap-minecraft/bluemap:latest`) in Docker on the NAS, render threads 4, world copy of `world_KNK-DEV` (7.5 GB), working folder `/mnt/fast/knk-alpha/bluemap`. Test area centred on X 1415, Z -522 (town + hills).

| Metric | Run 1: town + hills | Run 2: expanded | Run 3: unlit chunks included | Run 4: + caves cutoff Y 30 (final, 2026-11-12) |
|---|---|---|---|---|
| Area rendered (blocks) | 1,000 × 1,000 | 2,000 × 2,000 | 2,000 × 2,000 | 2,000 × 2,000 |
| Settings | default | default | `ignore-missing-light-data: true`, forced re-render (`-f`) | run 3 + `remove-caves-below-y: 30` |
| Render time (4 threads) | about 3–5 min | about 6 min (added area only) | 13 min (full area) | about 13 min |
| Disk size (`web/maps`) | 147 MB | 334 MB | **430 MB** | **435 MB** |
| File count | 1,062 | 3,036 | 4,106 | 4,106 |
| Size per million blocks² | 147 MB | 84 MB | **about 108 MB** | **about 109 MB** |
| Extrapolated full world (22k × 17k, ×374) | about 55 GB | about 31 GB (gaps not rendered) | **about 40 GB**, about 385,000 files | **about 41 GB** |
| Look on PC (1–5) | | | **5** | 5; plaza under the arch renders correctly |
| Look/performance on phone (1–5) | | | **5**: good on iPhone 16 Pro Max and iPhone 13; budget Android untested | |
| Low-res usable for 2D tables? | | | Depends on zoom; verify with a prototype table page | |

Runs 1–2 left black gaps: WorldPainter chunks never loaded by the server have no light data, and BlueMap skips those by default. Run 3 sets `ignore-missing-light-data: true` and forces a re-render. Run 3 still had holes in shadowed ground below Y 55 (cave culling, §4.3); run 4 sets `remove-caves-below-y: 30` and is the representative figure.

**Full-world estimate: about 40 GB** (range about 30–55 GB depending on how built-up the world is), versus 150–300 GB for Dynmap with a single angle. Full first render: about 20 hours on 4 threads. Long-term, load the world on the server (e.g. Chunky, after a backup, on dev first) so all chunks get proper lighting — players need lit chunks too.

## 7. Test procedure (reproducible, NAS over SSH)

Run in an SSH session (PowerShell: `ssh <user>@<nas-ip>`). Start with `sudo -i` (the user can't reach the Docker socket) **on its own**, enter the password, then paste the rest: lines pasted together with `sudo -i` are swallowed by the password prompt. Stay in that root shell, so `MC` and `DATA` are kept.

### 7.1 Find the container and world

```
docker ps --filter "label=com.docker.compose.project=knk-alpha" --format '{{.Names}}\t{{.Image}}'
MC=knk-alpha-minecraft

docker inspect "$MC" --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{println}}{{end}}'
DATA=/srv/docker/stacks/knk-alpha/minecraft-data      # host source of /data
ls "$DATA"                                            # overworld folder: world_KNK-DEV
docker logs "$MC" 2>&1 | grep -i "starting minecraft server version" | tail -1
```

### 7.2 Prepare the folder (final location, not the NVMe)

```
df -h /srv/docker/stacks/knk-alpha /mnt/fast   # /srv is on the system NVMe
mkdir -p /mnt/fast/knk-alpha/bluemap/{config,data,web,world}
cd /mnt/fast/knk-alpha/bluemap
```

If BlueMap stays, config and tiles stay here and the stack mounts this folder later. Only `world/` is a throwaway snapshot.

### 7.3 Copy the world safely

```
docker exec "$MC" rcon-cli save-off
docker exec "$MC" rcon-cli save-all flush
sleep 15
rsync -a --info=progress2 "$DATA/world_KNK-DEV/" /mnt/fast/knk-alpha/bluemap/world/
docker exec "$MC" rcon-cli save-on      # always run, even if the copy fails
```

### 7.4 Generate and edit the config

```
docker run --rm -it -v "$(pwd)/config:/app/config" ghcr.io/bluemap-minecraft/bluemap:latest
sed -i 's/accept-download: false/accept-download: true/' config/core.conf
grep -n "render-thread-count" config/core.conf        # set to 4 or lower
mkdir -p config/maps-off && mv config/maps/nether.conf config/maps/end.conf config/maps-off/
sed -i 's/#\?\s*ignore-missing-light-data: false/ignore-missing-light-data: true/' config/maps/overworld.conf
sed -i 's/^\(\s*\)remove-caves-below-y:.*/\1remove-caves-below-y: 30/' config/maps/overworld.conf
grep -n "ignore-missing-light-data:\|remove-caves-below-y:" config/maps/overworld.conf
```

Add the area as a **render mask** at the end of `config/maps/overworld.conf` (top-level `min-x`/`max-x` keys are rejected as an outdated config):

```
cat >> config/maps/overworld.conf <<'EOF'
# Test area: 2,000 x 2,000 blocks around X 1415, Z -522
render-mask: [
  {
    min-x: 415
    max-x: 2415
    min-z: -1522
    max-z: 478
  }
]
EOF
```

### 7.5 Render, host and measure

```
docker run -d --name bluemap-test -p 8100:8100 \
  -v "$(pwd)/config:/app/config" \
  -v "$(pwd)/world:/app/world" \
  -v "$(pwd)/data:/app/data" \
  -v "$(pwd)/web:/app/web" \
  ghcr.io/bluemap-minecraft/bluemap:latest -r -w     # add -f to force a full re-render
docker logs -f bluemap-test                           # Ctrl+C stops following only

du -sh /mnt/fast/knk-alpha/bluemap/web/maps
find /mnt/fast/knk-alpha/bluemap/web/maps -type f | wc -l
hostname -I                                           # open http://<nas-ip>:8100
```

After a config change, always `docker rm -f bluemap-test` and start again with `-f`; a container that is still running uses the old config. If the container stops on a config error: fix it and start again. Clean up with `docker stop bluemap-test && docker rm bluemap-test` (files stay).

## 8. Next steps

To be split into sub-issues of #224 when picked up:

1. ~~Update DESIGN.md decisions M2–M4 to BlueMap~~ — done 2026-11-12.
2. **WorldGuard town and district regions:** first test with the standalone renderer: [`scripts/bluemap/wg2bluemap.py`](../../../scripts/bluemap/wg2bluemap.py) turns WorldGuard's `regions.yml` (towns = priority 10, districts = priority 20, names `domain_<id>`) into static `marker-sets` in the map config; `--markers` applies them without a re-render. Later: a plugin pushing regions (with town/district names from knk-web-api) through the BlueMap API, kept in sync on region changes.
3. **Web UI extensibility spike:** one custom marker with a tooltip, one region overlay, one click handler logging world X/Z (the targeting path).
4. **2D table page prototype** on the low-res tiles; test in headless Chromium for CPU cost and check readability at the table's zoom.
5. **Plugin on the dev server** (Paper jar) with live players and auto-render off/limited; tiles from the offline render.
6. **Lighting:** load the world on the dev server (Chunky, after a backup) and re-render without `ignore-missing-light-data`.
7. **Stack integration:** BlueMap service in the knk-alpha Compose stack, mounting `/mnt/fast/knk-alpha/bluemap`; Nginx + Cloudflare caching.
8. **Optional:** measure a budget Android phone; a full-world render to confirm the 40 GB estimate.
