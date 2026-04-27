## Lighting Manager
## Implements evening/golden hour lighting with biome-specific variations
## Features: Golden hour mood, dramatic shadows, biome-dependent atmosphere
## Reference: Witcher 3, Medieval Dynasty - realistic, warm, atmospheric
class_name LightingManager
extends RefCounted

# =============================================================================
# EVENING GOLDEN HOUR PROFILE
# =============================================================================

## Global Lighting Profile - "Golden Hour Evening"
## Primary Source: Low angle warm sunlight
## Color Temp: Warm (3500K-4000K) for golden hour
const GOLDEN_HOUR_PROFILE: Dictionary = {
	# Sky colors - warm evening sky
	"sky_top_color": Color(0.12, 0.22, 0.42, 1.0),       # Deep blue-violet sky
	"sky_horizon_color": Color(0.90, 0.58, 0.32, 1.0),     # Rich warm orange horizon
	"ground_bottom_color": Color(0.08, 0.06, 0.05, 1.0), # Dark ground
	"ground_horizon_color": Color(0.22, 0.16, 0.10, 1.0),  # Warm brown ground
	
	# Sun settings - low evening angle
	"sun_angle_max": 4.0,    # Larger sun disk at low angle
	
	# Directional Light - Vibrant golden hour sunlight
	"light_color": Color(1.0, 0.88, 0.62, 1.0),    # Rich warm golden
	"light_energy": 2.0,     # Strong for vibrant terrain illumination
	"light_indirect_energy": 1.0,  # Strong bounce — fills shadow areas with warm light
	"light_specular": 1.0,  # Full specular for surface highlights
	"shadow_bias": 0.03,
	"shadow_normal_bias": 1.0,
	"shadow_blur": 0.6,   # Soft but defined shadows
	
	# Ambient Light - Warm but not washed out
	"ambient_color": Color(0.60, 0.48, 0.35, 1.0),  # Warm amber ambient
	"ambient_energy": 0.6,   # Moderate — let directional light do the heavy lifting
	
	# Fog - Warm evening haze
	"fog_enabled": true,
	"fog_light_color": Color(0.85, 0.62, 0.42, 1.0),   # Rich amber fog
	"fog_light_energy": 0.5,
	"fog_density": 0.0015,   # Slightly denser for atmosphere
	"fog_aerial_perspective": 0.6,
	"fog_sky_affect": 0.7,
	
	# Tonemap - ACES Filmic
	"tonemap_mode": Environment.TONE_MAPPER_ACES,  # ACES Filmic
	"tonemap_exposure": 1.05,
	"tonemap_white": 0.9,
	
	# Post-processing - vibrant, warm
	"adjustment_brightness": 1.08,
	"adjustment_contrast": 1.15,     # More dramatic contrast
	"adjustment_saturation": 1.2,    # Colors pop vibrantly
	
	# SSAO - Contact shadows for terrain depth
	"ssao_enabled": true,
	"ssao_radius": 1.5,
	"ssao_intensity": 2.0,
	"ssao_power": 1.5,
	"ssao_detail": 0.5,
	"ssao_horizon": 0.06,
	"ssao_sharpness": 0.98,
	"ssao_light_affect": 0.7,
	
	# Volumetric fog - evening haze
	"volumetric_fog_enabled": true,
	"volumetric_fog_density": 0.008,
	"volumetric_fog_albedo": Color(0.90, 0.72, 0.50, 1.0),  # Warm golden fog
	"volumetric_fog_emission": Color(0.0, 0.0, 0.0, 1.0),
	"volumetric_fog_emission_energy": 0.0,
	"volumetric_fog_anisotropy": 0.6,
	"volumetric_fog_length": 48.0,
	"volumetric_fog_detail_spread": 2.0,
	
	# Glow - vibrant warm bloom
	"glow_enabled": true,
	"glow_intensity": 0.9,
	"glow_strength": 1.0,
	"glow_bloom": 0.12,
	"glow_blend_mode": Environment.GLOW_BLEND_MODE_ADDITIVE,  # Additive
	
	# SSR - disabled: terrain surfaces are matte and should not reflect
	# (enabling SSR causes plastic-like reflections on grass/soil/bark)
	"ssr_enabled": false,
	"ssr_max_steps": 80,
	"ssr_fade_in": 0.15,
	"ssr_fade_out": 2.0,
	"ssr_depth_tolerance": 0.2
}

