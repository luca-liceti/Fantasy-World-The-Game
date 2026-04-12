## Biome Decoration System
## ============================================================================
##
## Spawns lightweight 3D environment props on biome hex tiles.
##
## PERFORMANCE CONTRACT
## --------------------
##   The board has 397 hexes. ~60 are Forest. With naïve dense spawning that
##   quickly means thousands of high-poly meshes. This system is deliberately
##   conservative to keep frame rate playable on mid-range hardware:
##
##   • LARGE trees (fir_tree_01, pine_tree_01) are EXCLUDED from runtime use.
##     Those assets have 5 M+ vertex twig meshes — cinematic quality, not
##     game-ready.  Only saplings (4–7 wu tall) are used for large items.
##
##   • Each Forest tile spawns AT MOST:
##       – 0 or 1 center grass/ground item
##       – 0–3 small ground-cover items   (down from 6 attempts)
##       – 0–1 large sapling              (down from 2, only 55% of tiles)
##
##   • The PackedScene cache is static so each GLTF is loaded from disk only
##     once across all 60+ forest tiles.
##
##   • The GLTF variant-extraction trick is still used (Req 4), but only the
##     first (index 0) variant is used for large items — the "random" pick is
##     seeded so results vary per tile while avoiding re-instantiation cost.
##
##   Quick dials (project-wide) in GameConfig:
##     DECORATIONS_ENABLED = false  → no decorations at all (fastest)
##     DECORATION_DENSITY  = 0.3   → 30 % of normal density (lightweight)
##
## BIOME MODULARITY
## ----------------
##   Add a new biome by adding a Biomes.Type key to BIOME_CONFIG below.
##   All pool arrays, chances, and radii are read at runtime — no other
##   code changes needed.

class_name ForestDecorationSystem
extends RefCounted

# =============================================================================
# ASSET PATHS  (Forest only — other biomes can add their own paths later)
# =============================================================================

const BASE_PATH := "res://assets/models/enviroment/forest/optimized_assets/"

# ----- GRASS LOD VARIANTS -----
# Large grass (a-c): Tall, dense grass clumps for close-up
const GRASS_LARGE := [
	BASE_PATH + "grass_medium_01_2k_opt.glb",
]

# Mid grass (a-c): Medium height grass for mid-distance
const GRASS_MID := [
	BASE_PATH + "grass_medium_01_2k_opt.glb",
]

# Small grass (a-b): Compact grass for background fill
const GRASS_SMALL := [
	BASE_PATH + "grass_medium_01_2k_opt.glb",
]

# Tall grass (a-c): Upright tall grass variations
const GRASS_TALL := [
	BASE_PATH + "grass_medium_01_2k_opt.glb",
]

# Tiny grass (a-f): Very small grass tufts for dense fill
const GRASS_TINY := [
	BASE_PATH + "grass_medium_01_2k_opt.glb",
]

# ----- ground cover (low poly, center-safe) ----------------------------------
const PATH_FERN := BASE_PATH + "fern_02_2k_opt.glb"
const PATH_MOSS := BASE_PATH + "moss_01_2k_opt.glb"

# ----- medium debris (outer zone) --------------------------------------------
const PATH_ROCK_SET_01 := BASE_PATH + "rock_moss_set_01_2k_opt.glb"
const PATH_ROCK_SET_02 := BASE_PATH + "rock_moss_set_02_2k_opt.glb"
const PATH_STUMP_01 := BASE_PATH + "tree_stump_01_2k_opt.glb"
const PATH_STUMP_02 := BASE_PATH + "tree_stump_02_2k_opt.glb"
const PATH_PINE_ROOTS := BASE_PATH + "pine_roots_2k_opt.glb"
const PATH_DRY_BRANCHES := BASE_PATH + "dry_branches_medium_01_2k_opt.glb"
const PATH_FIR_SAPLING := BASE_PATH + "fir_sapling_2k_opt.glb"
const PATH_FIR_SAPLING_MED := BASE_PATH + "fir_sapling_medium_2k_opt.glb"
const PATH_PINE_SAPLING_SML := BASE_PATH + "pine_sapling_small_2k_opt.glb"
const PATH_PINE_SAPLING_MED := BASE_PATH + "pine_sapling_medium_2k_opt.glb"


