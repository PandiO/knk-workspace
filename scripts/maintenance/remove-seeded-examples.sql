-- Remove the example rows the API's startup seeders created (one-time cleanup, closed alpha, 2026-10-25).
--
-- The API seeds on every start, create-only by natural key, so builds without Seeding:IncludeExamples recreate the
-- examples that the knk seed (knk-dev-db-seed) leaves out. On knightsandkings_alpha the first start of API a38c8ee
-- after loading the seed added 9 menus (27 instead of 18), 1 siege lobby (2), 18 item blueprints (158 instead of
-- 140) and 1 tag (8). First deploy an API build with Seeding__IncludeExamples=false (otherwise the next start makes
-- them again), then run this once. docs/guides/alpha-go-live.md § 4 has the steps.
--
-- Deleted, matched by natural key exactly (case and spaces), together with their own rows:
--   menu_templates   Key example.placeholder, .pagination, .permissions, .search, .conditions, .presets, .catalog,
--                    .domain, .domain.detail (MenuTemplateSeed): sections, items, action/condition/variable bindings;
--   siege_lobbies    Key example (SiegeLobbySeed);
--   item_blueprints  the 18 trade goods Bolt of Silk ... Sack of Flour (ItemBlueprintExampleCatalogSeed): default
--                    enchantments, tag links, origins;
--   tags             Name Test (KitSeed).
-- A row that something real still uses is listed with the reason and kept:
--   menu       an action or condition binding of a menu outside this list names its key (menu.open, menu-available);
--   lobby      siege matches, scenarios in its rotation, or enabled;
--   blueprint  item instances, kit equipment or kit contents, lootbox pool or special entries, lootbox claims;
--   tag        a category, or a blueprint that stays.
-- An example menu opened only by another example menu (example.domain -> example.domain.detail) is deleted even when
-- that other menu is kept.
--
-- Usage (back up first, docs/guides/alpha-go-live.md § 3 step 1): run the whole file with the MySQL client inside the
-- knk-alpha-mysql container, as root, like repair-holder-id-clash.sql:
--   mysql -uroot -p knightsandkings_alpha < remove-seeded-examples.sql
-- or paste it into phpMyAdmin's SQL tab with "Enable foreign key checks" left TICKED (it runs as one batch, which the
-- temporary tables need). The first result lists every example row found and what happens to it; the last one counts
-- them (still_in_database = kept). A second run finds only the kept rows, or nothing, and changes nothing. A failed
-- run commits nothing. Written for MySQL 9.6 and uses nothing newer than MySQL 8.0. Tried on 2026-10-25 against the
-- seed on MariaDB 10.4, after an API start had added the examples: afterwards every table it touches matched the seed.
--
-- References as of migration 20261024224826_AddSiegeSkipSeconds (re-check after new migrations):
--   item_blueprints.Id  own rows: ItemBlueprintDefaultEnchantment, ItemBlueprintTag, item_blueprint_origins;
--                       real use: item_instances, kits.{Helmet,Chestplate,Leggings,Boots,Shield,Hand}Id, kit_contents,
--                       lootbox_pool_entries, lootbox_special_entries, lootbox_claims.
--   menu_templates.Id   own rows: menu_section_templates > menu_item_templates > menu_action_bindings,
--                       menu_condition_bindings, menu_variable_bindings (items and sections); other menus name it by
--                       key in ParamsJson. menu_funnel_daily keeps its analytics rows by key (no foreign key).
--   siege_lobbies.Id    siege_lobby_scenarios, siege_matches.
--   tags.Id             CategoryTag, ItemBlueprintTag.

-- RESTRICT foreign keys stop the run if a real reference was missed above.
SET FOREIGN_KEY_CHECKS = 1;
SET SESSION group_concat_max_len = 65535;

DROP TEMPORARY TABLE IF EXISTS knk_ex_menu, knk_ex_menu_ids, knk_ex_lobby, knk_ex_blueprint, knk_ex_tag;
-- KeptBecause is NULL for a row that will be deleted. MySQL opens a temporary table only once per statement, hence
-- the second copy of the menu ids.
CREATE TEMPORARY TABLE knk_ex_menu (Id INT PRIMARY KEY, KeptBecause TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL);
CREATE TEMPORARY TABLE knk_ex_menu_ids (Id INT PRIMARY KEY);
CREATE TEMPORARY TABLE knk_ex_lobby (Id INT PRIMARY KEY, KeptBecause TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL);
CREATE TEMPORARY TABLE knk_ex_blueprint (Id INT PRIMARY KEY, KeptBecause TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL);
CREATE TEMPORARY TABLE knk_ex_tag (Id INT PRIMARY KEY, KeptBecause TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL);

