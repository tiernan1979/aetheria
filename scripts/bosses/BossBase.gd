# ════════════════════════════════════════════════════════════════
#  BOSS BASE  (scripts/bosses/BossBase.gd)
# ════════════════════════════════════════════════════════════════
# All bosses extend this. Adds phase transitions, arena lock,
# death cutscene, loot shower, world notification.

class_name BossBase
extends EnemyBase

signal phase_changed(new_phase: int)
signal boss_died(boss_id: String, position: Vector2)

@export var boss_id:    String = "unknown_boss"
@export var boss_title: String = "???"
@export var phase_thresholds: Array = [0.5]   # HP fraction triggers (e.g. 0.5 = 50%)

var current_phase: int = 1
var _phase_idx:    int = 0

func _ready() -> void:
	var w3d = get_tree().get_first_node_in_group("world3d")
	if w3d: w3d.set_boss_arena_lighting(boss_id)
	super._ready()
	add_to_group("boss")
	# Show boss health bar via HUD
	_notify_hud_boss_start()

func _check_phase_transition() -> void:
	if _phase_idx >= phase_thresholds.size():
		return
	var threshold = phase_thresholds[_phase_idx]
	if float(hp) / float(max_hp) <= threshold:
		_phase_idx    += 1
		current_phase += 1
		emit_signal("phase_changed", current_phase)
		_on_phase_change(current_phase)

func _on_phase_change(phase: int) -> void:
	pass  # Override in subclasses

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	super.take_damage(amount, knockback_dir)
	_check_phase_transition()

func _die() -> void:
	var w3d = get_tree().get_first_node_in_group("world3d")
	if w3d: w3d.restore_normal_lighting()
	emit_signal("boss_died", boss_id, global_position)
	_notify_world_boss_died()
	super._die()

func _notify_hud_boss_start() -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_boss_bar"):
		hud.show_boss_bar(boss_title, max_hp)

func _notify_world_boss_died() -> void:
	var world = get_tree().get_first_node_in_group("world")
	if world and world.has_method("register_boss_defeat"):
		world.register_boss_defeat(boss_id)


# ════════════════════════════════════════════════════════════════
#  BOSS 1 — THE SLIME KING  (scripts/bosses/SlimeKing.gd)
# ════════════════════════════════════════════════════════════════
class SlimeKing extends BossBase:
	"""
	HP: 2500  |  2 phases
	Phase 1 (HP > 1000): Hops toward player, spawns mini slimes every 8s.
	Phase 2 (HP <= 1000): Speed +60%, spawns slime rain on jump.
	Drops: Slime Hook, Royal Gel
	"""
	const JUMP_CD     = 1.0
	const SLIME_CD    = 8.0
	const RAIN_CD     = 5.0   # phase 2 only

	var _jump_t:  float = 0.0
	var _slime_t: float = 0.0
	var _rain_t:  float = 0.0

	func _ready() -> void:
		boss_id           = "slime_king"
		boss_title        = "The Slime King"
		max_hp            = 2500
		base_damage       = 28
		move_speed        = 70.0
		phase_thresholds  = [0.40]
		knock_resist      = 0.8
		is_flying         = false
		super._ready()
		loot_table = [
			{id="gel",         count_min=15, count_max=30, chance=1.0},
			{id="slime_hook",  count_min=1,  count_max=1,  chance=1.0},
			{id="royal_gel",   count_min=1,  count_max=1,  chance=0.33},
		]

	func _physics_process(delta: float) -> void:
		super._physics_process(delta)
		if not _is_alive: return
		_jump_t  -= delta
		_slime_t -= delta
		_rain_t  -= delta
		if _slime_t <= 0.0: _spawn_mini_slimes(); _slime_t = SLIME_CD
		if current_phase >= 2 and _rain_t <= 0.0: _slime_rain(); _rain_t = RAIN_CD

	func _state_chase(delta: float) -> void:
		if not _player: _change_state(State.WANDER); return
		var diff  = _player.global_position - global_position
		_facing   = int(sign(diff.x)) if diff.x != 0 else _facing
		var spd_mult = 1.6 if current_phase >= 2 else 1.0
		if is_on_floor() and _jump_t <= 0.0:
			velocity.x = float(_facing) * move_speed * spd_mult * 2.5
			velocity.y = -620.0
			_jump_t    = JUMP_CD / spd_mult
			anim.play("jump")
		if diff.length() <= attack_range: _change_state(State.ATTACK)

	func _on_phase_change(_phase: int) -> void:
		# Visual flash
		sprite.modulate = Color(0.5, 1.0, 0.5)
		await get_tree().create_timer(0.3).timeout
		sprite.modulate = Color.WHITE
		_slime_t = 0.5   # immediate slime spawn on phase change

	func _spawn_mini_slimes() -> void:
		var mini = load("res://scenes/enemies/GreenSlime.tscn")
		if not mini: return
		for _i in 3:
			var s = mini.instantiate()
			s.global_position = global_position + Vector2(randf_range(-60,60),-20)
			get_parent().add_child(s)

	func _slime_rain() -> void:
		var player_x = _player.global_position.x if _player else global_position.x
		var mini = load("res://scenes/enemies/GreenSlime.tscn")
		if not mini: return
		for i in 8:
			var s = mini.instantiate()
			s.global_position = Vector2(player_x + (i-4)*48, global_position.y - 400)
			get_parent().add_child(s)


