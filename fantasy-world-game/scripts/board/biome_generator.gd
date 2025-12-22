## Biome Generator - Seed and Grow (Voronoi/BFS) Algorithm
## ========================================================================
## 
## This algorithm generates 7 distinct biome regions across 397 hex tiles,
## ensuring natural-looking, contiguous regions with balanced distribution.
##
## ALGORITHM OVERVIEW
## ==================
## 1. SEED PLACEMENT: 7 random hexes are chosen as "seed centers" for each biome.
##    Seeds for forbidden pairs (e.g., PEAKS/ASHLANDS) are placed at least 3 
##    tiles apart to ensure they don't immediately conflict.
##
## 2. SIMULTANEOUS BFS GROWTH: All 7 biomes expand outward simultaneously,
##    one tile at a time in round-robin fashion. This creates balanced, 
##    organic shapes similar to Voronoi diagrams.
##
## 3. FORBIDDEN NEIGHBOR ENFORCEMENT: During expansion, a biome CANNOT claim
##    a tile if doing so would create an illegal border with an already-assigned
##    neighbor. The tile is skipped and may be claimed by a compatible biome.
##
## 4. CLEANUP PASS: After all tiles are assigned, any "orphan" tile (surrounded
##    entirely by a different biome) is absorbed into the surrounding biome.
##
## 5. FINAL ADJACENCY FIX: Any remaining violations are resolved by converting
##    the offending tile to HILLS (the universal connector biome).
##
## HOW ADJACENCY CHECKS PREVENT ILLEGAL TRANSITIONS
## =================================================
## The key mechanism is the `_can_claim_tile()` function:
##
##   1. When a biome tries to claim a frontier tile, we check ALL existing
##      neighbors of that tile.
##
##   2. For EACH neighbor that's already assigned a biome, we verify:
##      "Is the claiming biome allowed to share a border with the neighbor?"
##
##   3. This check uses the FORBIDDEN_PAIRS constant. For example:
##      - PEAKS (cold snowy mountains) cannot border ASHLANDS (volcanic heat)
##      - FOREST (temperate wet) cannot border ASHLANDS (volcanic dry)
##
##   4. If ANY neighbor would create a forbidden transition, the claim is
##      DENIED. The tile stays in the frontier for other biomes to claim.
##
##   5. HILLS acts as a "universal connector" biome that can legally border
##      ANY other biome, acting as a natural transition zone.
##
## This approach guarantees that forbidden biomes never share a border,
## while still allowing organic, natural-looking region shapes.
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

## Random variance applied to each biome's target size (±10 tiles)
## This prevents the map from looking perfectly symmetrical
const TILE_VARIANCE: int = 10

## Minimum hex distance between incompatible biome seeds
## This ensures forbidden biomes start far enough apart that their
## regions won't immediately collide during early growth
const FORBIDDEN_SEED_DISTANCE: int = 3


# =============================================================================
# FORBIDDEN NEIGHBOR PAIRS - Temperature/Climate Logic
# =============================================================================
## These biome pairs represent incompatible ecosystems that cannot share a 
## border. The logic is based on realistic climate/temperature transitions:
##
## - PEAKS (frozen mountains) vs ASHLANDS (volcanic lava): Extreme cold vs 
##   extreme heat - impossible transition without a buffer zone
##
## - PEAKS (frozen) vs WASTES (hot desert): Snow and ice cannot directly
##   transition to scorching desert without temperate zones between
##
## - SWAMP (wet marshland) vs ASHLANDS (dry volcanic): Moisture extremes -
##   swamps require water that would instantly evaporate near lava
##
## - FOREST (temperate woodland) vs ASHLANDS (volcanic): Trees cannot survive
##   adjacent to volcanic activity; requires a barren buffer zone
##
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


# =============================================================================
# MAIN GENERATION ENTRY POINT
# =============================================================================

