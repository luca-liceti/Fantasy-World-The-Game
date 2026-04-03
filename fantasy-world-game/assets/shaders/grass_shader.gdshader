shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, depth_prepass_alpha, diffuse_burley, specular_schlick_ggx;

// =============================================================================
// MANOR LORDS STYLE GRASS SHADER
// =============================================================================
// Features:
// - Alpha-tested grass clump texture with biome-specific tinting
// - World-space wind with noise propagation
// - Terrain color blending at base for seamless ground integration
// - Subsurface scattering / transmittance for realistic light
// - Per-instance color variation for natural look
// =============================================================================

// Grass texture
uniform sampler2D grass_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform float alpha_scissor : hint_range(0.0, 1.0) = 0.35;

// Color tinting (multiplied with texture)
uniform vec4 color_tint : source_color = vec4(0.75, 0.85, 0.65, 1.0);
uniform float color_variation : hint_range(0.0, 0.5) = 0.12;

// Terrain blending - blend grass base with ground color
uniform vec4 terrain_color : source_color = vec4(0.12, 0.10, 0.07, 1.0);
uniform float terrain_blend_height : hint_range(0.0, 0.5) = 0.25;

// Wind parameters - world space wave propagation
uniform float wind_strength : hint_range(0.0, 0.5) = 0.10;
uniform float wind_speed : hint_range(0.0, 3.0) = 0.7;
uniform vec2 wind_direction = vec2(1.0, 0.3);
uniform float wind_wave_size : hint_range(0.5, 5.0) = 2.0;
uniform float wind_turbulence : hint_range(0.0, 1.0) = 0.20;

// Subsurface scattering (backlit glow)
uniform float sss_strength : hint_range(0.0, 1.0) = 0.35;
uniform vec4 sss_color : source_color = vec4(0.45, 0.65, 0.25, 1.0);

// Ambient / shadow softening
uniform float ambient_boost : hint_range(0.0, 0.5) = 0.12;
uniform float ao_strength : hint_range(0.0, 1.0) = 0.55;

// Varyings
varying float v_height;
varying vec3 v_world_pos;
varying float v_random;
varying float v_random2;

// Noise function for natural variation
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	// World position for wind calculation
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	// Height factor from UV (0 = base, 1 = tip)
	// Invert because UV.y = 0 is top, 1 is bottom for our texture
	v_height = 1.0 - UV.y;
	
	// Per-instance random for variation (using world position)
	v_random = fract(sin(dot(v_world_pos.xz, vec2(12.9898, 78.233))) * 43758.5453);
	v_random2 = fract(sin(dot(v_world_pos.xz, vec2(93.989, 17.731))) * 24871.3318);
	
	// ==========================================================
	// WORLD-SPACE WIND ANIMATION (Manor Lords style waves)
	// ==========================================================
	float time = TIME * wind_speed;
	vec2 wind_dir = normalize(wind_direction);
	
	// World-space wave position (wind travels across field)
	float wave_pos = dot(v_world_pos.xz, wind_dir) / wind_wave_size;
	
	// Primary wave - large slow movement (the "wave" rolling across the field)
	float wave1 = sin(time + wave_pos);
	
	// Secondary wave - different frequency for complexity
	float wave2 = sin(time * 0.7 + wave_pos * 1.5) * 0.5;
	
	// Tertiary turbulence - smaller faster per-blade detail
	float wave3 = sin(time * 2.1 + wave_pos * 3.0 + v_random * 6.28) * wind_turbulence;
	
	// Combined wind effect with smooth blending
	float wind_wave = wave1 + wave2 * 0.4 + wave3 * 0.3;
	
	// Apply only to top of blade (squared for smooth anchor at base)
	float height_mask = v_height * v_height;
	float wind_offset = wind_wave * wind_strength * height_mask;
	
	// Add per-instance phase offset for natural variation
	wind_offset *= (0.7 + v_random * 0.6);
	
	// Apply wind displacement
	VERTEX.x += wind_dir.x * wind_offset;
	VERTEX.z += wind_dir.y * wind_offset;
	VERTEX.y -= abs(wind_offset) * 0.12; // Slight droop when bent
	
	// ==========================================================
	// UPWARD NORMALS for uniform lighting
	// ==========================================================
	// Point normals upward to avoid harsh dark spots on thin blades
	NORMAL = vec3(0.0, 1.0, 0.0);
}

void fragment() {
	// Sample grass texture
	vec4 tex = texture(grass_texture, UV);
	
	// Native alpha scissoring (allows Godot to optimize Z-testing and depth prepass)
	ALPHA = tex.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor;
	
	// ==========================================================
	// COLOR WITH BIOME TINTING AND VARIATION
	// ==========================================================
	vec3 grass_color = tex.rgb * color_tint.rgb;
	
	// Per-instance color variation (hue shift toward yellow or darker green)
	float hue_shift = (v_random - 0.5) * color_variation * 2.0;
	grass_color.r += hue_shift * 0.15;
	grass_color.g += hue_shift * 0.05;
	grass_color.b -= hue_shift * 0.1;
	
	// Brightness variation
	float brightness_var = 0.88 + v_random2 * 0.24;
	grass_color *= brightness_var;
	
	// Tip brightening (light hits tops more)
	grass_color += vec3(0.03, 0.04, 0.01) * v_height;
	
	// ==========================================================
	// TERRAIN BLENDING (removes "floating" look)
	// ==========================================================
	float terrain_blend = smoothstep(terrain_blend_height, 0.0, v_height);
	grass_color = mix(grass_color, terrain_color.rgb, terrain_blend * 0.65);
	
	// Ambient boost to prevent pure black in shadows
	grass_color += vec3(0.015, 0.02, 0.008) * ambient_boost;
	
	// Clamp to avoid over-brightening
	grass_color = clamp(grass_color, vec3(0.0), vec3(1.0));
	
	ALBEDO = grass_color;
	
	// ==========================================================
	// PBR PROPERTIES
	// ==========================================================
	ROUGHNESS = 0.65 + v_random * 0.25;
	METALLIC = 0.0;
	SPECULAR = 0.25;
	
	// Ambient occlusion - darker at base, lighter at tips
	AO = mix(1.0 - ao_strength, 1.0, smoothstep(0.0, 0.5, v_height));
	
	// ==========================================================
	// SUBSURFACE SCATTERING (backlit glow - key for realism)
	// ==========================================================
	// Creates the beautiful "rim light" effect when looking toward the sun
	BACKLIGHT = sss_color.rgb * sss_strength * smoothstep(0.2, 0.8, v_height);
	
	// Transmittance for light passing through thin blades
	// SSS_STRENGTH = sss_strength * 0.4; // DISABLED: Triggers a massive GPU screen-space blur pass
}
