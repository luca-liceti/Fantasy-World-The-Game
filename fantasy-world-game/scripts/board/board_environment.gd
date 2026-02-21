## Board Environment
## Creates a realistic tabletop environment for the hex board game
## Features:
## - Wooden table surface (below everything)
## - Raised hexagonal board platform 
## - Tarnished silver frame around the hex board
##
## "Manor Lords" Aesthetic Integration:
## - Muted, desaturated colors (earth tones)
## - High roughness values for organic/weathered look
## - Heavy AO for surface texture depth
class_name BoardEnvironment
extends Node3D

# =============================================================================
# CONSTANTS
# =============================================================================

## Path to board textures (table, frame, edges)
const BOARD_TEXTURES_PATH := "res://assets/textures/board/"

## Board parameters
const TABLE_PADDING := 8.0 # Extra space around the board for table
const FRAME_PADDING := 0.05 # Tiny gap to prevent z-fighting
const FRAME_WIDTH := 1.2 # Width of the stone border frame
const FRAME_HEIGHT := 0.45 # Height of raised border above the tiles
const PLATFORM_THICKNESS := 1.5 # Thickness of the board platform (tall border)
# Note: Board lift height is GameConfig.BOARD_LIFT (1.0)

## Floating tabletop dimensions (thick slab, no legs - "ripped off" look)
## Medieval tables were extremely robust - thick solid oak/hardwood planks
## This gives a hefty, substantial feel matching the era
const TABLE_THICKNESS := 1.2 # Robust medieval table thickness (~4-5 inches at scale)

## Texture scale for tiling (lower = larger texture appearance)
const TABLE_TEXTURE_SCALE := 0.015 # Large wood grain - realistic table planks

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

## Create and setup the board environment with optional perimeter data
## skip_table: if true, only creates the stone border frame (no wooden table surface)
static func create_for_board(board_radius: int, hex_size: float, perimeter_points: Array[Vector3] = [], skip_table: bool = false) -> BoardEnvironment:
	var env = BoardEnvironment.new()
	env.name = "BoardEnvironment"
	env._setup(board_radius, hex_size, perimeter_points, skip_table)
	return env


# =============================================================================
# SETUP
# =============================================================================

func _setup(board_radius: int, hex_size: float, perimeter_points: Array[Vector3] = [], skip_table: bool = false) -> void:
	# Calculate board dimensions
	# For a hexagonal board with pointy-top hexes:
	# hex width = sqrt(3) * size
	var hex_width: float = sqrt(3.0) * hex_size
	
	# World radius of the hex board (distance from center to edge hex centers)
	var world_radius: float = (board_radius + 0.5) * hex_width
	
	# Outer frame radius (clean hexagon that surrounds all tiles)
	var frame_outer_radius: float = world_radius + hex_size + FRAME_WIDTH
	
	# Create elements (order matters for layering)
	# Table surface is only created for standalone mode (no room model)
	if not skip_table:
		_create_table_surface(world_radius)
	
	if perimeter_points.is_empty():
		# Fallback to simple hexagon if no perimeter data (legacy)
		_create_board_platform(world_radius)
		_create_frame(world_radius)
	else:
		# Create jagged form-fitted border with straight outer edge
		_create_jagged_board_setup(perimeter_points, frame_outer_radius)
	
	print("[BoardEnvironment] Created board environment (Jagged: %s, Table: %s)" % [not perimeter_points.is_empty(), not skip_table])


# =============================================================================
# TABLE SURFACE (Floating thick wooden slab - no legs)
# =============================================================================

func _create_table_surface(board_world_radius: float) -> void:
	# Calculate table size based on board
	var hex_size: float = 1.0 # Standard hex size
	var table_size: float = (board_world_radius + TABLE_PADDING + FRAME_WIDTH + hex_size) * 2.5
	
	# Create just the thick tabletop (floating slab, no legs)
	table_mesh = MeshInstance3D.new()
	table_mesh.name = "Tabletop"
	add_child(table_mesh)
	
	# Create a thick box for the floating tabletop
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(table_size, TABLE_THICKNESS, table_size)
	table_mesh.mesh = box_mesh
	
	# Position: top surface at Y=0, so box center is at -TABLE_THICKNESS/2
	table_mesh.position.y = - TABLE_THICKNESS / 2.0
	
	# Create and apply wood material with enhanced normals and AO
	var material = _create_wood_material()
	if material:
		table_mesh.material_override = material
	
	print("[BoardEnvironment] Created floating tabletop (thickness: %.2f)" % TABLE_THICKNESS)


# =============================================================================
# BOARD PLATFORM (Legacy Hexagonal Support)
# =============================================================================

## Create a simple hexagonal platform (fallback for when no perimeter data exists)
func _create_board_platform(radius: float) -> void:
	platform_mesh = MeshInstance3D.new()
	platform_mesh.name = "Platform"
	add_child(platform_mesh)
	
	# Create solid hex prism
	platform_mesh.mesh = _create_hexagonal_prism(radius, PLATFORM_THICKNESS)
	
	# Position top surface at BOARD_LIFT height
	# Center of prism is at 0, so we move it so top face is at BOARD_LIFT
	platform_mesh.position.y = GameConfig.BOARD_LIFT - (PLATFORM_THICKNESS / 2.0)
	
	# Use stone material
	platform_mesh.material_override = _create_stone_border_material()
	
	print("[BoardEnvironment] Created hex platform (radius: %.2f)" % radius)

