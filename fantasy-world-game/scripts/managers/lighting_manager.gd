## Lighting Manager
## Implements "Manor Lords" aesthetic lighting: Atmospheric Naturalism
## Features: Overcast look, soft shadows, muted colors, atmospheric perspective
## Reference: Photogrammetry, Upper Franconian Climate, Muted Medieval, Diffuse Daylight
class_name LightingManager
extends RefCounted

# =============================================================================
# LIGHTING PROFILE CONSTANTS - "Manor Lords" Aesthetic
# =============================================================================

## Global Lighting Profile - "The Overcast Look"
## Primary Source: Large, diffuse light (High Overcast)
## Color Temp: Neutral to Cool (5500K - 6500K) - "Slate Grey" / "Damp Morning" sky
const OVERCAST_PROFILE: Dictionary = {
	# Sky colors - muted, overcast, "damp morning" feel
	"sky_top_color": Color(0.42, 0.48, 0.58, 1.0),        # Slate grey-blue - overcast
	"sky_horizon_color": Color(0.58, 0.60, 0.64, 1.0),    # Lighter grey at horizon
	"ground_bottom_color": Color(0.12, 0.11, 0.10, 1.0),  # Dark earthy ground
	"ground_horizon_color": Color(0.28, 0.26, 0.24, 1.0), # Muted brown horizon
	"sun_angle_max": 30.0,  # Lower sun angle for diffuse light
	
	# Directional Light - Soft diffuse daylight, NOT golden hour
	"light_color": Color(0.92, 0.91, 0.88, 1.0),  # Cool neutral ~6000K (NOT warm/orange)
	"light_energy": 0.85,  # Reduced energy - overcast feel
	"light_indirect_energy": 0.4,  # Reduced bounce light
	"shadow_bias": 0.08,
	"shadow_normal_bias": 3.0,
	"shadow_blur": 2.5,  # Soft-box effect - blurred shadow edges
	
	# Ambient Light - Cool atmospheric
	"ambient_color": Color(0.48, 0.50, 0.55, 1.0),  # Cool grey ambient
	"ambient_energy": 0.65,  # Strong ambient for fill
	
	# Fog - Blue-grey distance fog (Atmospheric Perspective)
	"fog_enabled": true,
	"fog_light_color": Color(0.55, 0.58, 0.65, 1.0),  # Blue-grey fog
	"fog_light_energy": 0.3,
	"fog_density": 0.002,  # Subtle atmospheric haze
	"fog_aerial_perspective": 0.4,  # Desaturation with distance
	"fog_sky_affect": 0.3,
	
	# Tonemap - Natural, non-stylized
	"tonemap_mode": 3,  # ACES Filmic for photorealistic look
	"tonemap_exposure": 0.95,  # Slightly reduced exposure
	"tonemap_white": 1.1,
	
	# Post-processing for muted medieval look
	"adjustment_brightness": 0.97,  # Slight reduction
	"adjustment_contrast": 0.92,    # Low contrast for heavy, overcast feel
	"adjustment_saturation": 0.85,  # Reduce global saturation by ~15%
	
	# SSAO - Heavy Ambient Occlusion (crucial for Manor Lords look)
	"ssao_enabled": true,
	"ssao_radius": 1.5,           # Wider radius for crevice detection
	"ssao_intensity": 3.0,        # Strong AO
	"ssao_power": 1.8,
	"ssao_detail": 0.6,
	"ssao_horizon": 0.1,
	"ssao_sharpness": 0.98,
	"ssao_light_affect": 0.6,
	
	# Volumetric fog for atmospheric haze
	"volumetric_fog_enabled": true,
	"volumetric_fog_density": 0.01,
	"volumetric_fog_albedo": Color(0.9, 0.9, 0.92, 1.0),
	"volumetric_fog_emission": Color(0.0, 0.0, 0.0, 1.0),
	"volumetric_fog_emission_energy": 0.0,
	"volumetric_fog_anisotropy": 0.2,
	"volumetric_fog_length": 64.0,
	"volumetric_fog_detail_spread": 2.0,
	
	# Glow - Minimal, subtle
	"glow_enabled": true,
	"glow_intensity": 0.3,
	"glow_strength": 0.6,
	"glow_bloom": 0.02,  # Very subtle bloom
	"glow_blend_mode": 2,  # Softlight for natural look
	
	# SSR - Subtle reflections for wet surfaces
	"ssr_enabled": true,
	"ssr_max_steps": 64,
	"ssr_fade_in": 0.15,
	"ssr_fade_out": 2.0,
	"ssr_depth_tolerance": 0.2
}

