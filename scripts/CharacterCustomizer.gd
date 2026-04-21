# CharacterCustomizer.gd
# Complete character customization system for Aetheria
# Handles: gender, face, hair color, animations, equipment, clothes, and wind-affected hair

extends Node2D

# Character configuration signals
signal appearance_changed(appearance_data: Dictionary)
signal animation_changed(anim_name: String)
signal hair_state_changed(wind_state: String)

# Layer order (back to front) - defines z-index layering
enum Layer {
    BASE_LEGS = 0,          # Bottom layer
    BASE_ARMS = 1,
    BASE_TORSO = 2,
    CLOTHES_PANTS = 3,
    CLOTHES_TOP = 4,
    EQUIP_BOOTS = 5,
    EQUIP_CHEST = 6,
    BASE_FACE = 7,
    HAIR = 8,               # Hair layer (affected by wind)
    EQUIP_HELMET = 9,      # Top layer (excluding effects)
}

# Wind hair states
enum HairWindState {
    NORMAL,     # Still/no wind
    LIGHT,      # Light breeze
    MEDIUM,     # Moderate wind
    STRONG,     # Strong wind
}

# Character appearance data
var appearance: Dictionary = {
    "gender": "male",           # "male", "female", "neutral"
    "face": "stoic",             # "stoic", "fierce", "calm", "battle"
    "hair_color": "black",      # "black", "brown", "blonde", "red"
    "class": "warrior",          # "warrior", "wizard", "archer", "neutral"
    "clothes_top": "tunic",      # "tunic", "shirt", "robe", ""
    "clothes_pants": "pants",    # "pants", ""
    "armor_chest": "",           # "" = no armor (use clothes)
    "armor_helmet": "",          # "" = no helmet
    "armor_boots": "",           # "" = no boots
}

# Animation state
enum AnimationState {
    IDLE,
    WALK,
    RUN,
    SWING,
}

var current_animation: AnimationState = AnimationState.IDLE
var facing_right: bool = true
var _layer_sprites: Dictionary = {}
var _animation_frame: int = 0
var _animation_timer: float = 0.0

# Wind system
var _wind_system: Node = null
var _current_wind_state: HairWindState = HairWindState.NORMAL
var _hair_anim_timer: float = 0.0
var _hair_anim_frame: int = 0
var _hair_flow_enabled: bool = true
var _player_velocity: Vector2 = Vector2.ZERO

# Animation configuration
const ANIM_FPS: Dictionary = {
    AnimationState.IDLE: 4.0,
    AnimationState.WALK: 6.0,
    AnimationState.RUN: 10.0,
    AnimationState.SWING: 12.0,
}

# Hair animation
const HAIR_ANIM_FPS: float = 8.0
const HAIR_FRAMES: int = 4

# Sprite paths
const SPRITE_BASE_PATH = "res://assets/sprites/player/parts/"

func _ready() -> void:
    setup_layers()
    _initialize_wind_system()
    apply_appearance()
    play_idle()

func _initialize_wind_system() -> void:
    """Find or create wind system"""
    _wind_system = get_tree().root.get_node_or_null("WindSystem")
    if not _wind_system:
        # Try sibling nodes
        _wind_system = get_node_or_null("../WindSystem")
    if not _wind_system:
        # Create a default wind system
        _wind_system = Node.new()
        _wind_system.set_script(load("res://scripts/WindSystem.gd"))
        get_tree().root.add_child(_wind_system)
        _wind_system.name = "WindSystem"

func setup_layers() -> void:
    """Initialize all sprite layers in correct z-order"""
    for layer in Layer.values():
        var sprite = Sprite2D.new()
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        sprite.centered = true
        add_child(sprite)
        _layer_sprites[layer] = sprite

    # Set initial z-index for each layer
    _layer_sprites[Layer.BASE_LEGS].z_index = 0
    _layer_sprites[Layer.BASE_ARMS].z_index = 1
    _layer_sprites[Layer.BASE_TORSO].z_index = 2
    _layer_sprites[Layer.CLOTHES_PANTS].z_index = 2
    _layer_sprites[Layer.CLOTHES_TOP].z_index = 3
    _layer_sprites[Layer.EQUIP_BOOTS].z_index = 1
    _layer_sprites[Layer.EQUIP_CHEST].z_index = 4
    _layer_sprites[Layer.BASE_FACE].z_index = 5
    _layer_sprites[Layer.HAIR].z_index = 6
    _layer_sprites[Layer.EQUIP_HELMET].z_index = 7

# ==================== APPEARANCE METHODS ====================

