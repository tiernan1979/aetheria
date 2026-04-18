# ItemDatabase.gd
# Autoload singleton — stores every item definition in the game.
# Access via:  ItemDB.get_item("iron_sword")
# Add to Project > Project Settings > Autoload as "ItemDB"

extends Node

# ─────────────────────────────────────────────────────────────
#  ITEM CATEGORIES
# ─────────────────────────────────────────────────────────────
enum Category {
	BLOCK, ORE, BAR, TOOL, WEAPON, ARMOR, CONSUMABLE, SEED, FURNITURE, MISC
}

enum ToolType { NONE, PICKAXE, AXE, SWORD, BOW, STAFF, SHOVEL, HAMMER }
enum ArmorSlot { NONE, HEAD, CHEST, LEGS, FEET }
enum Rarity    { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

# ─────────────────────────────────────────────────────────────
#  ITEM DEFINITION
# ─────────────────────────────────────────────────────────────
class ItemDef:
	var id:          String
	var name:        String
	var description: String
	var category:    int          # Category enum
	var sprite:      String       # path under res://assets/sprites/
	var max_stack:   int  = 99
	var rarity:      int  = Rarity.COMMON
	var value:       int  = 1     # sell price (coins)

	# Tool/weapon stats
	var tool_type:   int  = ToolType.NONE
	var damage:      int  = 0
	var speed:       float = 1.0  # attacks per second
	var reach:       int  = 4     # tiles reach
	var mining_power:int  = 0     # which tier of blocks it can mine

	# Armor stats
	var armor_slot:  int  = ArmorSlot.NONE
	var defense:     int  = 0
	var bonus_desc:  String = ""

	# Block placement
	var placeable:   bool  = false
	var tile_id:     int   = -1   # TileSet source ID when placed

	# Consumable
	var heal_hp:     int  = 0
	var heal_mana:   int  = 0
	var buff_desc:   String = ""
	var buff_duration:float = 0.0

