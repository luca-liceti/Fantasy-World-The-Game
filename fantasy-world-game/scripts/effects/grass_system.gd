## Grass System - GLB Mesh Based
## Uses GLB meshes with MultiMeshInstance3D for realistic grass clumps
## Features: World-space wind, terrain blending, SSS, slope alignment, biome-specific colors
class_name GrassSystem
extends RefCounted

# =============================================================================
# SETTINGS
# =============================================================================

static var grass_enabled: bool = true
static var grass_quality: int = 3
static var player_position: Vector3 = Vector3.ZERO

# =============================================================================
# CONSTANTS
# =============================================================================

const GRASS_SHADER_PATH := "res://assets/shaders/grass_shader.gdshader"

const GRASS_GLB_PATH := "res://assets/models/enviroment/forest/optimized_assets/grass_medium_01_2k_opt.glb"

const GRASS_TEXTURE := "res://assets/models/enviroment/forest/textures/grass_medium_01_diff_2k.jpg"
const FALLBACK_TEXTURE := "res://assets/models/enviroment/forest/textures/grass_medium_01_diff_2k.jpg"

## Biome-specific grass textures (using same texture for now)
const GRASS_TEXTURES: Dictionary = {
	Biomes.Type.PLAINS: GRASS_TEXTURE,
	Biomes.Type.HILLS: GRASS_TEXTURE,
	Biomes.Type.FOREST: GRASS_TEXTURE,
	Biomes.Type.SWAMP: GRASS_TEXTURE,
}

const GRASS_DENSITY_BY_QUALITY: Dictionary = {
	0: 0,
	1: 30,
	2: 50,
	3: 80
}

## Clump dimensions - proportional to knight (1.8 units = 100%)
## Grass should be ~6% of knight height = ~10-12cm
const CLUMP_WIDTH := 0.10     # 10cm wide clump
const CLUMP_HEIGHT := 0.12    # 12cm tall

## GLB mesh scale multiplier (meshes are ~0.5-1m, scale to ~10-15cm)
const GLB_SCALE := 0.15

## Surface offset to place grass on top of tile (matches tree placement)
const SURFACE_OFFSET := 0.02

## Distribution
const SPAWN_RADIUS := 1.0
const SCALE_VARIATION := 0.4  # Random size variation for natural look

# =============================================================================
# BIOME CONFIGURATION - Manor Lords Style
# =============================================================================

enum GrassType { NONE, MEADOW, HILLS_GRASS, FOREST_FLOOR, SWAMP_REEDS }
enum DistributionMode { UNIFORM, PATCHY, SPARSE_RANDOM }