## Generate biomes for all coordinates using Seed-and-Grow BFS algorithm.
## 
## @param coordinates: Array of all HexCoordinates on the board
## @return Dictionary mapping "q,r" keys to Biomes.Type values
func generate_biomes(coordinates: Array[HexCoordinates]) -> Dictionary:
	# Initialize random number generator with system time
	_rng.randomize()
	
	# Build lookup tables for fast neighbor access
	_build_coord_lookup(coordinates)
	_build_adjacency_matrix()
	
	# STEP 1: Calculate target sizes with random variance
	# Each biome gets ~56 tiles ± 10, ensuring natural-looking distribution
	var target_sizes: Dictionary = _calculate_target_sizes()
	
	# STEP 2: Place 7 seeds respecting forbidden neighbor distance
	# Seeds for incompatible biomes (e.g., PEAKS and ASHLANDS) must be
	# at least FORBIDDEN_SEED_DISTANCE apart
	var seeds: Array[Dictionary] = _place_seeds(coordinates, target_sizes)
	
	# STEP 3: Grow all biomes simultaneously via BFS
	# Each biome expands one tile per round, checking adjacency rules
	var biome_map: Dictionary = _grow_biomes(coordinates, seeds, target_sizes)
	
	# STEP 4: Fill any tiles that couldn't be claimed due to conflicts
	biome_map = _fill_remaining_tiles(coordinates, biome_map)
	
	# STEP 5: Cleanup isolated tiles (tiles surrounded by different biome)
	biome_map = _cleanup_isolated_tiles(coordinates, biome_map)
	
	# STEP 6: Final pass to fix any remaining adjacency violations
	biome_map = _fix_adjacency_violations(coordinates, biome_map)
	
	return biome_map


# =============================================================================
# STEP 1: ADJACENCY MATRIX CONSTRUCTION
# =============================================================================

## Build the adjacency matrix from forbidden pairs.
## Initially, all biomes can neighbor each other. Then we remove forbidden pairs.
func _build_adjacency_matrix() -> void:
	_valid_adjacencies.clear()
	
	# Start with all biomes being valid neighbors for each other
	var all_biomes: Array = Biomes.Type.values()
	for biome_a in all_biomes:
		_valid_adjacencies[biome_a] = []
		for biome_b in all_biomes:
			if biome_a != biome_b:
				_valid_adjacencies[biome_a].append(biome_b)
	
	# Remove forbidden pairs from the adjacency matrix
	for pair in FORBIDDEN_PAIRS:
		var biome_a: Biomes.Type = pair[0]
		var biome_b: Biomes.Type = pair[1]
		
		if biome_b in _valid_adjacencies[biome_a]:
			_valid_adjacencies[biome_a].erase(biome_b)
		if biome_a in _valid_adjacencies[biome_b]:
			_valid_adjacencies[biome_b].erase(biome_a)


## Check if two biomes can share a border
func _can_be_adjacent(biome_a: Biomes.Type, biome_b: Biomes.Type) -> bool:
	# Same biome is always valid
	if biome_a == biome_b:
		return true
	
	# HILLS is a universal connector - can border any biome
	# This acts as a natural transition zone between incompatible biomes
	if biome_a == Biomes.Type.HILLS or biome_b == Biomes.Type.HILLS:
		return true
	
	# Check the adjacency matrix
	return biome_b in _valid_adjacencies.get(biome_a, [])


## Check if two biome types are a forbidden pair
func _is_forbidden_pair(biome_a: Biomes.Type, biome_b: Biomes.Type) -> bool:
	for pair in FORBIDDEN_PAIRS:
		if (pair[0] == biome_a and pair[1] == biome_b) or \
		   (pair[0] == biome_b and pair[1] == biome_a):
			return true
	return false


# =============================================================================
# COORDINATE UTILITIES
# =============================================================================

## Build fast O(1) lookup dictionary for coordinate existence checks
func _build_coord_lookup(coordinates: Array[HexCoordinates]) -> void:
	_coord_lookup.clear()
	for coord in coordinates:
		_coord_lookup[coord._to_key()] = coord


