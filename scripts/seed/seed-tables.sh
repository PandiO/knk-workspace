# Table manifest for the production seed data set.
# Sourced by export-seed.sh and import-seed.sh, never run on its own.
# Every table in the knk-web-api schema must appear in exactly one list below;
# export-seed.sh refuses to run while a table is unclassified, so a new
# migration that adds a table forces a decision here.
# Living document: docs/guides/production-installation.md § 7.

# Curated content authored in the dev DB through the web app or seeded at startup.
# Shipped with every seed.
CONTENT_TABLES="
FormConfigurations FormSteps FormFields FieldValidations FieldValidationRules StepConditions
DisplayConditionGroups DisplayConditions DisplayConfigurations DisplaySections DisplayFields
entity_type_configurations
minecraftmaterialrefs minecraftblockrefs minecraftenchantmentrefs
EnchantmentDefinitions AbilityDefinitions
categories CategoryTag grades tags item_blueprints ItemBlueprintTag ItemBlueprintDefaultEnchantment
menu_templates menu_section_templates menu_item_templates
menu_variable_bindings menu_action_bindings menu_condition_bindings
kits kit_contents
lootbox_types lootbox_type_grade_weights lootbox_pool_entries lootbox_enchant_rolls
lootbox_special_entries lootbox_configurations
title_brackets permission_groups salary_configurations discovery_reward_rules currency_policies
game_settings audit_log_retention_configurations siege_configurations
"

# Permission tables shared by users and groups (TPT: users and groups share the
# permission_holders id space). Exported filtered to group rows only.
GROUP_FILTERED_TABLES="permission_holders permission_grants"

# Rows tied to the Minecraft world map: domains and their WorldGuard region ids,
# coordinates, gates, siege scenarios, lootbox areas. Ship them only together
# with a copy of the matching world folder (export-seed.sh --with-world).
WORLD_TABLES="
domains towns districts structures streets locations DistrictStreet TownStreet
domain_discovery_overrides item_blueprint_origins
gate_structures gate_structure_guard_spawn_locations gate_doors gate_block_snapshots
gate_opened_block_snapshots
banner_designs banner_layers clans
siege_scenarios siege_scenario_districts siege_teams siege_spawnpoints siege_objectives
siege_scenario_gates siege_lobbies siege_lobby_scenarios
lootbox_spawn_area_types lootbox_spawn_areas
"

# Player and runtime data. Never part of a seed.
RUNTIME_TABLES="
__EFMigrationsHistory
users user_permission_groups linkcodes refresh_tokens
currency_transactions currency_entries currency_pending_transfers currency_alerts teleport_fee_voids
item_instances item_instance_enchantments kit_claims kit_purchases
lootbox_spawns lootbox_claims lootbox_tokens lootbox_token_grants
audit_log_entries user_domain_discoveries user_ignores private_message_log_entries
FormSubmissionProgresses workflow_sessions step_progress world_tasks
siege_matches siege_match_participants siege_match_objective_results siege_match_gate_snapshots
"

# Content columns that point at a user. The seed ships without users, so the
# import clears them.
USER_REFERENCE_COLUMNS="currency_policies.UpdatedByUserId lootbox_spawn_areas.CreatedByUserId"
