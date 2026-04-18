# Projectile.gd  — base class for all fired projectiles (arrows, bolts, spells)
# Node tree:
#   Projectile (Area2D) — collision_mask=4 (enemies) | 2 (world)
#   ├── Sprite2D / Line2D (visual)
#   ├── CollisionShape2D (CircleShape2D r=4)
#   └── GlowLight (PointLight2D) — optional, for magic bolts

class_name Projectile
extends Area2D

signal hit_enemy(enemy: Node2D, damage: int)
signal hit_world(tile_pos: Vector2i)

@export var speed:      float = 400.0
@export var damage:     int   = 15
@export var lifetime:   float = 2.5
@export var pierce:     int   = 0        # 0=stops on first hit, N=passes through N enemies
@export var aoe_radius: float = 0.0      # explosion radius on impact
@export var glow_color: Color = Color.WHITE

var _dir:       Vector2 = Vector2.RIGHT
var _age:       float   = 0.0
var _hits:      int     = 0
var _world_ref          = null

@onready var sprite: Node2D = $Sprite2D
@onready var light: PointLight2D = $GlowLight if has_node("GlowLight") else null

func setup(direction: Vector2, dmg: int, spd: float = 0.0) -> void:
	_dir   = direction.normalized()
	damage = dmg
	if spd > 0.0: speed = spd
	rotation = _dir.angle()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	if light:
		light.color  = glow_color
		light.energy = 0.8

func _physics_process(delta: float) -> void:
	position += _dir * speed * delta
	_age += delta
	if _age >= lifetime:
		_expire()
		return
	# Trail particles — subclasses override for custom FX

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("world_tiles"):
		emit_signal("hit_world", Vector2i.ZERO)
		_on_hit_world()
	elif body.is_in_group("enemy"):
		_on_hit_enemy(body)

func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent and parent.is_in_group("enemy"):
		_on_hit_enemy(parent)

func _on_hit_enemy(enemy: Node2D) -> void:
	enemy.take_damage(damage)
	emit_signal("hit_enemy", enemy, damage)
	_hits += 1
	if aoe_radius > 0.0:
		_do_aoe_damage()
	if _hits > pierce:
		_expire()

func _on_hit_world() -> void:
	if aoe_radius > 0.0:
		_do_aoe_damage()
	_expire()

func _do_aoe_damage() -> void:
	var space = get_world_2d().direct_space_state
	var params = PhysicsShapeQueryParameters2D.new()
	params.shape = CircleShape2D.new()
	params.shape.radius   = aoe_radius
	params.transform      = Transform2D(0.0, global_position)
	params.collision_mask = 4  # enemies
	for result in space.intersect_shape(params, 16):
		var col = result.get("collider")
		if col and col.is_in_group("enemy"):
			col.take_damage(int(damage * 0.5))

func _expire() -> void:
	_on_expire_fx()
	queue_free()

func _on_expire_fx() -> void:
	pass  # Overridden in subclasses

# ════════════════════════════════════════════════════════════════
#  ARROW  (scripts/spells/Arrow.gd)
# ════════════════════════════════════════════════════════════════
class Arrow extends Projectile:
	func _ready() -> void:
		speed   = 500.0
		lifetime = 1.8
		glow_color = Color(1.0, 0.9, 0.7)

	func _physics_process(delta: float) -> void:
		super._physics_process(delta)
		# Gravity arc
		_dir.y += 180.0 * delta / speed
		rotation = _dir.angle()

# ════════════════════════════════════════════════════════════════
#  GENERIC BOLT  (scripts/spells/generic_bolt.gd)
# ════════════════════════════════════════════════════════════════
class GenericBolt extends Projectile:
	var _trail: Array = []

	func _ready() -> void:
		speed     = 380.0
		lifetime  = 2.0
		glow_color = Color(0.7, 0.4, 1.0)

	func _physics_process(delta: float) -> void:
		super._physics_process(delta)
		# Leave trail dots
		_trail.append(global_position)
		if _trail.size() > 6: _trail.pop_front()
		queue_redraw()

	func _draw() -> void:
		for i in _trail.size():
			var alpha = float(i) / _trail.size()
			draw_circle(_trail[i] - global_position,
				3.0 * alpha, Color(0.7,0.4,1.0, alpha * 0.6))

	func _on_expire_fx() -> void:
		# Burst of particles
		for _i in 6:
			var p = ColorRect.new()
			p.size    = Vector2(4,4)
			p.color   = Color(0.8,0.5,1.0,0.9)
			p.position = global_position + Vector2(randf_range(-8,8),randf_range(-8,8))
			get_parent().add_child(p)
			var tw = get_tree().create_tween() if get_tree() else null
			if tw:
				tw.tween_property(p,"modulate:a",0.0,0.4)
				tw.tween_callback(p.queue_free)

