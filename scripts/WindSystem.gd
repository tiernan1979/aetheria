# WindSystem.gd
# Global wind system that affects character hair and environment
# Provides wind direction, strength, and turbulence for realistic hair flow

extends Node

# Wind configuration
@export var base_wind_direction: Vector2 = Vector2(1.0, 0.0)  # Direction wind blows
@export var base_wind_strength: float = 1.0  # Base wind strength (0.0 - 3.0)
@export var wind_turbulence: float = 0.3  # How much wind fluctuates
@export var wind_change_interval: float = 2.0  # How often wind changes

# Runtime wind state
var current_wind_direction: Vector2 = Vector2(1.0, 0.0)
var current_wind_strength: float = 1.0
var wind_phase: float = 0.0
var _timer: float = 0.0

# Wind zones for area-specific effects
var _wind_zones: Array[Dictionary] = []

# Signal for wind changes
signal wind_changed(direction: Vector2, strength: float)

func _ready() -> void:
	randomize()
	_reset_wind()

func _process(delta: float) -> void:
	_timer += delta

	# Update wind periodically
	if _timer >= wind_change_interval:
		_timer = 0.0
		_update_wind_turbulence()

	# Apply continuous turbulence
	wind_phase += delta * 2.0
	var turbulence = sin(wind_phase) * wind_turbulence + cos(wind_phase * 0.7) * wind_turbulence * 0.5

	# Calculate current wind with turbulence
	current_wind_strength = base_wind_strength + turbulence
	current_wind_strength = clamp(current_wind_strength, 0.0, 3.0)

func _update_wind_turbulence() -> void:
	"""Randomize wind slightly at intervals"""
	# Slight direction change
	var angle_offset = randf_range(-0.3, 0.3)
	var current_angle = base_wind_direction.angle()
	var new_angle = current_angle + angle_offset
	current_wind_direction = Vector2.from_angle(new_angle).normalized()

	# Strength variation
	base_wind_strength = randf_range(0.5, 2.0)

	emit_signal("wind_changed", current_wind_direction, current_wind_strength)

func get_wind_at_position(position: Vector2) -> Dictionary:
	"""Get wind parameters at a specific world position"""
	var wind_dir = current_wind_direction
	var wind_str = current_wind_strength

	# Check wind zones
	for zone in _wind_zones:
		if _is_position_in_zone(position, zone):
			wind_dir = zone.get("direction", wind_dir)
			wind_str = zone.get("strength", wind_str)
			break

	# Apply speed-based wind when player is moving fast
	return {
		"direction": wind_dir,
		"strength": wind_str,
		"gust": sin(wind_phase * 3.0) * 0.5 + 0.5,  # 0-1 gust value
	}

func _is_position_in_zone(position: Vector2, zone: Dictionary) -> bool:
	"""Check if position is inside a wind zone"""
	var center = zone.get("center", Vector2.ZERO)
	var radius = zone.get("radius", 100.0)
	return position.distance_to(center) <= radius

func add_wind_zone(center: Vector2, radius: float, direction: Vector2, strength: float) -> void:
	"""Add a localized wind zone (e.g., windy areas, fans)"""
	_wind_zones.append({
		"center": center,
		"radius": radius,
		"direction": direction.normalized(),
		"strength": strength
	})

func remove_wind_zones() -> void:
	"""Clear all wind zones"""
	_wind_zones.clear()

func set_base_wind(direction: Vector2, strength: float) -> void:
	"""Set global wind parameters"""
	base_wind_direction = direction.normalized()
	base_wind_strength = clamp(strength, 0.0, 3.0)

func apply_player_speed_wind(player_velocity: Vector2, player_speed: float) -> Vector2:
	"""Calculate additional wind from player movement"""
	# Moving creates a "headwind" opposite to movement
	# Faster movement = stronger perceived wind
	var speed_factor = min(player_speed / 500.0, 1.0)
	var headwind = -player_velocity.normalized() * speed_factor * 2.0

	return current_wind_direction * current_wind_strength + headwind

func get_wind_angle() -> float:
	"""Get current wind direction as angle in degrees"""
	return current_wind_direction.angle() * RAD_TO_DEG

# Debug info
func get_debug_info() -> String:
	return "Wind: dir=%.1f, str=%.2f, phase=%.2f" % [
		get_wind_angle(),
		current_wind_strength,
		wind_phase
	]
