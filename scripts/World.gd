# World.gd  (Godot 4.6.1)
extends Node2D

# Tile size is 16px — matches TileSetBuilder.TILE_SIZE and world_tiles.png
const TILE_SIZE = 16
# Convenience: world pixel dimensions (tiles × 16)
const WORLD_WIDTH_PX  = WorldGen.WORLD_WIDTH  * 16
const WORLD_HEIGHT_PX = WorldGen.WORLD_HEIGHT * 16

const TILE_DATA: Dictionary = {
	0: {h=2.0,p=0,drops=[{id="dirt",count=1}]},
	1: {h=1.5,p=0,drops=[{id="dirt",count=1}]},
	2: {h=4.0,p=1,drops=[{id="stone",count=1}]},
	3: {h=1.5,p=0,drops=[{id="sand",count=1}]},
	4: {h=3.0,p=1,drops=[{id="sandstone",count=1}]},
	5: {h=3.0,p=1,drops=[{id="ice_block",count=1}]},
	6: {h=1.0,p=0,drops=[{id="snow",count=1}]},
	7: {h=2.0,p=0,drops=[{id="mud",count=1}]},
	8: {h=8.0,p=3,drops=[{id="obsidian",count=1}]},
	9: {h=2.5,p=0,drops=[{id="wood",count=1}]},
	10:{h=3.5,p=1,drops=[{id="stone_brick",count=1}]},
	11:{h=1.0,p=0,drops=[{id="platform",count=1}]},
	# Dirt/stone variants — same drops as base
	80:{h=2.0,p=0,drops=[{id="dirt", count=1}]},  # dirt pebble
	81:{h=2.0,p=0,drops=[{id="dirt", count=1}]},  # dirt root
	82:{h=2.0,p=0,drops=[{id="dirt", count=1}]},  # dirt stone
	83:{h=2.0,p=0,drops=[{id="dirt", count=1}]},  # dirt crack
	84:{h=4.0,p=1,drops=[{id="stone",count=1}]},  # stone fossil
	85:{h=4.0,p=1,drops=[{id="stone",count=1}]},  # stone vein
	13:{h=999,p=99,drops=[]},
	96: {h=5.0,p=1,drops=[{id="coprite_ore",   count=1}]},
	97: {h=5.0,p=1,drops=[{id="stannite_ore",  count=1}]},
	98: {h=6.0,p=1,drops=[{id="ferrite_ore",   count=1}]},
	99: {h=6.0,p=1,drops=[{id="plumbite_ore",  count=1}]},
	100:{h=7.0,p=2,drops=[{id="argite_ore",    count=1}]},
	101:{h=7.0,p=2,drops=[{id="volframite_ore",count=1}]},
	102:{h=8.0,p=2,drops=[{id="aurite_ore",    count=1}]},
	103:{h=8.0,p=2,drops=[{id="palatite_ore",  count=1}]},
	112:{h=10.0,p=4,drops=[{id="aethril_ore",  count=1}]},
	113:{h=10.0,p=4,drops=[{id="veridite_ore", count=1}]},
	114:{h=12.0,p=5,drops=[{id="draconite_ore",count=1}]},
	115:{h=12.0,p=5,drops=[{id="solite_ore",   count=1}]},
	116:{h=15.0,p=6,drops=[{id="voidite_ore",  count=1}]},
	# ── Slope tiles (half-blocks + angled blocks) ──
	# IDs = base_id + 32 (half), + 48 (slope-L), + 64 (slope-R)
	# Same drops as their base tile; hardness/power inherited via _get_slope_base()
	32:{h=2.0,p=0,drops=[{id="dirt",      count=1}]},  # half-block dirt
	33:{h=1.5,p=0,drops=[{id="dirt",      count=1}]},  # half-block grass
	34:{h=4.0,p=1,drops=[{id="stone",     count=1}]},  # half-block stone
	35:{h=1.5,p=0,drops=[{id="sand",      count=1}]},  # half-block sand
	36:{h=3.0,p=1,drops=[{id="sandstone", count=1}]},
	37:{h=3.0,p=1,drops=[{id="ice_block", count=1}]},
	38:{h=1.0,p=0,drops=[{id="snow",      count=1}]},
	39:{h=2.0,p=0,drops=[{id="mud",       count=1}]},
	40:{h=8.0,p=3,drops=[{id="obsidian",  count=1}]},
	42:{h=3.5,p=1,drops=[{id="stone_brick",count=1}]},
	44:{h=999,p=99,drops=[]},
	46:{h=1.5,p=0,drops=[{id="dirt",      count=1}]},  # half-block leaves
	48:{h=2.0,p=0,drops=[{id="dirt",      count=1}]},  # slope-L dirt
	49:{h=1.5,p=0,drops=[{id="dirt",      count=1}]},
	50:{h=4.0,p=1,drops=[{id="stone",     count=1}]},
	51:{h=1.5,p=0,drops=[{id="sand",      count=1}]},
	52:{h=3.0,p=1,drops=[{id="sandstone", count=1}]},
	53:{h=3.0,p=1,drops=[{id="ice_block", count=1}]},
	54:{h=1.0,p=0,drops=[{id="snow",      count=1}]},
	55:{h=2.0,p=0,drops=[{id="mud",       count=1}]},
	56:{h=8.0,p=3,drops=[{id="obsidian",  count=1}]},
	58:{h=3.5,p=1,drops=[{id="stone_brick",count=1}]},
	60:{h=999,p=99,drops=[]},
	62:{h=1.5,p=0,drops=[{id="dirt",      count=1}]},
	64:{h=2.0,p=0,drops=[{id="dirt",      count=1}]},  # slope-R dirt
	65:{h=1.5,p=0,drops=[{id="dirt",      count=1}]},
	66:{h=4.0,p=1,drops=[{id="stone",     count=1}]},
	67:{h=1.5,p=0,drops=[{id="sand",      count=1}]},
	68:{h=3.0,p=1,drops=[{id="sandstone", count=1}]},
	69:{h=3.0,p=1,drops=[{id="ice_block", count=1}]},
	70:{h=1.0,p=0,drops=[{id="snow",      count=1}]},
	71:{h=2.0,p=0,drops=[{id="mud",       count=1}]},
	72:{h=8.0,p=3,drops=[{id="obsidian",  count=1}]},
	74:{h=3.5,p=1,drops=[{id="stone_brick",count=1}]},
	76:{h=999,p=99,drops=[]},
	78:{h=1.5,p=0,drops=[{id="dirt",      count=1}]},
}

