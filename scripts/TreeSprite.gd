# TreeSprite.gd — Visual-only tree (ghost trunk tiles are invisible in tilemap).
# World._on_tree_planted() instantiates this as Node2D and calls setup().
class_name TreeSprite
extends Node2D

var trunk_base_world: Vector2 = Vector2.ZERO

var _trunk_spr:  Sprite2D
var _canopy_spr: Sprite2D
var _time:       float = 0.0
var _wind_freq:  float = 1.0
var _wind_amp:   float = 1.2
var _shake_amt:  float = 0.0

func setup(tile_top_pos: Vector2, variant: String) -> void:
	trunk_base_world = tile_top_pos

	var tex_path = "res://assets/sprites/trees/%s.png" % variant
	if not ResourceLoader.exists(tex_path):
		push_warning("TreeSprite: texture not found: " + tex_path)
		return
	var full_tex = load(tex_path)
	if not full_tex: return

	var tw = float(full_tex.get_width())
	var th = float(full_tex.get_height())

	# Trunk: bottom 42% of image, no sway
	_trunk_spr = Sprite2D.new()
	_trunk_spr.texture         = full_tex
	_trunk_spr.texture_filter  = CanvasItem.TEXTURE_FILTER_NEAREST
	_trunk_spr.centered        = false
	_trunk_spr.region_enabled  = true
	_trunk_spr.region_rect     = Rect2(0.0, th * 0.58, tw, th * 0.42)
	_trunk_spr.position        = Vector2(-tw * 0.5, -th * 0.42)
	add_child(_trunk_spr)

	# Canopy: top 58% of image, gently swaying
	_canopy_spr = Sprite2D.new()
	_canopy_spr.texture         = full_tex
	_canopy_spr.texture_filter  = CanvasItem.TEXTURE_FILTER_NEAREST
	_canopy_spr.centered        = false
	_canopy_spr.region_enabled  = true
	_canopy_spr.region_rect     = Rect2(0.0, 0.0, tw, th * 0.58)
	_canopy_spr.position        = Vector2(-tw * 0.5, -th)
	add_child(_canopy_spr)

	# Place node so its local origin is at tile_top_pos (ground surface)
	global_position = tile_top_pos
	z_index         = 0   # same layer as ground; player z_index should be 1+

	_wind_freq = 0.5 + randf() * 0.6
	_wind_amp  = 0.8 + randf() * 0.7
	_time      = randf() * TAU

func _process(delta: float) -> void:
	if not _canopy_spr: return
	_time += delta
	var sway  = sin(_time * _wind_freq)                  * _wind_amp
	sway     += sin(_time * _wind_freq * 2.1 + 1.2)     * _wind_amp * 0.28
	sway     += sin(_time * _wind_freq * 3.7 + 0.5)     * _wind_amp * 0.10
	if _shake_amt > 0.0:
		sway       += sin(_time * 9.0) * _shake_amt * 3.0
		_shake_amt  = max(0.0, _shake_amt - delta * 2.8)
	_canopy_spr.rotation_degrees = lerp(_canopy_spr.rotation_degrees, sway, 14.0 * delta)

func shake(amount: float = 2.5) -> void:
	_shake_amt = amount