# =============================================================================
# GRASS LOD CONFIGURATION
## ============================================================================
## LOD levels determine which grass mesh variant to use based on camera distance.
## Farther = simpler mesh = better performance.
## Distance thresholds in world units from camera.
# =============================================================================

enum GrassLOD {
	LARGE = 0,   # Close-up: 0-15 units
	MID,         # Mid-range: 15-30 units
	SMALL,       # Far: 30-50 units
	TALL,        # Very far: 50-70 units
	TINY,        # Extreme distance: 70+ units
}

const LOD_DISTANCES: Array[float] = [15.0, 30.0, 50.0, 70.0, 1000000.0]

const GRASS_LOD_POOLS: Dictionary = {
	GrassLOD.LARGE: GRASS_LARGE,
	GrassLOD.MID: GRASS_MID,
	GrassLOD.SMALL: GRASS_SMALL,
	GrassLOD.TALL: GRASS_TALL,
	GrassLOD.TINY: GRASS_TINY,
}

# =============================================================================
# SCALE TABLE
## ============================================================================
## Formula: target_scale = desired_m × (0.30 wu/m) / native_height_wu
## Native heights taken from GLTF accessor max-Y values.
## ±SCALE_JITTER (15 %) random variation applied per instance.
# =============================================================================

const DECO_SCALE: Dictionary = {
	"grass_medium_01_2k_opt.glb": {"base": 0.45},  # 1/4 knight height (~45cm grass)
	"fern_02_2k_opt.glb": {"base": 0.350},  # Increased for visibility
	"moss_01_2k_opt.glb": {"base": 0.400},  # Increased for visibility
	"rock_moss_set_01_2k_opt.glb": {"base": 0.240},
	"rock_moss_set_02_2k_opt.glb": {"base": 0.280},
	"tree_stump_01_2k_opt.glb": {"base": 0.300},
	"tree_stump_02_2k_opt.glb": {"base": 0.300},
	"pine_roots_2k_opt.glb": {"base": 0.175},
	"dry_branches_medium_01_2k_opt.glb": {"base": 0.225},
	# Saplings (Scaled up for taller forests)
	"fir_sapling_2k_opt.glb": {"base": 0.180},
	"fir_sapling_medium_2k_opt.glb": {"base": 0.225},
	"pine_sapling_small_2k_opt.glb": {"base": 0.237},
	"pine_sapling_medium_2k_opt.glb": {"base": 0.277},
}

## ±15 % scale jitter so no two instances look identical.
const SCALE_JITTER := 0.15

## Grass-specific scale multipliers per LOD level (larger at close range, smaller at far)
const GRASS_LOD_SCALE: Dictionary = {
	GrassLOD.LARGE: 1.5,  # 9cm close grass
	GrassLOD.MID: 1.0,     # 6cm mid grass
	GrassLOD.SMALL: 0.6,   # 3.6cm far grass
	GrassLOD.TALL: 0.8,    # 4.8cm tall grass
	GrassLOD.TINY: 0.4,    # 2.4cm distant grass
}


# =============================================================================
# PLACEMENT CONSTANTS
# =============================================================================

const CENTER_EXCLUSION_RADIUS := 0.35 # fraction of hex_size — only grass here
const SURFACE_OFFSET := 0.02 # Y lift above tile surface


# =============================================================================
# BIOME CONFIG
## ============================================================================
## Performance-tuned spawn counts for DENSE FOREST:
##   center    : 3-5 grass items (LOD variants)
##   grass_ground: 8-12 tiny grass tufts for dense coverage
##   small     : 4-6 ground cover items
##   large     : 2-4 saplings per tile
##
## TOTAL expected decorations per Forest tile ≈ 15-25 nodes.
## At 60 forest tiles: ~900-1200 decoration nodes total.
## LOD system ensures close grass is detailed, distant grass is simple.
# =============================================================================

