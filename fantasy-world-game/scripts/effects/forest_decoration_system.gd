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
##
class_name ForestDecorationSystem
extends RefCounted

# =============================================================================
# ASSET PATHS  (Forest only — other biomes can add their own paths later)
# =============================================================================

const BASE_PATH := "res://assets/models/enviroment/forest/"

# ----- ground cover (low poly, center-safe) ----------------------------------
const PATH_GRASS          := BASE_PATH + "grass_medium_01_2k.gltf"
const PATH_FERN           := BASE_PATH + "fern_02_2k.gltf"
const PATH_MOSS           := BASE_PATH + "moss_01_2k.gltf"

# ----- medium debris (outer zone) --------------------------------------------
const PATH_ROCK_SET_01    := BASE_PATH + "rock_moss_set_01_2k.gltf"
const PATH_ROCK_SET_02    := BASE_PATH + "rock_moss_set_02_2k.gltf"
const PATH_STUMP_01       := BASE_PATH + "tree_stump_01_2k.gltf"
const PATH_STUMP_02       := BASE_PATH + "tree_stump_02_2k.gltf"
const PATH_DEAD_TRUNK     := BASE_PATH + "dead_tree_trunk_2k.gltf"
const PATH_PINE_ROOTS     := BASE_PATH + "pine_roots_2k.gltf"
const PATH_DRY_BRANCHES   := BASE_PATH + "dry_branches_medium_01_2k.gltf"

# ----- tall items (far-outer zone) — SAPLINGS ONLY, no mature trees ----------
## ⚠️  fir_tree_01 / pine_tree_01 are excluded: their twig surface alone has
##     5,368,447 vertices per variant × 3 variants = 16 M verts per GLTF load.
##     Use saplings until lower-poly tree assets are available.
const PATH_FIR_SAPLING        := BASE_PATH + "fir_sapling_2k.gltf"
const PATH_FIR_SAPLING_MED    := BASE_PATH + "fir_sapling_medium_2k.gltf"
const PATH_PINE_SAPLING_SML   := BASE_PATH + "pine_sapling_small_2k.gltf"
const PATH_PINE_SAPLING_MED   := BASE_PATH + "pine_sapling_medium_2k.gltf"


# =============================================================================
# SCALE TABLE
## ============================================================================
## Formula: target_scale = desired_m × (0.30 wu/m) / native_height_wu
## Native heights taken from GLTF accessor max-Y values.
## ±SCALE_JITTER (15 %) random variation applied per instance.
# =============================================================================

const DECO_SCALE: Dictionary = {
	"grass_medium_01_2k.gltf": { "base": 0.136 },
	"fern_02_2k.gltf":          { "base": 0.210 },
	"moss_01_2k.gltf":          { "base": 0.250 },
	"rock_moss_set_01_2k.gltf": { "base": 0.400 },
	"rock_moss_set_02_2k.gltf": { "base": 0.467 },
	"tree_stump_01_2k.gltf":    { "base": 0.300 },
	"tree_stump_02_2k.gltf":    { "base": 0.300 },
	"dead_tree_trunk_2k.gltf":  { "base": 0.300 },
	"pine_roots_2k.gltf":       { "base": 0.175 },
	"dry_branches_medium_01_2k.gltf": { "base": 0.225 },
	# Saplings
	"fir_sapling_2k.gltf":          { "base": 0.120 },
	"fir_sapling_medium_2k.gltf":   { "base": 0.150 },
	"pine_sapling_small_2k.gltf":   { "base": 0.158 },
	"pine_sapling_medium_2k.gltf":  { "base": 0.185 },
}

## ±15 % scale jitter so no two instances look identical.
const SCALE_JITTER := 0.15


# =============================================================================
# PLACEMENT CONSTANTS
# =============================================================================

const CENTER_EXCLUSION_RADIUS := 0.35   # fraction of hex_size — only grass here
const SURFACE_OFFSET          := 0.02   # Y lift above tile surface


# =============================================================================
# BIOME CONFIG
## ============================================================================
## Performance-tuned spawn counts:
##   center  : 0–1  (80 % probability)
##   small   : 3 attempts, 55 % each  → avg 1.65 items per tile
##   large   : 1 attempt, 45 % each, only 45 % of tiles → avg 0.20 per tile
##
## TOTAL expected decorations per Forest tile ≈ 1.85 nodes (down from ~6).
## At 60 forest tiles: ~111 decoration nodes total.  Very manageable.
##
## Each node uses ONE mesh from a reasonably-poly GLTF.  The ultra-poly
## mature trees are intentionally omitted (see PATH comments above).
# =============================================================================