# =============================================================================
# BIOME-SPECIFIC PROFILES
# =============================================================================

const BIOME_PROFILES: Dictionary = {
	# PLAINS - Golden hour standard — vibrant warm meadows
	Biomes.Type.PLAINS: {
		"profile_name": "GOLDEN_HOUR",
		"ambient_energy_mult": 0.9,
		"fog_density_mult": 1.0,
		"fog_light_color": Color(0.85, 0.65, 0.42, 1.0),
		"ambient_color": Color(0.55, 0.45, 0.32, 1.0),
		"light_energy_mult": 1.0,
		"saturation_mult": 1.1,
		"ssao_intensity_add": 0.0,
		"glow_intensity_mult": 1.1,
	},
	
	# FOREST - Dappled gold through canopy — warm, rich, slightly dim
	Biomes.Type.FOREST: {
		"profile_name": "GOLDEN_HOUR_FILTERED",
		"ambient_energy_mult": 1.2,    # Bright enough to see trees
		"fog_density_mult": 1.3,        # Misty forest atmosphere
		"fog_light_color": Color(0.70, 0.60, 0.40, 1.0),  # Warm filtered
		"ambient_color": Color(0.55, 0.50, 0.35, 1.0),
		"light_energy_mult": 1.3,      # Sun breaking through canopy
		"saturation_mult": 1.05,        # Rich greens
		"ssao_intensity_add": 0.3,      # Strong AO for tree roots/debris
		"glow_intensity_mult": 1.4,     # God rays through trees
	},
	
	# HILLS - Open sky, clear, slightly elevated brightness
	Biomes.Type.HILLS: {
		"profile_name": "GOLDEN_HOUR",
		"ambient_energy_mult": 0.95,
		"fog_density_mult": 0.7,         # Clearer air on hilltops
		"fog_light_color": Color(0.88, 0.65, 0.45, 1.0),
		"ambient_color": Color(0.55, 0.48, 0.35, 1.0),
		"light_energy_mult": 1.15,
		"saturation_mult": 1.1,
		"ssao_intensity_add": 0.1,
		"glow_intensity_mult": 1.15,
	},
	
	# PEAKS - Alpine blue hour — crisp, bright snow reflections
	Biomes.Type.PEAKS: {
		"profile_name": "BLUE_HOUR",
		"ambient_energy_mult": 1.1,     # Snow reflects a lot
		"fog_density_mult": 0.5,         # Crystal clear mountain air
		"fog_light_color": Color(0.55, 0.65, 0.85, 1.0),  # Cool blue mist
		"ambient_color": Color(0.45, 0.52, 0.65, 1.0),    # Cool ambient
		"light_energy_mult": 1.2,       # Snow bounce
		"saturation_mult": 0.95,
		"ssao_intensity_add": -0.3,      # Snow flattens AO
		"glow_intensity_mult": 1.3,      # Bright snow sparkle
		"sky_top_color": Color(0.08, 0.18, 0.38, 1.0),
		"sky_horizon_color": Color(0.50, 0.55, 0.72, 1.0),
		"light_color": Color(0.75, 0.85, 1.0, 1.0),  # Cool crisp light
	},
	
	# SWAMP - Heavy overcast, murky green-grey, oppressive
	Biomes.Type.SWAMP: {
		"profile_name": "OVERCAST_MUTED",
		"ambient_energy_mult": 0.75,
		"fog_density_mult": 2.0,         # Thick swamp fog
		"fog_light_color": Color(0.40, 0.48, 0.38, 1.0),  # Green-grey miasma
		"ambient_color": Color(0.35, 0.38, 0.30, 1.0),
		"light_energy_mult": 0.7,
		"saturation_mult": 0.7,         # Desaturated, sickly
		"ssao_intensity_add": 0.2,
		"glow_intensity_mult": 0.4,     # Muted — no bright glow
		"light_color": Color(0.70, 0.68, 0.55, 1.0),  # Sickly warm
	},
	
	# ASHLANDS - Scorched, heavy, ember-lit darkness
	Biomes.Type.ASHLANDS: {
		"profile_name": "OVERCAST_HEAVY",
		"ambient_energy_mult": 0.6,
		"fog_density_mult": 1.8,         # Ash and soot haze
		"fog_light_color": Color(0.35, 0.30, 0.25, 1.0),  # Dark soot fog
		"ambient_color": Color(0.30, 0.25, 0.22, 1.0),
		"light_energy_mult": 0.65,
		"saturation_mult": 0.55,        # Very desaturated — ash covers everything
		"ssao_intensity_add": -0.4,      # Flat, heavy
		"glow_intensity_mult": 0.5,      # Ember glow only
		"light_color": Color(0.75, 0.60, 0.45, 1.0),  # Smoggy warm
	},
	
	# WASTES - Harsh desert sun, dusty glare
	Biomes.Type.WASTES: {
		"profile_name": "OVERCAST_DUSTY",
		"ambient_energy_mult": 0.85,
		"fog_density_mult": 1.5,         # Dust storms on the horizon
		"fog_light_color": Color(0.65, 0.55, 0.40, 1.0),  # Sandy dust
		"ambient_color": Color(0.50, 0.42, 0.32, 1.0),
		"light_energy_mult": 0.85,
		"saturation_mult": 0.80,
		"ssao_intensity_add": -0.1,
		"glow_intensity_mult": 0.8,
		"light_color": Color(0.90, 0.78, 0.55, 1.0),  # Hot dusty sun
	},
}

