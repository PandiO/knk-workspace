"""Extract Knights and Kings v1 item definitions from v1 playerdata and generate the
ItemBlueprintV1Seed table (docs/specs/items/V1_SEED_DATA.md).

v1 never persisted an ItemStack: every product was rebuilt from the Products table as
  name "§f<grade colour><DisplayName>", lore [custom enchant lines "§7<name> <roman>"...,
  "   ", "   ", "§l§bGrade: ★ ★ ★", optional "Soulbound"/"Ghosted"], plus unsafe vanilla
  enchantments. The v1 DB itself is gone, so the players' inventories/ender chests are the
  only surviving source. Stdlib only.

usage:
  python v1_items.py player   <playerdata-dir> <name|uuid>   # one player's named items
  python v1_items.py report   <playerdata-dir>               # consensus per item, all players
  python v1_items.py generate <playerdata-dir>               # C# rows for ItemBlueprintV1Seed
"""
import sys, os, re, json, glob, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import nbt

DEFAULT_DIR = ('MinecraftServer/Servers/Archive/K&K_OpenBeta_Archive_17-08-22/Server/Old_KnK/playerdata')

# Pre-1.13 numeric enchantment ids -> modern keys.
ENCH = {0: 'protection', 1: 'fire_protection', 2: 'feather_falling', 3: 'blast_protection',
        4: 'projectile_protection', 5: 'respiration', 6: 'aqua_affinity', 7: 'thorns',
        8: 'depth_strider', 9: 'frost_walker', 10: 'binding_curse', 16: 'sharpness', 17: 'smite',
        18: 'bane_of_arthropods', 19: 'knockback', 20: 'fire_aspect', 21: 'looting', 22: 'sweeping',
        32: 'efficiency', 33: 'silk_touch', 34: 'unbreaking', 35: 'fortune', 48: 'power',
        49: 'punch', 50: 'flame', 51: 'infinity', 61: 'luck_of_the_sea', 62: 'lure',
        70: 'mending', 71: 'vanishing_curse'}

# Pre-flattening (id, Damage) -> 1.13+ key, for ids whose name changed. Damage is durability for
# tools/armor, so it's only consulted for ids listed in RENAMED.
LEGACY = {
    ('log', 0): 'oak_log', ('log', 1): 'spruce_log', ('log', 2): 'birch_log', ('log', 3): 'jungle_log',
    ('log2', 0): 'acacia_log', ('log2', 1): 'dark_oak_log',
    ('planks', 0): 'oak_planks', ('planks', 1): 'spruce_planks', ('planks', 2): 'birch_planks',
    ('planks', 3): 'jungle_planks', ('planks', 4): 'acacia_planks', ('planks', 5): 'dark_oak_planks',
    ('stonebrick', 0): 'stone_bricks', ('stonebrick', 1): 'mossy_stone_bricks',
    ('stonebrick', 2): 'cracked_stone_bricks', ('stonebrick', 3): 'chiseled_stone_bricks',
    ('grass', 0): 'grass_block', ('wool', 0): 'white_wool', ('fish', 0): 'cod', ('fish', 1): 'salmon',
    ('cooked_fish', 0): 'cooked_cod', ('cooked_fish', 1): 'cooked_salmon',
    ('dye', 3): 'cocoa_beans', ('dye', 4): 'lapis_lazuli', ('dye', 15): 'bone_meal',
    ('red_flower', 0): 'poppy', ('yellow_flower', 0): 'dandelion', ('sapling', 0): 'oak_sapling',
    ('leaves', 0): 'oak_leaves', ('wooden_door', 0): 'oak_door', ('fence', 0): 'oak_fence',
    ('boat', 0): 'oak_boat', ('skull', 0): 'skeleton_skull', ('reeds', 0): 'sugar_cane',
    ('melon', 0): 'melon_slice', ('speckled_melon', 0): 'glistering_melon_slice',
    ('fireworks', 0): 'firework_rocket', ('golden_apple', 0): 'golden_apple',
    ('golden_apple', 1): 'enchanted_golden_apple',
}
RENAMED = {k for k, _ in LEGACY}

