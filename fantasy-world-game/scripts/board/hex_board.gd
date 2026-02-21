## Hex Board
## Manages the hexagonal game board
## Handles board generation, tile access, and coordinate lookups
class_name HexBoard
extends Node3D

# =============================================================================
# SIGNALS
# =============================================================================
signal tile_selected(tile: HexTile)
signal tile_hovered(tile: HexTile)

# =============================================================================
# PROPERTIES - BOARD SIZE
# =============================================================================
## Board radius (GameConfig.BOARD_SIZE - 1, e.g., 12 hexes per side = radius 11)
var board_radius: int:
	get:
		return GameConfig.BOARD_SIZE - 1

# =============================================================================
# EXPORTS
# =============================================================================
@export var hex_size: float = 1.0 # Size of each hex
@export var hex_tile_scene: PackedScene # Reference to hex_tile.tscn

# =============================================================================
# PROPERTIES
# =============================================================================
# Dictionary mapping coordinate key to HexTile
var tiles: Dictionary = {}
# Array of all hex coordinates
var all_coordinates: Array[HexCoordinates] = []
# Height map for all tiles (coordinate key -> height value)
var height_map: Dictionary = {}
# Vertex map for vertex-based displacement (vertex_key -> height value)
var vertex_map: Dictionary = {}
# Biome map (coordinate key -> Biome.Type)
var biome_map: Dictionary = {}
# Spawn positions for each player (player_id -> Array[HexCoordinates])
var spawn_positions: Dictionary = {}
# Currently selected tile
var selected_tile: HexTile = null
# Currently highlighted tiles for movement/attack
var highlighted_tiles: Array[HexTile] = []


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	pass # Board is generated via generate_board()


## Generate the complete hex board with procedural biomes and terrain height
func generate_board() -> void:
	_clear_board()
	
	# Generate all hex coordinates for the board
	all_coordinates = HexCoordinates.generate_hexagonal_board(board_radius)
	
	print("Generating board with %d hexes" % all_coordinates.size())
	
	# Generate biomes and heights for the board
	var biome_generator = BiomeGenerator.new()
	var generation_data = biome_generator.generate_biomes(all_coordinates)
	
	# Extract biome and height maps (store biome_map as instance variable)
	biome_map = generation_data.get("biomes", {})
	height_map = generation_data.get("heights", {})
	
	# Quantize height map to 0.25 unit steps to prevent micro-clipping
	for key in height_map:
		height_map[key] = snappedf(height_map[key], 0.25)
	
	# Print debug info
	biome_generator.print_distribution(biome_map)
	biome_generator.print_adjacency_violations(all_coordinates, biome_map)
	
	# Create hex tiles with initial setup
	for coord in all_coordinates:
		var key = coord._to_key()
		var biome = biome_map.get(key, Biomes.Type.PLAINS)
		var height = height_map.get(key, 0.0)
		_create_tile(coord, biome, height)
	
	# VERTEX-BASED DISPLACEMENT SYSTEM
	# Generate vertex heights based on biome interpolation
	_generate_vertex_heights()
	
	# Second pass: update tile meshes with vertex heights
	_update_tile_meshes_with_vertex_heights()
	
	# Note: Junction fills disabled - vertex-based system creates seamless terrain
	# _create_junction_fills()
	
	# Set up spawn positions
	_setup_spawn_positions()
	
	print("Board generation complete!")


## Clear existing board
func _clear_board() -> void:
	for key in tiles:
		tiles[key].queue_free()
	tiles.clear()
	all_coordinates.clear()
	height_map.clear()
	vertex_map.clear()
	biome_map.clear()
	spawn_positions.clear()


# =============================================================================
# TILE CREATION
# =============================================================================

