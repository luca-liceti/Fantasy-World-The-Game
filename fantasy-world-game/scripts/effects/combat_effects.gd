## Combat Effects
## Handles visual effects for the combat system
## Camera zoom, screen shake, highlighting, particles
class_name CombatEffects
extends Node

# =============================================================================
# SIGNALS
# =============================================================================
signal effect_started(effect_type: String)
signal effect_completed(effect_type: String)

# =============================================================================
# REFERENCES
# =============================================================================
var game_camera: Camera3D = null
var original_camera_position: Vector3
var original_camera_fov: float
var is_combat_zoomed: bool = false

# Troop highlighting
var highlighted_troops: Array[Node] = []
var highlight_materials: Dictionary = {}

# =============================================================================
# CONFIGURATION
# =============================================================================
const COMBAT_ZOOM_AMOUNT: float = 0.7  # Multiply FOV by this during combat
const COMBAT_ZOOM_DURATION: float = 0.5
const SCREEN_SHAKE_INTENSITY: float = 0.3
const SCREEN_SHAKE_DURATION: float = 0.3
const CRIT_SHAKE_INTENSITY: float = 0.6
const CRIT_SHAKE_DURATION: float = 0.5

# Colors for highlighting
const ATTACKER_HIGHLIGHT_COLOR = Color(1.0, 0.3, 0.2, 0.8)  # Red
const DEFENDER_HIGHLIGHT_COLOR = Color(0.2, 0.5, 1.0, 0.8)  # Blue
const DAMAGE_TYPE_COLORS = {
	"PHYSICAL": Color(0.8, 0.8, 0.8),
	"FIRE": Color(1.0, 0.4, 0.1),
	"ICE": Color(0.4, 0.8, 1.0),
	"DARK": Color(0.5, 0.2, 0.6),
	"HOLY": Color(1.0, 0.95, 0.5),
	"NATURE": Color(0.3, 0.8, 0.3)
}


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	# Find camera in scene
	await get_tree().process_frame
	_find_camera()


func _find_camera() -> void:
	game_camera = get_viewport().get_camera_3d()
	if game_camera:
		original_camera_fov = game_camera.fov
		original_camera_position = game_camera.global_position


## Set camera reference manually
func set_camera(camera: Camera3D) -> void:
	game_camera = camera
	if camera:
		original_camera_fov = camera.fov
		original_camera_position = camera.global_position


# =============================================================================
# 5.1.1 - CAMERA ZOOM DURING COMBAT
# =============================================================================

## Zoom camera in for combat selection
func zoom_in_for_combat(attacker: Node, defender: Node) -> void:
	if game_camera == null:
		_find_camera()
		if game_camera == null:
			return
	
	if is_combat_zoomed:
		return
	
	is_combat_zoomed = true
	effect_started.emit("combat_zoom")
	
	# Calculate midpoint between combatants
	var attacker_pos = attacker.global_position if attacker else Vector3.ZERO
	var defender_pos = defender.global_position if defender else Vector3.ZERO
	var midpoint = (attacker_pos + defender_pos) / 2.0
	
	# Store original values
	original_camera_position = game_camera.global_position
	original_camera_fov = game_camera.fov
	
	# Animate zoom
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	
	# Zoom in (reduce FOV)
	var target_fov = original_camera_fov * COMBAT_ZOOM_AMOUNT
	tween.tween_property(game_camera, "fov", target_fov, COMBAT_ZOOM_DURATION)
	
	# Optionally move camera slightly toward midpoint
	# var look_direction = (midpoint - game_camera.global_position).normalized()
	# var target_pos = original_camera_position + look_direction * 3.0
	# tween.tween_property(game_camera, "global_position", target_pos, COMBAT_ZOOM_DURATION)


## Zoom camera back out after combat
func zoom_out_from_combat() -> void:
	if game_camera == null or not is_combat_zoomed:
		return
	
	is_combat_zoomed = false
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUART)
	
	tween.tween_property(game_camera, "fov", original_camera_fov, COMBAT_ZOOM_DURATION)
	tween.tween_callback(func(): effect_completed.emit("combat_zoom"))


