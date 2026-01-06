## Biome Particle Emitter
## Spawns ambient particles based on biome type
## Attach as child of HexTile for biome-specific ambient effects
class_name BiomeParticleEmitter
extends GPUParticles3D

# =============================================================================
# CONFIGURATION
# =============================================================================

## The biome type this emitter is configured for
var current_biome: Biomes.Type = Biomes.Type.PLAINS

## Base particle amount (scaled by settings)
const BASE_AMOUNT := 8

## Particle lifetime in seconds
const LIFETIME := 4.0

# =============================================================================
# INITIALIZATION
# =============================================================================

func _init() -> void:
	# Basic GPUParticles3D setup
	amount = BASE_AMOUNT
	lifetime = LIFETIME
	explosiveness = 0.0
	randomness = 1.0
	local_coords = false
	draw_order = DRAW_ORDER_INDEX
	emitting = false


## Configure the emitter for a specific biome
func configure_for_biome(biome_type: Biomes.Type) -> void:
	current_biome = biome_type
	
	# Get particle config from BiomeMaterialManager
	var config := BiomeMaterialManager.get_particle_config(biome_type)
	
	if not config.get("enabled", false):
		emitting = false
		visible = false
		return
	
	visible = true
	
	# Create process material
	var process_mat := ParticleProcessMaterial.new()
	
	# Configure based on particle type
	var particle_type: String = config.get("type", "dust")
	_configure_particle_type(process_mat, particle_type, config)
	
	# Apply process material
	process_material = process_mat
	
	# Create simple quad mesh for particles
	var draw_pass := QuadMesh.new()
	draw_pass.size = Vector2(0.1, 0.1)
	draw_pass_1 = draw_pass
	
	# Set up the material for the draw pass
	var particle_mat := StandardMaterial3D.new()
	particle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	particle_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	particle_mat.vertex_color_use_as_albedo = true
	particle_mat.albedo_color = config.get("color", Color.WHITE)
	particle_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	
	# Add emission for glowing particles (embers, fireflies)
	if particle_type in ["embers", "fireflies"]:
		particle_mat.emission_enabled = true
		particle_mat.emission = config.get("color", Color.WHITE)
		particle_mat.emission_energy_multiplier = 2.0
	
	draw_pass.material = particle_mat
	
	# Configure amount based on config
	amount = int(config.get("amount", 4))


## Configure process material based on particle type
func _configure_particle_type(mat: ParticleProcessMaterial, ptype: String, config: Dictionary) -> void:
	# Common settings
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(0.5, 0.1, 0.5)  # Spread over hex
	
	match ptype:
		"embers":
			# Rising ember particles (Ashlands)
			mat.direction = Vector3(0, 1, 0)
			mat.initial_velocity_min = 0.3
			mat.initial_velocity_max = 0.8
			mat.gravity = Vector3(0, 0.2, 0)  # Rise upward
			mat.scale_min = 0.03
			mat.scale_max = 0.08
			mat.color = config.get("color", Color(1.0, 0.4, 0.1, 0.9))
			mat.hue_variation_min = -0.1
			mat.hue_variation_max = 0.1
			
		"snow":
			# Falling snow particles (Peaks)
			mat.direction = Vector3(0, -1, 0)
			mat.initial_velocity_min = 0.2
			mat.initial_velocity_max = 0.5
			mat.gravity = Vector3(0, -0.3, 0)  # Fall slowly
			mat.scale_min = 0.04
			mat.scale_max = 0.08
			mat.color = config.get("color", Color(0.95, 0.95, 1.0, 0.6))
			mat.emission_box_extents = Vector3(0.5, 1.0, 0.5)  # Spawn above
			
		"fireflies":
			# Floating firefly particles (Forest)
			mat.direction = Vector3(0, 1, 0)
			mat.initial_velocity_min = 0.05
			mat.initial_velocity_max = 0.15
			mat.gravity = Vector3(0, 0, 0)  # Float
			mat.scale_min = 0.02
			mat.scale_max = 0.05
			mat.color = config.get("color", Color(0.9, 0.95, 0.5, 0.8))
			mat.angular_velocity_min = -180
			mat.angular_velocity_max = 180
			
		"dust":
			# Dust particles (Wastes)
			mat.direction = Vector3(1, 0.2, 0)
			mat.spread = 45.0
			mat.initial_velocity_min = 0.2
			mat.initial_velocity_max = 0.6
			mat.gravity = Vector3(0, -0.05, 0)
			mat.scale_min = 0.02
			mat.scale_max = 0.06
			mat.color = config.get("color", Color(0.7, 0.6, 0.4, 0.3))
			
		"pollen":
			# Floating pollen (Plains)
			mat.direction = Vector3(0, 0.5, 0)
			mat.spread = 90.0
			mat.initial_velocity_min = 0.02
			mat.initial_velocity_max = 0.1
			mat.gravity = Vector3(0, 0.02, 0)  # Slight rise
			mat.scale_min = 0.02
			mat.scale_max = 0.04
			mat.color = config.get("color", Color(0.95, 0.9, 0.6, 0.4))
			
		"fog":
			# Fog wisps (Swamp)
			mat.direction = Vector3(0, 0.2, 0)
			mat.spread = 60.0
			mat.initial_velocity_min = 0.05
			mat.initial_velocity_max = 0.15
			mat.gravity = Vector3(0, 0.01, 0)
			mat.scale_min = 0.15
			mat.scale_max = 0.3
			mat.color = config.get("color", Color(0.4, 0.5, 0.3, 0.5))
			mat.emission_box_extents = Vector3(0.5, 0.05, 0.5)  # Ground level
			
		"grass":
			# Grass blades blowing (Hills)
			mat.direction = Vector3(1, 0.3, 0)
			mat.spread = 30.0
			mat.initial_velocity_min = 0.3
			mat.initial_velocity_max = 0.6
			mat.gravity = Vector3(0, -0.1, 0)
			mat.scale_min = 0.02
			mat.scale_max = 0.05
			mat.color = config.get("color", Color(0.6, 0.7, 0.5, 0.3))


## Enable particles (call when hex is near camera or always visible)
func enable_particles() -> void:
	if visible:
		emitting = true


## Disable particles (call to save performance)
func disable_particles() -> void:
	emitting = false


# =============================================================================
# FACTORY METHOD
# =============================================================================

## Create a particle emitter for a specific biome type
static func create_for_biome(biome_type: Biomes.Type) -> BiomeParticleEmitter:
	var emitter := BiomeParticleEmitter.new()
	emitter.configure_for_biome(biome_type)
	return emitter
