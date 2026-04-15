## Grass System — GodotGrass Blade-Shader Approach
## ============================================================================
## Uses individual blade meshes (grass_high.obj / grass_low.obj) with a GPU
## shader that handles wind, clumping, height variation, SSS, and view-space
## thickening.  Each biome gets its own ShaderMaterial with tuned colors,
## density, and wind parameters.
##
## Blade scale is 1:1 with the medieval knight (1.8 units).  The native blade
## mesh is 0.75 units tall; the shader's height_offset multiplier (0.4–2.0×)
## yields an effective range of 0.3–1.5 units, so grass is roughly ankle-to-
## waist height relative to a human-sized troop.
##
## PERFORMANCE
## -----------
## At HIGH quality, Plains biome spawns ~400 blades per hex.
## ~80 Plains tiles × 400 = 32,000 MultiMesh instances total.
## GodotGrass comfortably handles 100k+ blades, so this is well within budget.
## Shadows are OFF by default (huge GPU cost per GodotGrass docs).
class_name GrassSystem
extends RefCounted

# =============================================================================
# SETTINGS
# =============================================================================

static var grass_enabled: bool = true
static var grass_quality: int = 2  # 0=Off, 1=Low, 2=Medium, 3=High

# =============================================================================
# ASSET PATHS
# =============================================================================

const GRASS_SHADER_PATH := "res://assets/shaders/grass_shader.gdshader"
const GRASS_MESH_HIGH := "res://assets/grass/grass_high.obj"
const GRASS_MESH_LOW := "res://assets/grass/grass_low.obj"

# =============================================================================
# QUALITY → DENSITY MULTIPLIER
# =============================================================================
## Maps quality level to a fraction of the biome's base blade count.
## OFF=0 means no blades.  LOW uses the low-poly mesh with 25% density.

const QUALITY_CONFIG: Dictionary = {
	0: {"mult": 0.0,  "use_high_mesh": false},  # OFF
	1: {"mult": 0.25, "use_high_mesh": false},  # LOW  — grass_low.obj
	2: {"mult": 0.55, "use_high_mesh": true},   # MEDIUM — grass_high.obj
	3: {"mult": 1.0,  "use_high_mesh": true},   # HIGH — grass_high.obj
}

# =============================================================================
# PLACEMENT — Jitter-grid blade distribution within a hex
# =============================================================================

## Small Y lift above the tile surface so blades don't z-fight with terrain.
const SURFACE_OFFSET := 0.02

# =============================================================================
# BIOME CONFIGURATION
# =============================================================================
## Each entry controls density, distribution mode, colors, wind, and clumping
## for that biome's grass.

enum DistributionMode { UNIFORM, PATCHY }

const BIOME_GRASS_CONFIG: Dictionary = {
	# ---- Plains: Dense golden wheat-like fields ----------------------------
	Biomes.Type.PLAINS: {
		"enabled": true,
		"base_density": 600,  # blades per hex at quality 3 (+50% for shorter blades)
		"distribution": DistributionMode.UNIFORM,
		"base_color": Color(0.35, 0.28, 0.08),   # Golden brown
		"tip_color": Color(0.85, 0.75, 0.35),     # Golden yellow
		"sss_color": Color(1.0, 0.85, 0.3),       # Warm SSS
		"wind_speed": 0.9,
		"clumping_factor": 0.6,
		"brightness": 1.3,
	},

	# ---- Hills: Windswept highland grass -----------------------------------
	Biomes.Type.HILLS: {
		"enabled": true,
		"base_density": 420,
		"distribution": DistributionMode.UNIFORM,
		"base_color": Color(0.15, 0.30, 0.08),   # Cool green
		"tip_color": Color(0.55, 0.65, 0.30),     # Yellow-green
		"sss_color": Color(0.6, 0.8, 0.3),
		"wind_speed": 1.35,
		"clumping_factor": 0.4,
		"brightness": 1.2,
	},

	# ---- Forest: Sparse undergrowth, patchy gaps under tree canopy ---------
	Biomes.Type.FOREST: {
		"enabled": true,
		"base_density": 375,
		"distribution": DistributionMode.PATCHY,
		"patch_chance": 0.55,        # 55% of area has grass
		"patch_cluster_radius": 0.3, # cluster size as fraction of hex_size
		"base_color": Color(0.08, 0.18, 0.04),   # Dark moss
		"tip_color": Color(0.35, 0.40, 0.15),     # Olive
		"sss_color": Color(0.7, 0.5, 0.2),
		"wind_speed": 0.3,
		"clumping_factor": 0.7,
		"brightness": 1.1,
	},

	# ---- Swamp: Sparse, murky reed-like tufts in patches -------------------
	Biomes.Type.SWAMP: {
		"enabled": true,
		"base_density": 225,
		"distribution": DistributionMode.PATCHY,
		"patch_chance": 0.35,
		"patch_cluster_radius": 0.25,
		"base_color": Color(0.18, 0.20, 0.08),   # Murky dark
		"tip_color": Color(0.50, 0.45, 0.20),     # Brown-yellow
		"sss_color": Color(0.5, 0.4, 0.2),
		"wind_speed": 0.225,
		"clumping_factor": 0.8,
		"brightness": 1.0,
	},

	# ---- No grass biomes ---------------------------------------------------
	Biomes.Type.PEAKS: {"enabled": false},
	Biomes.Type.WASTES: {"enabled": false},
	Biomes.Type.ASHLANDS: {"enabled": false},
}