# The 12 custom enchantments of knk-plugin's EnchantmentRegistry (docs/specs/custom-enchantments/).
# v1 wrote them as lore "§7<name> <roman>", e.g. "§7blindness III" / "§7Health Boost I".
CUSTOM = {'poison', 'wither', 'freeze', 'blindness', 'confusion', 'strength', 'chaos', 'flash_chaos',
          'health_boost', 'armor_repair', 'resistance', 'invisibility'}
ROMAN = {'I': 1, 'II': 2, 'III': 3, 'IIII': 4, 'IV': 4, 'IIIII': 5, 'V': 5, 'IIIIII': 6, 'VI': 6}
COLOR = re.compile('§[0-9a-fk-or]', re.I)
GRADE = re.compile(r'Grade:\s*((?:★\s*)+)')
CUSTOM_LINE = re.compile(r'^([A-Za-z ]+?)\s+(I{1,6}|IV|V|VI)$')

def plain(s): return COLOR.sub('', s).strip()
def amp(s): return s.replace('§', '&')

def material(it):
    mid = it['id'].split(':', 1)[-1]; dmg = it.get('Damage', 0)
    if mid in RENAMED:
        key = LEGACY.get((mid, dmg))
        return ('minecraft:' + key, None) if key else ('minecraft:' + mid, f'unmapped legacy {mid}:{dmg}')
    return 'minecraft:' + mid, None

def parse(it, src):
    tag = it.get('tag') or {}; disp = tag.get('display') or {}
    name = disp.get('Name'); lore = disp.get('Lore') or []
    mat, warn = material(it)
    grade = None; custom = []; flags = []; desc = []
    for line in lore:
        p = plain(line)
        if not p: continue
        m = GRADE.search(p)
        if m: grade = m.group(1).count('★'); continue
        if p in ('Soulbound', 'Ghosted'): flags.append(p); continue
        m = CUSTOM_LINE.match(p)
        if m and m.group(1).strip().lower().replace(' ', '_') in CUSTOM:
            custom.append({'key': m.group(1).strip().lower().replace(' ', '_'), 'level': ROMAN[m.group(2)]})
            continue
        desc.append(amp(line))
    # v1 prefixes every product name with §f, then the grade colour.
    dn = amp(re.sub('^§f(?=§)', '', name)) if name else None
    vanilla = [{'key': 'minecraft:' + ENCH.get(e['id'], f"unknown_{e['id']}"), 'level': e['lvl']}
               for e in tag.get('ench', [])]
    return {'source': src, 'slot': it.get('Slot'), 'material': mat, 'count': it.get('Count', 1),
            'name': plain(name) if name else None, 'displayName': dn, 'grade': grade,
            'description': desc, 'vanillaEnchantments': vanilla, 'customEnchantments': custom,
            'instanceFlags': flags, 'warning': warn}

def named_items(d, who=None):
    for s in ('Inventory', 'EnderItems'):
        for i in d.get(s, []):
            if (i.get('tag') or {}).get('display', {}).get('Name'):
                r = parse(i, s); r['player'] = who; yield r

def collect(folder):
    groups = collections.OrderedDict()
    for p in sorted(glob.glob(os.path.join(folder, '*.dat'))):
        d = nbt.load(p)
        for r in named_items(d, (d.get('bukkit') or {}).get('lastKnownName') or os.path.basename(p)[:-4]):
            groups.setdefault((r['material'], r['name']), []).append(r)
    return groups

def majority(values):
    c = collections.Counter(v for v in values if v is not None)
    return c.most_common(1)[0][0] if c else None

def consensus(inst, field):
    """Enchantments present on every copy, at the lowest level seen. v1 rolled enchantments per
    copy (loot boxes, enchant books), so only what every copy shares is part of the item type."""
    sets = [{e['key']: e['level'] for e in i[field]} for i in inst]
    keys = set.intersection(*(set(s) for s in sets))
    return {k: min(s[k] for s in sets) for k in sorted(keys)}

