# VegetationSway.gd — Animated plant sprites (weeds, flowers) on the surface.
# Uses AtlasTexture sliced from world_tiles.png — no separate sprite files needed.
class_name VegetationSway
extends Node2D

const ATLAS_PATH = "res://assets/tilesets/world_tiles.png"
const TILE_PX    = 16
const ATLAS_COLS = 16

const TILE_ATLAS_COORDS = {
	16: Vector2i(0, 1),   # T_WEED
	17: Vector2i(1, 1),   # T_FLOWER_R
	18: Vector2i(2, 1),   # T_FLOWER_Y
}

const SWAY_FREQ = 1.2
const SWAY_AMP  = 2.5

var _sprites:   Array = []
var _time:      float = 0.0
var _atlas_tex         # Texture2D, loaded once

func _ready() -> void:
	if ResourceLoader.exists(ATLAS_PATH):
		_atlas_tex = load(ATLAS_PATH)
	else:
		push_warning("VegetationSway: atlas not found at " + ATLAS_PATH)

# Called by World._on_plant_placed.
# world_pos = map_to_local result for the plant tile = tile CENTRE.
func add_plant(world_pos: Vector2, tile_id: int) -> void:
	if not _atlas_tex: return
	if not tile_id in TILE_ATLAS_COORDS: return

	var ac  = TILE_ATLAS_COORDS[tile_id]
	var tex = AtlasTexture.new()
	tex.atlas       = _atlas_tex
	tex.region      = Rect2(ac.x * TILE_PX, ac.y * TILE_PX, TILE_PX, TILE_PX)
	tex.filter_clip = true

	var sp = Sprite2D.new()
	sp.texture        = tex
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sp.centered       = true
	# FIX: pivot at the BASE of the plant (bottom-centre of sprite image).
	# The plant must sit ON TOP OF the grass tile below it.
	# world_pos is the CENTER of the plant tile (surf-1 row).
	# The BOTTOM of the plant tile  = world_pos.y + TILE_PX/2 = world_pos.y + 8.
	# That bottom edge lines up perfectly with the TOP of the grass tile below.
	# We want the node origin at the plant's bottom so rotation pivots there.
	# centered=true → image centre at (0,0). Shift image UP by half height:
	sp.offset = Vector2(0.0, -float(TILE_PX) * 0.5)
	# Place origin at the BOTTOM of the plant tile = world_pos.y + 8
	sp.global_position = Vector2(world_pos.x, world_pos.y + 8.0)

	add_child(sp)
	_sprites.append({
		"node":      sp,
		"world_pos": world_pos,   # store for support-tile removal check
		"phase":     randf() * TAU,
		"freq":      SWAY_FREQ + randf_range(-0.15, 0.15),
		"shake":     0.0,
	})

# Called by World.break_tile when the PLANT tile itself is broken.
func remove_plant(tile_center_world: Vector2) -> void:
	for i in range(_sprites.size() - 1, -1, -1):
		var sp: Sprite2D = _sprites[i]["node"]
		if not is_instance_valid(sp):
			_sprites.remove_at(i); continue
		# Match by sprite origin position (world_pos.y + 8 = plant bottom)
		var stored: Vector2 = _sprites[i]["world_pos"]
		if stored.distance_to(tile_center_world) < 12.0:
			_pop_sprite(i, sp)
			return

# Called by World.break_tile when the SUPPORT tile (grass below) is broken.
# Any plant whose bottom sits within 2px of the broken tile's top must fall.
func remove_plants_above(support_tile_center: Vector2) -> void:
	# Support tile top = support_tile_center.y - 8
	# Plant bottom     = plant_world_pos.y + 8
	# They match when plant_world_pos.y + 8  ≈  support_tile_center.y - 8
	# i.e.  plant_world_pos.y  ≈  support_tile_center.y - 16
	var expected_plant_y: float = support_tile_center.y - float(TILE_PX)
	for i in range(_sprites.size() - 1, -1, -1):
		var sp: Sprite2D = _sprites[i]["node"]
		if not is_instance_valid(sp):
			_sprites.remove_at(i); continue
		var stored: Vector2 = _sprites[i]["world_pos"]
		if abs(stored.x - support_tile_center.x) < 4.0 and abs(stored.y - expected_plant_y) < 4.0:
			_pop_sprite(i, sp)

func _pop_sprite(i: int, sp: Sprite2D) -> void:
	var tw = sp.create_tween()
	tw.tween_property(sp, "modulate:a", 0.0, 0.12)
	tw.tween_callback(sp.queue_free)
	_sprites.remove_at(i)

func _process(delta: float) -> void:
	_time += delta
	for entry in _sprites:
		var sp: Sprite2D = entry["node"]
		if not is_instance_valid(sp): continue
		var sway: float = sin(_time * entry["freq"] + entry["phase"]) * SWAY_AMP
		if entry["shake"] > 0.0:
			sway += sin(_time * 9.0) * entry["shake"] * 3.0
			entry["shake"] = max(0.0, entry["shake"] - delta * 4.0)
		sp.rotation_degrees = sway

func trigger_shake(world_pos: Vector2, radius: float = 22.0) -> void:
	for entry in _sprites:
		var sp: Sprite2D = entry["node"]
		if not is_instance_valid(sp): continue
		if sp.global_position.distance_to(world_pos) < radius:
			entry["shake"] = SWAY_AMP
