## Biome Material Manager
## Creates and caches StandardMaterial3D materials for each biome type
## Supports loading PBR textures with proper world-space UV mapping for seamless tiling
##
## "Manor Lords" Aesthetic Implementation:
## - PBR Workflow: Roughness and AO maps prioritized over Base Color
## - Normal Maps: Slightly over-driven (1.2x - 1.5x) for top-down visibility
## - Color Palette: Muted earth tones (Umber, Sage, Slate, Charcoal)
## - Global saturation reduced ~15% for medieval atmosphere
## Reference: Photogrammetry, Upper Franconian Climate, Muted Medieval, High AO
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

## Normal map intensity multiplier (Manor Lords: 1.2x - 1.5x for top-down visibility)
const NORMAL_MAP_OVERDRIVE := 1.3  # Slightly over-driven for camera angle

## Global saturation reduction (Manor Lords: reduce by ~15%)
const SATURATION_REDUCTION := 0.15  # How much to desaturate base colors

## Muted earth tone color palette (Manor Lords style)
## Colors: Umber, Sage, Slate, and Charcoal
const EARTH_TONE_PALETTE: Dictionary = {
	"umber": Color(0.35, 0.25, 0.18),      # Raw umber brown
	"sage": Color(0.44, 0.50, 0.40),        # Sage green
	"slate": Color(0.35, 0.38, 0.42),       # Slate grey
	"charcoal": Color(0.21, 0.20, 0.19),    # Charcoal
	"ochre": Color(0.55, 0.45, 0.30),       # Yellow ochre
	"moss": Color(0.28, 0.35, 0.22),        # Moss green
}

## Biome to texture name mapping
## Maps each biome type to its texture prefix (with fallback options)
## Format: Primary texture, then fallbacks
## New textures from AmbientCG/PolyHaven use "_new" suffix
const BIOME_TEXTURE_MAP: Dictionary = {
	# Forest: Use new Ground037 from AmbientCG (forest floor with leaves)
	Biomes.Type.FOREST: "enchanted_forest_new",  # Priority: AmbientCG Ground037
	# Peaks: Use existing frozen peaks (ice/snow)
	Biomes.Type.PEAKS: "frozen_peaks",
	# Wastes: Use existing desolate wastes (rocky barren)
	Biomes.Type.WASTES: "desolate_wastes",
	# Plains: Use existing golden plains (grassy fields)
	Biomes.Type.PLAINS: "golden_plains",
	# Ashlands: Use new burned_ground_01 from PolyHaven
	Biomes.Type.ASHLANDS: "ashlands_new",  # Priority: PolyHaven burned_ground_01
	# Hills: Reuse golden plains for grassy look
	Biomes.Type.HILLS: "golden_plains",
	# Swamp: Use new Ground025 from AmbientCG (muddy/wet ground)
	Biomes.Type.SWAMP: "swamplands_new"  # Priority: AmbientCG Ground025
}

## Fallback texture map if primary texture not found
const BIOME_TEXTURE_FALLBACKS: Dictionary = {
	"enchanted_forest_new": "enchanted_forest",
	"ashlands_new": "ashlands",
	"swamplands_new": "swamplands"
}