# =============================================================================
# CACHE
# =============================================================================

static var _grass_shader: Shader = null
static var _mesh_high: Mesh = null
static var _mesh_low: Mesh = null
static var _material_cache: Dictionary = {}  # keyed by biome type
static var _noise_cache: Dictionary = {}     # keyed by noise type string
static var _resources_loaded: bool = false

# =============================================================================
# PUBLIC API
# =============================================================================

static func set_grass_enabled(enabled: bool) -> void:
	grass_enabled = enabled

static func set_grass_quality(quality: int) -> void:
	grass_quality = clampi(quality, 0, 3)
	_material_cache.clear()

static func biome_has_grass(biome_type: Biomes.Type) -> bool:
	if not grass_enabled or grass_quality == 0:
		return false
	return BIOME_GRASS_CONFIG.get(biome_type, {}).get("enabled", false)

static func clear_cache() -> void:
	_grass_shader = null
	_mesh_high = null
	_mesh_low = null
	_material_cache.clear()
	_noise_cache.clear()
	_resources_loaded = false


## Create grass blades for a single hex tile.
## Returns a MultiMeshInstance3D with hundreds of blade instances, or null.
static func create_grass_for_hex(
		biome_type: Biomes.Type,
		hex_size: float = 1.0,
		vertex_heights: Array[float] = []
) -> MultiMeshInstance3D:
	if not grass_enabled or grass_quality == 0:
		return null

	if not biome_has_grass(biome_type):
		return null

	_ensure_resources_loaded()

	var config: Dictionary = BIOME_GRASS_CONFIG.get(biome_type, {})
	if config.is_empty() or not config.get("enabled", false):
		return null

	# --- Determine blade count from quality ---------------------------------
	var qcfg: Dictionary = QUALITY_CONFIG.get(grass_quality, QUALITY_CONFIG[2])
	var blade_count: int = int(config.get("base_density", 200) * qcfg.get("mult", 0.5))
	if blade_count <= 0:
		return null

	# --- Pick mesh (high or low poly) based on quality ----------------------
	var blade_mesh: Mesh = _mesh_high if qcfg.get("use_high_mesh", true) else _mesh_low
	if not blade_mesh:
		blade_mesh = _mesh_high if _mesh_high else _mesh_low
	if not blade_mesh:
		push_warning("[GrassSystem] No blade mesh loaded — cannot create grass")
		return null

	# --- Build MultiMesh ----------------------------------------------------
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = blade_mesh
	mm.instance_count = blade_count

	# --- Populate blade transforms ------------------------------------------
	var dist_mode: int = config.get("distribution", DistributionMode.UNIFORM)
	match dist_mode:
		DistributionMode.UNIFORM:
			_populate_uniform(mm, blade_count, hex_size, vertex_heights)
		DistributionMode.PATCHY:
			_populate_patchy(mm, blade_count, hex_size, vertex_heights, config)

	# --- Wrap in MultiMeshInstance3D ----------------------------------------
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Grass_%s" % Biomes.get_biome_name(biome_type)
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.material_override = _get_or_create_material(biome_type, config)

	return mmi


