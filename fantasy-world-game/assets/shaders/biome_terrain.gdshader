shader_type spatial;
render_mode depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

// =============================================================================
// BIOME TERRAIN SHADER — Optimised Stochastic Sampling
// =============================================================================
// Stochastic sampling eliminates visible texture tiling repetition.
// Reference: "Histogram-Preserving Blending for Randomized Texture Tiling"
//            Heitz & Neyret 2018 — simplified version for real-time use.
//
// PERFORMANCE NOTES (vs original):
//  • Parallax/displacement pass removed — 12 fetch saves per fragment
//  • Plain-sample fallback path removed (stochastic_strength always 1.0)
//  • Only Y-axis triplanar used for nearly-flat hex tiles (3× less fetches)
//    X/Z planes are blended in only when the surface is steep
//  • Total texture reads: ~9-12 per fragment (down from ~60)
// =============================================================================

// --- PBR Texture Maps ---
uniform sampler2D texture_albedo   : source_color,        filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D texture_normal   : hint_normal,          filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D texture_roughness: hint_default_white,   filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D texture_ao       : hint_default_white,   filter_linear_mipmap_anisotropic, repeat_enable;

// --- World-Space Tiling ---
// Controls how densely the texture tiles in world space.
// Lower = larger texel footprint. Matches TEXTURE_SCALE in GDScript.
uniform float texture_scale : hint_range(0.05, 2.0) = 0.3;

// --- Triplanar blending sharpness (higher = sharper XYZ seams) ---
// Used only for steep surfaces. Flat tiles use Y-only.
uniform float triplanar_sharpness : hint_range(1.0, 16.0) = 8.0;

// --- Stochastic cell size (world units) ---
// Controls how large each randomly-oriented patch is.
// Should be 2-4x the texture period for good coverage.
uniform float stochastic_cell_size : hint_range(0.5, 10.0) = 3.0;

// --- PBR base overrides ---
uniform float roughness_override : hint_range(0.0, 1.0) = 1.0;
uniform float normal_scale       : hint_range(0.0, 3.0)  = 1.3;
uniform float ao_intensity       : hint_range(0.0, 1.0)  = 0.5;
// Brightness at 1.0 — spot lights above the board already provide the right level
uniform float brightness         : hint_range(0.5, 2.0)  = 1.0;
uniform vec4  albedo_tint        : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// Specular 0.0 — terrain is matte/diffuse, not reflective (prevents plastic look)
uniform float specular_override  : hint_range(0.0, 1.0)  = 0.0;
uniform float metallic_override  : hint_range(0.0, 1.0)  = 0.0;

// =============================================================================
// HASH / NOISE HELPERS
// =============================================================================

// 2-D → 1-D hash (returns value in [0,1])
float hash21(vec2 p) {
	p  = fract(p * vec2(127.1, 311.7));
	p += dot(p, p + 19.19);
	return fract(p.x * p.y);
}

// 2-D → 2-D hash (returns vector with components in [-1,1])
vec2 hash22(vec2 p) {
	vec2 q = vec2(dot(p, vec2(127.1, 311.7)),
	              dot(p, vec2(269.5, 183.3)));
	return fract(sin(q) * 43758.5453) * 2.0 - 1.0;
}

// =============================================================================
// STOCHASTIC TEXTURE SAMPLING
// =============================================================================
// Divides UV space into jittered cells. Inside each cell the texture is
// sampled with a unique random rotation + offset, then three neighbouring
// cells are blended with smooth weights to avoid hard seams.
// Plain fallback and stochastic_strength lerp are removed — we always use
// full stochastic (the only mode that matters visually and for performance it
// is actually cheaper than branching between two full paths).
// =============================================================================

