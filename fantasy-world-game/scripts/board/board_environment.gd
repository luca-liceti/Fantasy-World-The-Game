## Board Environment
## Creates a realistic tabletop environment for the hex board game
## Features:
## - Wooden table surface (below everything)
## - Raised hexagonal board platform 
## - Tarnished silver frame around the hex board
class_name BoardEnvironment
extends Node3D

# =============================================================================
# CONSTANTS
# =============================================================================

## Path to board textures (table, frame, edges)
const BOARD_TEXTURES_PATH := "res://assets/textures/board/"

## Board parameters
const TABLE_PADDING := 8.0       # Extra space around the board for table
const FRAME_PADDING := 1.2       # Padding between edge hexes and frame inner edge
const FRAME_WIDTH := 0.8         # Width of the metal frame
const FRAME_THICKNESS := 0.15    # Height/thickness of the frame rim above board
const PLATFORM_THICKNESS := 0.3  # Thickness of the board platform
# Note: Board lift height is GameConfig.BOARD_LIFT (0.4)

## Texture scale for tiling (lower = larger texture appearance)
const TABLE_TEXTURE_SCALE := 0.015  # Large wood grain - realistic table planks

# =============================================================================
# CACHED TEXTURES
# =============================================================================

static var _texture_cache: Dictionary = {}

# =============================================================================
# NODES
# =============================================================================

var table_mesh: MeshInstance3D
var platform_mesh: MeshInstance3D
var frame_mesh: MeshInstance3D

# =============================================================================
# PUBLIC STATIC METHOD
# =============================================================================

## Create and setup the board environment for a given board radius
static func create_for_board(board_radius: int, hex_size: float) -> BoardEnvironment:
	var env = BoardEnvironment.new()
	env.name = "BoardEnvironment"
	env._setup(board_radius, hex_size)
	return env


# =============================================================================
# SETUP
# =============================================================================

func _setup(board_radius: int, hex_size: float) -> void:
	# Calculate board dimensions
	# For a hexagonal board with pointy-top hexes:
	# hex width = sqrt(3) * size
	var hex_width: float = sqrt(3.0) * hex_size
	
	# World radius of the hex board (distance from center to edge hex centers)
	var world_radius: float = (board_radius + 0.5) * hex_width
	
	# Create all elements (order matters for layering)
	_create_table_surface(world_radius)
	_create_board_platform(world_radius)
	_create_frame(world_radius)
	
	print("[BoardEnvironment] Created raised board with tarnished silver frame")


# =============================================================================
# TABLE SURFACE (Wooden table beneath everything)
# =============================================================================

func _create_table_surface(board_world_radius: float) -> void:
	table_mesh = MeshInstance3D.new()
	table_mesh.name = "TableSurface"
	add_child(table_mesh)
	
	# Create a large quad for the table
	var table_size: float = (board_world_radius + TABLE_PADDING + FRAME_WIDTH + FRAME_PADDING) * 2.5
	
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(table_size, table_size)
	plane_mesh.subdivide_depth = 4
	plane_mesh.subdivide_width = 4
	table_mesh.mesh = plane_mesh
	
	# Position at Y=0 (ground level)
	table_mesh.position.y = 0.0
	
	# Create and apply wood material
	var material = _create_wood_material()
	table_mesh.material_override = material


# =============================================================================
# BOARD PLATFORM (Raised hexagonal base for the tiles)
# =============================================================================

func _create_board_platform(board_world_radius: float) -> void:
	platform_mesh = MeshInstance3D.new()
	platform_mesh.name = "BoardPlatform"
	add_child(platform_mesh)
	
	# Platform extends to the inner edge of the frame
	var platform_radius: float = board_world_radius + FRAME_PADDING
	
	# Create hexagonal prism for the platform
	var mesh = _create_hexagonal_prism(platform_radius, PLATFORM_THICKNESS)
	platform_mesh.mesh = mesh
	
	# Position: top surface SLIGHTLY BELOW hex tiles to avoid z-fighting
	# Hex tiles are at GameConfig.BOARD_LIFT, platform top should be just below
	var platform_top_y: float = GameConfig.BOARD_LIFT - 0.02  # 2cm below hex tiles
	platform_mesh.position.y = platform_top_y - PLATFORM_THICKNESS / 2.0
	
	# Apply a neutral stone/concrete material for the platform base
	var material = _create_platform_material()
	platform_mesh.material_override = material


