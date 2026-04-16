## Biome Generator - Voronoi Seed + Noise Hybrid
## ============================================================================
## 
## Generates coherent biome regions using scattered biome seed points
## combined with noise-based distance warping for organic, blob-shaped
## biome regions with natural boundaries.
##
## APPROACH:
##   1. Place N random seed-points across the board (≥2 per biome)
##   2. Each tile measures warped-distance to every seed
##   3. The closest seed determines the tile's biome → natural Voronoi blobs
##   4. Noise warps distances so boundaries are irregular (not straight)
##   5. Cleanup passes remove isolated single tiles and fix forbidden adjacencies
##
## This avoids the contour-band artefacts of percentile-based single-noise
## approaches while still producing large, contiguous, organic-looking regions.
##
class_name BiomeGenerator
extends RefCounted


# =============================================================================
# CONFIGURATION CONSTANTS
# =============================================================================

## Total number of biome types (matches Biomes.Type enum count)
const NUM_BIOMES: int = 7

## Total tiles on the board (hexagonal board with radius 11 = 397 tiles)
const TOTAL_TILES: int = 397

## Base tiles per biome (397 / 7 ≈ 56, or ~14%)
const BASE_TILES_PER_BIOME: int = 56

## Random variance applied to each biome's target size (±8 tiles)
const TILE_VARIANCE: int = 8

## Hard maximum tiles per biome (25% cap = ~99 tiles)
const MAX_TILES_PER_BIOME: int = 99

## Height scale for terrain (world units)
const HEIGHT_SCALE: float = 0.5

## Maximum allowed height difference between adjacent tiles
const MAX_HEIGHT_DIFFERENCE: float = 0.15

## Number of smoothing passes for height blending
const SMOOTHING_PASSES: int = 3

## Number of cleanup passes to remove isolated tiles
const CLEANUP_PASSES: int = 5

## Number of seed points placed per biome (more = smaller, more distributed regions)
const SEEDS_PER_BIOME: int = 3

## Noise warp amplitude applied to seed distances (higher = more irregular edges)
const DISTANCE_WARP_AMP: float = 3.5

## Noise frequency for distance warping
const DISTANCE_WARP_FREQ: float = 0.06


# =============================================================================
# FORBIDDEN NEIGHBOR PAIRS - Temperature/Climate Logic
# =============================================================================
const FORBIDDEN_PAIRS: Array = [
	[Biomes.Type.PEAKS, Biomes.Type.ASHLANDS], # Cold vs Hot
	[Biomes.Type.PEAKS, Biomes.Type.WASTES], # Frozen vs Desert
	[Biomes.Type.SWAMP, Biomes.Type.ASHLANDS], # Wet vs Volcanic
	[Biomes.Type.FOREST, Biomes.Type.ASHLANDS], # Forest vs Volcanic
]


# =============================================================================
# INTERNAL STATE
# =============================================================================
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _coord_lookup: Dictionary = {} # "q,r" -> HexCoordinates for O(1) lookup
var _valid_adjacencies: Dictionary = {} # BiomeType -> [allowed neighbor types]

## Noise for warping seed distances (creates irregular boundaries)
var _warp_noise: FastNoiseLite

## Terrain detail noise for micro-variation within biomes
var _terrain_detail_noise: FastNoiseLite

## Master noise for height variation within biomes
var _master_noise: FastNoiseLite

# Board dimensions (calculated during generation)
var _board_radius: float = 11.0


# =============================================================================
# MAIN GENERATION ENTRY POINT
# =============================================================================