# =============================================================================
# PRIVATE — RESOURCE LOADING
# =============================================================================

static func _ensure_resources_loaded() -> void:
	if _resources_loaded:
		return
	_resources_loaded = true

	# Shader
	if ResourceLoader.exists(GRASS_SHADER_PATH):
		_grass_shader = load(GRASS_SHADER_PATH)

	# Blade meshes
	if ResourceLoader.exists(GRASS_MESH_HIGH):
		_mesh_high = load(GRASS_MESH_HIGH)
	if ResourceLoader.exists(GRASS_MESH_LOW):
		_mesh_low = load(GRASS_MESH_LOW)

	if not _mesh_high and not _mesh_low:
		push_warning("[GrassSystem] Could not load blade meshes from: %s / %s" % [GRASS_MESH_HIGH, GRASS_MESH_LOW])


# =============================================================================
# PRIVATE — MATERIAL
# =============================================================================

static func _get_or_create_material(biome_type: Biomes.Type, config: Dictionary) -> Material:
	var cache_key := str(biome_type) + "_q" + str(grass_quality)
	if _material_cache.has(cache_key):
		return _material_cache[cache_key]

	if _grass_shader:
		var mat := ShaderMaterial.new()
		mat.shader = _grass_shader

		# Noise textures
		mat.set_shader_parameter("clump_noise", _get_or_create_noise("clump"))
		mat.set_shader_parameter("wind_noise", _get_or_create_noise("wind"))

		# Per-biome colors
		mat.set_shader_parameter("base_color", config.get("base_color", Color(0.2, 0.38, 0.12)))
		mat.set_shader_parameter("tip_color", config.get("tip_color", Color(0.55, 0.55, 0.25)))
		mat.set_shader_parameter("subsurface_scattering_color", config.get("sss_color", Color(1.0, 0.85, 0.4)))

		# Per-biome wind & clumping
		mat.set_shader_parameter("clumping_factor", config.get("clumping_factor", 0.5))
		mat.set_shader_parameter("wind_speed", config.get("wind_speed", 1.0))
		mat.set_shader_parameter("brightness", config.get("brightness", 1.2))

		_material_cache[cache_key] = mat
		return mat

	# Fallback: plain green StandardMaterial3D
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = config.get("tip_color", Color(0.4, 0.7, 0.2))
	fallback.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material_cache[cache_key] = fallback
	return fallback


static func _get_or_create_noise(noise_type: String) -> NoiseTexture2D:
	if _noise_cache.has(noise_type):
		return _noise_cache[noise_type]

	var noise := FastNoiseLite.new()
	noise.seed = randi()

	if noise_type == "clump":
		noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	else:
		# Wind noise — matches GodotGrass mat_grass.tres
		noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
		noise.frequency = 0.0275
		noise.fractal_gain = 0.1
		noise.domain_warp_enabled = true
		noise.domain_warp_amplitude = 20.0
		noise.domain_warp_frequency = 0.005

	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.seamless = true
	tex.width = 256
	tex.height = 256

	_noise_cache[noise_type] = tex
	return tex


# =============================================================================
# PRIVATE — BLADE POPULATION (Transforms)
# =============================================================================

## Uniform distribution — jittered grid filling the hex.
## Used for Plains and Hills where grass covers the whole tile evenly.
static func _populate_uniform(
		multi_mesh: MultiMesh,
		count: int,
		hex_size: float,
		vertex_heights: Array[float]
) -> void:
	var placed := 0
	var max_attempts := count * 3

	for _attempt in range(max_attempts):
		if placed >= count:
			break

		# Random polar position within hex
		var angle := randf() * TAU
		var radius := sqrt(randf()) * hex_size * 0.95
		var px := cos(angle) * radius
		var pz := sin(angle) * radius

		if not _in_hex(px, pz, hex_size):
			continue

		var y := _get_surface_height(px, pz, vertex_heights, hex_size) + SURFACE_OFFSET

		var xform := Transform3D()
		xform.origin = Vector3(px, y, pz)
		multi_mesh.set_instance_transform(placed, xform)
		placed += 1

	# Zero out any remaining (shouldn't happen with 3× attempts)
	for i in range(placed, count):
		multi_mesh.set_instance_transform(i, Transform3D().scaled(Vector3.ZERO))