# =============================================================================
# FRAME (Tarnished silver hexagonal frame)
# =============================================================================

func _create_frame(board_world_radius: float) -> void:
	frame_mesh = MeshInstance3D.new()
	frame_mesh.name = "TarnishedSilverFrame"
	add_child(frame_mesh)
	
	var inner_radius: float = board_world_radius + FRAME_PADDING
	var outer_radius: float = inner_radius + FRAME_WIDTH
	# Frame extends from just above table level to above hex tiles
	var frame_bottom: float = 0.01  # Just above table to avoid z-fighting
	var frame_top: float = GameConfig.BOARD_LIFT + FRAME_THICKNESS
	
	# Create the frame mesh (hexagonal ring with thickness)
	var mesh = _create_hexagonal_frame_mesh(inner_radius, outer_radius, frame_bottom, frame_top)
	frame_mesh.mesh = mesh
	
	# Apply tarnished silver material
	var material = _create_tarnished_silver_material()
	frame_mesh.material_override = material


# =============================================================================
# MESH CREATION HELPERS
# =============================================================================

## Create a solid hexagonal prism mesh
func _create_hexagonal_prism(radius: float, height: float) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	var normals = PackedVector3Array()
	
	var half_height: float = height / 2.0
	
	# Create center vertex for top and bottom
	var center_top_idx: int = 0
	var center_bottom_idx: int = 1
	vertices.append(Vector3(0, half_height, 0))  # Top center
	normals.append(Vector3.UP)
	vertices.append(Vector3(0, -half_height, 0))  # Bottom center
	normals.append(Vector3.DOWN)
	
	# Create 6 corner vertices for top and bottom
	for i in range(6):
		# Match hex tile orientation (flat-top when viewed from above)
		var angle: float = deg_to_rad(60 * i)  # No offset for flat-top orientation
		var x: float = radius * cos(angle)
		var z: float = radius * sin(angle)
		
		# Top vertex
		vertices.append(Vector3(x, half_height, z))
		normals.append(Vector3.UP)
		
		# Bottom vertex
		vertices.append(Vector3(x, -half_height, z))
		normals.append(Vector3.DOWN)
	
	# Top face triangles (fan from center)
	for i in range(6):
		var v1: int = 2 + i * 2  # Current top vertex
		var v2: int = 2 + ((i + 1) % 6) * 2  # Next top vertex
		indices.append(center_top_idx)
		indices.append(v1)
		indices.append(v2)
	
	# Bottom face triangles (fan from center, reversed winding)
	for i in range(6):
		var v1: int = 3 + i * 2  # Current bottom vertex
		var v2: int = 3 + ((i + 1) % 6) * 2  # Next bottom vertex
		indices.append(center_bottom_idx)
		indices.append(v2)
		indices.append(v1)
	
	# Side faces (6 quads = 12 triangles)
	for i in range(6):
		var top1: int = 2 + i * 2
		var bottom1: int = 3 + i * 2
		var top2: int = 2 + ((i + 1) % 6) * 2
		var bottom2: int = 3 + ((i + 1) % 6) * 2
		
		# Add side vertices with proper normals
		var angle: float = deg_to_rad(60 * i)
		var side_normal = Vector3(cos(angle), 0, sin(angle)).normalized()
		
		var base_idx: int = vertices.size()
		vertices.append(vertices[top1])
		normals.append(side_normal)
		vertices.append(vertices[bottom1])
		normals.append(side_normal)
		vertices.append(vertices[top2])
		normals.append(side_normal)
		vertices.append(vertices[bottom2])
		normals.append(side_normal)
		
		# Two triangles for the quad
		indices.append(base_idx)
		indices.append(base_idx + 1)
		indices.append(base_idx + 2)
		
		indices.append(base_idx + 2)
		indices.append(base_idx + 1)
		indices.append(base_idx + 3)
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Create a hexagonal frame mesh (ring shape with inner and outer radius)
func _create_hexagonal_frame_mesh(inner_radius: float, outer_radius: float, 
								   bottom_y: float, top_y: float) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	var normals = PackedVector3Array()
	
	# For each of the 6 sides of the hexagon
	for i in range(6):
		# Match hex tile orientation (flat-top when viewed from above)
		var angle1: float = deg_to_rad(60 * i)  # No offset for flat-top
		var angle2: float = deg_to_rad(60 * (i + 1))
		
		# Calculate corner positions
		var inner1 = Vector3(inner_radius * cos(angle1), 0, inner_radius * sin(angle1))
		var inner2 = Vector3(inner_radius * cos(angle2), 0, inner_radius * sin(angle2))
		var outer1 = Vector3(outer_radius * cos(angle1), 0, outer_radius * sin(angle1))
		var outer2 = Vector3(outer_radius * cos(angle2), 0, outer_radius * sin(angle2))
		
		# === TOP FACE ===
		var base_idx: int = vertices.size()
		vertices.append(Vector3(outer1.x, top_y, outer1.z))
		vertices.append(Vector3(inner1.x, top_y, inner1.z))
		vertices.append(Vector3(outer2.x, top_y, outer2.z))
		vertices.append(Vector3(inner2.x, top_y, inner2.z))
		for _j in range(4):
			normals.append(Vector3.UP)
		
		indices.append(base_idx)
		indices.append(base_idx + 1)
		indices.append(base_idx + 2)
		indices.append(base_idx + 1)
		indices.append(base_idx + 3)
		indices.append(base_idx + 2)
		
		# === OUTER SIDE FACE ===
		base_idx = vertices.size()
		var outer_normal = Vector3(cos((angle1 + angle2) / 2.0), 0, sin((angle1 + angle2) / 2.0)).normalized()
		vertices.append(Vector3(outer1.x, top_y, outer1.z))
		vertices.append(Vector3(outer2.x, top_y, outer2.z))
		vertices.append(Vector3(outer1.x, bottom_y, outer1.z))
		vertices.append(Vector3(outer2.x, bottom_y, outer2.z))
		for _j in range(4):
			normals.append(outer_normal)
		
		indices.append(base_idx)
		indices.append(base_idx + 2)
		indices.append(base_idx + 1)
		indices.append(base_idx + 1)
		indices.append(base_idx + 2)
		indices.append(base_idx + 3)
		
		# === INNER SIDE FACE ===
		base_idx = vertices.size()
		var inner_normal = -Vector3(cos((angle1 + angle2) / 2.0), 0, sin((angle1 + angle2) / 2.0)).normalized()
		vertices.append(Vector3(inner1.x, top_y, inner1.z))
		vertices.append(Vector3(inner2.x, top_y, inner2.z))
		vertices.append(Vector3(inner1.x, bottom_y, inner1.z))
		vertices.append(Vector3(inner2.x, bottom_y, inner2.z))
		for _j in range(4):
			normals.append(inner_normal)
		
		indices.append(base_idx)
		indices.append(base_idx + 1)
		indices.append(base_idx + 2)
		indices.append(base_idx + 1)
		indices.append(base_idx + 3)
		indices.append(base_idx + 2)
		
		# === BOTTOM FACE ===
		base_idx = vertices.size()
		vertices.append(Vector3(outer1.x, bottom_y, outer1.z))
		vertices.append(Vector3(inner1.x, bottom_y, inner1.z))
		vertices.append(Vector3(outer2.x, bottom_y, outer2.z))
		vertices.append(Vector3(inner2.x, bottom_y, inner2.z))
		for _j in range(4):
			normals.append(Vector3.DOWN)
		
		indices.append(base_idx)
		indices.append(base_idx + 2)
		indices.append(base_idx + 1)
		indices.append(base_idx + 1)
		indices.append(base_idx + 2)
		indices.append(base_idx + 3)
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


