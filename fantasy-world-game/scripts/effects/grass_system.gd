## Grass System - Manor Lords Quality
## Uses textured cross-quads with alpha for realistic grass clumps
## Features: World-space wind, terrain blending, SSS, LOD, biome-specific textures
class_name GrassSystem
extends RefCounted

# =============================================================================
# SETTINGS
# =============================================================================

static var grass_enabled: bool = true
static var grass_quality: int = 2  # 0=Off, 1=Low, 2=Medium, 3=High

# =============================================================================
# CONSTANTS
# =============================================================================

const GRASS_SHADER_PATH := "res://assets/shaders/grass_shader.gdshader"

## Biome-specific grass textures
const GRASS_TEXTURES: Dictionary = {
	Biomes.Type.PLAINS: "res://assets/textures/effects/grass_plains.png",
	Biomes.Type.HILLS: "res://assets/textures/effects/grass_hills.png",
	Biomes.Type.FOREST: "res://assets/textures/effects/grass_forest.png",
	Biomes.Type.SWAMP: "res://assets/textures/effects/grass_swamp.png",
}
const FALLBACK_TEXTURE_PATH := "res://assets/textures/effects/grass_clump.png"

## Grass clumps per hex by quality - REDUCED for tabletop scale
const GRASS_DENSITY_BY_QUALITY: Dictionary = {
	0: 0,
	1: 20,     # Low - very sparse
	2: 40,     # Medium - light coverage
	3: 80      # High - modest density
}

## Clump dimensions - TABLETOP MINIATURE SCALE
## These are tiny grass clumps for a board game, not real grass
const CLUMP_WIDTH := 0.035    # 3.5cm wide clump (miniature scale)
const CLUMP_HEIGHT := 0.025   # 2.5cm tall (very short for tabletop)

## Distribution
const SPAWN_RADIUS := 0.92
const SCALE_VARIATION := 0.3  # Random size variation

# =============================================================================
# BIOME CONFIGURATION - Manor Lords Style
# =============================================================================

enum GrassType { NONE, MEADOW, HILLS_GRASS, FOREST_FLOOR, SWAMP_REEDS }
enum DistributionMode { UNIFORM, PATCHY, SPARSE_RANDOM }