const BIOME_CONFIG: Dictionary = {
	Biomes.Type.FOREST: {
		# Center (overlap-safe)
		"center_pool":    [ PATH_GRASS, PATH_GRASS, PATH_MOSS ],
		"center_weights": [ 4,          4,          1 ],
		"center_chance":  0.80,

		# Small ground-cover in outer zone
		"small_pool": [
			PATH_FERN,  PATH_FERN,          # most common undergrowth
			PATH_MOSS,
			PATH_ROCK_SET_01, PATH_ROCK_SET_02,
			PATH_STUMP_01,
			PATH_DEAD_TRUNK,
			PATH_PINE_ROOTS,
			PATH_DRY_BRANCHES,
		],
		"small_attempts": 3,    # ↓ from 6
		"small_chance":   0.55, # ↓ from 0.60

		# Large (saplings only) in far-outer / corner zone
		"large_pool": [
			PATH_FIR_SAPLING,  PATH_PINE_SAPLING_SML,
			PATH_FIR_SAPLING_MED, PATH_PINE_SAPLING_MED,
		],
		"large_max":            1,     # ↓ from 2 — one sapling per tile max
		"large_attempt_chance": 0.45,  # skip large entirely on 55 % of tiles
		"large_chance":         0.50,  # when attempted, 50 % success
		"large_min_radius":     0.60,
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
# RESOURCE CACHE
# =============================================================================

## PackedScene cache — each GLTF is loaded from disk only once.
static var _scene_cache: Dictionary = {}


# =============================================================================
# PUBLIC API
# =============================================================================

## Main entry point.  Spawns decorations as children of `tile`.
##
##   tile            – Node3D container that will own the spawned props
##   hex_size        – center-to-corner radius (world units)
##   rng             – seeded RandomNumberGenerator for reproducible results
##   biome_type      – the tile's biome (controls which asset pool is used)
##   tile_height     – local-space Y of the tile center vertex
##   vertex_heights  – local-space Y of the 6 corner vertices (index 0-5)
static func decorate_tile(
		tile:           Node3D,
		hex_size:       float,
		rng:            RandomNumberGenerator,
		biome_type:     Biomes.Type,
		tile_height:    float = 0.0,
		vertex_heights: Array = []
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

	# ---- 1. Center item (grass / ground scatter) ------------------------------
	if not cfg.center_pool.is_empty():
		if rng.randf() < cfg.center_chance * density:
			var path = _weighted_pick(cfg.center_pool, cfg.center_weights, rng)
			if path != "":
				var prop = _spawn_prop(path, rng)
				if prop:
					var sd = _get_surface_data(Vector2.ZERO, tile_height, vertex_heights, hex_size)
					prop.position = Vector3(0, sd["y"] + SURFACE_OFFSET, 0)
					prop.rotation_degrees.y = rng.randf_range(0.0, 360.0)
					_apply_slope_rotation(prop, sd["normal"], path, false)
					prop.name = "Deco_Center"
					tile.add_child(prop)

	# ---- 2. Small ground-cover in the outer zone -----------------------------
	var small_pool: Array = cfg.small_pool
	if not small_pool.is_empty():
		var attempts: int = cfg.small_attempts
		var chance: float  = cfg.small_chance * density

		for _i in range(attempts):
			if rng.randf() > chance:
				continue

			var path: String = small_pool[rng.randi() % small_pool.size()]
			var pos := _random_outer_position(rng, hex_size, CENTER_EXCLUSION_RADIUS, 0.92)
			if pos == Vector2.INF:
				continue

			var prop = _spawn_prop(path, rng)
			if not prop:
				continue

			var sd = _get_surface_data(pos, tile_height, vertex_heights, hex_size)
			prop.position = Vector3(pos.x, sd["y"] + SURFACE_OFFSET, pos.y)
			prop.rotation_degrees.y = rng.randf_range(0.0, 360.0)
			_apply_slope_rotation(prop, sd["normal"], path, false)
			prop.name = "Deco_Small"
			tile.add_child(prop)

	# ---- 3. Large item in the far-outer zone (saplings only) -----------------
	var large_pool: Array = cfg.large_pool
	if large_pool.is_empty():
		return
	if rng.randf() > cfg.large_attempt_chance * density:
		return

	var large_placed   := 0
	var large_max: int  = cfg.large_max
	var attempts2      := 0
	var max_attempts2  := large_max * 3

	while large_placed < large_max and attempts2 < max_attempts2:
		attempts2 += 1
		if rng.randf() > cfg.large_chance:
			continue

		var path: String = large_pool[rng.randi() % large_pool.size()]

		var pos: Vector2
		if rng.randf() < 0.6:
			pos = _corner_position(rng, hex_size)
		else:
			pos = _random_outer_position(rng, hex_size, cfg.large_min_radius, 0.88)

		if pos == Vector2.INF:
			continue

		var prop = _spawn_prop(path, rng)
		if not prop:
			continue

		var sd = _get_surface_data(pos, tile_height, vertex_heights, hex_size)
		prop.position = Vector3(pos.x, sd["y"] + SURFACE_OFFSET, pos.y)
		prop.rotation_degrees.y = rng.randf_range(0.0, 360.0)
		# Trees (saplings) stay upright; other large props tilt with the slope
		_apply_slope_rotation(prop, sd["normal"], path, true)
		prop.name = "Deco_Large"
		tile.add_child(prop)
		large_placed += 1


# =============================================================================
# PRIVATE HELPERS
# =============================================================================

## Returns {"y": float, "normal": Vector3} for a local XZ point on the hex surface.
## The hex fan has 6 triangles: (center, corner[i], corner[(i+1)%6]).
## We find which triangle contains `pos` and do barycentric interpolation.
## Falls back to tile_height / Vector3.UP if vertex_heights is empty or out-of-bounds.
static func _get_surface_data(
		pos:            Vector2,
		tile_height:    float,
		vertex_heights: Array,
		hex_size:       float
) -> Dictionary:
	if vertex_heights.size() != 6:
		# No vertex data — flat tile
		return { "y": tile_height, "normal": Vector3.UP }

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
			return { "y": y, "normal": n }

	# Fallback (point outside hex, shouldn't happen for valid placements)
	return { "y": tile_height, "normal": Vector3.UP }


## Rotate `prop` so its up-axis aligns with `surface_normal`.
## For tree/sapling assets the rotation is skipped so they stay vertical.
## The existing Y-rotation (random azimuth) is restored after tilting.
static func _apply_slope_rotation(
		prop:          Node3D,
		surface_normal: Vector3,
		path:          String,
		is_large:      bool
) -> void:
	# Trees always stay upright: skip slope rotation for sapling paths
	if is_large and (
			path.find("sapling") != -1 or
			path.find("fir_tree") != -1 or
			path.find("pine_tree") != -1
	):
		return

	# If the surface is essentially flat, skip the maths
	if surface_normal.distance_to(Vector3.UP) < 0.001:
		return

	# Build a rotation that maps Vector3.UP → surface_normal,
	# then additionally apply the already-set Y azimuth rotation.
	var current_y_rot := prop.rotation.y
	var tilt := Quaternion(Vector3.UP, surface_normal)
	prop.quaternion = tilt * Quaternion.from_euler(Vector3(0, current_y_rot, 0))


## Load (cache), pick a random child variant, apply calibrated scale.
## Returns null if the resource cannot be loaded.
static func _spawn_prop(path: String, rng: RandomNumberGenerator) -> Node3D:
	# Load / retrieve cached PackedScene
	if not _scene_cache.has(path):
		if not ResourceLoader.exists(path):
			_scene_cache[path] = null
		else:
			var res = load(path)
			_scene_cache[path] = res if res is PackedScene else null

	var scene: PackedScene = _scene_cache[path] as PackedScene
	if scene == null:
		return null

	# --- Requirement 4: Sub-node variant selection ----------------------------
	# Instantiate the full scene into a temporary holder, detach ONE variant,
	# reset its position (Quixel packs variants with X offsets), free the rest.
	var root: Node3D = scene.instantiate() as Node3D
	if root == null:
		return null

	var children: Array[Node] = root.get_children()
	var chosen: Node3D

	if children.is_empty():
		# Scene is a single mesh — use it directly
		chosen = root
		root = null
	else:
		var pick_idx: int = rng.randi() % children.size()
		var variant_node = children[pick_idx] as Node3D
		if variant_node == null:
			root.queue_free()
			return null

		root.remove_child(variant_node)
		variant_node.position = Vector3.ZERO  # clear inter-variant X offset
		root.queue_free()                      # frees all remaining siblings
		chosen = variant_node

	# --- Requirement 3: Calibrated 1:1 realistic scale with ±15 % jitter ------
	var scale_key := path.get_file()
	if DECO_SCALE.has(scale_key):
		var base_s: float = DECO_SCALE[scale_key]["base"]
		var jitter: float = rng.randf_range(-SCALE_JITTER, SCALE_JITTER)
		var s: float      = base_s * (1.0 + jitter)
		chosen.scale = Vector3(s, s, s)

	return chosen


## Weighted random pick from parallel pool + weights arrays.
static func _weighted_pick(
		pool:    Array,
		weights: Array,
		rng:     RandomNumberGenerator
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

	var roll: int      = rng.randi() % total
	var cumulative: int = 0
	for i in range(pool.size()):
		cumulative += int(weights[i])
		if roll < cumulative:
			return pool[i]
	return pool[pool.size() - 1]


## Random 2D position in the annular band [min_r, max_r] * hex_size.
## Returns Vector2.INF when no valid position found.
static func _random_outer_position(
		rng:       RandomNumberGenerator,
		hex_size:  float,
		min_r:     float,
		max_r:     float,
		max_tries: int = 10
) -> Vector2:
	var inner := hex_size * min_r
	var outer := hex_size * max_r

	for _t in range(max_tries):
		var angle  := rng.randf() * TAU
		var radius := rng.randf_range(inner, outer)
		var px     := cos(angle) * radius
		var pz     := sin(angle) * radius
		if _in_hex(px, pz, hex_size):
			return Vector2(px, pz)

	return Vector2.INF


## Position near one of the 6 hex corners (slightly inward from the edge).
static func _corner_position(rng: RandomNumberGenerator, hex_size: float) -> Vector2:
	var idx   := rng.randi() % 6
	var angle := deg_to_rad(60.0 * idx - 30.0)
	var r     := rng.randf_range(hex_size * 0.60, hex_size * 0.85)
	return Vector2(cos(angle) * r, sin(angle) * r)


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
