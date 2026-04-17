shader_type spatial;
render_mode depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

// =============================================================================
// BIOME TERRAIN SHADER — Stochastic Sampling
// =============================================================================
// Stochastic sampling eliminates visible texture tiling repetition by
// randomly rotating and offsetting the UV lattice per-cell. Each cell
// samples the texture at a different orientation, so the eye never locks onto
// a repeating grid pattern even at low texture scales.
//
// Reference: "Histogram-Preserving Blending for Randomized Texture Tiling"
//            Heitz & Neyret 2018 — simplified version for real-time use.
//
// Triplanar world-space mapping is used so textures tile seamlessly across
// the entire hex board regardless of mesh UV layout.
// =============================================================================

// --- PBR Texture Maps ---
uniform sampler2D texture_albedo   : source_color,        filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D texture_normal   : hint_normal,          filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D texture_roughness: hint_default_white,   filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D texture_ao       : hint_default_white,   filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D texture_displacement : hint_default_black, filter_linear_mipmap_anisotropic, repeat_enable;

// --- World-Space Tiling ---
// Controls how densely the texture tiles in world space.
// Lower = larger texel footprint. Matches TEXTURE_SCALE in GDScript.
uniform float texture_scale : hint_range(0.05, 2.0) = 0.3;

// --- Triplanar blending sharpness (higher = sharper XYZ seams) ---
uniform float triplanar_sharpness : hint_range(1.0, 16.0) = 8.0;

// --- Stochastic sampling strength ---
// 0 = disabled (original tiling), 1 = full stochastic randomisation
uniform float stochastic_strength : hint_range(0.0, 1.0) = 1.0;

// --- Stochastic cell size (world units) ---
// Controls how large each randomly-oriented patch is.
// Should be 2-4x the texture period for good coverage.
uniform float stochastic_cell_size : hint_range(0.5, 10.0) = 3.0;

// --- PBR base overrides ---
uniform float roughness_override : hint_range(0.0, 1.0) = 1.0;
uniform float normal_scale       : hint_range(0.0, 3.0)  = 1.3;
uniform float ao_intensity       : hint_range(0.0, 1.0)  = 0.5;
uniform float brightness         : hint_range(0.5, 2.0)  = 1.25;
uniform vec4  albedo_tint        : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float specular_override  : hint_range(0.0, 1.0)  = 0.5;
uniform float metallic_override  : hint_range(0.0, 1.0)  = 0.0;
uniform float height_scale       : hint_range(-0.5, 0.5) = 0.15;

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
// Divides UV space into jittered hexagonal-like cells. Inside each cell the
// texture is sampled with a unique random rotation + offset, then three
// neighbouring cells are blended with smooth weights to avoid hard seams.
//
// The result looks like the original texture but without any visible grid.
// =============================================================================

// Sample the albedo texture stochastically at the given UV coordinate.
vec4 stochastic_albedo(sampler2D tex, vec2 uv, float cell) {
	// Skew UV into a rhombic lattice (avoids square-cell alignment artifacts)
	const mat2 skew    = mat2(vec2(1.0, 0.577), vec2(0.0, 1.155));
	const mat2 unskew  = mat2(vec2(1.0, -0.5),  vec2(0.0, 0.866));

	vec2 grid_uv  = skew * (uv / cell);
	vec2 grid_id  = floor(grid_uv);
	vec2 grid_frac = fract(grid_uv);

	// Three candidate lattice vertices (triangle subdivision)
	vec2 v0, v1, v2;
	if (grid_frac.x > grid_frac.y) {
		v0 = vec2(1.0, 0.0);
		v1 = vec2(1.0, 1.0);
		v2 = vec2(0.0, 0.0);
	} else {
		v0 = vec2(0.0, 1.0);
		v1 = vec2(1.0, 1.0);
		v2 = vec2(0.0, 0.0);
	}

	// Barycentric weights — smooth falloff from triangle vertices
	vec3 w;
	w.x = 1.0 - distance(grid_frac, v0);
	w.y = 1.0 - distance(grid_frac, v1);
	w.z = 1.0 - distance(grid_frac, v2);

	// Sharpen weights so blend zones aren't too wide
	w = pow(max(w, vec3(0.0)), vec3(7.0));
	w /= (w.x + w.y + w.z);

	// Random rotation angle and offset for each vertex cell
	float r0 = hash21(grid_id + v0) * 6.2832;
	float r1 = hash21(grid_id + v1) * 6.2832;
	float r2 = hash21(grid_id + v2) * 6.2832;

	vec2 o0 = hash22(grid_id + v0) * 0.5;
	vec2 o1 = hash22(grid_id + v1) * 0.5;
	vec2 o2 = hash22(grid_id + v2) * 0.5;

	// Apply rotation to UVs relative to each cell centre
	vec2 cell_centre = unskew * (grid_id * cell);
	vec2 local_uv    = uv - cell_centre;

	mat2 rot0 = mat2(vec2(cos(r0), -sin(r0)), vec2(sin(r0), cos(r0)));
	mat2 rot1 = mat2(vec2(cos(r1), -sin(r1)), vec2(sin(r1), cos(r1)));
	mat2 rot2 = mat2(vec2(cos(r2), -sin(r2)), vec2(sin(r2), cos(r2)));

	vec2 uv0 = rot0 * local_uv + o0 + cell_centre;
	vec2 uv1 = rot1 * local_uv + o1 + cell_centre;
	vec2 uv2 = rot2 * local_uv + o2 + cell_centre;

	// Sample and blend
	vec4 s0 = texture(tex, uv0);
	vec4 s1 = texture(tex, uv1);
	vec4 s2 = texture(tex, uv2);

	return w.x * s0 + w.y * s1 + w.z * s2;
}