func _create_tile(coord: HexCoordinates, biome: Biomes.Type, height: float) -> HexTile:
	var tile: HexTile
	
	if hex_tile_scene:
		tile = hex_tile_scene.instantiate() as HexTile
	else:
		# Create tile programmatically if no scene assigned
		tile = HexTile.new()
	
	tile.hex_size = hex_size
	tile.tile_height = height
	add_child(tile)
	tile.setup(coord, biome)
	
	# STRICT TRANSFORM ENFORCEMENT
	# 1. Calculate precise pixel position (Pointy Top)
	var pixel_pos = coord.to_pixel(hex_size)
	
	# 2. Add Z-fighting offset (0.02) to base height
	var base_y = GameConfig.BOARD_LIFT + 0.02
	
	# 3. Apply Transform (Pivot at center, Upright)
	tile.position = Vector3(pixel_pos.x, base_y, pixel_pos.y)
	tile.basis = Basis.IDENTITY
	
	# Connect signals
	tile.tile_clicked.connect(_on_tile_clicked)
	tile.tile_hovered.connect(_on_tile_hovered)
	
	# Store in dictionary
	var key = coord._to_key()
	tiles[key] = tile
	
	return tile


## Update all tile meshes with neighbor height information for smooth ramps
func _update_tile_meshes_with_neighbors() -> void:
	for key in tiles:
		var tile: HexTile = tiles[key]
		var coord: HexCoordinates = tile.coordinates
		
		# Get neighbor heights (6 neighbors for hex)
		var neighbor_heights: Array[float] = []
		for neighbor in coord.get_all_neighbors():
			var nkey = neighbor._to_key()
			if nkey in height_map:
				# Use quantized height directly
				neighbor_heights.append(height_map[nkey])
			else:
				# Edge of board - use special sentinel value to mark as edge
				# This makes edge tiles ramp to meet the stone frame at BOARD_LIFT
				neighbor_heights.append(-999.0)
		
		# Update mesh with neighbor heights for ramped edges
		tile.update_mesh_with_neighbors(neighbor_heights)

# =============================================================================
# VERTEX-BASED DISPLACEMENT SYSTEM
# =============================================================================




## Generate vertex heights using biome-based interpolation with proper averaging
## PERIMETER SEAL: Vertices shared by fewer than 3 tiles are pinned to 0.0
## In a hex grid, interior vertices are always shared by exactly 3 tiles.
## Perimeter vertices (shared by 1 or 2 tiles) are on the board edge and must
## match the stone border frame height (0.0 in local tile space).
func _generate_vertex_heights() -> void:
	vertex_map.clear()
	
	# Dictionary: vertex_position_key -> Array of base_heights from all touching tiles
	# This prevents additive height spikes by collecting heights first
	var vertex_height_collections: Dictionary = {}
	
	# FIRST PASS: Collect heights for each vertex
	# Don't calculate final heights yet - just collect the data
	for coord in all_coordinates:
		var key = coord._to_key()
		var biome = biome_map.get(key, Biomes.Type.PLAINS)
		var base_height = Biomes.get_base_height(biome) # Get biome's base height
		
		# For each of the 6 corners of this hex
		for i in range(6):
			var vertex_pos = _get_vertex_world_position(coord, i)
			var vertex_key = _vertex_position_to_key(vertex_pos)
			
			# Initialize array if this is the first tile touching this vertex
			if vertex_key not in vertex_height_collections:
				vertex_height_collections[vertex_key] = []
			
			# Add this tile's base height to the vertex's collection
			vertex_height_collections[vertex_key].append(base_height)
	
	# SECOND PASS: Calculate final heights with PERIMETER SEAL
	for vertex_key in vertex_height_collections:
		var height_array = vertex_height_collections[vertex_key]
		
		# PERIMETER SEAL: In a hex grid, interior vertices are shared by exactly 3 tiles.
		# If fewer than 3 tiles touch this vertex, it's on the board perimeter.
		# Pin it to 0.0 so it sits flush with the stone border frame.
		var is_perimeter_vertex = height_array.size() < 3
		
		if is_perimeter_vertex:
			# HARD CLAMP: Force all perimeter vertices to exactly 0.0
			# This ensures edge tile corners meet the stone border seamlessly
			vertex_map[vertex_key] = 0.0
		else:
			# Interior vertex: Calculate average of all collected heights
			var total_height = 0.0
			for h in height_array:
				total_height += h
			
			var averaged_height = total_height / height_array.size()
			
			# Apply the height multiplier (after averaging, not before)
			var final_height = averaged_height * GameConfig.TERRAIN_HEIGHT_MULTIPLIER
			
			vertex_map[vertex_key] = final_height
	
	var border_count = 0
	var interior_count = 0
	for vertex_key in vertex_map:
		if vertex_map[vertex_key] == 0.0:
			border_count += 1
		else:
			interior_count += 1
	
	print("Generated %d unique vertices (perimeter sealed: %d, interior: %d)" % 
		[vertex_map.size(), border_count, interior_count])


