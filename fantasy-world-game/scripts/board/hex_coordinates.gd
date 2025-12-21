## Hex Coordinates Utility
## Provides axial/cube coordinate system for hexagonal grid math
## Based on Red Blob Games' excellent hex grid guide
class_name HexCoordinates
extends RefCounted

# =============================================================================
# HEX COORDINATE REPRESENTATION
# =============================================================================
# Using axial coordinates (q, r) for storage
# Can convert to cube coordinates (x, y, z) where x + y + z = 0

var q: int  # Column (axial)
var r: int  # Row (axial)

# Cube coordinates (derived from axial)
var x: int:
	get: return q
var y: int:
	get: return -q - r
var z: int:
	get: return r


func _init(q_coord: int = 0, r_coord: int = 0) -> void:
	q = q_coord
	r = r_coord


## Create from cube coordinates
static func from_cube(x: int, y: int, z: int) -> HexCoordinates:
	# Validate cube coordinates sum to 0
	assert(x + y + z == 0, "Cube coordinates must sum to 0")
	return HexCoordinates.new(x, z)


## Create a copy of this hex coordinate
func duplicate() -> HexCoordinates:
	return HexCoordinates.new(q, r)


# =============================================================================
# HEX GEOMETRY CONSTANTS
# =============================================================================
# For pointy-top hexagons
const SQRT_3: float = 1.7320508075688772

# Direction vectors for the 6 neighbors (pointy-top orientation)
# Starting from right, going counter-clockwise
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),   # Right
	Vector2i(1, -1),  # Upper Right
	Vector2i(0, -1),  # Upper Left
	Vector2i(-1, 0),  # Left
	Vector2i(-1, 1),  # Lower Left
	Vector2i(0, 1)    # Lower Right
]

const DIRECTION_NAMES: Array[String] = [
	"Right", "Upper Right", "Upper Left", "Left", "Lower Left", "Lower Right"
]


# =============================================================================
# NEIGHBOR OPERATIONS
# =============================================================================

## Get neighbor in specified direction (0-5)
func get_neighbor(direction: int) -> HexCoordinates:
	var dir = DIRECTIONS[direction % 6]
	return HexCoordinates.new(q + dir.x, r + dir.y)


## Get all 6 neighbors
func get_all_neighbors() -> Array[HexCoordinates]:
	var neighbors: Array[HexCoordinates] = []
	for dir in DIRECTIONS:
		neighbors.append(HexCoordinates.new(q + dir.x, r + dir.y))
	return neighbors


## Get neighbors within a certain range (ring)
func get_neighbors_at_range(range_val: int) -> Array[HexCoordinates]:
	if range_val <= 0:
		return [self.duplicate()]
	
	var results: Array[HexCoordinates] = []
	var current = HexCoordinates.new(q - range_val, r + range_val)
	
	for i in range(6):
		for _j in range(range_val):
			results.append(current.duplicate())
			current = current.get_neighbor(i)
	
	return results


## Get all hexes within range (filled circle)
func get_hexes_in_range(range_val: int) -> Array[HexCoordinates]:
	var results: Array[HexCoordinates] = []
	for dq in range(-range_val, range_val + 1):
		for dr in range(max(-range_val, -dq - range_val), min(range_val, -dq + range_val) + 1):
			results.append(HexCoordinates.new(q + dq, r + dr))
	return results


# =============================================================================
# DISTANCE CALCULATIONS
# =============================================================================

## Calculate hex distance to another coordinate
func distance_to(other: HexCoordinates) -> int:
	# Using cube coordinate distance formula
	return (abs(x - other.x) + abs(y - other.y) + abs(z - other.z)) / 2


## Static version for convenience
static func distance(a: HexCoordinates, b: HexCoordinates) -> int:
	return a.distance_to(b)


# =============================================================================
# COORDINATE CONVERSION
# =============================================================================

