# ModularCharacterSprite.gd
# Handles layered sprite system for modular character customization
# Supports: gender (head), class (arms), equipment (chest, helmet, boots)

extends Node2D

# Layer order (back to front)
enum Layer {
    BASE_LEGS = 0,
    BASE_TORSO = 1,
    BASE_ARMS = 2,
    EQUIP_BOOTS = 3,
    EQUIP_CHEST = 4,
    EQUIP_HELMET = 5,
    HEAD = 6,
}

# Sprite configuration
@export var character_gender: String = "male"  # "male", "female", "neutral"
@export var character_class: String = "warrior"  # "warrior", "wizard", "archer", "neutral"
@export var facing_right: bool = true

# Sprite nodes (created dynamically)
var _layer_sprites: Dictionary = {}

# Base paths
const SPRITE_PATH = "res://assets/sprites/player/parts/"

func _ready() -> void:
    setup_layers()
    update_sprites()

func setup_layers() -> void:
    """Initialize all sprite layers"""
    for layer in Layer.values():
        var sprite = Sprite2D.new()
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        add_child(sprite)
        _layer_sprites[layer] = sprite

func set_gender(gender: String) -> void:
    character_gender = gender
    update_head()
    update_torso()

func set_character_class(class_name: String) -> void:
    character_class = class_name
    update_arms()

func set_equipment(slot: String, item_id: String) -> void:
    """Set equipment on a slot. Pass empty string to remove."""
    match slot:
        "helmet":
            update_helmet(item_id)
        "chest":
            update_chest(item_id)
        "boots":
            update_boots(item_id)

func update_sprites() -> void:
    update_base()
    update_head()
    update_arms()
    update_equipment()

func update_base() -> void:
    """Update base body parts (legs, torso)"""
    set_layer_texture(Layer.BASE_LEGS, "base_legs.png")
    set_layer_texture(Layer.BASE_TORSO, "base_torso_%s.png" % character_gender)

func update_head() -> void:
    """Update head sprite based on gender"""
    set_layer_texture(Layer.HEAD, "head_%s.png" % character_gender)

func update_arms() -> void:
    """Update arms sprite based on class"""
    set_layer_texture(Layer.BASE_ARMS, "arms_%s.png" % character_class)

func update_equipment() -> void:
    """Update equipment - call set_equipment() for specific items"""
    # Default: no equipment
    set_layer_texture(Layer.EQUIP_CHEST, null)
    set_layer_texture(Layer.EQUIP_HELMET, null)
    set_layer_texture(Layer.EQUIP_BOOTS, null)

func update_chest(item_id: String) -> void:
    """Update chest armor"""
    if item_id == "" or item_id == "none":
        set_layer_texture(Layer.EQUIP_CHEST, null)
    elif item_id.begins_with("heavy"):
        set_layer_texture(Layer.EQUIP_CHEST, "armor_chest_heavy.png")
    elif item_id.begins_with("robe"):
        set_layer_texture(Layer.EQUIP_CHEST, "armor_chest_robes.png")
    else:
        set_layer_texture(Layer.EQUIP_CHEST, "armor_chest_light.png")

func update_helmet(item_id: String) -> void:
    """Update helmet"""
    if item_id == "" or item_id == "none":
        set_layer_texture(Layer.EQUIP_HELMET, null)
    elif item_id.begins_with("full"):
        set_layer_texture(Layer.EQUIP_HELMET, "helmet_full.png")
    elif item_id.begins_with("hood"):
        set_layer_texture(Layer.EQUIP_HELMET, "helmet_hood.png")
    else:
        set_layer_texture(Layer.EQUIP_HELMET, null)

func update_boots(item_id: String) -> void:
    """Update boots"""
    if item_id == "" or item_id == "none":
        set_layer_texture(Layer.EQUIP_BOOTS, null)
    elif item_id.begins_with("heavy"):
        set_layer_texture(Layer.EQUIP_BOOTS, "boots_heavy.png")
    else:
        set_layer_texture(Layer.EQUIP_BOOTS, "boots_light.png")

func set_layer_texture(layer: Layer, filename: String) -> void:
    """Set texture for a specific layer"""
    var sprite = _layer_sprites.get(layer)
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
    """Set facing direction. 1 = right, -1 = left"""
    facing_right = (direction > 0)
    for sprite in _layer_sprites.values():
        sprite.flip_h = not facing_right

# Animation support
func get_sprite() -> Sprite2D:
    return _layer_sprites[Layer.BASE_TORSO]

func set_idle_animation() -> void:
    """Configure sprites for idle animation - use base frame"""
    pass  # Base sprites don't animate

# Debug/utility
func print_layers() -> void:
    for layer in Layer.values():
        var sprite = _layer_sprites[layer]
        var tex_name = sprite.texture.resource_path.get_file() if sprite.texture else "none"
        print("Layer %d: %s" % [layer, tex_name])