## Get the surface height for a tile using vertex averaging
## Used for troop placement - much faster than raycasting
## Returns the average Y height of the 6 vertices + 0.2 buffer
const TROOP_HEIGHT_BUFFER: float = 0.2  # Troop Y = average of 6 vertices + 0.2

func get_tile_surface_height(coord: HexCoordinates) -> float:
	var total_height: float = 0.0
	var count: int = 0
	
	# Average the heights of all 6 vertices
	for i in range(6):
		var vertex_pos = _get_vertex_world_position(coord, i)
		var vertex_key = _vertex_position_to_key(vertex_pos)
		var vertex_height = vertex_map.get(vertex_key, 0.0)
		total_height += vertex_height
		count += 1
	
	if count > 0:
		return (total_height / count) + TROOP_HEIGHT_BUFFER
	
	return TROOP_HEIGHT_BUFFER  # Fallback

## Update all tile meshes using vertex heights
func _update_tile_meshes_with_vertex_heights() -> void:
	for key in tiles:
		var tile: HexTile = tiles[key]
		var coord: HexCoordinates = tile.coordinates
		
		# Get vertex heights for this tile's 6 corners
		var vertex_heights: Array[float] = []
		for i in range(6):
			var vertex_pos = _get_vertex_world_position(coord, i)
			var vertex_key = _vertex_position_to_key(vertex_pos)
			var vertex_height = vertex_map.get(vertex_key, 0.0)
			vertex_heights.append(vertex_height)
		
		# Update the tile mesh with these vertex heights
		tile.update_mesh_with_vertex_heights(vertex_heights)


## Get world position of a hex vertex (corner)
## hex_index: 0-5, the corner index
func _get_vertex_world_position(coord: HexCoordinates, corner_index: int) -> Vector3:
	var pixel_pos = coord.to_pixel(hex_size)
	var angle = deg_to_rad(60 * corner_index - 30)
	
	return Vector3(
		pixel_pos.x + hex_size * cos(angle),
		0.0, # Y doesn't matter for keying
		pixel_pos.y + hex_size * sin(angle)
	)


## Convert vertex position to a unique key string
## Rounds to avoid floating point precision issues
func _vertex_position_to_key(pos: Vector3) -> String:
	var precision = 1000.0 # 3 decimal places
	var x = round(pos.x * precision)
	var z = round(pos.z * precision)
	return "%d,%d" % [x, z]


## Convert vertex key back to position (for perimeter checking)
func _key_to_vertex_position(vertex_key: String) -> Vector3:
	var parts = vertex_key.split(",")
	var precision = 1000.0
	return Vector3(
		float(parts[0]) / precision,
		0.0,
		float(parts[1]) / precision
	)


## Check if a tile is on the edge of the board
func _is_tile_on_edge(coord: HexCoordinates) -> bool:
	var neighbors = coord.get_all_neighbors()
	for neighbor in neighbors:
		if neighbor._to_key() not in tiles:
			return true
	return false


## Check if a specific vertex is on the perimeter of the board
## Returns true if this vertex doesn't have a full set of tiles around it
func _is_vertex_on_perimeter(coord: HexCoordinates, vertex_pos: Vector3) -> bool:
	# A vertex is shared by up to 3 tiles
	# If any of those tiles are missing, it's a perimeter vertex
	
	# Find all corners of this tile that match this vertex position
	for i in range(6):
		var corner_pos = _get_vertex_world_position(coord, i)
		if corner_pos.distance_to(vertex_pos) < 0.001:
			# This is corner i of the tile
			# Check the two neighbors that share this corner
			var prev_neighbor_idx = (i + 5) % 6
			var curr_neighbor_idx = i
			
			var neighbors = coord.get_all_neighbors()
			var prev_neighbor = neighbors[prev_neighbor_idx]
			var curr_neighbor = neighbors[curr_neighbor_idx]
			
			# If either neighbor is missing, this vertex is on the perimeter
			if prev_neighbor._to_key() not in tiles or curr_neighbor._to_key() not in tiles:
				return true
			break
	
	return false