## Generate biomes and heights for all coordinates.
## 
## @param coordinates: Array of all HexCoordinates on the board
## @return Dictionary with "biomes" (key -> Type) and "heights" (key -> float)
func generate_biomes(coordinates: Array[HexCoordinates]) -> Dictionary:
	# Initialize
	_rng.randomize()
	_setup_noise()
	_build_coord_lookup(coordinates)
	_build_adjacency_matrix()
	
	# Calculate board radius for island falloff
	_board_radius = _calculate_board_radius(coordinates)
	
	# ==========================================================================
	# STEP 1: Scatter seed points across the board
	# Place SEEDS_PER_BIOME random points for each biome type
	# ==========================================================================
	var all_biomes: Array = Biomes.Type.values()
	
	# Collect pixel positions of every tile for random selection
	var pixel_positions: Array[Vector2] = []
	var coord_keys: Array[String] = []
	for coord in coordinates:
		pixel_positions.append(coord.to_pixel(1.0))
		coord_keys.append(coord._to_key())
	
	# Place seed points -- pick random board positions for each biome
	var seeds: Array[Dictionary] = [] # [{pos: Vector2, biome: Type}, ...]
	
	# Shuffle biome order so there's no fixed spatial pattern
	var shuffled_biomes: Array = all_biomes.duplicate()
	_shuffle_array(shuffled_biomes)
	
	for biome in shuffled_biomes:
		for _i in range(SEEDS_PER_BIOME):
			# Pick a random tile position (with some jitter beyond the tile)
			var idx = _rng.randi_range(0, pixel_positions.size() - 1)
			var base_pos = pixel_positions[idx]
			# Add jitter so seeds of the same biome don't stack on the same tile
			var jitter = Vector2(
				_rng.randf_range(-2.0, 2.0),
				_rng.randf_range(-2.0, 2.0)
			)
			seeds.append({"pos": base_pos + jitter, "biome": biome})
	
	# Spread seeds apart using Lloyd relaxation (1 pass) so they don't clump
	seeds = _lloyd_relax_seeds(seeds, pixel_positions)
	
	# ==========================================================================
	# STEP 2: Assign each tile to nearest seed (warped Voronoi)
	# Noise warps the distance metric so boundaries look organic
	# ==========================================================================
	var biome_map: Dictionary = {}
	var height_map: Dictionary = {}
	
	for coord in coordinates:
		var key: String = coord._to_key()
		var pixel = coord.to_pixel(1.0)
		
		# Find the closest seed with distance warped by noise
		var best_dist: float = INF
		var best_biome: Biomes.Type = Biomes.Type.PLAINS
		
		for seed_data in seeds:
			var raw_dist = pixel.distance_to(seed_data["pos"])
			
			# Warp distance using noise to create irregular, organic boundaries
			# The warp noise is sampled at a point between tile and seed
			var mid = (pixel + seed_data["pos"]) * 0.5
			var warp = _warp_noise.get_noise_2d(mid.x, mid.y) * DISTANCE_WARP_AMP
			var warped_dist = raw_dist + warp
			
			if warped_dist < best_dist:
				best_dist = warped_dist
				best_biome = seed_data["biome"]
		
		biome_map[key] = best_biome
		
		# Height: use master noise with biome-based ranges
		var base_noise = (_master_noise.get_noise_2d(pixel.x, pixel.y) + 1.0) * 0.5
		var detail = (_terrain_detail_noise.get_noise_2d(pixel.x, pixel.y) + 1.0) * 0.5
		var combined = base_noise * 0.8 + detail * 0.2
		combined = _apply_island_falloff(coord, combined)
		height_map[key] = combined
	
	# DEBUG: Print distribution after Voronoi assignment
	print("Distribution after Voronoi seed assignment:")
	_print_biome_distribution(biome_map)
	
	# ==========================================================================
	# STEP 3: REBALANCE DISTRIBUTION
	# Trim boundary tiles from over-represented biomes and give them to
	# under-represented neighbors. This keeps shapes organic (only boundary
	# tiles move) while enforcing roughly equal distribution.
	# ==========================================================================
	@warning_ignore("integer_division")
	var target_per_biome: int = TOTAL_TILES / NUM_BIOMES  # ~56
	var tolerance: int = 8  # Allow ±8 tiles from target (~±2%)
	var max_rebalance_iters: int = 200  # Safety cap
	
	for _iter in range(max_rebalance_iters):
		var counts = _count_biomes(biome_map)
		
		# Find the most over-represented biome
		var worst_over: Biomes.Type = Biomes.Type.PLAINS
		var worst_over_excess: int = 0
		for biome in Biomes.Type.values():
			var excess = counts.get(biome, 0) - (target_per_biome + tolerance)
			if excess > worst_over_excess:
				worst_over_excess = excess
				worst_over = biome
		
		# If no biome exceeds tolerance, we're balanced
		if worst_over_excess <= 0:
			break
		
		# Find boundary tiles of the over-represented biome
		# (tiles that have at least one neighbor of a different biome)
		var boundary_tiles: Array[String] = []
		for coord in coordinates:
			var key: String = coord._to_key()
			if biome_map[key] != worst_over:
				continue
			var neighbors = _get_valid_neighbors(coord)
			for nb in neighbors:
				var nkey = nb._to_key()
				if nkey in biome_map and biome_map[nkey] != worst_over:
					boundary_tiles.append(key)
					break
		
		if boundary_tiles.is_empty():
			break  # Can't trim further without breaking contiguity
		
		# Find the most under-represented biome
		var best_under: Biomes.Type = Biomes.Type.PLAINS
		var worst_deficit: int = 0
		for biome in Biomes.Type.values():
			var deficit = (target_per_biome - tolerance) - counts.get(biome, 0)
			if deficit > worst_deficit:
				worst_deficit = deficit
				best_under = biome
		
		# Reassign one boundary tile to the most under-represented neighbor biome
		# Prefer tiles that actually border the under-represented biome
		var reassigned: bool = false
		for bkey in boundary_tiles:
			var bcoord = _coord_lookup[bkey]
			var neighbors = _get_valid_neighbors(bcoord)
			for nb in neighbors:
				var nkey = nb._to_key()
				if nkey in biome_map and biome_map[nkey] == best_under:
					biome_map[bkey] = best_under
					reassigned = true
					break
			if reassigned:
				break
		
		# If we couldn't find a tile bordering the most-needed biome,
		# reassign to ANY under-represented neighbor biome instead
		if not reassigned:
			for bkey in boundary_tiles:
				var bcoord = _coord_lookup[bkey]
				var neighbors = _get_valid_neighbors(bcoord)
				for nb in neighbors:
					var nkey = nb._to_key()
					if nkey in biome_map:
						var nb_biome = biome_map[nkey]
						if nb_biome != worst_over and counts.get(nb_biome, 0) < target_per_biome:
							biome_map[bkey] = nb_biome
							reassigned = true
							break
				if reassigned:
					break
		
		if not reassigned:
			break  # No valid reassignment possible
	
	print("Distribution after rebalancing:")
	_print_biome_distribution(biome_map)
	
	# ==========================================================================
	# STEP 4: Cleanup — remove isolated tiles and fix forbidden adjacencies
	# An isolated tile has NO same-biome neighbors → reassign to majority neighbor
	# ==========================================================================
	for _pass in range(CLEANUP_PASSES):
		var changed: bool = false
		for coord in coordinates:
			var key: String = coord._to_key()
			var current: Biomes.Type = biome_map[key]
			var neighbors = _get_valid_neighbors(coord)
			
			# Count neighbor biomes
			var neighbor_counts: Dictionary = {}
			for nb in neighbors:
				var nkey = nb._to_key()
				if nkey in biome_map:
					var nb_biome = biome_map[nkey]
					neighbor_counts[nb_biome] = neighbor_counts.get(nb_biome, 0) + 1
			
			var same_count = neighbor_counts.get(current, 0)
			
			# If tile is isolated (0 same-biome neighbors) or nearly isolated (1)
			# reassign it to the most common neighbor biome
			if same_count <= 1 and neighbor_counts.size() > 0:
				var best_biome: Biomes.Type = current
				var best_count: int = 0
				for nb_biome in neighbor_counts:
					if neighbor_counts[nb_biome] > best_count:
						best_count = neighbor_counts[nb_biome]
						best_biome = nb_biome
				if best_biome != current:
					biome_map[key] = best_biome
					changed = true
		
		if not changed:
			break
	
	# ==========================================================================
	# STEP 5: Fix forbidden adjacency violations
	# If a tile borders a forbidden neighbor, try to change it to a compatible biome
	# ==========================================================================
	biome_map = _fix_forbidden_adjacencies(coordinates, biome_map)
	
	# DEBUG: Final distribution
	print("Final distribution after cleanup:")
	_print_biome_distribution(biome_map)
	
	# ==========================================================================
	# STEP 6: Adjust heights based on final biome assignments
	# ==========================================================================
	height_map = _adjust_heights_for_biomes(coordinates, biome_map, height_map)
	
	# STEP 7: Smooth height transitions between neighbors
	height_map = _smooth_heights(coordinates, height_map)
	
	# STEP 8: Enforce maximum height difference between adjacent tiles
	height_map = _enforce_max_height_difference(coordinates, height_map)
	
	# STEP 9: Apply final HEIGHT_SCALE
	for key in height_map:
		height_map[key] = height_map[key] * HEIGHT_SCALE
	
	return {
		"biomes": biome_map,
		"heights": height_map
	}


