-- Town streets check before the TownStreet table is dropped (PandiO/knk-workspace#409, link L1 #514).
-- READ ONLY: SELECT statements only. It changes nothing and can be run as often as you like.
--
-- After #409, Town.Streets is the distinct streets of the town's districts (District.Streets) and the separate link
-- table TownStreet is dropped. This check lists what that drop would lose, so the developer can decide per row:
--   1. orphans: TownStreet rows whose street is in none of the town's districts, with town and street names and the
--      districts (of any town) the street is linked to today. These links disappear with the table unless the street
--      is first linked to a district of that town (District detail page, Streets section, Add...).
--   2. counts: all TownStreet rows, orphans, rows the derived list already covers, and the streets the derived list
--      will show that TownStreet does not have today.
--   3. stored configurations: form and display configurations of Town that name Streets / StreetIds, and validation
--      rules whose path or message names Town.Streets (see the design note § 4).
--
-- Table and column names are those of the EF model on knk-web-api `next` (b9ce7f05, 2026-11-14):
--   TownStreet(TownId, StreetId)       hidden join table of Town.Streets (KnKDbContext.cs, "TownStreet")
--   DistrictStreet(DistrictId, StreetId) hidden join table of District.Streets / Street.Districts
--   districts(Id, TownId)              TPT child of domains (District.TownId is required)
--   towns(Id)                          TPT child of domains
--   domains(Id, Name)                  the shared Domain table: the names of towns and districts
--   streets(Id, Name)
--   FormConfigurations / FormSteps / FormFields / FieldValidationRules, DisplayConfigurations / DisplaySections /
--   DisplayFields                      the stored form and display configurations
--
-- Usage: the design note docs/specs/towns/DESIGN_TOWN_STREETS.md § 6.2. In short, with the MySQL client:
--   mysql -u<user> -p <database> < town-street-orphans-409.sql
-- (dev: your local knightsandkings database; alpha: inside the knk-alpha-mysql container, database
-- knightsandkings_alpha), or paste it into phpMyAdmin's SQL tab. Three result sets come back, in the order above.
-- Written for MySQL 8.0+ (alpha runs 9.6); also runs on MariaDB 10.4+.

-- 1. Orphan TownStreet rows: the street is in none of the town's districts.
SELECT
    ts.TownId                                   AS town_id,
    town_domain.Name                            AS town_name,
    ts.StreetId                                 AS street_id,
    s.Name                                      AS street_name,
    (SELECT GROUP_CONCAT(DISTINCT CONCAT(dd.Name, ' (#', d.Id, ', town #', d.TownId, ')')
                         ORDER BY dd.Name SEPARATOR '; ')
       FROM DistrictStreet ds
       JOIN districts d   ON d.Id = ds.DistrictId
       JOIN domains dd    ON dd.Id = d.Id
      WHERE ds.StreetId = ts.StreetId)          AS street_districts_any_town,
    (SELECT GROUP_CONCAT(DISTINCT CONCAT(dd.Name, ' (#', d.Id, ')') ORDER BY dd.Name SEPARATOR '; ')
       FROM districts d
       JOIN domains dd    ON dd.Id = d.Id
      WHERE d.TownId = ts.TownId)               AS town_districts
FROM TownStreet ts
JOIN towns t                ON t.Id = ts.TownId
JOIN domains town_domain    ON town_domain.Id = t.Id
JOIN streets s              ON s.Id = ts.StreetId
WHERE NOT EXISTS (
    SELECT 1
      FROM DistrictStreet ds
      JOIN districts d ON d.Id = ds.DistrictId
     WHERE ds.StreetId = ts.StreetId
       AND d.TownId = ts.TownId)
ORDER BY town_domain.Name, ts.TownId, s.Name, ts.StreetId;

-- 2. Counts.
SELECT
    (SELECT COUNT(*) FROM TownStreet)                                   AS town_street_rows,
    (SELECT COUNT(*)
       FROM TownStreet ts
      WHERE NOT EXISTS (SELECT 1 FROM DistrictStreet ds JOIN districts d ON d.Id = ds.DistrictId
                         WHERE ds.StreetId = ts.StreetId AND d.TownId = ts.TownId))
                                                                        AS orphan_rows,
    (SELECT COUNT(*)
       FROM TownStreet ts
      WHERE EXISTS (SELECT 1 FROM DistrictStreet ds JOIN districts d ON d.Id = ds.DistrictId
                     WHERE ds.StreetId = ts.StreetId AND d.TownId = ts.TownId))
                                                                        AS rows_covered_by_districts,
    (SELECT COUNT(*)
       FROM (SELECT DISTINCT d.TownId, ds.StreetId
               FROM DistrictStreet ds JOIN districts d ON d.Id = ds.DistrictId) derived)
                                                                        AS derived_town_street_pairs,
    (SELECT COUNT(*)
       FROM (SELECT DISTINCT d.TownId, ds.StreetId
               FROM DistrictStreet ds JOIN districts d ON d.Id = ds.DistrictId) derived
      WHERE NOT EXISTS (SELECT 1 FROM TownStreet ts
                         WHERE ts.TownId = derived.TownId AND ts.StreetId = derived.StreetId))
                                                                        AS derived_pairs_new_on_town_page;

-- 3. Stored configurations that name Town.Streets.
SELECT 'display section' AS kind, dc.Id AS configuration_id, dc.Name AS configuration_name,
       ds.Id AS item_id, ds.SectionName AS item_name, ds.RelatedEntityPropertyName AS detail
  FROM DisplaySections ds
  LEFT JOIN DisplaySections parent ON parent.Id = ds.ParentSectionId
  JOIN DisplayConfigurations dc ON dc.Id = COALESCE(ds.DisplayConfigurationId, parent.DisplayConfigurationId)
 WHERE dc.EntityTypeName = 'Town' AND ds.RelatedEntityPropertyName IN ('Streets', 'streets')
UNION ALL
SELECT 'display field', dc.Id, dc.Name, df.Id, df.Label, df.FieldName
  FROM DisplayFields df
  JOIN DisplaySections ds       ON ds.Id = df.DisplaySectionId
  LEFT JOIN DisplaySections parent ON parent.Id = ds.ParentSectionId
  JOIN DisplayConfigurations dc ON dc.Id = COALESCE(ds.DisplayConfigurationId, parent.DisplayConfigurationId)
 WHERE dc.EntityTypeName = 'Town' AND ds.RelatedEntityPropertyName IS NULL
   AND (df.FieldName LIKE 'Streets%' OR df.FieldName LIKE 'streets%' OR df.FieldName IN ('StreetIds', 'streetIds'))
UNION ALL
SELECT 'display draft', dc.Id, dc.Name, NULL, NULL, 'DraftJson names Streets'
  FROM DisplayConfigurations dc
 WHERE dc.EntityTypeName = 'Town' AND dc.DraftJson LIKE '%treets%'
UNION ALL
SELECT 'form step', fc.Id, fc.Name, fs.Id, NULL, fs.RelatedEntityPropertyName
  FROM FormSteps fs
  JOIN FormConfigurations fc ON fc.Id = fs.FormConfigurationId
 WHERE fc.EntityTypeName = 'Town' AND fs.RelatedEntityPropertyName IN ('Streets', 'streets')
UNION ALL
SELECT 'form field', fc.Id, fc.Name, ff.Id, ff.Label, ff.FieldName
  FROM FormFields ff
  JOIN FormSteps fs          ON fs.Id = ff.FormStepId
  JOIN FormConfigurations fc ON fc.Id = fs.FormConfigurationId
 WHERE fc.EntityTypeName = 'Town' AND ff.FieldName IN ('Streets', 'streets', 'StreetIds', 'streetIds')
UNION ALL
SELECT 'form draft', fc.Id, fc.Name, NULL, NULL, 'DraftJson names Streets'
  FROM FormConfigurations fc
 WHERE fc.EntityTypeName = 'Town' AND fc.DraftJson LIKE '%treets%'
UNION ALL
SELECT 'validation rule', NULL, NULL, r.Id, NULL, CONCAT('form field #', r.FormFieldId)
  FROM FieldValidationRules r
 WHERE r.DependencyPath LIKE '%Town.Streets%' OR r.ConfigJson LIKE '%Town.Streets%'
    OR r.ErrorMessage LIKE '%Town.Streets%' OR r.SuccessMessage LIKE '%Town.Streets%'
ORDER BY kind, configuration_id, item_id;