func set_gender(gender: String) -> void:
    appearance["gender"] = gender
    apply_appearance()
    emit_signal("appearance_changed", appearance)

func set_face(face: String) -> void:
    appearance["face"] = face
    apply_appearance()
    emit_signal("appearance_changed", appearance)

func set_hair_color(color: String) -> void:
    appearance["hair_color"] = color
    apply_appearance()
    emit_signal("appearance_changed", appearance)

func set_class(class_name: String) -> void:
    appearance["class"] = class_name
    apply_appearance()
    emit_signal("appearance_changed", appearance)

func set_clothes(top: String, pants: String) -> void:
    appearance["clothes_top"] = top
    appearance["clothes_pants"] = pants
    apply_appearance()
    emit_signal("appearance_changed", appearance)

func equip_armor(chest: String = "", helmet: String = "", boots: String = "") -> void:
    appearance["armor_chest"] = chest
    appearance["armor_helmet"] = helmet
    appearance["armor_boots"] = boots
    apply_appearance()
    emit_signal("appearance_changed", appearance)

func unequip_all_armor() -> void:
    appearance["armor_chest"] = ""
    appearance["armor_helmet"] = ""
    appearance["armor_boots"] = ""
    apply_appearance()
    emit_signal("appearance_changed", appearance)

func apply_appearance() -> void:
    """Apply all appearance settings to sprites"""
    _apply_base_body()
    _apply_face()
    _apply_hair()
    _apply_clothes()
    _apply_armor()
    _update_animation_frame()

func _apply_base_body() -> void:
    """Apply base body sprites (torso, arms, legs) based on gender and class"""
    var gender = appearance["gender"]
    var class_name = appearance["class"]

    # Torso based on gender
    var torso_path = SPRITE_BASE_PATH + "base_torso_%s.png" % gender
    _set_layer_texture(Layer.BASE_TORSO, torso_path)

    # Arms based on class
    var arms_path = SPRITE_BASE_PATH + "arms_%s.png" % class_name
    _set_layer_texture(Layer.BASE_ARMS, arms_path)

    # Legs (generic)
    var legs_path = SPRITE_BASE_PATH + "base_legs.png"
    _set_layer_texture(Layer.BASE_LEGS, legs_path)

func _apply_face() -> void:
    """Apply face sprite based on gender and face type"""
    var gender = appearance["gender"]
    var face = appearance["face"]

    # Map face types to available faces per gender
    var face_file = "face_%s_%s.png" % [gender if gender != "neutral" else "male", face]
    var face_path = SPRITE_BASE_PATH + face_file

    # Fallback if specific face doesn't exist
    if not ResourceLoader.exists(face_path):
        face_path = SPRITE_BASE_PATH + "face_%s_stoic.png" % (gender if gender != "neutral" else "male")

    _set_layer_texture(Layer.BASE_FACE, face_path)

func _apply_hair() -> void:
    """Apply hair sprite based on gender and color, considering wind state"""
    var gender = appearance["gender"]
    var color = appearance["hair_color"]
    var gender_prefix = "female_" if gender == "female" else ""

    # Determine wind state sprite
    var wind_suffix = ""
    match _current_wind_state:
        HairWindState.LIGHT:
            wind_suffix = "_wind1"
        HairWindState.MEDIUM:
            wind_suffix = "_wind1"
        HairWindState.STRONG:
            wind_suffix = "_wind2"

    # Try wind-affected hair sprite first
    var hair_file = "hair_%s%s%s.png" % [gender_prefix, color, wind_suffix]
    var hair_path = SPRITE_BASE_PATH + hair_file

    if not ResourceLoader.exists(hair_path):
        # Fallback to normal hair
        hair_path = SPRITE_BASE_PATH + "hair_%s%s.png" % [gender_prefix, color]

    if not ResourceLoader.exists(hair_path):
        # Ultimate fallback to base hair
        hair_path = SPRITE_BASE_PATH + "hair_%s.png" % color

    _set_layer_texture(Layer.HAIR, hair_path)

func _apply_clothes() -> void:
    """Apply clothes when no armor is equipped"""
    var has_armor = appearance["armor_chest"] != ""

    # Clothes (only when not wearing armor on that slot)
    if not has_armor:
        var top = appearance["clothes_top"]
        if top != "":
            var top_path = SPRITE_BASE_PATH + "clothes_%s.png" % top
            _set_layer_texture(Layer.CLOTHES_TOP, top_path)
        else:
            _set_layer_texture(Layer.CLOTHES_TOP, null)

        var pants = appearance["clothes_pants"]
        if pants != "":
            var pants_path = SPRITE_BASE_PATH + "clothes_pants.png"
            _set_layer_texture(Layer.CLOTHES_PANTS, pants_path)
        else:
            _set_layer_texture(Layer.CLOTHES_PANTS, null)
    else:
        # No clothes when armored
        _set_layer_texture(Layer.CLOTHES_TOP, null)
        _set_layer_texture(Layer.CLOTHES_PANTS, null)