# =============================================================================
# SEED RELAXATION (Lloyd's algorithm — 1 pass)
# Moves each seed toward the centroid of its Voronoi cell
# Spreads seeds more evenly across the board
# =============================================================================

func _lloyd_relax_seeds(seeds: Array[Dictionary], all_positions: Array[Vector2]) -> Array[Dictionary]:
	# Assign each position to the nearest seed
	var cell_sums: Array[Vector2] = []
	var cell_counts: Array[int] = []
	cell_sums.resize(seeds.size())
	cell_counts.resize(seeds.size())
	for i in range(seeds.size()):
		cell_sums[i] = Vector2.ZERO
		cell_counts[i] = 0
	
	for pos in all_positions:
		var best_i: int = 0
		var best_d: float = INF
		for i in range(seeds.size()):
			var d = pos.distance_squared_to(seeds[i]["pos"])
			if d < best_d:
				best_d = d
				best_i = i
		cell_sums[best_i] += pos
		cell_counts[best_i] += 1
	
	# Move seeds toward centroid (blend 50% to avoid extreme movement)
	var relaxed: Array[Dictionary] = []
	for i in range(seeds.size()):
		var new_pos: Vector2
		if cell_counts[i] > 0:
			var centroid = cell_sums[i] / cell_counts[i]
			new_pos = seeds[i]["pos"].lerp(centroid, 0.5)
		else:
			new_pos = seeds[i]["pos"]
		relaxed.append({"pos": new_pos, "biome": seeds[i]["biome"]})
	
	return relaxed