## Create junction fill meshes at 3-tile meeting points to eliminate gaps
func _create_junction_fills() -> void:
	# Track which junctions we've already filled to avoid duplicates
	var filled_junctions: Dictionary = {}
	
	# Node to hold all junction meshes
	var junction_container = Node3D.new()
	junction_container.name = "JunctionFills"
	add_child(junction_container)
	
	# For each tile, check the 6 corners (each corner is a 3-tile junction)
	for key in tiles:
		var tile: HexTile = tiles[key]
		var coord: HexCoordinates = tile.coordinates
		var neighbors = coord.get_all_neighbors()
		
		# Each corner i is shared with neighbors (i-1) and (i)
		for i in range(6):
			var prev_neighbor_idx = (i + 5) % 6
			var curr_neighbor_idx = i
			
			var prev_neighbor: HexCoordinates = neighbors[prev_neighbor_idx]
			var curr_neighbor: HexCoordinates = neighbors[curr_neighbor_idx]
			
			# Only create junction if both neighbors exist (not at board edge)
			var prev_key = prev_neighbor._to_key()
			var curr_key = curr_neighbor._to_key()
			
			if prev_key not in tiles or curr_key not in tiles:
				continue
			
			# Create a unique key for this junction (sorted to avoid duplicates)
			var junction_keys = [key, prev_key, curr_key]
			junction_keys.sort()
			var junction_key = "%s_%s_%s" % [junction_keys[0], junction_keys[1], junction_keys[2]]
			
			if junction_key in filled_junctions:
				continue
			filled_junctions[junction_key] = true
			
			# Get the heights of the 3 tiles
			var h1 = height_map.get(key, 0.0)
			var h2 = height_map.get(prev_key, 0.0)
			var h3 = height_map.get(curr_key, 0.0)
			var avg_height = (h1 + h2 + h3) / 3.0
			
			# Calculate corner position in world space
			var angle = deg_to_rad(60 * i - 30)
			var corner_offset_x = hex_size * cos(angle)
			var corner_offset_z = hex_size * sin(angle)
			
			var tile_pos = coord.to_pixel(hex_size)
			var corner_world_pos = Vector3(
				tile_pos.x + corner_offset_x,
				avg_height,
				tile_pos.y + corner_offset_z
			)
			
			# Create a small triangular mesh to fill the junction
			_create_junction_mesh(junction_container, corner_world_pos, h1, h2, h3, avg_height, angle)


## Create a small triangular fill mesh at a junction point
func _create_junction_mesh(parent: Node3D, center: Vector3, h1: float, h2: float, h3: float, avg_height: float, corner_angle: float) -> void:
	# Small offset for the fill triangle vertices (about 10% of hex size)
	var fill_radius = hex_size * 0.15
	
	# Create 3 vertices for the triangle, one toward each tile
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	# Center vertex at average height
	vertices.append(Vector3(center.x, avg_height, center.z))
	normals.append(Vector3.UP)
	uvs.append(Vector2(0.5, 0.5))
	
	# 3 outer vertices, slightly offset toward each tile
	for j in range(3):
		var offset_angle = corner_angle + deg_to_rad(120 * j)
		var vx = center.x + fill_radius * cos(offset_angle)
		var vz = center.z + fill_radius * sin(offset_angle)
		
		# Height interpolated toward that tile
		var heights = [h1, h2, h3]
		var blend_height = avg_height * 0.7 + heights[j] * 0.3
		
		vertices.append(Vector3(vx, blend_height, vz))
		normals.append(Vector3.UP)
		uvs.append(Vector2(0.5 + cos(offset_angle) * 0.5, 0.5 + sin(offset_angle) * 0.5))
	
	# Create 3 triangles (center to each edge)
	indices.append_array([0, 1, 2])
	indices.append_array([0, 2, 3])
	indices.append_array([0, 3, 1])
	
	# Create the mesh
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	
	# Use a neutral dirt/rock material for the fill
	var fill_material = StandardMaterial3D.new()
	fill_material.albedo_color = Color(0.35, 0.30, 0.25) # Neutral earth tone
	fill_material.roughness = 0.9
	mesh_instance.material_override = fill_material
	
	parent.add_child(mesh_instance)


