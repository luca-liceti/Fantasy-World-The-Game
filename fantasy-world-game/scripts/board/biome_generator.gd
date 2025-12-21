## Biome Generator
## Handles procedural generation of biomes for the hex board
## Ensures all 7 biomes are present with natural clustering
class_name BiomeGenerator
extends RefCounted

# =============================================================================
# GENERATION SETTINGS
# =============================================================================
const MIN_BIOME_COUNT: int = 10  # Minimum hexes of each biome type
const CLUSTER_TENDENCY: float = 0.6  # Probability to match neighbor biome

# =============================================================================
# GENERATION
# =============================================================================

## Generate biomes for all hex coordinates
## Returns: Dictionary[String, Biomes.Type] mapping coord keys to biome types
func generate_biomes(coordinates: Array[HexCoordinates]) -> Dictionary:
	var biome_map: Dictionary = {}
	var biome_counts: Dictionary = _init_biome_counts()
	
	# Shuffle coordinates for random placement order
	var shuffled = coordinates.duplicate()
	shuffled.shuffle()
	
	# First pass: Place seed clusters for each biome type
	_place_biome_seeds(shuffled, biome_map, biome_counts)
	
	# Second pass: Fill remaining hexes with clustering
	for coord in shuffled:
		var key = coord._to_key()
		if key in biome_map:
			continue  # Already assigned
		
		var biome = _choose_biome_for_coord(coord, biome_map, biome_counts, coordinates)
		biome_map[key] = biome
		biome_counts[biome] += 1
	
	# Validation: Ensure all biomes are present
	if not _validate_biomes(biome_counts):
		push_warning("Biome validation failed! Some biomes may be missing.")
	
	return biome_map


## Initialize biome count tracking
func _init_biome_counts() -> Dictionary:
	var counts: Dictionary = {}
	for biome in Biomes.Type.values():
		counts[biome] = 0
	return counts


## Place initial seed clusters for each biome
func _place_biome_seeds(coords: Array, biome_map: Dictionary, biome_counts: Dictionary) -> void:
	var biome_types = Biomes.Type.values()
	var coords_copy = coords.duplicate()
	coords_copy.shuffle()
	
	# Place at least MIN_BIOME_COUNT/2 seeds for each biome type
	var seeds_per_biome = MIN_BIOME_COUNT / 2
	
	for biome in biome_types:
		var placed = 0
		for coord in coords_copy:
			var key = coord._to_key()
			if key in biome_map:
				continue
			
			biome_map[key] = biome
			biome_counts[biome] += 1
			placed += 1
			
			if placed >= seeds_per_biome:
				break


## Choose biome for a coordinate based on neighbors and weights
func _choose_biome_for_coord(coord: HexCoordinates, biome_map: Dictionary, 
							  biome_counts: Dictionary, all_coords: Array[HexCoordinates]) -> Biomes.Type:
	
	# Get neighbor biomes
	var neighbor_biomes = _get_neighbor_biomes(coord, biome_map)
	
	# Try to cluster with neighbors
	if randf() < CLUSTER_TENDENCY and not neighbor_biomes.is_empty():
		# Choose a neighbor biome, preferring clustering preferences
		var chosen = neighbor_biomes[randi() % neighbor_biomes.size()]
		
		# Check clustering preferences
		var biome_data = Biomes.get_biome_data(chosen)
		var preferences = biome_data.get("clustering_preference", [])
		
		for pref in preferences:
			var pref_biome = _name_to_biome_type(pref)
			if pref_biome in neighbor_biomes:
				return pref_biome
		
		return chosen
	
	# Otherwise, use weighted random based on distribution weights
	return _weighted_random_biome(biome_counts, all_coords.size())


## Get biome types of neighboring hexes
func _get_neighbor_biomes(coord: HexCoordinates, biome_map: Dictionary) -> Array:
	var biomes: Array = []
	var neighbors = coord.get_all_neighbors()
	
	for neighbor in neighbors:
		var key = neighbor._to_key()
		if key in biome_map:
			biomes.append(biome_map[key])
	
	return biomes


## Select biome based on distribution weights
func _weighted_random_biome(biome_counts: Dictionary, total_hexes: int) -> Biomes.Type:
	var weights: Array = []
	var biomes: Array = []
	
	for biome in Biomes.Type.values():
		var data = Biomes.get_biome_data(biome)
		var target_weight = data.get("distribution_weight", 0.1)
		var current_ratio = float(biome_counts[biome]) / float(max(1, total_hexes))
		
		# Increase weight if below target, decrease if above
		var adjusted_weight = target_weight * (1.0 + (target_weight - current_ratio) * 2.0)
		adjusted_weight = max(0.01, adjusted_weight)  # Ensure positive
		
		weights.append(adjusted_weight)
		biomes.append(biome)
	
	return _weighted_choice(biomes, weights)


## Weighted random choice
func _weighted_choice(items: Array, weights: Array) -> Biomes.Type:
	var total = 0.0
	for w in weights:
		total += w
	
	var roll = randf() * total
	var cumulative = 0.0
	
	for i in range(items.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return items[i]
	
	return items[items.size() - 1]


## Convert biome name string to enum type
func _name_to_biome_type(name: String) -> Biomes.Type:
	match name.to_upper():
		"FOREST": return Biomes.Type.FOREST
		"PEAKS": return Biomes.Type.PEAKS
		"WASTES": return Biomes.Type.WASTES
		"PLAINS": return Biomes.Type.PLAINS
		"ASHLANDS": return Biomes.Type.ASHLANDS
		"HILLS": return Biomes.Type.HILLS
		"SWAMP": return Biomes.Type.SWAMP
		_: return Biomes.Type.PLAINS


## Validate that all biomes are present
func _validate_biomes(biome_counts: Dictionary) -> bool:
	for biome in Biomes.Type.values():
		if biome_counts.get(biome, 0) < MIN_BIOME_COUNT:
			push_warning("Biome %s has only %d hexes (minimum: %d)" % [
				Biomes.get_biome_name(biome), 
				biome_counts.get(biome, 0),
				MIN_BIOME_COUNT
			])
			return false
	return true


# =============================================================================
# DEBUG
# =============================================================================

## Print biome distribution for debugging
func print_distribution(biome_counts: Dictionary, total: int) -> void:
	print("=== Biome Distribution ===")
	for biome in Biomes.Type.values():
		var count = biome_counts.get(biome, 0)
		var percent = 100.0 * count / total
		var name = Biomes.get_biome_name(biome)
		print("  %s: %d (%.1f%%)" % [name, count, percent])
