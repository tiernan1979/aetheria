# World3DManager.gd
# Attach as a child of World.gd's root node.
# Manages the pseudo-3D shader on the TileMapLayer:
#   - Applies the shader material at startup
#   - Updates light direction based on time of day (sun arc)
#   - Updates underground tint based on player depth
#   - Provides API for special lighting (boss arenas, caves, underworld)
#
# Add to World.tscn as Node child of the World root, AFTER TileMapLayer.

extends Node

const SHADER_PATH = "res://scripts/shaders/Pseudo3DShader.gdshader"

@export var tilemap_path: NodePath = "TileMapLayer"
@export var player_path:  NodePath = "Player"
@export var day_night_path: NodePath = "DayNightCycle"

@onready var tilemap:  TileMapLayer  = get_node_or_null(tilemap_path)
@onready var player:   CharacterBody2D = get_node_or_null(player_path)
@onready var day_night                  = get_node_or_null(day_night_path)

var _mat: ShaderMaterial

# Light presets for different areas
const PRESETS = {
	"surface_day": {
		"light_dir":        Vector2(0.6, -0.8),
		"light_color":      Color(1.00, 0.95, 0.78),
		"ambient_color":    Color(0.22, 0.20, 0.30),
		"light_intensity":  1.0,
		"depth_strength":   0.30,
		"edge_strength":    0.45,
	},
	"surface_night": {
		"light_dir":        Vector2(-0.4, -0.6),
		"light_color":      Color(0.30, 0.38, 0.65),
		"ambient_color":    Color(0.05, 0.05, 0.12),
		"light_intensity":  0.45,
		"depth_strength":   0.22,
		"edge_strength":    0.35,
	},
	"cave": {
		"light_dir":        Vector2(0.3, -0.5),
		"light_color":      Color(0.50, 0.45, 0.80),
		"ambient_color":    Color(0.04, 0.03, 0.09),
		"light_intensity":  0.35,
		"depth_strength":   0.40,
		"edge_strength":    0.60,
	},
	"underworld": {
		"light_dir":        Vector2(0.0, -1.0),
		"light_color":      Color(0.90, 0.30, 0.12),
		"ambient_color":    Color(0.12, 0.04, 0.02),
		"light_intensity":  0.70,
		"depth_strength":   0.50,
		"edge_strength":    0.65,
	},
}

var _current_preset:    String  = "surface_day"
var _target_preset:     String  = "surface_day"
var _blend_t:           float   = 1.0
var _blend_from:        Dictionary = {}
var _blend_to:          Dictionary = {}

func _ready() -> void:
	add_to_group("world3d")
	if not ResourceLoader.exists(SHADER_PATH):
		push_warning("World3DManager: shader not found at '%s'" % SHADER_PATH)
		return

	_mat = ShaderMaterial.new()
	_mat.shader = load(SHADER_PATH)

	if tilemap:
		tilemap.material = _mat
	else:
		push_warning("World3DManager: could not find TileMapLayer")
		return

	# Also apply to wall layer if present
	var wall = get_node_or_null("../WallLayer")
	if wall:
		var wall_mat = _mat.duplicate()
		wall_mat.set_shader_parameter("edge_strength", 0.25)
		wall_mat.set_shader_parameter("depth_strength", 0.15)
		wall.material = wall_mat

	_apply_preset("surface_day", true)
	print("World3DManager: pseudo-3D shader applied.")

func _process(delta: float) -> void:
	if not _mat: return

	# ── Time of day → light direction ────────────────────────────────────────
	if day_night:
		_update_time_of_day(day_night.time_of_day)

	# ── Player depth → underground tint ──────────────────────────────────────
	if player:
		_update_depth(player.global_position.y)

	# ── Smooth preset blending ────────────────────────────────────────────────
	if _blend_t < 1.0:
		_blend_t = min(1.0, _blend_t + delta * 1.5)
		_apply_blend(_blend_t)

