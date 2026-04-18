# EnemyManager.gd
# FIX: extends Node2D (was Node — caused "Script inherits from native type Node2D
#      so it can't be assigned to an object of type Node").
# FIX: added start(player, tilemap) which World.gd calls in _ready().
#      Previously there was no start() function, causing "Nonexistent function 'start'".
extends Node2D

const MAX_ENEMIES    = 12
const SPAWN_INTERVAL = 8.0
const SPAWN_DELAY    = 15.0

const SPAWN_TABLE = {
	0: ["res://scenes/enemies/GreenSlime.tscn"],
	1: ["res://scenes/enemies/GreenSlime.tscn"],
	2: ["res://scenes/enemies/GreenSlime.tscn"],
}

var _player:  CharacterBody2D = null
var _tilemap: TileMapLayer    = null
var _enemies: Array           = []
var _timer:   float           = SPAWN_INTERVAL
var _delay:   float           = 0.0
var _started: bool            = false

# Called by World._ready() once the world is fully generated.
func start(player: CharacterBody2D, tilemap: TileMapLayer) -> void:
	_player  = player
	_tilemap = tilemap
	_started = true

func _process(delta: float) -> void:
	if not _started or not _player: return
	_delay += delta
	if _delay < SPAWN_DELAY: return
	_timer -= delta
	if _timer <= 0.0:
		_timer = SPAWN_INTERVAL
		_try_spawn()
	_cull_distant()

func _try_spawn() -> void:
	if _enemies.size() >= MAX_ENEMIES: return

	var world = get_parent()
	if not world or not world.has_method("get_tile_id_at"): return

	# Pick a column off-screen to the left or right of the player
	var side  = 1 if randf() > 0.5 else -1
	var dist  = randf_range(500, 900)
	var spawn_x = _player.global_position.x + side * dist
	# Convert world-x to tile column (16 px tiles)
	var tile_x  = int(spawn_x / 16.0)
	tile_x = clamp(tile_x, 5, WorldGen.WORLD_WIDTH - 5)

	# Walk down from sky to find the first solid tile
	var surf_tile_y := -1
	for ty in range(WorldGen.SURFACE_MIN - 10, WorldGen.SURFACE_MAX + 30):
		if world.get_tile_id_at(Vector2i(tile_x, ty)) >= 0:
			surf_tile_y = ty
			break
	if surf_tile_y < 0: return

	# Snap spawn to top of surface tile (tile centre - 8 px for 16-px tile)
	var tile_center: Vector2 = _tilemap.map_to_local(Vector2i(tile_x, surf_tile_y))
	var tile_top:    float   = tile_center.y - 8.0
	# Slime CapsuleShape2D bottom ≈ +10 from origin → sit on tile top
	var spawn_pos := Vector2(tile_center.x, tile_top - 10.0)

	var zone := 0
	if surf_tile_y > WorldGen.UNDERWORLD_Y:   zone = 2
	elif surf_tile_y > WorldGen.CAVERN_START: zone = 1

	var table      = SPAWN_TABLE.get(zone, SPAWN_TABLE[0])
	var scene_path = table[randi() % table.size()]
	var scene      = load(scene_path)
	if not scene: return

	var e = scene.instantiate()
	e.global_position = spawn_pos
	get_parent().add_child(e)
	_enemies.append(e)

func _cull_distant() -> void:
	for e in _enemies.duplicate():
		if not is_instance_valid(e):
			_enemies.erase(e); continue
		if e.global_position.distance_to(_player.global_position) > 1100.0:
			_enemies.erase(e)
			e.queue_free()