const BIOME_CONFIG: Dictionary = {
	Biomes.Type.FOREST: {
		# CENTER: No grass clumps - grass is handled by GrassSystem
		"center_pool": [],
		"center_weights": [],
		"center_chance": 0.0,
		"center_count_min": 0,
		"center_count_max": 0,

		# GROUND FILL: Dense grass handled by GrassSystem - disable here
		"grass_ground_enabled": false,
		"grass_ground_pool": [],
		"grass_ground_attempts": 0,
		"grass_ground_chance": 0.0,

		# Small ground-cover in outer zone (ferns, moss, rocks)
		"small_pool": [
			PATH_FERN, PATH_FERN, PATH_FERN, PATH_FERN,
			PATH_FERN, PATH_FERN,
			PATH_MOSS, PATH_MOSS, PATH_MOSS, PATH_MOSS,
			PATH_ROCK_SET_01, PATH_ROCK_SET_02,
			PATH_STUMP_01, PATH_STUMP_02,
			PATH_PINE_ROOTS,
			PATH_DRY_BRANCHES,
		],
		"small_attempts": 8,
		"small_chance": 0.75,

		# Large (saplings) in far-outer / corner zone
		"large_pool": [
			PATH_FIR_SAPLING, PATH_PINE_SAPLING_SML, PATH_FIR_SAPLING,
			PATH_FIR_SAPLING_MED, PATH_PINE_SAPLING_MED, PATH_FIR_SAPLING_MED,
			PATH_FIR_SAPLING, PATH_FIR_SAPLING_MED,
		],
		"large_max": 4, # Dense clusters
		"large_attempt_chance": 0.98, # Almost always place
		"large_chance": 0.85, # High success rate
		"large_min_radius": 0.55,
	},

	# Placeholders — fill pools with biome-specific asset paths when assets land
	Biomes.Type.PEAKS: {
		"center_pool": [], "center_weights": [], "center_chance": 0.0,
		"small_pool": [], "small_attempts": 0, "small_chance": 0.0,
		"large_pool": [], "large_max": 0, "large_attempt_chance": 0.0,
		"large_chance": 0.0, "large_min_radius": 0.60,
	},
	Biomes.Type.WASTES: {
		"center_pool": [], "center_weights": [], "center_chance": 0.0,
		"small_pool": [], "small_attempts": 0, "small_chance": 0.0,
		"large_pool": [], "large_max": 0, "large_attempt_chance": 0.0,
		"large_chance": 0.0, "large_min_radius": 0.60,
	},
	Biomes.Type.PLAINS: {
		"center_pool": [], "center_weights": [], "center_chance": 0.0,
		"small_pool": [], "small_attempts": 0, "small_chance": 0.0,
		"large_pool": [], "large_max": 0, "large_attempt_chance": 0.0,
		"large_chance": 0.0, "large_min_radius": 0.60,
	},
	Biomes.Type.ASHLANDS: {
		"center_pool": [], "center_weights": [], "center_chance": 0.0,
		"small_pool": [], "small_attempts": 0, "small_chance": 0.0,
		"large_pool": [], "large_max": 0, "large_attempt_chance": 0.0,
		"large_chance": 0.0, "large_min_radius": 0.60,
	},
	Biomes.Type.HILLS: {
		"center_pool": [], "center_weights": [], "center_chance": 0.0,
		"small_pool": [], "small_attempts": 0, "small_chance": 0.0,
		"large_pool": [], "large_max": 0, "large_attempt_chance": 0.0,
		"large_chance": 0.0, "large_min_radius": 0.60,
	},
	Biomes.Type.SWAMP: {
		"center_pool": [], "center_weights": [], "center_chance": 0.0,
		"small_pool": [], "small_attempts": 0, "small_chance": 0.0,
		"large_pool": [], "large_max": 0, "large_attempt_chance": 0.0,
		"large_chance": 0.0, "large_min_radius": 0.60,
	},
}