# =============================================================================
# ENVIRONMENT CREATION
# =============================================================================

static func create_golden_hour_environment() -> Environment:
	var env := Environment.new()
	
	# Background - Procedural sky
	env.background_mode = Environment.BG_SKY
	env.sky = _create_golden_hour_sky()
	
	# Ambient light
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = GOLDEN_HOUR_PROFILE.ambient_color
	env.ambient_light_energy = GOLDEN_HOUR_PROFILE.ambient_energy
	env.ambient_light_sky_contribution = 0.5
	
	# Reflected light
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	
	# Tonemap
	env.tonemap_mode = GOLDEN_HOUR_PROFILE.tonemap_mode as Environment.ToneMapper
	env.tonemap_exposure = GOLDEN_HOUR_PROFILE.tonemap_exposure
	env.tonemap_white = GOLDEN_HOUR_PROFILE.tonemap_white
	
	# Color adjustments
	env.adjustment_enabled = true
	env.adjustment_brightness = GOLDEN_HOUR_PROFILE.adjustment_brightness
	env.adjustment_contrast = GOLDEN_HOUR_PROFILE.adjustment_contrast
	env.adjustment_saturation = GOLDEN_HOUR_PROFILE.adjustment_saturation
	
	# SSAO
	env.ssao_enabled = GOLDEN_HOUR_PROFILE.ssao_enabled
	env.ssao_radius = GOLDEN_HOUR_PROFILE.ssao_radius
	env.ssao_intensity = GOLDEN_HOUR_PROFILE.ssao_intensity
	env.ssao_power = GOLDEN_HOUR_PROFILE.ssao_power
	env.ssao_detail = GOLDEN_HOUR_PROFILE.ssao_detail
	env.ssao_horizon = GOLDEN_HOUR_PROFILE.ssao_horizon
	env.ssao_sharpness = GOLDEN_HOUR_PROFILE.ssao_sharpness
	env.ssao_light_affect = GOLDEN_HOUR_PROFILE.ssao_light_affect
	
	# Fog - evening warmth
	env.fog_enabled = GOLDEN_HOUR_PROFILE.fog_enabled
	env.fog_light_color = GOLDEN_HOUR_PROFILE.fog_light_color
	env.fog_light_energy = GOLDEN_HOUR_PROFILE.fog_light_energy
	env.fog_density = GOLDEN_HOUR_PROFILE.fog_density
	env.fog_aerial_perspective = GOLDEN_HOUR_PROFILE.fog_aerial_perspective
	env.fog_sky_affect = GOLDEN_HOUR_PROFILE.fog_sky_affect
	
	# Volumetric fog
	env.volumetric_fog_enabled = GOLDEN_HOUR_PROFILE.volumetric_fog_enabled
	env.volumetric_fog_density = GOLDEN_HOUR_PROFILE.volumetric_fog_density
	env.volumetric_fog_albedo = GOLDEN_HOUR_PROFILE.volumetric_fog_albedo
	env.volumetric_fog_emission = GOLDEN_HOUR_PROFILE.volumetric_fog_emission
	env.volumetric_fog_emission_energy = GOLDEN_HOUR_PROFILE.volumetric_fog_emission_energy
	env.volumetric_fog_anisotropy = GOLDEN_HOUR_PROFILE.volumetric_fog_anisotropy
	env.volumetric_fog_length = GOLDEN_HOUR_PROFILE.volumetric_fog_length
	env.volumetric_fog_detail_spread = GOLDEN_HOUR_PROFILE.volumetric_fog_detail_spread
	
	# Glow
	env.glow_enabled = GOLDEN_HOUR_PROFILE.glow_enabled
	env.glow_intensity = GOLDEN_HOUR_PROFILE.glow_intensity
	env.glow_strength = GOLDEN_HOUR_PROFILE.glow_strength
	env.glow_bloom = GOLDEN_HOUR_PROFILE.glow_bloom
	env.glow_blend_mode = GOLDEN_HOUR_PROFILE.glow_blend_mode as Environment.GlowBlendMode
	
	# SSR
	env.ssr_enabled = GOLDEN_HOUR_PROFILE.ssr_enabled
	env.ssr_max_steps = GOLDEN_HOUR_PROFILE.ssr_max_steps
	env.ssr_fade_in = GOLDEN_HOUR_PROFILE.ssr_fade_in
	env.ssr_fade_out = GOLDEN_HOUR_PROFILE.ssr_fade_out
	env.ssr_depth_tolerance = GOLDEN_HOUR_PROFILE.ssr_depth_tolerance
	
	return env


