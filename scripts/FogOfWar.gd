# FogOfWar.gd
# Attach to a Node2D called "FogOfWar" in World.tscn  (z_index = 5)
# Renders a dark overlay with a revealed circle around the player.
# Uses a low-res exploration bitmap to remember visited tiles.

class_name FogOfWar
extends Node2D

@export var view_radius:    int   = 12   # tiles visible in clear circle
@export var reveal_radius:  int   = 18   # tiles marked as "explored"
@export var fog_color:      Color = Color(0.0, 0.0, 0.02, 0.88)
@export var explored_color: Color = Color(0.0, 0.0, 0.04, 0.52)
@export var update_interval:float = 0.08  # seconds between fog updates

# Fog resolution: 1 fog pixel = FOG_SCALE world tiles
const FOG_SCALE    = 2
const MAP_W        = 4200 / FOG_SCALE
const MAP_H        = 1200 / FOG_SCALE
const TILE_PX      = 16   # world pixels per tile

var _explored: PackedByteArray     # 0=unseen, 1=explored
var _fog_img:  Image
var _fog_tex:  ImageTexture
var _player:   Node2D = null
var _timer:    float  = 0.0
var _dirty:    bool   = true
var _sprite:   Sprite2D

func _ready() -> void:
	add_to_group("fog_of_war")
	_explored = PackedByteArray()
	_explored.resize(MAP_W * MAP_H)
	_explored.fill(0)

	_fog_img = Image.create(MAP_W, MAP_H, false, Image.FORMAT_RGBA8)
	_fog_img.fill(fog_color)
	_fog_tex = ImageTexture.create_from_image(_fog_img)

	_sprite = Sprite2D.new()
	_sprite.texture = _fog_tex
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR  # smooth edges
	_sprite.centered = false
	# Scale sprite to cover entire world
	_sprite.scale = Vector2(FOG_SCALE * TILE_PX, FOG_SCALE * TILE_PX)
	add_child(_sprite)
	z_index = 5

func init(player: Node2D) -> void:
	_player = player

func _process(delta: float) -> void:
	if not _player: return
	_timer += delta
	if _timer >= update_interval:
		_timer = 0.0
		_reveal_around_player()
		if _dirty:
			_dirty = false
			_redraw_fog()

func _reveal_around_player() -> void:
	var tx = int(_player.global_position.x / (TILE_PX * FOG_SCALE))
	var ty = int(_player.global_position.y / (TILE_PX * FOG_SCALE))

	for dy in range(-reveal_radius, reveal_radius + 1):
		for dx in range(-reveal_radius, reveal_radius + 1):
			if dx*dx + dy*dy > reveal_radius * reveal_radius: continue
			var fx = clamp(tx + dx, 0, MAP_W - 1)
			var fy = clamp(ty + dy, 0, MAP_H - 1)
			var idx = fy * MAP_W + fx
			if _explored[idx] == 0:
				_explored[idx] = 1
				_dirty = true

func _redraw_fog() -> void:
	var tx = int(_player.global_position.x / (TILE_PX * FOG_SCALE))
	var ty = int(_player.global_position.y / (TILE_PX * FOG_SCALE))

	# Only redraw region around player for performance
	var margin = reveal_radius + 4
	var x0 = clamp(tx - margin, 0, MAP_W - 1)
	var y0 = clamp(ty - margin, 0, MAP_H - 1)
	var x1 = clamp(tx + margin, 0, MAP_W - 1)
	var y1 = clamp(ty + margin, 0, MAP_H - 1)

	for fy in range(y0, y1 + 1):
		for fx in range(x0, x1 + 1):
			var idx  = fy * MAP_W + fx
			var dx   = fx - tx
			var dy   = fy - ty
			var dist2= dx*dx + dy*dy

			var col: Color
			if dist2 <= view_radius * view_radius:
				# Fully visible — gradient fade at edge
				var edge_t = clamp((sqrt(dist2) - view_radius * 0.7) / (view_radius * 0.3), 0.0, 1.0)
				col = fog_color.lerp(Color(0, 0, 0, 0), 1.0 - edge_t * 0.6)
				col.a = edge_t * fog_color.a * 0.3
			elif _explored[idx] == 1:
				col = explored_color
			else:
				col = fog_color
			_fog_img.set_pixel(fx, fy, col)

	_fog_tex.update(_fog_img)

# Save/load explored state
func get_explored_data() -> PackedByteArray:
	return _explored.duplicate()

func set_explored_data(data: PackedByteArray) -> void:
	if data.size() == _explored.size():
		_explored = data
		# Redraw full map
		for idx in _explored.size():
			var fx = idx % MAP_W
			var fy = idx / MAP_W
			_fog_img.set_pixel(fx, fy,
				explored_color if _explored[idx] == 1 else fog_color)
	_fog_tex.update(_fog_img)
	_dirty = false
