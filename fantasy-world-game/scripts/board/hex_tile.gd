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
@export var hex_size: float = 1.0 # Distance from center to corner

# =============================================================================
# PROPERTIES
# =============================================================================
var coordinates: HexCoordinates
var biome_type: Biomes.Type = Biomes.Type.PLAINS
var tile_height: float = 0.0 # Height offset for terrain variation
var occupant: Node = null # Troop, NPC, or Gold Mine
var is_spawn_hex: bool = false
var spawn_player_id: int = -1 # Which player this spawn belongs to (-1 = none)

# Neighbor heights for ramped edges (6 values, one per direction)
var neighbor_heights: Array[float] = []

# Highlight states
var is_selected: bool = false
var is_movement_highlight: bool = false
var is_attack_highlight: bool = false
var is_hover: bool = false

# Node references
var mesh_instance: MeshInstance3D
var selection_mesh: MeshInstance3D # Full tile overlay for selection
var terrain_collision_body: StaticBody3D # Camera collision (Layer 16)
var terrain_collision_shape: CollisionShape3D # Trimesh matching terrain surface
var particle_emitter: BiomeParticleEmitter # Ambient particle effects
var forest_decorations: Node3D = null  # Forest biome 3D prop decorations

# Materials
var base_material: Material # Enhanced biome material with strong normals/AO (ShaderMaterial or StandardMaterial3D)
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
	_create_terrain_collision()
	_setup_materials()
	_update_visual()


func _process(delta: float) -> void:
	# Animate selection pulse
	if is_selected:
		selection_pulse_time += delta * PULSE_SPEED
		var pulse = (sin(selection_pulse_time) + 1.0) * 0.5 # 0 to 1
		var alpha = lerp(0.3, 0.6, pulse)
		if selection_material:
			selection_material.albedo_color.a = alpha


func setup(coords: HexCoordinates, biome: Biomes.Type) -> void:
	coordinates = coords
	biome_type = biome
	
	# Position the tile based on hex coordinates
	# All tiles at same base Y = BOARD_LIFT (terrain variation is in mesh vertices)
	var pixel_pos = coords.to_pixel(hex_size)
	position = Vector3(pixel_pos.x, GameConfig.BOARD_LIFT, pixel_pos.y)
	
	# Update visual for biome
	_update_visual()
	
	# Setup ambient particles for atmospheric biomes
	_setup_particles()
	
	# Setup forest decorations (replaces old grass system)
	_setup_forest_decorations()


# =============================================================================
# MESH CREATION
# =============================================================================

func _create_hex_mesh() -> void:
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	# Create initial flat hex mesh - will be updated with neighbor heights later
	_rebuild_hex_mesh()


## Rebuild the hex mesh with sloped edges
## Center stays flat, corner vertices blend to average of neighboring tile heights
## This creates smooth ramps between tiles with no gaps
func _rebuild_hex_mesh() -> void:
	_rebuild_hex_mesh_with_slopes()


