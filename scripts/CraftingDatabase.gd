# CraftingDatabase.gd
# Autoload singleton — all crafting recipes.
# Add to Project > Project Settings > Autoload as "CraftDB"
#
# Stations:
#   "hand"        — no station needed (anywhere)
#   "workbench"   — basic wood/string crafting
#   "furnace"     — smelting ores into bars
#   "anvil"       — iron/silver/gold tier weapons & armor
#   "mythril_anvil" — mythril+ tier
#   "forge"       — luminite / endgame

extends Node

class Recipe:
	var result_id:    String
	var result_count: int
	var ingredients:  Array  # [{id:String, count:int}, ...]
	var station:      String
	var category:     String  # for filter tabs in UI

	func _init(r:String, rc:int, ing:Array, st:String, cat:String="misc"):
		result_id    = r
		result_count = rc
		ingredients  = ing
		station      = st
		category     = cat

var _recipes: Array = []   # Array[Recipe]
var _by_station: Dictionary = {}

func _ready() -> void:
	_register_all()
	_index_by_station()

func get_recipes_for_station(station: String) -> Array:
	return _by_station.get(station, [])

func get_all_recipes() -> Array:
	return _recipes

# Returns recipes the player CAN craft given their inventory
func get_craftable(inventory: Dictionary, station: String) -> Array:
	var out = []
	for r in get_recipes_for_station(station):
		if can_craft(r, inventory):
			out.append(r)
	return out

func can_craft(r, inventory: Dictionary) -> bool:
	for ing in r.ingredients:
		if (inventory.get(ing.id, 0)) < ing.count:
			return false
	return true

func _reg(result:String, count:int, ingredients:Array, station:String, cat:String="misc") -> void:
	var r = Recipe.new(result, count, ingredients, station, cat)
	_recipes.append(r)

func _i(id:String, c:int) -> Dictionary:
	return {id=id, count=c}

func _index_by_station() -> void:
	for r in _recipes:
		if not _by_station.has(r.station):
			_by_station[r.station] = []
		_by_station[r.station].append(r)

# ─────────────────────────────────────────────────────────────
func _register_all() -> void:
	_register_hand_crafting()
	_register_workbench()
	_register_furnace()
	_register_anvil()
	_register_mythril_anvil()
	_register_potions()

# ─── HAND (no station) ────────────────────────────────────────
func _register_hand_crafting() -> void:
	# Basic survival
	_reg("wood_block",    4, [_i("wood",1)],              "hand", "blocks")
	_reg("torch",         4, [_i("wood",1),_i("coal",1)], "hand", "furniture")
	_reg("rope",          1, [_i("silk",2)],              "hand", "blocks")

	# Starter tools from wood
	_reg("wood_pickaxe",  1, [_i("wood",10)],             "hand", "tools")
	_reg("wood_axe",      1, [_i("wood",8)],              "hand", "tools")
	_reg("wood_hammer",   1, [_i("wood",8)],              "hand", "tools")
	_reg("wood_sword",    1, [_i("wood",7)],              "hand", "weapons")

# ─── WORKBENCH ───────────────────────────────────────────────
func _register_workbench() -> void:
	# Building blocks
	_reg("stone_brick",  4,  [_i("stone",4)],                         "workbench","blocks")
	_reg("glass",        1,  [_i("sand",4)],                          "workbench","blocks")
	_reg("platform",     4,  [_i("wood",1)],                          "workbench","blocks")

	# Basic furniture
	_reg("workbench",    1,  [_i("wood",10)],                         "workbench","furniture")
	_reg("wood_door",    1,  [_i("wood",8)],                          "workbench","furniture")
	_reg("chest",        1,  [_i("wood",8),_i("ferrite_bar",2)],         "workbench","furniture")
	_reg("bed",          1,  [_i("wood",15),_i("silk",5)],            "workbench","furniture")
	_reg("table",        1,  [_i("wood",8)],                          "workbench","furniture")
	_reg("chair",        1,  [_i("wood",4)],                          "workbench","furniture")
	_reg("bookshelf",    1,  [_i("wood",10),_i("stone",2)],           "workbench","furniture")

	# Ammo
	_reg("wooden_arrow", 20, [_i("wood",1)],                          "workbench","ammo")
	_reg("iron_arrow",   20, [_i("wood",1),_i("ferrite_bar",1)],         "workbench","ammo")

	# Wood armor
	_reg("wood_helmet",    1,[_i("wood",25)],                         "workbench","armor")
	_reg("wood_chestplate",1,[_i("wood",35)],                         "workbench","armor")
	_reg("wood_leggings",  1,[_i("wood",30)],                         "workbench","armor")

	# Bow
	_reg("wood_bow",      1, [_i("wood",10),_i("silk",3)],            "workbench","weapons")

	# Apprentice staff
	_reg("apprentice_staff",1,[_i("wood",12),_i("lens",2)],          "workbench","weapons")