# =============================================================================
# FORBIDDEN ADJACENCY FIX
# =============================================================================

func _fix_forbidden_adjacencies(coordinates: Array[HexCoordinates], biome_map: Dictionary) -> Dictionary:
	var result = biome_map.duplicate()
	
	for _pass in range(3):
		var changed: bool = false
		for coord in coordinates:
			var key: String = coord._to_key()
			var current: Biomes.Type = result[key]
			var neighbors = _get_valid_neighbors(coord)
			
			var has_violation: bool = false
			var neighbor_counts: Dictionary = {}
			
			for nb in neighbors:
				var nkey = nb._to_key()
				if nkey in result:
					var nb_biome = result[nkey]
					neighbor_counts[nb_biome] = neighbor_counts.get(nb_biome, 0) + 1
					if _is_forbidden_pair(current, nb_biome):
						has_violation = true
			
			if has_violation:
				# Find the most common neighbor biome that is NOT forbidden with any neighbor
				var best_biome: Biomes.Type = current
				var best_count: int = -1
				for candidate_biome in neighbor_counts:
					if neighbor_counts[candidate_biome] > best_count:
						# Check if this candidate would cause new violations
						var valid: bool = true
						for nb in neighbors:
							var nkey = nb._to_key()
							if nkey in result:
								if _is_forbidden_pair(candidate_biome, result[nkey]):
									valid = false
									break
						if valid:
							best_count = neighbor_counts[candidate_biome]
							best_biome = candidate_biome
				
				if best_biome != current:
					result[key] = best_biome
					changed = true
		
		if not changed:
			break
	
	return result


## Map master value to biome using pre-calculated percentile thresholds
## (Kept for compatibility — not used by the Voronoi approach)
func _master_value_to_biome(master_val: float, thresholds: Array[float]) -> Biomes.Type:
	if master_val < thresholds[0]:
		return Biomes.Type.SWAMP
	elif master_val < thresholds[1]:
		return Biomes.Type.PLAINS
	elif master_val < thresholds[2]:
		return Biomes.Type.FOREST
	elif master_val < thresholds[3]:
		return Biomes.Type.HILLS
	elif master_val < thresholds[4]:
		return Biomes.Type.WASTES
	elif master_val < thresholds[5]:
		return Biomes.Type.ASHLANDS
	else:
		return Biomes.Type.PEAKS


