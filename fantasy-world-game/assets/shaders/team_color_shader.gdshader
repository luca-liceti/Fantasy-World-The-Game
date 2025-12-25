shader_type spatial;
render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx;

// =============================================================================
// TEAM COLOR SHADER
// =============================================================================
// This shader allows recoloring troop models with team-specific colors.
// Uses a mask texture to define which areas receive primary vs accent colors.
// 
// Mask Channels:
// - Red channel: Areas for primary team color (armor plates, cloth)
// - Green channel: Areas for accent color (metal trim, details)
// - Blue channel: Reserved for magical glow effects (Phase 2)

// Base PBR textures
uniform sampler2D albedo_texture : source_color;
uniform sampler2D normal_texture : hint_normal;
uniform sampler2D roughness_texture : hint_default_white;
uniform sampler2D metallic_texture : hint_default_black;
uniform sampler2D ao_texture : hint_default_white;

// Team color parameters
uniform vec3 team_primary_color : source_color = vec3(0.24, 0.31, 0.39); // Default Player 1 Faded Navy
uniform vec3 team_accent_color : source_color = vec3(0.66, 0.71, 0.75);  // Default Player 1 Weathered Steel
uniform float team_color_intensity : hint_range(0.0, 1.0) = 0.7;

// Mask texture (R = primary areas, G = accent areas, B = glow areas)
uniform sampler2D team_mask_texture : hint_default_black;

// Glow parameters (for magical effects - Phase 2)
uniform vec3 glow_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.0;
uniform float glow_pulse_speed : hint_range(0.0, 5.0) = 0.0;

// Material adjustments
uniform float roughness_multiplier : hint_range(0.0, 2.0) = 1.0;
uniform float metallic_multiplier : hint_range(0.0, 2.0) = 1.0;

void fragment() {
    // Sample base textures
    vec4 albedo = texture(albedo_texture, UV);
    vec3 normal_map = texture(normal_texture, UV).rgb;
    float roughness = texture(roughness_texture, UV).r * roughness_multiplier;
    float metallic = texture(metallic_texture, UV).r * metallic_multiplier;
    float ao = texture(ao_texture, UV).r;
    
    // Sample team mask
    vec3 mask = texture(team_mask_texture, UV).rgb;
    
    // Apply team colors based on mask
    vec3 colored = albedo.rgb;
    
    // Primary color application (mask.r controls intensity)
    colored = mix(colored, team_primary_color * albedo.rgb, mask.r * team_color_intensity);
    
    // Accent color application (mask.g controls intensity)
    colored = mix(colored, team_accent_color * albedo.rgb, mask.g * team_color_intensity);
    
    // Apply glow effect (mask.b controls glow areas)
    float glow_pulse = 1.0;
    if (glow_pulse_speed > 0.0) {
        glow_pulse = 0.5 + 0.5 * sin(TIME * glow_pulse_speed);
    }
    vec3 glow = glow_color * mask.b * glow_intensity * glow_pulse;
    
    // Combine with ambient occlusion
    colored = colored * ao;
    
    // Output
    ALBEDO = colored;
    NORMAL_MAP = normal_map;
    ROUGHNESS = clamp(roughness, 0.0, 1.0);
    METALLIC = clamp(metallic, 0.0, 1.0);
    
    // Add emission for glow areas
    if (glow_intensity > 0.0) {
        EMISSION = glow;
    }
}

// =============================================================================
// TEAM COLOR PRESETS (for reference in GDScript)
// =============================================================================
// Player 1 (Blue/Steel):
//   Primary: vec3(0.24, 0.31, 0.39)  - Faded Navy
//   Accent:  vec3(0.66, 0.71, 0.75)  - Weathered Steel
//
// Player 2 (Red/Bronze):
//   Primary: vec3(0.42, 0.17, 0.17)  - Deep Burgundy
//   Accent:  vec3(0.61, 0.46, 0.33)  - Tarnished Bronze
//
// Player 3 (Green/Gold) - Future expansion:
//   Primary: vec3(0.18, 0.35, 0.20)  - Forest Green
//   Accent:  vec3(0.72, 0.64, 0.35)  - Aged Gold
//
// Player 4 (Purple/Silver) - Future expansion:
//   Primary: vec3(0.30, 0.18, 0.38)  - Royal Purple
//   Accent:  vec3(0.75, 0.75, 0.80)  - Polished Silver