## Set up spawn positions for both players
func _setup_spawn_positions() -> void:
	# Player 0 spawns on one edge
	spawn_positions[0] = HexCoordinates.get_spawn_positions(board_radius, 0)
	# Player 1 spawns on opposite edge
	spawn_positions[1] = HexCoordinates.get_spawn_positions(board_radius, 1)
	
	# Mark spawn tiles
	for player_id in spawn_positions:
		for coord in spawn_positions[player_id]:
			var tile = get_tile_at(coord)
			if tile:
				tile.set_as_spawn(player_id)


# =============================================================================
# TILE ACCESS
# =============================================================================

## Get tile at given coordinates
func get_tile_at(coord: HexCoordinates) -> HexTile:
	var key = coord._to_key()
	return tiles.get(key, null)


## Get tile at q, r coordinates
func get_tile_at_qr(q: int, r: int) -> HexTile:
	return get_tile_at(HexCoordinates.new(q, r))


## Check if coordinates are valid (on the board)
func is_valid_coordinate(coord: HexCoordinates) -> bool:
	return coord._to_key() in tiles


## Get all tiles
func get_all_tiles() -> Array[HexTile]:
	var result: Array[HexTile] = []
	for key in tiles:
		result.append(tiles[key])
	return result


## Get tiles in range from a coordinate
func get_tiles_in_range(center: HexCoordinates, range_val: int) -> Array[HexTile]:
	var result: Array[HexTile] = []
	var coords = center.get_hexes_in_range(range_val)
	for coord in coords:
		var tile = get_tile_at(coord)
		if tile:
			result.append(tile)
	return result


## Get neighbor tiles
func get_neighbor_tiles(coord: HexCoordinates) -> Array[HexTile]:
	var result: Array[HexTile] = []
	var neighbors = coord.get_all_neighbors()
	for neighbor_coord in neighbors:
		var tile = get_tile_at(neighbor_coord)
		if tile:
			result.append(tile)
	return result


