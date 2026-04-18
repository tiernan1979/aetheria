# WorldGen.gd  (Godot 4.6.1)
# 6400×1800 medium world. Fully random biome placement — no fixed order.
# Biomes affect surface AND underground zones independently.
# Dense cave network with slope/diagonal tiles on cave walls.

class_name WorldGen
extends Node

# ── WORLD SIZE ────────────────────────────────────────────────────────────
const WORLD_WIDTH   = 6400
const WORLD_HEIGHT  = 1800
const SURFACE_MIN   = 240
const SURFACE_MAX   = 360
const CAVERN_START  = 550
const UNDERWORLD_Y  = 1680
const BORDER_TILES  = 38     # bedrock bottom border only (sides wrap)

# ── TILE IDS ──────────────────────────────────────────────────────────────
const T_AIR        = -1
const T_DIRT       = 0
const T_GRASS      = 1
const T_STONE      = 2
const T_SAND       = 3
const T_SANDSTONE  = 4
const T_ICE        = 5
const T_SNOW       = 6
const T_MUD        = 7
const T_OBSIDIAN   = 8
const T_WOOD       = 9
const T_LEAVES     = 14
const T_HALF_OFF   = 32
const T_SLOPE_L    = 48   # ╱ lower-left triangle solid
const T_SLOPE_R    = 64   # ╲ lower-right triangle solid
const T_WEED       = 16
const T_FLOWER_R   = 17
const T_FLOWER_Y   = 18
const T_STONE_BRICK = 10
const T_PLATFORM   = 11
const T_BEDROCK    = 12
const ATLAS_COLS   = 16

const T_DIRT_PEBBLE  = 80
const T_DIRT_ROOT    = 81
const T_DIRT_STONE   = 82
const T_DIRT_CRACK   = 83
const T_STONE_FOSSIL = 84
const T_STONE_VEIN   = 85

# ── ORE IDS ───────────────────────────────────────────────────────────────
const T_COPRITE    = 96;  const T_STANNITE   = 97
const T_FERRITE    = 98;  const T_PLUMBITE   = 99
const T_ARGITE     = 100; const T_VOLFRAMITE = 101
const T_AURITE     = 102; const T_PALATITE   = 103
const T_AETHRIL    = 112; const T_VERIDITE   = 113
const T_DRACONITE  = 114; const T_SOLITE     = 115
const T_VOIDITE    = 116

# ── BIOME IDS ─────────────────────────────────────────────────────────────
const BIOME_FOREST     = 0
const BIOME_DESERT     = 1
const BIOME_ARCTIC     = 2
const BIOME_JUNGLE     = 3
const BIOME_CORRUPTION = 4
const BIOME_OCEAN      = 5

# ── INTERNALS ─────────────────────────────────────────────────────────────
var _rng:        RandomNumberGenerator = RandomNumberGenerator.new()
var _tm:         TileMapLayer  = null
var _wl:         TileMapLayer  = null
var _seed:       int  = 0
var _world_ore:  int  = 0
var _surf_biome: Array = []   # per-column surface biome
var _deep_biome: Array = []   # per-column underground biome (different layer)
var _heights:    Array = []

signal progress_changed(status: String, pct: float)
signal tree_planted(world_pos: Vector2, variant: String)
signal plant_placed(world_pos: Vector2, tile_id: int)