## Get all neighbors of a coordinate that exist on the board
func _get_valid_neighbors(coord: HexCoordinates) -> Array[HexCoordinates]:
	var result: Array[HexCoordinates] = []
	for neighbor in coord.get_all_neighbors():
		if neighbor._to_key() in _coord_lookup:
			result.append(neighbor)
	return result


# =============================================================================
# STEP 2: TARGET SIZE CALCULATION
# =============================================================================

## Calculate target tile count for each biome with random variance.
## This ensures the map doesn't look perfectly symmetrical.
func _calculate_target_sizes() -> Dictionary:
	var sizes: Dictionary = {}
	var all_biomes: Array = Biomes.Type.values()
	var total_assigned: int = 0
	
	# Assign size with random variance for all but the last biome
	for i in range(all_biomes.size() - 1):
		var biome: Biomes.Type = all_biomes[i]
		var variance: int = _rng.randi_range(-TILE_VARIANCE, TILE_VARIANCE)
		sizes[biome] = BASE_TILES_PER_BIOME + variance
		total_assigned += sizes[biome]
	
	# Last biome gets remaining tiles to ensure total = TOTAL_TILES
	var last_biome: Biomes.Type = all_biomes[all_biomes.size() - 1]
	sizes[last_biome] = TOTAL_TILES - total_assigned
	
	# Clamp all sizes to reasonable bounds
	for biome in sizes:
		sizes[biome] = clampi(
			sizes[biome],
			BASE_TILES_PER_BIOME - TILE_VARIANCE,
			BASE_TILES_PER_BIOME + TILE_VARIANCE + 15
		)
	
	return sizes


# =============================================================================
# STEP 3: SEED PLACEMENT
# =============================================================================

## Place 7 seed tiles across the board, respecting forbidden neighbor distance.
## Seeds for incompatible biomes must be at least FORBIDDEN_SEED_DISTANCE apart.
func _place_seeds(coordinates: Array[HexCoordinates], target_sizes: Dictionary) -> Array[Dictionary]:
	var seeds: Array[Dictionary] = []
	var all_biomes: Array = Biomes.Type.values().duplicate()
	
	# Shuffle biome order for variety
	all_biomes.shuffle()
	
	# Create shuffled list of candidate positions
	var candidates: Array[HexCoordinates] = []
	for coord in coordinates:
		candidates.append(coord)
	candidates.shuffle()
	
	# Place each biome's seed
	for biome in all_biomes:
		var placed: bool = false
		
		for candidate in candidates:
			if _is_valid_seed_position(candidate, biome, seeds):
				seeds.append({
					"coord": candidate,
					"biome": biome,
					"target_size": target_sizes[biome]
				})
				candidates.erase(candidate)
				placed = true
				break
		
		# Fallback: if no valid position found, relax constraints
		if not placed and candidates.size() > 0:
			var fallback: HexCoordinates = candidates[0]
			seeds.append({
				"coord": fallback,
				"biome": biome,
				"target_size": target_sizes[biome]
			})
			candidates.erase(fallback)
			push_warning("BiomeGenerator: Relaxed seed constraint for %s" % Biomes.get_biome_name(biome))
	
	return seeds


## Validate a seed position against existing seeds.
## Forbidden pairs must be at least FORBIDDEN_SEED_DISTANCE apart.
## All seeds must be at least 2 tiles apart for better distribution.
func _is_valid_seed_position(coord: HexCoordinates, biome: Biomes.Type, existing_seeds: Array[Dictionary]) -> bool:
	for seed in existing_seeds:
		var distance: int = coord.distance_to(seed["coord"])
		var other_biome: Biomes.Type = seed["biome"]
		
		# Forbidden pairs need extra distance to prevent early collision
		if _is_forbidden_pair(biome, other_biome):
			if distance < FORBIDDEN_SEED_DISTANCE:
				return false
		
		# All seeds need minimum spacing for good distribution
		if distance < 2:
			return false
	
	return true


# =============================================================================
# STEP 4: BFS GROWTH ALGORITHM
# =============================================================================

