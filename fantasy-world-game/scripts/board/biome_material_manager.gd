## Biome Material Manager
## Creates and caches StandardMaterial3D materials for each biome type
## Supports loading PBR textures with proper world-space UV mapping for seamless tiling
class_name BiomeMaterialManager
extends RefCounted

# =============================================================================
# CONSTANTS
# =============================================================================

## Path to biome textures
const TEXTURES_PATH := "res://assets/textures/biomes/"

# =============================================================================
# WORLD SCALE REFERENCE
# =============================================================================
# This game uses realistic 1:1 scale for immersion:
# - 1 Godot unit = 1 meter (approximately)
# - Hex size = 1.0 (center to corner), so hex width ≈ 1.73m, but represents ~5-8m of terrain
# - A knight troop model should be ~1.8-2.0 units tall (human height)
# - A hydra should be ~10-15 units tall (massive creature)
# - Texture scale is set so terrain details (rocks, leaves, grass blades) appear 
#   at realistic proportions when troops stand on them

## Texture scale for world-space UV mapping (controls texture tiling frequency)
## Lower value = larger texture appearance (less tiling), Higher = smaller/more tiled
## At scale 0.03: textures tile every ~33 meters, showing realistic ground detail
const TEXTURE_SCALE := 0.03  # Realistic 1:1 scale - visible rocks, leaves, terrain detail

## Biome to texture name mapping
## Maps each biome type to its texture prefix (matches your downloaded assets)
const BIOME_TEXTURE_MAP: Dictionary = {
	Biomes.Type.FOREST: "enchanted_forest",
	Biomes.Type.PEAKS: "frozen_peaks",
	Biomes.Type.WASTES: "desolate_wastes",
	Biomes.Type.PLAINS: "golden_plains",
	Biomes.Type.ASHLANDS: "ashlands",
	Biomes.Type.HILLS: "golden_plains",  # Re-use golden plains for hills (grassy look)
	Biomes.Type.SWAMP: "swamplands"
}

## Enhanced biome material properties for when textures aren't available
## Format: {color, roughness, metallic, emission_color, emission_energy}
const BIOME_MATERIAL_PROPERTIES: Dictionary = {
	Biomes.Type.FOREST: {
		"color": Color(0.18, 0.31, 0.09),  # Deep forest green
		"roughness": 0.85,
		"metallic": 0.0,
		"emission": Color(0.0, 0.0, 0.0),
		"emission_energy": 0.0
	},
	Biomes.Type.PEAKS: {
		"color": Color(0.83, 0.89, 0.97),  # Blue-white icy
		"roughness": 0.4,  # Icy sheen
		"metallic": 0.1,
		"emission": Color(0.9, 0.95, 1.0),
		"emission_energy": 0.05  # Subtle ice glow
	},
	Biomes.Type.WASTES: {
		"color": Color(0.79, 0.65, 0.42),  # Tan/sandy
		"roughness": 0.95,  # Very dry
		"metallic": 0.0,
		"emission": Color(0.0, 0.0, 0.0),
		"emission_energy": 0.0
	},
	Biomes.Type.PLAINS: {
		"color": Color(0.83, 0.69, 0.22),  # Golden yellow
		"roughness": 0.75,
		"metallic": 0.0,
		"emission": Color(0.0, 0.0, 0.0),
		"emission_energy": 0.0
	},
	Biomes.Type.ASHLANDS: {
		"color": Color(0.17, 0.17, 0.17),  # Charcoal
		"roughness": 0.6,
		"metallic": 0.1,
		"emission": Color(0.55, 0.14, 0.14),  # Ember red glow
		"emission_energy": 0.3
	},
	Biomes.Type.HILLS: {
		"color": Color(0.48, 0.62, 0.50),  # Sage green
		"roughness": 0.8,
		"metallic": 0.0,
		"emission": Color(0.0, 0.0, 0.0),
		"emission_energy": 0.0
	},
	Biomes.Type.SWAMP: {
		"color": Color(0.29, 0.36, 0.14),  # Murky green
		"roughness": 0.5,  # Wet/slimy
		"metallic": 0.15,  # Slight wet sheen
		"emission": Color(0.0, 0.0, 0.0),
		"emission_energy": 0.0
	}
}

# =============================================================================
# CACHED MATERIALS AND TEXTURES
# =============================================================================

## Cached materials dictionary {Biomes.Type: StandardMaterial3D}
static var _material_cache: Dictionary = {}

