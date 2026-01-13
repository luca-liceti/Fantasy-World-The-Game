## Hex Tile
## Represents a single hexagon on the game board
## Handles visual representation and input for selection
class_name HexTile
extends Node3D

# =============================================================================
# SIGNALS
# =============================================================================
signal tile_clicked(hex_tile: HexTile)
signal tile_hovered(hex_tile: HexTile)
signal tile_unhovered(hex_tile: HexTile)

# =============================================================================
# EXPORTS
# =============================================================================
@export var hex_size: float = 1.0  # Distance from center to corner

# =============================================================================
# PROPERTIES
# =============================================================================
var coordinates: HexCoordinates
var biome_type: Biomes.Type = Biomes.Type.PLAINS
var occupant: Node = null  # Troop, NPC, or Gold Mine
var is_spawn_hex: bool = false
var spawn_player_id: int = -1  # Which player this spawn belongs to (-1 = none)

# Highlight states
var is_selected: bool = false
var is_movement_highlight: bool = false
var is_attack_highlight: bool = false
var is_hover: bool = false

# Node references
var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D
var border_mesh: MeshInstance3D  # Border outline
var selection_mesh: MeshInstance3D  # Full tile overlay for selection
var area: Area3D
var particle_emitter: BiomeParticleEmitter  # Ambient particle effects

# Materials
var base_material: StandardMaterial3D
var border_material: StandardMaterial3D
var selection_material: StandardMaterial3D
var movement_material: StandardMaterial3D
var attack_material: StandardMaterial3D
var hover_material: StandardMaterial3D

# Animation
var selection_pulse_time: float = 0.0
const PULSE_SPEED: float = 3.0


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_create_hex_mesh()
	_create_selection_overlay()
	_create_border_mesh()
	_create_collision()
	_setup_materials()
	_update_visual()


func _process(delta: float) -> void:
	# Animate selection pulse
	if is_selected:
		selection_pulse_time += delta * PULSE_SPEED
		var pulse = (sin(selection_pulse_time) + 1.0) * 0.5  # 0 to 1
		var alpha = lerp(0.3, 0.6, pulse)
		if selection_material:
			selection_material.albedo_color.a = alpha
		# Slight scale pulse on border
		if border_mesh:
			var scale_pulse = lerp(1.0, 1.02, pulse)
			border_mesh.scale = Vector3(scale_pulse, 1.0, scale_pulse)


func setup(coords: HexCoordinates, biome: Biomes.Type) -> void:
	coordinates = coords
	biome_type = biome
	
	# Position the tile based on hex coordinates
	# Y = BOARD_LIFT from GameConfig (hex tiles sit on raised platform)
	var pixel_pos = coords.to_pixel(hex_size)
	position = Vector3(pixel_pos.x, GameConfig.BOARD_LIFT, pixel_pos.y)
	
	# Update visual for biome
	_update_visual()
	
	# Setup ambient particles for atmospheric biomes
	_setup_particles()


# =============================================================================
# MESH CREATION
# =============================================================================

func _create_hex_mesh() -> void:
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	# Create hexagon mesh (pointy-top orientation)
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# Center vertex
	vertices.append(Vector3.ZERO)
	
	# 6 corner vertices
	for i in range(6):
		var angle = deg_to_rad(60 * i - 30)  # Pointy-top: start at -30 degrees
		var x = hex_size * cos(angle)
		var z = hex_size * sin(angle)
		vertices.append(Vector3(x, 0, z))
	
	# Create triangles (6 triangles from center to each edge)
	for i in range(6):
		indices.append(0)  # Center
		indices.append(i + 1)
		indices.append(((i + 1) % 6) + 1)
	
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	# Calculate normals (all pointing up)
	var normals = PackedVector3Array()
	for _i in range(vertices.size()):
		normals.append(Vector3.UP)
	arrays[Mesh.ARRAY_NORMAL] = normals
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = mesh


