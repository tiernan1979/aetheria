# NPCBase.gd — Base for all town NPCs
# Node tree:
#   NPC (CharacterBody2D, collision_layer=1, mask=2)
#   ├── Sprite2D
#   ├── AnimationPlayer
#   ├── CollisionShape2D  (CapsuleShape2D r=6 h=20)
#   ├── InteractArea (Area2D, mask=1)  ← player enters → show prompt
#   │   └── CollisionShape2D (CircleShape2D r=32)
#   ├── DialoguePanel (Control, hidden)  ← parent: CanvasLayer or World UI
#   └── NameLabel (Label, z_index=5)

class_name NPCBase
extends CharacterBody2D

signal dialogue_opened(npc: NPCBase)
signal dialogue_closed(npc: NPCBase)
signal shop_opened(npc: NPCBase)

@export var npc_name:      String = "Villager"
@export var npc_portrait:  String = ""          # path in assets/sprites/npcs/
@export var wander_speed:  float  = 38.0
@export var home_tile:     Vector2i = Vector2i.ZERO

const GRAVITY = 980.0

var _player_near: bool  = false
var _talking:     bool  = false
var _wander_dir:  int   = 1
var _wander_t:    float = 0.0
var _idle_t:      float = 0.0
var _is_idle:     bool  = false
var _facing:      int   = 1

@onready var sprite:      Sprite2D      = $Sprite2D
@onready var anim:        AnimationPlayer = $AnimationPlayer
@onready var name_label:  Label         = $NameLabel
@onready var interact_area: Area2D      = $InteractArea

func _ready() -> void:
	add_to_group("npc")
	if name_label: name_label.text = npc_name
	if interact_area:
		interact_area.body_entered.connect(_on_body_entered)
		interact_area.body_exited.connect(_on_body_exited)
	if anim and sprite:
		AnimationHelper.setup_enemy_simple(anim, sprite, 2, 2, 1, 2)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	if not _talking:
		_do_wander(delta)

	sprite.flip_h = (_facing < 0)
	move_and_slide()

func _do_wander(delta: float) -> void:
	_wander_t -= delta
	_idle_t   -= delta

	if _is_idle:
		velocity.x = move_toward(velocity.x, 0.0, 120.0 * delta)
		_safe_play("idle")
		if _idle_t <= 0.0:
			_is_idle = false
			_wander_t = randf_range(2.0, 5.0)
			_wander_dir = 1 if randf() > 0.5 else -1
	else:
		velocity.x = lerp(velocity.x, _wander_dir * wander_speed, 8.0 * delta)
		_facing = _wander_dir
		_safe_play("walk")
		if _wander_t <= 0.0:
			_is_idle = true
			_idle_t  = randf_range(1.5, 4.0)

func _safe_play(clip: String) -> void:
	if not anim: return
	if anim.has_animation(clip) and anim.current_animation != clip:
		anim.play(clip)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_near = true
		_show_interact_prompt(true)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_near = false
		_show_interact_prompt(false)
		if _talking: _close_dialogue()

func _input(event: InputEvent) -> void:
	if not _player_near: return
	if event.is_action_pressed("attack") and not _talking:
		_open_dialogue()
	elif event.is_action_pressed("attack") and _talking:
		_close_dialogue()

func _open_dialogue() -> void:
	_talking = true
	velocity.x = 0.0
	emit_signal("dialogue_opened", self)
	_show_dialogue_panel(true)

func _close_dialogue() -> void:
	_talking = false
	emit_signal("dialogue_closed", self)
	_show_dialogue_panel(false)

func _show_interact_prompt(show: bool) -> void:
	if name_label:
		name_label.text = ("%s\n[F] Talk" % npc_name) if show else npc_name

func _show_dialogue_panel(show: bool) -> void:
	var panel = get_node_or_null("../UI/HUD/DialoguePanel")
	if panel and panel.has_method("show_npc"):
		if show: panel.show_npc(self)
		else:    panel.hide_dialogue()

# Override in subclasses
func get_greeting() -> String:
	return "Hello, traveller."

func get_dialogues() -> Array:
	return [get_greeting()]

func has_shop() -> bool:
	return false

func get_shop_inventory() -> Array:
	return []
