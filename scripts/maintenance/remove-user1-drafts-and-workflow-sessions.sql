-- Remove the form drafts and workflow sessions that were saved as user 1 for every admin (one-time cleanup,
-- PandiO/knk-workspace#186, 2026-10-26).
--
-- Until the #186 fix the web app sent userId = 1 with every draft (FormSubmissionProgresses) and every workflow session
-- (workflow_sessions), and the API stored it: "Saved Progress" was shared and a world task's initiator was wrong. The
-- developer decided (2026-10-26) to delete all of those rows instead of guessing their real owner. From the fix on, the
-- API takes the owner from the login.
--
-- First deploy the API and web app with the #186 fix (otherwise new rows are saved as user 1 again), back up, then run
-- this once. Set @fixed_since below to the time (UTC) the fixed API went live when you run it later than right after the
-- deploy: rows user 1 really created after that stay.
--
-- Deleted, owned by @owner (1) and created before @fixed_since:
--   FormSubmissionProgresses  every draft and completed submission (child-form rows included). A row of another user
--                             whose ParentProgressId points at a deleted row loses that link (set to NULL) and stays.
--   workflow_sessions         with their step_progress and world_tasks rows.
-- A workflow session is kept, with the reason listed, when
--   - it belongs to a Minecraft catalog scan (EntityTypeName MinecraftCatalogScan, or a minecraft_catalog_scans row names
--     one of its tasks): the API makes those itself for the admin who started the scan;
--   - one of its world tasks drew a region that is still in use: tempregion_worldtask_<task id> is still the region of a
--     domain, a domain sub-region or a lootbox spawn area, or named in a road edge's or spawn area's region list (the
--     world of such a domain is read from that task, DomainWorldResolver). Rename the region first, then run again.
-- Nothing else points at these tables (as of migration 20261024224826_AddSiegeSkipSeconds; re-check after new
-- migrations): step_progress and world_tasks hang off workflow_sessions; FormSubmissionProgresses only off itself.
--
-- Usage (back up first, docs/guides/alpha-go-live.md § 3 step 1): run the whole file with the MySQL client, as in
-- remove-seeded-examples.sql:
--   mysql -uroot -p knightsandkings_alpha < remove-user1-drafts-and-workflow-sessions.sql
-- or paste it into phpMyAdmin's SQL tab with "Enable foreign key checks" left TICKED (it runs as one batch, which the
-- variables and temporary tables need). The first result lists what will happen to each session and draft; the last
-- counts them (still_in_database = kept). A second run finds only the kept rows and changes nothing. A failed run
-- commits nothing. Tried on 2026-10-26 on MySQL 8.0 against a database built from the migrations. Uses nothing newer
-- than MySQL 8.0 / MariaDB 10.4.

SET @owner = 1;
SET @fixed_since = UTC_TIMESTAMP();   -- or the deploy time of the fixed API, e.g. '2026-10-27 18:00:00' (UTC)

-- RESTRICT foreign keys stop the run if a reference was missed above.
SET FOREIGN_KEY_CHECKS = 1;
SET SESSION group_concat_max_len = 65535;

DROP TEMPORARY TABLE IF EXISTS knk_u1_session, knk_u1_progress, knk_u1_progress_ids;
-- KeptBecause is NULL for a row that will be deleted. MySQL opens a temporary table only once per statement, hence
-- the second copy of the draft ids.
CREATE TEMPORARY TABLE knk_u1_session (Id INT PRIMARY KEY, KeptBecause TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL);
CREATE TEMPORARY TABLE knk_u1_progress (Id INT PRIMARY KEY);
CREATE TEMPORARY TABLE knk_u1_progress_ids (Id INT PRIMARY KEY);

-- Workflow sessions
INSERT INTO knk_u1_session (Id, KeptBecause)
SELECT s.Id, NULLIF(CONCAT_WS('; ',
    IF(s.EntityTypeName = 'MinecraftCatalogScan', 'Minecraft catalog scan', NULL),
    (SELECT CONCAT('task of catalog scan ', GROUP_CONCAT(c.Id ORDER BY c.Id SEPARATOR ', '))
        FROM minecraft_catalog_scans c JOIN world_tasks t ON t.Id = c.WorldTaskId WHERE t.WorkflowSessionId = s.Id),
    (SELECT CONCAT('region of domain ', GROUP_CONCAT(DISTINCT d.Id ORDER BY d.Id SEPARATOR ', '))
        FROM world_tasks t JOIN domains d ON d.WgRegionId = CONCAT('tempregion_worldtask_', t.Id)
        WHERE t.WorkflowSessionId = s.Id),
    (SELECT CONCAT('sub-region of domain ', GROUP_CONCAT(DISTINCT r.DomainId ORDER BY r.DomainId SEPARATOR ', '))
        FROM world_tasks t JOIN domain_sub_regions r ON r.WgRegionId = CONCAT('tempregion_worldtask_', t.Id)
        WHERE t.WorkflowSessionId = s.Id),
    (SELECT CONCAT('region of lootbox spawn area ', GROUP_CONCAT(DISTINCT a.Id ORDER BY a.Id SEPARATOR ', '))
        FROM world_tasks t JOIN lootbox_spawn_areas a
            ON a.WgRegionId = CONCAT('tempregion_worldtask_', t.Id)
            OR LOCATE(CONCAT('"tempregion_worldtask_', t.Id, '"'), COALESCE(a.ExcludedRegionIds, '')) > 0
        WHERE t.WorkflowSessionId = s.Id),
    (SELECT CONCAT('region of road edge ', GROUP_CONCAT(DISTINCT e.Id ORDER BY e.Id SEPARATOR ', '))
        FROM world_tasks t JOIN road_edges e
            ON LOCATE(CONCAT('"tempregion_worldtask_', t.Id, '"'), COALESCE(e.RegionIdsJson, '')) > 0
        WHERE t.WorkflowSessionId = s.Id)), '')