# ─── FURNACE (smelting) ──────────────────────────────────────
func _register_furnace() -> void:
	var smelt = [
		# [ore_id, ore_count, bar_id, bar_count]
		["blazite_ore",    3, "blazite_bar",    1],
		["verdite_ore",       3, "verdite_bar",       1],
		["ferrite_ore",      3, "ferrite_bar",      1],
		["gravite_ore",      3, "gravite_bar",      1],
		["jadite_ore",    4, "jadite_bar",    1],
		["moonite_ore",  4, "moonite_bar",  1],
		["solite_ore",      4, "solite_bar",      1],
		["crystite_ore",  4, "crystite_bar",  1],
		["aethite_ore",   4, "aethite_bar",   1],
		["voidite_ore",4, "voidite_bar",1],
		["embrite_ore",5, "embrite_bar",1],
		["spectrite_ore",  5, "spectrite_bar",  1],
		["radiance_ore",  4, "radiance_bar",  1],
	]
	for s in smelt:
		_reg(s[2], s[3], [_i(s[0],s[1])], "furnace", "smelting")

	# Alloys
	_reg("bronze_bar",    1, [_i("blazite_bar",1),_i("verdite_bar",1)],    "furnace","smelting")

	# Brick from bars
	_reg("iron_brick",    4, [_i("ferrite_bar",1),_i("stone",2)],        "furnace","blocks")
	_reg("gold_brick",    4, [_i("solite_bar",1),_i("stone",2)],        "furnace","blocks")
	_reg("glass",         2, [_i("sand",4)],                          "furnace","blocks")

	# Furnace itself (bootstrapped at workbench)
	_reg("furnace",       1, [_i("stone",20),_i("coal",3)],           "workbench","furniture")

# ─── IRON ANVIL ──────────────────────────────────────────────
func _register_anvil() -> void:
	# Anvil itself
	_reg("anvil",          1, [_i("ferrite_bar",5)],                      "furnace","furniture")
	_reg("iron_door",      1, [_i("ferrite_bar",6)],                      "anvil","furniture")
	_reg("lantern",        1, [_i("ferrite_bar",3),_i("wood",4)],         "anvil","furniture")

	# Copper tier
	var copper = [
		["copper_pickaxe",   [_i("blazite_bar",8),_i("wood",4)]],
		["copper_axe",       [_i("blazite_bar",7),_i("wood",4)]],
		["copper_sword",     [_i("blazite_bar",7)]],
		["copper_bow",       [_i("blazite_bar",6),_i("wood",5)]],
		["copper_helmet",    [_i("blazite_bar",15)]],
		["copper_chestplate",[_i("blazite_bar",25)]],
		["copper_leggings",  [_i("blazite_bar",20)]],
		["copper_staff",     [_i("blazite_bar",10),_i("lens",3)]],
	]
	for c in copper: _reg(c[0], 1, c[1], "anvil", _cat_guess(c[0]))

	# Iron tier
	var iron = [
		["iron_pickaxe",    [_i("ferrite_bar",8), _i("wood",4)]],
		["iron_axe",        [_i("ferrite_bar",7), _i("wood",4)]],
		["iron_hammer",     [_i("ferrite_bar",8), _i("wood",4)]],
		["iron_sword",      [_i("ferrite_bar",8)]],
		["iron_bow",        [_i("ferrite_bar",7), _i("wood",4)]],
		["iron_helmet",     [_i("ferrite_bar",20)]],
		["iron_chestplate", [_i("ferrite_bar",30)]],
		["iron_leggings",   [_i("ferrite_bar",25)]],
	]
	for i2 in iron: _reg(i2[0], 1, i2[1], "anvil", _cat_guess(i2[0]))

	# Silver tier
	var silver = [
		["silver_pickaxe",    [_i("jadite_bar",10),_i("wood",4)]],
		["silver_sword",      [_i("jadite_bar",10)]],
		["silver_bow",        [_i("jadite_bar",9),_i("wood",4)]],
		["silver_staff",      [_i("jadite_bar",12),_i("lens",5)]],
		["silver_helmet",     [_i("jadite_bar",20)]],
		["silver_chestplate", [_i("jadite_bar",32)]],
		["silver_leggings",   [_i("jadite_bar",26)]],
	]
	for s in silver: _reg(s[0], 1, s[1], "anvil", _cat_guess(s[0]))

	# Gold tier
	var gold = [
		["gold_pickaxe",    [_i("solite_bar",10),_i("wood",4)]],
		["gold_hammer",     [_i("solite_bar",10),_i("wood",4)]],
		["gold_sword",      [_i("solite_bar",10)]],
		["gold_bow",        [_i("solite_bar",9),_i("wood",4)]],
		["staff_of_gilding",[_i("solite_bar",14),_i("lens",8)]],
		["gold_helmet",     [_i("solite_bar",22)]],
		["gold_chestplate", [_i("solite_bar",35)]],
		["gold_leggings",   [_i("solite_bar",28)]],
	]
	for g in gold: _reg(g[0], 1, g[1], "anvil", _cat_guess(g[0]))

	# Bone armor (from bones)
	var bone = [
		["bone_sword",      [_i("bone",20),_i("ferrite_bar",4)]],
		["bone_helmet",     [_i("bone",30)]],
		["bone_chestplate", [_i("bone",45)]],
		["bone_leggings",   [_i("bone",38)]],
	]
	for b in bone: _reg(b[0], 1, b[1], "anvil", _cat_guess(b[0]))

