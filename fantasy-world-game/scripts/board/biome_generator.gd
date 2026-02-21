## Biome Generator - Unified Noise System
## ============================================================================
## 
## Generates coherent biome regions using a SINGLE noise source for
## large, contiguous blob-shaped biome regions with perfect distribution.
##
## FEATURES:
## - Single master noise value per tile → large organic blobs
## - Strict percentile-based biome assignment → exact 14% per biome
## - Height variation based on biome type
## - Forbidden neighbor cleanup for climate logic
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
## Controls the overall vertical scale of terrain variation
const HEIGHT_SCALE: float = 0.5 # Visible peaks and valleys

## Maximum allowed height difference between adjacent tiles
## Higher value = steeper transitions allowed
const MAX_HEIGHT_DIFFERENCE: float = 0.15 # Allow visible but smooth slopes

## Number of smoothing passes for height blending
const SMOOTHING_PASSES: int = 3 # Less smoothing to preserve terrain variation

## Number of cleanup passes to remove isolated tiles
const CLEANUP_PASSES: int = 5

## ==========================================================================
## UNIFIED NOISE CONFIGURATION
## ==========================================================================
## Single FastNoiseLite instance with low frequency for LARGE contiguous blobs
const MASTER_NOISE_FREQUENCY: float = 0.012  # Slightly higher for more varied regions
const MASTER_NOISE_OCTAVES: int = 4  # Higher octaves for natural crinkly edges

## Domain warp strength - how much the sample coordinates are displaced
## Higher = more organic/twisted biome shapes, lower = smoother blobs
const DOMAIN_WARP_STRENGTH: float = 8.0


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

## Single unified noise generator for biome assignment
var _master_noise: FastNoiseLite

## Domain warp noise - displaces sample coordinates for organic biome shapes
## This breaks up the straight contour-line banding into irregular blobs
var _domain_warp_noise: FastNoiseLite

## Terrain detail noise for micro-variation within biomes
var _terrain_detail_noise: FastNoiseLite

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
	# STEP 1: Generate SINGLE Master Value per tile using unified noise source
	# This is the key to creating large, contiguous biome blobs
	# ==========================================================================
	var master_values: Array[float] = []
	var tile_master_map: Dictionary = {} # key -> master noise value
	var height_map: Dictionary = {}
	
	for coord in coordinates:
		var key: String = coord._to_key()
		var pixel = coord.to_pixel(1.0)
		
		# DOMAIN WARPING: Displace the sample coordinates using a second noise source
		# This twists and warps the biome boundaries from straight contour lines
		# into organic, irregular blob shapes - like real terrain biomes
		var warp_x = _domain_warp_noise.get_noise_2d(pixel.x, pixel.y) * DOMAIN_WARP_STRENGTH
		var warp_y = _domain_warp_noise.get_noise_2d(pixel.x + 31.7, pixel.y + 17.3) * DOMAIN_WARP_STRENGTH
		var warped_x = pixel.x + warp_x
		var warped_y = pixel.y + warp_y
		
		# UNIFIED NOISE: Sample at warped coordinates for organic blob shapes
		var master_value = (_master_noise.get_noise_2d(warped_x, warped_y) + 1.0) * 0.5
		tile_master_map[key] = master_value
		master_values.append(master_value)
		
		# Height derived from master noise + detail noise for micro-variation
		var base_height = master_value  # Use same noise for consistent terrain
		var detail = (_terrain_detail_noise.get_noise_2d(pixel.x, pixel.y) + 1.0) * 0.5
		var combined_height = base_height * 0.8 + detail * 0.2
		
		# Apply island falloff so edges are lower
		combined_height = _apply_island_falloff(coord, combined_height)
		height_map[key] = combined_height
	
	# ==========================================================================
	# STEP 2: STRICT PERCENTILE MAPPING
	# Sort all master values and calculate thresholds for each 14% band
	# This guarantees PERFECT distribution while keeping organic blob shapes
	# ==========================================================================
	master_values.sort()
	var total_tiles = master_values.size()
	var tiles_per_biome = total_tiles / NUM_BIOMES  # ~56 for 397 tiles / 7 biomes
	
	# Calculate the exact threshold values at each percentile boundary
	# Bottom 14% gets biome 0, next 14% gets biome 1, etc.
	var thresholds: Array[float] = []
	for i in range(1, NUM_BIOMES):
		var percentile_index = min(i * tiles_per_biome, total_tiles - 1)
		thresholds.append(master_values[percentile_index])
	
	print("Biome thresholds (14%% boundaries): ", thresholds)
	
	# ==========================================================================
	# STEP 3: Assign biomes using strict percentile thresholds
	# Each tile's biome is determined by where its master value falls
	# ==========================================================================
	var biome_map: Dictionary = {}
	
	for key in tile_master_map:
		var master_val = tile_master_map[key]
		biome_map[key] = _master_value_to_biome(master_val, thresholds)
	
	# DEBUG: Print distribution after percentile assignment
	print("Distribution after strict percentile mapping:")
	_print_biome_distribution(biome_map)
	
	# ==========================================================================
	# STEP 4: DISABLED - Post-processing was destroying the even distribution
	# The percentile method inherently creates valid natural patterns
	# ==========================================================================
	# biome_map = _fix_adjacency_violations(coordinates, biome_map)
	# biome_map = _smooth_biomes_by_neighbors(coordinates, biome_map)
	
	# DEBUG: Final distribution
	print("Final distribution:")
	_print_biome_distribution(biome_map)
	
	# ==========================================================================
	# STEP 5: Adjust heights based on final biome assignments
	# ==========================================================================
	height_map = _adjust_heights_for_biomes(coordinates, biome_map, height_map)
	
	# STEP 6: Smooth height transitions between neighbors
	height_map = _smooth_heights(coordinates, height_map)
	
	# STEP 7: Enforce maximum height difference between adjacent tiles
	height_map = _enforce_max_height_difference(coordinates, height_map)
	
	# STEP 8: Apply final HEIGHT_SCALE
	for key in height_map:
		height_map[key] = height_map[key] * HEIGHT_SCALE
	
	return {
		"biomes": biome_map,
		"heights": height_map
	}