func _update_time_of_day(t: float) -> void:
	# t: 0=midnight, 0.5=noon, 1=midnight
	# Sun arc: rises from east (-x,+y) → peaks at top (x,−y) → sets west (+x,+y)
	var sun_angle_deg = (t - 0.25) * 360.0   # 0.25=dawn, 0.75=dusk
	var sun_angle_rad = deg_to_rad(sun_angle_deg)
	var sun_dir = Vector2(cos(sun_angle_rad), -abs(sin(sun_angle_rad)))
	_mat.set_shader_parameter("light_dir", sun_dir.normalized())

	# Light color shifts warm at dawn/dusk, white at noon, blue at night
	var sun_height = sin(t * TAU)   # -1 to 1
	var warmth     = 1.0 - abs(sun_height)   # 1 at horizon, 0 at noon/midnight
	var day_frac   = max(0.0, sun_height)
	var light_col  = Color(
		0.85 + warmth * 0.15,
		0.80 + day_frac * 0.15 - warmth * 0.05,
		0.65 + day_frac * 0.10 - warmth * 0.15
	)
	_mat.set_shader_parameter("light_color", light_col)
	_mat.set_shader_parameter("light_intensity", max(0.08, sun_height * 1.1))

	# Ambient: deep purple at night, soft grey-blue at day
	var amb = Color(
		lerp(0.04, 0.18, max(0.0, sun_height)),
		lerp(0.04, 0.18, max(0.0, sun_height)),
		lerp(0.10, 0.28, max(0.0, sun_height))
	)
	_mat.set_shader_parameter("ambient_color", amb)

func _update_depth(player_y: float) -> void:
	# Tile size 16; cavern starts around y=550 tiles → 8800px; underworld 1680 tiles → 26880px
	var depth_px      = player_y
	var cavern_start  = 550.0  * 16.0
	var underworld_y  = 1680.0 * 16.0

	var underground_blend = 0.0
	var chosen_preset     = "surface_day"

	if depth_px > underworld_y:
		underground_blend = 1.0
		chosen_preset     = "underworld"
	elif depth_px > cavern_start:
		var t = clamp((depth_px - cavern_start) / (underworld_y - cavern_start), 0.0, 1.0)
		underground_blend = t
		chosen_preset     = "cave"

	_mat.set_shader_parameter("underground_blend", underground_blend)

	if chosen_preset != _current_preset:
		_start_blend(chosen_preset)

# ─────────────────────────────────────────────────────────────────────────────
#  PRESET MANAGEMENT
# ─────────────────────────────────────────────────────────────────────────────
func _apply_preset(preset_id: String, immediate: bool = false) -> void:
	if not PRESETS.has(preset_id): return
	if immediate:
		var p = PRESETS[preset_id]
		for key in p:
			_mat.set_shader_parameter(key, p[key])
		_current_preset = preset_id
	else:
		_start_blend(preset_id)

func _start_blend(preset_id: String) -> void:
	if not PRESETS.has(preset_id): return
	if preset_id == _current_preset: return
	_blend_from    = PRESETS.get(_current_preset, {})
	_blend_to      = PRESETS[preset_id]
	_blend_t       = 0.0
	_current_preset = preset_id

func _apply_blend(t: float) -> void:
	for key in _blend_to:
		var a = _blend_from.get(key, _blend_to[key])
		var b = _blend_to[key]
		var val
		if a is Vector2:
			val = a.lerp(b, t)
		elif a is Color:
			val = a.lerp(b, t)
		elif a is float or a is int:
			val = lerp(float(a), float(b), t)
		else:
			val = b
		_mat.set_shader_parameter(key, val)

# ─────────────────────────────────────────────────────────────────────────────
#  PUBLIC API — called from boss fight scenes, etc.
# ─────────────────────────────────────────────────────────────────────────────
func set_boss_arena_lighting(boss_id: String) -> void:
	match boss_id:
		"slime_king":
			_mat.set_shader_parameter("light_color", Color(0.3, 0.9, 0.4))
			_mat.set_shader_parameter("ambient_color", Color(0.05, 0.15, 0.08))
		"eye_of_abyss":
			_mat.set_shader_parameter("light_color", Color(0.8, 0.2, 0.9))
			_mat.set_shader_parameter("ambient_color", Color(0.08, 0.02, 0.12))
		"skelethor":
			_mat.set_shader_parameter("light_color", Color(0.6, 0.5, 0.9))
			_mat.set_shader_parameter("ambient_color", Color(0.03, 0.03, 0.08))
		"wyrm_queen":
			_mat.set_shader_parameter("light_color", Color(0.3, 0.8, 0.3))
			_mat.set_shader_parameter("ambient_color", Color(0.04, 0.10, 0.05))

func restore_normal_lighting() -> void:
	_start_blend(_current_preset)

func set_depth_strength(v: float) -> void:
	if _mat: _mat.set_shader_parameter("depth_strength", v)

func set_edge_strength(v: float) -> void:
	if _mat: _mat.set_shader_parameter("edge_strength", v)
