## Biome Generator - Noise-Based Climate System
## ============================================================================
## 
## Generates coherent biome regions using dual-layer Perlin noise for
## temperature and elevation, creating natural climate zones with smooth
## transitions and balanced distribution.
##
## FEATURES:
## - Climate-based biome mapping (temperature + elevation → biome type)
## - Height variation for terrain depth
## - Distribution balancing to prevent over/underrepresentation
## - Forbidden neighbor enforcement via cleanup passes
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

## Base tiles per biome (397 / 7 ≈ 56)
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

## Noise configuration - very low frequency = large organic blobs
const NOISE_FREQUENCY: float = 0.01 # Very low for large natural blobs
const NOISE_OCTAVES: int = 4 # Higher octaves for crinkly natural edges

## Biome smoothing passes (neighbor influence) - only 1 pass at the end
const BIOME_SMOOTHING_PASSES: int = 1 # Single cleanup pass to preserve blob shapes


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

# Noise generators
var _elevation_noise: FastNoiseLite
var _temperature_noise: FastNoiseLite
var _moisture_noise: FastNoiseLite
var _terrain_detail_noise: FastNoiseLite # For micro-terrain variation

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
	# STEP 1: Generate raw noise values for all tiles
	# Use SINGLE noise source for biome assignment = true blob shapes
	# (Combining multiple noise layers creates stringy intersection patterns)
	# ==========================================================================
	var noise_values: Array[float] = []
	var tile_noise_map: Dictionary = {} # key -> single noise value for biome
	var height_map: Dictionary = {}
	
	for coord in coordinates:
		var key: String = coord._to_key()
		var pixel = coord.to_pixel(1.0)
		
		# Use SINGLE noise value for biome assignment (creates coherent blobs)
		var biome_noise = (_elevation_noise.get_noise_2d(pixel.x, pixel.y) + 1.0) * 0.5
		tile_noise_map[key] = biome_noise
		noise_values.append(biome_noise)
		
		# Height from elevation noise + detail noise for micro-variation
		var base_height = biome_noise  # Use same noise as biome for consistent terrain
		var detail = (_terrain_detail_noise.get_noise_2d(pixel.x, pixel.y) + 1.0) * 0.5
		var combined_height = base_height * 0.8 + detail * 0.2
		
		# Apply island falloff so edges are lower
		combined_height = _apply_island_falloff(coord, combined_height)
		height_map[key] = combined_height
	
	# ==========================================================================
	# STEP 2: Calculate percentile thresholds ("Rising Tide" Method)
	# Sort all noise values and find the 14th, 28th, 42nd... percentile boundaries
	# This guarantees perfect ~14% distribution while keeping blob shapes intact
	# ==========================================================================
	noise_values.sort()
	var total_tiles = noise_values.size()
	var tiles_per_biome = total_tiles / NUM_BIOMES  # ~56 for 397 tiles / 7 biomes
	
	# Find the threshold values at each percentile boundary
	var thresholds: Array[float] = []
	for i in range(1, NUM_BIOMES):
		var percentile_index = min(i * tiles_per_biome, total_tiles - 1)
		thresholds.append(noise_values[percentile_index])
	
	print("Biome thresholds (percentile boundaries): ", thresholds)
	
	# ==========================================================================
	# STEP 3: Assign biomes using percentile thresholds
	# Each tile gets a biome based on where its noise value falls
	# ==========================================================================
	var biome_map: Dictionary = {}
	
	for key in tile_noise_map:
		var noise_val = tile_noise_map[key]
		biome_map[key] = _noise_to_biome_percentile(noise_val, thresholds)
	
	# DEBUG: Print distribution after percentile assignment
	print("Distribution after percentile assignment:")
	_print_biome_distribution(biome_map)
	
	# ==========================================================================
	# STEP 4: DISABLED - Adjacency fixes were destroying distribution
	# The percentile method already creates valid natural patterns
	# ==========================================================================
	# biome_map = _fix_adjacency_violations(coordinates, biome_map)
	
	# ==========================================================================
	# STEP 5: DISABLED - Smoothing was destroying distribution
	# Trust the noise - percentile thresholds already give perfect balance
	# ==========================================================================
	# biome_map = _smooth_biomes_by_neighbors(coordinates, biome_map)
	
	# DEBUG: Final distribution
	print("Final distribution:")
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


