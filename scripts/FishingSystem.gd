# FishingSystem.gd
# Attach to Player or as a separate node referenced by Player.
# Usage: call start_fishing(player) when player uses a rod item near water.

class_name FishingSystem
extends Node

signal fish_caught(fish_id: String, rarity: String)
signal fishing_started
signal fishing_failed(reason: String)

# ── FISH DATABASE ─────────────────────────────────────────────
const FISH_TABLE = {
	# Zone 0: Surface ponds / ocean
	"surface": [
		{id="aetherian_bass",  name="Aetherian Bass",  rarity="common",    xp=2,  value=8,   effect=""},
		{id="glimmerfish",     name="Glimmerfish",     rarity="uncommon",  xp=5,  value=22,  effect=""},
		{id="verdite_carp",    name="Verdite Carp",    rarity="uncommon",  xp=5,  value=25,  effect="+5 max HP for 10 min"},
		{id="moonjelly",       name="Moon Jelly",      rarity="rare",      xp=12, value=60,  effect="Grants water breathing 5 min"},
		{id="crystal_floater", name="Crystal Floater", rarity="rare",      xp=15, value=85,  effect="Restores 50 mana"},
		{id="ancient_scale",   name="Ancient Scale",   rarity="legendary", xp=50, value=350, effect="Crafting material"},
	],
	# Zone 1: Underground pools
	"underground": [
		{id="cave_shrimp",     name="Cave Shrimp",     rarity="common",    xp=3,  value=12,  effect=""},
		{id="deepfin",         name="Deepfin",         rarity="uncommon",  xp=7,  value=32,  effect=""},
		{id="voideel",         name="Void Eel",        rarity="rare",      xp=18, value=95,  effect="Ingredient: Dark Potion"},
		{id="blazite_barb",    name="Blazite Barb",    rarity="rare",      xp=20, value=110, effect="Ingredient: Fire Flask"},
		{id="spectral_ray",    name="Spectral Ray",    rarity="legendary", xp=60, value=480, effect="Drops Spectrite Dust"},
	],
	# Zone 2: Lava fishing (requires lava-proof rod)
	"lava": [
		{id="lava_minnow",     name="Lava Minnow",     rarity="uncommon",  xp=10, value=55,  effect=""},
		{id="embrite_piranha", name="Embrite Piranha", rarity="rare",      xp=25, value=155, effect="Crafting: Embrite Bait"},
		{id="hellfish",        name="Hellfish",        rarity="legendary", xp=80, value=650, effect="Drops Radiance Essence"},
	],
}

# ── BAIT EFFECTS ──────────────────────────────────────────────
const BAIT_POWER = {
	"gel":          10,   # basic gel bait
	"fang":         20,   # fang bait (uncommon boost)
	"lunar_bait":   45,   # crafted from moonite + gel
	"embrite_bait": 60,   # lava fishing
}

# ── STATE ─────────────────────────────────────────────────────
var _player        = null
var _is_fishing:   bool  = false
var _cast_pos:     Vector2 = Vector2.ZERO
var _bite_timer:   float  = 0.0
var _max_wait:     float  = 0.0
var _bait_power:   int    = 10
var _zone:         String = "surface"
var _reel_window:  float  = 0.0   # seconds player has to press attack to catch
var _bite_active:  bool   = false
var _float_node:   Node2D = null  # visual bobber

func start_fishing(player: Node, bait_id: String = "gel") -> void:
	if _is_fishing:
		push_warning("FishingSystem: already fishing")
		return

	_player     = player
	_bait_power = BAIT_POWER.get(bait_id, 10)
	_is_fishing = true
	_bite_active = false
	_reel_window = 0.0

	# Determine zone from player depth
	var py = player.global_position.y / 16.0
	if   py > 1050: _zone = "lava"
	elif py > 400:  _zone = "underground"
	else:           _zone = "surface"

	# Cast position (in front of player)
	var facing = player.get("_facing") if player.get("_facing") else 1
	_cast_pos = player.global_position + Vector2(facing * 80, 30)

	# Wait time inversely proportional to bait power (5s–18s range)
	_max_wait   = randf_range(5.0, 18.0) * (1.0 - _bait_power * 0.008)
	_bite_timer = _max_wait

	emit_signal("fishing_started")
	_spawn_float_visual()
	print("FishingSystem: cast in zone '%s' (bait power %d)" % [_zone, _bait_power])

func cancel_fishing() -> void:
	_is_fishing  = false
	_bite_active = false
	if _float_node and is_instance_valid(_float_node):
		_float_node.queue_free()
	_float_node = null

func _process(delta: float) -> void:
	if not _is_fishing: return

	if _bite_active:
		_reel_window -= delta
		if _reel_window <= 0.0:
			# Missed the catch
			_bite_active = false
			_bite_timer  = randf_range(3.0, 8.0)
			_animate_float(false)
	else:
		_bite_timer -= delta
		if _bite_timer <= 0.0:
			_trigger_bite()

func _trigger_bite() -> void:
	_bite_active = true
	_reel_window = randf_range(0.8, 2.2)  # how long player has to react
	_animate_float(true)
	# In a real implementation this would flash the UI and play a sound
	if has_node("/root/AudioManager"):
		if has_node("/root/AudioManager"): AudioManager.play("coin")   # use coin sound as bite indicator

func reel_in() -> void:
	if not _is_fishing or not _bite_active: return
	_catch_fish()

func _catch_fish() -> void:
	_is_fishing  = false
	_bite_active = false
	if _float_node and is_instance_valid(_float_node):
		_float_node.queue_free()
	_float_node = null

	var table    = FISH_TABLE.get(_zone, FISH_TABLE["surface"])
	var fish     = _weighted_pick(table)
	if not fish: return

	# Give fish to player
	if _player and _player.has_method("add_item"):
		_player.add_item(fish.id, 1)

	emit_signal("fish_caught", fish.id, fish.rarity)
	print("FishingSystem: caught %s (%s)!" % [fish.name, fish.rarity])

func _weighted_pick(table: Array) -> Dictionary:
	var rarity_weights = {"common":60, "uncommon":28, "rare":10, "legendary":2}
	# Bait increases rare chances
	var extra_rare = int(_bait_power * 0.15)
	rarity_weights["rare"]      += extra_rare
	rarity_weights["legendary"] += int(extra_rare * 0.3)

	var weighted = []
	for entry in table:
		var w = rarity_weights.get(entry.rarity, 10)
		for _i in w:
			weighted.append(entry)
	if weighted.is_empty(): return {}
	return weighted[randi() % weighted.size()]

func _spawn_float_visual() -> void:
	var lbl = Label.new()
	lbl.text = "🪣"
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.global_position = _cast_pos
	lbl.z_index = 50
	if _player: _player.get_parent().add_child(lbl)
	_float_node = lbl

func _animate_float(bobbing: bool) -> void:
	if not _float_node or not is_instance_valid(_float_node): return
	if bobbing:
		var tw = _float_node.create_tween().set_loops()
		tw.tween_property(_float_node, "position:y",
			_cast_pos.y + 8, 0.18).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(_float_node, "position:y",
			_cast_pos.y, 0.18).set_ease(Tween.EASE_IN_OUT)
	else:
		_float_node.position = Vector2(_cast_pos.x, _cast_pos.y)