# --- curation (see V1_SEED_DATA.md "Decisions") ---
SKIP_MATERIALS = {'minecraft:enchanted_book'}           # v1 enchant-book mechanic, not blueprints
SKIP_NAMES = {'Personal menu'}                          # v1 UI item (compass that opens the menu)
RENAME = {('minecraft:iron_boots', 'Halloween armor'): 'Halloween Armor Boots',
          ('minecraft:iron_leggings', 'Halloween armor'): 'Halloween Armor Leggings'}
CATEGORY_OVERRIDE = {'Life amulet': 'Trinkets'}
FOOD = {'cod', 'cooked_rabbit', 'cookie', 'golden_apple', 'apple', 'cooked_beef', 'cooked_chicken',
        'rabbit', 'chicken', 'bread', 'baked_potato', 'mushroom_stew', 'pumpkin_pie', 'melon_slice',
        'potato', 'carrot', 'beef', 'porkchop', 'cooked_porkchop', 'cooked_mutton', 'cooked_cod',
        'rabbit_stew', 'cake', 'salmon', 'cooked_salmon', 'mutton'}
UNSTACKABLE = {'mushroom_stew', 'rabbit_stew', 'cake', 'bow'}

def category(name, mat):
    if name in CATEGORY_OVERRIDE: return CATEGORY_OVERRIDE[name]
    m = mat.split(':', 1)[1]
    if m.endswith(('_sword', '_axe')) or m in ('bow', 'arrow'): return 'Weapons'
    if m.endswith(('_helmet', '_chestplate', '_leggings', '_boots')): return 'Armor'
    if m.endswith(('_pickaxe', '_shovel', '_hoe')): return 'Tools'
    if m in FOOD: return 'Food'
    return 'Resources'

def max_stack(mat):
    m = mat.split(':', 1)[1]
    if m in UNSTACKABLE or m.endswith(('_sword', '_axe', '_pickaxe', '_shovel', '_hoe', '_helmet',
                                       '_chestplate', '_leggings', '_boots')):
        return 1
    return 16 if m in ('ender_pearl', 'egg', 'snowball') else 64

def blueprints(folder):
    out = []
    for (mat, name), inst in collect(folder).items():
        if mat in SKIP_MATERIALS or name in SKIP_NAMES: continue
        out.append({'name': RENAME.get((mat, name), name), 'material': mat,
                    'displayName': majority(i['displayName'] for i in inst),
                    'grade': majority(i['grade'] for i in inst), 'category': category(name, mat),
                    'maxStack': max_stack(mat),
                    'enchantments': {**consensus(inst, 'vanillaEnchantments'), **consensus(inst, 'customEnchantments')},
                    'description': majority('\n'.join(i['description']) for i in inst) or '',
                    'copies': len(inst), 'players': len({i['player'] for i in inst}),
                    'warnings': sorted({i['warning'] for i in inst if i['warning']})})
    return out

def cs(s): return '"' + s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'

def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else 'report'
    folder = sys.argv[2] if len(sys.argv) > 2 else DEFAULT_DIR
    if cmd == 'player':
        who = sys.argv[3]; p = os.path.join(folder, who + '.dat')
        if not os.path.exists(p):
            p = next((f for f in glob.glob(os.path.join(folder, '*.dat'))
                      if ((nbt.load(f).get('bukkit') or {}).get('lastKnownName') or '').lower() == who.lower()), None)
            if not p: sys.exit(f'player {who} not found')
        print(json.dumps(list(named_items(nbt.load(p), who)), indent=1, ensure_ascii=False))
    elif cmd == 'report':
        print(json.dumps(blueprints(folder), indent=1, ensure_ascii=False))
    elif cmd == 'generate':
        for b in blueprints(folder):
            ench = ', '.join(f'({cs(k)}, {v})' for k, v in b['enchantments'].items())
            print(f"        new({cs(b['name'])}, {cs(b['material'])}, {cs(b['displayName'])}, {cs(b['category'])}, "
                  f"{b['grade'] if b['grade'] is not None else 'null'}, {b['maxStack']}, "
                  f"new (string, int)[] {{ {ench} }}),".replace('new (string, int)[] {  }', 'NoEnchantments'))
    else:
        sys.exit(__doc__)

if __name__ == '__main__':
    main()
