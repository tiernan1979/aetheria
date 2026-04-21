# CharacterCreatorUI.gd
# UI controller for the character creation screen
# Wires up all buttons and preview to the CharacterCustomizer

extends Control

# Character customizer reference
@onready var customizer: CharacterCustomizer = null
@onready var preview_sprite: Sprite2D = $VBox/HBox/PreviewPanel/CharacterPreview

# Button references
@onready var gender_buttons = {
    "male": $VBox/HBox/CustomizationPanel/GenderSection/GenderButtons/MaleButton,
    "female": $VBox/HBox/CustomizationPanel/GenderSection/GenderButtons/FemaleButton,
    "neutral": $VBox/HBox/CustomizationPanel/GenderSection/GenderButtons/NeutralButton,
}

@onready var face_buttons = {
    "stoic": $VBox/HBox/CustomizationPanel/FaceSection/FaceButtons/StoicButton,
    "fierce": $VBox/HBox/CustomizationPanel/FaceSection/FaceButtons/FierceButton,
    "calm": $VBox/HBox/CustomizationPanel/FaceSection/FaceButtons/CalmButton,
    "battle": $VBox/HBox/CustomizationPanel/FaceSection/FaceButtons/BattleButton,
}

@onready var hair_buttons = {
    "black": $VBox/HBox/CustomizationPanel/HairSection/HairButtons/BlackButton,
    "brown": $VBox/HBox/CustomizationPanel/HairSection/HairButtons/BrownButton,
    "blonde": $VBox/HBox/CustomizationPanel/HairSection/HairButtons/BlondeButton,
    "red": $VBox/HBox/CustomizationPanel/HairSection/HairButtons/RedButton,
}

@onready var class_buttons = {
    "warrior": $VBox/HBox/CustomizationPanel/ClassSection/ClassButtons/WarriorButton,
    "wizard": $VBox/HBox/CustomizationPanel/ClassSection/ClassButtons/WizardButton,
    "archer": $VBox/HBox/CustomizationPanel/ClassSection/ClassButtons/ArcherButton,
}

@onready var clothes_buttons = {
    "tunic": $VBox/HBox/CustomizationPanel/ClothesSection/ClothesButtons/TunicButton,
    "shirt": $VBox/HBox/CustomizationPanel/ClothesSection/ClothesButtons/ShirtButton,
    "robe": $VBox/HBox/CustomizationPanel/ClothesSection/ClothesButtons/RobeButton,
}

@onready var armor_buttons = {
    "": $VBox/HBox/CustomizationPanel/ArmorSection/ArmorButtons/NoneButton,
    "light": $VBox/HBox/CustomizationPanel/ArmorSection/ArmorButtons/LightButton,
    "heavy": $VBox/HBox/CustomizationPanel/ArmorSection/ArmorButtons/HeavyButton,
}

@onready var helmet_buttons = {
    "": $VBox/HBox/CustomizationPanel/HelmetSection/HelmetButtons/NoneButton,
    "full": $VBox/HBox/CustomizationPanel/HelmetSection/HelmetButtons/FullButton,
    "hood": $VBox/HBox/CustomizationPanel/HelmetSection/HelmetButtons/HoodButton,
}

@onready var confirm_button: Button = $VBox/ActionButtons/ConfirmButton
@onready var random_button: Button = $VBox/ActionButtons/RandomButton

signal character_confirmed(appearance_data: Dictionary)

func _ready() -> void:
    setup_customizer()
    connect_buttons()
    update_button_states()

func setup_customizer() -> void:
    """Create and initialize the character customizer"""
    customizer = CharacterCustomizer.new()
    add_child(customizer)

    # Connect to customizer signals
    customizer.appearance_changed.connect(_on_appearance_changed)

    # Update preview to use customizer's base sprite
    preview_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func connect_buttons() -> void:
    """Connect all UI buttons to their handlers"""
    # Gender buttons
    for gender in gender_buttons:
        gender_buttons[gender].pressed.connect(_on_gender_selected.bind(gender))

    # Face buttons
    for face in face_buttons:
        face_buttons[face].pressed.connect(_on_face_selected.bind(face))

    # Hair color buttons
    for color in hair_buttons:
        hair_buttons[color].pressed.connect(_on_hair_color_selected.bind(color))

    # Class buttons
    for class_name in class_buttons:
        class_buttons[class_name].pressed.connect(_on_class_selected.bind(class_name))

    # Clothes buttons
    for clothes in clothes_buttons:
        clothes_buttons[clothes].pressed.connect(_on_clothes_selected.bind(clothes))

    # Armor buttons
    for armor in armor_buttons:
        armor_buttons[armor].pressed.connect(_on_armor_selected.bind(armor))

    # Helmet buttons
    for helmet in helmet_buttons:
        helmet_buttons[helmet].pressed.connect(_on_helmet_selected.bind(helmet))

    # Action buttons
    confirm_button.pressed.connect(_on_confirm_pressed)
    random_button.pressed.connect(_on_random_pressed)

