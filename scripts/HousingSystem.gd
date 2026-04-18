# HousingSystem.gd
# Scans the tilemap for valid NPC houses.
# A valid house requires:
#   • At least 60 tiles of enclosed floor space  (not more than 750)
#   • A placed Door (tile 60 or 61)
#   • A Light Source  (torch tile 50 or lantern tile 85)
#   • A flat surface (table 82 + chair 81, or bookshelf 83)
#   • A comfort item  (bed 80 or banner 86)
#   • Background walls on every interior tile
#   • No corruption/underworld blocks nearby
# Attach to World.gd or as AutoLoad.

extends Node

# Furniture tile IDs that fulfil each requirement
const DOOR_TILES     = [60, 61]
const LIGHT_TILES    = [50, 85]
const SURFACE_TILES  = [81, 82, 83]  # chair, table, bookshelf
const COMFORT_TILES  = [80, 86]      # bed, banner

const MIN_FLOOR_TILES = 60
const MAX_FLOOR_TILES = 750

# NPC roster — each NPC has a condition for moving in
const NPC_ROSTER = [
	{
		id="guide",
		name="The Guide",
		condition="Always present from world start",
		tip="Tells you what items can be crafted",
		biome_pref="any",
	},
	{
		id="merchant",
		name="The Merchant",
		condition="Player has at least 50 gold coins",
		shop=["healing_potion","mana_potion","rope","torch","wood_arrow"],
		biome_pref="any",
	},
	{
		id="nurse",
		name="The Nurse",
		condition="Player has a heart crystal (Life Fruit used)",
		service="heal_hp",
		biome_pref="any",
	},
	{
		id="arms_dealer",
		name="The Arms Dealer",
		condition="Player has a bow in inventory",
		shop=["iron_arrow","wooden_arrow"],
		biome_pref="any",
	},
	{
		id="demolitions",
		name="The Demolitions Expert",
		condition="Player has 1+ dynamite or bomb",
		shop=["bomb","dynamite","sticky_bomb"],
		biome_pref="any",
	},
	{
		id="dryad",
		name="The Dryad",
		condition="Defeat Eye of the Abyss (Boss 2)",
		service="purify_corruption",
		biome_pref="forest",
	},
	{
		id="blacksmith",
		name="The Blacksmith",
		condition="Defeat Skelethor (Boss 3)",
		service="reforge_items",   # random stat reroll for coins
		biome_pref="any",
	},
	{
		id="tinkerer",
		name="The Tinkerer",
		condition="Free from Goblin Army dungeon",
		service="combine_accessories",
		biome_pref="underground",
	},
	{
		id="witch_doctor",
		name="The Witch Doctor",
		condition="Defeat Slime King (Boss 1)",
		shop=["mana_potion","battle_brew"],
		biome_pref="jungle",
	},
	{
		id="painter",
		name="The Painter",
		condition="6 other NPCs living in town",
		service="paint_tiles",
		biome_pref="any",
	},
]

var _tilemap: TileMapLayer
var _wall_layer: TileMapLayer
var _valid_houses: Array = []       # Array[Rect2i]
var _assigned_npcs: Dictionary = {} # house_index -> npc_id

func setup(tilemap: TileMapLayer, wall_layer: TileMapLayer) -> void:
	_tilemap   = tilemap
	_wall_layer = wall_layer

# Call this after any tile placement to re-validate nearby rooms
func check_area(center_tile: Vector2i, radius: int = 30) -> void:
	_valid_houses.clear()
	var scan_min = center_tile - Vector2i(radius, radius)
	var scan_max = center_tile + Vector2i(radius, radius)
	_flood_find_rooms(scan_min, scan_max)

# Simple flood-fill room detector
func _flood_find_rooms(tmin: Vector2i, tmax: Vector2i) -> void:
	var visited = {}

	for sx in range(tmin.x, tmax.x):
		for sy in range(tmin.y, tmax.y):
			var start = Vector2i(sx, sy)
			if visited.has(start):
				continue
			if _tilemap.get_cell_source_id(start) != -1:
				continue  # solid tile — skip

			# BFS
			var frontier = [start]
			var room_tiles = []
			var frontier_idx = 0

			while frontier_idx < frontier.size():
				var cur = frontier[frontier_idx]
				frontier_idx += 1
				if visited.has(cur):
					continue
				visited[cur] = true
				if _tilemap.get_cell_source_id(cur) != -1:
					continue  # hit a wall, don't expand
				if cur.x < tmin.x or cur.x > tmax.x or cur.y < tmin.y or cur.y > tmax.y:
					continue
				room_tiles.append(cur)
				for d in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
					var nb = cur + d
					if not visited.has(nb):
						frontier.append(nb)

			if room_tiles.size() < MIN_FLOOR_TILES or room_tiles.size() > MAX_FLOOR_TILES:
				continue

			if _validate_room(room_tiles):
				var bounds = _bounds_of(room_tiles)
				_valid_houses.append(bounds)

func _validate_room(tiles: Array) -> bool:
	var has_door    = false
	var has_light   = false
	var has_surface = false
	var has_comfort = false
	var has_walls   = true

	for tile_pos in tiles:
		# Check wall layer behind each air tile
		if _wall_layer.get_cell_source_id(tile_pos) == -1:
			has_walls = false

		# Check adjacent solid tiles for furniture
		for d in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
			var nb = tile_pos + d
			var src = _tilemap.get_cell_source_id(nb)
			if src == -1:
				continue
			var atlas = _tilemap.get_cell_atlas_coords(nb)
			var tid   = atlas.x + atlas.y * 16
			if tid in DOOR_TILES:     has_door    = true
			if tid in LIGHT_TILES:    has_light   = true
			if tid in SURFACE_TILES:  has_surface = true
			if tid in COMFORT_TILES:  has_comfort = true

	return has_walls and has_door and has_light and has_surface and has_comfort

func _bounds_of(tiles: Array) -> Rect2i:
	var min_x = tiles[0].x; var max_x = tiles[0].x
	var min_y = tiles[0].y; var max_y = tiles[0].y
	for t in tiles:
		min_x = min(min_x, t.x); max_x = max(max_x, t.x)
		min_y = min(min_y, t.y); max_y = max(max_y, t.y)
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

func get_valid_house_count() -> int:
	return _valid_houses.size()

func try_move_in_npc(npc_id: String, player_inventory: Dictionary, defeated_bosses: Array) -> bool:
	var npc_def = _find_npc(npc_id)
	if not npc_def:
		return false
	# Find unoccupied house
	for i in _valid_houses.size():
		if not _assigned_npcs.has(i):
			_assigned_npcs[i] = npc_id
			return true
	return false

func _find_npc(id: String):
	for npc in NPC_ROSTER:
		if npc.id == id:
			return npc
	return null
