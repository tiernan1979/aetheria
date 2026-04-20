# ModularPlayer.gd
# Complete modular character system for Godot
# Supports gender swapping, class variations, and equipment layering

extends CharacterBody2D

# Character configuration
@export var gender: String = "male": set = _set_gender
@export var character_class: String = "warrior": set = _set_class

# Layer nodes
@onready var sprite_base: Sprite2D = $Layer_Base
@onready var sprite_legs: Sprite2D = $Layer_Legs
@onready var sprite_arms: Sprite2D = $Layer_Arms
@onready var sprite_chest: Sprite2D = $Layer_Chest
@onready var sprite_boots: Sprite2D = $Layer_Boots
@onready var sprite_head: Sprite2D = $Layer_Head
@onready var sprite_helmet: Sprite2D = $Layer_Helmet

# Equipment state
var equipped_items: Dictionary = {
	"helmet": "",
	"chest": "",
	"boots": "",
	"weapon": "",
}

# Animation
var _facing: int = 1

const SPRITE_PATH = "res://assets/sprites/player/parts/"

func _ready() -> void:
	_init_sprites()
	apply_configuration()

func _init_sprites() -> void:
    """Initialize all sprite layers with proper settings"""
	var layers = [sprite_base, sprite_legs, sprite_arms, sprite_chest, sprite_boots, sprite_head, sprite_helmet]
	for sprite in layers:
		if sprite:
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.centered = true

func _set_gender(value: String) -> void:
	gender = value
	if is_inside_tree():
		apply_gender()

func _set_class(value: String) -> void:
	character_class = value
	if is_inside_tree():
		apply_class()

func apply_configuration() -> void:
	apply_gender()
	apply_class()
	apply_equipment()

func apply_gender() -> void:
    """Apply gender-specific sprites (head, torso)"""
	_set_texture(sprite_head, "head_%s.png" % gender)
	_set_texture(sprite_base, "base_torso_%s.png" % gender)

func apply_class() -> void:
    """Apply class-specific sprites (arms)"""
	_set_texture(sprite_arms, "arms_%s.png" % character_class)

func apply_equipment() -> void:
    """Apply all equipped items"""
	apply_helmet(equipped_items.get("helmet", ""))
	apply_chest(equipped_items.get("chest", ""))
	apply_boots(equipped_items.get("boots", ""))

func equip_item(slot: String, item_id: String) -> void:
    """Equip an item to a slot"""
	equipped_items[slot] = item_id
	match slot:
		"helmet": apply_helmet(item_id)
		"chest": apply_chest(item_id)
		"boots": apply_boots(item_id)

func unequip_item(slot: String) -> void:
    """Remove item from slot"""
	equip_item(slot, "")

func apply_helmet(item_id: String) -> void:
	if item_id == "" or item_id == "none":
		_set_texture(sprite_helmet, null)
	elif "full" in item_id:
		_set_texture(sprite_helmet, "helmet_full.png")
	elif "hood" in item_id:
		_set_texture(sprite_helmet, "helmet_hood.png")
	else:
		_set_texture(sprite_helmet, null)

func apply_chest(item_id: String) -> void:
	if item_id == "" or item_id == "none":
		_set_texture(sprite_chest, null)
	elif "heavy" in item_id:
		_set_texture(sprite_chest, "armor_chest_heavy.png")
	elif "robe" in item_id:
		_set_texture(sprite_chest, "armor_chest_robes.png")
	else:
		_set_texture(sprite_chest, "armor_chest_light.png")

func apply_boots(item_id: String) -> void:
	if item_id == "" or item_id == "none":
		_set_texture(sprite_boots, null)
	elif "heavy" in item_id:
		_set_texture(sprite_boots, "boots_heavy.png")
	else:
		_set_texture(sprite_boots, "boots_light.png")

func _set_texture(sprite: Sprite2D, filename: String) -> void:
	if not sprite:
		return
	if filename == null:
		sprite.texture = null
		return
	var path = SPRITE_PATH + filename
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
	else:
		sprite.texture = null

func set_facing(direction: int) -> void:
    """Set sprite facing direction"""
	_facing = sign(direction) if direction != 0 else 1
	var flip = _facing < 0
	sprite_base.flip_h = flip
	sprite_legs.flip_h = flip
	sprite_arms.flip_h = flip
	sprite_chest.flip_h = flip
	sprite_boots.flip_h = flip
	sprite_head.flip_h = flip
	sprite_helmet.flip_h = flip

func get_base_sprite() -> Sprite2D:
	return sprite_base
