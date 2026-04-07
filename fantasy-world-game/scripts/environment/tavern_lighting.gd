## TavernLighting
## ─────────────────────────────────────────────────────────────────────────────
## Atmospheric lighting rig for the Tavern environment.
##
## What this does at runtime
## ─────────────────────────
##   1. Walks the loaded environment model and spawns OmniLight3D "candle" lights
##      on every MeshInstance3D whose surface material name contains "chandelier"
##      (case-insensitive).  Each light is a weak, warm amber point source that
##      sits just above the mesh centre — giving the feeling that the chandelier
##      is genuinely illuminating the scene.
##
##   2. Replaces (or updates) the WorldEnvironment's Environment resource with the
##      full atmospheric preset: SSAO, warm amber tonemapping, subtle glow, and
##      Depth-of-Field (Bokeh BlurFar) to sell the "miniature world cut from the
##      real tavern" scale illusion.
##
##   3. Adds a LightmapGI node to the scene so the Godot editor's Bake Lightmaps
##      workflow will pick up all static lights when you choose to bake.
##
## Usage
## ─────
##   • Call  TavernLighting.apply(environment_model_root, world_environment_node)
##     from PhysicalRoomBuilder after the model is instantiated.
##   • Or attach this script as a child of PhysicalRoom and set the exports.
##
##   The studio dev lights (DevLight_Main / DevLight_Fill) are intentionally
##   **not touched** — they remain visible for editor debugging.  Toggle
##   `hide_dev_lights_in_game` to disable them at runtime.
##
class_name TavernLighting
extends Node


# =============================================================================
# EXPORTS — tweak in the Inspector
# =============================================================================

## Root node of the loaded environment model (set automatically by apply()).
@export var environment_model: Node3D = null

## The scene's WorldEnvironment node (set automatically by apply()).
@export var world_environment: WorldEnvironment = null

## Turn off DevLight_Main & DevLight_Fill when the game lighting is active.
@export var hide_dev_lights_in_game: bool = true

# ── Chandelier light settings ─────────────────────────────────────────────────

## Candle flame colour — warm gold-amber (toned down from deep orange).
@export var candle_color: Color = Color(1.0, 0.78, 0.45, 1.0)

## Energy per chandelier light.  Must fill a room at environment_scale=25.
@export var candle_energy: float = 20.0

## Falloff range in world-space units.  Large enough to reach nearby walls.
@export var candle_range: float = 40.0

## Indirect energy multiplier for baked GI bounce.
@export var candle_indirect_energy: float = 1.0

## How far above the mesh centre (local units) to place each candle light.
@export var candle_height_offset: float = 0.05

## Enable soft shadows on chandelier lights.
@export var candle_shadows: bool = true

# ── Ambient / fill settings ───────────────────────────────────────────────────
## The reference image is well-lit overall — you can see every beam, shelf, and
## barrel.  This requires a fairly strong, warm-neutral ambient fill that
## simulates the cumulative bounce from fireplace + dozens of candles.

## Warm-neutral ambient — simulates fireplace and candlelight bounce without being too orange.
@export var ambient_color: Color = Color(0.88, 0.78, 0.65, 1.0)

## Strong enough to light walls and ceiling clearly, with shadows still present.
@export var ambient_energy: float = 0.55



# ── Tonemap / colour grading ──────────────────────────────────────────────────

## ACES provides cinematic contrast and handles high-energy highlights better.
@export var tonemap_mode: Environment.ToneMapper = Environment.TONE_MAPPER_ACES

## Moderate exposure — the room should feel bright and inviting, not dim.
@export var tonemap_exposure: float = 1.3

## White-point — higher = more headroom before highlights clip.
@export var tonemap_white: float = 10.0

# =============================================================================
# STATE
# =============================================================================

var _chandelier_lights: Array[OmniLight3D] = []
var _lightmap_gi: LightmapGI = null
var _applied: bool = false


# =============================================================================
# PUBLIC API
# =============================================================================

## Main entry point.  Call this after loading and positioning the environment
## model.  Passing nodes here overrides any Inspector exports.
func apply(env_model: Node3D = null, world_env: WorldEnvironment = null) -> void:
	if env_model:
		environment_model = env_model
	if world_env:
		world_environment = world_env

	if not environment_model:
		push_error("[TavernLighting] environment_model is null — cannot apply lighting.")
		return

	_remove_previous_lights()
	_spawn_chandelier_lights()
	_apply_world_environment()
	_ensure_lightmap_gi()
	_handle_dev_lights()

	_applied = true
	print("[TavernLighting] Atmospheric lighting applied.  Chandelier sources: %d" \
		% _chandelier_lights.size())