# ── GENERATION PIPELINE ───────────────────────────────────────────────────
func generate(tilemap: TileMapLayer, wall_layer: TileMapLayer, seed_val: int):
	_tm = tilemap; _wl = wall_layer
	_seed = seed_val; _rng.seed = seed_val
	_world_ore = _rng.randi() % 2

	emit_signal("progress_changed", "🌍 Shaping the land…", 3.0)
	await get_tree().process_frame
	_assign_biomes()
	_gen_heightmap()

	emit_signal("progress_changed", "⛏  Seeding ore veins…", 22.0)
	await get_tree().process_frame
	_gen_ores()

	emit_signal("progress_changed", "🕳  Carving cave networks…", 36.0)
	await get_tree().process_frame
	_gen_caves()

	emit_signal("progress_changed", "🗻 Cutting ravines…", 52.0)
	await get_tree().process_frame
	_gen_ravines()
	_gen_surface_lakes()

	emit_signal("progress_changed", "⛰  Smoothing edges…", 60.0)
	await get_tree().process_frame
	_gen_surface_slopes()
	_gen_cave_slopes()

	emit_signal("progress_changed", "🌳 Growing trees…", 68.0)
	await get_tree().process_frame
	_gen_trees()

	emit_signal("progress_changed", "🌸 Scattering plants…", 76.0)
	await get_tree().process_frame
	_gen_surface_plants()

	emit_signal("progress_changed", "🔥 Forging the Underworld…", 84.0)
	await get_tree().process_frame
	_gen_underworld()

	emit_signal("progress_changed", "☁  Raising floating islands…", 92.0)
	await get_tree().process_frame
	_gen_floating_islands()

	emit_signal("progress_changed", "✨ Almost ready…", 97.0)
	await get_tree().process_frame

# ── RANDOM BIOME ASSIGNMENT ───────────────────────────────────────────────
# Each biome is placed as a random-width "blob" scattered across the width.
# Surface and underground biomes are assigned completely independently.
# The world always starts with Forest near spawn (centre).
func _assign_biomes() -> void:
	_surf_biome.resize(WORLD_WIDTH)
	_deep_biome.resize(WORLD_WIDTH)
	for x in WORLD_WIDTH:
		_surf_biome[x] = BIOME_FOREST
		_deep_biome[x] = BIOME_FOREST

	# Biome pool for random placement
	var all_biomes = [BIOME_FOREST, BIOME_DESERT, BIOME_ARCTIC, BIOME_JUNGLE,
	                  BIOME_CORRUPTION, BIOME_OCEAN, BIOME_FOREST, BIOME_JUNGLE,
	                  BIOME_ARCTIC, BIOME_DESERT, BIOME_FOREST, BIOME_CORRUPTION]

	# Surface: scatter biome segments randomly, min 50 tiles each
	var segs_surf: Array = []
	var x_cursor = 0
	_rng.randomize()
	var biome_list = all_biomes.duplicate()
	biome_list.shuffle()  # fully random order
	# Always start with forest near spawn
	biome_list[biome_list.size()/2] = BIOME_FOREST

	for b in biome_list:
		var w = _rng.randi_range(80, 700)
		segs_surf.append({"biome": b, "start": x_cursor, "end": x_cursor + w})
		x_cursor += w
		if x_cursor >= WORLD_WIDTH: break

	# Fill remainder with forest
	if x_cursor < WORLD_WIDTH:
		segs_surf.append({"biome": BIOME_FOREST, "start": x_cursor, "end": WORLD_WIDTH})

	for seg in segs_surf:
		for x in range(seg.start, min(seg.end, WORLD_WIDTH)):
			_surf_biome[x] = seg.biome

	# Underground biomes: completely independent random assignment
	var biome_deep = [BIOME_FOREST, BIOME_ARCTIC, BIOME_CORRUPTION, BIOME_JUNGLE,
	                  BIOME_DESERT, BIOME_FOREST, BIOME_CORRUPTION, BIOME_ARCTIC,
	                  BIOME_JUNGLE, BIOME_FOREST]
	biome_deep.shuffle()
	x_cursor = 0
	for b in biome_deep:
		var w = _rng.randi_range(100, 800)
		for x in range(x_cursor, min(x_cursor + w, WORLD_WIDTH)):
			_deep_biome[x] = b
		x_cursor += w
		if x_cursor >= WORLD_WIDTH: break