static func _create_golden_hour_sky() -> Sky:
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	
	sky_material.sky_top_color = GOLDEN_HOUR_PROFILE.sky_top_color
	sky_material.sky_horizon_color = GOLDEN_HOUR_PROFILE.sky_horizon_color
	sky_material.ground_bottom_color = GOLDEN_HOUR_PROFILE.ground_bottom_color
	sky_material.ground_horizon_color = GOLDEN_HOUR_PROFILE.ground_horizon_color
	
	sky_material.sun_angle_max = GOLDEN_HOUR_PROFILE.sun_angle_max
	sky_material.sun_curve = 0.08  # Soft sun disk
	
	sky.sky_material = sky_material
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	
	return sky


static func create_directional_light() -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.name = "MainLight"
	
	light.light_color = GOLDEN_HOUR_PROFILE.light_color
	light.light_energy = GOLDEN_HOUR_PROFILE.light_energy
	light.light_indirect_energy = GOLDEN_HOUR_PROFILE.light_indirect_energy
	light.light_specular = GOLDEN_HOUR_PROFILE.get("light_specular", 1.0)
	
	light.shadow_enabled = true
	light.shadow_bias = GOLDEN_HOUR_PROFILE.shadow_bias
	light.shadow_normal_bias = GOLDEN_HOUR_PROFILE.shadow_normal_bias
	light.shadow_blur = GOLDEN_HOUR_PROFILE.shadow_blur
	
	light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	light.directional_shadow_max_distance = 80.0
	light.directional_shadow_split_1 = 0.1
	light.directional_shadow_split_2 = 0.25
	light.directional_shadow_split_3 = 0.5
	light.directional_shadow_fade_start = 0.9
	
	# Low evening angle (~25 degrees from horizon) for dramatic long shadows
	light.rotation_degrees = Vector3(-25, -35, 0)
	
	return light


static func create_fill_light() -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.name = "FillLight"
	
	# Cool blue fill from opposite direction (sky bounce)
	light.light_color = Color(0.50, 0.58, 0.75, 1.0)
	light.light_energy = 0.35
	light.light_indirect_energy = 0.2
	
	light.shadow_enabled = false
	
	# Opposite to main light
	light.rotation_degrees = Vector3(-20, 145, 0)
	
	return light


# =============================================================================
# BIOME-SPECIFIC ENVIRONMENT
# =============================================================================

static func create_environment_for_biome(biome_type: Biomes.Type) -> Environment:
	var env: Environment = create_golden_hour_environment()
	apply_biome_modifiers(env, biome_type)
	return env


