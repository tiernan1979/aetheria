# HairFlowSystem.gd
# Handles dynamic hair animation based on wind and movement
# Provides smooth hair flow physics for character customization

extends Node2D

# Hair configuration
@export var hair_color: String = "black"
@export var is_female: bool = false
@export var hair_length: int = 1  # 0 = short, 1 = medium, 2 = long

# Hair physics
@export var base_flow: float = 0.5  # Base hair movement responsiveness
@export var wind_influence: float = 1.0  # How much wind affects hair
@export var gravity_influence: float = 0.3  # How much gravity affects hair

# Hair sprites for different wind states
var _hair_sprites: Dictionary = {}
var _current_hair_state: String = "normal"  # "normal", "light", "medium", "strong"
var _current_frame: int = 0

# Animation
var _anim_timer: float = 0.0
var _anim_speed: float = 8.0  # Frames per second
var _is_animating: bool = false

# Wind reference
var _wind_system: Node = null

# Hair sprite paths
const SPRITE_PATH = "res://assets/sprites/player/parts/"

func _ready() -> void:
	_setup_hair_sprites()
	_initialize_wind()

func _setup_hair_sprites() -> void:
	"""Load all hair sprite variations"""
	var colors = ["black", "brown", "blonde", "red"]
	var gender_prefix = "female_" if is_female else ""

	for color in colors:
		var base_key = color  # e.g., "black"
		var sprite_key = "%s_%s" % [gender_prefix, color]  # e.g., "female_black"

		# Normal hair (no wind)
		var normal_path = SPRITE_PATH + "hair_%s%s.png" % [gender_prefix, color]
		if ResourceLoader.exists(normal_path):
			_hair_sprites["%s_normal" % sprite_key] = load(normal_path)

		# Wind states (frame 1 - light breeze)
		var wind1_path = SPRITE_PATH + "hair_%s%s_wind1.png" % [gender_prefix, color]
		if ResourceLoader.exists(wind1_path):
			_hair_sprites["%s_light" % sprite_key] = load(wind1_path)
			_hair_sprites["%s_medium" % sprite_key] = load(wind1_path)

		# Wind states (frame 2 - strong wind)
		var wind2_path = SPRITE_PATH + "hair_%s%s_wind2.png" % [gender_prefix, color]
		if ResourceLoader.exists(wind2_path):
			_hair_sprites["%s_strong" % sprite_key] = load(wind2_path)

func _initialize_wind() -> void:
	"""Find or create wind system"""
	_wind_system = get_tree().root.get_node_or_null("WindSystem")
	if not _wind_system:
		_wind_system = get_node_or_null("../WindSystem")

func _process(delta: float) -> void:
	if _is_animating:
		_update_animation(delta)

	# Update wind responsiveness
	_update_wind_response()

func _update_animation(delta: float) -> void:
	"""Animate hair sprites based on current state"""
	_anim_timer += delta

	var frame_duration = 1.0 / _anim_speed
	if _anim_timer >= frame_duration:
		_anim_timer = 0.0
		_current_frame = (_current_frame + 1) % 4  # 4 animation frames

func _update_wind_response() -> void:
	"""Update hair appearance based on wind conditions"""
	if not _wind_system:
		return

	var player_pos = get_global_position()
	var wind_data = _wind_system.get_wind_at_position(player_pos)
	var wind_strength = wind_data["strength"]
	var wind_gust = wind_data["gust"]

	# Determine hair state based on wind strength
	var new_state = "normal"
	if wind_strength > 2.5 or wind_gust > 0.8:
		new_state = "strong"
		_anim_speed = 12.0
	elif wind_strength > 1.5 or wind_gust > 0.5:
		new_state = "medium"
		_anim_speed = 10.0
	elif wind_strength > 0.8:
		new_state = "light"
		_anim_speed = 8.0
	else:
		_anim_speed = 6.0
		_anim_timer = 0.0

	# Start animation if wind picked up
	if new_state != "normal" and not _is_animating:
		_is_animating = true
		_current_frame = 0

	# Stop animation in calm
	if new_state == "normal" and _is_animating:
		_anim_timer = 0.0
		_is_animating = false

	_current_hair_state = new_state

func set_hair_color(color: String) -> void:
	hair_color = color
	_apply_hair_sprite()

func set_gender(female: bool) -> void:
	is_female = female
	_setup_hair_sprites()
	_apply_hair_sprite()

func get_current_sprite() -> Texture2D:
	"""Get the appropriate hair sprite for current state"""
	var sprite_key = "%s%s_%s" % ["female_" if is_female else "", hair_color, _current_hair_state]
	var sprite = _hair_sprites.get(sprite_key)

	# Fallback to normal hair if state sprite not found
	if not sprite:
		sprite_key = "%s%s_normal" % ["female_" if is_female else "", hair_color]
		sprite = _hair_sprites.get(sprite_key)

	# Ultimate fallback
	if not sprite:
		sprite = _hair_sprites.values()[0] if _hair_sprites.size() > 0 else null

	return sprite

func get_hair_offset() -> Vector2:
	"""Get hair position offset based on wind and animation"""
	var offset = Vector2.ZERO

	# Base offset from wind
	if _wind_system:
		var wind_data = _wind_system.get_wind_at_position(get_global_position())
		var wind_dir = wind_data["direction"]
		var wind_str = wind_data["strength"]

		offset = wind_dir * wind_str * 2.0 * wind_influence

	# Animation bob
	if _is_animating:
		var bob_amount = sin(_current_frame * PI / 2.0) * 1.0
		offset.y += bob_amount

	return offset

func start_wind_animation() -> void:
	"""Begin wind-driven animation"""
	_is_animating = true
	_current_frame = 0

func stop_wind_animation() -> void:
	"""Stop wind animation, return to static"""
	_is_animating = false
	_anim_timer = 0.0

func set_wind_intensity(intensity: float) -> void:
	"""Manually set wind intensity (0.0 - 1.0)"""
	wind_influence = intensity

# Utility
func _apply_hair_sprite() -> void:
	# This will be called by parent to update sprite
	pass

func get_debug_info() -> String:
	return "Hair: %s, state=%s, frame=%d, animating=%s" % [
		hair_color,
		_current_hair_state,
		_current_frame,
		"yes" if _is_animating else "no"
	]
