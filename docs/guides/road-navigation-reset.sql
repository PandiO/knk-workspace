-- Road navigation (KNG-27 / KNG-51): delete ALL road network data, to rebuild from scratch.
--
-- Target:  the knk-web-api MySQL database (dev), schema from migration 20260927190750_AddRoadNetwork
--          (knk-web-api branch claude/road-navigation, checked at 6947e2a on 2026-10-04).
-- Deletes: road_edges, road_nodes (incl. Pruned/PrunedEdge tombstones, locked/merged nodes, anchors),
--          road_tiles, road_seeds, road_surveys. Profiles: see PART 2 (kept unless you uncomment it).
-- Keeps:   streets (names) and everything outside the road_* tables. road_edges.StreetId is the only link
--          from roads to streets; deleting edges does not touch streets.
--
-- Before:  1. Back up:  mysqldump <db> road_profiles road_surveys road_tiles road_seeds road_nodes road_edges > roads-backup.sql
--          2. Stop the Minecraft server (or at least run no /knk road build / survey / record while this runs).
-- After:   3. Delete the plugin's local tile cache: plugins/KnightsAndKings/roads/  (the plugin data folder +
--             "roads"); otherwise the plugin keeps serving the old tiles from disk.
--          4. Start the server; /knk road status should show 0 nodes / 0 edges / 0 tiles per world.
--
-- Uses DELETE (not TRUNCATE) so it runs in one transaction and respects the foreign keys.

START TRANSACTION;

-- What is about to go (for the record)
SELECT 'road_edges'    AS tbl, COUNT(*) AS road_rows FROM road_edges
UNION ALL SELECT 'road_nodes',    COUNT(*) FROM road_nodes
UNION ALL SELECT 'road_tiles',    COUNT(*) FROM road_tiles
UNION ALL SELECT 'road_seeds',    COUNT(*) FROM road_seeds
UNION ALL SELECT 'road_surveys',  COUNT(*) FROM road_surveys
UNION ALL SELECT 'road_profiles', COUNT(*) FROM road_profiles;

-- ==================== PART 1: the network (always) ====================
-- Children first: edges reference nodes, tiles, streets, profiles; nodes reference tiles;
-- seeds reference surveys; surveys reference profiles and users.
DELETE FROM road_edges;
DELETE FROM road_nodes;
DELETE FROM road_tiles;
DELETE FROM road_seeds;
DELETE FROM road_surveys;

-- Optional, one world only: replace the five DELETEs above with
--   DELETE FROM road_edges   WHERE World = 'world';
--   DELETE FROM road_nodes   WHERE World = 'world';
--   DELETE FROM road_tiles   WHERE World = 'world';
--   DELETE FROM road_seeds   WHERE World = 'world';
--   DELETE FROM road_surveys WHERE World = 'world';

-- ==================== PART 2: profiles (optional) ====================
-- Uncomment to also forget every learned profile and start over with the migration's
-- bootstrap "Default road" profile (the migration's seed row is NOT re-inserted by EF on its own).
--
-- DELETE FROM road_profiles;
-- INSERT INTO road_profiles
--   (Name, RoadClass, CostMultiplier, MaterialsJson, WidthMin, WidthMax, SampleCount, Enabled, ScopeTownIdsJson, StatsJson, CreatedAt, UpdatedAt)
-- VALUES
--   ('Default road', 'Road', 1.0,
--    '[{"material":"GRAVEL","role":"Surface","ambiguous":false,"centreShare":0,"edgeShare":0,"samples":0},{"material":"DIRT_PATH","role":"Surface","ambiguous":false,"centreShare":0,"edgeShare":0,"samples":0},{"material":"COARSE_DIRT","role":"Surface","ambiguous":false,"centreShare":0,"edgeShare":0,"samples":0},{"material":"COBBLESTONE","role":"Surface","ambiguous":true,"centreShare":0,"edgeShare":0,"samples":0},{"material":"STONE_BRICKS","role":"Surface","ambiguous":true,"centreShare":0,"edgeShare":0,"samples":0},{"material":"COBBLESTONE_SLAB","role":"Accent","ambiguous":false,"centreShare":0,"edgeShare":0,"samples":0},{"material":"COBBLESTONE_STAIRS","role":"Accent","ambiguous":false,"centreShare":0,"edgeShare":0,"samples":0},{"material":"STONE_BRICK_SLAB","role":"Accent","ambiguous":false,"centreShare":0,"edgeShare":0,"samples":0},{"material":"STONE_BRICK_STAIRS","role":"Accent","ambiguous":false,"centreShare":0,"edgeShare":0,"samples":0},{"material":"MOSSY_COBBLESTONE","role":"Accent","ambiguous":false,"centreShare":0,"edgeShare":0,"samples":0},{"material":"MOSSY_STONE_BRICKS","role":"Accent","ambiguous":false,"centreShare":0,"edgeShare":0,"samples":0},{"material":"CRACKED_STONE_BRICKS","role":"Accent","ambiguous":false,"centreShare":0,"edgeShare":0,"samples":0}]',
--    1, 7, 0, 1, NULL, '{}', '2026-09-27 00:00:00', '2026-09-27 00:00:00');
--
-- Instead of the "Default road" re-insert you can leave road_profiles empty and create the
-- profiles from your new surveys (/knk road survey start "<name>" → Save).

-- Check: every count should be 0 (road_profiles: what you kept)
SELECT 'road_edges'    AS tbl, COUNT(*) AS road_rows FROM road_edges
UNION ALL SELECT 'road_nodes',    COUNT(*) FROM road_nodes
UNION ALL SELECT 'road_tiles',    COUNT(*) FROM road_tiles
UNION ALL SELECT 'road_seeds',    COUNT(*) FROM road_seeds
UNION ALL SELECT 'road_surveys',  COUNT(*) FROM road_surveys
UNION ALL SELECT 'road_profiles', COUNT(*) FROM road_profiles;

COMMIT;   -- or ROLLBACK; if the counts above look wrong
