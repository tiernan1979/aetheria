# SaveSystem.gd
# Autoload as "SaveSystem"
# Handles save slots, world delta compression, and auto-save.
#
# Usage:
#   SaveSystem.save_game(world_node, player_node, slot=0)
#   SaveSystem.load_game(world_node, player_node, slot=0) -> bool

extends Node

const SAVE_DIR      = "user://saves/"
const SAVE_VERSION  = 3
const AUTO_SAVE_INT = 300.0   # 5 minutes

var _auto_timer: float = 0.0
var _world_ref         = null
var _player_ref        = null

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func init_refs(world, player) -> void:
	_world_ref  = world
	_player_ref = player

func _process(delta: float) -> void:
	if not _world_ref or not _player_ref:
		return
	_auto_timer += delta
	if _auto_timer >= AUTO_SAVE_INT:
		_auto_timer = 0.0
		save_game(0)
		print("Auto-saved.")

# ── SAVE ──────────────────────────────────────────────────────
func save_game(slot: int = 0) -> bool:
	if not _world_ref or not _player_ref:
		return false

	var data = {
		"version":         SAVE_VERSION,
		"timestamp":       Time.get_unix_time_from_system(),
		"world_seed":      _world_ref.world_seed,
		"player_pos":      var_to_str(_player_ref.global_position),
		"player_hp":       _player_ref.hp,
		"player_mana":     _player_ref.mana,
		"base_max_hp":     _player_ref.base_max_hp,
		"base_max_mana":   _player_ref.base_max_mana,
		"inventory":       _player_ref.inventory.duplicate(),
		"hotbar":          _player_ref.hotbar.duplicate(),
		"equipped":        _player_ref.equipped.duplicate(),
		"kills":           _player_ref.kills if "kills" in _player_ref else 0,
		"defeated_bosses": _world_ref.defeated_bosses if "defeated_bosses" in _world_ref else [],
		"hardmode":        _world_ref.hardmode if "hardmode" in _world_ref else false,
		"tile_deltas":     _world_ref.get_tile_deltas(),
		"placed_objects":  _world_ref.placed_objects if "placed_objects" in _world_ref else {},
	}

	var path = _slot_path(slot)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("SaveSystem: cannot open %s for writing" % path)
		return false

	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("Saved to slot %d: %s" % [slot, path])
	return true

# ── LOAD ──────────────────────────────────────────────────────
func load_game(slot: int = 0) -> bool:
	if not _world_ref or not _player_ref:
		return false

	var path = _slot_path(slot)
	if not FileAccess.file_exists(path):
		return false

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return false
	var raw  = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(raw)
	if not parsed or typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveSystem: corrupt save file at slot %d" % slot)
		return false

	var data = parsed
	if data.get("version", 0) < SAVE_VERSION:
		push_warning("SaveSystem: old save version — some data may be missing")

	# Restore world
	_world_ref.world_seed = data.get("world_seed", 0)
	if "defeated_bosses" in _world_ref:
		_world_ref.defeated_bosses = data.get("defeated_bosses", [])
	if "hardmode" in _world_ref:
		_world_ref.hardmode = data.get("hardmode", false)

	# Apply tile deltas (player modifications to the generated world)
	var deltas = data.get("tile_deltas", {})
	for key in deltas:
		var parts    = key.split(",")
		var tile_pos = Vector2i(int(parts[0]), int(parts[1]))
		var tile_id  = int(deltas[key])
		_world_ref.tilemap.set_cell(tile_pos, 0,
			Vector2i(tile_id % 16, tile_id / 16) if tile_id > 0 else Vector2i(-1,-1))

	# Restore player
	var pos_str = data.get("player_pos", "")
	if pos_str != "":
		_player_ref.global_position = str_to_var(pos_str)

	_player_ref.hp           = data.get("player_hp",   _player_ref.max_hp)
	_player_ref.mana         = data.get("player_mana", _player_ref.max_mana)
	_player_ref.base_max_hp  = data.get("base_max_hp", 100)
	_player_ref.base_max_mana= data.get("base_max_mana",80)
	_player_ref.inventory    = data.get("inventory",   {})
	_player_ref.hotbar       = data.get("hotbar",      [])
	while _player_ref.hotbar.size() < 10:
		_player_ref.hotbar.append("")
	_player_ref.equipped     = data.get("equipped",    {})
	if "kills" in _player_ref:
		_player_ref.kills    = data.get("kills", 0)

	_player_ref._recalc_stats()
	_player_ref.emit_signal("hp_changed",   _player_ref.hp,   _player_ref.max_hp)
	_player_ref.emit_signal("mana_changed", _player_ref.mana, _player_ref.max_mana)
	_player_ref.emit_signal("inventory_changed")

	print("Loaded slot %d (seed=%d)" % [slot, _world_ref.world_seed])
	return true

# ── SLOT INFO ─────────────────────────────────────────────────
func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(_slot_path(slot))

func get_slot_info(slot: int) -> Dictionary:
	if not slot_exists(slot):
		return {}
	var file = FileAccess.open(_slot_path(slot), FileAccess.READ)
	if not file: return {}
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if not data: return {}
	return {
		"timestamp": data.get("timestamp", 0),
		"kills":     data.get("kills", 0),
		"hardmode":  data.get("hardmode", false),
	}

func delete_slot(slot: int) -> void:
	var path = _slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func _slot_path(slot: int) -> String:
	return SAVE_DIR + "aetheria_save_%d.json" % slot