// Same cell-based approach but for normal maps — we must rotate the XY
// components of the normal to match the UV rotation for each cell.
vec4 stochastic_normal(sampler2D tex, vec2 uv, float cell) {
	const mat2 skew    = mat2(vec2(1.0, 0.577), vec2(0.0, 1.155));
	const mat2 unskew  = mat2(vec2(1.0, -0.5),  vec2(0.0, 0.866));

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

	// Decode normals from map
	vec3 n0 = texture(tex, uv0).xyz * 2.0 - 1.0;
	vec3 n1 = texture(tex, uv1).xyz * 2.0 - 1.0;
	vec3 n2 = texture(tex, uv2).xyz * 2.0 - 1.0;

	// Rotate XY of each normal to match UV rotation
	n0.xy = rot0 * n0.xy;
	n1.xy = rot1 * n1.xy;
	n2.xy = rot2 * n2.xy;

	// Blend and re-encode
	vec3 n = normalize(w.x * n0 + w.y * n1 + w.z * n2);
	return vec4(n * 0.5 + 0.5, 1.0);
}

// Scalar texture stochastic sampling (roughness, AO — no rotation needed for XY)
float stochastic_scalar(sampler2D tex, vec2 uv, float cell) {
	const mat2 skew    = mat2(vec2(1.0, 0.577), vec2(0.0, 1.155));
	const mat2 unskew  = mat2(vec2(1.0, -0.5),  vec2(0.0, 0.866));

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

	float s0 = texture(tex, uv0).r;
	float s1 = texture(tex, uv1).r;
	float s2 = texture(tex, uv2).r;

	return w.x * s0 + w.y * s1 + w.z * s2;
}

// =============================================================================
// TRIPLANAR HELPERS
// =============================================================================

// Compute triplanar blend weights from surface normal
vec3 triplanar_weights(vec3 normal, float sharpness) {
	vec3 w = pow(abs(normal), vec3(sharpness));
	return w / (w.x + w.y + w.z + 0.0001);
}

// Full stochastic triplanar sample for albedo
vec4 triplanar_albedo(sampler2D tex, vec3 world_pos, vec3 weights, float scale, float cell) {
	vec4 x = stochastic_albedo(tex, world_pos.zy * scale, cell);
	vec4 y = stochastic_albedo(tex, world_pos.xz * scale, cell);
	vec4 z = stochastic_albedo(tex, world_pos.xy * scale, cell);
	return x * weights.x + y * weights.y + z * weights.z;
}

// Stochastic triplanar sample for normals (handles axis-specific tangent spaces)
vec3 triplanar_normal(sampler2D tex, vec3 world_pos, vec3 world_normal, vec3 weights, float scale, float cell) {
	// Sample each axis
	vec4 nx_raw = stochastic_normal(tex, world_pos.zy * scale, cell);
	vec4 ny_raw = stochastic_normal(tex, world_pos.xz * scale, cell);
	vec4 nz_raw = stochastic_normal(tex, world_pos.xy * scale, cell);

	// Decode
	vec3 nx = nx_raw.xyz * 2.0 - 1.0;
	vec3 ny = ny_raw.xyz * 2.0 - 1.0;
	vec3 nz = nz_raw.xyz * 2.0 - 1.0;

	// Swizzle to world space per axis
	nx = vec3(nx.z * sign(world_normal.x), nx.y, nx.x);
	ny = vec3(ny.x, ny.z * sign(world_normal.y), ny.y);
	nz = vec3(nz.x, nz.y, nz.z * sign(world_normal.z));

	return normalize(nx * weights.x + ny * weights.y + nz * weights.z);
}