const BIOME_GRASS_CONFIG: Dictionary = {
	# Plains: Golden wheat fields
	Biomes.Type.PLAINS: {
		"enabled": true,
		"type": GrassType.MEADOW,
		"distribution": DistributionMode.UNIFORM,
		"density_mult": 1.8,
		"base_color": Color(0.6, 0.5, 0.2),   # Golden brown base
		"tip_color": Color(0.95, 0.85, 0.5),  # Golden yellow tip
		"color_tint": Color(0.95, 0.85, 0.5), # Golden tint override
		"color_variation": 0.12,
		"terrain_color": Color(0.12, 0.10, 0.07),
		"terrain_blend": 0.25,
		"height_scale": 1.0,
		"width_scale": 1.0,
		"wind_strength": 0.10,
		"wind_speed": 0.7,
		"sss_strength": 0.40,
		"sss_color": Color(0.8, 0.7, 0.3),  # Golden SSS
	},
	
	# Hills: Windswept highland grass
	Biomes.Type.HILLS: {
		"enabled": true,
		"type": GrassType.HILLS_GRASS,
		"distribution": DistributionMode.UNIFORM,
		"density_mult": 1.4,
		"color_tint": Color(0.82, 0.88, 0.60),  # Yellow-green tint
		"color_variation": 0.18,
		"terrain_color": Color(0.14, 0.12, 0.08),
		"terrain_blend": 0.20,
		"height_scale": 0.75,          # Shorter due to wind exposure
		"width_scale": 1.1,
		"wind_strength": 0.16,         # Stronger wind
		"wind_speed": 1.0,
		"sss_strength": 0.35,
		"sss_color": Color(0.55, 0.70, 0.30),
	},
	
	Biomes.Type.FOREST: {
		"enabled": true,
		"type": GrassType.FOREST_FLOOR,
		"distribution": DistributionMode.UNIFORM,
		"density_mult": 1.0,
		"base_color": Color(0.15, 0.25, 0.1),   # Muted forest green
		"tip_color": Color(0.45, 0.45, 0.2),  # Golden hour olive
		"color_variation": 0.15,
		"terrain_color": Color(0.08, 0.06, 0.04),
		"terrain_blend": 0.35,
		"height_scale": 1.0,
		"width_scale": 1.0,
		"wind_strength": 0.08,
		"wind_speed": 0.5,
		"sss_strength": 0.50,   # Muted SSS
		"sss_color": Color(0.8, 0.6, 0.3),  # Golden muted SSS
	},
	
	# Swamp: Patchy reeds and dead grass
	Biomes.Type.SWAMP: {
		"enabled": true,
		"type": GrassType.SWAMP_REEDS,
		"distribution": DistributionMode.PATCHY,
		"density_mult": 0.6,
		"patch_chance": 0.35,          # 35% of area has grass patches
		"patch_cluster_size": 0.25,    # Size of each patch cluster
		"color_tint": Color(0.80, 0.72, 0.50),  # Brown-yellow tint
		"color_variation": 0.25,
		"terrain_color": Color(0.10, 0.09, 0.05),
		"terrain_blend": 0.30,
		"height_scale": 1.4,           # Tall reeds
		"width_scale": 0.85,
		"wind_strength": 0.06,
		"wind_speed": 0.5,
		"sss_strength": 0.25,
		"sss_color": Color(0.60, 0.55, 0.35),
	},
	
	Biomes.Type.PEAKS: {"enabled": false, "type": GrassType.NONE},
	Biomes.Type.WASTES: {"enabled": false, "type": GrassType.NONE},
	Biomes.Type.ASHLANDS: {"enabled": false, "type": GrassType.NONE}
}

# =============================================================================
# CACHE
# =============================================================================

static var _grass_shader: Shader = null
static var _texture_cache: Dictionary = {}
static var _resources_loaded: bool = false
static var _quad_mesh: ArrayMesh = null
static var _material_cache: Dictionary = {}
static var _glb_meshes: Array[Mesh] = []
static var _glb_loaded: bool = false

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
	_texture_cache.clear()
	_resources_loaded = false
	_quad_mesh = null
	_material_cache.clear()
	_noise_texture_cache.clear()
	_glb_meshes.clear()
	_glb_loaded = false