func _apply_armor() -> void:
    """Apply armor equipment"""
    # Chest armor
    var chest = appearance["armor_chest"]
    if chest != "":
        var chest_path = SPRITE_BASE_PATH + "armor_chest_%s.png" % chest
        _set_layer_texture(Layer.EQUIP_CHEST, chest_path)
    else:
        _set_layer_texture(Layer.EQUIP_CHEST, null)

    # Helmet (hides hair)
    var helmet = appearance["armor_helmet"]
    if helmet != "":
        var helmet_path = SPRITE_BASE_PATH + "helmet_%s.png" % helmet
        _set_layer_texture(Layer.EQUIP_HELMET, helmet_path)
        # Hide hair when helmet is equipped
        _set_layer_texture(Layer.HAIR, null)
    else:
        _set_layer_texture(Layer.EQUIP_HELMET, null)
        # Show hair when no helmet
        if appearance["hair_color"] != "":
            _apply_hair()

    # Boots
    var boots = appearance["armor_boots"]
    if boots != "":
        var boots_path = SPRITE_BASE_PATH + "boots_%s.png" % boots
        _set_layer_texture(Layer.EQUIP_BOOTS, boots_path)
    else:
        _set_layer_texture(Layer.EQUIP_BOOTS, null)

func _set_layer_texture(layer: Layer, path: String) -> void:
    """Set texture for a layer, with fallback handling"""
    var sprite = _layer_sprites.get(layer)
    if not sprite:
        return

    if path == "" or path == null:
        sprite.texture = null
        return

    if ResourceLoader.exists(path):
        sprite.texture = load(path)
    else:
        sprite.texture = null

# ==================== WIND & HAIR FLOW ====================

func _process(delta: float) -> void:
    # Base animation (non-swing states)
    if current_animation != AnimationState.SWING:
        _animation_timer += delta
        var fps = ANIM_FPS.get(current_animation, 4.0)
        var frame_duration = 1.0 / fps

        if _animation_timer >= frame_duration:
            _animation_timer = 0.0
            _advance_animation_frame()

    # Hair flow animation
    if _hair_flow_enabled:
        _update_hair_flow(delta)

func _update_hair_flow(delta: float) -> void:
    """Update hair based on wind conditions"""
    if not _wind_system or appearance["armor_helmet"] != "":
        return

    # Get wind data
    var wind_data = _wind_system.get_wind_at_position(get_global_position())
    var wind_strength = wind_data["strength"]
    var wind_gust = wind_data["gust"]

    # Combine wind strength with player movement
    var player_speed = _player_velocity.length()
    var movement_factor = min(player_speed / 400.0, 1.0) * 2.0
    var effective_wind = wind_strength + movement_factor

    # Determine wind state
    var new_state: HairWindState
    if effective_wind > 3.0 or wind_gust > 0.8:
        new_state = HairWindState.STRONG
    elif effective_wind > 2.0 or wind_gust > 0.5:
        new_state = HairWindState.MEDIUM
    elif effective_wind > 1.0:
        new_state = HairWindState.LIGHT
    else:
        new_state = HairWindState.NORMAL

    # Update state if changed
    if new_state != _current_wind_state:
        _current_wind_state = new_state
        _apply_hair()
        emit_signal("hair_state_changed", HairWindState.keys()[_current_wind_state].to_lower())

    # Animate hair in wind
    if _current_wind_state != HairWindState.NORMAL:
        _hair_anim_timer += delta
        var hair_frame_duration = 1.0 / HAIR_ANIM_FPS

        if _hair_anim_timer >= hair_frame_duration:
            _hair_anim_timer = 0.0
            _hair_anim_frame = (_hair_anim_frame + 1) % HAIR_FRAMES

            # Apply hair animation (subtle position offset)
            var hair_sprite = _layer_sprites.get(Layer.HAIR)
            if hair_sprite:
                var offset = Vector2.ZERO
                offset.x = sin(_hair_anim_frame * PI / 2.0) * effective_wind * 0.5
                offset.y = cos(_hair_anim_frame * PI / 2.0) * 0.3
                hair_sprite.position = offset

                # Flip hair based on wind direction
                var wind_dir = wind_data["direction"]
                hair_sprite.flip_h = wind_dir.x < 0
    else:
        # Reset hair position
        var hair_sprite = _layer_sprites.get(Layer.HAIR)
        if hair_sprite:
            hair_sprite.position = Vector2.ZERO

