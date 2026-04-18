class_name EnemyBase
# EnemyBase.gd
# Base class for all enemies.  Extend this for each enemy type.
#
# Node tree:
#   Enemy (CharacterBody2D)
#   ├── Sprite2D / AnimatedSprite2D
#   ├── AnimationPlayer
#   ├── CollisionShape2D
#   ├── DetectArea (Area2D)   ← aggro range
#   ├── AttackArea (Area2D)   ← melee hit range
#   ├── HurtBox  (Area2D)     ← receives player projectiles
#   ├── HealthBar (ProgressBar or Node2D/Label)
#   └── NavigationAgent2D     ← for path-finding (optional)

extends CharacterBody2D

signal died(position: Vector2, loot: Array)

# ── STATS (override in subclasses or Inspector) ───────────────
@export var enemy_name:      String  = "Enemy"
@export var max_hp:          int     = 50
@export var base_damage:     int     = 10
@export var move_speed:      float   = 80.0
@export var aggro_range:     float   = 400.0
@export var attack_range:    float   = 40.0
@export var attack_cooldown: float   = 1.4
@export var knock_resist:    float   = 0.0    # 0=full knockback, 1=immune
@export var is_flying:       bool    = false
@export var xp_reward:       int     = 5
@export var coin_reward:     int     = 2

# Loot table: [{id, count_min, count_max, chance}]
@export var loot_table: Array = []

# ── STATE MACHINE ─────────────────────────────────────────────
enum State { IDLE, WANDER, CHASE, ATTACK, HURT, DEAD }
var state: int = State.IDLE

# ── RUNTIME ───────────────────────────────────────────────────
var hp:           int
var _attack_cd:   float = 0.0
var _state_timer: float = 0.0
var _player:      CharacterBody2D = null
var _facing:      int  = 1
var _knockback:   Vector2 = Vector2.ZERO
var _is_alive:    bool = true

const GRAVITY = 1200.0

@onready var sprite:     Node2D      = $Sprite2D
@onready var anim:       AnimationPlayer = $AnimationPlayer
@onready var detect:     Area2D      = $DetectArea
@onready var attack_area:Area2D      = $AttackArea
@onready var hurt_box:   Area2D      = $HurtBox
@onready var hp_bar:     Node        = $HealthBar

# Safe animation play — never crashes if a clip is missing.
func _safe_play(clip: String) -> void:
	if not anim: return
	if anim.has_animation(clip):
		if anim.current_animation != clip:
			anim.play(clip)
	else:
		# Fallback order: try "idle", then play nothing
		if anim.has_animation("idle") and anim.current_animation != "idle":
			anim.play("idle")


func _ready() -> void:
	hp = max_hp
	add_to_group("enemy")
	detect.body_entered.connect(_on_detect_body_entered)
	detect.body_exited.connect(_on_detect_body_exited)
	hurt_box.area_entered.connect(_on_hurt_box_area_entered)
	_update_hp_bar()
	_init_loot_table()
	# Build animations at runtime so anim.play() never fails on a missing clip.
	# Subclasses may override _setup_animations() to customise frame counts.
	_setup_animations()

# Override in subclasses for non-standard spritesheets.
func _setup_animations() -> void:
	if anim and sprite:
		# Scale sprite up for visibility
		sprite.scale = Vector2(1.0, 1.0)  # scale per enemy type
		AnimationHelper.setup_enemy_simple(anim, sprite,
			_idle_frames, _walk_frames, _attack_frames, _die_frames)

# Subclasses can set these before super._ready() to change frame counts.
var _idle_frames:   int = 2
var _walk_frames:   int = 2
var _attack_frames: int = 2
var _die_frames:    int = 3

# Override in subclasses to add custom loot
func _init_loot_table() -> void:
	pass

func _physics_process(delta: float) -> void:
	if not _is_alive:
		return

	_attack_cd  = max(0.0, _attack_cd - delta)
	_state_timer += delta

	if not is_flying:
		velocity.y += GRAVITY * delta
		velocity.y  = min(velocity.y, 1400.0)

	# Apply knockback decay
	velocity.x += _knockback.x
	velocity.y += _knockback.y
	_knockback  = _knockback.lerp(Vector2.ZERO, 0.3)

	match state:
		State.IDLE:    _state_idle(delta)
		State.WANDER:  _state_wander(delta)
		State.CHASE:   _state_chase(delta)
		State.ATTACK:  _state_attack(delta)
		State.HURT:    _state_hurt(delta)
		State.DEAD:    pass

	move_and_slide()
	sprite.flip_h = (_facing < 0)

# ── STATES ────────────────────────────────────────────────────
func _state_idle(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0.0, 8.0 * delta)
	_safe_play("idle")
	if _state_timer > randf_range(1.5, 4.0):
		_change_state(State.WANDER)
	if _player:
		_change_state(State.CHASE)