## Patchy distribution — grass grows in clusters with bare gaps between.
## Used for Forest (gaps under tree canopy) and Swamp (isolated tufts).
static func _populate_patchy(
		multi_mesh: MultiMesh,
		count: int,
		hex_size: float,
		vertex_heights: Array[float],
		config: Dictionary
) -> void:
	var patch_chance: float = config.get("patch_chance", 0.5)
	var cluster_radius: float = config.get("patch_cluster_radius", 0.25) * hex_size

	# Generate patch centers
	var num_patches := maxi(int(count * 0.08), 3)
	var patch_centers: Array[Vector3] = []
	for _p in range(num_patches):
		var angle := randf() * TAU
		var radius := sqrt(randf()) * hex_size * 0.85
		var px := cos(angle) * radius
		var pz := sin(angle) * radius
		if _in_hex(px, pz, hex_size):
			var py := _get_surface_height(px, pz, vertex_heights, hex_size) + SURFACE_OFFSET
			patch_centers.append(Vector3(px, py, pz))

	if patch_centers.is_empty():
		# Fallback: center patch
		var cy := _get_surface_height(0.0, 0.0, vertex_heights, hex_size) + SURFACE_OFFSET
		patch_centers.append(Vector3(0, cy, 0))

	var placed := 0
	var max_attempts := count * 5

	for _attempt in range(max_attempts):
		if placed >= count:
			break

		# Decide: place near a random patch center, or skip (bare ground)
		if randf() > patch_chance:
			# Bare spot — skip this candidate
			continue

		var center: Vector3 = patch_centers[randi() % patch_centers.size()]

		# Offset within cluster
		var off_angle := randf() * TAU
		var off_dist := randf() * cluster_radius
		var px := center.x + cos(off_angle) * off_dist
		var pz := center.z + sin(off_angle) * off_dist

		if not _in_hex(px, pz, hex_size):
			continue

		var y := _get_surface_height(px, pz, vertex_heights, hex_size) + SURFACE_OFFSET

		var xform := Transform3D()
		xform.origin = Vector3(px, y, pz)
		multi_mesh.set_instance_transform(placed, xform)
		placed += 1

	# Zero out remaining instances
	for i in range(placed, count):
		multi_mesh.set_instance_transform(i, Transform3D().scaled(Vector3.ZERO))


# =============================================================================
# PRIVATE — HEX GEOMETRY HELPERS
# =============================================================================

## Pointy-top hex containment test (matches ForestDecorationSystem._in_hex).
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


## Get interpolated surface height at a local XZ position on the hex.
## Uses the 6-corner fan triangulation (center + 6 corners) with barycentric
## interpolation.  Falls back to 0.0 if no vertex heights are provided.
static func _get_surface_height(
		px: float,
		pz: float,
		vertex_heights: Array[float],
		hex_size: float
) -> float:
	if vertex_heights.size() != 6:
		return 0.0

	# Build corners
	var corners: Array[Vector3] = []
	for i in range(6):
		var angle := deg_to_rad(60 * i - 30)
		corners.append(Vector3(
			hex_size * cos(angle),
			vertex_heights[i],
			hex_size * sin(angle)
		))

	# Center = average of corners
	var center_y: float = 0.0
	for h in vertex_heights:
		center_y += h
	center_y /= 6.0
	var center := Vector3(0, center_y, 0)

	# Test each of the 6 fan triangles (center, corner[i], corner[i+1])
	for i in range(6):
		var a := center
		var b := corners[i]
		var c := corners[(i + 1) % 6]

		# Barycentric in XZ
		var v0 := Vector2(c.x - a.x, c.z - a.z)
		var v1 := Vector2(b.x - a.x, b.z - a.z)
		var v2 := Vector2(px - a.x, pz - a.z)

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
			return a.y + u * (c.y - a.y) + v * (b.y - a.y)

	# Fallback — should not reach here for points inside the hex
	return center_y
