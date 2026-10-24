# knk-alpha snapshots (closed alpha, runbook Phase 7 lite)

Two root-only commands for the NAS `knk-alpha` stack. They replace the hand-typed dumps of Phases 3b–6. The full
backup plan (schedule, off-site, retention, restore rehearsal) is deferred to the beta on a VPS: developer decision
2026-10-24, runbook Phase 7.

| Command | What it does |
|---|---|
| `sudo knk-alpha-snapshot [label]` | Writes `/srv/backups/knk-alpha/snapshots/<UTC time>[-label]/`:<br>• `db.sql.gz`: `mysqldump --single-transaction`, no locks, checked with `gzip -t`;<br>• `minecraft-data.tar.zst`: the world, taken during `save-off` → `save-all flush` → `save-on`. Players keep playing, and `save-on` always runs, even on an error;<br>• `config.tar`: `compose.yaml`, `config/`, `releases/`, `secrets/`;<br>• the Portainer copy, `meta.txt` (counts, Compose hash, images) and `SHA256SUMS`.<br>Keeps the newest `KNK_SNAPSHOT_KEEP` (10). About 1 minute and ~5 GB with today's world |
| `sudo knk-alpha-restore <snapshot> [db\|world\|all]` | Checks `SHA256SUMS`, shows `meta.txt`, warns when the snapshot's migration count differs from the database's, and asks you to type `RESTORE`. Then:<br>1. takes a **pre-restore safety snapshot**;<br>2. stops `api` and `minecraft` (only `minecraft` for `world`);<br>3. recreates `knightsandkings_alpha` from the dump, and/or moves `minecraft-data` aside to `minecraft-data.replaced-<time>` and unpacks the snapshot's world;<br>4. starts the stopped services again.<br>It doesn't change images or `compose.yaml`: when the snapshot belongs to another API build, restore that `compose.yaml` from `config.tar` and recreate the API as well |

**When:** before and after each alpha session (`sudo knk-alpha-snapshot before-run-1`, `after-run-1`), and before every
update (`pre-<sha>`). A snapshot stays on the NAS's own disk: this is a quick way back from a bad update or a mistake,
not protection against losing the NAS.

**Install** (as root on the NAS): copy both files to `/usr/local/sbin/`, mode 0700, owner root.

Tested on 2026-10-24 in a scratch Docker host against a mock stack (MySQL 9.6.0 with the alpha schema, stand-ins for the
API and Minecraft, a world owned by 2001):
- the snapshot passed `save-off`/flush/`save-on`;
- retention kept the newest N, and an invalid label was refused;
- after deleting rows and a world file, `restore … all` brought both back (144 tables, 4 triggers, owner 2001:2001). It
  also made the safety snapshot, kept the replaced world and restarted the services;
- a cancelled restore changed nothing.

On the NAS since 2026-10-24: the first snapshot `20261024T180424Z-initial` took 19 s (world 3.0 GB with zstd; API 95
migrations, 144 tables). Every container kept running.