@onready var tilemap:     TileMapLayer       = $TileMapLayer
@onready var wall_layer:  TileMapLayer       = $WallLayer
@onready var world_gen:   WorldGen           = $WorldGen
@onready var enemy_mgr:   Node2D             = $EnemyManager
@onready var loot_node:   Node2D             = $LootDrops
@onready var day_night                       = $DayNightCycle
@onready var world_light: DirectionalLight2D = $WorldLight
@onready var ambient:     CanvasModulate     = $AmbientLight
@onready var player:      CharacterBody2D    = $Player
@onready var hud                             = $UI/HUD
@onready var particles:   Node2D             = $Particles
@onready var sky_rect:    ColorRect          = $SkyBackground/SkyGradient
@onready var loading                         = $UI/Loading
@onready var dmg_numbers: Node2D             = $DamageNumbers
@onready var break_fx:    Node2D             = $Particles

var world_seed:      int     = 0
var hardmode:        bool    = false
var defeated_bosses: Array   = []
var spawn_pos:       Vector2 = Vector2.ZERO
var bed_pos:         Vector2 = Vector2.ZERO
var _tile_deltas:    Dictionary = {}

func _ready() -> void:
	var ts = TileSetBuilder.build()
	tilemap.tile_set    = ts
	wall_layer.tile_set = ts

	world_seed = randi()
	if loading:
		loading.set_status("Sculpting terrain…", 5)
		await get_tree().process_frame
		await get_tree().process_frame
	if world_gen.has_signal("progress_changed"):
		world_gen.progress_changed.connect(
			func(status: String, pct: float):
				if loading: loading.set_status(status, pct)
		)
	if world_gen.has_signal("tree_planted"):
		world_gen.tree_planted.connect(_on_tree_planted)
	if world_gen.has_signal("plant_placed"):
		world_gen.plant_placed.connect(_on_plant_placed)

	await world_gen.generate(tilemap, wall_layer, world_seed)
	await get_tree().process_frame

	# ── SPAWN POSITION ─────────────────────────────────────────
	# 16px tiles: tile centre = map_to_local result.
	# tile top = centre.y - 8.  Player CapsuleShape2D radius=6 height=14
	# → capsule bottom in local space = collider_pos.y + (height/2) = -8 + 7 = -1
	# → player.global_y = tile_top - (-1) - 1 = tile_top (exactly on surface)
	var cx = WorldGen.WORLD_WIDTH / 2
	for y in range(WorldGen.SURFACE_MIN - 10, WorldGen.SURFACE_MAX + 20):
		var tid = get_tile_id_at(Vector2i(cx, y))
		if tid >= 0 and tid != WorldGen.T_AIR:
			var tile_center = tilemap.map_to_local(Vector2i(cx, y))
			var tile_top    = tile_center.y - 8.0
			spawn_pos = Vector2(tile_center.x, tile_top)
			break
	if spawn_pos == Vector2.ZERO:
		spawn_pos = Vector2(cx * TILE_SIZE, WorldGen.SURFACE_MAX * TILE_SIZE)

	if loading:
		loading.set_status("Spawning you in…", 95)
		await get_tree().process_frame
		loading.hide_screen()

	player.global_position = spawn_pos
	player.world_ref       = self
	if player.has_signal("died"):
		player.died.connect(_on_player_died)
	if player.has_signal("inventory_changed"):
		player.inventory_changed.connect(_on_inventory_changed)
	hud.set_player(player)

	var mm_script = hud.get_node_or_null("MiniMap")
	if mm_script == null:
		mm_script = get_tree().get_first_node_in_group("minimap")
	if mm_script and mm_script.has_method("init"):
		mm_script.init(self, player)

	day_night.dawn.connect(_on_dawn)
	day_night.dusk.connect(_on_dusk)
	day_night.start()
	# FIX: EnemyManager now has start() defined; passing correct arguments
	enemy_mgr.start(player, tilemap)

	if dmg_numbers: dmg_numbers.add_to_group("damage_numbers")
	if has_node("/root/AudioManager"): AudioManager.play_music("overworld")
	if has_node("/root/SaveSystem"):
		SaveSystem.init_refs(self, player)
		if SaveSystem.slot_exists(0):
			SaveSystem.load_game(0)