	func _init(p:Dictionary):
		for key in p: set(key, p[key])

# ─────────────────────────────────────────────────────────────
#  DATABASE
# ─────────────────────────────────────────────────────────────
var _db: Dictionary = {}

func _ready() -> void:
	_register_blocks()
	_register_ores_and_bars()
	_register_tools()
	_register_weapons()
	_register_armor()
	_register_consumables()
	_register_furniture()

func get_item(id: String) -> ItemDef:
	return _db.get(id, null)

func _reg(p: Dictionary) -> void:
	var item = ItemDef.new(p)
	_db[item.id] = item

# ─────────────────────────────────────────────────────────────
#  BLOCKS
# ─────────────────────────────────────────────────────────────
func _register_blocks() -> void:
	var blocks = [
		{id="dirt",        name="Dirt",          tile_id=0,  mining_power=0, value=1},
		{id="grass",       name="Grass",          tile_id=1,  mining_power=0, value=1},
		{id="stone",       name="Stone",          tile_id=2,  mining_power=1, value=2},
		{id="sand",        name="Sand",           tile_id=3,  mining_power=0, value=1},
		{id="sandstone",   name="Sandstone",      tile_id=4,  mining_power=1, value=3},
		{id="ice_block",   name="Ice Block",      tile_id=5,  mining_power=1, value=2},
		{id="snow",        name="Snow",           tile_id=6,  mining_power=0, value=1},
		{id="mud",         name="Mud",            tile_id=7,  mining_power=0, value=1},
		{id="obsidian",    name="Obsidian",       tile_id=8,  mining_power=3, value=20},
		{id="wood_block",  name="Wood Block",     tile_id=9,  mining_power=0, value=2},
		{id="stone_brick", name="Stone Brick",    tile_id=10, mining_power=1, value=5},
		{id="iron_brick",  name="Iron Brick",     tile_id=12, mining_power=2, value=15},
		{id="gold_brick",  name="Gold Brick",     tile_id=13, mining_power=2, value=40},
		{id="glass",       name="Glass",          tile_id=14, mining_power=1, value=8},
		{id="platform",    name="Wood Platform",  tile_id=15, mining_power=0, value=2},
		{id="spike",       name="Spike",          tile_id=16, mining_power=1, value=5},
	]
	for b in blocks:
		b["category"] = Category.BLOCK
		b["placeable"] = true
		b["sprite"] = "blocks/%s" % b["id"]
		_reg(b)

# ─────────────────────────────────────────────────────────────
#  ORES & BARS
# ─────────────────────────────────────────────────────────────
func _register_ores_and_bars() -> void:
	# Raw ores (dropped when mined)
	var ores = [
		{id="blazite_ore",   name="Blazite Ore",   value=4,  rarity=Rarity.COMMON},
		{id="verdite_ore",      name="Verdite Ore",       value=4,  rarity=Rarity.COMMON},
		{id="ferrite_ore",     name="Ferrite Ore",      value=8,  rarity=Rarity.COMMON},
		{id="gravite_ore",     name="Gravite Ore",      value=8,  rarity=Rarity.COMMON},
		{id="jadite_ore",   name="Jadite Ore",    value=18, rarity=Rarity.UNCOMMON},
		{id="moonite_ore", name="Moonite Ore",  value=18, rarity=Rarity.UNCOMMON},
		{id="solite_ore",     name="Solite Ore",      value=35, rarity=Rarity.UNCOMMON},
		{id="crystite_ore", name="Crystite Ore",  value=35, rarity=Rarity.UNCOMMON},
		{id="aethite_ore",  name="Aethite Ore",   value=80, rarity=Rarity.RARE},
		{id="voidite_ore",name="Voidite Ore",value=80,rarity=Rarity.RARE},
		{id="embrite_ore",name="Embrite Ore",value=150,rarity=Rarity.EPIC},
		{id="spectrite_ore", name="Spectrite Ore",  value=150, rarity=Rarity.EPIC},
		{id="radiance_ore", name="Radiance Ore",  value=400, rarity=Rarity.LEGENDARY},
	]
	for o in ores:
		o["category"] = Category.ORE
		o["sprite"] = "ores/%s" % o["id"]
		_reg(o)

	# Smelted bars (crafted at furnace)
	var bars = [
		{id="blazite_bar",    name="Blazite Bar",    value=10,  rarity=Rarity.COMMON},
		{id="verdite_bar",       name="Verdite Bar",       value=10,  rarity=Rarity.COMMON},
		{id="bronze_bar",    name="Bronze Bar",    value=14,  rarity=Rarity.COMMON,    description="Alloy of copper + tin"},
		{id="ferrite_bar",      name="Ferrite Bar",      value=20,  rarity=Rarity.COMMON},
		{id="gravite_bar",      name="Gravite Bar",      value=20,  rarity=Rarity.COMMON},
		{id="jadite_bar",    name="Jadite Bar",    value=45,  rarity=Rarity.UNCOMMON},
		{id="moonite_bar",  name="Moonite Bar",  value=45,  rarity=Rarity.UNCOMMON},
		{id="solite_bar",      name="Solite Bar",      value=90,  rarity=Rarity.UNCOMMON},
		{id="crystite_bar",  name="Crystite Bar",  value=90,  rarity=Rarity.UNCOMMON},
		{id="aethite_bar",   name="Aethite Bar",   value=200, rarity=Rarity.RARE},
		{id="voidite_bar",name="Voidite Bar",value=200, rarity=Rarity.RARE},
		{id="embrite_bar",name="Embrite Bar",value=380, rarity=Rarity.EPIC},
		{id="spectrite_bar",  name="Spectrite Bar",  value=380, rarity=Rarity.EPIC},
		{id="radiance_bar",  name="Radiance Bar",  value=900, rarity=Rarity.LEGENDARY},
	]
	for b in bars:
		b["category"] = Category.BAR
		b["sprite"] = "bars/%s" % b["id"]
		_reg(b)