# =============================================================================
# BOARD BORDER (Ring frame around tiles - inner edge below tiles, outer raised)
# =============================================================================

## Create a form-fitted border that follows the exact jagged perimeter of the hex board
## with a clean hexagonal outer edge
func _create_jagged_board_setup(perimeter: Array[Vector3], outer_radius: float) -> void:
	# 1. Solid Platform (Underneath tiles) - extends to outer hexagon
	var platform = MeshInstance3D.new()
	platform.name = "BoardPlatform"
	add_child(platform)
	
	# Build the solid platform that fills from jagged inner to straight outer hexagon
	platform.mesh = _create_platform_with_straight_outer(perimeter, outer_radius)
	platform.material_override = _create_stone_border_material()
	platform.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	# 2. Frame Border (The raised rim)
	var frame = MeshInstance3D.new()
	frame.name = "BoardFrame"
	add_child(frame)
	
	# Create frame mesh - jagged inner edge, straight hexagonal outer edge, fixed height
	frame.mesh = _create_fixed_height_frame_mesh(perimeter, outer_radius)
	frame.material_override = _create_stone_border_material()
	frame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	
	print("[BoardEnvironment] Fixed-height frame with straight outer edge created")


## Create a solid jagged mesh to fit under the tiles
func _create_solid_jagged_mesh(perimeter: Array[Vector3], bottom_y: float, top_y: float) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	var normals = PackedVector3Array()
	
	# Expand perimeter slightly for the platform
	var expanded_perimeter: Array[Vector3] = []
	for p in perimeter:
		var dir = Vector3(p.x, 0, p.z).normalized()
		expanded_perimeter.append(p + dir * 0.2)
	
	# Top center
	var top_center_idx = vertices.size()
	vertices.append(Vector3(0, top_y, 0))
	normals.append(Vector3.UP)
	
	# Top vertices
	var top_start = vertices.size()
	for p in expanded_perimeter:
		vertices.append(Vector3(p.x, top_y, p.z))
		normals.append(Vector3.UP)
	
	# Top triangles
	var size = expanded_perimeter.size()
	for i in range(size):
		indices.append(top_center_idx)
		indices.append(top_start + i)
		indices.append(top_start + (i + 1) % size)
	
	# Bottom center
	var bot_center_idx = vertices.size()
	vertices.append(Vector3(0, bottom_y, 0))
	normals.append(Vector3.DOWN)
	
	# Bottom vertices
	var bot_start = vertices.size()
	for p in expanded_perimeter:
		vertices.append(Vector3(p.x, bottom_y, p.z))
		normals.append(Vector3.DOWN)
	
	# Bottom triangles
	for i in range(size):
		indices.append(bot_center_idx)
		indices.append(bot_start + (i + 1) % size)
		indices.append(bot_start + i)
	
	# Sides
	for i in range(size):
		var t1 = top_start + i
		var t2 = top_start + (i + 1) % size
		var b1 = bot_start + i
		var b2 = bot_start + (i + 1) % size
		
		# Outward normal
		var side_dir = Vector3(expanded_perimeter[i].x, 0, expanded_perimeter[i].z).normalized()
		
		var s_base = vertices.size()
		vertices.push_back(vertices[t1]); normals.push_back(side_dir)
		vertices.push_back(vertices[t2]); normals.push_back(side_dir)
		vertices.push_back(vertices[b1]); normals.push_back(side_dir)
		vertices.push_back(vertices[b2]); normals.push_back(side_dir)
		
		indices.push_back(s_base); indices.push_back(s_base + 2); indices.push_back(s_base + 1)
		indices.push_back(s_base + 1); indices.push_back(s_base + 3); indices.push_back(s_base + 2)
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Create a platform mesh as a RING from the jagged tile perimeter to the straight outer hex
## This does NOT fill the center area where tiles live — only the border ring area
func _create_platform_with_straight_outer(perimeter: Array[Vector3], outer_radius: float) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	var normals = PackedVector3Array()
	
	var bottom_y: float = -0.15
	# Platform top matches tile base level so tiles sit flush on the platform edge
	var top_y: float = GameConfig.BOARD_LIFT + 0.02  # Same as tile position Y
	
	var inner_size = perimeter.size()
	if inner_size < 3:
		return mesh
	
	# Generate subdivided outer hexagon ring to match inner perimeter density
	var outer_ring_points: Array[Vector3] = []
	var points_per_edge: int = max(4, inner_size / 6 + 2)
	for i in range(6):
		var angle1 = deg_to_rad(60 * i)
		var angle2 = deg_to_rad(60 * (i + 1))
		var corner1 = Vector3(outer_radius * cos(angle1), top_y, outer_radius * sin(angle1))
		var corner2 = Vector3(outer_radius * cos(angle2), top_y, outer_radius * sin(angle2))
		for j in range(points_per_edge):
			var t = float(j) / float(points_per_edge)
			outer_ring_points.append(corner1.lerp(corner2, t))
	
	var outer_size = outer_ring_points.size()
	
	# === TOP FACE (Ring from inner perimeter to outer hex) ===
	var inner_top_start = vertices.size()
	for p in perimeter:
		vertices.append(Vector3(p.x, top_y, p.z))
		normals.append(Vector3.UP)
	
	var outer_top_start = vertices.size()
	for p in outer_ring_points:
		vertices.append(p)
		normals.append(Vector3.UP)
	
	# Marching ring triangulation
	var i_inner = 0
	var i_outer = 0
	while i_inner < inner_size or i_outer < outer_size:
		var curr_inner = inner_top_start + (i_inner % inner_size)
		var next_inner = inner_top_start + ((i_inner + 1) % inner_size)
		var curr_outer = outer_top_start + (i_outer % outer_size)
		var next_outer = outer_top_start + ((i_outer + 1) % outer_size)
		
		if i_inner >= inner_size:
			indices.append(curr_inner); indices.append(curr_outer); indices.append(next_outer)
			i_outer += 1
		elif i_outer >= outer_size:
			indices.append(curr_inner); indices.append(curr_outer); indices.append(next_inner)
			i_inner += 1
		else:
			var inner_angle = atan2(vertices[next_inner].z, vertices[next_inner].x)
			var outer_angle = atan2(vertices[next_outer].z, vertices[next_outer].x)
			var curr_angle = atan2(vertices[curr_inner].z, vertices[curr_inner].x)
			var d_inner = fmod(inner_angle - curr_angle + TAU, TAU)
			var d_outer = fmod(outer_angle - curr_angle + TAU, TAU)
			
			if d_inner <= d_outer:
				indices.append(curr_inner); indices.append(curr_outer); indices.append(next_inner)
				i_inner += 1
			else:
				indices.append(curr_inner); indices.append(curr_outer); indices.append(next_outer)
				i_outer += 1
	
	# === OUTER SIDE WALL ===
	for i in range(outer_size):
		var p_curr = outer_ring_points[i]
		var p_next = outer_ring_points[(i + 1) % outer_size]
		var side_normal = Vector3((p_curr.x + p_next.x) / 2.0, 0, (p_curr.z + p_next.z) / 2.0).normalized()
		
		var s_base = vertices.size()
		vertices.push_back(Vector3(p_curr.x, top_y, p_curr.z)); normals.push_back(side_normal)
		vertices.push_back(Vector3(p_next.x, top_y, p_next.z)); normals.push_back(side_normal)
		vertices.push_back(Vector3(p_curr.x, bottom_y, p_curr.z)); normals.push_back(side_normal)
		vertices.push_back(Vector3(p_next.x, bottom_y, p_next.z)); normals.push_back(side_normal)
		
		indices.push_back(s_base); indices.push_back(s_base + 2); indices.push_back(s_base + 1)
		indices.push_back(s_base + 1); indices.push_back(s_base + 2); indices.push_back(s_base + 3)
	
	# === BOTTOM FACE (Ring) ===
	var inner_bot_start = vertices.size()
	for p in perimeter:
		vertices.append(Vector3(p.x, bottom_y, p.z))
		normals.append(Vector3.DOWN)
	
	var outer_bot_start = vertices.size()
	for p in outer_ring_points:
		vertices.append(Vector3(p.x, bottom_y, p.z))
		normals.append(Vector3.DOWN)
	
	# Marching ring triangulation (reversed winding for bottom face)
	i_inner = 0
	i_outer = 0
	while i_inner < inner_size or i_outer < outer_size:
		var curr_inner = inner_bot_start + (i_inner % inner_size)
		var next_inner = inner_bot_start + ((i_inner + 1) % inner_size)
		var curr_outer = outer_bot_start + (i_outer % outer_size)
		var next_outer = outer_bot_start + ((i_outer + 1) % outer_size)
		
		if i_inner >= inner_size:
			indices.append(curr_inner); indices.append(next_outer); indices.append(curr_outer)
			i_outer += 1
		elif i_outer >= outer_size:
			indices.append(curr_inner); indices.append(next_inner); indices.append(curr_outer)
			i_inner += 1
		else:
			var inner_angle = atan2(vertices[next_inner].z, vertices[next_inner].x)
			var outer_angle = atan2(vertices[next_outer].z, vertices[next_outer].x)
			var curr_angle = atan2(vertices[curr_inner].z, vertices[curr_inner].x)
			var d_inner = fmod(inner_angle - curr_angle + TAU, TAU)
			var d_outer = fmod(outer_angle - curr_angle + TAU, TAU)
			
			if d_inner <= d_outer:
				indices.append(curr_inner); indices.append(next_inner); indices.append(curr_outer)
				i_inner += 1
			else:
				indices.append(curr_inner); indices.append(next_outer); indices.append(curr_outer)
				i_outer += 1
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Create a frame mesh with:
## - INNER edge exactly at the tile perimeter (connecting seamlessly to tile edges)
## - Straight hexagonal OUTER edge
## - Rim top at tile base level for seamless connection
func _create_fixed_height_frame_mesh(perimeter: Array[Vector3], outer_radius: float) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	var normals = PackedVector3Array()
	
	# Rim top matches tile position Y exactly so tiles connect seamlessly to frame
	var rim_top_y: float = GameConfig.BOARD_LIFT + 0.02  # Same as tile position Y
	var bottom_y: float = -0.15
	
	var inner_size = perimeter.size()
	if inner_size < 3:
		return mesh
	
	# Generate outer hexagon points - but with MANY subdivisions to match perimeter density
	# This prevents degenerate triangles in the top face
	var outer_ring_points: Array[Vector3] = []
	var points_per_edge: int = max(4, inner_size / 6 + 2) # Roughly match inner density
	for i in range(6):
		var angle1 = deg_to_rad(60 * i)
		var angle2 = deg_to_rad(60 * (i + 1))
		var corner1 = Vector3(outer_radius * cos(angle1), rim_top_y, outer_radius * sin(angle1))
		var corner2 = Vector3(outer_radius * cos(angle2), rim_top_y, outer_radius * sin(angle2))
		for j in range(points_per_edge):
			var t = float(j) / float(points_per_edge)
			outer_ring_points.append(corner1.lerp(corner2, t))
	
	var outer_size = outer_ring_points.size()
	
	# === TOP FACE (Ring from inner perimeter to subdivided outer) ===
	# Add inner ring vertices
	var inner_top_start = vertices.size()
	for p in perimeter:
		vertices.append(Vector3(p.x, rim_top_y, p.z))
		normals.append(Vector3.UP)
	
	# Add outer ring vertices
	var outer_top_start = vertices.size()
	for p in outer_ring_points:
		vertices.append(p)
		normals.append(Vector3.UP)
	
	# Triangulate the ring between inner and outer using marching approach
	# Walk both rings simultaneously, always connecting to the closer next point
	var i_inner = 0
	var i_outer = 0
	while i_inner < inner_size or i_outer < outer_size:
		var curr_inner = inner_top_start + (i_inner % inner_size)
		var next_inner = inner_top_start + ((i_inner + 1) % inner_size)
		var curr_outer = outer_top_start + (i_outer % outer_size)
		var next_outer = outer_top_start + ((i_outer + 1) % outer_size)
		
		if i_inner >= inner_size:
			# Exhausted inner ring, connect remaining outer
			indices.append(curr_inner)
			indices.append(curr_outer)
			indices.append(next_outer)
			i_outer += 1
		elif i_outer >= outer_size:
			# Exhausted outer ring, connect remaining inner
			indices.append(curr_inner)
			indices.append(curr_outer)
			indices.append(next_inner)
			i_inner += 1
		else:
			# Both rings have points remaining - pick the triangle that advances
			# the ring whose next point has the smaller angular step
			var inner_angle = atan2(vertices[next_inner].z, vertices[next_inner].x)
			var outer_angle = atan2(vertices[next_outer].z, vertices[next_outer].x)
			var curr_angle = atan2(vertices[curr_inner].z, vertices[curr_inner].x)
			
			# Normalize angles relative to current position
			var d_inner = fmod(inner_angle - curr_angle + TAU, TAU)
			var d_outer = fmod(outer_angle - curr_angle + TAU, TAU)
			
			if d_inner <= d_outer:
				# Advance inner ring
				indices.append(curr_inner)
				indices.append(curr_outer)
				indices.append(next_inner)
				i_inner += 1
			else:
				# Advance outer ring
				indices.append(curr_inner)
				indices.append(curr_outer)
				indices.append(next_outer)
				i_outer += 1
	
	# === OUTER SIDE WALL (subdivided outer ring to bottom) ===
	for i in range(outer_size):
		var p_curr = outer_ring_points[i]
		var p_next = outer_ring_points[(i + 1) % outer_size]
		
		var side_normal = Vector3((p_curr.x + p_next.x) / 2.0, 0, (p_curr.z + p_next.z) / 2.0).normalized()
		
		var s_base = vertices.size()
		vertices.push_back(Vector3(p_curr.x, rim_top_y, p_curr.z)); normals.push_back(side_normal)
		vertices.push_back(Vector3(p_next.x, rim_top_y, p_next.z)); normals.push_back(side_normal)
		vertices.push_back(Vector3(p_curr.x, bottom_y, p_curr.z)); normals.push_back(side_normal)
		vertices.push_back(Vector3(p_next.x, bottom_y, p_next.z)); normals.push_back(side_normal)
		
		indices.push_back(s_base); indices.push_back(s_base + 2); indices.push_back(s_base + 1)
		indices.push_back(s_base + 1); indices.push_back(s_base + 2); indices.push_back(s_base + 3)
	
	# === INNER SIDE WALL (perimeter to bottom) ===
	for i in range(inner_size):
		var p_curr = perimeter[i]
		var p_next = perimeter[(i + 1) % inner_size]
		
		# Inward-facing normal (toward board center)
		var in_normal = -Vector3((p_curr.x + p_next.x) / 2.0, 0, (p_curr.z + p_next.z) / 2.0).normalized()
		
		var s_base = vertices.size()
		vertices.push_back(Vector3(p_curr.x, rim_top_y, p_curr.z)); normals.push_back(in_normal)
		vertices.push_back(Vector3(p_next.x, rim_top_y, p_next.z)); normals.push_back(in_normal)
		vertices.push_back(Vector3(p_curr.x, bottom_y, p_curr.z)); normals.push_back(in_normal)
		vertices.push_back(Vector3(p_next.x, bottom_y, p_next.z)); normals.push_back(in_normal)
		
		# Winding for inward-facing surface
		indices.push_back(s_base); indices.push_back(s_base + 1); indices.push_back(s_base + 2)
		indices.push_back(s_base + 1); indices.push_back(s_base + 3); indices.push_back(s_base + 2)
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Create a frame mesh that follows the jagged perimeter and tile heights (LEGACY - kept for reference)
func _create_form_fitted_frame_mesh(perimeter: Array[Vector3]) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	var normals = PackedVector3Array()
	
	# RIM_OFFSET: how much higher/lower the border is relative to the tile edge
	const RIM_OFFSET := 0.15 # Small raised lip
	const EXTENSION := FRAME_WIDTH
	var bottom_y := -0.15
	
	var size = perimeter.size()
	
	# Points definitions:
	# inner_top: flush with tile corner + RIM_OFFSET
	# outer_top: pushed out + constant height or follows rim
	# inner_bottom & outer_bottom
	
	for i in range(size):
		var p_curr = perimeter[i]
		var p_next = perimeter[(i + 1) % size]
		
		var dir_curr = Vector3(p_curr.x, 0, p_curr.z).normalized()
		var dir_next = Vector3(p_next.x, 0, p_next.z).normalized()
		
		# Inner edge sits slightly INSIDE the tile boundary to ensure no overlap gaps
		var in_p1 = p_curr - dir_curr * 0.05
		var in_p2 = p_next - dir_next * 0.05
		
		# Top vertex height follows tile height exactly to seal gaps
		# Snow peaks (tall) will have tall border walls
		var top_y1 = in_p1.y + RIM_OFFSET
		var top_y2 = in_p2.y + RIM_OFFSET
		
		# Outer points
		var out_p1 = in_p1 + dir_curr * EXTENSION
		var out_p2 = in_p2 + dir_next * EXTENSION
		# Outer top can be slightly sloped or flat - let's keep it flat-ish but following terrain
		var out_top_y1 = max(GameConfig.BOARD_LIFT + 0.45, top_y1 - 0.1)
		var out_top_y2 = max(GameConfig.BOARD_LIFT + 0.45, top_y2 - 0.1)
		
		# Build the segment
		var base = vertices.size()
		
		# TOP FACE (Inner to Outer)
		vertices.push_back(Vector3(in_p1.x, top_y1, in_p1.z)); normals.push_back(Vector3.UP)
		vertices.push_back(Vector3(out_p1.x, out_top_y1, out_p1.z)); normals.push_back(Vector3.UP)
		vertices.push_back(Vector3(in_p2.x, top_y2, in_p2.z)); normals.push_back(Vector3.UP)
		vertices.push_back(Vector3(out_p2.x, out_top_y2, out_p2.z)); normals.push_back(Vector3.UP)
		
		indices.push_back(base); indices.push_back(base + 1); indices.push_back(base + 2)
		indices.push_back(base + 1); indices.push_back(base + 3); indices.push_back(base + 2)
		
		# OUTER SIDE WALL (Top to Table)
		var side_base = vertices.size()
		var side_normal = (dir_curr + dir_next).normalized()
		vertices.push_back(Vector3(out_p1.x, out_top_y1, out_p1.z)); normals.push_back(side_normal)
		vertices.push_back(Vector3(out_p2.x, out_top_y2, out_p2.z)); normals.push_back(side_normal)
		vertices.push_back(Vector3(out_p1.x, bottom_y, out_p1.z)); normals.push_back(side_normal)
		vertices.push_back(Vector3(out_p2.x, bottom_y, out_p2.z)); normals.push_back(side_normal)
		
		indices.push_back(side_base); indices.push_back(side_base + 2); indices.push_back(side_base + 1)
		indices.push_back(side_base + 1); indices.push_back(side_base + 2); indices.push_back(side_base + 3)
		
		# INNER SIDE WALL (Seal against tile)
		# This goes from top_y down to platform level
		var in_side_base = vertices.size()
		var in_normal = - side_normal
		vertices.push_back(Vector3(in_p1.x, top_y1, in_p1.z)); normals.push_back(in_normal)
		vertices.push_back(Vector3(in_p2.x, top_y2, in_p2.z)); normals.push_back(in_normal)
		vertices.push_back(Vector3(in_p1.x, bottom_y, in_p1.z)); normals.push_back(in_normal)
		vertices.push_back(Vector3(in_p2.x, bottom_y, in_p2.z)); normals.push_back(in_normal)
		
		indices.push_back(in_side_base); indices.push_back(in_side_base + 1); indices.push_back(in_side_base + 2)
		indices.push_back(in_side_base + 1); indices.push_back(in_side_base + 3); indices.push_back(in_side_base + 2)
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Create a solid hexagonal mesh (filled, not a ring)
func _create_solid_hex_mesh(radius: float, bottom_y: float, top_y: float) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	var normals = PackedVector3Array()
	
	# === TOP FACE ===
	# Center vertex
	var top_center_idx: int = 0
	vertices.append(Vector3(0, top_y, 0))
	normals.append(Vector3.UP)
	
	# 6 corner vertices for top
	for i in range(6):
		var angle: float = deg_to_rad(60 * i)
		var x: float = radius * cos(angle)
		var z: float = radius * sin(angle)
		vertices.append(Vector3(x, top_y, z))
		normals.append(Vector3.UP)
	
	# Top face triangles (fan from center)
	for i in range(6):
		indices.append(top_center_idx)
		indices.append(i + 1)
		indices.append(((i + 1) % 6) + 1)
	
	# === BOTTOM FACE ===
	var bottom_center_idx: int = vertices.size()
	vertices.append(Vector3(0, bottom_y, 0))
	normals.append(Vector3.DOWN)
	
	# 6 corner vertices for bottom
	for i in range(6):
		var angle: float = deg_to_rad(60 * i)
		var x: float = radius * cos(angle)
		var z: float = radius * sin(angle)
		vertices.append(Vector3(x, bottom_y, z))
		normals.append(Vector3.DOWN)
	
	# Bottom face triangles (fan from center, reversed winding)
	var bottom_start: int = bottom_center_idx + 1
	for i in range(6):
		indices.append(bottom_center_idx)
		indices.append(bottom_start + ((i + 1) % 6))
		indices.append(bottom_start + i)
	
	# === SIDE FACES ===
	# Connect top and bottom corners with quads
	for i in range(6):
		var top1: int = i + 1 # Top corner i
		var top2: int = ((i + 1) % 6) + 1 # Top corner i+1
		var bot1: int = bottom_start + i # Bottom corner i
		var bot2: int = bottom_start + ((i + 1) % 6) # Bottom corner i+1
		
		# Calculate outward normal for this side
		var mid_angle: float = deg_to_rad(60 * i + 30)
		var side_normal = Vector3(cos(mid_angle), 0, sin(mid_angle)).normalized()
		
		# Add side vertices with proper normals
		var side_base: int = vertices.size()
		vertices.append(vertices[top1])
		normals.append(side_normal)
		vertices.append(vertices[top2])
		normals.append(side_normal)
		vertices.append(vertices[bot1])
		normals.append(side_normal)
		vertices.append(vertices[bot2])
		normals.append(side_normal)
		
		# Two triangles for the quad
		indices.append(side_base)
		indices.append(side_base + 2)
		indices.append(side_base + 1)
		
		indices.append(side_base + 1)
		indices.append(side_base + 2)
		indices.append(side_base + 3)
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Create the stone brick material for the platform/border
## Uses enhanced normals and AO for visible stone depth
func _create_stone_border_material() -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	
	# Try to load stone texture
	var base_path: String = BOARD_TEXTURES_PATH + "board_stone_"
	var diffuse_tex = _load_texture(base_path + "diffuse.jpg")
	if not diffuse_tex:
		diffuse_tex = _load_texture(base_path + "diffuse.png")
	if not diffuse_tex:
		base_path = BOARD_TEXTURES_PATH + "frame_stone_"
		diffuse_tex = _load_texture(base_path + "diffuse.png")
	
	if diffuse_tex:
		material.albedo_texture = diffuse_tex
		material.albedo_color = Color(0.85, 0.83, 0.80) # Slight brightness boost
		
		# Normal map with ENHANCED strength for visible stone depth
		var normal_tex = _load_texture(base_path + "normal.jpg")
		if not normal_tex:
			normal_tex = _load_texture(base_path + "normal.png")
		if normal_tex:
			material.normal_enabled = true
			material.normal_texture = normal_tex
			material.normal_scale = 1.8 # ENHANCED - very strong for visible mortar lines
		
		# Roughness map
		var roughness_tex = _load_texture(base_path + "roughness.jpg")
		if not roughness_tex:
			roughness_tex = _load_texture(base_path + "roughness.png")
		if roughness_tex:
			material.roughness_texture = roughness_tex
			material.roughness = 1.0 # Let texture drive roughness
		else:
			material.roughness = 0.9
		
		# AO map with ENHANCED intensity for deep shadows in mortar
		var ao_tex = _load_texture(base_path + "ao.jpg")
		if not ao_tex:
			ao_tex = _load_texture(base_path + "ao.png")
		if ao_tex:
			material.ao_enabled = true
			material.ao_texture = ao_tex
			material.ao_light_affect = 1.0 # ENHANCED - full strength for deep crevice shadows
		
		print("[BoardEnvironment] Stone texture loaded with enhanced depth: " + base_path)
	else:
		# Fallback - uniform gray stone color
		material.albedo_color = Color(0.55, 0.53, 0.50)
		material.roughness = 0.9
		print("[BoardEnvironment] Using fallback gray color for border")
	
	material.metallic = 0.0
	material.cull_mode = BaseMaterial3D.CULL_BACK
	
	# High quality shading
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	material.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
	material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	
	# Triplanar for seamless tiling
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3(0.08, 0.08, 0.08)
	
	return material


