## Biome Material Manager
## Creates and caches StandardMaterial3D materials for each biome type
## Supports loading PBR textures when available, falls back to enhanced procedural colors
class_name BiomeMaterialManager
extends RefCounted

# =============================================================================
# CONSTANTS
# =============================================================================

## Path to biome textures (if downloaded from Poly Haven)
const TEXTURES_PATH := "res://assets/textures/biomes/"

## Enhanced biome material properties per the asset integration plan
## Format: {color, roughness, metallic, emission_color, emission_energy}
const BIOME_MATERIAL_PROPERTIES: Dictionary = {
	Biomes.Type.FOREST: {
		"color": Color(0.18, 0.31, 0.09),  # Deep forest green (#2D5016)
		"roughness": 0.85,
		"metallic": 0.0,
		"emission": Color(0.0, 0.0, 0.0),
		"emission_energy": 0.0,
		"texture_name": "forest_leaves_02"
	},
	Biomes.Type.PEAKS: {
		"color": Color(0.83, 0.89, 0.97),  # Blue-white (#D4E4F7)
		"roughness": 0.4,  # Icy sheen
		"metallic": 0.1,
		"emission": Color(0.9, 0.95, 1.0),
		"emission_energy": 0.05,  # Subtle ice glow
		"texture_name": "snow_02"
	},
	Biomes.Type.WASTES: {
		"color": Color(0.79, 0.65, 0.42),  # Tan (#C9A66B)
		"roughness": 0.95,  # Very dry
		"metallic": 0.0,
		"emission": Color(0.0, 0.0, 0.0),
		"emission_energy": 0.0,
		"texture_name": "desert_sand_02"
	},
	Biomes.Type.PLAINS: {
		"color": Color(0.83, 0.69, 0.22),  # Golden yellow (#D4AF37)
		"roughness": 0.75,
		"metallic": 0.0,
		"emission": Color(0.0, 0.0, 0.0),
		"emission_energy": 0.0,
		"texture_name": "grass_field_001"
	},
	Biomes.Type.ASHLANDS: {
		"color": Color(0.17, 0.17, 0.17),  # Charcoal (#2B2B2B)
		"roughness": 0.6,
		"metallic": 0.1,
		"emission": Color(0.55, 0.14, 0.14),  # Ember red glow
		"emission_energy": 0.3,
		"texture_name": "volcanic_rock"
	},
	Biomes.Type.HILLS: {
		"color": Color(0.48, 0.62, 0.50),  # Sage green (#7A9D7E)
		"roughness": 0.8,
		"metallic": 0.0,
		"emission": Color(0.0, 0.0, 0.0),
		"emission_energy": 0.0,
		"texture_name": "hill_grass"
	},
	Biomes.Type.SWAMP: {
		"color": Color(0.29, 0.36, 0.14),  # Murky green (#4A5D23)
		"roughness": 0.5,  # Wet/slimy
		"metallic": 0.15,  # Slight wet sheen
		"emission": Color(0.0, 0.0, 0.0),
		"emission_energy": 0.0,
		"texture_name": "mud_cracked_dry_03"
	}
}

# =============================================================================
# CACHED MATERIALS
# =============================================================================

## Cached materials dictionary {Biomes.Type: StandardMaterial3D}
static var _material_cache: Dictionary = {}

## Whether PBR textures are available
static var _textures_available: bool = false
static var _texture_check_done: bool = false

# =============================================================================
# PUBLIC METHODS
# =============================================================================

## Get the material for a biome type
## Creates and caches the material if not already cached
static func get_material(biome_type: Biomes.Type) -> StandardMaterial3D:
	# Check cache first
	if _material_cache.has(biome_type):
		return _material_cache[biome_type]
	
	# Create new material
	var material = _create_material(biome_type)
	_material_cache[biome_type] = material
	return material


## Clear material cache (call when changing quality settings)
static func clear_cache() -> void:
	_material_cache.clear()
	_texture_check_done = false


## Get a duplicate material (for unique instances that may be modified)
static func get_material_copy(biome_type: Biomes.Type) -> StandardMaterial3D:
	var base = get_material(biome_type)
	return base.duplicate() as StandardMaterial3D


# =============================================================================
# PRIVATE METHODS
# =============================================================================