## Build hex mesh with sloped edges and skirts to eliminate gaps
func _rebuild_hex_mesh_with_slopes() -> void:
	# =========================================================================
	# GEOMETRY CALCULATION
	# =========================================================================
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	var corner_positions: Array[Vector3] = []
	var corner_normals: Array[Vector3] = []
	var corner_heights: Array[float] = []
	
	# Pre-calculate data for 6 corners
	for i in range(6):
		var angle_deg = 60 * i - 30
		var angle = deg_to_rad(angle_deg)
		var cx = hex_size * cos(angle)
		var cz = hex_size * sin(angle)
		
		# Identify neighbors
		var prev_idx = (i + 5) % 6
		var curr_idx = i
		
		var h_self = tile_height
		var h_prev = h_self
		var h_curr = h_self
		
		var prev_is_edge = false
		var curr_is_edge = false
		
		if neighbor_heights.size() == 6:
			h_prev = neighbor_heights[prev_idx]
			h_curr = neighbor_heights[curr_idx]
			if h_prev < -900.0: prev_is_edge = true
			if h_curr < -900.0: curr_is_edge = true
		
		# --- HEIGHT CALCULATION ---
		var cy: float
		
		if prev_is_edge or curr_is_edge:
			# If EITHER neighbor is missing, this corner is on the board perimeter.
			# Pin it STRICTLY to 0.0 to match the stone border height.
			cy = 0.0
			h_prev = 0.0 if prev_is_edge else h_prev # For normal calc
			h_curr = 0.0 if curr_is_edge else h_curr # For normal calc
		else:
			# Interior corner: average of 3 meeting tiles
			cy = (h_self + h_prev + h_curr) / 3.0
			
		corner_positions.append(Vector3(cx, cy, cz))
		corner_heights.append(cy)
		
		# --- SMOOTH NORMAL CALCULATION (Plane of Centers) ---
		# Normal of the plane passing through the 3 tile centers
		var dist = hex_size * 1.73205
		var ang_curr = deg_to_rad(60 * i)
		var ang_prev = deg_to_rad(60 * (i - 1))
		
		var p_center = Vector3(0, h_self, 0)
		var p_curr = Vector3(dist * cos(ang_curr), h_curr, dist * sin(ang_curr))
		var p_prev = Vector3(dist * cos(ang_prev), h_prev, dist * sin(ang_prev))
		
		var v1 = p_curr - p_center
		var v2 = p_prev - p_center
		
		# Wind order: Center -> Curr -> Prev ?? No, let's check direction.
		# A normal pointing UP should result from Cross product.
		# v_prev is "left/CCW" relative to v_curr?
		# 60*i (Curr) vs 60*(i-1) (Prev).
		# Prev is -60 deg from Curr. Clockwise.
		# So v_curr is CCW from v_prev.
		# (v_curr) x (v_prev) would point DOWN?
		# (v_prev) x (v_curr) should point UP.
		var n = v2.cross(v1).normalized()
		if n.y < 0: n = -n
		
		corner_normals.append(n)

	# --- CENTER VERTEX ---
	var center_pos = Vector3(0, tile_height, 0)
	var center_uv = Vector2(0.5, 0.5)
	
	# Average center normal
	var center_normal = Vector3.ZERO
	for n in corner_normals:
		center_normal += n
	center_normal = center_normal.normalized()
	if center_normal.length() < 0.001: center_normal = Vector3.UP

	# =========================================================================
	# BUILD MESH DATA
	# =========================================================================
	
	# 0: Center
	vertices.append(center_pos)
	normals.append(center_normal)
	uvs.append(center_uv)
	
	# 1-6: Corners
	for i in range(6):
		var angle = deg_to_rad(60 * i - 30)
		var u = 0.5 + cos(angle) * 0.5
		var v = 0.5 + sin(angle) * 0.5
		vertices.append(corner_positions[i])
		normals.append(corner_normals[i])
		uvs.append(Vector2(u, v))
		
	# Top Indices
	for i in range(6):
		indices.append(0)
		indices.append(i + 1)
		indices.append(((i + 1) % 6) + 1)

	# =========================================================================
	# SKIRTS (Shallow - just enough to seal gaps without making board too tall)
	# =========================================================================
	var skirt_y = -0.5
	
	for i in range(6):
		var next_i = (i + 1) % 6
		var p1 = corner_positions[i]
		var p2 = corner_positions[next_i]
		
		# Identify if this is a "wall" skirt (interior gap fill) or "edge" skirt (border)
		# If both heights are 0.0 (pinned), it's a border skirt.
		# Actually, just make them all uniform structure.
		
		var b1 = Vector3(p1.x, skirt_y, p1.z)
		var b2 = Vector3(p2.x, skirt_y, p2.z)
		
		var idx = vertices.size()
		vertices.append(p1)
		vertices.append(p2)
		vertices.append(b1)
		vertices.append(b2)
		
		# Flat normals for skirt "walls"
		var edge_vec = p2 - p1
		var skirt_n = edge_vec.cross(Vector3.UP).normalized()
		for k in range(4): normals.append(skirt_n)
		
		# Stretched UVs
		uvs.append(Vector2(0, 0))
		uvs.append(Vector2(1, 0))
		uvs.append(Vector2(0, 1))
		uvs.append(Vector2(1, 1))
		
		# Triangles
		indices.append(idx); indices.append(idx + 1); indices.append(idx + 2) # p1-p2-b1
		indices.append(idx + 1); indices.append(idx + 3); indices.append(idx + 2) # p2-b2-b1
	
	# =========================================================================
	# COMMIT VIA SURFACETOOL (Auto Tangents)
	# =========================================================================
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for i in range(vertices.size()):
		st.set_normal(normals[i])
		st.set_uv(uvs[i])
		st.add_vertex(vertices[i])
		
	for idx in indices:
		st.add_index(idx)
		
	st.generate_tangents()
	st.index() # Optimize
	mesh_instance.mesh = st.commit()