func _create_selection_overlay() -> void:
	# Create a slightly raised hex for selection overlay
	selection_mesh = MeshInstance3D.new()
	add_child(selection_mesh)
	
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	# Center vertex (slightly raised)
	vertices.append(Vector3(0, 0.02, 0))
	
	# 6 corner vertices (slightly smaller than base, raised)
	var overlay_scale = 0.95
	for i in range(6):
		var angle = deg_to_rad(60 * i - 30)
		var x = hex_size * overlay_scale * cos(angle)
		var z = hex_size * overlay_scale * sin(angle)
		vertices.append(Vector3(x, 0.02, z))
	
	# Create triangles
	for i in range(6):
		indices.append(0)
		indices.append(i + 1)
		indices.append(((i + 1) % 6) + 1)
	
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var normals = PackedVector3Array()
	for _i in range(vertices.size()):
		normals.append(Vector3.UP)
	arrays[Mesh.ARRAY_NORMAL] = normals
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	selection_mesh.mesh = mesh
	selection_mesh.visible = false


func _create_border_mesh() -> void:
	border_mesh = MeshInstance3D.new()
	add_child(border_mesh)
	
	# Create a thick raised hex border
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var outer_scale = 1.0
	var inner_scale = 0.88
	var height = 0.05  # Raised border
	
	# Create outer and inner rings at height
	for i in range(6):
		var angle = deg_to_rad(60 * i - 30)
		
		# Outer vertex
		var outer_x = hex_size * outer_scale * cos(angle)
		var outer_z = hex_size * outer_scale * sin(angle)
		vertices.append(Vector3(outer_x, height, outer_z))
		
		# Inner vertex
		var inner_x = hex_size * inner_scale * cos(angle)
		var inner_z = hex_size * inner_scale * sin(angle)
		vertices.append(Vector3(inner_x, height, inner_z))
	
	# Create triangles for the ring (top face)
	for i in range(6):
		var outer1 = i * 2
		var inner1 = i * 2 + 1
		var outer2 = ((i + 1) % 6) * 2
		var inner2 = ((i + 1) % 6) * 2 + 1
		
		# Two triangles per segment
		indices.append(outer1)
		indices.append(inner1)
		indices.append(outer2)
		
		indices.append(inner1)
		indices.append(inner2)
		indices.append(outer2)
	
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var normals = PackedVector3Array()
	for _i in range(vertices.size()):
		normals.append(Vector3.UP)
	arrays[Mesh.ARRAY_NORMAL] = normals
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	border_mesh.mesh = mesh
	border_mesh.visible = false


func _create_collision() -> void:
	area = Area3D.new()
	add_child(area)
	
	collision_shape = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = hex_size * 0.9
	shape.height = 0.2
	collision_shape.shape = shape
	area.add_child(collision_shape)
	
	# Connect signals
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)
	area.input_event.connect(_on_input_event)


# =============================================================================
# PARTICLES (DISABLED)
# =============================================================================

## Setup ambient particle effects for this biome (disabled for realism)
func _setup_particles() -> void:
	# Particles disabled for cleaner, more realistic appearance
	# The biome textures provide enough visual interest
	pass


# =============================================================================
# MATERIALS
# =============================================================================

