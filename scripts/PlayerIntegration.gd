# PlayerIntegration.gd
# Complete player integration for the character customization system
# Bridges the CharacterCustomizer with the existing Player.gd system

extends CharacterBody2D

# Player configuration exports
@export var start_gender: String = "male"
@export var start_class: String = "warrior"
@export var start_face: String = "stoic"
@export var start_hair_color: String = "black"

# Character customizer reference
var character_customizer: Node2D = null

# State
var is_controllable: bool = true
var current_appearance: Dictionary = {}

# References
@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var wind_system: Node = null

# Movement state for wind
var _last_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
    _initialize_character_system()
    _load_or_create_character()

func _initialize_character_system() -> void:
    """Initialize the character customizer system"""

    # Create or find wind system
    wind_system = get_tree().root.get_node_or_null("WindSystem")
    if not wind_system:
        wind_system = get_node_or_null("../WindSystem")

    # Create character customizer
    character_customizer = Node2D.new()
    character_customizer.set_script(load("res://scripts/CharacterCustomizer.gd"))
    add_child(character_customizer)

    # Connect signals
    if character_customizer.has_signal("appearance_changed"):
        character_customizer.appearance_changed.connect(_on_appearance_changed)
    if character_customizer.has_signal("hair_state_changed"):
        character_customizer.hair_state_changed.connect(_on_hair_state_changed)

func _load_or_create_character() -> void:
    """Load saved character or use defaults"""
    var saved_data = _load_character_data()

    if saved_data.size() > 0:
        character_customizer.load_appearance_data(saved_data)
    else:
        # Apply defaults
        character_customizer.set_gender(start_gender)
        character_customizer.set_class(start_class)
        character_customizer.set_face(start_face)
        character_customizer.set_hair_color(start_hair_color)

    current_appearance = character_customizer.get_appearance_data()

func _load_character_data() -> Dictionary:
    """Load character from save file if exists"""
    var save_path = "user://character_save.dat"
    if FileAccess.file_exists(save_path):
        var file = FileAccess.open_encrypted_with_pass(save_path, FileAccess.READ, "aetheria_save_key")
        if file:
            var json_str = file.get_line()
            file.close()
            var json = JSON.new()
            if json.parse(json_str) == OK:
                return json.get_data()
    return {}

func save_character() -> void:
    """Save current character appearance"""
    var save_path = "user://character_save.dat"
    var file = FileAccess.open_encrypted_with_pass(save_path, FileAccess.WRITE, "aetheria_save_key")
    if file:
        var data = character_customizer.get_appearance_data()
        var json_str = JSON.stringify(data)
        file.store_line(json_str)
        file.close()

# ==================== APPEARANCE METHODS ====================

func set_gender(gender: String) -> void:
    character_customizer.set_gender(gender)
    current_appearance = character_customizer.get_appearance_data()

func set_class(class_name: String) -> void:
    character_customizer.set_class(class_name)
    current_appearance = character_customizer.get_appearance_data()

func set_face(face: String) -> void:
    character_customizer.set_face(face)
    current_appearance = character_customizer.get_appearance_data()

func set_hair_color(color: String) -> void:
    character_customizer.set_hair_color(color)
    current_appearance = character_customizer.get_appearance_data()

func equip_armor(chest: String, helmet: String = "", boots: String = "") -> void:
    character_customizer.equip_armor(chest, helmet, boots)
    current_appearance = character_customizer.get_appearance_data()

func unequip_all_armor() -> void:
    character_customizer.unequip_all_armor()
    current_appearance = character_customizer.get_appearance_data()

# ==================== ANIMATION METHODS ====================

func play_idle() -> void:
    character_customizer.play_idle()
    _play_animation("idle")

func play_walk() -> void:
    character_customizer.play_walk()
    _play_animation("walk")

func play_run() -> void:
    character_customizer.play_run()
    _play_animation("run")

func play_swing() -> void:
    character_customizer.play_swing()
    _play_animation("swing")

func _play_animation(anim_name: String) -> void:
    """Play animation on AnimationPlayer if exists"""
    if animation_player and animation_player.has_animation(anim_name):
        animation_player.play(anim_name)

# ==================== MOVEMENT & WIND ====================

func _physics_process(delta: float) -> void:
    # Update velocity for wind system
    _last_velocity = velocity
    character_customizer.set_player_velocity(velocity)

func set_facing_direction(direction: int) -> void:
    """Set facing direction. 1 = right, -1 = left"""
    character_customizer.set_facing(direction)

func get_facing_direction() -> int:
    return character_customizer.get_facing_direction()

# ==================== SIGNALS ====================

func _on_appearance_changed(data: Dictionary) -> void:
    """Called when character appearance changes"""
    current_appearance = data
    # Emit custom signal for other systems
    emit_signal("appearance_changed", data)

func _on_hair_state_changed(wind_state: String) -> void:
    """Called when hair wind state changes"""
    # Can trigger visual effects based on wind state
    pass

# ==================== UTILITY ====================

func get_appearance_data() -> Dictionary:
    return character_customizer.get_appearance_data() if character_customizer else {}

func get_customizer() -> Node2D:
    return character_customizer

func enable_movement(enabled: bool) -> void:
    is_controllable = enabled

# Signal declaration
signal appearance_changed(appearance_data: Dictionary)
