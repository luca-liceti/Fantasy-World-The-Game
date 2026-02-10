## Biome Definitions
## Contains all 7 biome types with their properties and visual settings
class_name Biomes
extends RefCounted

# =============================================================================
# BIOME ENUM
# =============================================================================
enum Type {
	FOREST,      # Enchanted Forest
	PEAKS,       # Frozen Peaks
	WASTES,      # Desolate Wastes
	PLAINS,      # Golden Plains
	ASHLANDS,    # Ashlands (volcanic)
	HILLS,       # Highlands/Rolling Hills
	SWAMP        # Swamplands
}

# =============================================================================
# BIOME DATA
# =============================================================================
const DATA: Dictionary = {
	Type.FOREST: {
		"name": "Enchanted Forest",
		"description": "Magical woodlands filled with ancient trees and mystical creatures.",
		"color": Color(0.2, 0.6, 0.3),  # Forest green
		"distribution_weight": 0.15,    # 15% of board
		"can_place_mine": true,
		"clustering_preference": ["HILLS", "SWAMP"]  # Tends to appear near these
	},
	Type.PEAKS: {
		"name": "Frozen Peaks",
		"description": "Towering mountains covered in eternal ice and snow.",
		"color": Color(0.85, 0.9, 0.95),  # Icy white-blue
		"distribution_weight": 0.10,      # 10% of board
		"can_place_mine": false,          # Cannot place mines on Peaks
		"clustering_preference": ["HILLS", "WASTES"]
	},
	Type.WASTES: {
		"name": "Desolate Wastes",
		"description": "Barren lands scarred by ancient cataclysms.",
		"color": Color(0.6, 0.5, 0.4),  # Dusty brown
		"distribution_weight": 0.10,    # 10% of board
		"can_place_mine": true,
		"clustering_preference": ["PEAKS", "ASHLANDS"]
	},
	Type.PLAINS: {
		"name": "Golden Plains",
		"description": "Vast grasslands with rolling golden wheat fields.",
		"color": Color(0.9, 0.8, 0.4),  # Golden yellow
		"distribution_weight": 0.20,    # 20% of board
		"can_place_mine": true,
		"clustering_preference": ["HILLS", "FOREST"]
	},
	Type.ASHLANDS: {
		"name": "Ashlands",
		"description": "Volcanic terrain with rivers of lava and ash-covered ground.",
		"color": Color(0.5, 0.25, 0.2),  # Volcanic red-brown
		"distribution_weight": 0.12,     # 12% of board
		"can_place_mine": true,
		"clustering_preference": ["WASTES", "PEAKS"]
	},
	Type.HILLS: {
		"name": "Highlands",
		"description": "Rolling green hills and rocky outcrops.",
		"color": Color(0.5, 0.7, 0.4),  # Hill green
		"distribution_weight": 0.15,    # 15% of board
		"can_place_mine": true,
		"clustering_preference": ["PLAINS", "FOREST", "PEAKS"]
	},
	Type.SWAMP: {
		"name": "Swamplands",
		"description": "Murky wetlands filled with fog and hidden dangers.",
		"color": Color(0.3, 0.4, 0.3),  # Murky green
		"distribution_weight": 0.12,    # 12% of board
		"can_place_mine": true,
		"clustering_preference": ["FOREST", "WASTES"]
	}
}

# Special biomes weight (remaining 6%)
const SPECIAL_BIOME_WEIGHT: float = 0.06

# =============================================================================
# BIOME BASE HEIGHTS (for vertex-based terrain)
# =============================================================================
# Base height values for each biome (before height multiplier)
# These are averaged at shared vertices to create smooth transitions
const BASE_HEIGHTS: Dictionary = {
	Type.SWAMP: 0.1,      # Lowest - near water level
	Type.PLAINS: 0.3,     # Low flatlands
	Type.FOREST: 0.5,     # Mid-elevation forests
	Type.WASTES: 0.6,     # Desert plateaus
	Type.HILLS: 0.8,      # Rolling highlands
	Type.ASHLANDS: 1.0,   # Volcanic high ground
	Type.PEAKS: 1.5       # Highest - mountain peaks
}

# =============================================================================
# TROOP BIOME MODIFIERS
# =============================================================================
# Modifier types: "A" = Advantage (+25%), "S" = Strength (+15%), 
#                 "D" = Defense (-15% incoming), "W" = Weakness (-25%)
# null = no modifier (neutral)