FROM workflow_sessions s
WHERE s.UserId = @owner AND s.CreatedAt < @fixed_since;

-- Drafts
INSERT INTO knk_u1_progress (Id)
SELECT p.Id FROM FormSubmissionProgresses p WHERE p.UserId = @owner AND p.CreatedAt < @fixed_since;
INSERT INTO knk_u1_progress_ids (Id) SELECT Id FROM knk_u1_progress;

-- What this run will do
SELECT 'workflow session' AS kind, x.Id AS id, s.EntityTypeName AS entity_type, s.EntityId AS entity_id, s.Status AS status,
       s.CreatedAt AS created_at,
       IF(x.KeptBecause IS NULL, 'delete', CONCAT('KEEP: ', x.KeptBecause)) AS action,
       CONCAT((SELECT COUNT(*) FROM step_progress t WHERE t.WorkflowSessionId = x.Id), ' step(s), ',
              (SELECT COUNT(*) FROM world_tasks t WHERE t.WorkflowSessionId = x.Id), ' world task(s)') AS own_rows
FROM knk_u1_session x JOIN workflow_sessions s ON s.Id = x.Id
UNION ALL
SELECT 'draft', x.Id, f.EntityTypeName, p.EntityId, p.Status, p.CreatedAt,
       IF(p.ParentProgressId IS NULL, 'delete', CONCAT('delete (child of ', p.ParentProgressId, ')')),
       CONCAT((SELECT COUNT(*) FROM FormSubmissionProgresses c
                WHERE c.ParentProgressId = x.Id AND c.Id NOT IN (SELECT Id FROM knk_u1_progress_ids)),
              ' child row(s) of other users unlinked')
FROM knk_u1_progress x
JOIN FormSubmissionProgresses p ON p.Id = x.Id
LEFT JOIN FormConfigurations f ON f.Id = p.FormConfigurationId
ORDER BY kind DESC, id;

START TRANSACTION;

-- Other users' rows keep their own data, without the link to a deleted parent.
UPDATE FormSubmissionProgresses c JOIN knk_u1_progress x ON x.Id = c.ParentProgressId
SET c.ParentProgressId = NULL
WHERE c.Id NOT IN (SELECT Id FROM knk_u1_progress_ids);
-- Within the deleted set too: the self-reference is RESTRICT and checked row by row.
UPDATE FormSubmissionProgresses p JOIN knk_u1_progress x ON x.Id = p.Id SET p.ParentProgressId = NULL;
DELETE p FROM FormSubmissionProgresses p JOIN knk_u1_progress x ON x.Id = p.Id;

-- Child rows explicitly first: the result doesn't depend on ON DELETE CASCADE.
DELETE t FROM world_tasks t JOIN knk_u1_session x ON x.Id = t.WorkflowSessionId WHERE x.KeptBecause IS NULL;
DELETE t FROM step_progress t JOIN knk_u1_session x ON x.Id = t.WorkflowSessionId WHERE x.KeptBecause IS NULL;
DELETE s FROM workflow_sessions s JOIN knk_u1_session x ON x.Id = s.Id WHERE x.KeptBecause IS NULL;

COMMIT;

-- Counts (no ROW_COUNT(): phpMyAdmin resets it between statements)
SELECT 'workflow sessions' AS kind, COUNT(*) AS found, COALESCE(SUM(x.KeptBecause IS NULL), 0) AS deleted,
       COALESCE(SUM(x.KeptBecause IS NOT NULL), 0) AS kept, COUNT(s.Id) AS still_in_database
FROM knk_u1_session x LEFT JOIN workflow_sessions s ON s.Id = x.Id
UNION ALL
SELECT 'drafts', COUNT(*), COUNT(*) - COUNT(p.Id), 0, COUNT(p.Id)
FROM knk_u1_progress x LEFT JOIN FormSubmissionProgresses p ON p.Id = x.Id;

DROP TEMPORARY TABLE knk_u1_session, knk_u1_progress, knk_u1_progress_ids;