## Update mesh with neighbor heights for smooth slope transitions
func update_mesh_with_neighbors(heights: Array[float]) -> void:
	neighbor_heights = heights
	# Rebuild mesh with sloped edges based on neighbor heights
	_rebuild_hex_mesh_with_slopes()
	
	# Re-apply material
	if base_material and mesh_instance:
		mesh_instance.material_override = base_material


# Stored vertex heights for surface height calculation (troop placement)
var stored_vertex_heights: Array[float] = []

## Buffer height for troop placement (keeps models from z-fighting with terrain)
const SURFACE_HEIGHT_BUFFER: float = 0.05


## Update mesh with vertex heights from vertex-based displacement system
## This creates a seamless terrain using pre-calculated vertex heights
func update_mesh_with_vertex_heights(vertex_heights: Array[float]) -> void:
	if vertex_heights.size() != 6:
		push_error("update_mesh_with_vertex_heights requires exactly 6 vertex heights")
		return
	
	# Store vertex heights for surface height calculation
	stored_vertex_heights = vertex_heights.duplicate()
	
	# Build mesh using provided vertex heights
	_rebuild_hex_mesh_with_vertex_heights(vertex_heights)
	
	# Rebuild selection overlay to match new terrain shape
	_rebuild_selection_overlay()
	
	# Rebuild terrain collision trimesh to match the new surface
	_rebuild_terrain_collision()
	
	# Re-apply material
	if base_material and mesh_instance:
		mesh_instance.material_override = base_material

## Get the average surface height for this tile (used for troop placement)
## Uses vertex averaging - much faster than raycasting
## Returns the average Y height of all 6 vertices + a small buffer
func get_surface_height() -> float:
	if stored_vertex_heights.size() != 6:
		# Fallback to tile_height if vertex heights not set
		return tile_height + SURFACE_HEIGHT_BUFFER
	
	var total_height: float = 0.0
	for h in stored_vertex_heights:
		total_height += h
	
	return (total_height / 6.0) + SURFACE_HEIGHT_BUFFER