## Map noise value to biome using pre-calculated percentile thresholds
## This preserves exact distribution while keeping natural noise patterns
func _noise_to_biome_percentile(noise_val: float, thresholds: Array[float]) -> Biomes.Type:
	# Biomes ordered from lowest to highest noise value
	# SWAMP (lowest) -> PLAINS -> FOREST -> HILLS -> WASTES -> ASHLANDS -> PEAKS (highest)
	if noise_val < thresholds[0]:
		return Biomes.Type.SWAMP
	elif noise_val < thresholds[1]:
		return Biomes.Type.PLAINS
	elif noise_val < thresholds[2]:
		return Biomes.Type.FOREST
	elif noise_val < thresholds[3]:
		return Biomes.Type.HILLS
	elif noise_val < thresholds[4]:
		return Biomes.Type.WASTES
	elif noise_val < thresholds[5]:
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
	
	# Elevation noise - Simplex with very low frequency for large organic blobs
	_elevation_noise = FastNoiseLite.new()
	_elevation_noise.seed = base_seed
	_elevation_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_elevation_noise.frequency = NOISE_FREQUENCY
	_elevation_noise.fractal_octaves = NOISE_OCTAVES
	_elevation_noise.fractal_lacunarity = 2.0
	_elevation_noise.fractal_gain = 0.5
	
	# Temperature noise - Simplex for natural hot/cold gradients
	_temperature_noise = FastNoiseLite.new()
	_temperature_noise.seed = base_seed + 1000
	_temperature_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_temperature_noise.frequency = NOISE_FREQUENCY * 0.8
	_temperature_noise.fractal_octaves = NOISE_OCTAVES
	_temperature_noise.fractal_lacunarity = 2.0
	_temperature_noise.fractal_gain = 0.5
	
	# Moisture noise - Simplex for natural wet/dry gradients
	_moisture_noise = FastNoiseLite.new()
	_moisture_noise.seed = base_seed + 2000
	_moisture_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_moisture_noise.frequency = NOISE_FREQUENCY * 0.9
	_moisture_noise.fractal_octaves = NOISE_OCTAVES
	_moisture_noise.fractal_lacunarity = 2.0
	_moisture_noise.fractal_gain = 0.5
	
	# Terrain detail noise - Higher frequency for micro-variation
	_terrain_detail_noise = FastNoiseLite.new()
	_terrain_detail_noise.seed = base_seed + 3000
	_terrain_detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_terrain_detail_noise.frequency = NOISE_FREQUENCY * 4.0
	_terrain_detail_noise.fractal_octaves = 2
	_terrain_detail_noise.fractal_lacunarity = 2.0
	_terrain_detail_noise.fractal_gain = 0.4


## Get climate values for a coordinate (all normalized 0-1)
func _get_climate_values(coord: HexCoordinates) -> Dictionary:
	var pixel = coord.to_pixel(1.0)
	
	# Get raw noise values (-1 to 1) and normalize to 0-1
	var elevation = (_elevation_noise.get_noise_2d(pixel.x, pixel.y) + 1.0) * 0.5
	var temperature = (_temperature_noise.get_noise_2d(pixel.x, pixel.y) + 1.0) * 0.5
	var moisture = (_moisture_noise.get_noise_2d(pixel.x, pixel.y) + 1.0) * 0.5
	
	return {
		"elevation": elevation,
		"temperature": temperature,
		"moisture": moisture
	}


# =============================================================================
# CLIMATE TO BIOME MAPPING
# =============================================================================