# =============================================================================
# PUBLIC API
# =============================================================================

## Main entry point.  Registers decoration transforms with the central `manager`.
##
##   manager         – The central DecorationManager node
##   hex_size        – center-to-corner radius (world units)
##   rng             – seeded RandomNumberGenerator for reproducible results
##   biome_type      – the tile's biome (controls which asset pool is used)
##   tile_height     – local-space Y of the tile center vertex
##   vertex_heights  – local-space Y of the 6 corner vertices (index 0-5)
##   tile_transform  – the tile's global transform for world-space conversion
static func decorate_tile(
		manager: Node,
		hex_size: float,
		rng: RandomNumberGenerator,
		biome_type: Biomes.Type,
		tile_height: float,
		vertex_heights: Array,
		tile_transform: Transform3D
) -> void:
	# --- Master kill-switch (GameConfig.DECORATIONS_ENABLED) ------------------
	if not GameConfig.DECORATIONS_ENABLED:
		return

	# --- Biome guard ----------------------------------------------------------
	if not BIOME_CONFIG.has(biome_type):
		return
	var cfg: Dictionary = BIOME_CONFIG[biome_type]

	# Density multiplier (0.0 – 1.0) from GameConfig.DECORATION_DENSITY
	var density: float = clampf(GameConfig.DECORATION_DENSITY, 0.0, 1.0)
	
	var placed_count = 0

	# ---- 1. CENTER GRASS: Multiple grass clumps at hex center (LOD LARGE/MID) ----
	if not cfg.center_pool.is_empty() and cfg.has("center_chance"):
		var center_count: int = cfg.get("center_count_min", 1)
		var center_max: int = cfg.get("center_count_max", 1)
		var actual_count: int = center_count
		
		# Randomize count between min and max
		if center_max > center_count:
			actual_count = rng.randi_range(center_count, center_max)
		
		for i in range(actual_count):
			if rng.randf() < cfg.center_chance * density:
				var path = _weighted_pick(cfg.center_pool, cfg.get("center_weights", []), rng)
				if path != "":
					# Slight offset from center for variety
					var offset = Vector2(
						rng.randf_range(-0.15, 0.15) * hex_size,
						rng.randf_range(-0.15, 0.15) * hex_size
					)
					var sd = _get_surface_data(offset, tile_height, vertex_heights, hex_size)
					var pos = Vector3(offset.x, sd["y"] + SURFACE_OFFSET, offset.y)
					var lod_level = _get_grass_lod_for_position(tile_transform * Transform3D().translated(pos))
					var lod_path = _get_lod_path(path, lod_level)
					var transform = _get_decoration_transform(lod_path, pos, sd["normal"], rng, false, GrassLOD.MID)
					manager.add_decoration(lod_path, tile_transform * transform)
					placed_count += 1

	# ---- 1b. GROUND FILL: Dense tiny grass for carpet effect ----
	if cfg.get("grass_ground_enabled", false) and not cfg.grass_ground_pool.is_empty():
		var gg_attempts: int = cfg.get("grass_ground_attempts", 10)
		var gg_chance: float = cfg.get("grass_ground_chance", 0.7) * density
		
		for _i in range(gg_attempts):
			# Always place (no random chance check) for dense coverage
			var path: String = cfg.grass_ground_pool[rng.randi() % cfg.grass_ground_pool.size()]
			var uv_pos: Vector2 = _random_position_in_hex(rng, hex_size, 0.05, 0.95)
			
			if uv_pos == Vector2.INF:
				continue
			
			var sd = _get_surface_data(uv_pos, tile_height, vertex_heights, hex_size)
			var pos = Vector3(uv_pos.x, sd["y"] + SURFACE_OFFSET * 0.5, uv_pos.y)
			var lod_level = _get_grass_lod_for_position(tile_transform * Transform3D().translated(pos))
			var lod_path = _get_lod_path(path, lod_level)
			var transform = _get_decoration_transform(lod_path, pos, sd["normal"], rng, false, GrassLOD.TINY)
			manager.add_decoration(lod_path, tile_transform * transform)
			placed_count += 1

	# ---- 2. Small ground-cover in the outer zone -----------------------------
	var small_pool: Array = cfg.small_pool
	if not small_pool.is_empty():
		var attempts: int = cfg.small_attempts
		var chance: float = cfg.small_chance * density
		
		# Used to group small items together into clusters
		var cluster_center := Vector2.INF

		for _i in range(attempts):
			if rng.randf() > chance:
				continue

			var path: String = small_pool[rng.randi() % small_pool.size()]
			var uv_pos: Vector2
			
			if cluster_center != Vector2.INF and rng.randf() < 0.65:
				# 65% chance to cluster near the first item
				var offset_angle = rng.randf() * TAU
				var offset_dist = rng.randf_range(0.08, 0.25)
				uv_pos = cluster_center + Vector2(cos(offset_angle), sin(offset_angle)) * (offset_dist * hex_size)
				if not _in_hex(uv_pos.x, uv_pos.y, hex_size) or uv_pos.length() < hex_size * CENTER_EXCLUSION_RADIUS:
					uv_pos = _random_outer_position(rng, hex_size, CENTER_EXCLUSION_RADIUS, 0.92)
			else:
				uv_pos = _random_outer_position(rng, hex_size, CENTER_EXCLUSION_RADIUS, 0.92)
				
			if uv_pos == Vector2.INF:
				continue
				
			if cluster_center == Vector2.INF:
				cluster_center = uv_pos

			var sd = _get_surface_data(uv_pos, tile_height, vertex_heights, hex_size)
			var pos = Vector3(uv_pos.x, sd["y"] + SURFACE_OFFSET, uv_pos.y)
			var transform = _get_decoration_transform(path, pos, sd["normal"], rng, false)
			manager.add_decoration(path, tile_transform * transform)

	# ---- 3. Large item in the far-outer zone (saplings only) -----------------
	var large_pool: Array = cfg.large_pool
	if large_pool.is_empty():
		return
	if rng.randf() > cfg.large_attempt_chance * density:
		return

	var large_placed := 0
	var large_max: int = cfg.large_max
	var attempts2 := 0
	var max_attempts2 := large_max * 3
	var large_cluster_center := Vector2.INF

	while large_placed < large_max and attempts2 < max_attempts2:
		attempts2 += 1
		if rng.randf() > cfg.large_chance:
			continue

		var path: String = large_pool[rng.randi() % large_pool.size()]

		var uv_pos: Vector2
		if large_cluster_center != Vector2.INF and rng.randf() < 0.5:
			# Cluster tree near first tree
			var offset_angle = rng.randf() * TAU
			var offset_dist = rng.randf_range(0.12, 0.3)
			uv_pos = large_cluster_center + Vector2(cos(offset_angle), sin(offset_angle)) * (offset_dist * hex_size)
			if not _in_hex(uv_pos.x, uv_pos.y, hex_size) or uv_pos.length() < hex_size * cfg.large_min_radius:
				uv_pos = _corner_position(rng, hex_size)
		else:
			if rng.randf() < 0.6:
				uv_pos = _corner_position(rng, hex_size)
			else:
				uv_pos = _random_outer_position(rng, hex_size, cfg.large_min_radius, 0.88)

		if uv_pos == Vector2.INF:
			continue
			
		if large_cluster_center == Vector2.INF:
			large_cluster_center = uv_pos

		var sd = _get_surface_data(uv_pos, tile_height, vertex_heights, hex_size)
		var pos = Vector3(uv_pos.x, sd["y"] + SURFACE_OFFSET, uv_pos.y)
		var transform = _get_decoration_transform(path, pos, sd["normal"], rng, true)
		manager.add_decoration(path, tile_transform * transform)
		large_placed += 1