func set_player_velocity(velocity: Vector2) -> void:
    """Set player velocity for movement-based wind effect"""
    _player_velocity = velocity

func enable_hair_flow(enabled: bool) -> void:
    """Enable or disable hair flow effect"""
    _hair_flow_enabled = enabled
    if not enabled:
        _current_wind_state = HairWindState.NORMAL
        _hair_anim_timer = 0.0
        _hair_anim_frame = 0
        _apply_hair()

func get_wind_state() -> String:
    """Get current wind state name"""
    return HairWindState.keys()[_current_wind_state].to_lower()

# ==================== ANIMATION METHODS ====================

func play_idle() -> void:
    current_animation = AnimationState.IDLE
    _animation_frame = 0
    _update_sprite_frame()
    emit_signal("animation_changed", "idle")

func play_walk() -> void:
    if current_animation != AnimationState.WALK:
        current_animation = AnimationState.WALK
        _animation_frame = 0
    emit_signal("animation_changed", "walk")

func play_run() -> void:
    if current_animation != AnimationState.RUN:
        current_animation = AnimationState.RUN
        _animation_frame = 0
    emit_signal("animation_changed", "run")

func play_swing() -> void:
    current_animation = AnimationState.SWING
    _animation_frame = 0
    _update_sprite_frame()
    emit_signal("animation_changed", "swing")

func _advance_animation_frame() -> void:
    var max_frames = _get_animation_frame_count()
    _animation_frame = (_animation_frame + 1) % max_frames
    _update_sprite_frame()

func _get_animation_frame_count() -> int:
    match current_animation:
        AnimationState.IDLE: return 4
        AnimationState.WALK: return 4
        AnimationState.RUN: return 6
        AnimationState.SWING: return 4
    return 4

func _update_sprite_frame() -> void:
    """Update sprite textures based on current animation frame"""
    var frame = _animation_frame

    # Get animation sprite prefix
    var anim_prefix = _get_animation_prefix()

    # Update each layer with its animation frame
    for layer in _layer_sprites.keys():
        var sprite = _layer_sprites[layer]
        if sprite.texture:
            # For modular system, we update which sprite is used
            # This is a simplified version - full implementation would
            # swap between anim frames
            pass

func _get_animation_prefix() -> String:
    match current_animation:
        AnimationState.IDLE: return "anim_idle"
        AnimationState.WALK: return "anim_walk"
        AnimationState.RUN: return "anim_run"
        AnimationState.SWING: return "anim_swing"
    return "anim_idle"

# ==================== DIRECTION METHODS ====================

func set_facing(direction: int) -> void:
    """Set facing direction. 1 = right, -1 = left"""
    facing_right = (direction > 0)
    _flip_sprites(not facing_right)

func _flip_sprites(flip: bool) -> void:
    """Flip all sprites horizontally"""
    for sprite in _layer_sprites.values():
        if sprite:
            sprite.flip_h = flip

func get_facing_direction() -> int:
    return 1 if facing_right else -1

# ==================== UTILITY METHODS ====================

func get_appearance_data() -> Dictionary:
    return appearance.duplicate(true)

func load_appearance_data(data: Dictionary) -> void:
    appearance = data.duplicate(true)
    apply_appearance()

func get_base_sprite() -> Sprite2D:
    return _layer_sprites.get(Layer.BASE_TORSO)

func get_all_sprites() -> Array:
    var sprites = []
    for sprite in _layer_sprites.values():
        if sprite:
            sprites.append(sprite)
    return sprites

func hide_all_layers() -> void:
    for sprite in _layer_sprites.values():
        if sprite:
            sprite.visible = false

func show_all_layers() -> void:
    for sprite in _layer_sprites.values():
        if sprite:
            sprite.visible = true

# Debug method
func print_layers() -> void:
    print("=== Character Customizer Layers ===")
    for layer in Layer.keys():
        var sprite = _layer_sprites.get(Layer.get(layer))
        var tex_name = "none"
        if sprite and sprite.texture:
            tex_name = sprite.texture.resource_path.get_file()
        print("%s: %s" % [layer, tex_name])
    print("Wind State: %s" % get_wind_state())