# ── HEIGHTMAP ─────────────────────────────────────────────────────────────
func _gen_heightmap() -> void:
	_heights = _make_heights()

	for x in WORLD_WIDTH:
		if x % 600 == 0 and x > 0:
			await get_tree().process_frame

		var surf_b = _surf_biome[x]
		var deep_b = _deep_biome[x]
		var surf   = _heights[x]

		for y in WORLD_HEIGHT:
			# Hard bottom bedrock border
			if y >= WORLD_HEIGHT - BORDER_TILES:
				place_tile(_tm, x, y, T_BEDROCK)
				continue
			if y < surf - 1:
				pass  # air
			elif y == surf - 1:
				# Surface cap tile
				match surf_b:
					BIOME_ARCTIC:     place_tile(_tm, x, y, T_SNOW)
					BIOME_DESERT:     place_tile(_tm, x, y, T_SAND)
					BIOME_OCEAN:      place_tile(_tm, x, y, T_SAND)
					BIOME_JUNGLE:     place_tile(_tm, x, y, T_GRASS)
					BIOME_CORRUPTION: place_tile(_tm, x, y, T_GRASS)
					_:                place_tile(_tm, x, y, T_GRASS)
			elif y < surf + 20:
				# Sub-surface layer (biome-specific material)
				match surf_b:
					BIOME_ARCTIC:
						place_tile(_tm, x, y, T_SNOW if y < surf + 5 else T_ICE)
					BIOME_DESERT:  place_tile(_tm, x, y, T_SAND)
					BIOME_OCEAN:   place_tile(_tm, x, y, T_SAND)
					BIOME_JUNGLE:
						place_tile(_tm, x, y, T_MUD if y < surf + 8 else _dirty(x,y))
					BIOME_CORRUPTION:
						place_tile(_tm, x, y, T_STONE if y > surf + 5 else _dirty(x,y))
					_: place_tile(_tm, x, y, _dirty(x,y))
			elif y < WORLD_HEIGHT - BORDER_TILES - 1:
				# Deep stone — influenced by underground biome
				var tid = _deep_stone(x, y, deep_b)
				place_tile(_tm, x, y, tid)
			else:
				place_tile(_tm, x, y, T_BEDROCK)

		# Wall layer
		for wy in range(surf + 2, WORLD_HEIGHT - BORDER_TILES - 1):
			var wall_tid = 2  # default stone wall
			if _deep_biome[x] == BIOME_CORRUPTION and wy > CAVERN_START:
				wall_tid = 8  # obsidian wall hint
			place_tile(_wl, x, wy, wall_tid)

func _deep_stone(x: int, y: int, biome: int) -> int:
	# Different stone variants + biome-influenced occasional special blocks
	var hash_v = (x * 5 + y * 11 + x * y) % 30
	match biome:
		BIOME_CORRUPTION:
			if hash_v < 4:  return T_OBSIDIAN
			elif hash_v < 7: return T_STONE_VEIN
		BIOME_ARCTIC:
			if hash_v < 3:  return T_ICE
			elif hash_v < 5: return T_STONE_FOSSIL
		BIOME_JUNGLE:
			if hash_v < 3:  return T_MUD
			elif hash_v < 6: return T_STONE_FOSSIL
		BIOME_DESERT:
			if hash_v < 2:  return T_SANDSTONE
			elif hash_v < 5: return T_STONE_FOSSIL
	# Default stone with variants
	if hash_v == 0: return T_STONE_FOSSIL
	if hash_v == 1: return T_STONE_VEIN
	return T_STONE

func _dirty(x: int, y: int) -> int:
	var h = (x * 3 + y * 7 + x*y) % 18
	match h:
		0: return T_DIRT_PEBBLE
		1: return T_DIRT_ROOT
		2: return T_DIRT_STONE
		3: return T_DIRT_CRACK
	return T_DIRT

