# Minimap.gd
# Attach to a Control node inside HUD.
# Renders a compressed overview of the world using pixel sampling.
# 
# Node tree:
#   Minimap (Control)  — size 200×120, top-right corner
#   ├── Frame (Panel)  — dark border
#   ├── MapTexture (TextureRect) — the rendered map image
#   ├── PlayerDot (ColorRect) 2×2 — tracks player position
#   └── ZoneLabel (Label) — shows current biome name

extends Control

const MAP_W    = 200
const MAP_H    = 100
const UPDATE_INT = 0.8   # seconds between full redraws

var _world_ref   = null
var _player_ref  = null
var _map_img:    Image
var _map_tex:    ImageTexture
var _dirty:      bool = true
var _timer:      float = 0.0

# Tile color lookup (tile_id → minimap color)
const TILE_COLORS: Dictionary = {
	-1:  Color(0.05, 0.04, 0.09),   # air / cave
	0:   Color(0.42, 0.26, 0.12),   # dirt
	1:   Color(0.25, 0.62, 0.18),   # grass
	2:   Color(0.34, 0.34, 0.42),   # stone
	3:   Color(0.82, 0.72, 0.42),   # sand
	4:   Color(0.72, 0.61, 0.34),   # sandstone
	5:   Color(0.62, 0.80, 0.95),   # ice
	6:   Color(0.90, 0.92, 0.98),   # snow
	7:   Color(0.27, 0.18, 0.08),   # mud
	8:   Color(0.10, 0.03, 0.16),   # obsidian
	9:   Color(0.51, 0.30, 0.10),   # wood
	10:  Color(0.38, 0.38, 0.45),   # stone brick
	11:  Color(0.60, 0.40, 0.15),   # platform
	12:  Color(0.07, 0.07, 0.08),   # bedrock  (col 12, row 0 in atlas)
	# Ore tiles — row 6 of atlas (id = col + 6*16)
	96:  Color(0.88, 0.48, 0.18),   # blazite  (col 0 row 6 → 96)
	97:  Color(0.28, 0.78, 0.42),   # verdite  (col 1 row 6 → 97)
	98:  Color(0.42, 0.48, 0.62),   # ferrite  (col 2 row 6 → 98)
	99:  Color(0.55, 0.38, 0.72),   # gravite  (col 3 row 6 → 99)
	100: Color(0.85, 0.88, 0.98),   # moonite
	101: Color(0.14, 0.72, 0.58),   # jadite
	102: Color(0.92, 0.75, 0.08),   # solite
	103: Color(0.60, 0.85, 0.98),   # crystite
	# Row 7 ores
	112: Color(0.08, 0.88, 0.78),   # aethite  (col 0 row 7 → 112)
	113: Color(0.82, 0.28, 0.90),   # voidite
	114: Color(0.88, 0.15, 0.15),   # embrite
	115: Color(0.72, 0.78, 0.95),   # spectrite
	116: Color(0.90, 0.95, 1.00),   # radiance
}

const WATER_COLOR  = Color(0.18, 0.38, 0.72)
const LAVA_COLOR   = Color(0.90, 0.28, 0.05)
const SKY_COLOR    = Color(0.10, 0.15, 0.35)

@onready var map_texture_rect: TextureRect = $MapTexture
@onready var player_dot:       ColorRect   = $PlayerDot
@onready var zone_label:       Label       = $ZoneLabel

func _ready() -> void:
	add_to_group("minimap")
	custom_minimum_size = Vector2(MAP_W + 4, MAP_H + 4)
	_map_img = Image.create(MAP_W, MAP_H, false, Image.FORMAT_RGBA8)
	_map_tex = ImageTexture.create_from_image(_map_img)
	if map_texture_rect:
		map_texture_rect.texture = _map_tex
		map_texture_rect.position = Vector2(2, 2)
		map_texture_rect.size     = Vector2(MAP_W, MAP_H)

func init(world_node, player_node) -> void:
	_world_ref  = world_node
	_player_ref = player_node
	_dirty = true

func _process(delta: float) -> void:
	if not _world_ref or not _player_ref:
		# Auto-discover world and player
		if not _world_ref:
			_world_ref = get_tree().get_first_node_in_group("world")
		if not _player_ref:
			_player_ref = get_tree().get_first_node_in_group("player")
		if not _world_ref or not _player_ref: return
	_timer += delta
	if _timer >= UPDATE_INT or _dirty:
		_timer = 0.0
		_dirty = false
		_redraw_map()
	_update_player_dot()
	_update_zone_label()

func _redraw_map() -> void:
	if not _world_ref: return

	var world_w  = 4200   # WorldGen.WORLD_WIDTH
	var world_h  = 1200   # WorldGen.WORLD_HEIGHT
	var step_x   = float(world_w) / MAP_W
	var step_y   = float(world_h) / MAP_H

	# Center the view on player with a scroll window
	var px_tile  = int(_player_ref.global_position.x / 16.0)
	var py_tile  = int(_player_ref.global_position.y / 16.0)
	var view_half_w = int(MAP_W * step_x / 2.0)
	var view_half_h = int(MAP_H * step_y / 2.0)
	var ox = clamp(px_tile - view_half_w, 0, world_w - MAP_W)
	var oy = clamp(py_tile - view_half_h, 0, world_h - MAP_H)

	_map_img.fill(Color(0.05, 0.04, 0.09, 1.0))

	for my in range(MAP_H):
		var wy = oy + int(my * step_y)
		if wy < 0 or wy >= world_h: continue
		for mx in range(MAP_W):
			var wx = ox + int(mx * step_x)
			if wx < 0 or wx >= world_w: continue

			var tile_id = _world_ref.get_tile_id_at(Vector2i(wx, wy))
			var col:Color

			if wy < WorldGen.SURFACE_MIN:
				col = SKY_COLOR
			elif tile_id == -1:
				col = Color(0.06, 0.05, 0.10)  # air/cave
			else:
				col = TILE_COLORS.get(tile_id, Color(0.3, 0.3, 0.35))

			# Depth tinting
			var depth_t = clamp(float(wy) / float(world_h), 0.0, 1.0)
			col = col.lerp(Color(0.05, 0.04, 0.08), depth_t * 0.4)

			_map_img.set_pixel(mx, my, col)

	_map_tex.update(_map_img)

func _update_player_dot() -> void:
	if not player_dot or not _player_ref: return
	var world_w = 4200; var world_h = 1200
	var px_tile = _player_ref.global_position.x / 16.0
	var py_tile = _player_ref.global_position.y / 16.0
	var t = fmod(Time.get_ticks_msec() * 0.003, 1.0)
	player_dot.color = Color(1.0, 1.0-t*0.3, t*0.2, 0.9+t*0.1)
	# Position relative to map view
	var view_frac_x = clamp(px_tile / world_w, 0.0, 1.0)
	var view_frac_y = clamp(py_tile / world_h, 0.0, 1.0)
	player_dot.position = Vector2(
		2.0 + view_frac_x * MAP_W - 1.0,
		2.0 + view_frac_y * MAP_H - 1.0
	)

func _update_zone_label() -> void:
	if not zone_label or not _player_ref: return
	var py = _player_ref.global_position.y / 16.0
	var zone: String
	if   py < 180:  zone = "Sky"
	elif py < 400:  zone = "Surface"
	elif py < 700:  zone = "Underground"
	elif py < 950:  zone = "Caverns"
	elif py < 1100: zone = "Deep Caverns"
	else:           zone = "The Underworld"
	zone_label.text = zone

func mark_dirty() -> void:
	_dirty = true
