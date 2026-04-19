# TreeSprite.gd — Visual-only tree (trunk tiles are ghost tiles in tilemap).
# FIX v2: Corrected anchor math so trees sit ON the ground, not floating.
# IMPROVED: Separate trunk sprite + layered canopy for visual depth.
# Trunk has no sway; lower canopy sways slowly; upper canopy sways more.
# This gives an organic "heavy base, light top" feel.

class_name TreeSprite
extends Node2D

var trunk_base_world: Vector2 = Vector2.ZERO

# Node refs created in setup()
var _trunk_spr:   Sprite2D
var _canopy_low:  Sprite2D   # bottom ~30% of canopy image, slow sway
var _canopy_hi:   Sprite2D   # top ~70% of canopy image, faster sway
var _time:        float = 0.0
var _wind_freq:   float = 1.0
var _wind_amp:    float = 1.2
var _shake_amt:   float = 0.0
var _tree_height: float = 0.0

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
	_tree_height = th

	# ── TRUNK ─────────────────────────────────────────────────────────────────
	# Bottom 40% of the sprite = trunk area (bark, roots).
	# Placed with centered=false so origin is at trunk base.
	_trunk_spr                  = Sprite2D.new()
	_trunk_spr.texture          = full_tex
	_trunk_spr.texture_filter   = CanvasItem.TEXTURE_FILTER_NEAREST
	_trunk_spr.centered         = false
	_trunk_spr.region_enabled   = true
	# Row 0.60..1.00 = bottom 40% = trunk
	var trunk_start_y   = th * 0.60
	var trunk_region_h  = th * 0.40
	_trunk_spr.region_rect      = Rect2(0.0, trunk_start_y, tw, trunk_region_h)
	# With centered=false the sprite top-left is at node origin.
	# We want the BOTTOM of the trunk to be at node origin (ground level).
	# So shift the sprite up by trunk_region_h and left by half-width:
	_trunk_spr.offset           = Vector2(-tw * 0.5, -trunk_region_h)
	_trunk_spr.z_index          = 0
	add_child(_trunk_spr)

	# ── LOWER CANOPY ──────────────────────────────────────────────────────────
	# Rows 0.30..0.60 = lower canopy. Slow gentle sway from trunk base.
	var canopy_low_start = th * 0.30
	var canopy_low_h     = th * 0.30

	_canopy_low                  = Sprite2D.new()
	_canopy_low.texture          = full_tex
	_canopy_low.texture_filter   = CanvasItem.TEXTURE_FILTER_NEAREST
	_canopy_low.centered         = false
	_canopy_low.region_enabled   = true
	_canopy_low.region_rect      = Rect2(0.0, canopy_low_start, tw, canopy_low_h)
	# Position: sits above the trunk, bottom aligned with trunk top
	# trunk top = -trunk_region_h from origin → canopy_low bottom there
	_canopy_low.offset           = Vector2(-tw * 0.5, -trunk_region_h - canopy_low_h)
	_canopy_low.z_index          = 1
	add_child(_canopy_low)

	# ── UPPER CANOPY ──────────────────────────────────────────────────────────
	# Rows 0.00..0.30 = upper canopy / crown. Fastest sway.
	var canopy_hi_h = th * 0.30

	_canopy_hi                  = Sprite2D.new()
	_canopy_hi.texture          = full_tex
	_canopy_hi.texture_filter   = CanvasItem.TEXTURE_FILTER_NEAREST
	_canopy_hi.centered         = false
	_canopy_hi.region_enabled   = true
	_canopy_hi.region_rect      = Rect2(0.0, 0.0, tw, canopy_hi_h)
	# Sits above lower canopy
	_canopy_hi.offset           = Vector2(-tw * 0.5, -trunk_region_h - canopy_low_h - canopy_hi_h)
	_canopy_hi.z_index          = 2
	add_child(_canopy_hi)

	# ── POSITION ──────────────────────────────────────────────────────────────
	# tile_top_pos is the world-space position of the TOP of the grass tile (ground surface).
	# Node origin = ground level (where tree base meets earth).
	global_position = tile_top_pos
	z_index         = 0

	# Randomise wind per-tree so a forest doesn't look like a single animation
	_wind_freq = 0.45 + randf() * 0.5
	_wind_amp  = 0.7  + randf() * 0.8
	_time      = randf() * TAU

func _process(delta: float) -> void:
	if not _canopy_low or not _canopy_hi: return
	_time += delta

	var shake_bias: float = 0.0
	if _shake_amt > 0.0:
		shake_bias   = sin(_time * 10.0) * _shake_amt * 5.0
		_shake_amt   = max(0.0, _shake_amt - delta * 3.0)

	# Primary + harmonic for organic movement
	var primary   = sin(_time * _wind_freq)                          * _wind_amp
	var harmonic2 = sin(_time * _wind_freq * 2.4 + 1.1)             * _wind_amp * 0.22
	var harmonic3 = sin(_time * _wind_freq * 4.8 + 0.4)             * _wind_amp * 0.08

	var sway_base = primary + harmonic2 + harmonic3 + shake_bias

	# Lower canopy: 60% of base sway — anchored low, moves a little
	var target_low = sway_base * 0.60
	_canopy_low.rotation_degrees = lerp(_canopy_low.rotation_degrees, target_low, 10.0 * delta)

	# Upper canopy: 100% + extra for treetop bounce
	var top_bounce = sin(_time * _wind_freq * 3.0 + 0.8) * _wind_amp * 0.15
	var target_hi  = sway_base + top_bounce
	_canopy_hi.rotation_degrees  = lerp(_canopy_hi.rotation_degrees, target_hi, 14.0 * delta)

	# Trunk: slight lean only during heavy shake
	if _trunk_spr:
		_trunk_spr.rotation_degrees = lerp(_trunk_spr.rotation_degrees, shake_bias * 0.1, 6.0 * delta)

func shake(amount: float = 2.5) -> void:
	_shake_amt = amount