# =============================================================================
# MATERIAL CREATION
# =============================================================================

## Create wood material for the table (rustic medieval oak)
## Uses table_wood_alt3 which is darker/more rustic looking
func _create_wood_material() -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	# Try alt3 first (darker rustic wood), then alt2, then default
	var variants = ["table_wood_alt3_", "table_wood_alt2_", "table_wood_"]
	var loaded = false
	
	for variant in variants:
		var base_path: String = BOARD_TEXTURES_PATH + variant
		var diffuse_tex = _load_texture(base_path + "diffuse.png")
		if diffuse_tex:
			material.albedo_texture = diffuse_tex
			material.albedo_color = Color.WHITE  # No tint - use natural texture color
			
			# Load normal map
			var normal_tex = _load_texture(base_path + "normal.png")
			if normal_tex:
				material.normal_enabled = true
				material.normal_texture = normal_tex
				material.normal_scale = 0.4
			
			# Load roughness map
			var roughness_tex = _load_texture(base_path + "roughness.png")
			if roughness_tex:
				material.roughness_texture = roughness_tex
				material.roughness = 1.0
			else:
				material.roughness = 0.8
			
			# Load AO map
			var ao_tex = _load_texture(base_path + "ao.png")
			if ao_tex:
				material.ao_enabled = true
				material.ao_texture = ao_tex
				material.ao_light_affect = 0.3
			
			loaded = true
			break
	
	if not loaded:
		# Fallback - rustic dark wood color
		material.albedo_color = Color(0.25, 0.18, 0.10)  # Dark aged oak
		material.roughness = 0.85
	
	material.metallic = 0.0
	
	# Triplanar for seamless tiling
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3(TABLE_TEXTURE_SCALE, TABLE_TEXTURE_SCALE, TABLE_TEXTURE_SCALE)
	
	return material