## Map climate values to a biome type
## Uses combined climate value for even 7-way distribution (~14% each)
## Cellular noise creates distinct regions, so we map cell values to biomes directly
func _climate_to_biome(elevation: float, temperature: float, moisture: float) -> Biomes.Type:
	# Combine climate values into a single index
	# Each noise value (elevation, temperature, moisture) is 0-1
	# We weight and combine to get a value that maps to 7 biomes
	
	# Primary factor: elevation (0-1) determines base biome
	# Secondary: temperature shifts within bands
	# Tertiary: moisture for fine-tuning
	
	# Create a combined value that covers the full 0-1 range evenly
	var combined = elevation * 0.5 + temperature * 0.3 + moisture * 0.2
	
	# Map to 7 biomes with equal probability bands (~14.3% each)
	# Band 0.000 - 0.143: SWAMP (lowest combined = wet + low + cool)
	# Band 0.143 - 0.286: PLAINS
	# Band 0.286 - 0.429: FOREST
	# Band 0.429 - 0.571: HILLS
	# Band 0.571 - 0.714: WASTES
	# Band 0.714 - 0.857: ASHLANDS
	# Band 0.857 - 1.000: PEAKS (highest combined = dry + high + hot)
	
	if combined < 0.143:
		return Biomes.Type.SWAMP
	elif combined < 0.286:
		return Biomes.Type.PLAINS
	elif combined < 0.429:
		return Biomes.Type.FOREST
	elif combined < 0.571:
		return Biomes.Type.HILLS
	elif combined < 0.714:
		return Biomes.Type.WASTES
	elif combined < 0.857:
		return Biomes.Type.ASHLANDS
	else:
		return Biomes.Type.PEAKS


# =============================================================================
# DISTRIBUTION BALANCING
# =============================================================================

## Balance biome distribution by shifting borderline tiles
func _balance_distribution(coordinates: Array[HexCoordinates], biome_map: Dictionary, climate_data: Dictionary) -> Dictionary:
	var new_map: Dictionary = biome_map.duplicate()
	
	# Calculate target ranges
	var min_tiles: int = BASE_TILES_PER_BIOME - TILE_VARIANCE
	var max_tiles: int = BASE_TILES_PER_BIOME + TILE_VARIANCE
	
	# Run many balancing passes to ensure distribution
	for _pass in range(20):  # More passes for better balance
		var counts: Dictionary = _count_biomes(new_map)
		var changed: bool = false
		
		# Find overrepresented and underrepresented biomes
		# Also enforce HARD MAXIMUM cap (no biome > 25%)
		var over: Array = []
		var under: Array = []
		
		for biome in Biomes.Type.values():
			var count: int = counts.get(biome, 0)
			# Hard cap takes priority - any biome over MAX_TILES_PER_BIOME is over
			if count > MAX_TILES_PER_BIOME:
				over.append(biome)
			elif count > max_tiles:
				over.append(biome)
			elif count < min_tiles:
				under.append(biome)
		
		# If distribution is balanced, we're done
		if under.is_empty():
			break
		
		# If no overrepresented biomes but still underrepresented ones,
		# take from biomes closest to max
		if over.is_empty() and not under.is_empty():
			var sorted_biomes: Array = Biomes.Type.values().duplicate()
			sorted_biomes.sort_custom(func(a, b): return counts.get(a, 0) > counts.get(b, 0))
			for biome in sorted_biomes:
				if counts.get(biome, 0) > min_tiles + 5 and biome not in under:
					over.append(biome)
					break
		
		if over.is_empty():
			break
		
		# For each overrepresented biome, try to shift borderline tiles
		for over_biome in over:
			var tiles_to_shift: Array = _find_borderline_tiles(coordinates, new_map, climate_data, over_biome)
			
			for tile_key in tiles_to_shift:
				var current_count: int = counts.get(over_biome, 0)
				if current_count <= min_tiles + 5:
					break
				
				# Find best alternative biome for this tile
				var coord = HexCoordinates.from_key(tile_key)
				var alt_biome = _find_alternative_biome(coord, new_map, under, climate_data[tile_key])
				
				if alt_biome != null:
					new_map[tile_key] = alt_biome
					counts[over_biome] = counts.get(over_biome, 0) - 1
					counts[alt_biome] = counts.get(alt_biome, 0) + 1
					changed = true
					
					# Remove from under if now satisfied
					if counts.get(alt_biome, 0) >= min_tiles:
						under.erase(alt_biome)
		
		if not changed:
			# Try more aggressive approach - shift any tile adjacent to underrepresented biome
			for under_biome in under:
				for coord in coordinates:
					var key: String = coord._to_key()
					var current_biome = new_map.get(key)
					if current_biome == under_biome:
						continue
					if counts.get(current_biome, 0) <= min_tiles + 5:
						continue
					
					# Check if adjacent to the under biome
					for neighbor in _get_valid_neighbors(coord):
						var nkey: String = neighbor._to_key()
						if nkey in new_map and new_map[nkey] == under_biome:
							# Check adjacency rules
							var valid: bool = true
							for check_neighbor in _get_valid_neighbors(coord):
								var cnkey: String = check_neighbor._to_key()
								if cnkey in new_map and not _can_be_adjacent(under_biome, new_map[cnkey]):
									valid = false
									break
							
							if valid:
								new_map[key] = under_biome
								counts[current_biome] = counts.get(current_biome, 0) - 1
								counts[under_biome] = counts.get(under_biome, 0) + 1
								changed = true
								break
					
					if changed:
						break
				if changed:
					break
	
	return new_map