## Enhanced biome material properties for when textures aren't available
## Format: {color, roughness, metallic, emission_color, emission_energy}
## Manor Lords aesthetic: Muted earth tones, high roughness, absorptive surfaces
const BIOME_MATERIAL_PROPERTIES: Dictionary = {
	Biomes.Type.FOREST: {
		# Forest Floor: Absorptive, high roughness (0.7+), organic decay/moss look
		"color": Color(0.15, 0.22, 0.08),  # Dark moss green - absorptive
		"roughness": 0.85,  # High roughness per Manor Lords spec (0.7+)
		"metallic": 0.0,
		"emission": Color(0.0, 0.0, 0.0),
		"emission_energy": 0.0,
		"normal_scale": 1.5,  # Over-driven normals for debris/pine needles
		"ao_intensity": 0.7   # Heavy AO for crevices
	},
	Biomes.Type.PEAKS: {
		"color": Color(0.75, 0.80, 0.88),  # Muted blue-white (less saturated)
		"roughness": 0.45,  # Icy but not mirror-smooth
		"metallic": 0.08,
		"emission": Color(0.85, 0.90, 0.95),
		"emission_energy": 0.03,  # Very subtle ice glow
		"normal_scale": 1.2,
		"ao_intensity": 0.4
	},
	Biomes.Type.WASTES: {
		# Dry, dusty - muted ochre/tan
		"color": Color(0.60, 0.50, 0.35),  # Muted ochre
		"roughness": 0.92,  # Very dry, rough
		"metallic": 0.0,
		"emission": Color(0.0, 0.0, 0.0),
		"emission_energy": 0.0,
		"normal_scale": 1.3,
		"ao_intensity": 0.45
	},
	Biomes.Type.PLAINS: {
		# Sage-golden grass - muted earth tone
		"color": Color(0.58, 0.52, 0.25),  # Muted golden/sage
		"roughness": 0.78,
		"metallic": 0.0,
		"emission": Color(0.0, 0.0, 0.0),
		"emission_energy": 0.0,
		"normal_scale": 1.2,
		"ao_intensity": 0.4
	},
	Biomes.Type.ASHLANDS: {
		# Flat, desaturated, "dead" look - low contrast, reduced light bounce
		"color": Color(0.20, 0.19, 0.18),  # Charcoal - desaturated
		"roughness": 0.88,  # Very rough, no shine
		"metallic": 0.05,
		"emission": Color(0.30, 0.10, 0.03),  # Muted ember glow
		"emission_energy": 0.12,  # Reduced from previous
		"normal_scale": 1.1,  # Less normal detail - flat look
		"ao_intensity": 0.25  # Reduced AO - flat, heavy feel
	},
	Biomes.Type.HILLS: {
		# Sage green - earth tone
		"color": Color(0.42, 0.48, 0.38),  # Sage from palette
		"roughness": 0.80,
		"metallic": 0.0,
		"emission": Color(0.0, 0.0, 0.0),
		"emission_energy": 0.0,
		"normal_scale": 1.3,
		"ao_intensity": 0.45
	},
	Biomes.Type.SWAMP: {
		# Reflective wet patches vs high-roughness mud
		# Sharp specular highlights for standing water glint
		"color": Color(0.24, 0.28, 0.12),  # Dark murky green
		"roughness": 0.55,  # Mix of wet (0.1-0.3) and mud (0.7+)
		"metallic": 0.22,  # Wet reflectivity for water glint
		"emission": Color(0.0, 0.0, 0.0),
		"emission_energy": 0.0,
		"normal_scale": 1.4,  # Strong normals for viscous texture
		"ao_intensity": 0.55  # Strong AO for wet crevices
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


## Load a texture trying multiple extensions (jpg, png)
static func _load_texture_any_ext(base_path: String, map_type: String) -> Texture2D:
	# Try jpg first (new downloads), then png (original textures)
	var extensions = ["jpg", "png"]
	for ext in extensions:
		var path = base_path + map_type + "." + ext
		var tex = _load_texture(path)
		if tex:
			return tex
	return null


## Try to load PBR textures for a material
static func _try_load_pbr_textures(material: StandardMaterial3D, texture_prefix: String, biome_type: Biomes.Type) -> bool:
	# Texture patterns to try:
	# 1. Direct name: {prefix}_{map_type}.{ext} (new textures like ashlands_new_diffuse.jpg)
	# 2. Primary variant: {prefix}_primary_{map_type}.{ext} (original textures)
	
	var diffuse_tex: Texture2D = null
	var base_path: String = ""
	var variant_tried: String = ""
	
	# Try direct path first (new texture format)
	base_path = TEXTURES_PATH + texture_prefix + "_"
	diffuse_tex = _load_texture_any_ext(base_path, "diffuse")
	if diffuse_tex:
		variant_tried = "direct"
	
	# Try primary/secondary variants (original texture format)
	if not diffuse_tex:
		# Peaks should always use primary (snowy) texture
		# Other biomes can randomly use primary/secondary for variety
		var variant: String
		if biome_type == Biomes.Type.PEAKS:
			variant = "primary"  # Always snowy for peaks
		else:
			variant = "primary" if randf() > 0.3 else "secondary"
		
		base_path = TEXTURES_PATH + texture_prefix + "_" + variant + "_"
		diffuse_tex = _load_texture_any_ext(base_path, "diffuse")
		if diffuse_tex:
			variant_tried = variant
		elif variant == "secondary":
			# Fallback to primary
			base_path = TEXTURES_PATH + texture_prefix + "_primary_"
			diffuse_tex = _load_texture_any_ext(base_path, "diffuse")
			if diffuse_tex:
				variant_tried = "primary"
	
	# Try fallback texture if primary texture not found
	if not diffuse_tex and BIOME_TEXTURE_FALLBACKS.has(texture_prefix):
		var fallback = BIOME_TEXTURE_FALLBACKS[texture_prefix]
		base_path = TEXTURES_PATH + fallback + "_primary_"
		diffuse_tex = _load_texture_any_ext(base_path, "diffuse")
		if diffuse_tex:
			variant_tried = "fallback: " + fallback
	
	if not diffuse_tex:
		print("[BiomeMaterialManager] No texture found for: %s" % texture_prefix)
		return false
	
	# Apply diffuse texture
	material.albedo_texture = diffuse_tex
	material.albedo_color = Color.WHITE  # Use natural texture color
	
	# Enable triplanar mapping for seamless world-space tiling
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_triplanar_sharpness = 1.0
	material.uv1_scale = Vector3(TEXTURE_SCALE, TEXTURE_SCALE, TEXTURE_SCALE)
	
	# Get biome-specific properties for customization
	var props: Dictionary = BIOME_MATERIAL_PROPERTIES.get(biome_type, {})
	
	# Load normal map - ENHANCED strength for visible terrain depth
	# Over-driven per Manor Lords spec (1.2x - 1.5x) for top-down camera visibility
	var normal_tex = _load_texture_any_ext(base_path, "normal")
	if normal_tex:
		material.normal_enabled = true
		material.normal_texture = normal_tex
		# Use biome-specific or default enhanced scale
		var normal_scale = props.get("normal_scale", NORMAL_MAP_OVERDRIVE)
		material.normal_scale = normal_scale  # Use full strength for visible depth
	
	# Load roughness map - PRIORITY per Manor Lords PBR workflow
	# "The look relies more on how light interacts with surface texture than Base Color"
	var roughness_tex = _load_texture_any_ext(base_path, "roughness")
	if roughness_tex:
		material.roughness_texture = roughness_tex
		material.roughness = 1.0  # Let texture drive roughness
	else:
		# Fallback: use biome-specific roughness
		material.roughness = props.get("roughness", 0.75)
	
	# Load ambient occlusion map - HIGH PRIORITY per Manor Lords spec
	# "Heavy Ambient Occlusion in crevices to define debris, sticks, pine needles"
	var ao_tex = _load_texture_any_ext(base_path, "ao")
	if ao_tex:
		material.ao_enabled = true
		material.ao_texture = ao_tex
		# Per Manor Lords spec: heavy AO - use biome-specific intensity
		var ao_intensity = props.get("ao_intensity", 0.5)
		material.ao_light_affect = ao_intensity
	
	# Apply biome-specific adjustments (roughness, wetness, desaturation)
	_apply_biome_adjustments(material, biome_type)
	
	print("[BiomeMaterialManager] Loaded: %s (%s) [Manor Lords PBR]" % [texture_prefix, variant_tried])
	return true


## Apply biome-specific material adjustments per "Manor Lords" aesthetic
## Design Doc Requirements:
## - Muted medieval palette (Umber, Sage, Slate, Charcoal)
## - Reduce global saturation by ~15%
## - High AO, diffuse daylight, earth tones
## - Forest: Absorptive (roughness 0.7+), heavy AO for debris/moss
## - Swamp: Reflective wet patches vs high-roughness mud, sharp specular glints
## - Ashlands: Flat, desaturated, "dead" - reduced light bounce
static func _apply_biome_adjustments(material: StandardMaterial3D, biome_type: Biomes.Type) -> void:
	var props: Dictionary = BIOME_MATERIAL_PROPERTIES.get(biome_type, {})
	
	# ==========================================================================
	# GLOBAL: Reduce saturation by ~15% for muted medieval palette
	# ==========================================================================
	# Lerp towards grey to desaturate
	var desat_amount: float = SATURATION_REDUCTION
	material.albedo_color = material.albedo_color.lerp(
		Color(material.albedo_color.v, material.albedo_color.v, material.albedo_color.v), 
		desat_amount
	)
	
	# ==========================================================================
	# BIOME-SPECIFIC ADJUSTMENTS
	# ==========================================================================
	match biome_type:
		Biomes.Type.FOREST:
			# FOREST FLOOR: Absorptive - high roughness (0.7+) for organic decay/moss
			# Micro-Detail: Heavy AO in crevices for debris, sticks, pine needles
			material.roughness = props.get("roughness", 0.85)
			material.metallic = 0.0  # No metallic reflection - absorptive
			# Darken slightly for absorptive, under-canopy feel
			material.albedo_color = material.albedo_color * 0.88
		
		Biomes.Type.PEAKS:
			# Icy peaks - subtle shimmer, not mirror-like
			material.metallic = props.get("metallic", 0.08)
			material.roughness = props.get("roughness", 0.45)
			# Subtle rim lighting for ice crystalline effect
			material.rim_enabled = true
			material.rim = 0.2
			material.rim_tint = 0.15
		
		Biomes.Type.ASHLANDS:
			# FLAT AND DESATURATED: "Dead" look
			# Low global contrast, reduced light bounce (GI)
			# Extra desaturation beyond global
			material.albedo_color = material.albedo_color.lerp(
				Color(0.22, 0.21, 0.20), 0.25
			)
			material.roughness = props.get("roughness", 0.88)  # Very rough, no shine
			# Muted ember glow - reduced from fantasy to realistic
			material.emission_enabled = true
			material.emission = props.get("emission", Color(0.30, 0.10, 0.03))
			material.emission_energy_multiplier = props.get("emission_energy", 0.12)
		
		Biomes.Type.SWAMP:
			# REFLECTIVE/VISCOUS: Contrast high-roughness mud with wet patches
			# Key Detail: Sharp specular highlights for "glint" of standing water
			material.metallic = props.get("metallic", 0.22)
			material.roughness = props.get("roughness", 0.55)
			# Sharp specular for water glints against dull mud
			material.metallic_specular = 0.65
			# SSR will handle reflections via environment
		
		Biomes.Type.WASTES:
			# Dry, dusty - harsh but diffuse
			material.roughness = props.get("roughness", 0.92)
			material.metallic = 0.0
		
		Biomes.Type.HILLS:
			# Sage green hills - standard earth tone
			material.roughness = props.get("roughness", 0.80)
			material.metallic = 0.0
		
		Biomes.Type.PLAINS:
			# Golden-sage plains - standard
			material.roughness = props.get("roughness", 0.78)
			material.metallic = 0.0


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
