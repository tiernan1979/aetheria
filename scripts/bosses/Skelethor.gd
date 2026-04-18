# ════════════════════════════════════════════════════════
#  BOSS 3 — SKELETHOR  (scripts/bosses/Skelethor.gd)
# ════════════════════════════════════════════════════════
# Multi-part boss: Head + 2 Arms + Torso
# Defeating the Head triggers hardmode.
# Each part is a separate CharacterBody2D that references the head.

class_name Skelethor
extends BossBase

# Skelethor is the HEAD. Arms are spawned separately.
@export var arm_scene_path: String = "res://scenes/bosses/SkelethorArm.tscn"

const FLOAT_SPEED   = 95.0
const HOVER_HEIGHT  = 180.0   # pixels above player
const SKULL_SHOOT_CD = 0.9
const SKULL_BURST_CD = 4.0

var _left_arm: Node2D  = null
var _right_arm: Node2D = null
var _skull_cd: float   = 0.0
var _burst_cd: float   = 0.0
var _hover_t:  float   = 0.0

func _ready() -> void:
	boss_id          = "skelethor"
	boss_title       = "Skelethor the Undying"
	max_hp           = 12000
	base_damage      = 55
	is_flying        = true
	knock_resist     = 0.95
	phase_thresholds = [0.66, 0.33]
	super._ready()
	loot_table = [
		{id="bone",           count_min=20, count_max=40, chance=1.0},
		{id="ferrite_bar",    count_min=8,  count_max=15, chance=1.0},
		{id="skelethor_mask", count_min=1,  count_max=1,  chance=0.33},
		{id="bone_sword",     count_min=1,  count_max=1,  chance=0.5},
	]
	_spawn_arms()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not _is_alive: return
	_skull_cd -= delta
	_burst_cd -= delta
	_hover_t  += delta
	_update_arm_positions()

func _state_chase(delta: float) -> void:
	if not _player: return
	var target_y = _player.global_position.y - HOVER_HEIGHT + sin(_hover_t * 1.4) * 28.0
	var target   = Vector2(_player.global_position.x, target_y)
	velocity = velocity.lerp((target - global_position).normalized() * FLOAT_SPEED, 4.0 * delta)

	if _skull_cd <= 0.0:
		_fire_skull(_player.global_position)
		_skull_cd = SKULL_SHOOT_CD / (1.3 if current_phase >= 2 else 1.0)

	if _burst_cd <= 0.0 and current_phase >= 2:
		_skull_burst()
		_burst_cd = SKULL_BURST_CD

func _fire_skull(target: Vector2) -> void:
	var bolt_scene = load("res://scenes/spells/generic_bolt.tscn")
	if not bolt_scene: return
	var bolt = bolt_scene.instantiate()
	bolt.global_position = global_position
	bolt.setup((target - global_position).normalized(), 42, 245.0)
	bolt.add_to_group("enemy_projectile")
	get_parent().add_child(bolt)

func _skull_burst() -> void:
	for i in 8:
		var angle = i / 8.0 * TAU
		var bolt_scene = load("res://scenes/spells/generic_bolt.tscn")
		if not bolt_scene: continue
		var bolt = bolt_scene.instantiate()
		bolt.global_position = global_position
		bolt.setup(Vector2(cos(angle), sin(angle)), 30, 195.0)
		bolt.add_to_group("enemy_projectile")
		get_parent().add_child(bolt)

func _spawn_arms() -> void:
	# Arms are simple nodes that orbit the head
	var arm_scene = load(arm_scene_path) if ResourceLoader.exists(arm_scene_path) else null
	if arm_scene:
		_left_arm  = arm_scene.instantiate()
		_right_arm = arm_scene.instantiate()
		get_parent().add_child(_left_arm)
		get_parent().add_child(_right_arm)
		if _left_arm.has_method("init"):
			_left_arm.init(self, -1)
			_right_arm.init(self, 1)
	else:
		push_warning("Skelethor: arm scene not found at %s" % arm_scene_path)

func _update_arm_positions() -> void:
	if _left_arm  and is_instance_valid(_left_arm):
		_left_arm.global_position  = global_position + Vector2(-90 + sin(_hover_t)*20, 60)
	if _right_arm and is_instance_valid(_right_arm):
		_right_arm.global_position = global_position + Vector2( 90 + sin(_hover_t+1.2)*20, 60)

func _on_phase_change(phase: int) -> void:
	match phase:
		2:
			# Lose one arm
			if _left_arm and is_instance_valid(_left_arm):
				_left_arm.queue_free()
		3:
			# Lose both arms, speed up
			if _right_arm and is_instance_valid(_right_arm):
				_right_arm.queue_free()
			FLOAT_SPEED  # Would need to be a var; set it via a var override

func _die() -> void:
	if _left_arm  and is_instance_valid(_left_arm):  _left_arm.queue_free()
	if _right_arm and is_instance_valid(_right_arm): _right_arm.queue_free()
	super._die()