func _make_heights() -> Array:
	var h = []; h.resize(WORLD_WIDTH)
	var base = (SURFACE_MIN + SURFACE_MAX) / 2 - 5
	var ph = []; for _i in 6: ph.append(_rng.randf_range(0.0, TAU))

	for x in WORLD_WIDTH:
		var v = float(base)
		v += sin(x*0.00055+ph[0]) * 24.0
		v += sin(x*0.0018 +ph[1]) * 14.0
		v += sin(x*0.008  +ph[2]) * 7.0
		v += sin(x*0.025  +ph[3]) * 3.0
		v += sin(x*0.065  +ph[4]) * 1.2
		var cliff = sin(x*0.016+ph[5]*2.0)
		if cliff > 0.80: v += (cliff - 0.80)*52.0
		if cliff < -0.80: v += (cliff + 0.80)*38.0
		h[x] = int(clamp(v, float(SURFACE_MIN), float(SURFACE_MAX)))

	for _pass in 4:
		for x in range(2, WORLD_WIDTH-2):
			h[x] = int((h[x-2]+h[x-1]*2+h[x]*4+h[x+1]*2+h[x+2])/10)

	# Flatten only the 50 tiles around spawn
	var cx = WORLD_WIDTH/2; var fy = h[cx]
	for x in range(cx-50, cx+50):
		if x<0 or x>=WORLD_WIDTH: continue
		var d = float(abs(x-cx))/40.0
		h[x] = int(lerp(float(fy), float(h[x]), min(1.0, d*d)))
	return h

# ── ORES ──────────────────────────────────────────────────────────────────
func _gen_ores() -> void:
	var table = [
		[T_COPRITE,  T_STANNITE,   SURFACE_MAX,     550,  1600, 4],
		[T_FERRITE,  T_PLUMBITE,   380,              850,  1200, 5],
		[T_ARGITE,   T_VOLFRAMITE, 520,             1150,   900, 5],
		[T_AURITE,   T_PALATITE,   720,             1650,   600, 6],
	]
	for row in table:
		_scatter_ore(row[0] if _world_ore==0 else row[1],
		             row[2], row[3], row[4], row[5])

func scatter_hardmode_ores(tilemap: TileMapLayer) -> void:
	_tm = tilemap
	for row in [[T_AETHRIL,T_VERIDITE,CAVERN_START,UNDERWORLD_Y,420,6],
	            [T_DRACONITE,T_SOLITE,900,UNDERWORLD_Y,260,7],
	            [T_VOIDITE,T_VOIDITE,1250,UNDERWORLD_Y,140,8]]:
		_scatter_ore(row[0] if _world_ore==0 else row[1],row[2],row[3],row[4],row[5])

func _scatter_ore(ore_id:int, min_y:int, max_y:int, count:int, cluster:int) -> void:
	for _i in count:
		var cx = _rng.randi_range(10, WORLD_WIDTH-10)
		var cy = _rng.randi_range(min_y, max_y)
		for _j in cluster:
			var ox = cx+_rng.randi_range(-3,3)
			var oy = cy+_rng.randi_range(-2,2)
			var t = read_tile(_tm, ox, oy)
			if t==T_STONE or t==T_STONE_FOSSIL or t==T_STONE_VEIN or t==T_MUD:
				place_tile(_tm, ox, oy, ore_id)