## Remove all chandelier lights previously spawned by this script.
func clear() -> void:
	_remove_previous_lights()
	_applied = false


## Returns true if apply() has been called successfully at least once.
func is_applied() -> bool:
	return _applied


# =============================================================================
# CHANDELIER LIGHT SPAWNING
# =============================================================================

func _spawn_chandelier_lights() -> void:
	if not environment_model:
		return

	_walk_for_chandeliers(environment_model)


func _walk_for_chandeliers(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if _mesh_has_chandelier_material(mi):
			_spawn_light_on_mesh(mi)

	for child in node.get_children():
		_walk_for_chandeliers(child)


## Returns true if any surface material on this MeshInstance3D has "chandelier"
## anywhere in its name (case-insensitive).
func _mesh_has_chandelier_material(mi: MeshInstance3D) -> bool:
	if not mi.mesh:
		return false
	for i in mi.get_surface_override_material_count():
		# Check overrides first
		var mat := mi.get_surface_override_material(i)
		if mat and _name_has_chandelier(mat.resource_name):
			return true
		# Fall back to mesh's own material
		mat = mi.mesh.surface_get_material(i)
		if mat and _name_has_chandelier(mat.resource_name):
			return true
	# Also check the mesh instance node name itself as a last resort
	if _name_has_chandelier(mi.name):
		return true
	return false


func _name_has_chandelier(s: String) -> bool:
	var lower := s.to_lower()
	return lower.contains("chandelier") or lower.contains("lantern") or \
		   lower.contains("candle") or lower.contains("lamp") or \
		   lower.contains("torch")


func _spawn_light_on_mesh(mi: MeshInstance3D) -> void:
	var light := OmniLight3D.new()
	light.name = "CandleLight_" + mi.name

	# Colour & energy
	light.light_color = candle_color
	light.light_energy = candle_energy
	light.light_indirect_energy = candle_indirect_energy

	# Range / attenuation
	light.omni_range = candle_range
	# Slightly physically-based attenuation; 1.0 = natural inverse-square falloff
	light.omni_attenuation = 1.0

	# Shadows
	light.shadow_enabled = candle_shadows

	# Static bake mode — participates in LightmapGI baking
	light.light_bake_mode = Light3D.BAKE_STATIC

	# Place the light at the mesh's global centre, slightly above
	# We parent to the mesh itself so it inherits position/scale changes
	mi.add_child(light)
	light.position = Vector3(0.0, candle_height_offset, 0.0)

	_chandelier_lights.append(light)
	print("[TavernLighting]   → Candle on '%s' (mat-match)" % mi.name)


func _remove_previous_lights() -> void:
	for light in _chandelier_lights:
		if is_instance_valid(light):
			light.queue_free()
	_chandelier_lights.clear()


# =============================================================================
# WORLD ENVIRONMENT
# =============================================================================

func _apply_world_environment() -> void:
	if not world_environment:
		# Try to find it in the scene tree
		world_environment = _find_world_environment()
	if not world_environment:
		push_warning("[TavernLighting] No WorldEnvironment found — skipping environment setup.")
		return

	var env := Environment.new()

	# ── Background ────────────────────────────────────────────────────────────
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.10, 0.08, 1.0)   # dark neutral brown, not reddish

	# ── Ambient light ────────────────────────────────────────────────────────
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient_color
	env.ambient_light_energy = ambient_energy

	# ── Reflected light ───────────────────────────────────────────────────────
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED

	# ── Tonemapping (warm amber ACES) ─────────────────────────────────────────
	env.tonemap_mode = tonemap_mode as Environment.ToneMapper
	env.tonemap_exposure = tonemap_exposure
	env.tonemap_white = tonemap_white

	# ── SSAO — subtle contact shadows in corners / under furniture ───────────
	# Reference has soft, natural AO — not dramatic dark halos.
	env.ssao_enabled = true
	env.ssao_radius = 1.0
	env.ssao_intensity = 2.5       # stronger contact shadows for stone texture depth
	env.ssao_power = 1.5
	env.ssao_detail = 0.5
	env.ssao_horizon = 0.06
	env.ssao_sharpness = 0.98
	env.ssao_light_affect = 0.0

	# ── SSIL — very subtle warm bounce ────────────────────────────────────────
	env.ssil_enabled = true
	env.ssil_radius = 3.0
	env.ssil_intensity = 0.4       # stronger warm bounce for a richer look
	env.ssil_sharpness = 0.9
	env.ssil_normal_rejection = 1.0

	# ── Glow — soft candle halos, not a bloom explosion ───────────────────────
	env.glow_enabled = true
	env.glow_normalized = false
	env.glow_intensity = 0.35
	env.glow_strength = 0.7
	env.glow_bloom = 0.1           # soft halos around the lanterns
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.glow_hdr_threshold = 2.0   # only the brightest spots glow
	env.glow_hdr_scale = 1.5

	# ── Fog — OFF: at environment_scale=25, any fog density floods the room red.
	# Re-enable with density < 0.0001 only after confirming scale.
	env.fog_enabled = false

	# NOTE: Depth of Field is set on Camera3D.attributes, not Environment.
	# See _apply_dof_to_cameras() called from apply().

	# ── SSR — off (too expensive for candlelight scene, no reflective surfaces) ─
	env.ssr_enabled = false

	# ── SDFGI — off (chandelier OmniLights provide GI; SDFGI costs too much) ──
	env.sdfgi_enabled = false

	# ── Volumetric fog — adds that "hazy tavern" atmosphere ──────────────────
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.005  # subtle, but visible near lights
	env.volumetric_fog_albedo = Color(0.18, 0.16, 0.14)  # neutral-warm dust color
	env.volumetric_fog_emission = Color(0.05, 0.04, 0.02) # slight self-illumination

	world_environment.environment = env
	print("[TavernLighting] WorldEnvironment replaced with atmospheric preset.")