## Build hex mesh using pre-calculated vertex heights
func _rebuild_hex_mesh_with_vertex_heights(vertex_heights: Array[float]) -> void:
	# =========================================================================
	# GEOMETRY CALCULATION
	# =========================================================================
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	var corner_positions: Array[Vector3] = []
	var corner_normals: Array[Vector3] = []
	
	# Pre-calculate corner positions using provided vertex heights
	for i in range(6):
		var angle_deg = 60 * i - 30
		var angle = deg_to_rad(angle_deg)
		var cx = hex_size * cos(angle)
		var cz = hex_size * sin(angle)
		var cy = vertex_heights[i] # Use the provided vertex height directly
		
		corner_positions.append(Vector3(cx, cy, cz))
	
	# Calculate normals for each corner
	for i in range(6):
		var prev_idx = (i + 5) % 6
		var next_idx = (i + 1) % 6
		
		# Calculate normal using cross product of edge vectors
		var edge1 = corner_positions[next_idx] - corner_positions[i]
		var edge2 = corner_positions[prev_idx] - corner_positions[i]
		
		var n = edge2.cross(edge1).normalized()
		if n.y < 0: n = -n
		
		corner_normals.append(n)
	
	# --- CENTER VERTEX ---
	# Center height is average of all corner heights
	var center_height = 0.0
	for h in vertex_heights:
		center_height += h
	center_height /= 6.0
	
	var center_pos = Vector3(0, center_height, 0)
	var center_uv = Vector2(0.5, 0.5)
	
	# Average center normal
	var center_normal = Vector3.ZERO
	for n in corner_normals:
		center_normal += n
	center_normal = center_normal.normalized()
	if center_normal.length() < 0.001: center_normal = Vector3.UP

	# =========================================================================
	# BUILD MESH DATA
	# =========================================================================
	
	# 0: Center
	vertices.append(center_pos)
	normals.append(center_normal)
	uvs.append(center_uv)
	
	# 1-6: Corners
	for i in range(6):
		var angle = deg_to_rad(60 * i - 30)
		var u = 0.5 + cos(angle) * 0.5
		var v = 0.5 + sin(angle) * 0.5
		vertices.append(corner_positions[i])
		normals.append(corner_normals[i])
		uvs.append(Vector2(u, v))
		
	# Top Indices
	for i in range(6):
		indices.append(0)
		indices.append(i + 1)
		indices.append(((i + 1) % 6) + 1)

	# =========================================================================
	# SKIRTS (Shallow - just enough to seal gaps without making board too tall)
	# =========================================================================
	var skirt_y = -0.5
	
	for i in range(6):
		var next_i = (i + 1) % 6
		var p1 = corner_positions[i]
		var p2 = corner_positions[next_i]
		
		var b1 = Vector3(p1.x, skirt_y, p1.z)
		var b2 = Vector3(p2.x, skirt_y, p2.z)
		
		var idx = vertices.size()
		vertices.append(p1)
		vertices.append(p2)
		vertices.append(b1)
		vertices.append(b2)
		
		# Flat normals for skirt "walls"
		var edge_vec = p2 - p1
		var skirt_n = edge_vec.cross(Vector3.UP).normalized()
		for k in range(4): normals.append(skirt_n)
		
		# Stretched UVs
		uvs.append(Vector2(0, 0))
		uvs.append(Vector2(1, 0))
		uvs.append(Vector2(0, 1))
		uvs.append(Vector2(1, 1))
		
		# Triangles
		indices.append(idx); indices.append(idx + 1); indices.append(idx + 2) # p1-p2-b1
		indices.append(idx + 1); indices.append(idx + 3); indices.append(idx + 2) # p2-b2-b1
	
	# =========================================================================
	# COMMIT VIA SURFACETOOL (Auto Tangents)
	# =========================================================================
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for i in range(vertices.size()):
		st.set_normal(normals[i])
		st.set_uv(uvs[i])
		st.add_vertex(vertices[i])
		
	for idx in indices:
		st.add_index(idx)
		
	st.generate_tangents()
	st.index() # Optimize
	mesh_instance.mesh = st.commit()


func _create_selection_overlay() -> void:
	# Create a hex overlay that conforms to the tile's terrain slope
	selection_mesh = MeshInstance3D.new()
	add_child(selection_mesh)
	_rebuild_selection_overlay()