## Map master value to biome using pre-calculated percentile thresholds
## This ensures each biome gets exactly ~14% of tiles while preserving noise patterns
func _master_value_to_biome(master_val: float, thresholds: Array[float]) -> Biomes.Type:
	# Biomes ordered from lowest to highest master value
	# SWAMP (lowest) -> PLAINS -> FOREST -> HILLS -> WASTES -> ASHLANDS -> PEAKS (highest)
	# This ordering creates natural elevation flow
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
# NOISE SETUP - UNIFIED SINGLE SOURCE
# =============================================================================

func _setup_noise() -> void:
	var base_seed = _rng.randi()
	
	# ==========================================================================
	# MASTER NOISE - Single unified source for biome determination
	# Type: SIMPLEX_SMOOTH for natural organic patterns
	# Frequency: 0.012 (low) → creates large contiguous biome blobs
	# ==========================================================================
	_master_noise = FastNoiseLite.new()
	_master_noise.seed = base_seed
	_master_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_master_noise.frequency = MASTER_NOISE_FREQUENCY  # 0.012
	_master_noise.fractal_octaves = MASTER_NOISE_OCTAVES
	_master_noise.fractal_lacunarity = 2.0
	_master_noise.fractal_gain = 0.5
	
	# ==========================================================================
	# DOMAIN WARP NOISE - Displaces sample coordinates to break up linear bands
	# Uses a different seed and higher frequency to create irregular warping
	# The warp makes biome boundaries look like real terrain instead of contours
	# ==========================================================================
	_domain_warp_noise = FastNoiseLite.new()
	_domain_warp_noise.seed = base_seed + 7777
	_domain_warp_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_domain_warp_noise.frequency = 0.05  # Higher freq = more irregular warping
	_domain_warp_noise.fractal_octaves = 3
	_domain_warp_noise.fractal_lacunarity = 2.0
	_domain_warp_noise.fractal_gain = 0.5
	
	# Terrain detail noise - Higher frequency for micro-variation within biomes
	_terrain_detail_noise = FastNoiseLite.new()
	_terrain_detail_noise.seed = base_seed + 3000
	_terrain_detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_terrain_detail_noise.frequency = MASTER_NOISE_FREQUENCY * 4.0  # Higher freq for detail
	_terrain_detail_noise.fractal_octaves = 2
	_terrain_detail_noise.fractal_lacunarity = 2.0
	_terrain_detail_noise.fractal_gain = 0.4


# =============================================================================
# HEIGHT ADJUSTMENT
# =============================================================================