## Create a material for the given biome type
static func _create_material(biome_type: Biomes.Type) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	
	# Get properties for this biome
	var props: Dictionary = BIOME_MATERIAL_PROPERTIES.get(biome_type, {})
	if props.is_empty():
		# Fallback to basic Biomes color
		material.albedo_color = Biomes.get_biome_color(biome_type)
		return material
	
	# Check if textures are available (only once)
	if not _texture_check_done:
		_check_textures_available()
	
	# Try to load PBR textures if available
	var texture_loaded := false
	if _textures_available and props.has("texture_name"):
		texture_loaded = _try_load_pbr_textures(material, props["texture_name"])
	
	# If no textures, use procedural color with enhanced properties
	if not texture_loaded:
		material.albedo_color = props.get("color", Color.WHITE)
	
	# Apply material properties
	material.roughness = props.get("roughness", 0.75)
	material.metallic = props.get("metallic", 0.0)
	
	# Apply emission (for glowing biomes like Ashlands)
	var emission_energy: float = props.get("emission_energy", 0.0)
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = props.get("emission", Color.WHITE)
		material.emission_energy_multiplier = emission_energy
	
	# Enable ambient occlusion if texture has AO
	material.ao_enabled = texture_loaded
	
	# Shading settings for better quality
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	
	return material


## Check if PBR textures are available
static func _check_textures_available() -> void:
	_texture_check_done = true
	
	# Check if the biomes texture folder has any content
	var dir := DirAccess.open(TEXTURES_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".png") or file_name.ends_with(".jpg"):
				_textures_available = true
				break
			file_name = dir.get_next()
		dir.list_dir_end()


## Try to load PBR textures for a material
static func _try_load_pbr_textures(material: StandardMaterial3D, texture_name: String) -> bool:
	var base_path := TEXTURES_PATH + texture_name
	
	# Check for albedo texture (required)
	var albedo_path := base_path + "_diff_1k.png"  # Poly Haven naming convention
	if not ResourceLoader.exists(albedo_path):
		albedo_path = base_path + "_albedo.png"
	if not ResourceLoader.exists(albedo_path):
		albedo_path = base_path + ".png"
	
	if not ResourceLoader.exists(albedo_path):
		return false
	
	# Load albedo
	var albedo_tex := load(albedo_path) as Texture2D
	if albedo_tex:
		material.albedo_texture = albedo_tex
	else:
		return false
	
	# Try to load normal map
	var normal_paths := [
		base_path + "_nor_gl_1k.png",
		base_path + "_normal.png",
		base_path + "_nor.png"
	]
	for path in normal_paths:
		if ResourceLoader.exists(path):
			var normal_tex := load(path) as Texture2D
			if normal_tex:
				material.normal_enabled = true
				material.normal_texture = normal_tex
			break
	
	# Try to load roughness map
	var rough_paths := [
		base_path + "_rough_1k.png",
		base_path + "_roughness.png"
	]
	for path in rough_paths:
		if ResourceLoader.exists(path):
			var rough_tex := load(path) as Texture2D
			if rough_tex:
				material.roughness_texture = rough_tex
			break
	
	# Try to load AO map
	var ao_paths := [
		base_path + "_ao_1k.png",
		base_path + "_ao.png"
	]
	for path in ao_paths:
		if ResourceLoader.exists(path):
			var ao_tex := load(path) as Texture2D
			if ao_tex:
				material.ao_enabled = true
				material.ao_texture = ao_tex
			break
	
	return true


# =============================================================================
# PARTICLE CONFIGURATION
# =============================================================================

## Particle effect data for each biome type
## Used by particle spawning systems
const BIOME_PARTICLES: Dictionary = {
	Biomes.Type.FOREST: {
		"enabled": true,
		"type": "fireflies",
		"color": Color(0.9, 0.95, 0.5, 0.8),  # Yellow-green glow
		"amount": 3,
		"emission_rate": 0.5
	},
	Biomes.Type.PEAKS: {
		"enabled": true,
		"type": "snow",
		"color": Color(0.95, 0.95, 1.0, 0.6),  # White snowflakes
		"amount": 8,
		"emission_rate": 1.0
	},
	Biomes.Type.WASTES: {
		"enabled": true,
		"type": "dust",
		"color": Color(0.7, 0.6, 0.4, 0.3),  # Sandy dust
		"amount": 5,
		"emission_rate": 0.8
	},
	Biomes.Type.PLAINS: {
		"enabled": true,
		"type": "pollen",
		"color": Color(0.95, 0.9, 0.6, 0.4),  # Golden pollen
		"amount": 2,
		"emission_rate": 0.3
	},
	Biomes.Type.ASHLANDS: {
		"enabled": true,
		"type": "embers",
		"color": Color(1.0, 0.4, 0.1, 0.9),  # Orange embers
		"amount": 6,
		"emission_rate": 1.2
	},
	Biomes.Type.HILLS: {
		"enabled": true,
		"type": "grass",
		"color": Color(0.6, 0.7, 0.5, 0.3),  # Green grass
		"amount": 2,
		"emission_rate": 0.4
	},
	Biomes.Type.SWAMP: {
		"enabled": true,
		"type": "fog",
		"color": Color(0.4, 0.5, 0.3, 0.5),  # Murky fog
		"amount": 4,
		"emission_rate": 0.6
	}
}


## Get particle configuration for a biome
static func get_particle_config(biome_type: Biomes.Type) -> Dictionary:
	return BIOME_PARTICLES.get(biome_type, {"enabled": false})