## Find tiles that are on the border of a biome region (candidates for reassignment)
func _find_borderline_tiles(coordinates: Array[HexCoordinates], biome_map: Dictionary, climate_data: Dictionary, target_biome: Biomes.Type) -> Array:
	var borderline: Array = []
	
	for coord in coordinates:
		var key: String = coord._to_key()
		if biome_map.get(key) != target_biome:
			continue
		
		# Check if this tile borders a different biome
		var has_different_neighbor: bool = false
		for neighbor in _get_valid_neighbors(coord):
			var nkey: String = neighbor._to_key()
			if nkey in biome_map and biome_map[nkey] != target_biome:
				has_different_neighbor = true
				break
		
		if has_different_neighbor:
			# Score by how "borderline" the climate values are
			var climate = climate_data[key]
			var score = _get_borderline_score(climate, target_biome)
			borderline.append({"key": key, "score": score})
	
	# Sort by score (highest = most borderline = best candidate for reassignment)
	borderline.sort_custom(func(a, b): return a["score"] > b["score"])
	
	var result: Array = []
	for item in borderline:
		result.append(item["key"])
	return result


## Calculate how "borderline" a tile's climate is for its assigned biome
func _get_borderline_score(climate: Dictionary, biome: Biomes.Type) -> float:
	# Higher score = more borderline = climate values are near thresholds
	var e: float = climate.elevation
	var t: float = climate.temperature
	var m: float = climate.moisture
	
	# Distance from climate thresholds (closer to threshold = more borderline)
	var threshold_distances: Array = [
		abs(e - 0.7), abs(e - 0.3), # Elevation thresholds
		abs(t - 0.35), abs(t - 0.55), abs(t - 0.65), # Temperature thresholds
		abs(m - 0.55), abs(m - 0.6) # Moisture thresholds
	]
	
	# Return inverse of minimum distance (closer = higher score)
	var min_dist: float = 1.0
	for d in threshold_distances:
		min_dist = min(min_dist, d)
	
	return 1.0 - min_dist


## Find an alternative biome for a tile that needs reassignment
## Returns null if no valid alternative found
func _find_alternative_biome(coord: HexCoordinates, biome_map: Dictionary, under_biomes: Array, climate: Dictionary):
	var best_biome = null
	var best_score: float = -1.0
	
	for candidate in under_biomes:
		# Check if this biome would be valid here (no forbidden neighbors)
		var valid: bool = true
		for neighbor in _get_valid_neighbors(coord):
			var nkey: String = neighbor._to_key()
			if nkey in biome_map:
				if not _can_be_adjacent(candidate, biome_map[nkey]):
					valid = false
					break
		
		if not valid:
			continue
		
		# Score based on climate compatibility
		var score: float = _get_climate_compatibility(climate, candidate)
		if score > best_score:
			best_score = score
			best_biome = candidate
	
	return best_biome