func _setup_materials() -> void:
	# Base material from BiomeMaterialManager (enhanced PBR materials)
	base_material = BiomeMaterialManager.get_material_copy(biome_type)
	mesh_instance.material_override = base_material
	
	# Selection material (golden yellow, semi-transparent)
	selection_material = StandardMaterial3D.new()
	selection_material.albedo_color = Color(1.0, 0.85, 0.2, 0.4)
	selection_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	selection_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	selection_material.no_depth_test = true
	
	# Border material (bright, emissive for visibility)
	border_material = StandardMaterial3D.new()
	border_material.albedo_color = Color(1.0, 0.9, 0.3, 1.0)
	border_material.emission_enabled = true
	border_material.emission = Color(1.0, 0.8, 0.2)
	border_material.emission_energy_multiplier = 2.0
	
	# Hover material (subtle white glow)
	hover_material = StandardMaterial3D.new()
	hover_material.albedo_color = Color(1.0, 1.0, 1.0, 0.25)
	hover_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hover_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	# Movement material (blue)
	movement_material = StandardMaterial3D.new()
	movement_material.albedo_color = Color(0.2, 0.5, 1.0, 0.5)
	movement_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	movement_material.emission_enabled = true
	movement_material.emission = Color(0.2, 0.4, 0.8)
	movement_material.emission_energy_multiplier = 1.0
	
	# Attack material (red)
	attack_material = StandardMaterial3D.new()
	attack_material.albedo_color = Color(1.0, 0.2, 0.2, 0.5)
	attack_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	attack_material.emission_enabled = true
	attack_material.emission = Color(0.8, 0.2, 0.2)
	attack_material.emission_energy_multiplier = 1.0


func _update_visual() -> void:
	# Update base material from BiomeMaterialManager if biome changed
	if base_material and mesh_instance:
		var new_material = BiomeMaterialManager.get_material_copy(biome_type)
		base_material = new_material
		mesh_instance.material_override = base_material
	
	# Reset meshes
	selection_mesh.visible = false
	border_mesh.visible = false
	selection_pulse_time = 0.0
	
	# Selected state - highest priority
	if is_selected:
		selection_mesh.visible = true
		selection_mesh.material_override = selection_material
		border_mesh.visible = true
		border_mesh.material_override = border_material
		set_process(true)  # Enable pulse animation
	# Attack highlight
	elif is_attack_highlight:
		selection_mesh.visible = true
		selection_mesh.material_override = attack_material
		border_mesh.visible = true
		border_mesh.material_override = attack_material
		set_process(false)
	# Movement highlight
	elif is_movement_highlight:
		selection_mesh.visible = true
		selection_mesh.material_override = movement_material
		set_process(false)
	# Hover state
	elif is_hover:
		selection_mesh.visible = true
		selection_mesh.material_override = hover_material
		set_process(false)
	else:
		set_process(false)


# =============================================================================
# PUBLIC METHODS
# =============================================================================

## Set the biome type and update visuals
func set_biome(biome: Biomes.Type) -> void:
	biome_type = biome
	_update_visual()


## Set as spawn hex for a player
func set_as_spawn(player_id: int) -> void:
	is_spawn_hex = true
	spawn_player_id = player_id


## Check if this hex is occupied
func is_occupied() -> bool:
	return occupant != null


## Set occupant (troop, NPC, or mine)
func set_occupant(entity: Node) -> void:
	occupant = entity


## Clear occupant
func clear_occupant() -> void:
	occupant = null


## Get occupant
func get_occupant() -> Node:
	return occupant


## Set selection state
func set_selected(selected: bool) -> void:
	is_selected = selected
	_update_visual()


## Set movement highlight
func set_movement_highlight(highlighted: bool) -> void:
	is_movement_highlight = highlighted
	_update_visual()


## Set attack highlight
func set_attack_highlight(highlighted: bool) -> void:
	is_attack_highlight = highlighted
	_update_visual()


## Clear all highlights
func clear_highlights() -> void:
	is_selected = false
	is_movement_highlight = false
	is_attack_highlight = false
	_update_visual()


## Check if mine can be placed here
func can_place_mine() -> bool:
	return not is_occupied() and Biomes.can_place_mine(biome_type)


# =============================================================================
# INPUT HANDLING
# =============================================================================

func _on_mouse_entered() -> void:
	is_hover = true
	_update_visual()
	tile_hovered.emit(self)


func _on_mouse_exited() -> void:
	is_hover = false
	_update_visual()
	tile_unhovered.emit(self)


func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			tile_clicked.emit(self)