## Create grass for a hex tile
## Optionally pass vertex_heights (Array of 6 floats) and tile_height for slope-aligned grass
static func create_grass_for_hex(biome_type: Biomes.Type, hex_size: float = 1.0, vertex_heights: Array[float] = []) -> MultiMeshInstance3D:
	if not grass_enabled:
		print("[GrassSystem] grass_enabled = false")
		return null
	
	if grass_quality == 0:
		print("[GrassSystem] grass_quality = 0")
		return null
	
	if not biome_has_grass(biome_type):
		print("[GrassSystem] biome_has_grass returned false for biome: %s" % str(biome_type))
		return null
	
	_ensure_resources_loaded()
	
	var config: Dictionary = BIOME_GRASS_CONFIG.get(biome_type, {})
	if config.is_empty():
		print("[GrassSystem] config is empty for biome: %s" % str(biome_type))
		return null
	
	var density: int = GRASS_DENSITY_BY_QUALITY.get(grass_quality, 0)
	if density == 0:
		print("[GrassSystem] density is 0")
		return null
	
	print("[GrassSystem] Creating grass for biome %s with density %d" % [str(biome_type), density])
	
	var mm_instance := MultiMeshInstance3D.new()
	mm_instance.name = "Grass_%s" % Biomes.get_biome_name(biome_type)
	
	# Get mesh from GLB (fallback to quad if GLB not loaded)
	var grass_mesh: Mesh = _get_glb_mesh()
	if not grass_mesh:
		grass_mesh = _get_cross_quad_mesh(
			config.get("width_scale", 1.0),
			config.get("height_scale", 1.0)
		)
	
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = grass_mesh
	mm.instance_count = density
	
	# Calculate surface tilt from vertex_heights (like ForestDecorationSystem does)
	var surface_normal := Vector3.UP
	if vertex_heights.size() == 6:
		surface_normal = _calculate_surface_normal(vertex_heights, hex_size)
	
	var dist_mode: DistributionMode = config.get("distribution", DistributionMode.UNIFORM)
	match dist_mode:
		DistributionMode.UNIFORM:
			_populate_uniform_clumps(mm, density, hex_size, config.get("height_scale", 1.0), vertex_heights)
		DistributionMode.PATCHY:
			_populate_patchy_clumps(mm, density, hex_size, config.get("height_scale", 1.0), config, vertex_heights)
		DistributionMode.SPARSE_RANDOM:
			_populate_sparse_clumps(mm, density, hex_size, config.get("height_scale", 1.0), vertex_heights)
	
	mm_instance.multimesh = mm
	
	var mat: Material = _get_or_create_material(biome_type, config)
	mm_instance.material_override = mat
	
	return mm_instance


# =============================================================================
# PRIVATE - RESOURCE LOADING
# =============================================================================

static func _ensure_resources_loaded() -> void:
	if _resources_loaded:
		return
	
	_resources_loaded = true
	
	# Load shader
	if ResourceLoader.exists(GRASS_SHADER_PATH):
		_grass_shader = load(GRASS_SHADER_PATH)
	
	# Load GLB meshes
	_load_glb_meshes()
	
	# Setup global shader parameters for grass crushing (only if shader defines them)
	# Skip for now - these parameters must be defined in project settings

static func _load_glb_meshes() -> void:
	if _glb_loaded:
		return
	
	if not ResourceLoader.exists(GRASS_GLB_PATH):
		push_warning("[GrassSystem] GLB file not found: " + GRASS_GLB_PATH)
		return
	
	var gltf = GLTFDocument.new()
	var state = GLTFState.new()
	
	var err = gltf.append_from_file(GRASS_GLB_PATH, state)
	if err != OK:
		push_warning("[GrassSystem] Failed to load GLB: " + GRASS_GLB_PATH)
		return
	
	var doc_root = gltf.generate_scene(state, 0)
	if not doc_root:
		push_warning("[GrassSystem] Failed to generate scene from GLB")
		return
	
	# Collect all meshes from the GLB
	var mesh_nodes: Array[Node3D] = []
	_collect_mesh_nodes(doc_root, mesh_nodes)
	
	for node in mesh_nodes:
		if node is MeshInstance3D:
			var mesh = node.mesh
			if mesh:
				_glb_meshes.append(mesh)
	
	_glb_loaded = true
	print("[GrassSystem] Loaded %d meshes from GLB" % _glb_meshes.size())

static func _collect_mesh_nodes(node: Node, result: Array[Node3D]) -> void:
	if node is MeshInstance3D:
		result.append(node as Node3D)
	for child in node.get_children():
		_collect_mesh_nodes(child, result)

