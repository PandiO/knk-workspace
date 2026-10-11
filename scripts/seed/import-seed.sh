#!/usr/bin/env bash
# Load a seed data set made by export-seed.sh into a NEW production database.
#
# Usage:
#   scripts/seed/import-seed.sh --defaults-file ~/.knk-prod-migrator.cnf --database knk_prod --seed seed/2026-10-07
#
# Run it after the EF migrations and BEFORE the API starts for the first time.
# It refuses a database that already has users, or whose schema version differs
# from the seed's. Everything is one transaction: on any error nothing changes.
# See docs/guides/production-installation.md § 7.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=seed-tables.sh
source "$here/seed-tables.sh"

defaults=""; db=""; seed=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --defaults-file) defaults="$2"; shift 2 ;;
    --database) db="$2"; shift 2 ;;
    --seed) seed="$2"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
[[ -n "$defaults" && -n "$db" && -n "$seed" ]] || { echo "usage: $0 --defaults-file FILE --database DB --seed DIR" >&2; exit 2; }
[[ -f "$seed/seed.sql" && -f "$seed/manifest.txt" ]] || { echo "$seed must contain seed.sql and manifest.txt" >&2; exit 1; }

mysql_q() { mysql --defaults-extra-file="$defaults" -N -B "$db" -e "$1"; }
manifest() { grep "^$1=" "$seed/manifest.txt" | cut -d= -f2-; }

# 1. The file is the one that was exported.
expected="$(manifest sha256)"; actual="$(sha256sum "$seed/seed.sql" | cut -d' ' -f1)"
[[ "$expected" == "$actual" ]] || { echo "seed.sql checksum mismatch (manifest $expected, file $actual)" >&2; exit 1; }

# 2. Same schema version as the source, so every column in the dump exists here.
target="$(mysql_q "SELECT MigrationId FROM __EFMigrationsHistory ORDER BY MigrationId DESC LIMIT 1")"
[[ "$target" == "$(manifest schema_version)" ]] || {
  echo "schema mismatch: seed is $(manifest schema_version), database is ${target:-empty}." >&2
  echo "Apply migrations to the same version (or re-export from a dev DB at this version)." >&2
  exit 1
}

# 3. Never over a live database: the import replaces whole tables.
users="$(mysql_q "SELECT COUNT(*) FROM users")"
[[ "$users" == "0" ]] || { echo "refusing: $db already has $users user(s). A seed is for a new database only." >&2; exit 1; }

tables="$CONTENT_TABLES"
[[ "$(manifest with_world)" == "1" ]] && tables="$tables $WORLD_TABLES"

{
  echo "SET FOREIGN_KEY_CHECKS = 0;"
  echo "START TRANSACTION;"
  # Clear what the migrations seeded; the dev DB ran the same migrations, so its rows replace them.
  for t in $tables $GROUP_FILTERED_TABLES; do echo "DELETE FROM \`$t\`;"; done
  cat "$seed/seed.sql"
  for c in $USER_REFERENCE_COLUMNS; do echo "UPDATE \`${c%%.*}\` SET \`${c#*.}\` = NULL;"; done
  # 4. Row counts match the manifest, checked before COMMIT: a mismatch prints the table and
  # then fails on purpose (a scalar subquery with two rows), so mysql stops and the
  # transaction rolls back.
  for t in $tables $GROUP_FILTERED_TABLES; do
    want="$(manifest "$t")"
    [[ "$want" =~ ^[0-9]+$ ]] || { echo "manifest has no row count for $t" >&2; exit 1; }
    echo "SET @n := (SELECT COUNT(*) FROM \`$t\`);"
    echo "SELECT CONCAT('row count mismatch in $t: manifest $want, database ', @n) FROM DUAL WHERE @n <> $want;"
    echo "DO IF(@n = $want, 0, (SELECT 1 UNION ALL SELECT 2));"
  done
  echo "COMMIT;"
  echo "SET FOREIGN_KEY_CHECKS = 1;"
} | mysql --defaults-extra-file="$defaults" -N -B "$db" >&2 || {
  echo "import rolled back: nothing changed in $db." >&2
  exit 1
}
echo "Seed $(manifest exported_utc) imported into $db (schema $target). Start the API next."