# =============================================================================
# FRAME (No longer needed - unified border handles this)
# =============================================================================

func _create_frame(_board_world_radius: float) -> void:
	# Border is now created as a single unified mesh in _create_board_platform
	pass


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
	vertices.append(Vector3(0, half_height, 0)) # Top center
	normals.append(Vector3.UP)
	vertices.append(Vector3(0, -half_height, 0)) # Bottom center
	normals.append(Vector3.DOWN)
	
	# Create 6 corner vertices for top and bottom
	for i in range(6):
		# Match hex tile orientation (flat-top when viewed from above)
		var angle: float = deg_to_rad(60 * i) # No offset for flat-top orientation
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
		var v1: int = 2 + i * 2 # Current top vertex
		var v2: int = 2 + ((i + 1) % 6) * 2 # Next top vertex
		indices.append(center_top_idx)
		indices.append(v1)
		indices.append(v2)
	
	# Bottom face triangles (fan from center, reversed winding)
	for i in range(6):
		var v1: int = 3 + i * 2 # Current bottom vertex
		var v2: int = 3 + ((i + 1) % 6) * 2 # Next bottom vertex
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
## inner_top_y and outer_top_y can differ to create a sloped top surface
func _create_hexagonal_frame_mesh(inner_radius: float, outer_radius: float,
								   bottom_y: float, top_y: float,
								   inner_top_y: float = -999.0) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	var normals = PackedVector3Array()
	
	# If inner_top_y not specified, use same as top_y (uniform height)
	var actual_inner_top_y: float = inner_top_y if inner_top_y > -900.0 else top_y
	var actual_outer_top_y: float = top_y
	
	# For each of the 6 sides of the hexagon
	for i in range(6):
		# Match hex tile orientation (flat-top when viewed from above)
		var angle1: float = deg_to_rad(60 * i) # No offset for flat-top
		var angle2: float = deg_to_rad(60 * (i + 1))
		
		# Calculate corner positions
		var inner1 = Vector3(inner_radius * cos(angle1), 0, inner_radius * sin(angle1))
		var inner2 = Vector3(inner_radius * cos(angle2), 0, inner_radius * sin(angle2))
		var outer1 = Vector3(outer_radius * cos(angle1), 0, outer_radius * sin(angle1))
		var outer2 = Vector3(outer_radius * cos(angle2), 0, outer_radius * sin(angle2))
		
		# === TOP FACE (may be sloped if inner_top != outer_top) ===
		var base_idx: int = vertices.size()
		vertices.append(Vector3(outer1.x, actual_outer_top_y, outer1.z))
		vertices.append(Vector3(inner1.x, actual_inner_top_y, inner1.z))
		vertices.append(Vector3(outer2.x, actual_outer_top_y, outer2.z))
		vertices.append(Vector3(inner2.x, actual_inner_top_y, inner2.z))
		
		# Calculate sloped normal for top face
		var top_normal = Vector3.UP
		if abs(actual_outer_top_y - actual_inner_top_y) > 0.01:
			# Sloped - calculate proper normal
			var edge1 = Vector3(outer1.x - inner1.x, actual_outer_top_y - actual_inner_top_y, outer1.z - inner1.z)
			var edge2 = Vector3(inner2.x - inner1.x, 0, inner2.z - inner1.z)
			top_normal = edge2.cross(edge1).normalized()
			if top_normal.y < 0:
				top_normal = - top_normal
		
		for _j in range(4):
			normals.append(top_normal)
		
		indices.append(base_idx)
		indices.append(base_idx + 1)
		indices.append(base_idx + 2)
		indices.append(base_idx + 1)
		indices.append(base_idx + 3)
		indices.append(base_idx + 2)
		
		# === OUTER SIDE FACE ===
		base_idx = vertices.size()
		var outer_normal = Vector3(cos((angle1 + angle2) / 2.0), 0, sin((angle1 + angle2) / 2.0)).normalized()
		vertices.append(Vector3(outer1.x, actual_outer_top_y, outer1.z))
		vertices.append(Vector3(outer2.x, actual_outer_top_y, outer2.z))
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
		var inner_normal = - Vector3(cos((angle1 + angle2) / 2.0), 0, sin((angle1 + angle2) / 2.0)).normalized()
		vertices.append(Vector3(inner1.x, actual_inner_top_y, inner1.z))
		vertices.append(Vector3(inner2.x, actual_inner_top_y, inner2.z))
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