static func _get_glb_mesh() -> Mesh:
	if _glb_meshes.is_empty():
		return null
	# Return a random mid-size mesh (MID or SMALL variants for variety)
	# Use simplified selection - prefer mid/small count meshes
	var candidates: Array[Mesh] = []
	
	for m in _glb_meshes:
		if m is ArrayMesh:
			candidates.append(m)
	
	if candidates.is_empty():
		return _glb_meshes[randi() % _glb_meshes.size()]
	
	# Pick random from candidates
	return candidates[randi() % candidates.size()]

static func _get_texture_for_biome(biome_type: Biomes.Type) -> Texture2D:
	if _texture_cache.has(biome_type):
		return _texture_cache[biome_type]
	
	var texture_path = GRASS_TEXTURES.get(biome_type, "")
	if texture_path != "" and ResourceLoader.exists(texture_path):
		var tex = load(texture_path)
		_texture_cache[biome_type] = tex
		return tex
	
	if ResourceLoader.exists(FALLBACK_TEXTURE):
		var tex = load(FALLBACK_TEXTURE)
		_texture_cache[biome_type] = tex
		return tex
	
	return null

static var _noise_texture_cache: Dictionary = {}

static func _get_or_create_noise_texture(noise_type: String) -> Texture2D:
	if _noise_texture_cache.has(noise_type):
		return _noise_texture_cache[noise_type]
	
	var noise := FastNoiseLite.new()
	noise.seed = randi()
	
	if noise_type == "clump":
		noise.noise_type = FastNoiseLite.TYPE_PERLIN
		noise.frequency = 0.02
	else:
		noise.noise_type = FastNoiseLite.TYPE_PERLIN
		noise.frequency = 0.0275
		noise.fractal_gain = 0.1
		noise.domain_warp_enabled = true
		noise.domain_warp_amplitude = 20.0
		noise.domain_warp_frequency = 0.005
	
	var noise_tex := NoiseTexture2D.new()
	noise_tex.noise = noise
	noise_tex.seamless = true
	noise_tex.width = 256
	noise_tex.height = 256
	
	_noise_texture_cache[noise_type] = noise_tex
	return noise_tex

static func update_player_position(pos: Vector3) -> void:
	player_position = pos
	RenderingServer.global_shader_parameter_set("player_position", pos)


## Calculate surface normal from vertex heights (matches ForestDecorationSystem approach)
static func _calculate_surface_normal(vertex_heights: Array[float], hex_size: float) -> Vector3:
	var corners: Array[Vector3] = []
	for i in range(6):
		var angle = deg_to_rad(60 * i - 30)
		corners.append(Vector3(hex_size * cos(angle), vertex_heights[i], hex_size * sin(angle)))
	
	var center = Vector3.ZERO
	for c in corners:
		center += c
	center /= 6.0
	
	var normal := Vector3.ZERO
	for i in range(6):
		var c1 = corners[i]
		var c2 = corners[(i + 1) % 6]
		var edge = c2 - c1
		var to_center = center - c1
		normal += edge.cross(to_center).normalized()
	
	return normal.normalized()


## Get height at a given XZ position on the hex surface (matches ForestDecorationSystem)
static func _get_surface_height_at(pos: Vector2, vertex_heights: Array[float], hex_size: float) -> float:
	if vertex_heights.size() != 6:
		return 0.0
	
	var corners: Array[Vector3] = []
	for i in range(6):
		var angle = deg_to_rad(60 * i - 30)
		corners.append(Vector3(hex_size * cos(angle), vertex_heights[i], hex_size * sin(angle)))
	
	var center = Vector3.ZERO
	for c in corners:
		center += c
	center /= 6.0
	
	var p = Vector3(pos.x, 0, pos.y)
	var heights: Array[float] = []
	var tris = [
		[0, 1, 2], [0, 2, 3], [0, 3, 4], [0, 4, 5], [0, 5, 1]
	]
	for tri in tris:
		var a = corners[tri[0]]
		var b = corners[tri[1]]
		var c = corners[tri[2]]
		var ab = b - a
		var ac = c - a
		var ap = p - a
		var denom = ab.x * ac.z - ab.z * ac.x
		if abs(denom) < 0.0001:
			continue
		var u = (ap.x * ac.z - ap.z * ac.x) / denom
		var v = (ab.x * ap.z - ab.z * ap.x) / denom
		if u >= 0 and v >= 0 and u + v <= 1:
			var h = a.y + u * (b.y - a.y) + v * (c.y - a.y)
			return h
	
	return center.y