# ── CAVE NETWORKS ─────────────────────────────────────────────────────────
# Dense worm caves + open pocket caverns + connecting tunnels
func _gen_caves() -> void:
	# 1. Worm caves — many more, varying sizes
	var worm_count = 680
	for cave_i in worm_count:
		if cave_i % 80 == 0: await get_tree().process_frame
		var wx = _rng.randi_range(5, WORLD_WIDTH-5)
		var wy = _rng.randi_range(SURFACE_MAX + 10, WORLD_HEIGHT - BORDER_TILES - 80)
		var angle = _rng.randf_range(0.0, TAU)
		var length = _rng.randi_range(35, 130)
		var radius = _rng.randi_range(2, 7)
		for _step in length:
			angle += _rng.randf_range(-0.5, 0.5)
			wx = int(wx + cos(angle)*1.6)
			wy = int(wy + sin(angle)*0.9)
			for dy in range(-radius, radius+1):
				for dx in range(-radius, radius+1):
					if dx*dx+dy*dy <= radius*radius:
						_carve(_tm, wx+dx, wy+dy)
						_carve(_wl,  wx+dx, wy+dy)

	# 2. Pocket caverns — large open spaces
	var pocket_count = 55
	for _i in pocket_count:
		if _i % 20 == 0: await get_tree().process_frame
		var px_c = _rng.randi_range(5, WORLD_WIDTH-5)
		var py_c = _rng.randi_range(CAVERN_START, WORLD_HEIGHT - BORDER_TILES - 100)
		var rx = _rng.randi_range(12, 32)
		var ry = _rng.randi_range(8, 20)
		# Ellipse carve
		for dy in range(-ry, ry+1):
			for dx in range(-rx, rx+1):
				var nx = float(dx)/rx; var ny = float(dy)/ry
				if nx*nx+ny*ny <= 1.0:
					_carve(_tm, px_c+dx, py_c+dy)
					_carve(_wl,  px_c+dx, py_c+dy)

	# 3. Near-surface caves (shallower, dips into surface layer)
	var surf_cave_count = 80
	for _i in surf_cave_count:
		var sx = _rng.randi_range(5, WORLD_WIDTH-5)
		var sy_start = _rng.randi_range(SURFACE_MAX - 10, SURFACE_MAX + 40)
		var angle = _rng.randf_range(0.1, 0.9)   # mostly horizontal
		var length = _rng.randi_range(20, 60)
		var radius = _rng.randi_range(1, 4)
		for _step in length:
			angle += _rng.randf_range(-0.3, 0.3)
			sx = int(sx + cos(angle)*1.8)
			sy_start = int(sy_start + sin(angle)*0.6)
			for dy in range(-radius, radius+1):
				for dx in range(-radius, radius+1):
					if dx*dx+dy*dy <= radius*radius:
						_carve(_tm, sx+dx, sy_start+dy)

func _carve(tm: TileMapLayer, x: int, y: int) -> void:
	var t = read_tile(tm, x, y)
	if t == T_BEDROCK or t == T_AIR: return
	if y < SURFACE_MIN - 5: return   # don't carve above world
	_erase(tm, x, y)

# ── RAVINES ───────────────────────────────────────────────────────────────
func _gen_ravines() -> void:
	var num = _rng.randi_range(8, 16)   # more ravines
	var cx  = WORLD_WIDTH/2
	for _i in num:
		var rx    = _rng.randi_range(100, WORLD_WIDTH-100)
		if abs(rx-cx) < 150: continue
		var rw    = _rng.randi_range(2, 7)
		var depth = _rng.randi_range(50, 180)
		var surf  = _find_surface(rx)
		if surf < 0: continue
		var sx = rx
		for y in range(surf, surf+depth):
			sx += _rng.randi_range(-1, 1)   # slight drift
			for x in range(sx-rw, sx+rw+1):
				_carve(_tm, x, y)
		# Widen at bottom
		for dx in range(-rw*2, rw*2+1):
			for dy in range(0, rw):
				_carve(_tm, sx+dx, surf+depth+dy)

func _gen_surface_lakes() -> void:
	var cx = WORLD_WIDTH/2
	for _i in 18:
		var lx = _rng.randi_range(100, WORLD_WIDTH-100)
		if abs(lx-cx) < 80: continue
		var surf = _find_surface(lx)
		if surf < 0 or surf > SURFACE_MAX - 3: continue
		var lw = _rng.randi_range(4, 18)
		for y in range(surf, surf+6):
			for x in range(lx-lw, lx+lw):
				var dx2 = abs(x-lx); var dy2 = y-surf
				if float(dx2)/lw + float(dy2)/6.0 < 1.0:
					_erase(_tm, x, y)

# ── SLOPE SMOOTHING ───────────────────────────────────────────────────────
func _gen_surface_slopes() -> void:
	for x in range(1, WORLD_WIDTH-1):
		var sh  = _find_surface(x)
		var sl  = _find_surface(x-1)
		var sr  = _find_surface(x+1)
		if sh < 0: continue
		var tid = read_tile(_tm, x, sh)
		if tid < 0 or tid >= T_HALF_OFF: continue
		if sr >= 0 and sr == sh-1:
			var rt = read_tile(_tm, x+1, sr)
			if rt >= 0 and rt < T_HALF_OFF:
				_erase(_tm, x+1, sr); place_tile(_tm, x+1, sr, rt+T_SLOPE_L)
		if sl >= 0 and sl == sh-1:
			var lt = read_tile(_tm, x-1, sl)
			if lt >= 0 and lt < T_HALF_OFF:
				_erase(_tm, x-1, sl); place_tile(_tm, x-1, sl, lt+T_SLOPE_R)