# ════════════════════════════════════════════════════════════════
#  FIREBALL  (scripts/spells/fireball.gd)
# ════════════════════════════════════════════════════════════════
class Fireball extends Projectile:
	func _ready() -> void:
		speed      = 280.0
		lifetime   = 2.5
		aoe_radius = 64.0
		glow_color = Color(1.0, 0.5, 0.1)

	func _physics_process(delta: float) -> void:
		super._physics_process(delta)
		# Fire trail
		var p = ColorRect.new()
		p.size     = Vector2(randf_range(3,7), randf_range(3,7))
		p.color    = Color(1.0, randf_range(0.3,0.7), 0.0, 0.8)
		p.position = global_position + Vector2(randf_range(-6,6), randf_range(-6,6))
		if get_parent():
			get_parent().add_child(p)
			var tw = p.create_tween()
			tw.tween_property(p, "modulate:a", 0.0, 0.25)
			tw.tween_callback(p.queue_free)

	func _on_expire_fx() -> void:
		for _i in 12:
			var p = ColorRect.new()
			p.size    = Vector2(randf_range(4,9), randf_range(4,9))
			p.color   = Color(1.0, randf_range(0.2,0.6), 0.0, 1.0)
			p.position= global_position + Vector2(randf_range(-24,24),randf_range(-24,24))
			if get_parent():
				get_parent().add_child(p)
				var tw = p.create_tween()
				tw.tween_property(p,"scale",Vector2(0,0),0.4)
				tw.parallel().tween_property(p,"modulate:a",0.0,0.4)
				tw.tween_callback(p.queue_free)

# ════════════════════════════════════════════════════════════════
#  ICE SHARD  (scripts/spells/ice_shard.gd)
# ════════════════════════════════════════════════════════════════
class IceShard extends Projectile:
	func _ready() -> void:
		speed    = 420.0
		lifetime = 1.6
		glow_color = Color(0.4, 0.9, 1.0)

	func _on_hit_enemy(enemy: Node2D) -> void:
		super._on_hit_enemy(enemy)
		# Freeze debuff
		if enemy.has_method("apply_debuff"):
			enemy.apply_debuff("frozen", 3.5)

# ════════════════════════════════════════════════════════════════
#  LIGHTNING BOLT  (scripts/spells/lightning_bolt.gd)
# ════════════════════════════════════════════════════════════════
class LightningBolt extends Node2D:
	"""Not a projectile — instant raycast chain."""
	var damage:    int  = 70
	var max_chain: int  = 3
	var chain_range: float = 180.0
	var _targets: Array = []

	func setup(origin: Vector2, initial_target: Node2D, dmg: int) -> void:
		damage = dmg
		global_position = origin
		_chain_to(initial_target, max_chain)
		_draw_bolts()
		await get_tree().create_timer(0.2).timeout
		queue_free()

	func _chain_to(target: Node2D, remaining: int) -> void:
		if not target or remaining <= 0: return
		_targets.append(target)
		target.take_damage(damage)
		damage = int(damage * 0.65)
		# Find next nearest un-hit enemy
		for e in get_tree().get_nodes_in_group("enemy"):
			if e in _targets: continue
			if e.global_position.distance_to(target.global_position) < chain_range:
				_chain_to(e, remaining - 1)
				break

	func _draw_bolts() -> void:
		# Render jagged lines between targets
		var prev = global_position
		for t in _targets:
			var end = t.global_position + Vector2(randf_range(-10,10),randf_range(-10,10))
			var ln = Line2D.new()
			ln.width          = 3.0
			ln.default_color  = Color(1,0.95,0.2,0.9)
			# Jag the line
			var steps = 8
			for s in range(steps+1):
				var p = prev.lerp(end, float(s)/steps)
				if s > 0 and s < steps:
					p += Vector2(randf_range(-12,12), randf_range(-12,12))
				ln.add_point(p - global_position)
			add_child(ln)
			var tw = ln.create_tween()
			tw.tween_property(ln,"modulate:a",0.0,0.18)
			tw.tween_callback(ln.queue_free)
			prev = end

# ════════════════════════════════════════════════════════════════
#  VOID BOLT  (scripts/spells/void_bolt.gd)
# ════════════════════════════════════════════════════════════════
class VoidBolt extends Projectile:
	func _ready() -> void:
		speed      = 200.0
		lifetime   = 3.0
		aoe_radius = 90.0
		glow_color = Color(0.6, 0.1, 1.0)

	func _physics_process(delta: float) -> void:
		super._physics_process(delta)
		# Seek nearest enemy
		var nearest: Node2D = null
		var best_dist = 200.0
		for e in get_tree().get_nodes_in_group("enemy"):
			var d = global_position.distance_to(e.global_position)
			if d < best_dist:
				best_dist = d
				nearest   = e
		if nearest:
			var desired = (nearest.global_position - global_position).normalized()
			_dir = _dir.lerp(desired, 2.5 * delta).normalized()
			rotation = _dir.angle()