# =============================================================================
# PRIVATE - MESH GENERATION (Grass Blade)
# =============================================================================

## Load grass blade mesh (imported as Mesh, not PackedScene)
static func _load_grass_blade_mesh(high_quality: bool = true) -> Mesh:
	var mesh_path := "res://assets/models/enviroment/forest/grass_high.obj" if high_quality else "res://assets/models/enviroment/forest/grass_low.obj"
	if ResourceLoader.exists(mesh_path):
		var mesh = load(mesh_path)
		if mesh is Mesh:
			return mesh
	return null

## Create a grass blade mesh (uses 3D obj files from GodotGrass)
static func _get_cross_quad_mesh(width_mult: float = 1.0, height_mult: float = 1.0) -> ArrayMesh:
	var blade_mesh = _load_grass_blade_mesh(grass_quality >= 2)
	if blade_mesh:
		if blade_mesh is ArrayMesh:
			return blade_mesh as ArrayMesh
		var array_mesh := ArrayMesh.new()
		array_mesh.add_mesh(blade_mesh)
		return array_mesh
	
	var mesh := ArrayMesh.new()
	var hw := CLUMP_WIDTH * 0.5 * width_mult
	var h := CLUMP_HEIGHT * height_mult
	
	var verts := PackedVector3Array([
		Vector3(-hw * 0.5, 0, 0),
		Vector3(hw * 0.5, 0, 0),
		Vector3(0, h, 0),
	])
	
	var normals := PackedVector3Array([
		Vector3(0, 0, 1),
		Vector3(0, 0, 1),
		Vector3(0, 0, 1),
	])
	
	var uvs := PackedVector2Array([
		Vector2(0, 1),
		Vector2(1, 1),
		Vector2(0.5, 0),
	])
	
	var indices := PackedInt32Array([0, 1, 2])
	
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	return mesh


# =============================================================================
# PRIVATE - MATERIAL
# =============================================================================

static func _get_or_create_material(biome_type: Biomes.Type, config: Dictionary) -> Material:
	var cache_key = str(biome_type) + "_" + str(grass_quality)
	if _material_cache.has(cache_key):
		return _material_cache[cache_key]
	
	var texture = _get_texture_for_biome(biome_type)
	
	if _grass_shader:
		var mat := ShaderMaterial.new()
		mat.shader = _grass_shader
		
		# Noise textures (create if not exist)
		mat.set_shader_parameter("clump_noise", _get_or_create_noise_texture("clump"))
		mat.set_shader_parameter("wind_noise", _get_or_create_noise_texture("wind"))
		
		# Color - GodotGrass explicit base_color and tip_color
		if config.has("base_color") and config.has("tip_color"):
			mat.set_shader_parameter("base_color", config.get("base_color"))
			mat.set_shader_parameter("tip_color", config.get("tip_color"))
		else:
			var tint_color: Color = config.get("color_tint", Color(0.55, 0.70, 0.45))
			mat.set_shader_parameter("base_color", Color(tint_color.r * 0.1, tint_color.g * 0.3, tint_color.b * 0.05))
			mat.set_shader_parameter("tip_color", tint_color)
		
		# Clumping factor
		mat.set_shader_parameter("clumping_factor", 0.5)
		
		# Wind speed
		mat.set_shader_parameter("wind_speed", config.get("wind_speed", 0.7))
		
		# SSS
		mat.set_shader_parameter("subsurface_scattering_color", config.get("sss_color", Color(1.0, 0.75, 0.1)))
		
		# Brightness
		mat.set_shader_parameter("brightness", 1.5)
		
		_material_cache[cache_key] = mat
		return mat
	
	# Fallback: Simple green material (always visible)
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = Color(0.4, 0.7, 0.2)  # Bright green color
	fallback.cull_mode = BaseMaterial3D.CULL_DISABLED
	fallback.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	fallback.vertex_color_use_as_albedo = true
	_material_cache[cache_key] = fallback
	return fallback