## Create wood material for the table (rustic medieval)
## Uses new Poly Haven textures: weathered_planks, dark_wooden_planks
## Manor Lords aesthetic: Muted earth tones, high roughness, heavy AO
func _create_wood_material() -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	# Priority order: weathered planks (most rustic), dark planks, worn cabinet
	var variants = [
		"table_weathered_", # Weathered wood planks (Poly Haven)
		"table_dark_planks_", # Dark wooden planks (Poly Haven)
		"table_worn_cabinet_", # Worn wood cabinet (Poly Haven)
		"table_wood_alt3_", # Original alt textures
	]
	var loaded = false
	
	for variant in variants:
		var base_path: String = BOARD_TEXTURES_PATH + variant
		# Try jpg first (new downloads), then png (old textures)
		var diffuse_tex = _load_texture(base_path + "diffuse.jpg")
		if not diffuse_tex:
			diffuse_tex = _load_texture(base_path + "diffuse.png")
		
		if diffuse_tex:
			material.albedo_texture = diffuse_tex
			# Manor Lords: Slight desaturation of wood
			material.albedo_color = Color(0.92, 0.90, 0.88) # Subtle desaturation
			
			# Load normal map (try jpg then png)
			# Manor Lords: Over-driven normals (1.2x-1.5x)
			var normal_tex = _load_texture(base_path + "normal.jpg")
			if not normal_tex:
				normal_tex = _load_texture(base_path + "normal.png")
			if normal_tex:
				material.normal_enabled = true
				material.normal_texture = normal_tex
				material.normal_scale = 1.5 # ENHANCED - strong for visible wood grain
			
			# Load roughness map - PRIORITY for Manor Lords PBR
			var roughness_tex = _load_texture(base_path + "roughness.jpg")
			if not roughness_tex:
				roughness_tex = _load_texture(base_path + "roughness.png")
			if roughness_tex:
				material.roughness_texture = roughness_tex
				material.roughness = 1.0
			else:
				material.roughness = 0.88 # High roughness for weathered wood
			
			# Load AO map - HIGH PRIORITY for Manor Lords aesthetic
			var ao_tex = _load_texture(base_path + "ao.jpg")
			if not ao_tex:
				ao_tex = _load_texture(base_path + "ao.png")
			if ao_tex:
				material.ao_enabled = true
				material.ao_texture = ao_tex
				material.ao_light_affect = 0.9 # ENHANCED - strong for deep grain shadows
			
			loaded = true
			print("[BoardEnvironment] Table using: " + variant)
			break
	
	if not loaded:
		# Fallback - rustic dark wood color (Manor Lords muted earth tone)
		material.albedo_color = Color(0.18, 0.13, 0.08) # Deep umber - muted
		material.roughness = 0.92 # Very rough weathered wood
	
	material.metallic = 0.0
	
	# Triplanar for seamless tiling
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3(TABLE_TEXTURE_SCALE, TABLE_TEXTURE_SCALE, TABLE_TEXTURE_SCALE)
	
	return material


