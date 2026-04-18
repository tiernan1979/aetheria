# TileBreakFX.gd
# Spawns animated debris particles when a block is broken.
# Attach to $Particles node in World scene.

class_name TileBreakFX
extends Node2D

# Colour palette per tile ID
const TILE_DUST = {
	-1:  Color(0.05, 0.04, 0.09),
	0:   Color(0.55, 0.32, 0.12),   # dirt
	1:   Color(0.32, 0.68, 0.22),   # grass
	2:   Color(0.42, 0.40, 0.52),   # stone
	3:   Color(0.78, 0.68, 0.38),   # sand
	5:   Color(0.68, 0.85, 0.98),   # ice
	6:   Color(0.92, 0.94, 1.00),   # snow
	8:   Color(0.22, 0.06, 0.32),   # obsidian
	9:   Color(0.55, 0.32, 0.12),   # wood
	14:  Color(0.32, 0.72, 0.18),   # leaves
}

func burst(world_pos: Vector2, tile_id: int, count: int = 8) -> void:
	var base_col = TILE_DUST.get(tile_id, Color(0.5, 0.5, 0.5))
	for i in count:
		var chip = ColorRect.new()
		var sz = randf_range(2, 5)
		chip.size = Vector2(sz, sz)
		# Slight colour variation per chip
		var tint = randf_range(-0.12, 0.12)
		chip.color = base_col.lightened(tint)
		chip.global_position = world_pos + Vector2(randf_range(-6, 6), randf_range(-6, 6))
		add_child(chip)

		var angle = randf() * TAU
		var speed = randf_range(30, 95)
		var vx    = cos(angle) * speed
		var vy    = sin(angle) * speed - randf_range(15, 40)  # bias upward

		var tw = chip.create_tween()
		tw.tween_property(chip, "position",
			chip.position + Vector2(vx, vy) * 0.55, randf_range(0.28, 0.55))
		tw.parallel().tween_property(chip, "modulate:a", 0.0, randf_range(0.25, 0.5))
		tw.tween_callback(chip.queue_free)

func hit_spark(world_pos: Vector2, tile_id: int) -> void:
	# Smaller burst for "hit but not broken" feedback
	burst(world_pos, tile_id, 3)
