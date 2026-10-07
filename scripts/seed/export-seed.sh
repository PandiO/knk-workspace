#!/usr/bin/env bash
# Export the production seed data set (curated content, no players) from a
# knk-web-api MySQL database, normally the developer's dev DB.
#
# Usage:
#   scripts/seed/export-seed.sh --defaults-file ~/.knk-dev.cnf --database knightsandkings_dev_v2 \
#       [--with-world] [--out seed/2026-10-07]
#
# The defaults file is a MySQL option file, so the password stays out of the
# command line and shell history:
#   [client]
#   host=192.168.50.119
#   user=knk_seed_reader
#   password=...
#
# Needs the MySQL 8 client tools (mysql, mysqldump) on PATH. On Windows run it
# from Git Bash with MySQL Server's or Workbench's bin folder on PATH.
# Writes <out>/seed.sql and <out>/manifest.txt. See
# docs/guides/production-installation.md § 7.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=seed-tables.sh
source "$here/seed-tables.sh"

defaults=""; db=""; with_world=0; out="seed/$(date +%Y-%m-%d)"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --defaults-file) defaults="$2"; shift 2 ;;
    --database) db="$2"; shift 2 ;;
    --with-world) with_world=1; shift ;;
    --out) out="$2"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done
[[ -n "$defaults" && -n "$db" ]] || { echo "usage: $0 --defaults-file FILE --database DB [--with-world] [--out DIR]" >&2; exit 2; }

mysql_q() { mysql --defaults-extra-file="$defaults" -N -B "$db" -e "$1"; }

# 1. Every table must be classified, so new tables never slip in or out silently.
known=" $CONTENT_TABLES $GROUP_FILTERED_TABLES $WORLD_TABLES $RUNTIME_TABLES "
known="$(echo "$known" | tr -s ' \n' '  ')"
unclassified=""
for t in $(mysql_q "SELECT table_name FROM information_schema.tables WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE'"); do
  [[ "$known" == *" $t "* ]] || unclassified="$unclassified $t"
done
if [[ -n "$unclassified" ]]; then
  echo "Unclassified tables:$unclassified" >&2
  echo "Add each to one list in scripts/seed/seed-tables.sh, then re-run." >&2
  exit 1
fi

tables="$CONTENT_TABLES"
[[ $with_world -eq 1 ]] && tables="$tables $WORLD_TABLES"
tables="$(echo $tables)"

mkdir -p "$out"
migration="$(mysql_q "SELECT MigrationId FROM __EFMigrationsHistory ORDER BY MigrationId DESC LIMIT 1")"

# Data only (the schema comes from the EF migrations), one consistent snapshot,
# full column lists so a column-order difference cannot shift values,
# no LOCK TABLES or ALTER TABLE ... DISABLE KEYS (both commit implicitly) so the
# import can run in one transaction.
dump_opts=(--defaults-extra-file="$defaults" --no-create-info --skip-triggers --complete-insert
           --single-transaction --skip-add-locks --skip-disable-keys --hex-blob --no-tablespaces
           --default-character-set=utf8mb4 --set-gtid-purged=OFF)

{
  echo "-- Knights and Kings seed data set"
  echo "-- source database: $db, exported $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "-- schema version: $migration"
  mysqldump "${dump_opts[@]}" "$db" $tables
  # Group rows of the shared permission tables only: no user and no user grant leaves the dev DB.
  mysqldump "${dump_opts[@]}" --where="Id IN (SELECT Id FROM permission_groups)" "$db" permission_holders
  mysqldump "${dump_opts[@]}" --where="HolderId IN (SELECT Id FROM permission_groups)" "$db" permission_grants
} > "$out/seed.sql"

{
  echo "schema_version=$migration"
  echo "with_world=$with_world"
  echo "source_database=$db"
  echo "exported_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "sha256=$(sha256sum "$out/seed.sql" | cut -d' ' -f1)"
  echo "# rows per table"
  for t in $tables; do echo "$t=$(mysql_q "SELECT COUNT(*) FROM \`$t\`")"; done
  echo "permission_holders=$(mysql_q "SELECT COUNT(*) FROM permission_holders WHERE Id IN (SELECT Id FROM permission_groups)")"
  echo "permission_grants=$(mysql_q "SELECT COUNT(*) FROM permission_grants WHERE HolderId IN (SELECT Id FROM permission_groups)")"
} > "$out/manifest.txt"

echo "Seed written to $out (schema $migration, world tables: $([[ $with_world -eq 1 ]] && echo yes || echo no))."
