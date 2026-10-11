-- Repair a user and a permission group that share one permission_holders id.
--
-- Users and groups share the permission_holders id space (table-per-type): every holder id belongs to
-- exactly one user OR one group. When both a `users` row and a `permission_groups` row use the same id,
-- every grant on that id applies to the user AND the group, and loading that user fails with
-- "Unable to cast object of type 'PermissionGroup' to type 'User'" (500 on Users/{id}/groups and
-- friends). The KNG-64 smoke test found this in the dev DB: the web-only test account `admin` and
-- the Staff group are both id 29 (it is in the UI/UX seed too, so it predates 2026-10-08).
--
-- This keeps the USER on the old id (far more tables point at users) and moves the GROUP to a new
-- holder id, with every reference to it. The grants on the shared id were the group's (Staff nodes),
-- so they move with the group: the user keeps no direct grants afterwards. Re-grant that account
-- what it needs.
--
-- Usage (back up first, see docs/guides/alpha-hardening-smoke-test.md step 1):
--   Run the whole file. The first SELECT lists the clashes; each run repairs the lowest one, and a run
--   with none changes nothing. Run it again until clashes_left is 0.
--   mysql --defaults-extra-file=~/.knk-dev.cnf knightsandkings_dev_v2 < scripts/maintenance/repair-holder-id-clash.sql
--   or paste the whole file into phpMyAdmin's SQL tab (it runs as one batch, which the variables need).
--   Works on MySQL 8 and MariaDB 10.3+.
--
-- References to permission_groups.Id as of migration 20261010170000 (re-check after new migrations):
-- permission_groups.ParentGroupId, user_permission_groups.PermissionGroupId,
-- lootbox_token_grants.PermissionGroupId, kits.RequiredPermissionGroupId,
-- domains.TeleportMinPremiumGroupId, game_settings.GroupOverridesJson ("permissionGroupId").

SELECT u.Id AS clash_id, u.Username AS user_name, g.Name AS group_name
FROM users u JOIN permission_groups g ON g.Id = u.Id;

SET @clash := (SELECT MIN(u.Id) FROM users u JOIN permission_groups g ON g.Id = u.Id);

START TRANSACTION;
SET FOREIGN_KEY_CHECKS = 0;

-- A new holder id for the group, chosen up front and inserted explicitly. No ROW_COUNT() or
-- LAST_INSERT_ID(): phpMyAdmin runs its own queries between statements, which resets them.
SET @new := IF(@clash IS NULL, NULL, (SELECT MAX(Id) + 1 FROM permission_holders));
INSERT INTO permission_holders (Id, ChatPrefix, ChatSuffix)
SELECT @new, ChatPrefix, ChatSuffix FROM permission_holders WHERE Id = @clash AND @new IS NOT NULL;

UPDATE permission_groups      SET Id = @new                        WHERE Id = @clash AND @new IS NOT NULL;
UPDATE permission_groups      SET ParentGroupId = @new             WHERE ParentGroupId = @clash AND @new IS NOT NULL;
UPDATE user_permission_groups SET PermissionGroupId = @new         WHERE PermissionGroupId = @clash AND @new IS NOT NULL;
UPDATE lootbox_token_grants   SET PermissionGroupId = @new         WHERE PermissionGroupId = @clash AND @new IS NOT NULL;
UPDATE kits                   SET RequiredPermissionGroupId = @new WHERE RequiredPermissionGroupId = @clash AND @new IS NOT NULL;
UPDATE domains                SET TeleportMinPremiumGroupId = @new WHERE TeleportMinPremiumGroupId = @clash AND @new IS NOT NULL;
-- Plain REPLACE with one explicit collation on every side: works on MySQL 8 and MariaDB, and in clients
-- whose connection collation differs from the table's (phpMyAdmin: utf8mb4_unicode_ci vs general_ci).
SET @c := CAST(@clash AS CHAR), @n := CAST(@new AS CHAR);
UPDATE game_settings
SET GroupOverridesJson =
    REPLACE(REPLACE(REPLACE(REPLACE(CONVERT(GroupOverridesJson USING utf8mb4) COLLATE utf8mb4_general_ci,
        CONVERT(CONCAT('"permissionGroupId":', @c, ',') USING utf8mb4) COLLATE utf8mb4_general_ci,
        CONVERT(CONCAT('"permissionGroupId":', @n, ',') USING utf8mb4) COLLATE utf8mb4_general_ci),
        CONVERT(CONCAT('"permissionGroupId":', @c, '}') USING utf8mb4) COLLATE utf8mb4_general_ci,
        CONVERT(CONCAT('"permissionGroupId":', @n, '}') USING utf8mb4) COLLATE utf8mb4_general_ci),
        CONVERT(CONCAT('"permissionGroupId": ', @c, ',') USING utf8mb4) COLLATE utf8mb4_general_ci,
        CONVERT(CONCAT('"permissionGroupId": ', @n, ',') USING utf8mb4) COLLATE utf8mb4_general_ci),
        CONVERT(CONCAT('"permissionGroupId": ', @c, '}') USING utf8mb4) COLLATE utf8mb4_general_ci,
        CONVERT(CONCAT('"permissionGroupId": ', @n, '}') USING utf8mb4) COLLATE utf8mb4_general_ci)
WHERE @new IS NOT NULL;
-- The grants on the shared id were the group's.
UPDATE permission_grants      SET HolderId = @new                  WHERE HolderId = @clash AND @new IS NOT NULL;

-- Holder rows that belong to no user and no group and carry no grants (left by an interrupted run).
DELETE ph FROM permission_holders ph
WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.Id = ph.Id)
  AND NOT EXISTS (SELECT 1 FROM permission_groups g WHERE g.Id = ph.Id)
  AND NOT EXISTS (SELECT 1 FROM permission_grants pg WHERE pg.HolderId = ph.Id);

SET FOREIGN_KEY_CHECKS = 1;
COMMIT;

SELECT @clash AS repaired_id, @new AS group_moved_to,
       (SELECT Name FROM permission_groups WHERE Id = @new) AS group_name,
       (SELECT COUNT(*) FROM permission_grants WHERE HolderId = @new) AS group_grants,
       (SELECT COUNT(*) FROM users u JOIN permission_groups g ON g.Id = u.Id) AS clashes_left;