func _on_gender_selected(gender: String) -> void:
    customizer.set_gender(gender)
    update_button_states()

func _on_face_selected(face: String) -> void:
    customizer.set_face(face)
    update_button_states()

func _on_hair_color_selected(color: String) -> void:
    customizer.set_hair_color(color)
    update_button_states()

func _on_class_selected(class_name: String) -> void:
    customizer.set_class(class_name)
    update_button_states()

func _on_clothes_selected(clothes: String) -> void:
    customizer.set_clothes(clothes, "pants")
    customizer.unequip_all_armor()
    update_button_states()

func _on_armor_selected(armor_type: String) -> void:
    if armor_type == "":
        customizer.unequip_all_armor()
    else:
        customizer.equip_armor(armor_type)
    update_button_states()

func _on_helmet_selected(helmet_type: String) -> void:
    if customizer.appearance.get("armor_chest", "") != "":
        customizer.equip_armor(customizer.appearance["armor_chest"], helmet_type, customizer.appearance.get("armor_boots", ""))
    else:
        customizer.equip_armor("", helmet_type)
    update_button_states()

func _on_confirm_pressed() -> void:
    var data = customizer.get_appearance_data()
    emit_signal("character_confirmed", data)
    queue_free()

func _on_random_pressed() -> void:
    var genders = ["male", "female", "neutral"]
    var faces = ["stoic", "fierce", "calm", "battle"]
    var colors = ["black", "brown", "blonde", "red"]
    var classes = ["warrior", "wizard", "archer", "neutral"]
    var clothes_options = ["tunic", "shirt", "robe", ""]

    customizer.set_gender(genders[randi() % genders.size()])
    customizer.set_face(faces[randi() % faces.size()])
    customizer.set_hair_color(colors[randi() % colors.size()])
    customizer.set_class(classes[randi() % classes.size()])

    # Random clothes or armor
    if randi() % 2 == 0:
        customizer.set_clothes(clothes_options[randi() % 3], "pants")
    else:
        var armor_types = ["light", "heavy", "robes"]
        customizer.equip_armor(armor_types[randi() % armor_types.size()])

        # Random helmet (30% chance)
        if randi() % 3 == 0:
            var helmets = ["full", "hood"]
            customizer.equip_armor("", helmets[randi() % helmets.size()])

    update_button_states()

func _on_appearance_changed(data: Dictionary) -> void:
    """Called when customizer appearance changes"""
    update_preview()

func update_preview() -> void:
    """Update the preview sprite"""
    if customizer:
        var sprite = customizer.get_base_sprite()
        if sprite:
            preview_sprite.texture = sprite.texture

func update_button_states() -> void:
    """Highlight selected options"""
    if not customizer:
        return

    var appearance = customizer.appearance

    # Update gender buttons
    for gender in gender_buttons:
        gender_buttons[gender].add_theme_color_override("font_color",
            Color.WHITE if gender == appearance["gender"] else Color.GRAY)

    # Update face buttons
    for face in face_buttons:
        face_buttons[face].add_theme_color_override("font_color",
            Color.WHITE if face == appearance["face"] else Color.GRAY)

    # Update hair buttons
    for color in hair_buttons:
        hair_buttons[color].add_theme_color_override("font_color",
            Color.WHITE if color == appearance["hair_color"] else Color.GRAY)

    # Update class buttons
    for class_name in class_buttons:
        class_buttons[class_name].add_theme_color_override("font_color",
            Color.WHITE if class_name == appearance["class"] else Color.GRAY)

    # Update clothes buttons
    for clothes in clothes_buttons:
        var is_selected = appearance["clothes_top"] == clothes and appearance["armor_chest"] == ""
        clothes_buttons[clothes].add_theme_color_override("font_color",
            Color.WHITE if is_selected else Color.GRAY)

    # Update armor buttons
    for armor in armor_buttons:
        var is_selected = appearance["armor_chest"] == armor and armor != ""
        armor_buttons[armor].add_theme_color_override("font_color",
            Color.WHITE if is_selected else Color.GRAY)

    # Update helmet buttons
    for helmet in helmet_buttons:
        var is_selected = appearance["armor_helmet"] == helmet
        helmet_buttons[helmet].add_theme_color_override("font_color",
            Color.WHITE if is_selected else Color.GRAY)

    update_preview()

func get_character_data() -> Dictionary:
    return customizer.get_appearance_data() if customizer else {}