## Grow all biomes simultaneously from their seeds using BFS.
## Each biome expands one tile per round in round-robin fashion.
## This creates organic Voronoi-like shapes.
func _grow_biomes(coordinates: Array[HexCoordinates], seeds: Array[Dictionary], target_sizes: Dictionary) -> Dictionary:
	var biome_map: Dictionary = {}
	
	# Initialize: assign seed tiles and create frontiers
	var frontiers: Array[Array] = [] # One frontier queue per biome
	var current_sizes: Array[int] = [] # Current size of each biome
	
	for seed in seeds:
		var key: String = seed["coord"]._to_key()
		biome_map[key] = seed["biome"]
		
		# Initialize frontier with seed's valid neighbors
		var frontier: Array = []
		for neighbor in _get_valid_neighbors(seed["coord"]):
			var nkey: String = neighbor._to_key()
			if nkey not in biome_map:
				frontier.append(neighbor)
		
		frontiers.append(frontier)
		current_sizes.append(1) # Seed counts as 1 tile
	
	# Main growth loop: round-robin expansion
	var max_iterations: int = TOTAL_TILES * 2 # Safety limit
	var iteration: int = 0
	
	while iteration < max_iterations:
		iteration += 1
		var any_growth: bool = false
		
		# Each biome tries to claim one tile per round
		for i in range(seeds.size()):
			var biome: Biomes.Type = seeds[i]["biome"]
			var target: int = target_sizes[biome]
			
			# Skip if biome has reached its target size
			if current_sizes[i] >= target:
				continue
			
			# Try to claim one tile from the frontier
			var frontier: Array = frontiers[i]
			frontier.shuffle() # Randomize for organic shapes
			
			var new_frontier: Array = []
			var claimed_this_round: bool = false
			
			for candidate in frontier:
				var ckey: String = candidate._to_key()
				
				# Skip already claimed tiles
				if ckey in biome_map:
					continue
				
				if claimed_this_round:
					# Already claimed one this round, save for next round
					new_frontier.append(candidate)
					continue
				
				# ============================================================
				# CRITICAL: Adjacency check - this prevents illegal transitions
				# ============================================================
				if _can_claim_tile(candidate, biome, biome_map):
					# Claim this tile
					biome_map[ckey] = biome
					current_sizes[i] += 1
					claimed_this_round = true
					any_growth = true
					
					# Add new neighbors to frontier
					for neighbor in _get_valid_neighbors(candidate):
						var nkey: String = neighbor._to_key()
						if nkey not in biome_map:
							new_frontier.append(neighbor)
				else:
					# Can't claim now due to adjacency conflict, try later
					new_frontier.append(candidate)
			
			frontiers[i] = new_frontier
		
		# Check termination conditions
		var total_assigned: int = 0
		for size in current_sizes:
			total_assigned += size
		
		if total_assigned >= TOTAL_TILES or not any_growth:
			break
	
	return biome_map


## Check if a biome can claim a tile without creating forbidden adjacencies.
## 
## This is the CORE mechanism for preventing illegal biome transitions:
##   1. Get all neighbors of the candidate tile that are already assigned
##   2. For each assigned neighbor, check if the claiming biome can share a border
##   3. If ANY neighbor would create a forbidden transition, DENY the claim
##
## @param coord: The tile being considered for claiming
## @param biome: The biome type trying to claim this tile
## @param biome_map: Current state of all assigned tiles
## @return true if the claim is allowed, false if it would create a violation
func _can_claim_tile(coord: HexCoordinates, biome: Biomes.Type, biome_map: Dictionary) -> bool:
	var neighbors: Array[HexCoordinates] = _get_valid_neighbors(coord)
	
	for neighbor in neighbors:
		var nkey: String = neighbor._to_key()
		if nkey in biome_map:
			var neighbor_biome: Biomes.Type = biome_map[nkey]
			
			# Would claiming this tile create a forbidden adjacency?
			if not _can_be_adjacent(biome, neighbor_biome):
				return false # DENY - would create illegal transition
	
	return true # ALLOW - all adjacencies are valid


# =============================================================================
# STEP 5: FILL REMAINING TILES
# =============================================================================