func _state_wander(delta: float) -> void:
	var dir = float(_facing)
	velocity.x = lerp(velocity.x, dir * move_speed * 0.4, 6.0 * delta)
	_safe_play("walk")
	# Turn around at walls
	if is_on_wall():
		_facing *= -1
	if _state_timer > randf_range(2.0, 5.0):
		_facing = [-1, 1][randi() % 2]
		_change_state(State.IDLE)
	if _player:
		_change_state(State.CHASE)

func _state_chase(delta: float) -> void:
	if not _player:
		_change_state(State.WANDER)
		return
	var diff = _player.global_position - global_position
	_facing  = int(sign(diff.x)) if diff.x != 0 else _facing
	_safe_play("walk")

	var dist = diff.length()
	if dist <= attack_range:
		_change_state(State.ATTACK)
		return

	if not is_flying:
		velocity.x = lerp(velocity.x, float(_facing) * move_speed, 8.0 * delta)
		# Jump over obstacles
		if is_on_wall() and is_on_floor():
			velocity.y = -500.0
	else:
		var fly_dir = diff.normalized()
		velocity    = velocity.lerp(fly_dir * move_speed, 4.0 * delta)

	if dist > aggro_range * 1.5:
		_player = null
		_change_state(State.WANDER)

func _state_attack(_delta: float) -> void:
	velocity.x = lerp(velocity.x, 0.0, 12.0 * _delta)
	if _attack_cd <= 0.0:
		_do_attack()
		_attack_cd = attack_cooldown
	if not _player or _player.global_position.distance_to(global_position) > attack_range * 1.5:
		_change_state(State.CHASE)

func _state_hurt(_delta: float) -> void:
	if _state_timer > 0.25:
		_change_state(State.CHASE if _player else State.WANDER)

# ── ATTACK ────────────────────────────────────────────────────
func _do_attack() -> void:
	_safe_play("attack")
	if _player and _player.global_position.distance_to(global_position) <= attack_range:
		var knock_dir = (_player.global_position - global_position).normalized()
		_player.take_damage(base_damage, knock_dir)

# ── DAMAGE RECEPTION ─────────────────────────────────────────
func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	var dmg_node = get_tree().get_first_node_in_group("damage_numbers")
	if dmg_node: dmg_node.damage(global_position, amount)
	if has_node("/root/AudioManager"): AudioManager.play("enemy_hit", 0.15)
	if not _is_alive:
		return
	hp -= max(1, amount)
	_update_hp_bar()
	_show_damage_number(amount)
	if knockback_dir != Vector2.ZERO:
		_knockback = knockback_dir * 280.0 * (1.0 - knock_resist)
	_change_state(State.HURT)
	# Flash red
	sprite.modulate = Color(1.8, 0.3, 0.3)
	await get_tree().create_timer(0.12).timeout
	if _is_alive:
		sprite.modulate = Color.WHITE
	if hp <= 0:
		_die()

func _die() -> void:
	_is_alive = false
	_change_state(State.DEAD)
	_safe_play("die")
	var loot = _roll_loot()
	emit_signal("died", global_position, loot)
	# Spawn physical loot drops in the world
	var loot_parent = get_tree().get_first_node_in_group("loot_drops")
	if not loot_parent: loot_parent = get_parent()
	var drop_script = load("res://scripts/LootDrop.gd")
	if drop_script:
		for drop_data in loot:
			var drop = RigidBody2D.new()
			drop.set_script(drop_script)
			drop.global_position = global_position + Vector2(randf_range(-14,14), -6)
			loot_parent.add_child(drop)
			if drop.has_method("setup"):
				drop.setup(drop_data.id, drop_data.count)
	await get_tree().create_timer(0.6).timeout
	queue_free()

func _roll_loot() -> Array:
	var drops = []
	for entry in loot_table:
		if randf() < entry.get("chance", 0.5):
			var count = randi_range(
				entry.get("count_min", 1),
				entry.get("count_max", 1)
			)
			drops.append({id=entry.id, count=count})
	return drops

# ── DETECTION ────────────────────────────────────────────────
func _on_detect_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player = body
		if state == State.IDLE or state == State.WANDER:
			_change_state(State.CHASE)

func _on_detect_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null

func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area.has_method("get_damage"):
		var dmg      = area.get_damage()
		var dir      = (global_position - area.global_position).normalized()
		take_damage(dmg, dir)

# ── HELPERS ──────────────────────────────────────────────────
func _change_state(new_state: int) -> void:
	state        = new_state
	_state_timer = 0.0

func _update_hp_bar() -> void:
	if hp_bar and hp_bar.has_method("set_value"):
		hp_bar.max_value = max_hp
		hp_bar.value     = hp

func _show_damage_number(amount: int) -> void:
	# Instantiate a floating damage label
	var lbl = Label.new()
	lbl.text = "-%d" % amount
	lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	lbl.position = Vector2(-10, -40)
	add_child(lbl)
	var tween = create_tween()
	tween.tween_property(lbl, "position:y", lbl.position.y - 30, 0.6)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 0.6)
	tween.tween_callback(lbl.queue_free)