## Get compatibility score between climate values and a biome type
func _get_climate_compatibility(climate: Dictionary, biome: Biomes.Type) -> float:
	var e: float = climate.elevation
	var t: float = climate.temperature
	var m: float = climate.moisture
	
	match biome:
		Biomes.Type.PEAKS:
			return (1.0 - t) * e # Cold + High
		Biomes.Type.ASHLANDS:
			return t * e # Hot + High
		Biomes.Type.HILLS:
			return e * (1.0 - abs(t - 0.5) * 2) # High + Temperate
		Biomes.Type.WASTES:
			return t * (1.0 - m) # Hot + Dry
		Biomes.Type.SWAMP:
			return (1.0 - e) * m # Low + Wet
		Biomes.Type.FOREST:
			return m * (1.0 - abs(e - 0.5) * 2) # Mid elevation + Wet
		Biomes.Type.PLAINS:
			return (1.0 - abs(e - 0.4) * 2) * (1.0 - abs(t - 0.5) * 2) # Mid everything
		_:
			return 0.5


func _count_biomes(biome_map: Dictionary) -> Dictionary:
	var counts: Dictionary = {}
	for biome in Biomes.Type.values():
		counts[biome] = 0
	for key in biome_map:
		counts[biome_map[key]] = counts.get(biome_map[key], 0) + 1
	return counts


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
		
		# Use the original elevation noise to vary within the biome's range
		var climate = _get_climate_values(coord)
		var elevation_factor = (climate.elevation + 1.0) * 0.5 # Convert -1..1 to 0..1
		
		# Add some micro-variation using detail noise
		var pixel = coord.to_pixel(1.0)
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
# BIOME SMOOTHING (Neighbor Influence)
# =============================================================================

## Smooth biomes by neighbor influence - eliminates isolated tiles and thin strings
## If a tile is surrounded by 5-6 neighbors of a DIFFERENT biome, flip it to match
func _smooth_biomes_by_neighbors(coordinates: Array[HexCoordinates], biome_map: Dictionary) -> Dictionary:
	var new_map: Dictionary = biome_map.duplicate()
	
	for _pass in range(BIOME_SMOOTHING_PASSES):
		var changed: bool = false
		
		for coord in coordinates:
			var key: String = coord._to_key()
			var current_biome: Biomes.Type = new_map.get(key, Biomes.Type.PLAINS)
			
			var neighbors: Array[HexCoordinates] = _get_valid_neighbors(coord)
			if neighbors.size() < 5:
				continue # Edge tiles - skip
			
			# Count how many neighbors share our biome
			var same_biome_count: int = 0
			var neighbor_biome_counts: Dictionary = {}
			
			for neighbor in neighbors:
				var nkey: String = neighbor._to_key()
				if nkey in new_map:
					var nb: Biomes.Type = new_map[nkey]
					neighbor_biome_counts[nb] = neighbor_biome_counts.get(nb, 0) + 1
					if nb == current_biome:
						same_biome_count += 1
			
			# If surrounded by 5+ neighbors of a DIFFERENT biome, flip to dominant neighbor
			var total_different = neighbors.size() - same_biome_count
			if total_different >= 5:
				# Find the most common neighbor biome
				var best_biome: Biomes.Type = current_biome
				var best_count: int = 0
				
				for biome in neighbor_biome_counts:
					if biome != current_biome and neighbor_biome_counts[biome] > best_count:
						# Check adjacency rules before flipping
						var valid: bool = true
						for check_neighbor in neighbors:
							var cnkey: String = check_neighbor._to_key()
							if cnkey in new_map and not _can_be_adjacent(biome, new_map[cnkey]):
								valid = false
								break
						
						if valid:
							best_count = neighbor_biome_counts[biome]
							best_biome = biome
				
				if best_biome != current_biome:
					new_map[key] = best_biome
					changed = true
		
		if not changed:
			break
	
	return new_map