// Stochastic triplanar sample for scalar maps
float triplanar_scalar(sampler2D tex, vec3 world_pos, vec3 weights, float scale, float cell) {
	float x = stochastic_scalar(tex, world_pos.zy * scale, cell);
	float y = stochastic_scalar(tex, world_pos.xz * scale, cell);
	float z = stochastic_scalar(tex, world_pos.xy * scale, cell);
	return x * weights.x + y * weights.y + z * weights.z;
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

	// --- Parallax Mapping (Displacement) ---
	vec3 view_dir_world = normalize(CAMERA_POSITION_WORLD - v_world_pos);
	// Sample displacement to find height
	float h_stoch = triplanar_scalar(texture_displacement, v_world_pos, blend, texture_scale, cell_uv);
	float h_plain;
	{
		float hx = texture(texture_displacement, v_world_pos.zy * texture_scale).r;
		float hy = texture(texture_displacement, v_world_pos.xz * texture_scale).r;
		float hz = texture(texture_displacement, v_world_pos.xy * texture_scale).r;
		h_plain = hx * blend.x + hy * blend.y + hz * blend.z;
	}
	float height_val = mix(h_plain, h_stoch, stochastic_strength);
	
	// Offset world position based on view direction and height
	vec3 parallax_pos = v_world_pos;
	// We offset perpendicular to the normal, scaled by the height map. This creates a basic parallax effect.
	// Since we use world space coords instead of UVs, we reverse the view direction offset
	vec3 offset = view_dir_world * (height_val * height_scale);
	// Project offset onto the surface plane so we don't 'sink' straight down in world space
	offset -= v_world_normal * dot(offset, v_world_normal);
	parallax_pos -= offset; // SUBTRACT to simulate depth correctly

	// --- Albedo ---
	vec4 albedo_stoch = triplanar_albedo(texture_albedo, parallax_pos, blend, texture_scale, cell_uv);
	// Fallback plain triplanar sample (for stochastic_strength < 1)
	vec4 albedo_plain;
	{
		vec4 ax = texture(texture_albedo, parallax_pos.zy * texture_scale);
		vec4 ay = texture(texture_albedo, parallax_pos.xz * texture_scale);
		vec4 az = texture(texture_albedo, parallax_pos.xy * texture_scale);
		albedo_plain = ax * blend.x + ay * blend.y + az * blend.z;
	}
	vec4 final_albedo = mix(albedo_plain, albedo_stoch, stochastic_strength);
	ALBEDO = final_albedo.rgb * albedo_tint.rgb * brightness;

	// --- Normal Map ---
	vec3 norm_stoch = triplanar_normal(texture_normal, parallax_pos, v_world_normal, blend, texture_scale, cell_uv);
	// Blend toward unperturbed normal at stochastic_strength = 0
	vec3 norm_plain;
	{
		vec4 nx_r = texture(texture_normal, parallax_pos.zy * texture_scale);
		vec4 ny_r = texture(texture_normal, parallax_pos.xz * texture_scale);
		vec4 nz_r = texture(texture_normal, parallax_pos.xy * texture_scale);
		vec3 nx = nx_r.xyz * 2.0 - 1.0; nx = vec3(nx.z, nx.y, nx.x);
		vec3 ny = ny_r.xyz * 2.0 - 1.0; ny = vec3(ny.x, ny.z, ny.y);
		vec3 nz = nz_r.xyz * 2.0 - 1.0;
		norm_plain = normalize(nx * blend.x + ny * blend.y + nz * blend.z);
	}
	vec3 final_normal = mix(norm_plain, norm_stoch, stochastic_strength);
	// Apply normal scale — scale XY relative to Z
	final_normal.xy *= normal_scale;
	NORMAL_MAP = final_normal * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 1.0;

	// --- Roughness ---
	float rough_stoch = triplanar_scalar(texture_roughness, parallax_pos, blend, texture_scale, cell_uv);
	float rough_plain;
	{
		float rx = texture(texture_roughness, parallax_pos.zy * texture_scale).r;
		float ry = texture(texture_roughness, parallax_pos.xz * texture_scale).r;
		float rz = texture(texture_roughness, parallax_pos.xy * texture_scale).r;
		rough_plain = rx * blend.x + ry * blend.y + rz * blend.z;
	}
	ROUGHNESS = mix(rough_plain, rough_stoch, stochastic_strength) * roughness_override;

	// --- Ambient Occlusion ---
	float ao_stoch = triplanar_scalar(texture_ao, parallax_pos, blend, texture_scale, cell_uv);
	float ao_plain;
	{
		float ax2 = texture(texture_ao, parallax_pos.zy * texture_scale).r;
		float ay2 = texture(texture_ao, parallax_pos.xz * texture_scale).r;
		float az2 = texture(texture_ao, parallax_pos.xy * texture_scale).r;
		ao_plain = ax2 * blend.x + ay2 * blend.y + az2 * blend.z;
	}
	float ao_val = mix(ao_plain, ao_stoch, stochastic_strength);
	AO = ao_val;
	// Apply AO heavily to direct light to ground decorations and terrain details
	AO_LIGHT_AFFECT = ao_intensity;

	METALLIC = metallic_override;
	SPECULAR = specular_override;
}
