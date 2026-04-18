# ════════════════════════════════════════════════════════
#  BOSS 4 — WYRM QUEEN  (scripts/bosses/WyrmQueen.gd)
# ════════════════════════════════════════════════════════
# Segmented worm boss. Head chases player underground.
# Body segments follow with a delay. Tail last.

class_name WyrmQueen
extends BossBase

const SEGMENT_COUNT = 18
const SEGMENT_GAP   = 22.0    # pixels between segment centres
const MOVE_SPEED    = 180.0
const PHASE2_SPEED  = 260.0
const BITE_RANGE    = 45.0
const SPIT_CD       = 2.5

var _segments: Array   = []   # positions, newest first
var _spit_cd:  float   = 0.0
var _chase_dir: Vector2 = Vector2.RIGHT

func _ready() -> void:
	boss_id          = "wyrm_queen"
	boss_title       = "Wyrm Queen Verath"
	max_hp           = 18000
	base_damage      = 65
	is_flying        = true    # doesn't use CharacterBody gravity
	knock_resist     = 0.98
	phase_thresholds = [0.5]
	super._ready()
	loot_table = [
		{id="scale",           count_min=8,  count_max=16, chance=1.0},
		{id="wyrm_scale_armor",count_min=1,  count_max=1,  chance=0.5},
		{id="venom_fang",      count_min=1,  count_max=3,  chance=0.8},
	]
	# Initialise segment history
	for i in SEGMENT_COUNT:
		_segments.append(global_position - Vector2(i * SEGMENT_GAP, 0))
	_spawn_body_segments()

func _process(delta: float) -> void:
	if not _is_alive or not _player: return
	_spit_cd -= delta
	_update_movement(delta)
	_update_segment_nodes()
	if _spit_cd <= 0.0 and current_phase >= 1:
		_spit_venom()
		_spit_cd = SPIT_CD * (0.65 if current_phase >= 2 else 1.0)

func _update_movement(delta: float) -> void:
	var target    = _player.global_position
	var desired   = (target - global_position).normalized()
	var spd       = PHASE2_SPEED if current_phase >= 2 else MOVE_SPEED
	_chase_dir    = _chase_dir.lerp(desired, 3.5 * delta).normalized()
	global_position += _chase_dir * spd * delta

	# Push new head position into segment history
	_segments.push_front(global_position)
	if _segments.size() > SEGMENT_COUNT + 1:
		_segments.pop_back()

func _spawn_body_segments() -> void:
	var seg_scene = load("res://scenes/bosses/WyrmSegment.tscn")
	if not seg_scene: return
	for i in range(1, SEGMENT_COUNT):
		var seg = seg_scene.instantiate()
		seg.name = "WyrmSeg%d" % i
		get_parent().add_child(seg)

func _update_segment_nodes() -> void:
	var children = get_parent().get_children()
	var seg_idx  = 0
	for child in children:
		if child.name.begins_with("WyrmSeg"):
			seg_idx += 1
			if seg_idx < _segments.size():
				child.global_position = _segments[seg_idx]
				# Face the direction they're moving
				if seg_idx + 1 < _segments.size():
					var dir = (_segments[seg_idx-1] - _segments[seg_idx]).normalized()
					child.rotation = dir.angle()

func _spit_venom() -> void:
	var target    = _player.global_position if _player else global_position
	var bolt_scn  = load("res://scenes/spells/generic_bolt.tscn")
	if not bolt_scn: return
	for spread in [-0.25, 0.0, 0.25]:
		var bolt  = bolt_scn.instantiate()
		bolt.global_position = global_position
		var dir   = (target - global_position).normalized().rotated(spread)
		bolt.setup(dir, 48, 210.0)
		bolt.modulate = Color(0.3, 0.95, 0.2)
		bolt.add_to_group("enemy_projectile")
		get_parent().add_child(bolt)

func _die() -> void:
	# Remove body segments
	for child in get_parent().get_children():
		if child.name.begins_with("WyrmSeg"):
			child.queue_free()
	super._die()