## Debug helper to print biome distribution
func _print_biome_distribution(biome_map: Dictionary) -> void:
	var counts: Dictionary = {}
	for key in biome_map:
		var biome = biome_map[key]
		counts[biome] = counts.get(biome, 0) + 1
	
	var total = biome_map.size()
	for biome in Biomes.Type.values():
		var count = counts.get(biome, 0)
		var pct = (count * 100.0) / total
		print("  %s: %d (%.1f%%)" % [Biomes.get_biome_name(biome), count, pct])


# =============================================================================
# NOISE SETUP
# =============================================================================

func _setup_noise() -> void:
	var base_seed = _rng.randi()
	
	# Distance warp noise — warps Voronoi cell boundaries for organic shapes
	_warp_noise = FastNoiseLite.new()
	_warp_noise.seed = base_seed + 7777
	_warp_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_warp_noise.frequency = DISTANCE_WARP_FREQ
	_warp_noise.fractal_octaves = 3
	_warp_noise.fractal_lacunarity = 2.0
	_warp_noise.fractal_gain = 0.5
	
	# Master noise for height variation
	_master_noise = FastNoiseLite.new()
	_master_noise.seed = base_seed
	_master_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_master_noise.frequency = 0.012
	_master_noise.fractal_octaves = 4
	_master_noise.fractal_lacunarity = 2.0
	_master_noise.fractal_gain = 0.5
	
	# Terrain detail noise for micro-variation within biomes
	_terrain_detail_noise = FastNoiseLite.new()
	_terrain_detail_noise.seed = base_seed + 3000
	_terrain_detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_terrain_detail_noise.frequency = 0.048
	_terrain_detail_noise.fractal_octaves = 2
	_terrain_detail_noise.fractal_lacunarity = 2.0
	_terrain_detail_noise.fractal_gain = 0.4


# =============================================================================
# HEIGHT ADJUSTMENT
# =============================================================================

## Adjust heights based on biome type
func _adjust_heights_for_biomes(coordinates: Array[HexCoordinates], biome_map: Dictionary, _height_map: Dictionary) -> Dictionary:
	var new_heights: Dictionary = {}
	
	var biome_height_ranges: Dictionary = {
		Biomes.Type.SWAMP: [0.0, 0.15],
		Biomes.Type.PLAINS: [0.1, 0.3],
		Biomes.Type.FOREST: [0.2, 0.45],
		Biomes.Type.WASTES: [0.15, 0.4],
		Biomes.Type.ASHLANDS: [0.3, 0.65],
		Biomes.Type.HILLS: [0.4, 0.75],
		Biomes.Type.PEAKS: [0.6, 0.9],
	}
	
	for coord in coordinates:
		var key: String = coord._to_key()
		var biome: Biomes.Type = biome_map.get(key, Biomes.Type.PLAINS)
		
		var height_range: Array = biome_height_ranges.get(biome, [0.1, 0.25])
		var base_height: float = height_range[0]
		var max_height: float = height_range[1]
		
		var pixel = coord.to_pixel(1.0)
		var elevation_factor = (_master_noise.get_noise_2d(pixel.x, pixel.y) + 1.0) * 0.5
		var detail_noise = (_terrain_detail_noise.get_noise_2d(pixel.x, pixel.y) + 1.0) * 0.5
		var height_variation = elevation_factor * 0.7 + detail_noise * 0.3
		var final_height = base_height + (max_height - base_height) * height_variation
		
		new_heights[key] = final_height
	
	# Ensure peaks are always higher than adjacent non-peak tiles
	for coord in coordinates:
		var key: String = coord._to_key()
		var biome: Biomes.Type = biome_map.get(key, Biomes.Type.PLAINS)
		
		if biome == Biomes.Type.PEAKS:
			var max_neighbor_height: float = 0.0
			for neighbor in _get_valid_neighbors(coord):
				var nkey: String = neighbor._to_key()
				if nkey in new_heights and biome_map.get(nkey, Biomes.Type.PLAINS) != Biomes.Type.PEAKS:
					max_neighbor_height = max(max_neighbor_height, new_heights[nkey])
			
			if new_heights[key] <= max_neighbor_height:
				new_heights[key] = max_neighbor_height + 0.12
	
	return new_heights


# =============================================================================
# TERRAIN SMOOTHING AND ISLAND FALLOFF
# =============================================================================

