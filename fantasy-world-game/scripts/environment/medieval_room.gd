## Medieval Room Controller
## Manages the medieval scholar's study room
## Handles lighting effects (candle flicker, fireplace), atmosphere
class_name MedievalRoom
extends Node3D

# =============================================================================
# CONFIGURATION
# =============================================================================

## Enable candle flicker effect
@export var enable_candle_flicker: bool = true

## Candle flicker intensity (0-1)
@export_range(0.0, 1.0) var flicker_intensity: float = 0.15

## Candle flicker speed
@export_range(0.5, 5.0) var flicker_speed: float = 3.0

## Enable fireplace flicker
@export var enable_fireplace_flicker: bool = true

## Fireplace flicker intensity
@export_range(0.0, 1.0) var fireplace_flicker_intensity: float = 0.3

## Enable dust particles
@export var enable_dust_particles: bool = true

# =============================================================================
# REFERENCES
# =============================================================================

@onready var lighting_node: Node3D = $Lighting
@onready var game_board_mount: Node3D = $GameBoardMount
@onready var prop_setup: Node3D = $PropSetup

# Light references (will be found dynamically)
var candle_lights: Array[OmniLight3D] = []
var fireplace_lights: Array[OmniLight3D] = []
var all_flicker_lights: Array[Dictionary] = []  # {light, base_energy, offset}

# Noise for flicker effect
var _flicker_noise: FastNoiseLite
var _time_offset: float = 0.0

# Dust particle system
var dust_particles: GPUParticles3D


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_setup_flicker_noise()
	_find_lights()
	
	if enable_dust_particles:
		_setup_dust_particles()
	
	print("[MedievalRoom] Room initialized with %d candle lights, %d fireplace lights" % [
		candle_lights.size(), fireplace_lights.size()
	])


func _process(delta: float) -> void:
	_time_offset += delta
	
	if enable_candle_flicker or enable_fireplace_flicker:
		_update_light_flicker()


# =============================================================================
# INITIALIZATION
# =============================================================================

func _setup_flicker_noise() -> void:
	_flicker_noise = FastNoiseLite.new()
	_flicker_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_flicker_noise.frequency = 0.5
	_flicker_noise.fractal_octaves = 3
	_flicker_noise.fractal_gain = 0.5


func _find_lights() -> void:
	# Find all lights in the Lighting node and PropSetup
	var nodes_to_search: Array[Node] = []
	
	if lighting_node:
		nodes_to_search.append(lighting_node)
	
	if prop_setup:
		var lights_container = prop_setup.get_node_or_null("Lights")
		if lights_container:
			nodes_to_search.append(lights_container)
	
	for container in nodes_to_search:
		for child in container.get_children():
			if child is OmniLight3D:
				var light_name = child.name.to_lower()
				var is_fireplace = "fireplace" in light_name or "fire" in light_name
				var is_candle = "candle" in light_name or "torch" in light_name or "lantern" in light_name or "chandelier" in light_name
				
				if is_fireplace:
					fireplace_lights.append(child)
					all_flicker_lights.append({
						"light": child,
						"base_energy": child.light_energy,
						"offset": randf() * 100.0,
						"is_fireplace": true
					})
				elif is_candle:
					candle_lights.append(child)
					all_flicker_lights.append({
						"light": child,
						"base_energy": child.light_energy,
						"offset": randf() * 100.0,
						"is_fireplace": false
					})


# =============================================================================
# LIGHTING EFFECTS
# =============================================================================