# =============================================================================
# PRIVATE - INSTANCE POPULATION (Various Distribution Modes)
# =============================================================================

## Uniform distribution - for plains and hills (dense, even coverage)
static func _populate_uniform_clumps(multi_mesh: MultiMesh, count: int, hex_size: float, height_scale: float, vertex_heights: Array[float] = []) -> void:
	var spawn_radius := hex_size * SPAWN_RADIUS
	
	for i in range(count):
		# Random position in hex
		var pos := Vector3.ZERO
		var attempts := 0
		while attempts < 10:
			var angle := randf() * TAU
			var radius := sqrt(randf()) * spawn_radius
			pos.x = cos(angle) * radius
			pos.z = sin(angle) * radius
			
			var in_hex_x: bool = abs(pos.x) <= hex_size * 0.866
			var in_hex_z: bool = abs(pos.z) <= hex_size * 0.95
			if in_hex_x and in_hex_z:
				break
			attempts += 1
		
		# Get height at this position from the sloped surface (matches tree placement)
		var surface_y := 0.0
		if vertex_heights.size() == 6:
			surface_y = _get_surface_height_at(Vector2(pos.x, pos.z), vertex_heights, hex_size) + SURFACE_OFFSET
		else:
			surface_y = pos.y
		
		# Random Y-axis rotation (critical for varied look)
		var rotation := randf() * TAU
		
		# GLB mesh scale (base GLB_SCALE with variation)
		var base_scale := GLB_SCALE * (0.8 + randf() * 0.4)
		var scale_x := base_scale
		var scale_y := base_scale * height_scale
		
		# Grass stays upright (vertical)
		var xform := Transform3D()
		xform = xform.rotated(Vector3.UP, rotation)
		xform = xform.scaled(Vector3(scale_x, scale_y, scale_x))
		xform.origin = Vector3(pos.x, surface_y, pos.z)
		
		multi_mesh.set_instance_transform(i, xform)