const TROOP_MODIFIERS: Dictionary = {
	"medieval_knight": {
		Type.FOREST: null, Type.PEAKS: null, Type.WASTES: "W",
		Type.PLAINS: "S", Type.ASHLANDS: null, Type.HILLS: "D", Type.SWAMP: null
	},
	"stone_giant": {
		Type.FOREST: null, Type.PEAKS: "A", Type.WASTES: null,
		Type.PLAINS: null, Type.ASHLANDS: "S", Type.HILLS: "D", Type.SWAMP: "W"
	},
	"four_headed_hydra": {
		Type.FOREST: null, Type.PEAKS: "W", Type.WASTES: "S",
		Type.PLAINS: null, Type.ASHLANDS: "A", Type.HILLS: null, Type.SWAMP: "S"
	},
	"dark_blood_dragon": {
		Type.FOREST: "W", Type.PEAKS: null, Type.WASTES: "A",
		Type.PLAINS: null, Type.ASHLANDS: "S", Type.HILLS: null, Type.SWAMP: null
	},
	"sky_serpent": {
		Type.FOREST: "S", Type.PEAKS: "A", Type.WASTES: null,
		Type.PLAINS: "S", Type.ASHLANDS: "W", Type.HILLS: null, Type.SWAMP: null
	},
	"frost_valkyrie": {
		Type.FOREST: null, Type.PEAKS: "A", Type.WASTES: "W",
		Type.PLAINS: null, Type.ASHLANDS: "W", Type.HILLS: "S", Type.SWAMP: null
	},
	"dark_magic_wizard": {
		Type.FOREST: "A", Type.PEAKS: null, Type.WASTES: "S",
		Type.PLAINS: null, Type.ASHLANDS: null, Type.HILLS: null, Type.SWAMP: "S"
	},
	"demon_of_darkness": {
		Type.FOREST: "W", Type.PEAKS: null, Type.WASTES: "S",
		Type.PLAINS: "W", Type.ASHLANDS: "A", Type.HILLS: null, Type.SWAMP: null
	},
	"elven_archer": {
		Type.FOREST: "A", Type.PEAKS: null, Type.WASTES: "W",
		Type.PLAINS: "S", Type.ASHLANDS: null, Type.HILLS: "S", Type.SWAMP: "W"
	},
	"celestial_cleric": {
		Type.FOREST: "S", Type.PEAKS: "S", Type.WASTES: "W",
		Type.PLAINS: "D", Type.ASHLANDS: "W", Type.HILLS: null, Type.SWAMP: null
	},
	"shadow_assassin": {
		Type.FOREST: "A", Type.PEAKS: "W", Type.WASTES: null,
		Type.PLAINS: null, Type.ASHLANDS: "S", Type.HILLS: null, Type.SWAMP: "S"
	},
	"infernal_soul": {
		Type.FOREST: "W", Type.PEAKS: "W", Type.WASTES: null,
		Type.PLAINS: null, Type.ASHLANDS: "A", Type.HILLS: null, Type.SWAMP: "S"
	}
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

## Get biome data by type
static func get_biome_data(biome_type: Type) -> Dictionary:
	return DATA.get(biome_type, {})


## Get biome name by type
static func get_biome_name(biome_type: Type) -> String:
	var data = get_biome_data(biome_type)
	return data.get("name", "Unknown")


## Get biome color by type
static func get_biome_color(biome_type: Type) -> Color:
	var data = get_biome_data(biome_type)
	return data.get("color", Color.WHITE)


## Check if mines can be placed on this biome
static func can_place_mine(biome_type: Type) -> bool:
	var data = get_biome_data(biome_type)
	return data.get("can_place_mine", true)


## Get troop modifier for a specific biome
## Returns: "A", "S", "D", "W", or null
static func get_troop_modifier(troop_id: String, biome_type: Type):
	var troop_mods = TROOP_MODIFIERS.get(troop_id, {})
	return troop_mods.get(biome_type, null)


## Get modifier value based on modifier type
static func get_modifier_value(modifier_type) -> float:
	match modifier_type:
		"A": return GameConfig.ADVANTAGE_MODIFIER   # +25%
		"S": return GameConfig.STRENGTH_MODIFIER    # +15%
		"D": return GameConfig.DEFENSE_MODIFIER     # -15% incoming
		"W": return GameConfig.WEAKNESS_MODIFIER    # -25%
		_: return 0.0


## Get base height for a biome type (for vertex-based terrain)
static func get_base_height(biome_type: Type) -> float:
	return BASE_HEIGHTS.get(biome_type, 0.5)