# =============================================================================
# 5.1.2 - TROOP HIGHLIGHTING
# =============================================================================

## Highlight the attacker and defender during selection
func highlight_combatants(attacker: Node, defender: Node) -> void:
	clear_highlights()
	
	if attacker:
		_highlight_troop(attacker, ATTACKER_HIGHLIGHT_COLOR, true)
		highlighted_troops.append(attacker)
	
	if defender:
		_highlight_troop(defender, DEFENDER_HIGHLIGHT_COLOR, false)
		highlighted_troops.append(defender)
	
	effect_started.emit("highlight")


## Clear all troop highlights
func clear_highlights() -> void:
	for troop in highlighted_troops:
		if is_instance_valid(troop):
			_remove_highlight(troop)
	
	highlighted_troops.clear()
	highlight_materials.clear()
	effect_completed.emit("highlight")


func _highlight_troop(troop: Node, color: Color, pulse: bool) -> void:
	# Find mesh instance in troop
	var mesh_instance: MeshInstance3D = null
	if "mesh_instance" in troop and troop.mesh_instance:
		mesh_instance = troop.mesh_instance
	else:
		# Try to find one
		for child in troop.get_children():
			if child is MeshInstance3D:
				mesh_instance = child
				break
	
	if mesh_instance == null:
		return
	
	# Store original material
	highlight_materials[troop] = mesh_instance.material_override
	
	# Create highlight material
	var highlight_mat = StandardMaterial3D.new()
	highlight_mat.albedo_color = color
	highlight_mat.emission_enabled = true
	highlight_mat.emission = color
	highlight_mat.emission_energy_multiplier = 1.5
	
	mesh_instance.material_override = highlight_mat
	
	# Add pulsing animation for attacker.
	# IMPORTANT: tween must be created on a Node (mesh_instance), NOT on the
	# material Resource directly.  Tweening a Resource property with set_loops()
	# can cause Godot to detect a zero-duration infinite loop (tween.cpp:406).
	if pulse:
		var tween = mesh_instance.create_tween()
		tween.set_loops()
		tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
		# We can't tween a Resource property directly with set_loops() safely,
		# so we drive the pulse via a method callback on this node.
		tween.tween_method(
			func(v: float) -> void:
				if is_instance_valid(highlight_mat):
					highlight_mat.emission_energy_multiplier = v,
			1.5, 2.5, 0.5
		)
		tween.tween_method(
			func(v: float) -> void:
				if is_instance_valid(highlight_mat):
					highlight_mat.emission_energy_multiplier = v,
			2.5, 1.0, 0.5
		)


func _remove_highlight(troop: Node) -> void:
	var mesh_instance: MeshInstance3D = null
	if "mesh_instance" in troop and troop.mesh_instance:
		mesh_instance = troop.mesh_instance
	else:
		for child in troop.get_children():
			if child is MeshInstance3D:
				mesh_instance = child
				break
	
	if mesh_instance and troop in highlight_materials:
		mesh_instance.material_override = highlight_materials[troop]


# =============================================================================
# 5.1.3 - SMOOTH TRANSITIONS
# =============================================================================

## Play transition animation between selection and resolution
func play_selection_to_resolution_transition(callback: Callable = Callable()) -> void:
	effect_started.emit("transition")
	
	# Create a brief flash/pulse effect
	var overlay = ColorRect.new()
	overlay.color = Color(1, 1, 1, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Add to a CanvasLayer to ensure it's on top
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	canvas.add_child(overlay)
	
	var tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.4, 0.15)
	tween.tween_property(overlay, "color:a", 0.0, 0.3)
	tween.tween_callback(func():
		canvas.queue_free()
		effect_completed.emit("transition")
		if callback.is_valid():
			callback.call()
	)


# =============================================================================
# 5.1.4 - SCREEN SHAKE
# =============================================================================