// Compute stochastic blend weights + rotations for a UV position
// Returns weights in w, rotation matrices in rot0/rot1/rot2,
// and the three transformed UVs in uv0/uv1/uv2.
void stochastic_setup(vec2 uv, float cell,
		out vec3 w,
		out vec2 uv0, out vec2 uv1, out vec2 uv2) {
	const mat2 skew   = mat2(vec2(1.0, 0.577), vec2(0.0, 1.155));
	const mat2 unskew = mat2(vec2(1.0, -0.5),  vec2(0.0, 0.866));

	vec2 grid_uv   = skew * (uv / cell);
	vec2 grid_id   = floor(grid_uv);
	vec2 grid_frac = fract(grid_uv);

	vec2 v0, v1, v2;
	if (grid_frac.x > grid_frac.y) {
		v0 = vec2(1.0, 0.0); v1 = vec2(1.0, 1.0); v2 = vec2(0.0, 0.0);
	} else {
		v0 = vec2(0.0, 1.0); v1 = vec2(1.0, 1.0); v2 = vec2(0.0, 0.0);
	}

	w.x = 1.0 - distance(grid_frac, v0);
	w.y = 1.0 - distance(grid_frac, v1);
	w.z = 1.0 - distance(grid_frac, v2);
	w = pow(max(w, vec3(0.0)), vec3(7.0));
	w /= (w.x + w.y + w.z);

	float r0 = hash21(grid_id + v0) * 6.2832;
	float r1 = hash21(grid_id + v1) * 6.2832;
	float r2 = hash21(grid_id + v2) * 6.2832;

	vec2 o0 = hash22(grid_id + v0) * 0.5;
	vec2 o1 = hash22(grid_id + v1) * 0.5;
	vec2 o2 = hash22(grid_id + v2) * 0.5;

	vec2 cell_centre = unskew * (grid_id * cell);
	vec2 local_uv    = uv - cell_centre;

	mat2 rot0 = mat2(vec2(cos(r0), -sin(r0)), vec2(sin(r0), cos(r0)));
	mat2 rot1 = mat2(vec2(cos(r1), -sin(r1)), vec2(sin(r1), cos(r1)));
	mat2 rot2 = mat2(vec2(cos(r2), -sin(r2)), vec2(sin(r2), cos(r2)));

	uv0 = rot0 * local_uv + o0 + cell_centre;
	uv1 = rot1 * local_uv + o1 + cell_centre;
	uv2 = rot2 * local_uv + o2 + cell_centre;
}

// Sample albedo stochastically (3 texture reads total)
vec4 stochastic_albedo(sampler2D tex, vec2 uv, float cell) {
	vec3 w; vec2 uv0, uv1, uv2;
	stochastic_setup(uv, cell, w, uv0, uv1, uv2);
	return w.x * texture(tex, uv0)
	     + w.y * texture(tex, uv1)
	     + w.z * texture(tex, uv2);
}

// Sample scalar map stochastically (roughness, AO — r channel)
float stochastic_scalar(sampler2D tex, vec2 uv, float cell) {
	vec3 w; vec2 uv0, uv1, uv2;
	stochastic_setup(uv, cell, w, uv0, uv1, uv2);
	return w.x * texture(tex, uv0).r
	     + w.y * texture(tex, uv1).r
	     + w.z * texture(tex, uv2).r;
}

// Sample normal map stochastically (XY rotated to match UV rotation)
vec3 stochastic_normal_vec(sampler2D tex, vec2 uv, float cell) {
	const mat2 skew   = mat2(vec2(1.0, 0.577), vec2(0.0, 1.155));
	const mat2 unskew = mat2(vec2(1.0, -0.5),  vec2(0.0, 0.866));

	vec2 grid_uv   = skew * (uv / cell);
	vec2 grid_id   = floor(grid_uv);
	vec2 grid_frac = fract(grid_uv);

	vec2 v0, v1, v2;
	if (grid_frac.x > grid_frac.y) {
		v0 = vec2(1.0, 0.0); v1 = vec2(1.0, 1.0); v2 = vec2(0.0, 0.0);
	} else {
		v0 = vec2(0.0, 1.0); v1 = vec2(1.0, 1.0); v2 = vec2(0.0, 0.0);
	}

	vec3 w;
	w.x = 1.0 - distance(grid_frac, v0);
	w.y = 1.0 - distance(grid_frac, v1);
	w.z = 1.0 - distance(grid_frac, v2);
	w = pow(max(w, vec3(0.0)), vec3(7.0));
	w /= (w.x + w.y + w.z);

	float r0 = hash21(grid_id + v0) * 6.2832;
	float r1 = hash21(grid_id + v1) * 6.2832;
	float r2 = hash21(grid_id + v2) * 6.2832;

	vec2 o0 = hash22(grid_id + v0) * 0.5;
	vec2 o1 = hash22(grid_id + v1) * 0.5;
	vec2 o2 = hash22(grid_id + v2) * 0.5;

	vec2 cell_centre = unskew * (grid_id * cell);
	vec2 local_uv    = uv - cell_centre;

	mat2 rot0 = mat2(vec2(cos(r0), -sin(r0)), vec2(sin(r0), cos(r0)));
	mat2 rot1 = mat2(vec2(cos(r1), -sin(r1)), vec2(sin(r1), cos(r1)));
	mat2 rot2 = mat2(vec2(cos(r2), -sin(r2)), vec2(sin(r2), cos(r2)));

	vec2 uv0 = rot0 * local_uv + o0 + cell_centre;
	vec2 uv1 = rot1 * local_uv + o1 + cell_centre;
	vec2 uv2 = rot2 * local_uv + o2 + cell_centre;

	vec3 n0 = texture(tex, uv0).xyz * 2.0 - 1.0;
	vec3 n1 = texture(tex, uv1).xyz * 2.0 - 1.0;
	vec3 n2 = texture(tex, uv2).xyz * 2.0 - 1.0;

	// Rotate XY of each normal to match UV rotation
	n0.xy = rot0 * n0.xy;
	n1.xy = rot1 * n1.xy;
	n2.xy = rot2 * n2.xy;

	return normalize(w.x * n0 + w.y * n1 + w.z * n2);
}

