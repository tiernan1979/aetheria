# ItemDrop.gd
# Attach to a RigidBody2D named "ItemDrop"
# Node tree:
#   ItemDrop (RigidBody2D) — collision_layer=8
#   ├── Sprite2D
#   ├── CollisionShape2D (CircleShape2D r=6)
#   ├── PickupArea (Area2D, collision_mask=1)  ← detects player
#   │   └── CollisionShape2D (CircleShape2D r=28)
#   └── CountLabel (Label, anchored bottom-right)

extends RigidBody2D

var item_id:    String = ""
var item_count: int    = 1

var _lifetime:  float = 600.0   # 10 minutes
var _pickup_cd: float = 0.8     # prevent instant re-pickup on drop
var _bob_phase: float = 0.0

@onready var sprite:       Sprite2D = $Sprite2D
@onready var count_label:  Label    = $CountLabel
@onready var pickup_area:  Area2D   = $PickupArea

func _ready() -> void:
	pickup_area.body_entered.connect(_on_body_entered)
	# Small initial impulse so drops scatter
	linear_velocity = Vector2(randf_range(-60, 60), randf_range(-120, -60))

func setup(id: String, count: int) -> void:
	item_id    = id
	item_count = count
	if not is_node_ready():
		await ready
	_apply_visuals()

func _apply_visuals() -> void:
	var item = ItemDB.get_item(item_id)
	if item:
		var tex_path = "res://assets/sprites/%s.png" % item.sprite
		if ResourceLoader.exists(tex_path):
			sprite.texture = load(tex_path)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	count_label.text    = str(item_count) if item_count > 1 else ""
	count_label.visible = item_count > 1

func _physics_process(delta: float) -> void:
	_lifetime  -= delta
	_pickup_cd -= delta
	_bob_phase += delta * 3.0

	# Gentle bob when resting
	if linear_velocity.length() < 5.0:
		position.y += sin(_bob_phase) * 0.3

	# Blink when about to expire
	if _lifetime < 15.0:
		visible = fmod(_lifetime, 0.5) > 0.25
	elif _lifetime < 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if _pickup_cd > 0.0:
		return
	if body.is_in_group("player"):
		body.add_item(item_id, item_count)
		_play_pickup_sound()
		queue_free()

func _play_pickup_sound() -> void:
	# Placeholder — swap for AudioStreamPlayer when audio assets are added
	pass