## Patchy distribution - for swamp (clusters with gaps)
static func _populate_patchy_clumps(multi_mesh: MultiMesh, count: int, hex_size: float, height_scale: float, config: Dictionary, vertex_heights: Array[float] = []) -> void:
	var spawn_radius := hex_size * SPAWN_RADIUS
	var patch_chance: float = config.get("patch_chance", 0.35)
	var cluster_size: float = config.get("patch_cluster_size", 0.25)
	
	# Generate patch centers using noise
	var patch_centers: Array[Vector3] = []
	var num_patches := int(count * patch_chance * 0.15)  # Few large patches
	num_patches = maxi(num_patches, 3)
	
	for p in range(num_patches):
		var angle := randf() * TAU
		var radius := sqrt(randf()) * spawn_radius * 0.8
		var px := cos(angle) * radius
		var pz := sin(angle) * radius
		var py := 0.0
		if vertex_heights.size() == 6:
			py = _get_surface_height_at(Vector2(px, pz), vertex_heights, hex_size) + SURFACE_OFFSET
		patch_centers.append(Vector3(px, py, pz))
	
	var placed := 0
	var max_attempts := count * 5
	var attempts := 0
	
	while placed < count and attempts < max_attempts:
		attempts += 1
		
		# Pick a random patch center
		var patch_center: Vector3 = patch_centers[randi() % patch_centers.size()]
		
		# Generate position near patch center
		var offset_angle := randf() * TAU
		var offset_dist := randf() * hex_size * cluster_size
		var pos := patch_center + Vector3(
			cos(offset_angle) * offset_dist,
			0,
			sin(offset_angle) * offset_dist
		)
		
		# Check if in hex bounds
		var in_hex_x: bool = abs(pos.x) <= hex_size * 0.866
		var in_hex_z: bool = abs(pos.z) <= hex_size * 0.95
		if not (in_hex_x and in_hex_z):
			continue
		
		# Get height at this position from the sloped surface (matches tree placement)
		var surface_y := 0.0
		if vertex_heights.size() == 6:
			surface_y = _get_surface_height_at(Vector2(pos.x, pos.z), vertex_heights, hex_size) + SURFACE_OFFSET
		else:
			surface_y = pos.y
		
		# Random Y-axis rotation
		var rotation := randf() * TAU
		
		# GLB mesh scale - reeds are taller
		var base_scale := GLB_SCALE * (1.0 + randf() * 0.6)
		var scale_x := base_scale * 0.85
		var scale_y := base_scale * height_scale * (0.8 + randf() * 0.4)
		
		# Reeds stay upright - position already accounts for slope
		var xform := Transform3D()
		xform = xform.rotated(Vector3.UP, rotation)
		xform = xform.scaled(Vector3(scale_x, scale_y, scale_x))
		xform.origin = Vector3(pos.x, surface_y, pos.z)
		
		multi_mesh.set_instance_transform(placed, xform)
		placed += 1
	
	# Zero out any remaining instances
	for i in range(placed, count):
		multi_mesh.set_instance_transform(i, Transform3D().scaled(Vector3.ZERO))


## Sparse random distribution - for forest (scattered, irregular)
static func _populate_sparse_clumps(multi_mesh: MultiMesh, count: int, hex_size: float, height_scale: float, vertex_heights: Array[float] = []) -> void:
	var spawn_radius := hex_size * SPAWN_RADIUS
	
	for i in range(count):
		# Use noise-like distribution (more clustered but with gaps)
		var pos := Vector3.ZERO
		var attempts := 0
		var valid := false
		
		while attempts < 15 and not valid:
			var angle := randf() * TAU
			var radius := sqrt(randf()) * spawn_radius
			pos.x = cos(angle) * radius
			pos.z = sin(angle) * radius
			
			# Use simple noise to create sparse areas
			var noise_val := sin(pos.x * 5.0) * cos(pos.z * 5.0)
			if noise_val > -0.3:  # Skip some areas based on noise
				var in_hex_x: bool = abs(pos.x) <= hex_size * 0.866
				var in_hex_z: bool = abs(pos.z) <= hex_size * 0.95
				if in_hex_x and in_hex_z:
					valid = true
			attempts += 1
		
		if not valid:
			# Hide this instance
			multi_mesh.set_instance_transform(i, Transform3D().scaled(Vector3.ZERO))
			continue
		
		# Get height at this position from the sloped surface (matches tree placement)
		var surface_y := pos.y
		if vertex_heights.size() == 6:
			surface_y = _get_surface_height_at(Vector2(pos.x, pos.z), vertex_heights, hex_size) + SURFACE_OFFSET
		
		# Random Y-axis rotation
		var rotation := randf() * TAU
		
		# GLB mesh scale - ferns are wider and shorter
		var base_scale := GLB_SCALE * (0.9 + randf() * 0.5)
		var scale_x := base_scale * 1.2
		var scale_y := base_scale * height_scale
		
		# Ferns/grass stay upright - position already accounts for slope
		var xform := Transform3D()
		xform = xform.rotated(Vector3.UP, rotation)
		xform = xform.scaled(Vector3(scale_x, scale_y, scale_x))
		xform.origin = Vector3(pos.x, surface_y, pos.z)
		
		multi_mesh.set_instance_transform(i, xform)