func _update_light_flicker() -> void:
	for light_data in all_flicker_lights:
		var light: OmniLight3D = light_data.light
		var base_energy: float = light_data.base_energy
		var offset: float = light_data.offset
		var is_fireplace: bool = light_data.is_fireplace
		
		if not light:
			continue
		
		var intensity: float
		var speed: float
		
		if is_fireplace:
			if not enable_fireplace_flicker:
				continue
			intensity = fireplace_flicker_intensity
			speed = 2.5  # Slower, more dramatic
			
			# Fireplace uses multiple noise layers for organic fire look
			var noise1 = _flicker_noise.get_noise_1d((_time_offset + offset) * speed)
			var noise2 = _flicker_noise.get_noise_1d((_time_offset + offset + 50.0) * speed * 2.0)
			var noise3 = _flicker_noise.get_noise_1d((_time_offset + offset + 100.0) * speed * 0.5)
			
			# Combine for organic fire flicker
			var combined = (noise1 * 0.5) + (noise2 * 0.3) + (noise3 * 0.2)
			var flicker = 1.0 + (combined * intensity)
			
			# Occasional bright flare
			if randf() < 0.002:
				flicker += 0.3
			
			light.light_energy = base_energy * flicker
		else:
			if not enable_candle_flicker:
				continue
			intensity = flicker_intensity
			speed = flicker_speed
			
			# Candles use simpler flicker
			var noise_value = _flicker_noise.get_noise_1d((_time_offset + offset) * speed * 10.0)
			var flicker = 1.0 + (noise_value * intensity)
			
			# Occasional flicker spike (wind effect)
			if randf() < 0.001:
				flicker *= 0.7  # Brief dim
			
			light.light_energy = base_energy * flicker


# =============================================================================
# DUST PARTICLES
# =============================================================================

func _setup_dust_particles() -> void:
	dust_particles = GPUParticles3D.new()
	dust_particles.name = "DustParticles"
	add_child(dust_particles)
	
	# Position in the room
	dust_particles.position = Vector3(0, 3, 0)
	
	# Particle settings
	dust_particles.amount = 200
	dust_particles.lifetime = 8.0
	dust_particles.speed_scale = 0.3
	dust_particles.randomness = 0.5
	dust_particles.visibility_aabb = AABB(Vector3(-8, -4, -8), Vector3(16, 8, 16))
	
	# Create particle material
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(5, 3, 5)
	
	# Movement
	material.direction = Vector3(0.2, -0.1, 0.1)
	material.spread = 180.0
	material.initial_velocity_min = 0.05
	material.initial_velocity_max = 0.15
	
	# Gravity (slight upward drift near lights)
	material.gravity = Vector3(0.02, 0.01, 0.01)
	
	# Scale
	material.scale_min = 0.01
	material.scale_max = 0.03
	
	# Color - subtle golden dust catching candlelight
	material.color = Color(1.0, 0.9, 0.7, 0.15)
	
	dust_particles.process_material = material
	
	# Create simple quad mesh for particles
	var mesh = QuadMesh.new()
	mesh.size = Vector2(0.05, 0.05)
	
	var mesh_material = StandardMaterial3D.new()
	mesh_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_material.albedo_color = Color(1.0, 0.95, 0.85, 0.2)
	mesh_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mesh.material = mesh_material
	
	dust_particles.draw_pass_1 = mesh
	
	print("[MedievalRoom] Dust particles enabled")


# =============================================================================
# PUBLIC API
# =============================================================================

## Get the mount point for the game board
func get_board_mount_point() -> Node3D:
	return game_board_mount


## Place a scene at the game board mount point
func place_game_board(board: Node3D) -> void:
	if game_board_mount:
		game_board_mount.add_child(board)
		print("[MedievalRoom] Game board placed on table")


## Set overall light intensity (0-2, 1 = normal)
func set_light_intensity(multiplier: float) -> void:
	for light_data in all_flicker_lights:
		light_data.base_energy *= multiplier


## Enable/disable all room lights
func set_lights_enabled(enabled: bool) -> void:
	for container in [lighting_node]:
		if container:
			for child in container.get_children():
				if child is Light3D:
					child.visible = enabled
	
	if prop_setup:
		var lights_container = prop_setup.get_node_or_null("Lights")
		if lights_container:
			for child in lights_container.get_children():
				if child is Light3D:
					child.visible = enabled


## Get room dimensions
func get_room_bounds() -> AABB:
	return AABB(Vector3(-6, 0, -6), Vector3(12, 7, 12))