	# Wood & other crafting mats
	var mats = [
		{id="wood",         name="Wood",          value=1,  category=Category.MISC, sprite="misc/wood"},
		{id="gel",          name="Gel",           value=2,  category=Category.MISC, sprite="misc/gel",   description="Dropped by slimes"},
		{id="lens",         name="Lens",          value=5,  category=Category.MISC, sprite="misc/lens",  description="Dropped by demon eyes"},
		{id="fang",         name="Fang",          value=8,  category=Category.MISC, sprite="misc/fang",  description="Dropped by giant bats"},
		{id="bone",         name="Bone",          value=3,  category=Category.MISC, sprite="misc/bone"},
		{id="silk",         name="Silk",          value=12, category=Category.MISC, sprite="misc/silk",  description="Dropped by spiders"},
		{id="scale",        name="Dragon Scale",  value=50, category=Category.MISC, sprite="misc/scale", rarity=Rarity.RARE, description="Dropped by Wyvern"},
		{id="stone_slab",   name="Stone Slab",    value=4,  category=Category.MISC, sprite="misc/stone_slab"},
		{id="coal",         name="Coal",          value=3,  category=Category.MISC, sprite="misc/coal",  description="Used as furnace fuel"},
		{id="torch",        name="Torch",         value=1,  category=Category.FURNITURE, placeable=true, tile_id=50, sprite="furniture/torch"},
		{id="rope",         name="Rope",          value=2,  category=Category.BLOCK, placeable=true, tile_id=51, sprite="misc/rope"},
	]
	for m in mats:
		_reg(m)

# ─────────────────────────────────────────────────────────────
#  TOOLS  (pickaxes, axes, shovels, hammers)
# ─────────────────────────────────────────────────────────────
func _register_tools() -> void:
	# Format: [id, name, tier_metal, mining_power, speed, damage, value, rarity, reach]
	var picks = [
		["wood_pickaxe",      "Wooden Pickaxe",      "",           1, 1.4, 4,  5,   Rarity.COMMON,   4],
		["copper_pickaxe",    "Copper Pickaxe",      "blazite",     1, 1.5, 6,  18,  Rarity.COMMON,   4],
		["iron_pickaxe",      "Iron Pickaxe",        "ferrite",       2, 1.7, 10, 40,  Rarity.COMMON,   5],
		["silver_pickaxe",    "Silver Pickaxe",      "jadite",     2, 2.0, 14, 90,  Rarity.UNCOMMON, 5],
		["gold_pickaxe",      "Gold Pickaxe",        "solite",       3, 2.2, 18, 200, Rarity.UNCOMMON, 6],
		["mythril_pickaxe",   "Mythril Pickaxe",     "aethite",    4, 2.5, 25, 450, Rarity.RARE,     6],
		["adamantite_pickaxe","Adamantite Pickaxe",  "embrite", 5, 2.8, 32, 900, Rarity.EPIC,     7],
		["luminite_pickaxe",  "Luminite Pickaxe",    "radiance",   6, 3.2, 45, 2000,Rarity.LEGENDARY,7],
	]
	for p in picks:
		_reg({id=p[0], name=p[1], category=Category.TOOL, tool_type=ToolType.PICKAXE,
			  mining_power=p[3], speed=p[4], damage=p[5], value=p[6], rarity=p[7],
			  reach=p[8], max_stack=1, sprite="tools/%s"%p[0]})