## Create platform material using old stone wall texture (medieval castle floor)
## Uses Poly Haven old_stone_wall texture
## Manor Lords aesthetic: Muted slate/charcoal, weathered stone
func _create_platform_material() -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	
	# Try new board_stone textures (old_stone_wall from Poly Haven)
	var base_path: String = BOARD_TEXTURES_PATH + "board_stone_"
	
	# Try jpg first (new download), then png, then fall back to frame_stone
	var diffuse_tex = _load_texture(base_path + "diffuse.jpg")
	if not diffuse_tex:
		diffuse_tex = _load_texture(base_path + "diffuse.png")
	if not diffuse_tex:
		base_path = BOARD_TEXTURES_PATH + "frame_stone_"
		diffuse_tex = _load_texture(base_path + "diffuse.png")
	
	if diffuse_tex:
		material.albedo_texture = diffuse_tex
		# Manor Lords: Muted, desaturated stone (slate/charcoal palette)
		material.albedo_color = Color(0.60, 0.58, 0.55) # Slate grey - desaturated
		
		# Normal map - over-driven for stone texture depth
		var normal_tex = _load_texture(base_path + "normal.jpg")
		if not normal_tex:
			normal_tex = _load_texture(base_path + "normal.png")
		if normal_tex:
			material.normal_enabled = true
			material.normal_texture = normal_tex
			material.normal_scale = 0.75 # ~1.5x for pronounced stone crevices
		
		# Roughness - PRIORITY for Manor Lords PBR
		var roughness_tex = _load_texture(base_path + "roughness.jpg")
		if not roughness_tex:
			roughness_tex = _load_texture(base_path + "roughness.png")
		if roughness_tex:
			material.roughness_texture = roughness_tex
			material.roughness = 1.0
		else:
			material.roughness = 0.92 # Very rough weathered stone
		
		# AO - HIGH PRIORITY for stone crevices
		var ao_tex = _load_texture(base_path + "ao.jpg")
		if not ao_tex:
			ao_tex = _load_texture(base_path + "ao.png")
		if ao_tex:
			material.ao_enabled = true
			material.ao_texture = ao_tex
			material.ao_light_affect = 0.6 # Heavy AO for stone crevices
		
		print("[BoardEnvironment] Platform using: " + base_path)
	else:
		# Fallback - aged stone color (Manor Lords charcoal/slate)
		material.albedo_color = Color(0.16, 0.15, 0.14) # Charcoal stone
		material.roughness = 0.95
	
	material.metallic = 0.0
	material.cull_mode = BaseMaterial3D.CULL_BACK
	
	# Triplanar for seamless tiling on sides
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
