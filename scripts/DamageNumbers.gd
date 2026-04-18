# DamageNumbers.gd
# Attach to $DamageNumbers (Node2D) in World.tscn
# Call via:  DamageNumbers.spawn(world_pos, amount, type)

class_name DamageNumbers
extends Node2D

enum Type { DAMAGE, CRIT, HEAL, MANA, MISS, BLOCK, XP }

const COLORS = {
	Type.DAMAGE: Color(1.00, 0.88, 0.20),  # golden yellow
	Type.CRIT:   Color(1.00, 0.30, 0.20),  # fiery red
	Type.HEAL:   Color(0.30, 1.00, 0.45),  # bright green
	Type.MANA:   Color(0.40, 0.60, 1.00),  # blue
	Type.MISS:   Color(0.75, 0.75, 0.75),  # grey
	Type.BLOCK:  Color(0.60, 0.80, 1.00),  # light blue
	Type.XP:     Color(0.90, 0.80, 1.00),  # pale purple
}
const SIZES = {
	Type.DAMAGE: 16,
	Type.CRIT:   24,
	Type.HEAL:   15,
	Type.MANA:   13,
	Type.MISS:   12,
	Type.BLOCK:  12,
	Type.XP:     11,
}

func spawn(world_pos: Vector2, amount: int, type: Type = Type.DAMAGE) -> void:
	var lbl = Label.new()
	lbl.add_theme_color_override("font_color", COLORS[type])
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	lbl.add_theme_font_size_override("font_size", SIZES[type])

	match type:
		Type.MISS:   lbl.text = "MISS"
		Type.BLOCK:  lbl.text = "BLOCK"
		Type.CRIT:   lbl.text = "✦ %d!" % amount
		Type.HEAL:   lbl.text = "+%d" % amount
		Type.MANA:   lbl.text = "+%d ✦" % amount
		Type.XP:     lbl.text = "+%d XP" % amount
		_:           lbl.text = str(amount)

	# Scale on crits
	if type == Type.CRIT:
		lbl.scale = Vector2(1.4, 1.4)

	lbl.position = world_pos + Vector2(randf_range(-12, 12), -20)
	lbl.z_index  = 100
	add_child(lbl)

	# Arc upward then fade
	var rise   = randf_range(35, 65)
	var drift  = randf_range(-18, 18)
	var tw     = lbl.create_tween()

	if type == Type.CRIT:
		# Pop scale up then down
		tw.tween_property(lbl, "scale", Vector2(1.6, 1.6), 0.08).set_ease(Tween.EASE_OUT)
		tw.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.10).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(lbl, "position",
			lbl.position + Vector2(drift, -rise * 1.3), 0.55).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.55).set_delay(0.3)
	else:
		tw.tween_property(lbl, "position",
			lbl.position + Vector2(drift, -rise), 0.45).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.45).set_delay(0.2)

	tw.tween_callback(lbl.queue_free)

# Convenience static-style access (works if added to World scene)
func damage(pos: Vector2, amt: int)  -> void: spawn(pos, amt, Type.DAMAGE)
func crit(pos: Vector2, amt: int)    -> void: spawn(pos, amt, Type.CRIT)
func heal(pos: Vector2, amt: int)    -> void: spawn(pos, amt, Type.HEAL)
func miss(pos: Vector2)              -> void: spawn(pos, 0,   Type.MISS)
func xp(pos: Vector2, amt: int)      -> void: spawn(pos, amt, Type.XP)
