# Road build offline replay (KNG-27)

**Status:** Reference tooling (not compiled from here). Used for finding L, 2026-10-04.
**Last updated:** 2026-10-04

Runs the real `TileBuilder` on copies of the dev world's region files, with the build inputs exported read-only from
the dev DB. Used to reproduce a live build exactly, then change one input at a time: tombstones on or off, a config
value, a builder change. Smoke-test guide, finding L, has an example.

## Files

- `export_replay.py`: exports one tile's build inputs (profiles, seeds, survey breadcrumbs (every 8th on-road point),
  Domain Locations, neighbour Boundary nodes, the tile's nodes, edges and tombstones) to JSON. It opens a read-only
  session and reads the connection from knk-web-api `appsettings.json`. Needs `pymysql`.
- `ReplayScratchTest.java`: the JUnit harness. It reads the region files with a small Anvil/NBT reader and captures
  chunks with the server's own `CompactSurfaceGrid`/`SpanExtractor`. It builds with the live config
  (`liveParams()`; adjust it if the server config changes) and writes a text report per tile (nodes, edges and
  correction notes inside a focus box).

## Use

1. Make a folder, e.g. `<scratch>/replay-data/`, with `region/` and `replay/` inside.
2. **Copy** (never move or open in place) the region files around the tile from
   `MinecraftServer/Servers/DEV_SERVER_1.21.10/world_KNK-DEV/region/` into `region/`. A tile `(tx, tz)` plus its
   32-block margin needs `r.{tx-1..tx+1}.{tz-1..tz+1}.mca`.
3. Run `python export_replay.py 2 -2 <scratch>/replay-data/replay/tile_2_-2.json` (optionally pass the path to
   `appsettings.json` as a 4th argument).
4. Write `replay/control.txt`:
   ```
   files=tile_2_-2.json
   variants=live,notomb,raw
   map=1380,1450,-590,-505,38,56
   ```
   - Variants: `live`, `notomb`, `raw`, `designed`, `c3`, `c1`, `rawc3`; add more in `replayTile`.
   - `map` is the box for the `map()` test: x0,x1,z0,z1,y0,y1.
5. Copy `ReplayScratchTest.java` into `knk-paper/src/test/java/net/knightsandkings/knk/paper/roads/`, set
   `KNK_REPLAY_DIR=<scratch>/replay-data`, stop the Gradle daemon (`./gradlew --stop`, so it picks up the variable), and
   run `./gradlew :knk-paper:test --offline --rerun --tests "*ReplayScratchTest*"`. `--rerun` matters: Gradle does not
   see changes to `control.txt` and would skip the test.
6. Read `replay/out_<tile>.txt` and `replay/map.txt`.
7. **Delete the test file from knk-plugin before committing** (until decision D7 in plan §5.7 says otherwise).

Check first that the `live` variant reproduces the stored build: the same node and edge counts and geometry. If it
does not, an input is missing (gate cells are not exported; the passability rules use the curated collidable list, not
Bukkit's).