func _process(_d: float) -> void:
	_update_lighting()

func _update_lighting() -> void:
	var t   = day_night.time_of_day
	var sun = clamp((sin(t * TAU - PI * 0.5) + 1.0) * 0.6 - 0.04, 0.0, 1.0)
	world_light.energy = sun
	var warm = 1.0 - abs(sun - 0.5) * 2.0
	world_light.color  = Color(0.9+warm*0.1, 0.88+warm*0.04, 0.82-warm*0.15)
	var depth_f = clamp(player.global_position.y / (WorldGen.WORLD_HEIGHT * 16.0), 0.0, 1.0)
	var sl      = lerp(sun, 0.07, depth_f * 0.9)
	ambient.color = Color(sl, sl*0.96, sl*1.06, 1.0)
	var pl = player.get_node_or_null("PlayerLight")
	if pl: pl.energy = lerp(0.0, 0.55, depth_f) + (0.1 if not day_night.is_daytime else 0.0)

func _on_plant_placed(world_pos: Vector2, tile_id: int) -> void:
	var veg = get_node_or_null("VegetationSway")
	if veg and veg.has_method("add_plant"):
		veg.add_plant(world_pos, tile_id)

func _on_tree_planted(world_pos: Vector2, variant: String) -> void:
	var tree_parent = get_node_or_null("Trees")
	if not tree_parent: return
	var ts_script = load("res://scripts/TreeSprite.gd")
	if not ts_script: return
	var sp = Node2D.new()
	sp.set_script(ts_script)
	tree_parent.add_child(sp)
	if sp.has_method("setup"):
		# world_pos is tile centre from WorldGen; pass tile TOP = centre.y - 8
		var tile_top_pos = Vector2(world_pos.x, world_pos.y - 8.0)
		sp.setup(tile_top_pos, variant)

func _on_dawn() -> void:
	if hud: hud.show_popup("☀  Dawn rises over Aetheria", 3.0)

func _on_dusk() -> void:
	if hud: hud.show_popup("🌙  Night falls — stay alert!", 3.0)

# ── TILE ACCESS ───────────────────────────────────────────────
func get_tile_id_at(tile_pos: Vector2i) -> int:
	var ac = tilemap.get_cell_atlas_coords(tile_pos)
	if ac == Vector2i(-1,-1): return -1
	return TileSetBuilder.atlas_to_id(ac)

func get_tile_hardness(tile_id: int) -> float:
	return TILE_DATA.get(tile_id, {}).get("h", 4.0)

func get_tile_req_power(tile_id: int) -> int:
	return TILE_DATA.get(tile_id, {}).get("p", 1)