## Cached textures dictionary {texture_path: Texture2D}
static var _texture_cache: Dictionary = {}

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
	_texture_cache.clear()
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
	
	# Get fallback properties for this biome
	var props: Dictionary = BIOME_MATERIAL_PROPERTIES.get(biome_type, {})
	
	# Check if textures are available (only once)
	if not _texture_check_done:
		_check_textures_available()
	
	# Try to load PBR textures if available
	var texture_loaded := false
	if _textures_available:
		var texture_prefix = BIOME_TEXTURE_MAP.get(biome_type, "")
		if texture_prefix != "":
			texture_loaded = _try_load_pbr_textures(material, texture_prefix, biome_type)
	
	# If no textures, use procedural color with enhanced properties
	if not texture_loaded:
		material.albedo_color = props.get("color", Biomes.get_biome_color(biome_type))
	
	# Apply material properties
	material.roughness = props.get("roughness", 0.75)
	material.metallic = props.get("metallic", 0.0)
	
	# Apply emission (for glowing biomes like Ashlands)
	var emission_energy: float = props.get("emission_energy", 0.0)
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = props.get("emission", Color.WHITE)
		material.emission_energy_multiplier = emission_energy
	
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
				print("[BiomeMaterialManager] Textures found at: %s" % TEXTURES_PATH)
				break
			file_name = dir.get_next()
		dir.list_dir_end()
	
	if not _textures_available:
		print("[BiomeMaterialManager] No textures found, using procedural materials")


## Load a texture with caching
static func _load_texture(path: String) -> Texture2D:
	# Check cache
	if _texture_cache.has(path):
		return _texture_cache[path]
	
	# Try to load
	if ResourceLoader.exists(path):
		var tex := load(path) as Texture2D
		if tex:
			_texture_cache[path] = tex
			return tex
	
	return null


## Try to load PBR textures for a material
static func _try_load_pbr_textures(material: StandardMaterial3D, texture_prefix: String, biome_type: Biomes.Type) -> bool:
	# Your textures follow the pattern: {prefix}_primary_{map_type}.png
	# e.g., enchanted_forest_primary_diffuse.png
	
	# Randomly choose primary or secondary variant for visual variety
	var variant: String = "primary" if randf() > 0.3 else "secondary"  # 70% primary, 30% secondary
	var base_path: String = TEXTURES_PATH + texture_prefix + "_" + variant + "_"
	
	# Try to load diffuse/albedo texture (required)
	var diffuse_path: String = base_path + "diffuse.png"
	var diffuse_tex: Texture2D = _load_texture(diffuse_path)
	
	if not diffuse_tex:
		# Try primary if secondary failed
		if variant == "secondary":
			base_path = TEXTURES_PATH + texture_prefix + "_primary_"
			diffuse_path = base_path + "diffuse.png"
			diffuse_tex = _load_texture(diffuse_path) as Texture2D
		
		if not diffuse_tex:
			print("[BiomeMaterialManager] Failed to load diffuse texture: %s" % diffuse_path)
			return false
	
	# Apply diffuse texture
	material.albedo_texture = diffuse_tex
	material.albedo_color = Color.WHITE  # Reset color when using texture
	
	# Enable triplanar mapping for seamless world-space tiling across hexes
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_triplanar_sharpness = 1.0
	material.uv1_scale = Vector3(TEXTURE_SCALE, TEXTURE_SCALE, TEXTURE_SCALE)
	
	# Load normal map
	var normal_path: String = base_path + "normal.png"
	var normal_tex: Texture2D = _load_texture(normal_path)
	if normal_tex:
		material.normal_enabled = true
		material.normal_texture = normal_tex
		material.normal_scale = 0.5  # Subtle normal mapping for realism
	
	# Load roughness map
	var roughness_path: String = base_path + "roughness.png"
	var roughness_tex: Texture2D = _load_texture(roughness_path)
	if roughness_tex:
		material.roughness_texture = roughness_tex
		material.roughness = 1.0  # Let texture control roughness
	
	# Load ambient occlusion map
	var ao_path: String = base_path + "ao.png"
	var ao_tex: Texture2D = _load_texture(ao_path)
	if ao_tex:
		material.ao_enabled = true
		material.ao_texture = ao_tex
		material.ao_light_affect = 0.3  # Subtle AO effect
	
	# Skip displacement/heightmap - it can cause visual noise on flat hex tiles
	# The normal maps provide enough depth perception
	# Heightmap would only be useful for close-up views
	
	# Apply biome-specific adjustments
	_apply_biome_adjustments(material, biome_type)
	
	print("[BiomeMaterialManager] Loaded PBR textures for biome: %s (%s variant)" % [Biomes.get_biome_name(biome_type), variant])
	return true


## Apply biome-specific material adjustments
static func _apply_biome_adjustments(material: StandardMaterial3D, biome_type: Biomes.Type) -> void:
	var props: Dictionary = BIOME_MATERIAL_PROPERTIES.get(biome_type, {})
	
	match biome_type:
		Biomes.Type.PEAKS:
			# Icy peaks should have a slight blue tint and shimmer
			material.metallic = 0.15
			material.rim_enabled = true
			material.rim = 0.5
			material.rim_tint = 0.3
		
		Biomes.Type.ASHLANDS:
			# Ashlands should glow with ember highlights
			material.emission_enabled = true
			material.emission = props.get("emission", Color(0.55, 0.14, 0.14))
			material.emission_energy_multiplier = props.get("emission_energy", 0.3)
		
		Biomes.Type.SWAMP:
			# Swamp should look wet and murky
			material.metallic = 0.2  # Wet sheen
			material.roughness = 0.4
		
		Biomes.Type.FOREST:
			# Forest should have rich, saturated colors
			material.albedo_color = material.albedo_color * 1.1  # Slight saturation boost


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