## Shake the screen for impact
func screen_shake(intensity: float = SCREEN_SHAKE_INTENSITY, duration: float = SCREEN_SHAKE_DURATION) -> void:
	if game_camera == null:
		_find_camera()
		if game_camera == null:
			return
	
	effect_started.emit("screen_shake")
	
	var original_pos = game_camera.global_position
	var elapsed = 0.0
	var shake_tween = create_tween()
	
	# Create shake by rapidly moving camera
	var shake_steps = int(duration / 0.03)
	for i in range(shake_steps):
		var offset = Vector3(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity),
			randf_range(-intensity * 0.5, intensity * 0.5)
		)
		# Reduce intensity over time
		var falloff = 1.0 - (float(i) / float(shake_steps))
		offset *= falloff
		
		shake_tween.tween_property(game_camera, "global_position", original_pos + offset, 0.03)
	
	# Return to original position
	shake_tween.tween_property(game_camera, "global_position", original_pos, 0.05)
	shake_tween.tween_callback(func(): effect_completed.emit("screen_shake"))


## Shake screen on critical hit (stronger)
func critical_hit_shake() -> void:
	screen_shake(CRIT_SHAKE_INTENSITY, CRIT_SHAKE_DURATION)


## Shake screen on regular hit
func hit_shake() -> void:
	screen_shake(SCREEN_SHAKE_INTENSITY, SCREEN_SHAKE_DURATION)


# =============================================================================
# 5.1.5 - DAMAGE TYPE PARTICLES
# =============================================================================

## Spawn damage type particles at position
func spawn_damage_particles(position: Vector3, damage_type: String, is_crit: bool = false) -> void:
	var color = DAMAGE_TYPE_COLORS.get(damage_type, Color.WHITE)
	
	# Create GPU particles
	var particles = GPUParticles3D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.amount = 20 if not is_crit else 40
	particles.lifetime = 0.8
	particles.global_position = position + Vector3(0, 0.5, 0)
	
	# Create process material
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 0.3
	material.direction = Vector3(0, 1, 0)
	material.spread = 45.0
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 4.0
	material.gravity = Vector3(0, -5, 0)
	material.scale_min = 0.1
	material.scale_max = 0.3 if not is_crit else 0.5
	material.color = color
	
	# Add color fade
	var gradient = Gradient.new()
	gradient.set_color(0, color)
	gradient.set_color(1, Color(color.r, color.g, color.b, 0))
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture
	
	particles.process_material = material
	
	# Add mesh for particles
	var mesh = SphereMesh.new()
	mesh.radius = 0.05
	mesh.height = 0.1
	particles.draw_pass_1 = mesh
	
	add_child(particles)
	
	# Auto-cleanup
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(particles):
		particles.queue_free()


## Spawn status effect particles (for DoT effects)
func spawn_status_particles(troop: Node, effect_id: String) -> void:
	if troop == null:
		return
	
	var position = troop.global_position + Vector3(0, 1.0, 0)
	var color: Color
	
	match effect_id:
		"burned":
			color = Color(1.0, 0.4, 0.1)
		"poisoned":
			color = Color(0.3, 0.8, 0.2)
		"cursed":
			color = Color(0.5, 0.2, 0.6)
		"stunned":
			color = Color(1.0, 1.0, 0.3)
		_:
			color = Color.WHITE
	
	spawn_damage_particles(position, "", false)


# =============================================================================
# COMBINED COMBAT EFFECTS
# =============================================================================

## Full combat start effects (zoom + highlight)
func on_combat_start(attacker: Node, defender: Node) -> void:
	zoom_in_for_combat(attacker, defender)
	highlight_combatants(attacker, defender)


## Full combat end effects
func on_combat_end() -> void:
	clear_highlights()
	zoom_out_from_combat()


## Play hit effects based on result
func on_combat_hit(defender: Node, damage_type: String, is_crit: bool) -> void:
	var position = defender.global_position if defender else Vector3.ZERO
	
	spawn_damage_particles(position, damage_type, is_crit)
	
	if is_crit:
		critical_hit_shake()
	else:
		hit_shake()