## Get the perimeter points of the board as Vector3 positions
## Returns an array of world-space points forming the outer boundary of the hex board
func get_perimeter_points() -> Array[Vector3]:
	var perimeter_points: Array[Vector3] = []
	var edge_segments: Array = [] # Array of [start_point, end_point, angle] for sorting
	
	# Find all perimeter tiles and their exposed edges
	for key in tiles:
		var tile: HexTile = tiles[key]
		var coord: HexCoordinates = tile.coordinates
		var neighbors = coord.get_all_neighbors()
		
		# Check each of the 6 edges
		for i in range(6):
			var neighbor_key = neighbors[i]._to_key()
			
			# If neighbor doesn't exist, this edge is on the perimeter
			if neighbor_key not in tiles:
				# Calculate the two corners of this edge
				var tile_pos = coord.to_pixel(hex_size)
				var tile_height = height_map.get(key, 0.0)
				
				# Corner angles: flat-top hex starts at -30 degrees
				var angle1 = deg_to_rad(60 * i - 30)
				var angle2 = deg_to_rad(60 * (i + 1) - 30)
				
				var corner1 = Vector3(
					tile_pos.x + hex_size * cos(angle1),
					GameConfig.BORDER_HEIGHT,
					tile_pos.y + hex_size * sin(angle1)
				)
				var corner2 = Vector3(
					tile_pos.x + hex_size * cos(angle2),
					GameConfig.BORDER_HEIGHT,
					tile_pos.y + hex_size * sin(angle2)
				)
				
				# Calculate midpoint for sorting angle
				var midpoint = (corner1 + corner2) / 2.0
				var sort_angle = atan2(midpoint.z, midpoint.x)
				
				edge_segments.append({
					"start": corner1,
					"end": corner2,
					"angle": sort_angle,
					"midpoint": midpoint
				})
	
	# Sort edges by angle around the center to form a continuous perimeter
	edge_segments.sort_custom(func(a, b): return a.angle < b.angle)
	
	# Build the perimeter by connecting edges
	if edge_segments.size() == 0:
		return perimeter_points
	
	# Use a more robust approach: connect edges that share endpoints
	var connected_points: Array[Vector3] = []
	var used: Array[bool] = []
	used.resize(edge_segments.size())
	used.fill(false)
	
	# Start with the first segment
	var current_segment = edge_segments[0]
	connected_points.append(current_segment.start)
	connected_points.append(current_segment.end)
	used[0] = true
	var segments_used = 1
	
	# Connect remaining segments
	while segments_used < edge_segments.size():
		var last_point = connected_points[connected_points.size() - 1]
		var found = false
		
		# Find segment that connects to last_point
		for j in range(edge_segments.size()):
			if used[j]:
				continue
			
			var seg = edge_segments[j]
			var distance_to_start = last_point.distance_to(seg.start)
			var distance_to_end = last_point.distance_to(seg.end)
			
			# Threshold for considering points as the same (floating point tolerance)
			var threshold = hex_size * 0.01
			
			if distance_to_start < threshold:
				# Start of this segment connects to our last point
				connected_points.append(seg.end)
				used[j] = true
				segments_used += 1
				found = true
				break
			elif distance_to_end < threshold:
				# End of this segment connects to our last point (reversed)
				connected_points.append(seg.start)
				used[j] = true
				segments_used += 1
				found = true
				break
		
		if not found:
			# No connecting segment found - might have multiple disconnected perimeters
			# Find next unused segment and start a new chain
			for j in range(edge_segments.size()):
				if not used[j]:
					current_segment = edge_segments[j]
					connected_points.append(current_segment.start)
					connected_points.append(current_segment.end)
					used[j] = true
					segments_used += 1
					break
	
	# Remove duplicate points that might occur at corners
	for point in connected_points:
		var is_duplicate = false
		for existing in perimeter_points:
			if point.distance_to(existing) < hex_size * 0.01:
				is_duplicate = true
				break
		if not is_duplicate:
			perimeter_points.append(point)
	
	print("Generated perimeter with %d points from %d edge segments" % [perimeter_points.size(), edge_segments.size()])
	return perimeter_points


# =============================================================================
# MOVEMENT & PATHFINDING
# =============================================================================

## Get valid movement tiles for a troop
func get_movement_tiles(from_coord: HexCoordinates, speed: int, occupied_check: Callable = Callable()) -> Array[HexTile]:
	var result: Array[HexTile] = []
	
	# Validity function for pathfinding
	var is_valid = func(coord: HexCoordinates) -> bool:
		if not is_valid_coordinate(coord):
			return false
		var tile = get_tile_at(coord)
		if occupied_check.is_valid():
			return not occupied_check.call(tile)
		return not tile.is_occupied()
	
	var reachable = from_coord.get_reachable_hexes(speed, is_valid)
	for coord in reachable:
		var tile = get_tile_at(coord)
		if tile:
			result.append(tile)
	
	return result


## Get attack range tiles
func get_attack_tiles(from_coord: HexCoordinates, attack_range: int) -> Array[HexTile]:
	var result: Array[HexTile] = []
	var coords = from_coord.get_hexes_in_range(attack_range)
	
	for coord in coords:
		if coord.equals(from_coord):
			continue # Can't attack self
		var tile = get_tile_at(coord)
		if tile:
			result.append(tile)
	
	return result


## Find path between two coordinates
func find_path(from: HexCoordinates, to: HexCoordinates) -> Array[HexCoordinates]:
	var is_valid = func(coord: HexCoordinates) -> bool:
		return is_valid_coordinate(coord)
	
	return from.find_path_to(to, is_valid)


