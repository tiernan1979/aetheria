# HeldItem.gd — Tool held in player's hand
#
# COORDINATE SYSTEM:
#   Sprite drawn: BLADE at top, HANDLE at bottom.
#   centered=false + offset=(-tw/2, -th) → handle bottom-centre at node (0,0).
#   Rotation is around (0,0) = around the handle grip.
#
#   Godot 2D: Y points DOWN, positive rotation = CLOCKWISE on screen.
#   0°   = blade points UP   (negative Y)
#   90°  = blade points RIGHT (clockwise)
#   180° = blade points DOWN
#   -90° = blade points LEFT
#
# FACING RIGHT — downward swing:
#   Idle start:  blade upper-right  ≈  45° (tool held ready, angled forward)
#   Swing raise: blade upper-left   ≈ -45° (arm pulled back)
#   Swing strike: blade lower-right ≈ 150° (sweeps clockwise = DOWN = correct)
#
# FACING LEFT — mirror (negate angle, flip_h):
#   Idle:  -45° (blade upper-left)
#   Raise: +45° (blade upper-right)
#   Strike: -150° (sweeps counter-clockwise = DOWN-LEFT = correct)

class_name HeldItemSprite
extends Sprite2D

var _player: Node2D = null

func _ready() -> void:
	_player = get_parent()

func _process(delta: float) -> void:
	if not _player: return

	var item = _player._active_item() if _player.has_method("_active_item") else null
	if not item or item.category == ItemDB.Category.CONSUMABLE:
		visible = false; return

	var tex_path = "res://assets/sprites/%s.png" % item.sprite
	if not ResourceLoader.exists(tex_path):
		visible = false; return
	var t = load(tex_path)
	if t != texture:
		texture = t
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visible = true

	# ── FACING ───────────────────────────────────────────────────
	# Use _facing directly (±1 int on Player) — most reliable
	var facing_right: bool
	if "_facing" in _player:
		facing_right = (_player._facing > 0)
	else:
		facing_right = not _player.sprite.flip_h

	# ── PIVOT AT HANDLE ───────────────────────────────────────────
	# offset is in RAW texture pixels (before scale).
	# Setting it to (-tw/2, -th) puts sprite bottom-centre at (0,0).
	centered = false
	scale    = Vector2(0.45, 0.45)
	var tw   = float(texture.get_width())
	var th   = float(texture.get_height())
	offset   = Vector2(-tw * 0.5, -th)

	# ── HAND POSITION ─────────────────────────────────────────────
	# Place the handle (node origin) at the player's extended hand.
	# x: forward from player centre; y: arm/shoulder height
	var hand_x = 11.0 if facing_right else -11.0
	position   = Vector2(hand_x, -8.0)

	# ── SWING PROGRESS ────────────────────────────────────────────
	var is_swing  = _player._is_swinging if "_is_swinging" in _player else false
	var is_mining = "_mine_tile_pos" in _player and \
	                _player._mine_tile_pos != Vector2i(-9999, -9999)

	# sw_t: 0 = swing just started (raised), 1 = swing complete (struck)
	var sw_t: float = 0.0
	if is_swing and "_swing_timer" in _player:
		var spd = 1.0
		if "speed" in item: spd = item.speed
		var total = 1.0 / spd
		sw_t = clamp(1.0 - _player._swing_timer / total, 0.0, 1.0)

	# ── BASE ROTATION (for facing RIGHT) ─────────────────────────
	# All angles defined for facing RIGHT. Facing left negates them.
	var base_rot: float
	var type_key = _get_type_key(item)

	if is_swing:
		# Raised (-45°, blade upper-left) → strike (150°, blade lower-right)
		# This is a CLOCKWISE sweep = downward arc ✓
		base_rot = lerp(-45.0, 150.0, sw_t)

	elif is_mining:
		# Chop rhythm: up (-60°) ↔ strike (100°), continuous
		var mt   = fmod(Time.get_ticks_msec() / 250.0, 1.0)
		# Use smoothstep-like curve: ease in to strike, snap back
		var chop = sin(mt * PI)          # 0→1→0 half-sine
		base_rot = lerp(-60.0, 100.0, chop)

	else:
		# Idle hold — blade angled forward-down like Terraria
		match type_key:
			"sword":          base_rot = 45.0
			"pickaxe", "axe": base_rot = 50.0
			"bow":            base_rot = 20.0
			_:                base_rot = 45.0

	# ── APPLY DIRECTION ───────────────────────────────────────────
	# Facing left: negate angle (mirror swing arc) + flip sprite horizontally
	var final_rot = base_rot if facing_right else -base_rot
	# Fast snap so it never shows the intermediate "wrong direction" frames
	rotation_degrees = lerp(rotation_degrees, final_rot, 30.0 * delta)
	flip_h = not facing_right

func _get_type_key(item) -> String:
	match item.tool_type:
		ItemDB.ToolType.PICKAXE: return "pickaxe"
		ItemDB.ToolType.AXE:     return "axe"
		ItemDB.ToolType.SWORD:   return "sword"
		ItemDB.ToolType.BOW:     return "bow"
		_:                       return "default"