func _calculate_board_radius(coordinates: Array[HexCoordinates]) -> float:
	var max_dist: float = 0.0
	for coord in coordinates:
		var dist = sqrt(pow(coord.q, 2) + pow(coord.r, 2) + coord.q * coord.r)
		max_dist = max(max_dist, dist)
	return max_dist


func _apply_island_falloff(coord: HexCoordinates, height: float) -> float:
	var distance_from_center = sqrt(pow(coord.q, 2) + pow(coord.r, 2) + coord.q * coord.r)
	var normalized_distance = distance_from_center / _board_radius if _board_radius > 0 else 0.0
	var falloff = 1.0 - pow(normalized_distance, 2.5)
	falloff = clampf(falloff, 0.0, 1.0)
	return height * (0.3 + falloff * 0.7)


func _smooth_heights(coordinates: Array[HexCoordinates], height_map: Dictionary) -> Dictionary:
	var new_heights: Dictionary = height_map.duplicate()
	
	for _pass in range(SMOOTHING_PASSES):
		var pass_heights: Dictionary = new_heights.duplicate()
		
		for coord in coordinates:
			var key: String = coord._to_key()
			var current_height: float = new_heights.get(key, 0.0)
			var neighbor_sum: float = 0.0
			var neighbor_count: int = 0
			
			for neighbor in _get_valid_neighbors(coord):
				var nkey: String = neighbor._to_key()
				if nkey in new_heights:
					neighbor_sum += new_heights[nkey]
					neighbor_count += 1
			
			if neighbor_count > 0:
				var neighbor_avg: float = neighbor_sum / neighbor_count
				pass_heights[key] = current_height * 0.4 + neighbor_avg * 0.6
		
		new_heights = pass_heights
	
	return new_heights


func _enforce_max_height_difference(coordinates: Array[HexCoordinates], height_map: Dictionary) -> Dictionary:
	var new_heights: Dictionary = height_map.duplicate()
	var max_iterations: int = 10
	
	for _iteration in range(max_iterations):
		var changed: bool = false
		
		for coord in coordinates:
			var key: String = coord._to_key()
			var current_height: float = new_heights.get(key, 0.0)
			
			for neighbor in _get_valid_neighbors(coord):
				var nkey: String = neighbor._to_key()
				if nkey not in new_heights:
					continue
				
				var neighbor_height: float = new_heights[nkey]
				var diff: float = abs(current_height - neighbor_height)
				
				if diff > MAX_HEIGHT_DIFFERENCE:
					var avg: float = (current_height + neighbor_height) / 2.0
					var target_diff: float = MAX_HEIGHT_DIFFERENCE * 0.9
					
					if current_height > neighbor_height:
						new_heights[key] = avg + target_diff / 2.0
						new_heights[nkey] = avg - target_diff / 2.0
					else:
						new_heights[key] = avg - target_diff / 2.0
						new_heights[nkey] = avg + target_diff / 2.0
					changed = true
		
		if not changed:
			break
	
	return new_heights


# =============================================================================
# ADJACENCY MATRIX
# =============================================================================

func _build_adjacency_matrix() -> void:
	_valid_adjacencies.clear()
	
	var all_biomes: Array = Biomes.Type.values()
	for biome_a in all_biomes:
		_valid_adjacencies[biome_a] = []
		for biome_b in all_biomes:
			if biome_a != biome_b:
				_valid_adjacencies[biome_a].append(biome_b)
	
	for pair in FORBIDDEN_PAIRS:
		var biome_a: Biomes.Type = pair[0]
		var biome_b: Biomes.Type = pair[1]
		
		if biome_b in _valid_adjacencies[biome_a]:
			_valid_adjacencies[biome_a].erase(biome_b)
		if biome_a in _valid_adjacencies[biome_b]:
			_valid_adjacencies[biome_b].erase(biome_a)


func _can_be_adjacent(biome_a: Biomes.Type, biome_b: Biomes.Type) -> bool:
	if biome_a == biome_b:
		return true
	if biome_a == Biomes.Type.HILLS or biome_b == Biomes.Type.HILLS:
		return true
	return biome_b in _valid_adjacencies.get(biome_a, [])


func _is_forbidden_pair(biome_a: Biomes.Type, biome_b: Biomes.Type) -> bool:
	for pair in FORBIDDEN_PAIRS:
		if (pair[0] == biome_a and pair[1] == biome_b) or \
		   (pair[0] == biome_b and pair[1] == biome_a):
			return true
	return false