## Create platform material using stone textures (medieval castle floor)
func _create_platform_material() -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	var base_path: String = BOARD_TEXTURES_PATH + "frame_stone_"
	
	# Try to load stone textures for the platform
	var diffuse_tex = _load_texture(base_path + "diffuse.png")
	if diffuse_tex:
		material.albedo_texture = diffuse_tex
		material.albedo_color = Color(0.6, 0.6, 0.6)  # Slight darkening tint
		
		var normal_tex = _load_texture(base_path + "normal.png")
		if normal_tex:
			material.normal_enabled = true
			material.normal_texture = normal_tex
			material.normal_scale = 0.5
		
		var roughness_tex = _load_texture(base_path + "roughness.png")
		if roughness_tex:
			material.roughness_texture = roughness_tex
			material.roughness = 1.0
		else:
			material.roughness = 0.9
	else:
		# Fallback - dark stone color
		material.albedo_color = Color(0.2, 0.18, 0.16)
		material.roughness = 0.9
	
	material.metallic = 0.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# Triplanar for seamless tiling on sides
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3(0.05, 0.05, 0.05)
	
	return material


## Create rusty iron material for the frame (medieval battle-worn)
## Uses frame_metal_rusty textures for authentic weathered look
func _create_tarnished_silver_material() -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	var base_path: String = BOARD_TEXTURES_PATH + "frame_metal_rusty_"
	
	# Load rusty metal textures
	var diffuse_tex = _load_texture(base_path + "diffuse.png")
	if diffuse_tex:
		material.albedo_texture = diffuse_tex
		material.albedo_color = Color.WHITE  # Use natural rust color
		
		var normal_tex = _load_texture(base_path + "normal.png")
		if normal_tex:
			material.normal_enabled = true
			material.normal_texture = normal_tex
			material.normal_scale = 0.6
		
		var roughness_tex = _load_texture(base_path + "roughness.png")
		if roughness_tex:
			material.roughness_texture = roughness_tex
			material.roughness = 1.0
		else:
			material.roughness = 0.75
		
		var ao_tex = _load_texture(base_path + "ao.png")
		if ao_tex:
			material.ao_enabled = true
			material.ao_texture = ao_tex
			material.ao_light_affect = 0.4
	else:
		# Fallback - aged rusty iron color
		material.albedo_color = Color(0.35, 0.25, 0.18)
		material.roughness = 0.8
	
	# Metallic properties - old weathered metal
	material.metallic = 0.5
	material.metallic_specular = 0.3
	
	# Render settings
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	
	# Triplanar for seamless tiling
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3(0.05, 0.05, 0.05)
	
	return material


## Load a texture with caching
func _load_texture(path: String) -> Texture2D:
	# Check cache
	if _texture_cache.has(path):
		return _texture_cache[path]
	
	# Try to load
	if ResourceLoader.exists(path):
		var tex = load(path) as Texture2D
		if tex:
			_texture_cache[path] = tex
			return tex
	
	return null