-- Menus
INSERT INTO knk_ex_menu (Id)
SELECT Id FROM menu_templates
WHERE `Key` COLLATE utf8mb4_bin IN ('example.placeholder', 'example.pagination', 'example.permissions',
    'example.search', 'example.conditions', 'example.presets', 'example.catalog', 'example.domain',
    'example.domain.detail');
INSERT INTO knk_ex_menu_ids (Id) SELECT Id FROM knk_ex_menu;

UPDATE knk_ex_menu x
SET x.KeptBecause = (
    SELECT CONCAT('named by menu ', GROUP_CONCAT(DISTINCT r.MenuKey ORDER BY r.MenuKey SEPARATOR ', '))
    FROM (
        SELECT rs.MenuTemplateId, rm.`Key` AS MenuKey, a.ParamsJson
        FROM menu_action_bindings a
        JOIN menu_item_templates ri ON ri.Id = a.MenuItemTemplateId
        JOIN menu_section_templates rs ON rs.Id = ri.MenuSectionTemplateId
        JOIN menu_templates rm ON rm.Id = rs.MenuTemplateId
        UNION ALL
        SELECT rs.MenuTemplateId, rm.`Key`, c.ParamsJson
        FROM menu_condition_bindings c
        JOIN menu_item_templates ri ON ri.Id = c.MenuItemTemplateId
        JOIN menu_section_templates rs ON rs.Id = ri.MenuSectionTemplateId
        JOIN menu_templates rm ON rm.Id = rs.MenuTemplateId
    ) r, menu_templates target
    WHERE target.Id = x.Id
      AND r.MenuTemplateId NOT IN (SELECT Id FROM knk_ex_menu_ids)
      AND LOCATE(CONCAT('"', target.`Key`, '"'), r.ParamsJson) > 0
);

-- Siege lobby
INSERT INTO knk_ex_lobby (Id, KeptBecause)
SELECT l.Id, NULLIF(CONCAT_WS('; ',
    IF(l.IsEnabled, 'enabled', NULL),
    (SELECT CONCAT(COUNT(*), ' scenario(s) in its rotation') FROM siege_lobby_scenarios t
        WHERE t.SiegeLobbyId = l.Id HAVING COUNT(*) > 0),
    (SELECT CONCAT(COUNT(*), ' siege match(es)') FROM siege_matches t
        WHERE t.SiegeLobbyId = l.Id HAVING COUNT(*) > 0)), '')
FROM siege_lobbies l
WHERE l.`Key` COLLATE utf8mb4_bin = 'example';

-- Trade-good blueprints
INSERT INTO knk_ex_blueprint (Id, KeptBecause)
SELECT b.Id, NULLIF(CONCAT_WS('; ',
    (SELECT CONCAT(COUNT(*), ' item instance(s)') FROM item_instances t
        WHERE t.ItemBlueprintId = b.Id HAVING COUNT(*) > 0),
    (SELECT CONCAT('equipment of kit ', GROUP_CONCAT(k.Name ORDER BY k.Name SEPARATOR ', ')) FROM kits k
        WHERE b.Id IN (k.HelmetId, k.ChestplateId, k.LeggingsId, k.BootsId, k.ShieldId, k.HandId)),
    (SELECT CONCAT('contents of kit ', GROUP_CONCAT(DISTINCT k.Name ORDER BY k.Name SEPARATOR ', ')) FROM kit_contents t
        JOIN kits k ON k.Id = t.KitId WHERE t.ItemBlueprintId = b.Id),
    (SELECT CONCAT('pool of lootbox ', GROUP_CONCAT(DISTINCT lt.Name ORDER BY lt.Name SEPARATOR ', '))
        FROM lootbox_pool_entries t JOIN lootbox_types lt ON lt.Id = t.LootboxTypeId WHERE t.ItemBlueprintId = b.Id),
    (SELECT CONCAT(COUNT(*), ' lootbox special entr(y/ies)') FROM lootbox_special_entries t
        WHERE t.ItemBlueprintId = b.Id HAVING COUNT(*) > 0),
    (SELECT CONCAT(COUNT(*), ' lootbox claim(s)') FROM lootbox_claims t
        WHERE t.ItemBlueprintId = b.Id HAVING COUNT(*) > 0)), '')
