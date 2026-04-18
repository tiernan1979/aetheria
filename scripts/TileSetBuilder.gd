# TileSetBuilder.gd  (Godot 4.6.1)
# Builds the TileSet at runtime from world_tiles.png (256×256, 16×16 tiles, 16 cols).
#
# Atlas row map:
#   Row 0  ids  0-14  — terrain (dirt,grass,stone,sand,sandstone,ice,snow,mud,obsidian,
#                               [9=wood ghost],stone_brick,platform,bedrock,glass,leaves)
#   Row 1  ids 16-18  — plants ghost (weed,flower_r,flower_y)
#   Row 2  ids 32-46  — half-blocks  (bottom 8px solid, top transparent)
#   Row 3  ids 48-62  — slope-L ╱   (lower-left triangle solid)
#   Row 4  ids 64-78  — slope-R ╲   (lower-right triangle solid)
#   Row 6  ids 96-103 — tier 1-4 ores
#   Row 7  ids 112-116— hardmode ores
#
# Ghost tile IDs (9, 16, 17, 18) are stored in the tilemap for game-logic reads
# but have NO atlas entry so nothing renders — Sprite2D nodes handle their visuals.

class_name TileSetBuilder

const TILE_SIZE  = Vector2i(16, 16)
const ATLAS_PATH = "res://assets/tilesets/world_tiles.png"
const ATLAS_COLS = 16

const SOLID_IDS = [
	0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 12,
	# dirt/stone variants (row 5, IDs 80-85)
	80, 81, 82, 83, 84, 85,
	96, 97, 98, 99, 100, 101, 102, 103,
	112, 113, 114, 115, 116,
]
const PLATFORM_IDS = [11]
const PASSABLE_IDS = [13, 14]  # glass, leaves — visible, no collision
const GHOST_IDS    = [9, 16, 17, 18]

# Slope tile IDs (row 2=half, row 3=slope-L, row 4=slope-R)
# Each slope ID = terrain_id + row_offset (32, 48, or 64)
const HALF_BLOCK_OFFSET  = 32   # row 2
const SLOPE_L_OFFSET     = 48   # row 3  ╱
const SLOPE_R_OFFSET     = 64   # row 4  ╲

# Which terrain IDs get slope variants
const SLOPE_SOURCE_IDS = [0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14]

const HE = 8.0  # half-extent for 16px tiles (±8 from centre)

static func build() -> TileSet:
	var texture = load(ATLAS_PATH)
	if not texture:
		push_error("TileSetBuilder: atlas not found at %s" % ATLAS_PATH)
		return TileSet.new()

	var ts = TileSet.new()
	ts.tile_size = TILE_SIZE

	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 0b00000010)
	ts.set_physics_layer_collision_mask(0,  0b00000001)

	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(1, 0b00000010)
	ts.set_physics_layer_collision_mask(1,  0b00000001)

	ts.add_navigation_layer()

	var src = TileSetAtlasSource.new()
	src.texture             = texture
	src.texture_region_size = TILE_SIZE
	src.use_texture_padding = false
	ts.add_source(src)

	# ── MAIN TERRAIN ──────────────────────────────────────────────────────────
	for tile_id in SOLID_IDS:
		var ac = id_to_atlas(tile_id)
		src.create_tile(ac)
		var td = src.get_tile_data(ac, 0)
		if not td: continue
		td.set_collision_polygons_count(0, 1)
		td.set_collision_polygon_points(0, 0, PackedVector2Array([
			Vector2(-HE,-HE), Vector2(HE,-HE), Vector2(HE,HE), Vector2(-HE,HE)
		]))

	for tile_id in PLATFORM_IDS:
		var ac = id_to_atlas(tile_id)
		src.create_tile(ac)
		var td = src.get_tile_data(ac, 0)
		if not td: continue
		td.set_collision_polygons_count(1, 1)
		td.set_collision_polygon_points(1, 0, PackedVector2Array([
			Vector2(-HE,-HE), Vector2(HE,-HE), Vector2(HE,-HE+3), Vector2(-HE,-HE+3)
		]))
		td.set_collision_polygon_one_way(1, 0, true)

	for tile_id in PASSABLE_IDS:
		var ac = id_to_atlas(tile_id)
		src.create_tile(ac)
		# No collision — visible but walkable

	# ── SLOPE TILES ───────────────────────────────────────────────────────────
	for src_id in SLOPE_SOURCE_IDS:
		var half_id  = src_id + HALF_BLOCK_OFFSET
		var slope_l  = src_id + SLOPE_L_OFFSET
		var slope_r  = src_id + SLOPE_R_OFFSET

		# Half-block: bottom 8px solid
		var ac_h = id_to_atlas(half_id)
		src.create_tile(ac_h)
		var td_h = src.get_tile_data(ac_h, 0)
		if td_h:
			td_h.set_collision_polygons_count(0, 1)
			td_h.set_collision_polygon_points(0, 0, PackedVector2Array([
				Vector2(-HE, 0.0), Vector2(HE, 0.0),
				Vector2(HE,  HE),  Vector2(-HE, HE)
			]))

		# Slope-L ╱: lower-left triangle (solid fills bottom-left, slope goes up-right)
		# Vertices: bottom-left, bottom-right, top-right (diagonal)
		var ac_l = id_to_atlas(slope_l)
		src.create_tile(ac_l)
		var td_l = src.get_tile_data(ac_l, 0)
		if td_l:
			td_l.set_collision_polygons_count(0, 1)
			td_l.set_collision_polygon_points(0, 0, PackedVector2Array([
				Vector2(-HE, HE),   # bottom-left
				Vector2(HE,  HE),   # bottom-right
				Vector2(HE, -HE),   # top-right
			]))

		# Slope-R ╲: lower-right triangle (solid fills bottom-right, slope goes up-left)
		var ac_r = id_to_atlas(slope_r)
		src.create_tile(ac_r)
		var td_r = src.get_tile_data(ac_r, 0)
		if td_r:
			td_r.set_collision_polygons_count(0, 1)
			td_r.set_collision_polygon_points(0, 0, PackedVector2Array([
				Vector2(-HE, HE),   # bottom-left
				Vector2(HE,  HE),   # bottom-right
				Vector2(-HE,-HE),   # top-left
			]))

	return ts

static func id_to_atlas(tile_id: int) -> Vector2i:
	return Vector2i(tile_id % ATLAS_COLS, tile_id / ATLAS_COLS)

static func atlas_to_id(atlas: Vector2i) -> int:
	return atlas.x + atlas.y * ATLAS_COLS

# Helper: get the half-block ID for a given terrain tile ID
static func half_block_id(terrain_id: int) -> int:
	return terrain_id + HALF_BLOCK_OFFSET

# Helper: get slope IDs for a given terrain tile ID
static func slope_l_id(terrain_id: int) -> int:
	return terrain_id + SLOPE_L_OFFSET

static func slope_r_id(terrain_id: int) -> int:
	return terrain_id + SLOPE_R_OFFSET