func break_tile(tile_pos: Vector2i) -> Array:
	var tid   = get_tile_id_at(tile_pos)
	# For slope/half tiles, look up drops from the base terrain ID
	var lookup_id: int = tid
	var H_OFF:  int = TileSetBuilder.HALF_BLOCK_OFFSET
	var SL_OFF: int = TileSetBuilder.SLOPE_L_OFFSET
	var SR_OFF: int = TileSetBuilder.SLOPE_R_OFFSET
	if tid >= SR_OFF and tid < SR_OFF + 16: lookup_id = tid - SR_OFF
	elif tid >= SL_OFF and tid < SL_OFF + 16: lookup_id = tid - SL_OFF
	elif tid >= H_OFF and tid < H_OFF + 16: lookup_id = tid - H_OFF
	var drops = TILE_DATA.get(lookup_id, TILE_DATA.get(tid, {})).get("drops", [])
	_tile_deltas["%d,%d" % [tile_pos.x, tile_pos.y]] = -1
	tilemap.erase_cell(tile_pos)
	_spawn_break_fx(tilemap.map_to_local(tile_pos), tid)
	var veg = get_node_or_null("VegetationSway")
	if tid == WorldGen.T_WOOD:
		drops = drops + _topple_tree(tile_pos)
	elif tid in [WorldGen.T_WEED, WorldGen.T_FLOWER_R, WorldGen.T_FLOWER_Y]:
		# Plant tile itself broken
		if veg and veg.has_method("remove_plant"):
			veg.remove_plant(tilemap.map_to_local(tile_pos))
	else:
		# A solid tile was broken — check if a plant is sitting on top of it
		var above_pos = Vector2i(tile_pos.x, tile_pos.y - 1)
		var above_tid = get_tile_id_at(above_pos)
		if above_tid in [WorldGen.T_WEED, WorldGen.T_FLOWER_R, WorldGen.T_FLOWER_Y]:
			# Remove both the tilemap cell and the visual sprite
			tilemap.erase_cell(above_pos)
			_tile_deltas["%d,%d" % [above_pos.x, above_pos.y]] = -1
			if veg and veg.has_method("remove_plants_above"):
				veg.remove_plants_above(tilemap.map_to_local(tile_pos))
	return drops

func _topple_tree(base_pos: Vector2i) -> Array:
	var trunk_x   = base_pos.x
	var wood_count = 0
	for y in range(base_pos.y - 1, 0, -1):
		var t = get_tile_id_at(Vector2i(trunk_x, y))
		if t == WorldGen.T_WOOD:
			tilemap.erase_cell(Vector2i(trunk_x, y))
			_spawn_break_fx(tilemap.map_to_local(Vector2i(trunk_x, y)), t)
			wood_count += 1
			for side in [-1, 1]:
				var nb = Vector2i(trunk_x + side, y + 1)
				if get_tile_id_at(nb) == WorldGen.T_WOOD:
					tilemap.erase_cell(nb)
		else:
			break
	var tree_parent = get_node_or_null("Trees")
	if tree_parent:
		var base_world = tilemap.map_to_local(base_pos)
		for child in tree_parent.get_children():
			var child_base = child.trunk_base_world if "trunk_base_world" in child else child.global_position
			if child_base.distance_to(base_world) < 20:
				var tw = child.create_tween()
				tw.tween_property(child, "modulate:a", 0.0, 0.3)
				tw.tween_callback(child.queue_free)
				break
	var drops = []
	for _i in wood_count:
		drops.append({id="wood", count=1})
	return drops

func place_tile(tile_pos: Vector2i, tile_id: int) -> bool:
	if get_tile_id_at(tile_pos) != -1: return false
	tilemap.set_cell(tile_pos, 0, TileSetBuilder.id_to_atlas(tile_id))
	_tile_deltas["%d,%d" % [tile_pos.x, tile_pos.y]] = tile_id
	return true

func get_tile_deltas() -> Dictionary: return _tile_deltas.duplicate()

