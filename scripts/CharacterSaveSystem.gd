# CharacterSaveSystem.gd
# Handles saving and loading character data

extends Node

const SAVE_PATH = "user://character.dat"
const ENCRYPT_KEY = "aetheria_character_key_v1"

func save_character(appearance_data: Dictionary) -> bool:
    """Save character appearance data to file"""
    var file = FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.WRITE, ENCRYPT_KEY)
    if file == null:
        push_error("Failed to open save file: %s" % FileAccess.get_open_error())
        return false

    var json_str = JSON.stringify(appearance_data)
    file.store_line(json_str)
    file.close()
    return true

func load_character() -> Dictionary:
    """Load character appearance data from file"""
    if not FileAccess.file_exists(SAVE_PATH):
        return {}

    var file = FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.READ, ENCRYPT_KEY)
    if file == null:
        push_error("Failed to open save file: %s" % FileAccess.get_open_error())
        return {}

    var json_str = file.get_line()
    file.close()

    var json = JSON.new()
    if json.parse(json_str) == OK:
        return json.get_data()
    return {}

func has_saved_character() -> bool:
    """Check if a character save exists"""
    return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
    """Delete the character save file"""
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(SAVE_PATH)

func export_character(export_path: String) -> bool:
    """Export character data to external file"""
    var data = load_character()
    if data.is_empty():
        return false

    var file = FileAccess.open(export_path, FileAccess.WRITE)
    if file == null:
        return false

    var json_str = JSON.stringify(data)
    file.store_line(json_str)
    file.close()
    return true

func import_character(import_path: String) -> bool:
    """Import character data from external file"""
    if not FileAccess.file_exists(import_path):
        return false

    var file = FileAccess.open(import_path, FileAccess.READ)
    if file == null:
        return false

    var json_str = file.get_line()
    file.close()

    var json = JSON.new()
    if json.parse(json_str) == OK:
        var data = json.get_data()
        if data is Dictionary:
            return save_character(data)
    return false