	var axes = [
		["wood_axe",       "Wooden Axe",       1, 1.3, 5,  4,  Rarity.COMMON],
		["copper_axe",     "Copper Axe",       2, 1.5, 8,  20, Rarity.COMMON],
		["iron_axe",       "Iron Axe",         3, 1.7, 12, 45, Rarity.COMMON],
		["mythril_axe",    "Mythril Axe",       5, 2.3, 20, 400,Rarity.RARE],
		["adamantite_axe", "Adamantite Axe",   6, 2.6, 28, 800,Rarity.EPIC],
	]
	for a in axes:
		_reg({id=a[0], name=a[1], category=Category.TOOL, tool_type=ToolType.AXE,
			  mining_power=a[2], speed=a[3], damage=a[4], value=a[5], rarity=a[6],
			  max_stack=1, sprite="tools/%s"%a[0]})

	var hammers = [
		["wood_hammer",      "Wooden Hammer",      1, 1.2, 3,  3,  Rarity.COMMON],
		["iron_hammer",      "Iron Hammer",        2, 1.5, 8,  40, Rarity.COMMON],
		["gold_hammer",      "Gold Hammer",        3, 1.8, 12, 180,Rarity.UNCOMMON],
		["adamantite_hammer","Adamantite Hammer",  5, 2.4, 22, 750,Rarity.EPIC],
	]
	for h in hammers:
		_reg({id=h[0], name=h[1], category=Category.TOOL, tool_type=ToolType.HAMMER,
			  mining_power=h[2], speed=h[3], damage=h[4], value=h[5], rarity=h[6],
			  max_stack=1, sprite="tools/%s"%h[0],
			  description="Used to shape and remove platforms/walls"})

# ─────────────────────────────────────────────────────────────
#  WEAPONS
# ─────────────────────────────────────────────────────────────
func _register_weapons() -> void:
	var swords = [
		["wood_sword",       "Wooden Sword",       8,  1.8, 5,   Rarity.COMMON,    ""],
		["copper_sword",     "Copper Sword",       14, 2.0, 18,  Rarity.COMMON,    ""],
		["iron_sword",       "Iron Sword",         22, 2.2, 45,  Rarity.COMMON,    ""],
		["silver_sword",     "Silver Sword",       30, 2.4, 100, Rarity.UNCOMMON,  "Deals extra damage to undead"],
		["gold_sword",       "Gold Sword",         40, 2.5, 220, Rarity.UNCOMMON,  ""],
		["mythril_sword",    "Mythril Sword",      55, 2.7, 500, Rarity.RARE,      "Emits faint arcane glow"],
		["adamantite_sword", "Adamantite Sword",   72, 2.9, 1100,Rarity.EPIC,      "+15% crit chance"],
		["luminite_blade",   "Luminite Blade",     100,3.2, 2500,Rarity.LEGENDARY, "Fires a beam of light on swing"],
		["bone_sword",       "Bone Sword",         18, 1.9, 30,  Rarity.UNCOMMON,  "Chance to summon bone shards"],
		["obsidian_sword",   "Obsidian Edge",      35, 2.3, 160, Rarity.RARE,      "Burns enemies on hit (DoT)"],
	]
	for s in swords:
		_reg({id=s[0], name=s[1], category=Category.WEAPON, tool_type=ToolType.SWORD,
			  damage=s[2], speed=s[3], value=s[4], rarity=s[5], description=s[6],
			  max_stack=1, sprite="weapons/%s"%s[0]})

	var bows = [
		["wood_bow",       "Wooden Bow",       12, 1.5, 10,  Rarity.COMMON,   ""],
		["iron_bow",       "Iron Bow",         22, 1.8, 60,  Rarity.COMMON,   ""],
		["silver_bow",     "Silver Bow",       32, 2.0, 150, Rarity.UNCOMMON, "Frost arrows slow enemies"],
		["gold_bow",       "Gold Bow",         44, 2.2, 300, Rarity.UNCOMMON, ""],
		["mythril_bow",    "Mythril Bow",      60, 2.5, 650, Rarity.RARE,     "Fires two arrows simultaneously"],
		["adamantite_bow", "Adamantite Bow",   80, 2.7, 1300,Rarity.EPIC,     "+20% arrow velocity"],
	]
	for b in bows:
		_reg({id=b[0], name=b[1], category=Category.WEAPON, tool_type=ToolType.BOW,
			  damage=b[2], speed=b[3], value=b[4], rarity=b[5], description=b[6],
			  max_stack=1, sprite="weapons/%s"%b[0]})