func _gen_cave_slopes() -> void:
	# Apply slopes to cave ceilings and floors for visual interest.
	# For every solid tile adjacent to air, check if it can become a slope.
	var step = 3   # sample every 3 tiles for performance
	for x in range(0, WORLD_WIDTH, step):
		for y in range(SURFACE_MAX, WORLD_HEIGHT - BORDER_TILES - 1, step):
			var tid = read_tile(_tm, x, y)
			if tid == T_AIR or tid == T_BEDROCK or tid >= T_HALF_OFF: continue
			if tid < 0: continue
			# Check if this tile has air on diagonal but solid below/beside it
			var air_r = read_tile(_tm, x+1, y) == T_AIR
			var air_l = read_tile(_tm, x-1, y) == T_AIR
			var sol_d = read_tile(_tm, x, y+1) != T_AIR
			var air_tl = read_tile(_tm, x-1, y-1) == T_AIR
			var air_tr = read_tile(_tm, x+1, y-1) == T_AIR
			# Cave wall going down-right → slope-R
			if air_r and sol_d and air_tr and tid < T_HALF_OFF and _rng.randi()%3==0:
				_erase(_tm, x, y); place_tile(_tm, x, y, tid + T_SLOPE_R)
			# Cave wall going down-left → slope-L
			elif air_l and sol_d and air_tl and tid < T_HALF_OFF and _rng.randi()%3==0:
				_erase(_tm, x, y); place_tile(_tm, x, y, tid + T_SLOPE_L)

# ── TREES ─────────────────────────────────────────────────────────────────
func _gen_trees() -> void:
	var spawn_clear = 18; var cx = WORLD_WIDTH/2
	var x = 5
	while x < WORLD_WIDTH - 5:
		if abs(x-cx) < spawn_clear: x+=1; continue
		var b = _surf_biome[x]
		if b != BIOME_FOREST and b != BIOME_JUNGLE: x+=1; continue
		var surf = _find_surface(x)
		if surf < 0: x+=1; continue
		var st = read_tile(_tm, x, surf)
		if st != T_GRASS and st != T_MUD: x+=1; continue
		var spacing = _rng.randi_range(2 if b==BIOME_JUNGLE else 3, 8)
		var ls = _find_surface(x-1)
		if ls >= 0 and abs(ls-surf) > 4: x+=spacing; continue
		_plant_tree(x, surf, b); x += spacing

func _plant_tree(tx:int, surf:int, biome:int) -> void:
	var roll = _rng.randi()%10; var trunk_h:int; var variant:String
	if biome==BIOME_JUNGLE:
		trunk_h=_rng.randi_range(9,16); variant="tree_xl" if roll>5 else "tree_lg"
	elif roll<4: trunk_h=_rng.randi_range(3,5); variant="tree_sm"
	elif roll<8: trunk_h=_rng.randi_range(5,8); variant="tree_md"
	else: trunk_h=_rng.randi_range(8,12); variant="tree_lg" if roll<9 else "tree_xl"
	for i in range(1, trunk_h+1):
		place_tile(_tm, tx, surf-i, T_WOOD)
		if i<=2 and trunk_h>8:
			place_tile(_tm, tx-1, surf-i+1, T_WOOD)
			place_tile(_tm, tx+1, surf-i+1, T_WOOD)
	emit_signal("tree_planted", _tm.map_to_local(Vector2i(tx, surf)), variant)