# =============================================================================
# BIOME-SPECIFIC LIGHTING ADJUSTMENTS
# =============================================================================

## Per-biome lighting modifiers (applied additively/multiplicatively to base)
const BIOME_LIGHTING_MODIFIERS: Dictionary = {
	# Forest Floor: Absorptive - darker, high roughness shadows
	"FOREST": {
		"ambient_energy_mult": 0.85,  # Darker under canopy
		"fog_density_mult": 1.5,      # Misty forest floor
		"ssao_intensity_add": 0.5,    # Extra AO for debris/pine needles
	},
	
	# Swamplands: Reflective/Viscous - wet patches with glints
	"SWAMP": {
		"ambient_energy_mult": 0.9,
		"fog_density_mult": 2.0,      # Heavy swamp fog
		"fog_light_color": Color(0.50, 0.55, 0.50, 1.0),  # Greenish fog
		"ssr_enabled": true,          # Reflections for water
	},
	
	# Ashlands: Flat and Desaturated - "dead" look
	"ASHLANDS": {
		"ambient_energy_mult": 0.75,  # Heavy, oppressive
		"saturation_mult": 0.7,       # Extra desaturation
		"fog_light_color": Color(0.45, 0.43, 0.42, 1.0),  # Soot-colored
		"fog_density_mult": 1.8,      # Ash haze
		"ssao_intensity_add": -0.3,   # Less AO - flat look
		"light_energy_mult": 0.85,    # Reduced light bounce
	},
	
	# Frozen Peaks: Cold, bright, icy
	"PEAKS": {
		"ambient_color": Color(0.55, 0.60, 0.70, 1.0),  # Blue-tinted ambient
		"fog_light_color": Color(0.75, 0.80, 0.90, 1.0), # Icy white fog
		"fog_density_mult": 0.8,
		"light_energy_mult": 1.1,     # Brighter - snow reflection
	},
	
	# Wastes: Dry, dusty, harsh light
	"WASTES": {
		"fog_light_color": Color(0.65, 0.58, 0.50, 1.0),  # Dusty tan
		"fog_density_mult": 1.3,
		"saturation_mult": 0.9,
	},
	
	# Plains: Standard overcast
	"PLAINS": {
		# Use base profile
	},
	
	# Hills: Slightly misty
	"HILLS": {
		"fog_density_mult": 1.2,
	}
}

# =============================================================================
# ENVIRONMENT CREATION
# =============================================================================