# ════════════════════════════════════════════════════════════════
#  BOSS 2 — EYE OF THE ABYSS  (scripts/bosses/EyeOfAbyss.gd)
# ════════════════════════════════════════════════════════════════
class EyeOfAbyss extends BossBase:
	"""
	HP: 5000  |  2 phases  |  Night summon only
	Phase 1 (HP > 2500): Orbits player slowly, fires tear projectiles every 1.5s.
	Phase 2 (HP <= 2500): Enrages — charges at 280 speed, 3-way spread tears.
	Drops: Bionic Lens, Abyss Shard
	"""
	const TEAR_CD_P1  = 1.5
	const TEAR_CD_P2  = 0.8
	const ORBIT_SPEED = 90.0
	const CHARGE_CD   = 2.2

	var _tear_t:   float = 0.0
	var _orbit_angle: float = 0.0
	var _charge_t: float = 0.0
	var _charging: bool  = false
	var _charge_dir: Vector2 = Vector2.ZERO

	func _ready() -> void:
		boss_id          = "eye_of_abyss"
		boss_title       = "Eye of the Abyss"
		max_hp           = 5000
		base_damage      = 35
		move_speed       = 130.0
		is_flying        = true
		knock_resist     = 0.9
		phase_thresholds = [0.5]
		super._ready()
		loot_table = [
			{id="lens",         count_min=3,  count_max=6,  chance=1.0},
			{id="bionic_lens",  count_min=1,  count_max=1,  chance=1.0},
			{id="abyss_shard",  count_min=1,  count_max=3,  chance=0.8},
		]

	func _physics_process(delta: float) -> void:
		super._physics_process(delta)
		if not _is_alive or not _player: return
		_tear_t   -= delta
		_charge_t -= delta
		var tear_cd = TEAR_CD_P2 if current_phase >= 2 else TEAR_CD_P1
		if _tear_t <= 0.0:
			_fire_tears()
			_tear_t = tear_cd

	func _state_chase(delta: float) -> void:
		if not _player: return
		if current_phase < 2:
			# Orbit
			_orbit_angle += delta * 0.9
			var orbit_r = 260.0
			var target = _player.global_position + Vector2(
				cos(_orbit_angle) * orbit_r,
				sin(_orbit_angle) * orbit_r * 0.6
			)
			velocity = (target - global_position).normalized() * ORBIT_SPEED
		else:
			# Charge
			if _charging:
				velocity = _charge_dir * 280.0
				if global_position.distance_to(_player.global_position) > 400 or _charge_t < 0:
					_charging = false
					_charge_t = CHARGE_CD
			elif _charge_t <= 0.0:
				_charge_dir = (_player.global_position - global_position).normalized()
				_charging   = true
			else:
				velocity = velocity.lerp(Vector2.ZERO, 4.0 * delta)

	func _fire_tears() -> void:
		if not _player: return
		var dir = (_player.global_position - global_position).normalized()
		_spawn_tear(dir)
		if current_phase >= 2:
			_spawn_tear(dir.rotated(0.35))
			_spawn_tear(dir.rotated(-0.35))

	func _spawn_tear(dir: Vector2) -> void:
		var bolt = load("res://scenes/spells/generic_bolt.tscn")
		if not bolt: return
		var b = bolt.instantiate()
		b.global_position = global_position
		b.setup(dir, 22, 320.0)
		b.add_to_group("enemy_projectile")
		get_parent().add_child(b)

	func _on_phase_change(_phase: int) -> void:
		# Violent red flash
		for _i in 4:
			sprite.modulate = Color(2.0, 0.2, 0.2)
			await get_tree().create_timer(0.08).timeout
			sprite.modulate = Color.WHITE
			await get_tree().create_timer(0.08).timeout
