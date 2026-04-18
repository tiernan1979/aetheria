# LootDrop.gd — Spawns item drops that the player can walk over to collect
# Attach to a RigidBody2D. Spawned by EnemyBase._die()
class_name LootDrop
extends RigidBody2D

const PICKUP_RANGE  = 52.0  # pixels — auto-collect when player within range
const ATTRACT_RANGE = 120.0 # pixels — floats toward player when this close
const ATTRACT_SPEED = 180.0
const DESPAWN_TIME  = 60.0  # seconds before drop disappears

var item_id:   String = ""
var quantity:  int    = 1
var _timer:    float  = 0.0
var _player:   Node2D = null
var _icon:     Sprite2D

@export var bob_speed: float = 2.0
@export var bob_height: float = 4.0

func _ready() -> void:
	add_to_group("loot_drop")
	collision_layer = 8
	collision_mask  = 2  # collides with world tiles
	gravity_scale   = 0.8
	# Icon sprite
	_icon = Sprite2D.new()
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon.scale = Vector2(0.7, 0.7)
	add_child(_icon)
	# Label for stack size
	if quantity > 1:
		var lbl = Label.new()
		lbl.text = str(quantity)
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.add_theme_color_override("font_shadow_color", Color(0,0,0,0.8))
		lbl.add_theme_constant_override("shadow_offset_x", 1)
		lbl.add_theme_constant_override("shadow_offset_y", 1)
		lbl.position = Vector2(-6, -4)
		add_child(lbl)
	# Glow ring
	_setup_glow()
	# Pop upward slightly when spawned
	linear_velocity = Vector2(randf_range(-40,40), -120)

func setup(id: String, qty: int) -> void:
	item_id  = id
	quantity = qty
	# Load sprite
	var item = ItemDB.get_item(id)
	if item and _icon:
		var tex_path = "res://assets/sprites/%s.png" % item.sprite
		if ResourceLoader.exists(tex_path):
			_icon.texture = load(tex_path)

func _setup_glow() -> void:
	var glow = PointLight2D.new()
	glow.texture  = _make_glow_texture()
	glow.energy   = 0.35
	glow.color    = Color(1.0, 0.9, 0.4)
	glow.texture_scale = 0.4
	add_child(glow)

func _make_glow_texture() -> ImageTexture:
	var img = Image.create(32,32,false,Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var d = Vector2(x-16,y-16).length()
			var a = clamp(1.0 - d/16.0, 0.0, 1.0) ** 2.0
			img.set_pixel(x,y,Color(1,1,1,a))
	return ImageTexture.create_from_image(img)

func _process(delta: float) -> void:
	_timer += delta
	# Despawn
	if _timer > DESPAWN_TIME:
		queue_free(); return
	# Flicker near despawn
	if _timer > DESPAWN_TIME - 5.0:
		modulate.a = 0.5 + sin(_timer * 8.0) * 0.5
	# Bob when resting
	if linear_velocity.length() < 5.0:
		_icon.position.y = sin(_timer * bob_speed) * bob_height
	# Find player
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
		return
	var dist = global_position.distance_to(_player.global_position)
	# Auto-collect
	if dist < PICKUP_RANGE:
		_collect(); return
	# Attract toward player
	if dist < ATTRACT_RANGE:
		var dir = (_player.global_position - global_position).normalized()
		linear_velocity = dir * ATTRACT_SPEED
		gravity_scale = 0.0
	else:
		gravity_scale = 0.8

func _collect() -> void:
	if not _player or not _player.has_method("add_item"): return
	_player.add_item(item_id, quantity)
	# Pickup sound + particle
	if has_node("/root/AudioManager"): AudioManager.play("coin", 0.1)
	queue_free()