# ── SURFACE PLANTS ────────────────────────────────────────────────────────
func _gen_surface_plants() -> void:
	for x in range(5, WORLD_WIDTH-5):
		var b = _surf_biome[x]
		if b == BIOME_OCEAN or b == BIOME_ARCTIC: continue
		var surf = _find_surface(x)
		if surf < 0: continue
		var st = read_tile(_tm, x, surf)
		var can_grow = (st==T_GRASS) or (st==T_MUD and b==BIOME_JUNGLE)
		if not can_grow: continue
		if read_tile(_tm, x, surf-1) != T_AIR: continue
		var r = _rng.randi()%100
		var dens = 40 if b==BIOME_FOREST else (58 if b==BIOME_JUNGLE else 22)
		var pid = -1
		if r < dens: place_tile(_tm, x, surf-1, T_WEED); pid=T_WEED
		elif r < dens+9: place_tile(_tm, x, surf-1, T_FLOWER_R); pid=T_FLOWER_R
		elif r < dens+18: place_tile(_tm, x, surf-1, T_FLOWER_Y); pid=T_FLOWER_Y
		if pid >= 0:
			emit_signal("plant_placed", _tm.map_to_local(Vector2i(x, surf-1)), pid)
		if r < 12 and read_tile(_tm, x, surf-2) == T_AIR:
			var top = T_FLOWER_R if _rng.randi()%2==0 else T_FLOWER_Y
			place_tile(_tm, x, surf-2, top)
			emit_signal("plant_placed", _tm.map_to_local(Vector2i(x, surf-2)), top)

# ── UNDERWORLD ────────────────────────────────────────────────────────────
func _gen_underworld() -> void:
	for x in WORLD_WIDTH:
		for y in range(UNDERWORLD_Y, WORLD_HEIGHT-BORDER_TILES):
			var t = read_tile(_tm, x, y)
			if t==T_STONE or t==T_STONE_FOSSIL or t==T_STONE_VEIN or t==T_MUD:
				place_tile(_tm, x, y, T_OBSIDIAN)
		if _rng.randi()%30==0:
			var lw = _rng.randi_range(20, 110)
			for lx in range(x, min(x+lw, WORLD_WIDTH)):
				place_tile(_tm, lx, WORLD_HEIGHT-BORDER_TILES-2, T_OBSIDIAN)

# ── FLOATING ISLANDS ─────────────────────────────────────────────────────
func _gen_floating_islands() -> void:
	var count = int(WORLD_WIDTH/480)
	for _i in count:
		var cx = _rng.randi_range(100, WORLD_WIDTH-100)
		var cy = _rng.randi_range(80, SURFACE_MIN-50)
		var rx = _rng.randi_range(18, 42); var ry = _rng.randi_range(5,12)
		for iy in range(cy-ry, cy+ry+1):
			for ix in range(cx-rx, cx+rx+1):
				var nx = float(ix-cx)/rx; var ny = float(iy-cy)/ry
				if nx*nx+ny*ny<=1.0:
					place_tile(_tm, ix, iy, T_STONE if ny>0.3 else T_DIRT)
		place_tile(_tm, cx, cy-ry, T_GRASS)

# ── TILE HELPERS ─────────────────────────────────────────────────────────
func place_tile(tm:TileMapLayer, x:int, y:int, tile_id:int) -> void:
	if x<0 or x>=WORLD_WIDTH or y<0 or y>=WORLD_HEIGHT: return
	tm.set_cell(Vector2i(x,y), 0, Vector2i(tile_id%ATLAS_COLS, tile_id/ATLAS_COLS))

func _erase(tm:TileMapLayer, x:int, y:int) -> void:
	if x<0 or x>=WORLD_WIDTH or y<0 or y>=WORLD_HEIGHT: return
	tm.erase_cell(Vector2i(x,y))

func read_tile(tm:TileMapLayer, x:int, y:int) -> int:
	if x<0 or x>=WORLD_WIDTH or y<0 or y>=WORLD_HEIGHT: return T_BEDROCK
	var ac = tm.get_cell_atlas_coords(Vector2i(x,y))
	if ac==Vector2i(-1,-1): return T_AIR
	return ac.x + ac.y*ATLAS_COLS

func _find_surface(x:int) -> int:
	for y in range(SURFACE_MIN-15, SURFACE_MAX+25):
		if read_tile(_tm,x,y) != T_AIR: return y
	return -1