## Rebuild the selection overlay mesh to match current vertex heights
## Called after vertex heights are updated so the highlight follows the terrain
func _rebuild_selection_overlay() -> void:
	if not selection_mesh:
		return
	
	var vertices = PackedVector3Array()
	var normals_arr = PackedVector3Array()
	var indices = PackedInt32Array()
	
	const OVERLAY_OFFSET: float = 0.025 # Tiny raise above surface to prevent z-fighting
	const OVERLAY_SCALE: float = 0.97 # Slightly smaller than tile to avoid edge bleed
	
	# Use stored vertex heights if available, otherwise fall back to tile_height
	var corner_heights: Array[float] = []
	if stored_vertex_heights.size() == 6:
		corner_heights = stored_vertex_heights.duplicate()
	else:
		for _i in range(6):
			corner_heights.append(tile_height)
	
	# Center height = average of all corners
	var center_h: float = 0.0
	for h in corner_heights:
		center_h += h
	center_h /= 6.0
	
	# Center vertex
	vertices.append(Vector3(0, center_h + OVERLAY_OFFSET, 0))
	
	# 6 corner vertices scaled inward and raised by OVERLAY_OFFSET
	for i in range(6):
		var angle = deg_to_rad(60 * i - 30)
		var x = hex_size * OVERLAY_SCALE * cos(angle)
		var z = hex_size * OVERLAY_SCALE * sin(angle)
		var y = corner_heights[i] + OVERLAY_OFFSET
		vertices.append(Vector3(x, y, z))
	
	# Triangles (fan from center)
	for i in range(6):
		indices.append(0)
		indices.append(i + 1)
		indices.append(((i + 1) % 6) + 1)
	
	# Calculate per-vertex normals to match tile slope
	# Center normal = average of face normals
	var face_normals: Array[Vector3] = []
	for i in range(6):
		var v0 = vertices[0]
		var v1 = vertices[i + 1]
		var v2 = vertices[((i + 1) % 6) + 1]
		var edge1 = v1 - v0
		var edge2 = v2 - v0
		var fn = edge1.cross(edge2).normalized()
		if fn.y < 0: fn = - fn
		face_normals.append(fn)
	
	var center_normal = Vector3.ZERO
	for fn in face_normals:
		center_normal += fn
	center_normal = center_normal.normalized()
	if center_normal.length() < 0.001: center_normal = Vector3.UP
	normals_arr.append(center_normal)
	
	for i in range(6):
		var prev_fn = face_normals[(i + 5) % 6]
		var curr_fn = face_normals[i]
		var corner_normal = (prev_fn + curr_fn).normalized()
		if corner_normal.length() < 0.001: corner_normal = Vector3.UP
		normals_arr.append(corner_normal)
	
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_NORMAL] = normals_arr
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	selection_mesh.mesh = mesh
	selection_mesh.visible = false


## Create terrain collision body on Layer 1 & 16.
## Uses a ConcavePolygonShape3D (trimesh) that exactly matches the visible
## hex surface mesh. By making this pickable, we get 100% pixel-perfect
## mouse selection on the exact terrain geometry without overlapping generic shapes.
func _create_terrain_collision() -> void:
	terrain_collision_body = StaticBody3D.new()
	terrain_collision_body.name = "TerrainCollision"
	# Layer 1 = Gameplay raycast (clicking), Layer 16 = Camera physical bounds
	terrain_collision_body.collision_layer = 1 | (1 << 15)
	terrain_collision_body.collision_mask = 0 # Does not detect anything natively
	
	# CRITICAL: This exact trimesh is our mouse-picking surface.
	terrain_collision_body.input_ray_pickable = true
	add_child(terrain_collision_body)
	
	terrain_collision_shape = CollisionShape3D.new()
	terrain_collision_shape.name = "TerrainShape"
	terrain_collision_body.add_child(terrain_collision_shape)
	
	# Bind mouse signals directly to the pixel-perfect trimesh
	terrain_collision_body.mouse_entered.connect(on_mouse_entered)
	terrain_collision_body.mouse_exited.connect(on_mouse_exited)
	terrain_collision_body.input_event.connect(_on_trimesh_input_event)
	
	# Build initial trimesh from the current mesh
	_rebuild_terrain_collision()


## Rebuild the terrain collision trimesh to match the current visual hex mesh.
## Called after vertex heights are updated so the collider follows the terrain.
func _rebuild_terrain_collision() -> void:
	if not terrain_collision_shape or not mesh_instance or not mesh_instance.mesh:
		return
	
	# Build faces from the mesh (top surface + skirts)
	var faces = mesh_instance.mesh.get_faces()
	if faces.size() < 3:
		return
	
	var trimesh = ConcavePolygonShape3D.new()
	trimesh.set_faces(faces)
	terrain_collision_shape.shape = trimesh

# =============================================================================
# PARTICLES (DISABLED)
# =============================================================================

## Setup ambient particle effects for this biome (disabled for realism)
func _setup_particles() -> void:
	# Particles disabled for cleaner, more realistic appearance
	# The biome textures provide enough visual interest
	pass


# =============================================================================
# FOREST DECORATION SYSTEM
# =============================================================================

