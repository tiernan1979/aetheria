# VegetationSway.gd — Animated plant sprites (weeds, flowers) on the surface.
# FIX v2: Plants now correctly anchor to the ground tile beneath them.
# Root cause of "flowers half in sky": world_pos from map_to_local is the tile CENTRE (y),
# so the plant was positioned at tile-centre instead of tile-bottom.
# 
# Correct math:
#   Tile centre Y   = world_pos.y  (from map_to_local for the plant tile at surf-1)
#   Tile bottom Y   = world_pos.y + 8.0   (tile is 16px tall, half = 8)
#   Plant should sit with its bottom at the GRASS tile top = plant-tile bottom = world_pos.y + 8
#   Node origin at plant bottom, image offset UP by 8 so sprite fills the tile above ground.

class_name VegetationSway
extends Node2D

const ATLAS_PATH = "res://assets/tilesets/world_tiles.png"
const TILE_PX    = 16
const ATLAS_COLS = 16

const TILE_ATLAS_COORDS = {
	16: Vector2i(0, 1),   # T_WEED      — col 0, row 1
	17: Vector2i(1, 1),   # T_FLOWER_R  — col 1, row 1
	18: Vector2i(2, 1),   # T_FLOWER_Y  — col 2, row 1
}

const SWAY_FREQ    = 1.0
const SWAY_AMP     = 2.2    # degrees max sway
const WEED_SCALE   = Vector2(1.0, 1.0)
const FLOWER_SCALE = Vector2(1.1, 1.1)

var _sprites: Array = []
var _time:    float = 0.0
var _atlas_tex       # Texture2D, loaded once

func _ready() -> void:
	if ResourceLoader.exists(ATLAS_PATH):
		_atlas_tex = load(ATLAS_PATH)
	else:
		push_warning("VegetationSway: atlas not found at " + ATLAS_PATH)

# Called by World._on_plant_placed.
# world_pos = map_to_local result for the plant tile = tile CENTRE of the plant tile.
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

	# Pivot at the BOTTOM of the sprite for natural swaying.
	# centered=false + offset places the sprite so its bottom-left is at node origin.
	# We want: node origin = bottom-centre of plant = world_pos.y + 8 (tile bottom).
	# With centered=false, the sprite top-left is at node origin.
	# So offset the sprite LEFT by half-width and UP by full-height:
	sp.centered = false
	sp.offset   = Vector2(-float(TILE_PX) * 0.5, -float(TILE_PX))

	# Scale — flowers slightly larger for readability
	if tile_id == 16:  # weed
		sp.scale = WEED_SCALE
	else:              # flower_r / flower_y
		sp.scale = FLOWER_SCALE

	# FIX: Place origin at bottom of the plant tile.
	# plant tile centre = world_pos.y
	# plant tile bottom = world_pos.y + TILE_PX/2 = world_pos.y + 8
	# That bottom edge should sit exactly at the grass tile top (surf tile top = surf_centre - 8).
	# So origin Y = world_pos.y + 8  correctly rests the plant on the grass.
	sp.global_position = Vector2(world_pos.x, world_pos.y + float(TILE_PX) * 0.5)

	add_child(sp)
	_sprites.append({
		"node":        sp,
		"world_pos":   world_pos,
		"tile_id":     tile_id,
		"phase":       randf() * TAU,
		"freq":        SWAY_FREQ + randf_range(-0.2, 0.2),
		"amp":         SWAY_AMP  + randf_range(-0.5, 0.5),
		"shake":       0.0,
	})

# Called by World.break_tile when the PLANT tile itself is broken.
func remove_plant(tile_center_world: Vector2) -> void:
	for i in range(_sprites.size() - 1, -1, -1):
		if not is_instance_valid(_sprites[i]["node"]):
			_sprites.remove_at(i); continue
		var stored: Vector2 = _sprites[i]["world_pos"]
		if stored.distance_to(tile_center_world) < 10.0:
			_pop_sprite(i, _sprites[i]["node"])
			return

# Called by World.break_tile when the SUPPORT tile (grass below) is broken.
func remove_plants_above(support_tile_center: Vector2) -> void:
	# Support tile top = support_tile_center.y - 8
	# Plant tile centre = support_tile_center.y - TILE_PX  (one tile above)
	var expected_plant_y: float = support_tile_center.y - float(TILE_PX)
	for i in range(_sprites.size() - 1, -1, -1):
		if not is_instance_valid(_sprites[i]["node"]):
			_sprites.remove_at(i); continue
		var stored: Vector2 = _sprites[i]["world_pos"]
		if abs(stored.x - support_tile_center.x) < 6.0 and abs(stored.y - expected_plant_y) < 6.0:
			_pop_sprite(i, _sprites[i]["node"])

func _pop_sprite(i: int, sp: Sprite2D) -> void:
	var tw = sp.create_tween()
	# Fly up and fade out naturally
	tw.tween_property(sp, "position:y", sp.position.y - 12.0, 0.18).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(sp, "modulate:a", 0.0, 0.15)
	tw.tween_callback(sp.queue_free)
	_sprites.remove_at(i)

func _process(delta: float) -> void:
	_time += delta
	for entry in _sprites:
		var sp: Sprite2D = entry["node"]
		if not is_instance_valid(sp): continue

		var t_freq: float = entry["freq"]
		var t_amp:  float = entry["amp"]

		# Primary gentle sway + harmonic overtone for organic feel
		var sway: float = sin(_time * t_freq + entry["phase"]) * t_amp
		sway += sin(_time * t_freq * 2.3 + entry["phase"] * 1.4) * t_amp * 0.18
		sway += sin(_time * t_freq * 5.1 + entry["phase"] * 0.7) * t_amp * 0.06

		if entry["shake"] > 0.0:
			sway += sin(_time * 11.0) * entry["shake"] * 4.0
			entry["shake"] = max(0.0, entry["shake"] - delta * 5.0)

		sp.rotation_degrees = lerp(sp.rotation_degrees, sway, 18.0 * delta)

func trigger_shake(world_pos: Vector2, radius: float = 24.0) -> void:
	for entry in _sprites:
		var sp: Sprite2D = entry["node"]
		if not is_instance_valid(sp): continue
		if sp.global_position.distance_to(world_pos) < radius:
			entry["shake"] = SWAY_AMP * 1.2