func _spawn_break_fx(world_pos: Vector2, tile_id: int) -> void:
	if break_fx and break_fx.has_method("burst"):
		break_fx.burst(world_pos, tile_id); return
	var col_map = {
		0:Color(0.55,0.38,0.18),1:Color(0.45,0.62,0.22),
		2:Color(0.55,0.55,0.65),8:Color(0.22,0.06,0.35),
		96:Color(0.8,0.42,0.18),98:Color(0.5,0.5,0.58),
		100:Color(0.82,0.82,0.92),102:Color(1.0,0.82,0.04),
		112:Color(0.08,0.82,0.72),114:Color(0.9,0.2,0.18),
		116:Color(0.82,0.9,1.0)
	}
	var col = col_map.get(tile_id, Color(0.6,0.6,0.6))
	for _i in 6:
		var c = ColorRect.new()
		c.size    = Vector2(randf_range(2,4),randf_range(2,4))
		c.color   = col
		c.position= world_pos + Vector2(randf_range(-6,6),randf_range(-6,6))
		particles.add_child(c)
		var tw = create_tween()
		tw.tween_property(c,"position",
			c.position+Vector2(randf_range(-24,24),randf_range(-44,-8)),0.35)
		tw.parallel().tween_property(c,"modulate:a",0.0,0.35)
		tw.tween_callback(c.queue_free)

func spawn_loot(world_pos: Vector2, loot: Array) -> void:
	var ds = load("res://scenes/ItemDrop.tscn")
	if not ds: return
	for entry in loot:
		var d = ds.instantiate()
		d.setup(entry.get("id",""), entry.get("count",1))
		d.global_position = world_pos + Vector2(randf_range(-16,16),-8)
		loot_node.add_child(d)

func _on_player_died() -> void:
	await get_tree().create_timer(2.8).timeout
	player.respawn(bed_pos if bed_pos != Vector2.ZERO else spawn_pos)
	if hud: hud.hide_death_screen()

func _on_inventory_changed() -> void:
	if not hardmode and "skelethor" in defeated_bosses:
		hardmode = true
		world_gen.scatter_hardmode_ores(tilemap)
		if hud: hud.show_popup("★  HARDMODE — New ores have cracked through the deep!", 6.0)

func register_boss_defeat(boss_id: String) -> void:
	if boss_id not in defeated_bosses:
		defeated_bosses.append(boss_id)
	_on_inventory_changed()

func register_bed(world_pos: Vector2) -> void:
	bed_pos = world_pos
	if hud: hud.show_popup("Spawn point set!", 2.0)

# ── SLOPE / SHAPE CYCLING ─────────────────────────────────────
# Cycles a placed block through: full → half-block → slope-L → slope-R → full
# Called by Player._handle_interaction when hammer is equipped.
const SLOPE_SOURCE_IDS = [0,1,2,3,4,5,6,7,8,10,12,14]

func cycle_block_shape(tile_pos: Vector2i) -> void:
	var tid = get_tile_id_at(tile_pos)
	if tid < 0: return

	# Determine base terrain ID (strip any existing slope offset)
	var base_id: int = tid
	var H_OFF:  int = TileSetBuilder.HALF_BLOCK_OFFSET   # 32
	var SL_OFF: int = TileSetBuilder.SLOPE_L_OFFSET       # 48
	var SR_OFF: int = TileSetBuilder.SLOPE_R_OFFSET       # 64

	if tid >= SR_OFF and tid < SR_OFF + 16:
		base_id = tid - SR_OFF
	elif tid >= SL_OFF and tid < SL_OFF + 16:
		base_id = tid - SL_OFF
	elif tid >= H_OFF and tid < H_OFF + 16:
		base_id = tid - H_OFF
	# else: already the full block

	if not base_id in SLOPE_SOURCE_IDS:
		return  # only cycle terrain blocks (not ores, not bedrock)

	# Advance to next shape
	var next_id: int
	if tid == base_id:             # full → half
		next_id = base_id + H_OFF
	elif tid == base_id + H_OFF:   # half → slope-L
		next_id = base_id + SL_OFF
	elif tid == base_id + SL_OFF:  # slope-L → slope-R
		next_id = base_id + SR_OFF
	else:                          # slope-R → full
		next_id = base_id

	tilemap.erase_cell(tile_pos)
	tilemap.set_cell(tile_pos, 0, TileSetBuilder.id_to_atlas(next_id))
	_tile_deltas["%d,%d" % [tile_pos.x, tile_pos.y]] = next_id

	# Particle flash to show the reshape
	var flash = ColorRect.new()
	flash.size = Vector2(16, 16)
	flash.color = Color(1, 0.9, 0.4, 0.6)
	flash.global_position = tilemap.map_to_local(tile_pos) - Vector2(8, 8)
	particles.add_child(flash)
	var tw = flash.create_tween()
	tw.tween_property(flash, "modulate:a", 0.0, 0.18)
	tw.tween_callback(flash.queue_free)