## Setup 3D environment decorations for this tile's biome.
## The system is modular — each biome reads its own asset pool from
## ForestDecorationSystem.BIOME_CONFIG and skips gracefully when no pool exists.
func _setup_forest_decorations() -> void:
	# Always clear leftover decorations first (handles biome reassignment too)
	if forest_decorations and is_instance_valid(forest_decorations):
		forest_decorations.queue_free()
		forest_decorations = null

	# Ensure we're in the scene tree before adding children.
	# The deferred re-call keeps the biome guard consistent after mid-frame
	# biome changes — ForestDecorationSystem.BIOME_CONFIG handles the guard now.
	if not is_inside_tree():
		call_deferred("_setup_forest_decorations")
		return

	# Create a container node to hold all decoration children
	forest_decorations = Node3D.new()
	forest_decorations.name = "BiomeDecorations"
	add_child(forest_decorations)

	# Tile-seeded RNG → reproducible decoration layout across reloads
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(coordinates._to_key()) if coordinates else randi()

	# Pass biome_type, height, and corner vertex heights so decorations sit on the surface
	ForestDecorationSystem.decorate_tile(
		forest_decorations, hex_size, rng, biome_type,
		tile_height, stored_vertex_heights
	)


# =============================================================================
# MATERIALS
# =============================================================================


func _setup_materials() -> void:
	# Base material from BiomeMaterialManager (enhanced PBR materials with strong normals/AO)
	base_material = BiomeMaterialManager.get_material_copy(biome_type)
	mesh_instance.material_override = base_material
	
	# Selection material (using central UI gold, semi-transparent)
	selection_material = StandardMaterial3D.new()
	var sel_col = UITheme.C_GOLD
	sel_col.a = 0.35 # Slightly more transparent for clarity
	selection_material.albedo_color = sel_col
	selection_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	selection_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# CRITICAL: Depth test must be ON so entities on top (troops) aren't obscured
	selection_material.no_depth_test = false
	selection_material.render_priority = 10 # Draw over terrain but respects entities
	
	# Hover material (subtle white glow)
	hover_material = StandardMaterial3D.new()
	hover_material.albedo_color = Color(1.0, 1.0, 1.0, 0.25)
	hover_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hover_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	# Movement material (blue)
	movement_material = StandardMaterial3D.new()
	movement_material.albedo_color = Color(0.2, 0.5, 1.0, 0.4)
	movement_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	movement_material.emission_enabled = true
	movement_material.emission = Color(0.2, 0.4, 0.8)
	movement_material.emission_energy_multiplier = 1.0
	movement_material.render_priority = 10
	
	# Attack material (red)
	attack_material = StandardMaterial3D.new()
	attack_material.albedo_color = Color(1.0, 0.2, 0.2, 0.4)
	attack_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	attack_material.emission_enabled = true
	attack_material.emission = Color(0.8, 0.2, 0.2)
	attack_material.emission_energy_multiplier = 1.0
	attack_material.render_priority = 10


func _update_visual() -> void:
	# Update base material from BiomeMaterialManager if biome changed
	if base_material and mesh_instance:
		var new_material = BiomeMaterialManager.get_material_copy(biome_type)
		base_material = new_material
		mesh_instance.material_override = base_material
	
	# Reset meshes
	selection_mesh.visible = false
	selection_pulse_time = 0.0
	
	# Selected state - highest priority
	if is_selected:
		selection_mesh.visible = true
		selection_mesh.material_override = selection_material
		set_process(true) # Enable pulse animation
	# Attack highlight
	elif is_attack_highlight:
		selection_mesh.visible = true
		selection_mesh.material_override = attack_material
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
	_setup_forest_decorations() # Regenerate decorations for new biome


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
# INPUT HANDLING (Called externally via direct physics raycast)
# =============================================================================

func on_mouse_entered() -> void:
	is_hover = true
	_update_visual()
	tile_hovered.emit(self )


func on_mouse_exited() -> void:
	is_hover = false
	_update_visual()
	tile_unhovered.emit(self )


func on_mouse_clicked() -> void:
	tile_clicked.emit(self )


func _on_trimesh_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			on_mouse_clicked()