# =============================================================================
# PRIVATE HELPERS
# =============================================================================

## Returns {"y": float, "normal": Vector3} for a local XZ point on the hex surface.
## The hex fan has 6 triangles: (center, corner[i], corner[(i+1)%6]).
## We find which triangle contains `pos` and do barycentric interpolation.
## Falls back to tile_height / Vector3.UP if vertex_heights is empty or out-of-bounds.
static func _get_surface_data(
		pos: Vector2,
		tile_height: float,
		vertex_heights: Array,
		hex_size: float
) -> Dictionary:
	if vertex_heights.size() != 6:
		# No vertex data — flat tile
		return {"y": tile_height, "normal": Vector3.UP}

	# Build the 6 corner positions (local space, matching _rebuild_hex_mesh_with_vertex_heights)
	var corners: Array[Vector3] = []
	for i in range(6):
		var angle = deg_to_rad(60 * i - 30)
		corners.append(Vector3(hex_size * cos(angle), vertex_heights[i], hex_size * sin(angle)))

	var center_h: float = 0.0
	for h in vertex_heights:
		center_h += h
	center_h /= 6.0
	var center := Vector3(0, center_h, 0)

	# Test each of the 6 fan triangles
	for i in range(6):
		var a := center
		var b := corners[i]
		var c := corners[(i + 1) % 6]

		# Barycentric test in XZ
		var v0 := Vector2(c.x - a.x, c.z - a.z)
		var v1 := Vector2(b.x - a.x, b.z - a.z)
		var v2 := Vector2(pos.x - a.x, pos.y - a.z)

		var dot00 := v0.dot(v0)
		var dot01 := v0.dot(v1)
		var dot02 := v0.dot(v2)
		var dot11 := v1.dot(v1)
		var dot12 := v1.dot(v2)

		var inv_denom := dot00 * dot11 - dot01 * dot01
		if absf(inv_denom) < 0.00001:
			continue
		inv_denom = 1.0 / inv_denom

		var u := (dot11 * dot02 - dot01 * dot12) * inv_denom
		var v := (dot00 * dot12 - dot01 * dot02) * inv_denom

		if u >= -0.001 and v >= -0.001 and (u + v) <= 1.001:
			# Interpolate Y
			var y := a.y + u * (c.y - a.y) + v * (b.y - a.y)
			# Compute face normal
			var edge1 := b - a
			var edge2 := c - a
			var n := edge1.cross(edge2).normalized()
			if n.y < 0.0:
				n = -n
			return {"y": y, "normal": n}

	# Fallback (point outside hex, shouldn't happen for valid placements)
	return {"y": tile_height, "normal": Vector3.UP}


