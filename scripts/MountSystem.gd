# MountSystem.gd
# Autoload or attach to Player node.
# Handles mounting/dismounting, mount stats, and visual swapping.
#
# Usage:
#   MountSystem.try_mount(player, mount_id)
#   MountSystem.dismount(player)
#
# Mount IDs: "slime_mount", "wyvern_mount", "spectre_horse", "void_crawler"

extends Node

signal mounted(mount_id: String)
signal dismounted(mount_id: String)

const MOUNTS: Dictionary = {
	"slime_mount": {
		"display_name": "Verdite Slime",
		"speed_bonus":   60.0,
		"jump_bonus":    120.0,
		"fly":           false,
		"fly_speed":     0.0,
		"fall_immunity": false,
		"color":        Color(0.28, 0.85, 0.42),
		"sprite":       "res://assets/sprites/enemies/slime_king.png",
		"unlock_item":  "slime_saddle",
		"desc":         "Bounces extremely high. Can't be damaged while riding.",
	},
	"wyvern_mount": {
		"display_name": "Aether Wyvern",
		"speed_bonus":   90.0,
		"jump_bonus":    0.0,
		"fly":           true,
		"fly_speed":     380.0,
		"fall_immunity": true,
		"color":        Color(0.08, 0.75, 0.58),
		"sprite":       "res://assets/sprites/enemies/dragon_wyvern.png",
		"unlock_item":  "wyvern_bridle",
		"desc":         "Full flight. Obtained by taming a Dragon Wyvern with Jadite bait.",
	},
	"spectre_horse": {
		"display_name": "Spectre Steed",
		"speed_bonus":   110.0,
		"jump_bonus":    80.0,
		"fly":           false,
		"fly_speed":     0.0,
		"fall_immunity": true,
		"color":        Color(0.75, 0.80, 0.98),
		"sprite":       "res://assets/sprites/enemies/wraith.png",
		"unlock_item":  "spectrite_saddle",
		"desc":         "Phases through thin walls. Hardmode mount.",
	},
	"void_crawler": {
		"display_name": "Void Crawler",
		"speed_bonus":   75.0,
		"jump_bonus":    60.0,
		"fly":           false,
		"fly_speed":     0.0,
		"fall_immunity": false,
		"color":        Color(0.72, 0.22, 0.85),
		"sprite":       "res://assets/sprites/enemies/cave_spider.png",
		"unlock_item":  "void_saddle",
		"desc":         "Climbs walls and ceilings. Shoots webs that slow enemies.",
	},
}

var current_mount: String = ""
var _player = null
var _mount_sprite: Sprite2D = null
var _bob_phase: float = 0.0

func _process(delta: float) -> void:
	if current_mount == "" or not _player: return
	_bob_phase += delta * _get_bob_speed()
	if _mount_sprite:
		_mount_sprite.position.y = sin(_bob_phase) * _get_bob_amplitude()
		_mount_sprite.position.x = _player.velocity.x * delta * 0.08

func try_mount(player_node, mount_id: String) -> bool:
	if not mount_id in MOUNTS:
		push_warning("MountSystem: unknown mount '%s'" % mount_id)
		return false
	if current_mount != "":
		dismount(player_node)

	var data = MOUNTS[mount_id]
	_player = player_node
	current_mount = mount_id

	# Apply stat bonuses
	_player.mount_speed_bonus = data.speed_bonus
	_player.mount_jump_bonus  = data.jump_bonus
	_player.is_mounted        = true
	_player.mount_can_fly     = data.fly
	_player.mount_fly_speed   = data.fly_speed
	_player.mount_fall_immune = data.fall_immunity

	# Spawn mount sprite under player
	if ResourceLoader.exists(data.sprite):
		_mount_sprite = Sprite2D.new()
		_mount_sprite.texture = load(data.sprite)
		_mount_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_mount_sprite.scale = Vector2(3.0, 3.0)
		_mount_sprite.position = Vector2(0, 28)
		_mount_sprite.modulate = data.color
		_player.add_child(_mount_sprite)

	emit_signal("mounted", mount_id)
	print("Mounted: %s" % data.display_name)
	return true

func dismount(player_node) -> void:
	if current_mount == "": return
	var old_mount = current_mount

	_player = player_node
	_player.mount_speed_bonus = 0.0
	_player.mount_jump_bonus  = 0.0
	_player.is_mounted        = false
	_player.mount_can_fly     = false
	_player.mount_fly_speed   = 0.0
	_player.mount_fall_immune = false

	if _mount_sprite and is_instance_valid(_mount_sprite):
		_mount_sprite.queue_free()
	_mount_sprite = null
	current_mount = ""

	emit_signal("dismounted", old_mount)
	print("Dismounted")

func get_mount_data(mount_id: String) -> Dictionary:
	return MOUNTS.get(mount_id, {})

func has_mount(player_node, mount_id: String) -> bool:
	return mount_id in player_node.inventory

func get_available_mounts(player_node) -> Array:
	var available = []
	for mid in MOUNTS:
		var unlock = MOUNTS[mid].unlock_item
		if unlock in player_node.inventory:
			available.append(mid)
	return available

# ── MOUNT-SPECIFIC BEHAVIOURS ─────────────────────────────────

func apply_mount_physics(player_node, delta: float) -> void:
	"""Call from Player._physics_process — handles fly mode and wall climb."""
	if current_mount == "" or not player_node.is_mounted: return

	match current_mount:
		"slime_mount":
			_slime_physics(player_node, delta)
		"wyvern_mount":
			_wyvern_physics(player_node, delta)
		"void_crawler":
			_void_crawler_physics(player_node, delta)

func _slime_physics(p, delta: float) -> void:
	# Auto-bounce on landing
	if p.is_on_floor() and p.velocity.y > 10:
		p.velocity.y = -(p.base_jump_velocity + p.mount_jump_bonus) * 0.85

func _wyvern_physics(p, _delta: float) -> void:
	# Hold jump = fly upward
	if Input.is_action_pressed("jump") and not p.is_on_floor():
		p.velocity.y = move_toward(p.velocity.y, -p.mount_fly_speed, 80.0)

func _void_crawler_physics(p, _delta: float) -> void:
	# Wall climbing — check if touching a wall and pressing into it
	if p.is_on_wall() and (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")):
		p.velocity.y = move_toward(p.velocity.y, -120.0, 60.0)

# ── HELPERS ───────────────────────────────────────────────────

func _get_bob_speed() -> float:
	match current_mount:
		"slime_mount":   return 6.0
		"wyvern_mount":  return 2.5
		"spectre_horse": return 4.0
		"void_crawler":  return 3.5
		_: return 3.0

func _get_bob_amplitude() -> float:
	match current_mount:
		"slime_mount":   return 4.0
		"wyvern_mount":  return 3.5
		"spectre_horse": return 2.5
		_: return 2.0