# =============================================================================
# HIGHLIGHTING
# =============================================================================

## Clear all highlights on the board
func clear_all_highlights() -> void:
	for tile in highlighted_tiles:
		tile.clear_highlights()
	highlighted_tiles.clear()
	
	if selected_tile:
		selected_tile.set_selected(false)
		selected_tile = null


## Highlight movement range for a troop
func highlight_movement(coord: HexCoordinates, speed: int) -> void:
	clear_all_highlights()
	var tiles_in_range = get_movement_tiles(coord, speed)
	print("DEBUG: Highlighting %d tiles for movement from %s with speed %d" % [tiles_in_range.size(), coord._to_string(), speed])
	for tile in tiles_in_range:
		tile.set_movement_highlight(true)
		highlighted_tiles.append(tile)


## Highlight attack range
func highlight_attack(coord: HexCoordinates, attack_range: int) -> void:
	clear_all_highlights()
	var tiles_in_range = get_attack_tiles(coord, attack_range)
	for tile in tiles_in_range:
		tile.set_attack_highlight(true)
		highlighted_tiles.append(tile)


## Select a tile
func select_tile(tile: HexTile) -> void:
	if selected_tile:
		selected_tile.set_selected(false)
	selected_tile = tile
	if tile:
		tile.set_selected(true)


# =============================================================================
# LINE OF SIGHT
# =============================================================================

## Check if there's line of sight between two coordinates
## Note: As per game rules, units do NOT block line of sight
func has_line_of_sight(from: HexCoordinates, to: HexCoordinates) -> bool:
	var line = from.line_to(to)
	
	for coord in line:
		if not is_valid_coordinate(coord):
			return false
		# No biome LOS blocking per game rules
		# Units do NOT block line of sight per game rules
	
	return true


# =============================================================================
# MINE PLACEMENT
# =============================================================================

## Get valid mine placement tiles
func get_valid_mine_placements(player_id: int, existing_mines: Array) -> Array[HexTile]:
	var result: Array[HexTile] = []
	
	for key in tiles:
		var tile: HexTile = tiles[key]
		
		# Check if mine can be placed
		if not tile.can_place_mine():
			continue
		
		# Check minimum distance from other mines
		var too_close = false
		for mine in existing_mines:
			var mine_coord = mine.coordinates
			var distance = tile.coordinates.distance_to(mine_coord)
			if distance < GameConfig.MIN_DISTANCE_BETWEEN_MINES:
				too_close = true
				break
		
		if not too_close:
			result.append(tile)
	
	return result


# =============================================================================
# SPAWN MANAGEMENT
# =============================================================================

## Get spawn positions for a player
func get_player_spawn_positions(player_id: int) -> Array[HexCoordinates]:
	return spawn_positions.get(player_id, [])


## Get available (unoccupied) spawn tiles for a player
func get_available_spawn_tiles(player_id: int) -> Array[HexTile]:
	var result: Array[HexTile] = []
	var positions = get_player_spawn_positions(player_id)
	
	for coord in positions:
		var tile = get_tile_at(coord)
		if tile and not tile.is_occupied():
			result.append(tile)
	
	return result


# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_tile_clicked(tile: HexTile) -> void:
	tile_selected.emit(tile)


func _on_tile_hovered(tile: HexTile) -> void:
	tile_hovered.emit(tile)


# =============================================================================
# DEBUG / UTILITY
# =============================================================================

## Print board statistics
func print_board_stats() -> void:
	print("=== Board Statistics ===")
	print("Total tiles: %d" % tiles.size())
	
	# Count biomes
	var biome_counts: Dictionary = {}
	for key in tiles:
		var tile: HexTile = tiles[key]
		var biome_name = Biomes.get_biome_name(tile.biome_type)
		biome_counts[biome_name] = biome_counts.get(biome_name, 0) + 1
	
	print("Biome distribution:")
	for biome_name in biome_counts:
		var count = biome_counts[biome_name]
		var percent = 100.0 * count / tiles.size()
		print("  %s: %d (%.1f%%)" % [biome_name, count, percent])