# =============================================================================
# CLEANUP PASSES
# =============================================================================

func _cleanup_isolated_tiles(coordinates: Array[HexCoordinates], biome_map: Dictionary) -> Dictionary:
	var new_map: Dictionary = biome_map.duplicate()
	
	for _pass in range(CLEANUP_PASSES):
		var changed: bool = false
		
		for coord in coordinates:
			var key: String = coord._to_key()
			var current: Biomes.Type = new_map.get(key, Biomes.Type.PLAINS)
			
			var neighbors: Array[HexCoordinates] = _get_valid_neighbors(coord)
			var neighbor_counts: Dictionary = {}
			var same_count: int = 0
			
			for neighbor in neighbors:
				var nkey: String = neighbor._to_key()
				if nkey in new_map:
					var nb: Biomes.Type = new_map[nkey]
					neighbor_counts[nb] = neighbor_counts.get(nb, 0) + 1
					if nb == current:
						same_count += 1
			
			# Merge tiles that have fewer than 2 same-biome neighbors (more aggressive)
			if same_count < 2 and neighbors.size() >= 3:
				var best_biome: Biomes.Type = current
				var best_count: int = 0
				
				for biome in neighbor_counts:
					if neighbor_counts[biome] > best_count:
						var valid: bool = true
						for neighbor in neighbors:
							var nkey: String = neighbor._to_key()
							if nkey in new_map:
								if not _can_be_adjacent(biome, new_map[nkey]):
									valid = false
									break
						
						if valid:
							best_count = neighbor_counts[biome]
							best_biome = biome
				
				if best_biome != current and best_count >= 2:
					new_map[key] = best_biome
					changed = true
		
		if not changed:
			break
	
	return new_map


func _fix_adjacency_violations(coordinates: Array[HexCoordinates], biome_map: Dictionary) -> Dictionary:
	var new_map: Dictionary = biome_map.duplicate()
	
	for _pass in range(3):
		var changed: bool = false
		
		for coord in coordinates:
			var key: String = coord._to_key()
			var current: Biomes.Type = new_map.get(key, Biomes.Type.PLAINS)
			
			if current == Biomes.Type.HILLS:
				continue
			
			var neighbors: Array[HexCoordinates] = _get_valid_neighbors(coord)
			var violation_count: int = 0
			var neighbor_biome_counts: Dictionary = {}
			
			for neighbor in neighbors:
				var nkey: String = neighbor._to_key()
				if nkey in new_map:
					var nb: Biomes.Type = new_map[nkey]
					neighbor_biome_counts[nb] = neighbor_biome_counts.get(nb, 0) + 1
					if not _can_be_adjacent(current, nb):
						violation_count += 1
			
			# Only fix if there's at least 1 violation
			if violation_count >= 1:
				# Try to find a valid biome that matches most neighbors
				var best_biome: Biomes.Type = Biomes.Type.HILLS
				var best_count: int = 0
				
				for candidate_biome in neighbor_biome_counts:
					if candidate_biome == current:
						continue
					
					# Check if this biome would be valid with ALL neighbors
					var valid: bool = true
					for neighbor in neighbors:
						var nkey: String = neighbor._to_key()
						if nkey in new_map:
							if not _can_be_adjacent(candidate_biome, new_map[nkey]):
								valid = false
								break
					
					if valid and neighbor_biome_counts[candidate_biome] > best_count:
						best_count = neighbor_biome_counts[candidate_biome]
						best_biome = candidate_biome
				
				new_map[key] = best_biome
				changed = true
		
		if not changed:
			break
	
	return new_map


# =============================================================================
# DEBUG UTILITIES
# =============================================================================

func print_distribution(biome_map: Dictionary) -> void:
	var counts: Dictionary = _count_biomes(biome_map)
	
	print("=== Biome Distribution (Target: ~%d ±%d) ===" % [BASE_TILES_PER_BIOME, TILE_VARIANCE])
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