const BIOME_GRASS_CONFIG: Dictionary = {
	# Plains: Dense dark green meadow - Manor Lords style
	Biomes.Type.PLAINS: {
		"enabled": true,
		"type": GrassType.MEADOW,
		"distribution": DistributionMode.UNIFORM,
		"density_mult": 1.8,           # Very dense coverage
		"color_tint": Color(0.75, 0.85, 0.65),   # Dark green tint
		"color_variation": 0.12,
		"terrain_color": Color(0.12, 0.10, 0.07),
		"terrain_blend": 0.25,
		"height_scale": 1.0,
		"width_scale": 1.0,
		"wind_strength": 0.10,
		"wind_speed": 0.7,
		"sss_strength": 0.40,
		"sss_color": Color(0.45, 0.65, 0.25),
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
	
	# Forest: Sparse dark undergrowth/ferns
	Biomes.Type.FOREST: {
		"enabled": true,
		"type": GrassType.FOREST_FLOOR,
		"distribution": DistributionMode.SPARSE_RANDOM,
		"density_mult": 0.5,           # Sparse coverage
		"color_tint": Color(0.55, 0.70, 0.45),  # Dark forest green
		"color_variation": 0.20,
		"terrain_color": Color(0.08, 0.06, 0.04),
		"terrain_blend": 0.35,
		"height_scale": 0.5,           # Short undergrowth
		"width_scale": 1.3,            # Wider fern-like spread
		"wind_strength": 0.03,         # Sheltered - minimal wind
		"wind_speed": 0.4,
		"sss_strength": 0.20,
		"sss_color": Color(0.35, 0.55, 0.20),
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


## Create grass for a hex tile
static func create_grass_for_hex(biome_type: Biomes.Type, hex_size: float = 1.0) -> MultiMeshInstance3D:
	if not grass_enabled or grass_quality == 0:
		return null
	
	var config = BIOME_GRASS_CONFIG.get(biome_type, {})
	if not config.get("enabled", false):
		return null
	
	# Load resources if needed
	_ensure_resources_loaded()
	
	var grass_instance := MultiMeshInstance3D.new()
	grass_instance.name = "GrassClumps"
	
	# Get cross-quad mesh with biome-specific dimensions
	var height_scale: float = config.get("height_scale", 1.0)
	var width_scale: float = config.get("width_scale", 1.0)
	var mesh = _get_cross_quad_mesh(width_scale, height_scale)
	
	# Create MultiMesh
	var multi_mesh := MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.mesh = mesh
	
	# Calculate clump count
	var base_density: int = GRASS_DENSITY_BY_QUALITY.get(grass_quality, 150)
	var density_mult: float = config.get("density_mult", 1.0)
	var hex_area: float = hex_size * hex_size * 2.6
	var clump_count := int(base_density * density_mult * hex_area)
	clump_count = maxi(clump_count, 15)
	multi_mesh.instance_count = clump_count
	
	# Populate transforms based on distribution mode
	var distribution: int = config.get("distribution", DistributionMode.UNIFORM)
	match distribution:
		DistributionMode.PATCHY:
			_populate_patchy_clumps(multi_mesh, clump_count, hex_size, height_scale, config)
		DistributionMode.SPARSE_RANDOM:
			_populate_sparse_clumps(multi_mesh, clump_count, hex_size, height_scale)
		_:  # UNIFORM
			_populate_uniform_clumps(multi_mesh, clump_count, hex_size, height_scale)
	
	grass_instance.multimesh = multi_mesh
	
	# Apply material with biome-specific texture
	var material = _get_or_create_material(biome_type, config)
	grass_instance.material_override = material
	
	# Rendering settings - no shadow casting for performance
	grass_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	return grass_instance


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

static func _get_texture_for_biome(biome_type: Biomes.Type) -> Texture2D:
	# Check cache first
	if _texture_cache.has(biome_type):
		return _texture_cache[biome_type]
	
	# Try biome-specific texture
	var texture_path = GRASS_TEXTURES.get(biome_type, "")
	if texture_path != "" and ResourceLoader.exists(texture_path):
		var tex = load(texture_path)
		_texture_cache[biome_type] = tex
		return tex
	
	# Fallback to default
	if ResourceLoader.exists(FALLBACK_TEXTURE_PATH):
		var tex = load(FALLBACK_TEXTURE_PATH)
		_texture_cache[biome_type] = tex
		return tex
	
	return null


# =============================================================================
# PRIVATE - MESH GENERATION (Cross-Quad)
# =============================================================================

## Create a cross-quad mesh (2 intersecting quads at 90°)
static func _get_cross_quad_mesh(width_mult: float = 1.0, height_mult: float = 1.0) -> ArrayMesh:
	# Note: We create a fresh mesh each time for different scales
	# In production, you'd want to cache by scale key
	
	var mesh := ArrayMesh.new()
	
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	
	var hw := CLUMP_WIDTH * 0.5 * width_mult
	var h := CLUMP_HEIGHT * height_mult
	
	# Quad 1: Facing +Z / -Z
	# Bottom left
	vertices.append(Vector3(-hw, 0, 0))
	uvs.append(Vector2(0, 1))
	normals.append(Vector3(0, 1, 0))  # Upward normal
	# Bottom right
	vertices.append(Vector3(hw, 0, 0))
	uvs.append(Vector2(1, 1))
	normals.append(Vector3(0, 1, 0))
	# Top right
	vertices.append(Vector3(hw, h, 0))
	uvs.append(Vector2(1, 0))
	normals.append(Vector3(0, 1, 0))
	# Top left
	vertices.append(Vector3(-hw, h, 0))
	uvs.append(Vector2(0, 0))
	normals.append(Vector3(0, 1, 0))
	
	# Quad 2: Facing +X / -X (rotated 90°)
	# Bottom left
	vertices.append(Vector3(0, 0, -hw))
	uvs.append(Vector2(0, 1))
	normals.append(Vector3(0, 1, 0))
	# Bottom right
	vertices.append(Vector3(0, 0, hw))
	uvs.append(Vector2(1, 1))
	normals.append(Vector3(0, 1, 0))
	# Top right
	vertices.append(Vector3(0, h, hw))
	uvs.append(Vector2(1, 0))
	normals.append(Vector3(0, 1, 0))
	# Top left
	vertices.append(Vector3(0, h, -hw))
	uvs.append(Vector2(0, 0))
	normals.append(Vector3(0, 1, 0))
	
	# Indices for both quads (two triangles each)
	# Quad 1
	indices.append_array([0, 1, 2, 0, 2, 3])
	# Quad 2
	indices.append_array([4, 5, 6, 4, 6, 7])
	
	# Build mesh
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
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
	
	if _grass_shader and texture:
		var mat := ShaderMaterial.new()
		mat.shader = _grass_shader
		
		# Texture
		mat.set_shader_parameter("grass_texture", texture)
		mat.set_shader_parameter("alpha_scissor", 0.35)
		
		# Color - biome specific
		mat.set_shader_parameter("color_tint", config.get("color_tint", Color(1, 1, 1)))
		mat.set_shader_parameter("color_variation", config.get("color_variation", 0.15))
		
		# Terrain blending
		mat.set_shader_parameter("terrain_color", config.get("terrain_color", Color(0.12, 0.10, 0.07)))
		mat.set_shader_parameter("terrain_blend_height", config.get("terrain_blend", 0.25))
		
		# Wind - biome specific
		mat.set_shader_parameter("wind_strength", config.get("wind_strength", 0.10))
		mat.set_shader_parameter("wind_speed", config.get("wind_speed", 0.7))
		mat.set_shader_parameter("wind_direction", Vector2(1.0, 0.3))
		mat.set_shader_parameter("wind_wave_size", 2.0)
		mat.set_shader_parameter("wind_turbulence", 0.20)
		
		# SSS - biome specific
		mat.set_shader_parameter("sss_strength", config.get("sss_strength", 0.35))
		mat.set_shader_parameter("sss_color", config.get("sss_color", Color(0.45, 0.65, 0.25)))
		
		# Ambient
		mat.set_shader_parameter("ambient_boost", 0.12)
		mat.set_shader_parameter("ao_strength", 0.55)
		
		_material_cache[cache_key] = mat
		return mat
	
	# Fallback if no shader/texture - make it transparent so it's not ugly
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = Color(0.3, 0.5, 0.2, 0.0)  # Fully transparent
	fallback.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fallback.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material_cache[cache_key] = fallback
	return fallback


# =============================================================================
# PRIVATE - INSTANCE POPULATION (Various Distribution Modes)
# =============================================================================

## Uniform distribution - for plains and hills (dense, even coverage)
static func _populate_uniform_clumps(multi_mesh: MultiMesh, count: int, hex_size: float, height_scale: float) -> void:
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
		
		# Random Y-axis rotation (critical for varied look)
		var rotation := randf() * TAU
		
		# Random scale variation
		var base_scale := 0.75 + randf() * SCALE_VARIATION
		var scale_x := base_scale * (0.9 + randf() * 0.2)
		var scale_y := base_scale * height_scale
		
		# Build transform
		var xform := Transform3D()
		xform = xform.rotated(Vector3.UP, rotation)
		xform = xform.scaled(Vector3(scale_x, scale_y, scale_x))
		xform.origin = pos
		
		multi_mesh.set_instance_transform(i, xform)


## Patchy distribution - for swamp (clusters with gaps)
static func _populate_patchy_clumps(multi_mesh: MultiMesh, count: int, hex_size: float, height_scale: float, config: Dictionary) -> void:
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
		var center := Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		patch_centers.append(center)
	
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
		
		# Random Y-axis rotation
		var rotation := randf() * TAU
		
		# Scale variation - reeds are taller and thinner
		var base_scale := 0.6 + randf() * 0.5
		var scale_x := base_scale * 0.85
		var scale_y := base_scale * height_scale * (0.8 + randf() * 0.4)
		
		# Build transform
		var xform := Transform3D()
		xform = xform.rotated(Vector3.UP, rotation)
		xform = xform.scaled(Vector3(scale_x, scale_y, scale_x))
		xform.origin = pos
		
		multi_mesh.set_instance_transform(placed, xform)
		placed += 1
	
	# Zero out any remaining instances
	for i in range(placed, count):
		multi_mesh.set_instance_transform(i, Transform3D().scaled(Vector3.ZERO))


## Sparse random distribution - for forest (scattered, irregular)
static func _populate_sparse_clumps(multi_mesh: MultiMesh, count: int, hex_size: float, height_scale: float) -> void:
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
		
		# Random Y-axis rotation
		var rotation := randf() * TAU
		
		# Scale variation - ferns are wider and shorter
		var base_scale := 0.65 + randf() * 0.4
		var scale_x := base_scale * 1.2
		var scale_y := base_scale * height_scale
		
		# Build transform
		var xform := Transform3D()
		xform = xform.rotated(Vector3.UP, rotation)
		xform = xform.scaled(Vector3(scale_x, scale_y, scale_x))
		xform.origin = pos
		
		multi_mesh.set_instance_transform(i, xform)