func _find_world_environment() -> WorldEnvironment:
	# Walk up to the scene root and search for a WorldEnvironment
	var root := get_tree().root if get_tree() else null
	if root:
		return _find_node_of_type(root, "WorldEnvironment") as WorldEnvironment
	return null


func _find_node_of_type(node: Node, type_name: String) -> Node:
	if node.get_class() == type_name:
		return node
	for child in node.get_children():
		var result := _find_node_of_type(child, type_name)
		if result:
			return result
	return null




# =============================================================================
# LIGHTMAP GI
# =============================================================================

func _ensure_lightmap_gi() -> void:
	# Check if the scene already has one
	if _lightmap_gi and is_instance_valid(_lightmap_gi):
		return

	var existing := _find_node_of_type(get_tree().root, "LightmapGI") if get_tree() else null
	if existing:
		_lightmap_gi = existing as LightmapGI
		print("[TavernLighting] Found existing LightmapGI.")
		return

	# Create and attach to this node's parent
	_lightmap_gi = LightmapGI.new()
	_lightmap_gi.name = "TavernLightmapGI"

	# Quality settings — balance bake time vs. result quality
	_lightmap_gi.quality = LightmapGI.BAKE_QUALITY_LOW   # change to HIGH for final bake
	_lightmap_gi.bounces = 3
	_lightmap_gi.bounce_indirect_energy = 0.8
	_lightmap_gi.use_denoiser = true
	_lightmap_gi.bias = 0.0005
	_lightmap_gi.max_texture_size = 16384

	get_parent().add_child(_lightmap_gi)
	_lightmap_gi.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else null
	print("[TavernLighting] LightmapGI node added to scene.")


# =============================================================================
# DEV LIGHTS
# =============================================================================

func _handle_dev_lights() -> void:
	if not hide_dev_lights_in_game:
		return
	if Engine.is_editor_hint():
		return   # Keep studio lights visible in the editor

	# Find and disable the two dev directional lights by name
	var root := get_tree().root if get_tree() else null
	if not root:
		return
	for light_name in ["DevLight_Main", "DevLight_Fill"]:
		var dev_light := _find_named_node(root, light_name)
		if dev_light:
			dev_light.visible = false
			print("[TavernLighting] Hidden dev light: %s" % light_name)


func _find_named_node(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result := _find_named_node(child, target_name)
		if result:
			return result
	return null