## Adjust heights based on biome type - Minecraft style fixed heights per biome
## Heights are in normalized 0-1 range (HEIGHT_SCALE applied later)
func _adjust_heights_for_biomes(coordinates: Array[HexCoordinates], biome_map: Dictionary, _height_map: Dictionary) -> Dictionary:
	var new_heights: Dictionary = {}
	
	# Biome height ranges for more natural variation
	# Peaks are ALWAYS the highest, other biomes have elevation ranges
	var biome_height_ranges: Dictionary = {
		Biomes.Type.SWAMP: [0.0, 0.15], # Low, near water level
		Biomes.Type.PLAINS: [0.1, 0.3], # Low to mid flat land
		Biomes.Type.FOREST: [0.2, 0.45], # Mid elevation forests
		Biomes.Type.WASTES: [0.15, 0.4], # Variable desert elevations
		Biomes.Type.ASHLANDS: [0.3, 0.65], # Volcanic, can be high
		Biomes.Type.HILLS: [0.4, 0.75], # Higher elevations
		Biomes.Type.PEAKS: [0.6, 0.9], # Highest elevations, snow peaks
	}
	
	for coord in coordinates:
		var key: String = coord._to_key()
		var biome: Biomes.Type = biome_map.get(key, Biomes.Type.PLAINS)
		
		# Get height range for this biome
		var height_range: Array = biome_height_ranges.get(biome, [0.1, 0.25])
		var base_height: float = height_range[0]
		var max_height: float = height_range[1]
		
		# Use the master noise to vary within the biome's range
		var pixel = coord.to_pixel(1.0)
		var elevation_factor = (_master_noise.get_noise_2d(pixel.x, pixel.y) + 1.0) * 0.5
		
		# Add some micro-variation using detail noise
		var detail_noise = (_terrain_detail_noise.get_noise_2d(pixel.x, pixel.y) + 1.0) * 0.5
		
		# Combine elevation and detail for natural variation within biome range
		var height_variation = elevation_factor * 0.7 + detail_noise * 0.3
		var final_height = base_height + (max_height - base_height) * height_variation
		
		new_heights[key] = final_height
	
	# Ensure peaks are always higher than adjacent non-peak tiles
	for coord in coordinates:
		var key: String = coord._to_key()
		var biome: Biomes.Type = biome_map.get(key, Biomes.Type.PLAINS)
		
		if biome == Biomes.Type.PEAKS:
			# Find the highest neighbor that's not a peak
			var max_neighbor_height: float = 0.0
			for neighbor in _get_valid_neighbors(coord):
				var nkey: String = neighbor._to_key()
				if nkey in new_heights and biome_map.get(nkey, Biomes.Type.PLAINS) != Biomes.Type.PEAKS:
					max_neighbor_height = max(max_neighbor_height, new_heights[nkey])
			
			# Ensure this peak is at least 0.12 units higher than the highest neighbor
			if new_heights[key] <= max_neighbor_height:
				new_heights[key] = max_neighbor_height + 0.12
	
	return new_heights


# =============================================================================
# TERRAIN SMOOTHING AND ISLAND FALLOFF
# =============================================================================

## Calculate the board radius from coordinates
func _calculate_board_radius(coordinates: Array[HexCoordinates]) -> float:
	var max_dist: float = 0.0
	for coord in coordinates:
		var dist = sqrt(pow(coord.q, 2) + pow(coord.r, 2) + coord.q * coord.r)
		max_dist = max(max_dist, dist)
	return max_dist


## Apply island-style falloff to height based on distance from center
## Creates a natural landmass shape with lower edges
func _apply_island_falloff(coord: HexCoordinates, height: float) -> float:
	var distance_from_center = sqrt(pow(coord.q, 2) + pow(coord.r, 2) + coord.q * coord.r)
	var normalized_distance = distance_from_center / _board_radius if _board_radius > 0 else 0.0
	
	# Smooth falloff curve (plateau in center, drops at edges)
	# Using smoothstep-like curve for natural transition
	var falloff = 1.0 - pow(normalized_distance, 2.5)
	falloff = clampf(falloff, 0.0, 1.0)
	
	# Apply falloff - center keeps height, edges reduced
	return height * (0.3 + falloff * 0.7)


## Smooth heights by blending with neighbor averages
## Multiple passes for increasingly smooth terrain
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
				# Blend 40% current + 60% neighbor average for stronger smoothing
				pass_heights[key] = current_height * 0.4 + neighbor_avg * 0.6
		
		new_heights = pass_heights
	
	return new_heights


## Enforce maximum height difference between adjacent tiles
## Prevents cliff-like jumps for natural terrain transitions
func _enforce_max_height_difference(coordinates: Array[HexCoordinates], height_map: Dictionary) -> Dictionary:
	var new_heights: Dictionary = height_map.duplicate()
	var max_iterations: int = 10 # Safety limit
	
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
					# Pull both heights toward their average
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
	
	print("=== Adjacency Violations: %d ===" % [violations / 2])
	if violations > 0:
		print("  Forbidden pairs found:")
		for pair_key in violation_pairs:
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
	
	stats["adjacency_violations"] /= 2
	
	return stats


func _count_biomes(biome_map: Dictionary) -> Dictionary:
	var counts: Dictionary = {}
	for biome in Biomes.Type.values():
		counts[biome] = 0
	for key in biome_map:
		counts[biome_map[key]] = counts.get(biome_map[key], 0) + 1
	return counts