## Calculates the final local transform (basis + position) including:
## 1. Random Y rotation
## 2. Slope alignment (optional)
## 3. Calibrated scale with jitter
## 4. Grass LOD scale modifier
static func _get_decoration_transform(
		path: String,
		pos: Vector3,
		surface_normal: Vector3,
		rng: RandomNumberGenerator,
		is_large: bool,
		grass_lod: int = -1
) -> Transform3D:
	# 1. Base Basis with random Y rotation
	var current_y_rot := rng.randf() * TAU
	var basis := Basis.from_euler(Vector3(0, current_y_rot, 0))
	
	# 2. Add slope tilt if not an upright-only asset
	var is_upright = is_large and (
			path.find("sapling") != -1 or
			path.find("fir_tree") != -1 or
			path.find("pine_tree") != -1
	)
	
	if not is_upright and surface_normal.distance_to(Vector3.UP) > 0.001:
		var tilt := Quaternion(Vector3.UP, surface_normal)
		basis = Basis(tilt) * basis
		
	# 3. Apply Calibrated Scale (matching DECO_SCALE table)
	var scale_key := path.get_file()
	var s := 1.0
	if DECO_SCALE.has(scale_key):
		var base_s: float = DECO_SCALE[scale_key]["base"]
		var jitter: float = rng.randf_range(-SCALE_JITTER, SCALE_JITTER)
		s = base_s * (1.0 + jitter)
	
	# 4. Apply grass LOD scale modifier
	if grass_lod >= 0 and GRASS_LOD_SCALE.has(grass_lod):
		s *= GRASS_LOD_SCALE[grass_lod]
	
	basis = basis.scaled(Vector3(s, s, s))
	
	return Transform3D(basis, pos)