# ─── MYTHRIL ANVIL ───────────────────────────────────────────
func _register_mythril_anvil() -> void:
	_reg("mythril_anvil",    1, [_i("aethite_bar",10)],               "anvil","furniture")

	var mythril = [
		["mythril_pickaxe",    [_i("aethite_bar",12),_i("wood",4)]],
		["mythril_axe",        [_i("aethite_bar",10),_i("wood",4)]],
		["mythril_sword",      [_i("aethite_bar",12)]],
		["mythril_bow",        [_i("aethite_bar",11),_i("wood",4)]],
		["mythril_staff",      [_i("aethite_bar",14),_i("lens",10)]],
		["mythril_helmet",     [_i("aethite_bar",20)]],
		["mythril_chestplate", [_i("aethite_bar",32)]],
		["mythril_leggings",   [_i("aethite_bar",26)]],
	]
	for m in mythril: _reg(m[0], 1, m[1], "mythril_anvil", _cat_guess(m[0]))

	var adam = [
		["adamantite_pickaxe",   [_i("embrite_bar",14),_i("wood",4)]],
		["adamantite_axe",       [_i("embrite_bar",12),_i("wood",4)]],
		["adamantite_hammer",    [_i("embrite_bar",14),_i("wood",4)]],
		["adamantite_sword",     [_i("embrite_bar",14)]],
		["adamantite_bow",       [_i("embrite_bar",13),_i("wood",4)]],
		["adamantite_staff",     [_i("embrite_bar",16),_i("scale",3)]],
		["staff_of_thunder",     [_i("embrite_bar",18),_i("lens",15),_i("scale",5)]],
		["adamantite_helmet",    [_i("embrite_bar",24)]],
		["adamantite_chestplate",[_i("embrite_bar",38)]],
		["adamantite_leggings",  [_i("embrite_bar",30)]],
	]
	for a in adam: _reg(a[0], 1, a[1], "mythril_anvil", _cat_guess(a[0]))

	# Endgame — Luminite (dropped from final boss)
	var lumi = [
		["luminite_pickaxe",  [_i("radiance_bar",12)]],
		["luminite_blade",    [_i("radiance_bar",14),_i("scale",8)]],
		["void_staff",        [_i("radiance_bar",18),_i("scale",12)]],
		["luminite_helmet",   [_i("radiance_bar",20)]],
		["luminite_chestplate",[_i("radiance_bar",32)]],
		["luminite_leggings", [_i("radiance_bar",26)]],
	]
	for l in lumi: _reg(l[0], 1, l[1], "mythril_anvil", _cat_guess(l[0]))

# ─── POTIONS (workbench with herbs) ──────────────────────────
func _register_potions() -> void:
	var pots = [
		["healing_potion",   [_i("gel",2),_i("wood",1)]],
		["greater_heal",     [_i("healing_potion",2),_i("solite_bar",1)]],
		["super_heal",       [_i("greater_heal",2),_i("radiance_bar",1)]],
		["mana_potion",      [_i("lens",1),_i("wood",2)]],
		["ironskin_potion",  [_i("ferrite_bar",2),_i("wood",1)]],
		["swiftness_potion", [_i("fang",2),_i("wood",1)]],
		["mining_potion",    [_i("coal",2),_i("wood",1)]],
		["night_vision",     [_i("lens",3),_i("wood",1)]],
		["battle_brew",      [_i("fang",3),_i("bone",3),_i("gel",2)]],
	]
	for p in pots: _reg(p[0], 1, p[1], "workbench", "potions")

# ─── HELPER ──────────────────────────────────────────────────
func _cat_guess(id: String) -> String:
	if id.ends_with("_sword") or id.ends_with("_bow") or id.ends_with("_staff") or id.ends_with("_blade"):
		return "weapons"
	if id.ends_with("_pickaxe") or id.ends_with("_axe") or id.ends_with("_hammer"):
		return "tools"
	if id.ends_with("_helmet") or id.ends_with("_chestplate") or id.ends_with("_leggings"):
		return "armor"
	return "misc"