static func apply_biome_modifiers(env: Environment, biome_type: Biomes.Type) -> void:
	if not BIOME_PROFILES.has(biome_type):
		return
	
	var mods: Dictionary = BIOME_PROFILES[biome_type]
	var profile: Dictionary = GOLDEN_HOUR_PROFILE
	
	# Apply multipliers
	if mods.has("ambient_energy_mult"):
		env.ambient_light_energy = profile.ambient_energy * mods.ambient_energy_mult
	
	if mods.has("fog_density_mult"):
		env.fog_density = profile.fog_density * mods.fog_density_mult
	
	if mods.has("saturation_mult"):
		env.adjustment_saturation = profile.adjustment_saturation * mods.saturation_mult
	
	# Apply colors
	if mods.has("fog_light_color"):
		env.fog_light_color = mods.fog_light_color
	
	if mods.has("ambient_color"):
		env.ambient_light_color = mods.ambient_color
	
	# Apply SSAO
	if mods.has("ssao_intensity_add"):
		env.ssao_intensity = profile.ssao_intensity + mods.ssao_intensity_add
	
	# Apply glow
	if mods.has("glow_intensity_mult"):
		env.glow_intensity = profile.glow_intensity * mods.glow_intensity_mult
	
	# Apply sky colors for special biomes (PEAKS blue hour)
	if mods.has("sky_top_color") and env.sky:
		var sky_mat: ProceduralSkyMaterial = env.sky.sky_material as ProceduralSkyMaterial
		if sky_mat:
			sky_mat.sky_top_color = mods.sky_top_color
			sky_mat.sky_horizon_color = mods.get("sky_horizon_color", mods.sky_top_color)


# =============================================================================
# LEGACY COMPATIBILITY (for backwards compatibility)
# =============================================================================

static func create_environment() -> Environment:
	return create_golden_hour_environment()


static func get_biome_modifiers(biome_type: Biomes.Type) -> Dictionary:
	return BIOME_PROFILES.get(biome_type, {})


static func reset_to_base_profile(env: Environment) -> void:
	env.ambient_light_energy = GOLDEN_HOUR_PROFILE.ambient_energy
	env.ambient_light_color = GOLDEN_HOUR_PROFILE.ambient_color
	env.fog_density = GOLDEN_HOUR_PROFILE.fog_density
	env.fog_light_color = GOLDEN_HOUR_PROFILE.fog_light_color
	env.adjustment_saturation = GOLDEN_HOUR_PROFILE.adjustment_saturation
	env.ssao_intensity = GOLDEN_HOUR_PROFILE.ssao_intensity


# =============================================================================
# QUALITY SCALING
# =============================================================================

static func apply_quality_to_environment(env: Environment, quality_level: int) -> void:
	match quality_level:
		0:  # Low
			env.ssao_enabled = false
			env.ssr_enabled = false
			env.volumetric_fog_enabled = false
			env.glow_enabled = false
		1:  # Medium
			env.ssao_enabled = true
			env.ssao_intensity = GOLDEN_HOUR_PROFILE.ssao_intensity * 0.7
			env.ssr_enabled = false
			env.volumetric_fog_enabled = false
			env.glow_enabled = true
			env.glow_intensity = GOLDEN_HOUR_PROFILE.glow_intensity * 0.5
		2:  # High
			env.ssao_enabled = true
			env.ssao_intensity = GOLDEN_HOUR_PROFILE.ssao_intensity
			env.ssr_enabled = true
			env.ssr_max_steps = 32
			env.volumetric_fog_enabled = true
			env.volumetric_fog_density = GOLDEN_HOUR_PROFILE.volumetric_fog_density * 0.7
			env.glow_enabled = true
		3:  # Ultra
			env.ssao_enabled = true
			env.ssao_intensity = GOLDEN_HOUR_PROFILE.ssao_intensity
			env.ssr_enabled = true
			env.ssr_max_steps = GOLDEN_HOUR_PROFILE.ssr_max_steps
			env.volumetric_fog_enabled = true
			env.volumetric_fog_density = GOLDEN_HOUR_PROFILE.volumetric_fog_density
			env.glow_enabled = true