## Fill any unassigned tiles that were blocked during growth.
## Uses neighboring biome with most occurrences that's also valid.
func _fill_remaining_tiles(coordinates: Array[HexCoordinates], biome_map: Dictionary) -> Dictionary:
	var new_map: Dictionary = biome_map.duplicate()
	
	# Find all unassigned tiles
	var unassigned: Array[HexCoordinates] = []
	for coord in coordinates:
		if coord._to_key() not in new_map:
			unassigned.append(coord)
	
	if unassigned.is_empty():
		return new_map
	
	# Iteratively assign tiles (some may become assignable as neighbors get filled)
	var max_iterations: int = unassigned.size() * 3
	var iteration: int = 0
	
	while not unassigned.is_empty() and iteration < max_iterations:
		iteration += 1
		var remaining: Array[HexCoordinates] = []
		
		for coord in unassigned:
			var key: String = coord._to_key()
			
			# Count neighboring biomes
			var neighbor_counts: Dictionary = {}
			for neighbor in _get_valid_neighbors(coord):
				var nkey: String = neighbor._to_key()
				if nkey in new_map:
					var nb: Biomes.Type = new_map[nkey]
					neighbor_counts[nb] = neighbor_counts.get(nb, 0) + 1
			
			if neighbor_counts.is_empty():
				remaining.append(coord)
				continue
			
			# Find the most common neighbor biome that's valid for all neighbors
			var best_biome = null
			var best_count: int = 0
			
			for biome in neighbor_counts:
				# Verify this biome would be valid for ALL existing neighbors
				var valid: bool = true
				for neighbor in _get_valid_neighbors(coord):
					var nkey: String = neighbor._to_key()
					if nkey in new_map:
						if not _can_be_adjacent(biome, new_map[nkey]):
							valid = false
							break
				
				if valid and neighbor_counts[biome] > best_count:
					best_count = neighbor_counts[biome]
					best_biome = biome
			
			# If no fully valid biome, use HILLS (universal connector)
			if best_biome == null:
				best_biome = Biomes.Type.HILLS
			
			new_map[key] = best_biome
		
		unassigned = remaining
	
	# Any remaining tiles get HILLS
	for coord in unassigned:
		new_map[coord._to_key()] = Biomes.Type.HILLS
	
	return new_map


# =============================================================================
# STEP 6: CLEANUP ISOLATED TILES
# =============================================================================

## Clean up isolated tiles that ended up surrounded by different biomes.
## Any tile with 0 same-biome neighbors is absorbed into the dominant neighbor.
func _cleanup_isolated_tiles(coordinates: Array[HexCoordinates], biome_map: Dictionary) -> Dictionary:
	var new_map: Dictionary = biome_map.duplicate()
	
	# Run multiple cleanup passes
	for _pass in range(3):
		var changed: bool = false
		
		for coord in coordinates:
			var key: String = coord._to_key()
			var current: Biomes.Type = new_map.get(key, Biomes.Type.PLAINS)
			
			var neighbors: Array[HexCoordinates] = _get_valid_neighbors(coord)
			var neighbor_counts: Dictionary = {}
			var same_count: int = 0
			
			# Count neighbor biomes
			for neighbor in neighbors:
				var nkey: String = neighbor._to_key()
				if nkey in new_map:
					var nb: Biomes.Type = new_map[nkey]
					neighbor_counts[nb] = neighbor_counts.get(nb, 0) + 1
					if nb == current:
						same_count += 1
			
			# If isolated (0 same-biome neighbors) and has enough neighbors
			if same_count == 0 and neighbors.size() >= 3:
				# Find most common neighbor that's valid for all neighbors
				var best_biome: Biomes.Type = current
				var best_count: int = 0
				
				for biome in neighbor_counts:
					if neighbor_counts[biome] > best_count:
						# Verify change wouldn't create violations
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
				
				if best_biome != current:
					new_map[key] = best_biome
					changed = true
		
		if not changed:
			break
	
	return new_map


# =============================================================================
# STEP 7: FIX ADJACENCY VIOLATIONS
# =============================================================================

