# Road build offline replay (KNG-27)

**Status:** Moved to knk-plugin (plan §5.7 decision D7, 2026-10-05).
**Last updated:** 2026-10-05

The replay harness is now committed to knk-plugin (branch `claude/road-curated-tiles-nsrorb` until it is merged):

- `tools/road-replay/README.md`: how to use it.
- `tools/road-replay/export_replay.py`: the read-only DB export.
- `knk-paper/src/test/java/net/knightsandkings/knk/paper/roads/RoadReplayTest.java`: the harness. It is skipped
  unless `KNK_REPLAY_DIR` is set. It also prints the proposal a rebuild of a curated tile would make.

The scratch copies that used to live here (`ReplayScratchTest.java`, `export_replay.py`) were removed so that they
cannot drift from the committed version. Their last state is in this folder's git history (commit `ad7615d`).