## Create a Manor Lords-style Environment resource
static func create_environment() -> Environment:
	var env := Environment.new()
	
	# Background - Procedural sky
	env.background_mode = Environment.BG_SKY
	env.sky = _create_overcast_sky()
	
	# Ambient light - Sky-based with color tint
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = OVERCAST_PROFILE.ambient_color
	env.ambient_light_energy = OVERCAST_PROFILE.ambient_energy
	env.ambient_light_sky_contribution = 0.5
	
	# Reflected light
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	
	# Tonemap - ACES Filmic for photorealistic look
	env.tonemap_mode = OVERCAST_PROFILE.tonemap_mode
	env.tonemap_exposure = OVERCAST_PROFILE.tonemap_exposure
	env.tonemap_white = OVERCAST_PROFILE.tonemap_white
	
	# Color adjustments - Muted medieval palette
	env.adjustment_enabled = true
	env.adjustment_brightness = OVERCAST_PROFILE.adjustment_brightness
	env.adjustment_contrast = OVERCAST_PROFILE.adjustment_contrast
	env.adjustment_saturation = OVERCAST_PROFILE.adjustment_saturation
	
	# SSAO - Critical for Manor Lords aesthetic
	env.ssao_enabled = OVERCAST_PROFILE.ssao_enabled
	env.ssao_radius = OVERCAST_PROFILE.ssao_radius
	env.ssao_intensity = OVERCAST_PROFILE.ssao_intensity
	env.ssao_power = OVERCAST_PROFILE.ssao_power
	env.ssao_detail = OVERCAST_PROFILE.ssao_detail
	env.ssao_horizon = OVERCAST_PROFILE.ssao_horizon
	env.ssao_sharpness = OVERCAST_PROFILE.ssao_sharpness
	env.ssao_light_affect = OVERCAST_PROFILE.ssao_light_affect
	
	# Fog - Atmospheric perspective (blue-grey distance fog)
	env.fog_enabled = OVERCAST_PROFILE.fog_enabled
	env.fog_light_color = OVERCAST_PROFILE.fog_light_color
	env.fog_light_energy = OVERCAST_PROFILE.fog_light_energy
	env.fog_density = OVERCAST_PROFILE.fog_density
	env.fog_aerial_perspective = OVERCAST_PROFILE.fog_aerial_perspective
	env.fog_sky_affect = OVERCAST_PROFILE.fog_sky_affect
	
	# Volumetric fog for atmospheric haze
	env.volumetric_fog_enabled = OVERCAST_PROFILE.volumetric_fog_enabled
	env.volumetric_fog_density = OVERCAST_PROFILE.volumetric_fog_density
	env.volumetric_fog_albedo = OVERCAST_PROFILE.volumetric_fog_albedo
	env.volumetric_fog_emission = OVERCAST_PROFILE.volumetric_fog_emission
	env.volumetric_fog_emission_energy = OVERCAST_PROFILE.volumetric_fog_emission_energy
	env.volumetric_fog_anisotropy = OVERCAST_PROFILE.volumetric_fog_anisotropy
	env.volumetric_fog_length = OVERCAST_PROFILE.volumetric_fog_length
	env.volumetric_fog_detail_spread = OVERCAST_PROFILE.volumetric_fog_detail_spread
	
	# Glow - Minimal, natural
	env.glow_enabled = OVERCAST_PROFILE.glow_enabled
	env.glow_intensity = OVERCAST_PROFILE.glow_intensity
	env.glow_strength = OVERCAST_PROFILE.glow_strength
	env.glow_bloom = OVERCAST_PROFILE.glow_bloom
	env.glow_blend_mode = OVERCAST_PROFILE.glow_blend_mode
	
	# SSR for wet surface reflections
	env.ssr_enabled = OVERCAST_PROFILE.ssr_enabled
	env.ssr_max_steps = OVERCAST_PROFILE.ssr_max_steps
	env.ssr_fade_in = OVERCAST_PROFILE.ssr_fade_in
	env.ssr_fade_out = OVERCAST_PROFILE.ssr_fade_out
	env.ssr_depth_tolerance = OVERCAST_PROFILE.ssr_depth_tolerance
	
	return env


## Create an overcast procedural sky
static func _create_overcast_sky() -> Sky:
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	
	# "Damp Morning" / "Slate Grey" overcast sky
	sky_material.sky_top_color = OVERCAST_PROFILE.sky_top_color
	sky_material.sky_horizon_color = OVERCAST_PROFILE.sky_horizon_color
	sky_material.ground_bottom_color = OVERCAST_PROFILE.ground_bottom_color
	sky_material.ground_horizon_color = OVERCAST_PROFILE.ground_horizon_color
	
	# Sun settings - diffuse, not harsh
	sky_material.sun_angle_max = OVERCAST_PROFILE.sun_angle_max
	sky_material.sun_curve = 0.1  # Soft sun disk
	
	sky.sky_material = sky_material
	sky.radiance_size = Sky.RADIANCE_SIZE_256  # For good ambient lighting
	
	return sky


## Create the main directional light with soft shadows
static func create_directional_light() -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.name = "MainLight"
	
	# Cool neutral daylight (NOT golden hour)
	light.light_color = OVERCAST_PROFILE.light_color
	light.light_energy = OVERCAST_PROFILE.light_energy
	light.light_indirect_energy = OVERCAST_PROFILE.light_indirect_energy
	
	# Soft shadow settings - "soft-box effect" with blurred edges
	light.shadow_enabled = true
	light.shadow_bias = OVERCAST_PROFILE.shadow_bias
	light.shadow_normal_bias = OVERCAST_PROFILE.shadow_normal_bias
	light.shadow_blur = OVERCAST_PROFILE.shadow_blur
	
	# Shadow cascade settings for quality
	light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	light.directional_shadow_max_distance = 80.0
	light.directional_shadow_split_1 = 0.1
	light.directional_shadow_split_2 = 0.25
	light.directional_shadow_split_3 = 0.5
	light.directional_shadow_fade_start = 0.9
	
	# Position for diffuse overcast lighting
	# High angle for even illumination across the board
	light.transform = Transform3D(
		Basis(Vector3(0.866, -0.354, 0.354), Vector3(0, 0.707, 0.707), Vector3(-0.5, -0.612, 0.612)),
		Vector3(10, 20, 10)
	)
	light.rotation_degrees = Vector3(-50, -30, 0)  # High overcast angle
	
	return light