## Convert hex coordinates to pixel position (for rendering)
## size = distance from center to corner
func to_pixel(hex_size: float) -> Vector2:
	var px = hex_size * (SQRT_3 * q + SQRT_3 / 2.0 * r)
	var py = hex_size * (3.0 / 2.0 * r)
	return Vector2(px, py)


## Convert pixel position to hex coordinates (for input)
static func from_pixel(pixel: Vector2, hex_size: float) -> HexCoordinates:
	var q_frac = (SQRT_3 / 3.0 * pixel.x - 1.0 / 3.0 * pixel.y) / hex_size
	var r_frac = (2.0 / 3.0 * pixel.y) / hex_size
	return round_hex(q_frac, r_frac)


## Round fractional hex coordinates to nearest hex
static func round_hex(q_frac: float, r_frac: float) -> HexCoordinates:
	var x_frac = q_frac
	var z_frac = r_frac
	var y_frac = -x_frac - z_frac
	
	var rx = round(x_frac)
	var ry = round(y_frac)
	var rz = round(z_frac)
	
	var x_diff = abs(rx - x_frac)
	var y_diff = abs(ry - y_frac)
	var z_diff = abs(rz - z_frac)
	
	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry - rz
	elif y_diff > z_diff:
		ry = -rx - rz
	else:
		rz = -rx - ry
	
	return HexCoordinates.new(int(rx), int(rz))


# =============================================================================
# LINE DRAWING (for line of sight)
# =============================================================================

## Get all hexes in a line from this hex to target
func line_to(target: HexCoordinates) -> Array[HexCoordinates]:
	var n = distance_to(target)
	if n == 0:
		return [self.duplicate()]
	
	var results: Array[HexCoordinates] = []
	var step = 1.0 / float(n)
	
	for i in range(n + 1):
		var t = step * i
		var lerped = _lerp_hex(self, target, t)
		results.append(lerped)
	
	return results


## Linear interpolation between two hexes
static func _lerp_hex(a: HexCoordinates, b: HexCoordinates, t: float) -> HexCoordinates:
	var q_lerp = a.q * (1.0 - t) + b.q * t
	var r_lerp = a.r * (1.0 - t) + b.r * t
	return round_hex(q_lerp, r_lerp)


# =============================================================================
# PATHFINDING (A* for hex grids)
# =============================================================================

## Find shortest path from this hex to target
## valid_hex_func: Callable that takes HexCoordinates and returns bool
## Returns empty array if no path found
func find_path_to(target: HexCoordinates, valid_hex_func: Callable, max_distance: int = 100) -> Array[HexCoordinates]:
	if not valid_hex_func.call(target):
		return []
	
	var open_set: Array = [{
		"hex": self.duplicate(),
		"g_cost": 0,
		"f_cost": distance_to(target)
	}]
	
	var came_from: Dictionary = {}  # HexCoordinates -> HexCoordinates
	var g_score: Dictionary = {}  # String -> int
	g_score[_to_key()] = 0
	
	while not open_set.is_empty():
		# Sort by f_cost and get lowest
		open_set.sort_custom(func(a, b): return a["f_cost"] < b["f_cost"])
		var current = open_set.pop_front()
		var current_hex: HexCoordinates = current["hex"]
		
		# Check if we reached the target
		if current_hex.equals(target):
			return _reconstruct_path(came_from, current_hex)
		
		# Check neighbors
		for neighbor in current_hex.get_all_neighbors():
			if not valid_hex_func.call(neighbor):
				continue
			
			var tentative_g = g_score.get(current_hex._to_key(), INF) + 1
			var neighbor_key = neighbor._to_key()
			
			if tentative_g < g_score.get(neighbor_key, INF):
				came_from[neighbor_key] = current_hex
				g_score[neighbor_key] = tentative_g
				var f_cost = tentative_g + neighbor.distance_to(target)
				
				if f_cost > max_distance:
					continue
				
				# Check if neighbor is already in open set
				var found = false
				for item in open_set:
					if item["hex"].equals(neighbor):
						item["f_cost"] = f_cost
						found = true
						break
				
				if not found:
					open_set.append({
						"hex": neighbor.duplicate(),
						"g_cost": tentative_g,
						"f_cost": f_cost
					})
	
	return []  # No path found