FROM item_blueprints b
WHERE b.Name COLLATE utf8mb4_bin IN ('Bolt of Silk', 'Sack of Grain', 'Crate of Spices', 'Barrel of Ale',
    'Ingot of Iron', 'Ingot of Copper', 'Coil of Rope', 'Bundle of Furs', 'Jar of Honey', 'Crate of Pottery',
    'Bolt of Wool', 'Sack of Salt', 'Crate of Timber', 'Ingot of Tin', 'Jug of Oil', 'Bundle of Herbs',
    'Crate of Glassware', 'Sack of Flour');

-- Test tag (after the blueprints: a link from a trade good deleted here doesn't keep it)
INSERT INTO knk_ex_tag (Id, KeptBecause)
SELECT g.Id, NULLIF(CONCAT_WS('; ',
    (SELECT CONCAT('category ', GROUP_CONCAT(c.Name ORDER BY c.Name SEPARATOR ', ')) FROM CategoryTag t
        JOIN categories c ON c.Id = t.CategoryId WHERE t.TagId = g.Id),
    (SELECT CONCAT('item blueprint ', GROUP_CONCAT(ib.Name ORDER BY ib.Name SEPARATOR ', ')) FROM ItemBlueprintTag t
        JOIN item_blueprints ib ON ib.Id = t.ItemBlueprintId
        WHERE t.TagId = g.Id
          AND t.ItemBlueprintId NOT IN (SELECT Id FROM knk_ex_blueprint WHERE KeptBecause IS NULL))), '')
FROM tags g
WHERE g.Name COLLATE utf8mb4_bin = 'Test';

-- What this run will do
SELECT 'menu' AS kind, x.Id AS id, m.`Key` AS natural_key,
       IF(x.KeptBecause IS NULL, 'delete', CONCAT('KEEP: ', x.KeptBecause)) AS action,
       (SELECT CONCAT(COUNT(DISTINCT s.Id), ' section(s), ', COUNT(i.Id), ' item(s)') FROM menu_section_templates s
            LEFT JOIN menu_item_templates i ON i.MenuSectionTemplateId = s.Id WHERE s.MenuTemplateId = x.Id) AS own_rows
FROM knk_ex_menu x JOIN menu_templates m ON m.Id = x.Id
UNION ALL
SELECT 'siege lobby', x.Id, l.`Key`,
       IF(x.KeptBecause IS NULL, 'delete', CONCAT('KEEP: ', x.KeptBecause)),
       CONCAT(IF(l.IsEnabled, 'enabled', 'disabled'), ', ', l.Name)
FROM knk_ex_lobby x JOIN siege_lobbies l ON l.Id = x.Id
UNION ALL
SELECT 'item blueprint', x.Id, b.Name,
       IF(x.KeptBecause IS NULL, 'delete', CONCAT('KEEP: ', x.KeptBecause)),
       CONCAT((SELECT COUNT(*) FROM ItemBlueprintDefaultEnchantment t WHERE t.ItemBlueprintId = x.Id), ' enchantment(s), ',
              (SELECT COUNT(*) FROM ItemBlueprintTag t WHERE t.ItemBlueprintId = x.Id), ' tag(s), ',
              (SELECT COUNT(*) FROM item_blueprint_origins t WHERE t.ItemBlueprintId = x.Id), ' origin(s)')
FROM knk_ex_blueprint x JOIN item_blueprints b ON b.Id = x.Id
UNION ALL
SELECT 'tag', x.Id, g.Name,
       IF(x.KeptBecause IS NULL, 'delete', CONCAT('KEEP: ', x.KeptBecause)),
       CONCAT((SELECT COUNT(*) FROM ItemBlueprintTag t WHERE t.TagId = x.Id), ' blueprint link(s)')
FROM knk_ex_tag x JOIN tags g ON g.Id = x.Id
ORDER BY kind, natural_key;

START TRANSACTION;

-- Child rows explicitly, deepest first: the result doesn't depend on ON DELETE CASCADE.
DELETE c FROM menu_condition_bindings c
    JOIN menu_item_templates i ON i.Id = c.MenuItemTemplateId
    JOIN menu_section_templates s ON s.Id = i.MenuSectionTemplateId
    JOIN knk_ex_menu x ON x.Id = s.MenuTemplateId
WHERE x.KeptBecause IS NULL;
DELETE a FROM menu_action_bindings a
    JOIN menu_item_templates i ON i.Id = a.MenuItemTemplateId
    JOIN menu_section_templates s ON s.Id = i.MenuSectionTemplateId
    JOIN knk_ex_menu x ON x.Id = s.MenuTemplateId
WHERE x.KeptBecause IS NULL;
DELETE v FROM menu_variable_bindings v
    JOIN menu_item_templates i ON i.Id = v.MenuItemTemplateId
    JOIN menu_section_templates s ON s.Id = i.MenuSectionTemplateId
    JOIN knk_ex_menu x ON x.Id = s.MenuTemplateId
WHERE x.KeptBecause IS NULL;
DELETE v FROM menu_variable_bindings v
    JOIN menu_section_templates s ON s.Id = v.MenuSectionTemplateId
    JOIN knk_ex_menu x ON x.Id = s.MenuTemplateId
WHERE x.KeptBecause IS NULL;
DELETE i FROM menu_item_templates i
    JOIN menu_section_templates s ON s.Id = i.MenuSectionTemplateId
    JOIN knk_ex_menu x ON x.Id = s.MenuTemplateId
WHERE x.KeptBecause IS NULL;
DELETE s FROM menu_section_templates s JOIN knk_ex_menu x ON x.Id = s.MenuTemplateId WHERE x.KeptBecause IS NULL;
DELETE m FROM menu_templates m JOIN knk_ex_menu x ON x.Id = m.Id WHERE x.KeptBecause IS NULL;

-- A lobby with a rotation is kept, so this removes nothing; it keeps the delete below safe on its own.
DELETE t FROM siege_lobby_scenarios t JOIN knk_ex_lobby x ON x.Id = t.SiegeLobbyId WHERE x.KeptBecause IS NULL;
DELETE l FROM siege_lobbies l JOIN knk_ex_lobby x ON x.Id = l.Id WHERE x.KeptBecause IS NULL;

DELETE t FROM ItemBlueprintDefaultEnchantment t JOIN knk_ex_blueprint x ON x.Id = t.ItemBlueprintId WHERE x.KeptBecause IS NULL;
DELETE t FROM ItemBlueprintTag t JOIN knk_ex_blueprint x ON x.Id = t.ItemBlueprintId WHERE x.KeptBecause IS NULL;
DELETE t FROM item_blueprint_origins t JOIN knk_ex_blueprint x ON x.Id = t.ItemBlueprintId WHERE x.KeptBecause IS NULL;
DELETE b FROM item_blueprints b JOIN knk_ex_blueprint x ON x.Id = b.Id WHERE x.KeptBecause IS NULL;

-- Only links of blueprints deleted above can be left: any other link keeps the tag.
DELETE t FROM ItemBlueprintTag t JOIN knk_ex_tag x ON x.Id = t.TagId WHERE x.KeptBecause IS NULL;
DELETE g FROM tags g JOIN knk_ex_tag x ON x.Id = g.Id WHERE x.KeptBecause IS NULL;

COMMIT;

-- Counts (no ROW_COUNT(): phpMyAdmin resets it between statements)
SELECT 'menus' AS kind, COUNT(*) AS found, COALESCE(SUM(x.KeptBecause IS NULL), 0) AS deleted,
       COALESCE(SUM(x.KeptBecause IS NOT NULL), 0) AS kept, COUNT(m.Id) AS still_in_database
FROM knk_ex_menu x LEFT JOIN menu_templates m ON m.Id = x.Id
UNION ALL
SELECT 'siege lobbies', COUNT(*), COALESCE(SUM(x.KeptBecause IS NULL), 0), COALESCE(SUM(x.KeptBecause IS NOT NULL), 0), COUNT(l.Id)
FROM knk_ex_lobby x LEFT JOIN siege_lobbies l ON l.Id = x.Id
UNION ALL
SELECT 'item blueprints', COUNT(*), COALESCE(SUM(x.KeptBecause IS NULL), 0), COALESCE(SUM(x.KeptBecause IS NOT NULL), 0), COUNT(b.Id)
FROM knk_ex_blueprint x LEFT JOIN item_blueprints b ON b.Id = x.Id
UNION ALL
SELECT 'tags', COUNT(*), COALESCE(SUM(x.KeptBecause IS NULL), 0), COALESCE(SUM(x.KeptBecause IS NOT NULL), 0), COUNT(g.Id)
FROM knk_ex_tag x LEFT JOIN tags g ON g.Id = x.Id;

DROP TEMPORARY TABLE knk_ex_menu, knk_ex_menu_ids, knk_ex_lobby, knk_ex_blueprint, knk_ex_tag;