## Create a secondary fill light for softer shadows
static func create_fill_light() -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.name = "FillLight"
	
	# Cooler, dimmer fill light from opposite direction
	light.light_color = Color(0.70, 0.72, 0.78, 1.0)  # Cool blue-grey
	light.light_energy = 0.25  # Subtle fill
	light.light_indirect_energy = 0.2
	
	# No shadows from fill light
	light.shadow_enabled = false
	
	# Position opposite to main light
	light.rotation_degrees = Vector3(-40, 150, 0)
	
	return light


# =============================================================================
# BIOME-SPECIFIC ADJUSTMENTS
# =============================================================================

## Get biome-specific environment adjustments
## These can be applied dynamically based on camera focus
static func get_biome_modifiers(biome_name: String) -> Dictionary:
	return BIOME_LIGHTING_MODIFIERS.get(biome_name, {})


## Apply biome-specific modifications to an environment
static func apply_biome_modifiers(env: Environment, biome_name: String) -> void:
	var mods := get_biome_modifiers(biome_name)
	if mods.is_empty():
		return
	
	# Apply multiplicative modifiers
	if mods.has("ambient_energy_mult"):
		env.ambient_light_energy = OVERCAST_PROFILE.ambient_energy * mods.ambient_energy_mult
	
	if mods.has("fog_density_mult"):
		env.fog_density = OVERCAST_PROFILE.fog_density * mods.fog_density_mult
	
	if mods.has("saturation_mult"):
		env.adjustment_saturation = OVERCAST_PROFILE.adjustment_saturation * mods.saturation_mult
	
	if mods.has("light_energy_mult"):
		# Note: This would need to be applied to the DirectionalLight3D separately
		pass
	
	# Apply additive modifiers
	if mods.has("ssao_intensity_add"):
		env.ssao_intensity = OVERCAST_PROFILE.ssao_intensity + mods.ssao_intensity_add
	
	# Apply override modifiers
	if mods.has("fog_light_color"):
		env.fog_light_color = mods.fog_light_color
	
	if mods.has("ambient_color"):
		env.ambient_light_color = mods.ambient_color


## Reset environment to base overcast profile
static func reset_to_base_profile(env: Environment) -> void:
	env.ambient_light_energy = OVERCAST_PROFILE.ambient_energy
	env.ambient_light_color = OVERCAST_PROFILE.ambient_color
	env.fog_density = OVERCAST_PROFILE.fog_density
	env.fog_light_color = OVERCAST_PROFILE.fog_light_color
	env.adjustment_saturation = OVERCAST_PROFILE.adjustment_saturation
	env.ssao_intensity = OVERCAST_PROFILE.ssao_intensity


# =============================================================================
# QUALITY SCALING
# =============================================================================

## Apply quality settings to environment (for performance scaling)
static func apply_quality_to_environment(env: Environment, quality_level: int) -> void:
	match quality_level:
		0:  # Low
			env.ssao_enabled = false
			env.ssr_enabled = false
			env.volumetric_fog_enabled = false
			env.glow_enabled = false
		1:  # Medium
			env.ssao_enabled = true
			env.ssao_intensity = OVERCAST_PROFILE.ssao_intensity * 0.7
			env.ssr_enabled = false
			env.volumetric_fog_enabled = false
			env.glow_enabled = true
			env.glow_intensity = OVERCAST_PROFILE.glow_intensity * 0.5
		2:  # High
			env.ssao_enabled = true
			env.ssao_intensity = OVERCAST_PROFILE.ssao_intensity
			env.ssr_enabled = true
			env.ssr_max_steps = 32
			env.volumetric_fog_enabled = true
			env.volumetric_fog_density = OVERCAST_PROFILE.volumetric_fog_density * 0.7
			env.glow_enabled = true
		3:  # Ultra
			env.ssao_enabled = true
			env.ssao_intensity = OVERCAST_PROFILE.ssao_intensity
			env.ssr_enabled = true
			env.ssr_max_steps = OVERCAST_PROFILE.ssr_max_steps
			env.volumetric_fog_enabled = true
			env.volumetric_fog_density = OVERCAST_PROFILE.volumetric_fog_density
			env.glow_enabled = true
