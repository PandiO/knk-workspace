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

-- A new holder for the group (only when there is a clash: @clash IS NOT NULL).
INSERT INTO permission_holders (ChatPrefix, ChatSuffix)
SELECT ChatPrefix, ChatSuffix FROM permission_holders WHERE Id = @clash AND @clash IS NOT NULL;
SET @new := IF(@clash IS NULL OR ROW_COUNT() = 0, NULL, LAST_INSERT_ID());

UPDATE permission_groups      SET Id = @new                        WHERE Id = @clash AND @new IS NOT NULL;
UPDATE permission_groups      SET ParentGroupId = @new             WHERE ParentGroupId = @clash AND @new IS NOT NULL;
UPDATE user_permission_groups SET PermissionGroupId = @new         WHERE PermissionGroupId = @clash AND @new IS NOT NULL;
UPDATE lootbox_token_grants   SET PermissionGroupId = @new         WHERE PermissionGroupId = @clash AND @new IS NOT NULL;
UPDATE kits                   SET RequiredPermissionGroupId = @new WHERE RequiredPermissionGroupId = @clash AND @new IS NOT NULL;
UPDATE domains                SET TeleportMinPremiumGroupId = @new WHERE TeleportMinPremiumGroupId = @clash AND @new IS NOT NULL;
UPDATE game_settings
SET GroupOverridesJson = REGEXP_REPLACE(GroupOverridesJson,
    CONCAT('"permissionGroupId"[[:space:]]*:[[:space:]]*', @clash, '([^0-9])'),
    CONCAT('"permissionGroupId":', @new, '$1'))
WHERE @new IS NOT NULL;
-- The grants on the shared id were the group's.
UPDATE permission_grants      SET HolderId = @new                  WHERE HolderId = @clash AND @new IS NOT NULL;

SET FOREIGN_KEY_CHECKS = 1;
COMMIT;

SELECT @clash AS repaired_id, @new AS group_moved_to,
       (SELECT Name FROM permission_groups WHERE Id = @new) AS group_name,
       (SELECT COUNT(*) FROM permission_grants WHERE HolderId = @new) AS group_grants,
       (SELECT COUNT(*) FROM users u JOIN permission_groups g ON g.Id = u.Id) AS clashes_left;