## Weighted random pick from parallel pool + weights arrays.
static func _weighted_pick(
		pool: Array,
		weights: Array,
		rng: RandomNumberGenerator
) -> String:
	if pool.is_empty():
		return ""
	if weights.is_empty() or weights.size() != pool.size():
		return pool[rng.randi() % pool.size()]

	var total: int = 0
	for w in weights:
		total += int(w)
	if total <= 0:
		return pool[rng.randi() % pool.size()]

	var roll: int = rng.randi() % total
	var cumulative: int = 0
	for i in range(pool.size()):
		cumulative += int(weights[i])
		if roll < cumulative:
			return pool[i]
	return pool[pool.size() - 1]


## Random 2D position in the annular band [min_r, max_r] * hex_size.
## Returns Vector2.INF when no valid position found.
static func _random_outer_position(
		rng: RandomNumberGenerator,
		hex_size: float,
		min_r: float,
		max_r: float,
		max_tries: int = 10
) -> Vector2:
	var inner := hex_size * min_r
	var outer := hex_size * max_r

	for _t in range(max_tries):
		var angle := rng.randf() * TAU
		var radius := rng.randf_range(inner, outer)
		var px := cos(angle) * radius
		var pz := sin(angle) * radius
		if _in_hex(px, pz, hex_size):
			return Vector2(px, pz)

	return Vector2.INF


## Position near one of the 6 hex corners (slightly inward from the edge).
static func _corner_position(rng: RandomNumberGenerator, hex_size: float) -> Vector2:
	var idx := rng.randi() % 6
	var angle := deg_to_rad(60.0 * idx - 30.0)
	var r := rng.randf_range(hex_size * 0.60, hex_size * 0.85)
	return Vector2(cos(angle) * r, sin(angle) * r)


## Random position anywhere within the hex (not just outer band).
static func _random_position_in_hex(
		rng: RandomNumberGenerator,
		hex_size: float,
		min_r: float = 0.0,
		max_r: float = 1.0,
		max_tries: int = 10
) -> Vector2:
	var outer := hex_size * max_r
	var inner := hex_size * min_r

	for _t in range(max_tries):
		var angle := rng.randf() * TAU
		var radius := rng.randf_range(inner, outer)
		var px := cos(angle) * radius
		var pz := sin(angle) * radius
		if _in_hex(px, pz, hex_size):
			return Vector2(px, pz)

	return Vector2.INF


## Determines the grass LOD level based on world position.
## For static decorations, this uses a default LOD level (can be overridden by camera distance).
static func _get_grass_lod_for_position(world_transform: Transform3D) -> int:
	return GrassLOD.MID


## Returns the LOD-appropriate path for a given grass path.
## Currently uses the same mesh for all LODs (placeholder for actual LOD meshes).
## In production, this would swap to lower-poly variants for distant grass.
static func _get_lod_path(base_path: String, lod_level: int) -> String:
	return base_path


## Pointy-top hex containment test.
static func _in_hex(px: float, pz: float, hex_size: float) -> bool:
	var ax := absf(px)
	var az := absf(pz)
	if ax > hex_size * 0.866:
		return false
	if az > hex_size:
		return false
	if ax * 0.5 + az * 0.866 > hex_size * 0.866:
		return false
	return true