## Final pass to fix any remaining adjacency violations.
## Converts violating tiles to HILLS (universal connector).
func _fix_adjacency_violations(coordinates: Array[HexCoordinates], biome_map: Dictionary) -> Dictionary:
	var new_map: Dictionary = biome_map.duplicate()
	
	for _pass in range(3):
		var changed: bool = false
		
		for coord in coordinates:
			var key: String = coord._to_key()
			var current: Biomes.Type = new_map.get(key, Biomes.Type.PLAINS)
			
			# Skip if already HILLS (universal connector)
			if current == Biomes.Type.HILLS:
				continue
			
			var neighbors: Array[HexCoordinates] = _get_valid_neighbors(coord)
			var has_violation: bool = false
			
			for neighbor in neighbors:
				var nkey: String = neighbor._to_key()
				if nkey in new_map:
					var nb: Biomes.Type = new_map[nkey]
					if not _can_be_adjacent(current, nb):
						has_violation = true
						break
			
			if has_violation:
				new_map[key] = Biomes.Type.HILLS # Convert to universal connector
				changed = true
		
		if not changed:
			break
	
	return new_map


# =============================================================================
# DEBUG & STATISTICS UTILITIES
# =============================================================================

## Print biome distribution statistics
func print_distribution(biome_map: Dictionary) -> void:
	var counts: Dictionary = {}
	for biome in Biomes.Type.values():
		counts[biome] = 0
	
	for key in biome_map:
		counts[biome_map[key]] = counts.get(biome_map[key], 0) + 1
	
	print("=== Biome Distribution (Target: ~%d ±%d) ===" % [BASE_TILES_PER_BIOME, TILE_VARIANCE])
	var total: int = biome_map.size()
	for biome in Biomes.Type.values():
		var count: int = counts.get(biome, 0)
		var pct: float = 100.0 * count / total if total > 0 else 0.0
		var diff: int = abs(count - BASE_TILES_PER_BIOME)
		var status: String = "✓" if diff <= TILE_VARIANCE else "!"
		print("  %s %s: %d tiles (%.1f%%)" % [status, Biomes.get_biome_name(biome), count, pct])


## Print adjacency violation report
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
	
	# Each violation counted twice (once from each side)
	print("=== Adjacency Violations: %d ===" % [violations / 2])
	if violations > 0:
		print("  Forbidden pairs found:")
		for pair_key in violation_pairs:
			print("    %s: %d borders" % [pair_key, violation_pairs[pair_key] / 2])
	else:
		print("  ✓ All biome borders are valid!")


## Count isolated tiles (tiles with 0 same-biome neighbors)
func count_isolated_tiles(coordinates: Array[HexCoordinates], biome_map: Dictionary) -> int:
	_build_coord_lookup(coordinates)
	
	var isolated: int = 0
	for coord in coordinates:
		var key: String = coord._to_key()
		var current: Biomes.Type = biome_map.get(key, Biomes.Type.PLAINS)
		
		var has_same_neighbor: bool = false
		for neighbor in _get_valid_neighbors(coord):
			var nkey: String = neighbor._to_key()
			if nkey in biome_map and biome_map[nkey] == current:
				has_same_neighbor = true
				break
		
		if not has_same_neighbor:
			isolated += 1
	
	return isolated


## Get detailed statistics about the generated map
func get_statistics(coordinates: Array[HexCoordinates], biome_map: Dictionary) -> Dictionary:
	_build_coord_lookup(coordinates)
	_build_adjacency_matrix()
	
	var stats: Dictionary = {
		"total_tiles": biome_map.size(),
		"biome_counts": {},
		"adjacency_violations": 0,
		"isolated_tiles": 0
	}
	
	# Count biomes
	for biome in Biomes.Type.values():
		stats["biome_counts"][biome] = 0
	for key in biome_map:
		stats["biome_counts"][biome_map[key]] += 1
	
	# Count violations and isolated tiles
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
	
	# Violations counted twice
	stats["adjacency_violations"] /= 2
	
	return stats