# =============================================================================
# COORDINATE UTILITIES
# =============================================================================

func _build_coord_lookup(coordinates: Array[HexCoordinates]) -> void:
	_coord_lookup.clear()
	for coord in coordinates:
		_coord_lookup[coord._to_key()] = coord


func _get_valid_neighbors(coord: HexCoordinates) -> Array[HexCoordinates]:
	var result: Array[HexCoordinates] = []
	for neighbor in coord.get_all_neighbors():
		if neighbor._to_key() in _coord_lookup:
			result.append(neighbor)
	return result


## Fisher-Yates shuffle for arrays
func _shuffle_array(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j = _rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


# =============================================================================
# DEBUG UTILITIES
# =============================================================================

func print_distribution(biome_map: Dictionary) -> void:
	var counts: Dictionary = _count_biomes(biome_map)
	
	print("=== Biome Distribution (Target: ~%d ±%d, ~14%% each) ===" % [BASE_TILES_PER_BIOME, TILE_VARIANCE])
	var total: int = biome_map.size()
	for biome in Biomes.Type.values():
		var count: int = counts.get(biome, 0)
		var pct: float = 100.0 * count / total if total > 0 else 0.0
		var diff: int = abs(count - BASE_TILES_PER_BIOME)
		var status: String = "✓" if diff <= TILE_VARIANCE else "!"
		print("  %s %s: %d tiles (%.1f%%)" % [status, Biomes.get_biome_name(biome), count, pct])


func print_adjacency_violations(coordinates: Array[HexCoordinates], biome_map: Dictionary) -> void:
	_build_coord_lookup(coordinates)
	_build_adjacency_matrix()
	
	var violations: int = 0
	var violation_pairs: Dictionary = {}
	
	for coord in coordinates:
		var key: String = coord._to_key()
		var current: Biomes.Type = biome_map.get(key, Biomes.Type.PLAINS)
		
		for neighbor in _get_valid_neighbors(coord):
			var nkey: String = neighbor._to_key()
			if nkey in biome_map:
				var nb: Biomes.Type = biome_map[nkey]
				if not _can_be_adjacent(current, nb):
					violations += 1
					var pair_key: String = str(mini(current, nb)) + "_" + str(maxi(current, nb))
					violation_pairs[pair_key] = violation_pairs.get(pair_key, 0) + 1
	
	@warning_ignore("integer_division")
	print("=== Adjacency Violations: %d ===" % [violations / 2])
	if violations > 0:
		print("  Forbidden pairs found:")
		for pair_key in violation_pairs:
			@warning_ignore("integer_division")
			print("    %s: %d borders" % [pair_key, violation_pairs[pair_key] / 2])
	else:
		print("  ✓ All biome borders are valid!")


func get_statistics(coordinates: Array[HexCoordinates], biome_map: Dictionary) -> Dictionary:
	_build_coord_lookup(coordinates)
	_build_adjacency_matrix()
	
	var stats: Dictionary = {
		"total_tiles": biome_map.size(),
		"biome_counts": _count_biomes(biome_map),
		"adjacency_violations": 0,
		"isolated_tiles": 0
	}
	
	for coord in coordinates:
		var key: String = coord._to_key()
		var current: Biomes.Type = biome_map.get(key, Biomes.Type.PLAINS)
		var neighbors: Array[HexCoordinates] = _get_valid_neighbors(coord)
		
		var same_count: int = 0
		for neighbor in neighbors:
			var nkey: String = neighbor._to_key()
			if nkey in biome_map:
				var nb: Biomes.Type = biome_map[nkey]
				if not _can_be_adjacent(current, nb):
					stats["adjacency_violations"] += 1
				if nb == current:
					same_count += 1
		
		if same_count == 0:
			stats["isolated_tiles"] += 1
	
	@warning_ignore("integer_division")
	stats["adjacency_violations"] /= 2
	
	return stats


func _count_biomes(biome_map: Dictionary) -> Dictionary:
	var counts: Dictionary = {}
	for biome in Biomes.Type.values():
		counts[biome] = 0
	for key in biome_map:
		counts[biome_map[key]] = counts.get(biome_map[key], 0) + 1
	return counts
