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


## Generate the complete hex board with procedural biomes
func generate_board() -> void:
	_clear_board()
	
	# Generate all hex coordinates for the board
	all_coordinates = HexCoordinates.generate_hexagonal_board(board_radius)
	
	print("Generating board with %d hexes" % all_coordinates.size())
	
	# Generate biomes for the board
	var biome_generator = BiomeGenerator.new()
	var biome_map = biome_generator.generate_biomes(all_coordinates)
	
	# Print debug info
	biome_generator.print_distribution(biome_map)
	biome_generator.print_adjacency_violations(all_coordinates, biome_map)
	
	# Create hex tiles
	for coord in all_coordinates:
		var biome = biome_map.get(coord._to_key(), Biomes.Type.PLAINS)
		_create_tile(coord, biome)
	
	# Set up spawn positions
	_setup_spawn_positions()
	
	print("Board generation complete!")


## Clear existing board
func _clear_board() -> void:
	for key in tiles:
		tiles[key].queue_free()
	tiles.clear()
	all_coordinates.clear()
	spawn_positions.clear()


# =============================================================================
# TILE CREATION
# =============================================================================

func _create_tile(coord: HexCoordinates, biome: Biomes.Type) -> HexTile:
	var tile: HexTile
	
	if hex_tile_scene:
		tile = hex_tile_scene.instantiate() as HexTile
	else:
		# Create tile programmatically if no scene assigned
		tile = HexTile.new()
	
	tile.hex_size = hex_size
	add_child(tile)
	tile.setup(coord, biome)
	
	# Connect signals
	tile.tile_clicked.connect(_on_tile_clicked)
	tile.tile_hovered.connect(_on_tile_hovered)
	
	# Store in dictionary
	var key = coord._to_key()
	tiles[key] = tile
	
	return tile


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