	var staves = [
		["apprentice_staff",  "Apprentice Staff",  18, 1.2, 40,  Rarity.COMMON,    "Fires weak arcane bolt"],
		["copper_staff",      "Copper Staff",      26, 1.4, 90,  Rarity.COMMON,    "Fires homing copper sparks"],
		["silver_staff",      "Silver Staff",      38, 1.6, 200, Rarity.UNCOMMON,  "Fires twin frost bolts"],
		["gold_staff",        "Staff of Gilding",  52, 1.7, 450, Rarity.UNCOMMON,  "Bouncing golden stars"],
		["mythril_staff",     "Mythril Staff",     70, 1.9, 900, Rarity.RARE,      "Summons mythril storm cloud"],
		["staff_of_thunder",  "Staff of Thunder",  90, 1.6, 800, Rarity.RARE,      "Strikes 3 nearest enemies with lightning"],
		["adamantite_staff",  "Adamantite Staff",  110,2.0, 1800,Rarity.EPIC,      "Fires explosive adamantite orbs"],
		["void_staff",        "Void Staff",        140,1.8, 3000,Rarity.LEGENDARY, "Creates a void rift that pulls enemies in"],
	]
	for s in staves:
		_reg({id=s[0], name=s[1], category=Category.WEAPON, tool_type=ToolType.STAFF,
			  damage=s[2], speed=s[3], value=s[4], rarity=s[5], description=s[6],
			  max_stack=1, sprite="weapons/%s"%s[0]})

# ─────────────────────────────────────────────────────────────
#  ARMOR SETS  (head/chest/legs — full set grants bonus)
# ─────────────────────────────────────────────────────────────
func _register_armor() -> void:
	var sets = [
		# [prefix, material, head_def, chest_def, legs_def, value_mult, rarity, set_bonus]
		["wood",       "Wood",       1,  2,  1,  1,   Rarity.COMMON,    "Set: +5 max HP"],
		["blazite",     "Blazite",     2,  4,  3,  2,   Rarity.COMMON,    "Set: +8 max HP"],
		["ferrite",       "Ferrite",       4,  7,  5,  4,   Rarity.COMMON,    "Set: +12 max HP, +1 defense"],
		["jadite",     "Jadite",     6,  11, 8,  8,   Rarity.UNCOMMON,  "Set: +20 max HP, enemies move slower near you"],
		["solite",       "Solite",       9,  15, 11, 18,  Rarity.UNCOMMON,  "Set: +30 max HP, +10% damage"],
		["aethite",    "Aethite",    13, 21, 15, 45,  Rarity.RARE,      "Set: +50 max HP, +15% speed"],
		["embrite", "Embrite", 18, 28, 20, 100, Rarity.EPIC,      "Set: +70 max HP, +20% damage reduction"],
		["radiance",   "Radiance",   25, 38, 27, 250, Rarity.LEGENDARY, "Set: Full Radiance — reflect 10% dmg, glow in darkness"],
		["shadow",     "Shadow",     5,  10, 7,  30,  Rarity.RARE,      "Set: +15% move speed, +10% damage, near-invisible at night"],
		["bone",       "Bone",       3,  6,  4,  10,  Rarity.UNCOMMON,  "Set: +15% defense, chance to summon bone wall"],
	]
	for s in sets:
		var slots = [
			["helmet",    ArmorSlot.HEAD,  s[2]],
			["chestplate",ArmorSlot.CHEST, s[3]],
			["leggings",  ArmorSlot.LEGS,  s[4]],
		]
		for sl in slots:
			_reg({
				id         = "%s_%s" % [s[0], sl[0]],
				name       = "%s %s" % [s[1], sl[0].capitalize()],
				category   = Category.ARMOR,
				armor_slot = sl[1],
				defense    = sl[2],
				value      = s[5] * (10 + sl[2] * 5),
				rarity     = s[6],
				bonus_desc = s[7],
				max_stack  = 1,
				sprite     = "armor/%s_%s" % [s[0], sl[0]],
			})

# ─────────────────────────────────────────────────────────────
#  CONSUMABLES
# ─────────────────────────────────────────────────────────────
func _register_consumables() -> void:
	var pots = [
		{id="healing_potion",   name="Healing Potion",   heal_hp=60,  value=10, description="Restores 60 HP"},
		{id="greater_heal",     name="Greater Heal",     heal_hp=120, value=25, description="Restores 120 HP",  rarity=Rarity.UNCOMMON},
		{id="super_heal",       name="Super Heal Potion",heal_hp=200, value=60, description="Restores 200 HP",  rarity=Rarity.RARE},
		{id="mana_potion",      name="Mana Potion",      heal_mana=80,value=10, description="Restores 80 Mana"},
		{id="ironskin_potion",  name="Ironskin Potion",  value=15, buff_desc="+8 defense", buff_duration=300.0},
		{id="swiftness_potion", name="Swiftness Potion", value=15, buff_desc="+25% movement speed", buff_duration=240.0},
		{id="mining_potion",    name="Mining Potion",    value=12, buff_desc="+25% mining speed", buff_duration=180.0},
		{id="night_vision",     name="Night Owl Potion", value=18, buff_desc="Full brightness underground", buff_duration=300.0},
		{id="battle_brew",      name="Battle Brew",      value=20, buff_desc="+15% damage, +10% crit", buff_duration=180.0, rarity=Rarity.UNCOMMON},
		{id="life_fruit",       name="Life Fruit",       heal_hp=1, value=200, buff_desc="Permanently +20 max HP", rarity=Rarity.RARE},
	]
	for p in pots:
		p["category"] = Category.CONSUMABLE
		if not p.has("rarity"): p["rarity"] = Rarity.COMMON
		p["sprite"] = "consumables/%s" % p["id"]
		_reg(p)

# ─────────────────────────────────────────────────────────────
#  FURNITURE (for NPC housing requirements)
# ─────────────────────────────────────────────────────────────
func _register_furniture() -> void:
	var furniture = [
		{id="wood_door",   name="Wood Door",       tile_id=60, value=4},
		{id="iron_door",   name="Iron Door",       tile_id=61, value=30},
		{id="workbench",   name="Workbench",       tile_id=70, value=8,  description="Basic crafting station"},
		{id="furnace",     name="Furnace",         tile_id=71, value=15, description="Smelt ores into bars"},
		{id="anvil",       name="Iron Anvil",      tile_id=72, value=40, description="Craft metal tools and weapons"},
		{id="mythril_anvil",name="Mythril Anvil",  tile_id=73, value=180,description="Craft mythril-tier and above", rarity=Rarity.RARE},
		{id="bed",         name="Bed",             tile_id=80, value=20, description="Set your spawn point"},
		{id="chair",       name="Chair",           tile_id=81, value=5},
		{id="table",       name="Table",           tile_id=82, value=8},
		{id="bookshelf",   name="Bookshelf",       tile_id=83, value=12},
		{id="chest",       name="Chest",           tile_id=84, value=10, description="Stores up to 40 items"},
		{id="lantern",     name="Lantern",         tile_id=85, value=15},
		{id="banner",      name="Banner",          tile_id=86, value=6},
		{id="piano",       name="Piano",           tile_id=87, value=35},
	]
	for f in furniture:
		f["category"] = Category.FURNITURE
		f["placeable"] = true
		if not f.has("rarity"): f["rarity"] = Rarity.COMMON
		f["sprite"] = "furniture/%s" % f["id"]
		_reg(f)
