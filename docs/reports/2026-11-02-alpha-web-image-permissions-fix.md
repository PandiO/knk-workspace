# Closed alpha: web images fix — `knk-deploy` extract permissions, web `1c9524d0` — 2026-11-02

**Status:** Done — deployed and verified by the developer 2026-11-02
**Last updated:** 2026-11-02
**Issue:** [#210](https://github.com/PandiO/knk-workspace/issues/210) (related: [#209](https://github.com/PandiO/knk-workspace/issues/209), Access bypass paths, still open)
**Procedure:** [NAS ops access § 7](../guides/nas-ops-access.md) (`knk-deploy`, Stage B)

## 1. Problem

After the first web deploy through `knk-deploy` (`alpha-b3b415d0`, [2026-11-01 report](2026-11-01-alpha-update-trunk-heads.md)), the nav logo
(`/brand/knk-shield.png`) and the landing slideshow (`/images/*.jpg`) were broken in every browser. `GET /brand/knk-shield.png`
returned **200 `text/html`**: nginx's `index.html` fallback.

## 2. Cause

`knk-deploy` runs with umask 077 and extracted the source with `tarfile`'s `data` filter, which ignores the archive's directory
modes. Every source directory came out 0700. `npm run build` copies `public/` with those modes, so `build/brand` and
`build/images` were 0700 root-owned in the image. nginx (UID 101) couldn't enter them, and `try_files $uri /index.html`
fell through to `index.html`. Root-level files (`favicon.ico`, `logo192.png`) were not affected. Reproduced in the cloud
session: a build from a umask-077 extract gives `build/brand` 700.

## 3. Fix and install

knk-workspace `claude/dazzling-dijkstra-37xmt1` (`7b3c49f`, `47a3dde`):

- `scripts/nas-ops/stage-b/knk-deploy`: `source_filter` (the `data` filter's checks, directories 0755; the build folder stays 0700) → `e5778e0a…`
- `scripts/nas-ops/stage-b/tests/test_extract_source.py` (new, no root or Docker): 10/10, 5 fail on the old program
- `scripts/alpha-web/Dockerfile`: `npm run build && chmod -R a+rX build`
- `tests/test_knk_deploy.py` refuses to run on a host with the real `knk-alpha` stack (the mock uses the live container names and its cleanup deletes every `knk-web-*:alpha-*` image)
- `SHA256SUMS` regenerated (also `pc/knk-release.sh`, stale since 2026-11-01)

Developer, 2026-11-02, on the NAS as the admin account: archive copied from the PC, `sha256sum -c SHA256SUMS` all OK,
`test_extract_source.py` 10/10 on the NAS. The old program was kept as `/var/lib/knk-deploy/knk-deploy.before-210`, then the new `knk-deploy` and the
web `_files/Dockerfile` were installed (the old Dockerfile was kept as `_files/Dockerfile.before-210`). The installed program's hash after the install was not
posted back. Not run: the root + Docker end-to-end `test_knk_deploy.py` (it needs a throwaway VM or WSL).

## 4. Deploy

| Time (UTC) | Command | Result |
|---|---|---|
| — | `knk-release.sh web 1c9524d0…` (run from `origin/main`'s copy, `/tmp/knk-release.sh`; the workspace checkout was on another branch) | upload ok, archive `44b6ce0f…`, 3.8 MB |
| 16:58 | `deploy-web 1c9524d0…` | built `knk-web-app:alpha-1c9524d0` (`sha256:0ed85f57…`), compose `97bfb08e…` → `2334937f…`, web healthy 16:58:51Z; backup `/var/lib/knk-deploy/backups/20261102T165850Z-web-1c9524d0` |

Web `alpha-b3b415d0` → `alpha-1c9524d0` also brings the 2026-11-01 hotfixes on knk-web-app `main`: the claim code field
centered (#206) and the invitation code fields with fixed `KNK-` and dashes (#208).

**Rollback:** `ssh knk-deploy rollback` (back to `alpha-b3b415d0`, which has the broken images).

## 5. Checks

| Check | Result |
|---|---|
| `deploy-web` health | healthy |
| Browser: logo and landing slideshow | **back** (developer, 2026-11-02) |
| `/link` claim code field centered, `/join` invitation field `KNK-_____-_____` | pending (developer) |