## Reconstruct path from came_from dictionary
func _reconstruct_path(came_from: Dictionary, current: HexCoordinates) -> Array[HexCoordinates]:
	var path: Array[HexCoordinates] = [current.duplicate()]
	var current_key = current._to_key()
	
	while current_key in came_from:
		current = came_from[current_key]
		current_key = current._to_key()
		path.push_front(current.duplicate())
	
	return path


## Get valid movement hexes within speed range
func get_reachable_hexes(speed: int, valid_hex_func: Callable) -> Array[HexCoordinates]:
	var reachable: Array[HexCoordinates] = []
	var visited: Dictionary = {}
	var frontier: Array = [{"hex": self.duplicate(), "distance": 0}]
	visited[_to_key()] = true
	
	while not frontier.is_empty():
		var current = frontier.pop_front()
		var current_hex: HexCoordinates = current["hex"]
		var current_dist: int = current["distance"]
		
		if current_dist > 0:  # Don't include starting hex
			reachable.append(current_hex)
		
		if current_dist < speed:
			for neighbor in current_hex.get_all_neighbors():
				var key = neighbor._to_key()
				if key not in visited and valid_hex_func.call(neighbor):
					visited[key] = true
					frontier.append({
						"hex": neighbor.duplicate(),
						"distance": current_dist + 1
					})
	
	return reachable


# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

## Equality check
func equals(other: HexCoordinates) -> bool:
	return q == other.q and r == other.r


## Hash key for dictionary storage
func _to_key() -> String:
	return "%d,%d" % [q, r]


## Create from key
static func from_key(key: String) -> HexCoordinates:
	var parts = key.split(",")
	return HexCoordinates.new(int(parts[0]), int(parts[1]))


## String representation
func _to_string() -> String:
	return "Hex(%d, %d)" % [q, r]


## Vector2i representation
func to_vector2i() -> Vector2i:
	return Vector2i(q, r)


## Create from Vector2i
static func from_vector2i(v: Vector2i) -> HexCoordinates:
	return HexCoordinates.new(v.x, v.y)


# =============================================================================
# BOARD GENERATION HELPERS
# =============================================================================

## Generate all hex coordinates for a hexagonal board with given radius
## radius = number of hexes from center to edge
## For 8 hexes per side, radius = 7 (center + 7 rings = 169 total hexes)
static func generate_hexagonal_board(radius: int) -> Array[HexCoordinates]:
	var hexes: Array[HexCoordinates] = []
	
	for dq in range(-radius, radius + 1):
		for dr in range(max(-radius, -dq - radius), min(radius, -dq + radius) + 1):
			hexes.append(HexCoordinates.new(dq, dr))
	
	return hexes


## Get spawn positions for a player (4 hexes at edge)
## side: 0 = left edge (q=-radius), 1 = right edge (q=radius)
static func get_spawn_positions(radius: int, side: int) -> Array[HexCoordinates]:
	var spawns: Array[HexCoordinates] = []
	
	if side == 0:
		# Left edge (q = -radius)
		# For q = -radius, valid r values are: 0 to radius
		# Pick 4 positions centered around middle
		var start_r = (radius - 3) / 2  # Center the 4 spawns
		for i in range(4):
			spawns.append(HexCoordinates.new(-radius, start_r + i))
	else:
		# Right edge (q = radius)
		# For q = radius, valid r values are: -radius to 0
		# Pick 4 positions centered around middle
		var start_r = (-radius + 3) / 2 - 3  # Center the 4 spawns
		for i in range(4):
			spawns.append(HexCoordinates.new(radius, start_r + i))
	
	return spawns