// =============================================================================
// OPTIMISED TRIPLANAR HELPERS
// =============================================================================
// For nearly-flat hex tiles the Y-plane dominates (blend.y ≈ 0.95+).
// We only add X/Z contributions when the surface tilts noticeably
// (blend.y < 0.92), saving 2/3 of the texture reads on flat geometry.
// =============================================================================

vec3 triplanar_weights(vec3 normal, float sharpness) {
	vec3 w = pow(abs(normal), vec3(sharpness));
	return w / (w.x + w.y + w.z + 0.0001);
}

// Minimum Y-weight below which we include X/Z planes (steep surfaces only)
const float FLAT_THRESHOLD = 0.92;

vec4 triplanar_albedo_opt(sampler2D tex, vec3 world_pos, vec3 weights, float scale, float cell) {
	vec4 y = stochastic_albedo(tex, world_pos.xz * scale, cell);
	if (weights.y >= FLAT_THRESHOLD) {
		return y;
	}
	vec4 x = stochastic_albedo(tex, world_pos.zy * scale, cell);
	vec4 z = stochastic_albedo(tex, world_pos.xy * scale, cell);
	return x * weights.x + y * weights.y + z * weights.z;
}

float triplanar_scalar_opt(sampler2D tex, vec3 world_pos, vec3 weights, float scale, float cell) {
	float y = stochastic_scalar(tex, world_pos.xz * scale, cell);
	if (weights.y >= FLAT_THRESHOLD) {
		return y;
	}
	float x = stochastic_scalar(tex, world_pos.zy * scale, cell);
	float z = stochastic_scalar(tex, world_pos.xy * scale, cell);
	return x * weights.x + y * weights.y + z * weights.z;
}

vec3 triplanar_normal_opt(sampler2D tex, vec3 world_pos, vec3 world_normal, vec3 weights, float scale, float cell) {
	// Y-plane normal: XZ UV, straightforward mapping
	vec3 ny_raw = stochastic_normal_vec(tex, world_pos.xz * scale, cell);
	vec3 ny = vec3(ny_raw.x, ny_raw.z * sign(world_normal.y), ny_raw.y);

	if (weights.y >= FLAT_THRESHOLD) {
		return normalize(ny);
	}

	vec3 nx_raw = stochastic_normal_vec(tex, world_pos.zy * scale, cell);
	vec3 nz_raw = stochastic_normal_vec(tex, world_pos.xy * scale, cell);
	vec3 nx = vec3(nx_raw.z * sign(world_normal.x), nx_raw.y, nx_raw.x);
	vec3 nz = vec3(nz_raw.x, nz_raw.y, nz_raw.z * sign(world_normal.z));

	return normalize(nx * weights.x + ny * weights.y + nz * weights.z);
}

// =============================================================================
// VARYINGS (passed from vertex to fragment)
// =============================================================================
varying vec3 v_world_pos;
varying vec3 v_world_normal;

// =============================================================================
// VERTEX SHADER
// =============================================================================
void vertex() {
	v_world_pos    = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

// =============================================================================
// FRAGMENT SHADER
// =============================================================================
void fragment() {
	// --- Triplanar blend weights ---
	vec3 blend = triplanar_weights(v_world_normal, triplanar_sharpness);

	// Cell size in UV space (world-units → normalised by texture_scale)
	float cell_uv = stochastic_cell_size * texture_scale;

	// --- Albedo (3-9 reads depending on surface slope) ---
	vec4 final_albedo = triplanar_albedo_opt(texture_albedo, v_world_pos, blend, texture_scale, cell_uv);
	ALBEDO = final_albedo.rgb * albedo_tint.rgb * brightness;

	// --- Normal Map (3-9 reads) ---
	vec3 final_normal = triplanar_normal_opt(texture_normal, v_world_pos, v_world_normal, blend, texture_scale, cell_uv);
	final_normal.xy *= normal_scale;
	NORMAL_MAP       = final_normal * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 1.0;

	// --- Roughness (3-9 reads) ---
	ROUGHNESS = triplanar_scalar_opt(texture_roughness, v_world_pos, blend, texture_scale, cell_uv) * roughness_override;

	// --- Ambient Occlusion (3-9 reads) ---
	float ao_val     = triplanar_scalar_opt(texture_ao, v_world_pos, blend, texture_scale, cell_uv);
	AO               = ao_val;
	AO_LIGHT_AFFECT  = ao_intensity;

	METALLIC  = metallic_override;
	SPECULAR  = specular_override;
}
