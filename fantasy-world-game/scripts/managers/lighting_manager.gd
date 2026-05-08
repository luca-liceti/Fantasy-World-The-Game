## Lighting Manager
## Implements a gritty, realistic cinematic golden hour lighting.
## Features: Static high-contrast golden hour mood, deep shadows.
class_name LightingManager
extends RefCounted

# =============================================================================
# CINEMATIC REALISTIC GOLDEN HOUR PROFILE
# =============================================================================

const GOLDEN_HOUR_PROFILE: Dictionary = {
	# Sky colors - realistic twilight, gritty and desaturated
	"sky_top_color": Color(0.15, 0.20, 0.30, 1.0),
	"sky_horizon_color": Color(0.85, 0.50, 0.25, 1.0),
	"ground_bottom_color": Color(0.05, 0.04, 0.03, 1.0),
	"ground_horizon_color": Color(0.18, 0.12, 0.08, 1.0),
	
	# Sun settings
	"sun_angle_max": 2.5,
	
	# Directional Light
	"light_color": Color(0.95, 0.82, 0.65, 1.0),
	"light_energy": 1.5,
	"light_indirect_energy": 0.5,
	"light_specular": 0.5,
	"shadow_bias": 0.1,
	"shadow_normal_bias": 2.5,
	"shadow_blur": 1.5,
	
	# Ambient Light - subtle and moody
	"ambient_color": Color(0.35, 0.32, 0.28, 1.0),
	"ambient_energy": 0.3,
	
	# Fog - slight atmospheric scattering
	"fog_enabled": true,
	"fog_light_color": Color(0.65, 0.50, 0.38, 1.0),
	"fog_light_energy": 0.3,
	"fog_density": 0.001,
	"fog_aerial_perspective": 0.5,
	"fog_sky_affect": 0.5,
	
	# Tonemap - realistic contrast (ACES)
	"tonemap_mode": Environment.TONE_MAPPER_ACES,
	"tonemap_exposure": 1.1,
	"tonemap_white": 0.9,
	
	# Post-processing - gritty, slightly desaturated
	"adjustment_brightness": 1.0,
	"adjustment_contrast": 1.25,
	"adjustment_saturation": 0.95,
	
	# SSAO
	"ssao_enabled": true,
	"ssao_radius": 1.2,
	"ssao_intensity": 2.5,
	"ssao_power": 1.5,
	"ssao_detail": 0.8,
	"ssao_horizon": 0.06,
	"ssao_sharpness": 0.98,
	"ssao_light_affect": 0.8,
	
	# Volumetric fog
	"volumetric_fog_enabled": true,
	"volumetric_fog_density": 0.005,
	"volumetric_fog_albedo": Color(0.80, 0.65, 0.50, 1.0),
	"volumetric_fog_emission": Color(0.0, 0.0, 0.0, 1.0),
	"volumetric_fog_emission_energy": 0.0,
	"volumetric_fog_anisotropy": 0.5,
	"volumetric_fog_length": 64.0,
	"volumetric_fog_detail_spread": 2.0,
	
	# Glow
	"glow_enabled": true,
	"glow_intensity": 0.8,
	"glow_strength": 0.9,
	"glow_bloom": 0.05,
	"glow_blend_mode": Environment.GLOW_BLEND_MODE_ADDITIVE,
	
	# SSR
	"ssr_enabled": false,
	"ssr_max_steps": 64,
	"ssr_fade_in": 0.15,
	"ssr_fade_out": 2.0,
	"ssr_depth_tolerance": 0.2
}

# =============================================================================
# ENVIRONMENT CREATION
# =============================================================================

static func create_environment() -> Environment:
	var env := Environment.new()
	
	# Background
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
	
	# Fog
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
	sky_material.sun_curve = 0.08
	
	sky.sky_material = sky_material
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	
	return sky


static func create_directional_light() -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.name = "MainLight"
	
	light.light_color = GOLDEN_HOUR_PROFILE.light_color
	light.light_energy = 1.5 
	light.light_indirect_energy = GOLDEN_HOUR_PROFILE.light_indirect_energy
	light.light_specular = GOLDEN_HOUR_PROFILE.get("light_specular", 1.0)
	
	light.shadow_enabled = true
	light.shadow_bias = GOLDEN_HOUR_PROFILE.shadow_bias
	light.shadow_normal_bias = GOLDEN_HOUR_PROFILE.shadow_normal_bias
	light.shadow_blur = GOLDEN_HOUR_PROFILE.shadow_blur
	
	light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	light.directional_shadow_max_distance = 60.0
	light.directional_shadow_fade_start = 0.85
	
	# Raised pitch to avoid massive tree shadows, rotated 180 deg to opposing corner
	light.rotation_degrees = Vector3(-35, -150, 0)
	
	return light


static func create_fill_light() -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.name = "FillLight"
	
	# Stronger, cool fill to keep shadowed areas visible (board gameplay clarity)
	light.light_color = Color(0.40, 0.45, 0.55, 1.0)
	light.light_energy = 0.7
	light.light_indirect_energy = 0.3
	
	light.shadow_enabled = false
	
	# Opposite to main light
	light.rotation_degrees = Vector3(-35, 30, 0)
	
	return light


static func create_rim_light() -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.name = "RimLight"
	
	# Cool blue rim light hitting from behind to separate trees/troops from background
	light.light_color = Color(0.5, 0.6, 0.8, 1.0)
	light.light_energy = 0.6
	light.light_indirect_energy = 0.0
	
	light.shadow_enabled = false
	
	# Very low angle, rotated 180 deg
	light.rotation_degrees = Vector3(-10, -60, 0)
	
	return light


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
