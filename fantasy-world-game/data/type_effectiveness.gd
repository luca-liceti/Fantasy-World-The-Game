## Type Effectiveness
## Defines damage type matchups for the D&D × Pokémon hybrid combat system
## Based on rock-paper-scissors style interactions between damage types and troop types
class_name TypeEffectiveness
extends RefCounted

# =============================================================================
# CONSTANTS
# =============================================================================

## Super effective multiplier
const SUPER_EFFECTIVE: float = 1.5

## Normal effectiveness multiplier
const NORMAL_EFFECTIVE: float = 1.0

## Not very effective multiplier
const NOT_EFFECTIVE: float = 0.5

## Immune/resistant multiplier
const IMMUNE: float = 0.0


# =============================================================================
# DAMAGE TYPE ENUM (mirrored from MoveData for easy access)
# =============================================================================

enum DamageType {
	PHYSICAL,   # Standard physical damage
	FIRE,       # Fire elemental
	ICE,        # Ice/Cold elemental
	DARK,       # Dark/Shadow elemental
	HOLY,       # Light/Holy elemental
	NATURE      # Nature/Poison elemental
}


# =============================================================================
# TROOP TYPE CATEGORIES
# =============================================================================

## Troop type categories for effectiveness calculation
enum TroopType {
	BEAST,      # Natural creatures (Hydra, Griffin)
	DRAGON,     # Draconic (Dark Blood Dragon)
	UNDEAD,     # Undead/Necromantic (Necromancer, skeletons)
	DEMON,      # Demonic (Infernal Soul, Demon Lord)
	CELESTIAL,  # Holy/Divine (Celestial Cleric, Phoenix)
	HUMANOID,   # Standard humanoids (Knight, Wizard, Archer, Assassin)
	ELEMENTAL   # Elemental beings (Frost Giant)
}


# =============================================================================
# TROOP TO TYPE MAPPING
# =============================================================================

const TROOP_TYPES: Dictionary = {
	# Ground Tanks
	"medieval_knight": TroopType.HUMANOID,
	"four_headed_hydra": TroopType.BEAST,
	
	# Air/Hybrid
	"dark_blood_dragon": TroopType.DRAGON,
	"griffin": TroopType.BEAST,
	
	# Ranged/Magic
	"dark_magic_wizard": TroopType.HUMANOID,
	"elven_archer": TroopType.HUMANOID,
	
	# Flex/Support
	"celestial_cleric": TroopType.CELESTIAL,
	"infernal_soul": TroopType.DEMON,
	"shadow_assassin": TroopType.HUMANOID,
	"necromancer": TroopType.UNDEAD,
	
	# Special
	"frost_giant": TroopType.ELEMENTAL,
	"phoenix": TroopType.CELESTIAL,
	
	# Additional troops (from move_data.gd TROOP_MOVES)
	"sky_serpent": TroopType.DRAGON,
	"frost_valkyrie": TroopType.ELEMENTAL,
	"demon_of_darkness": TroopType.DEMON,
	"thunder_behemoth": TroopType.BEAST,
	"frost_revenant": TroopType.UNDEAD,
	"ironclad_golem": TroopType.ELEMENTAL
}


# =============================================================================
# EFFECTIVENESS MATRIX
# Key: DamageType, Value: Dictionary with strong_against and weak_against arrays
# =============================================================================

const EFFECTIVENESS: Dictionary = {
	DamageType.PHYSICAL: {
		"strong_against": [],  # Physical has no type advantages
		"weak_against": [TroopType.ELEMENTAL],  # Reduced against elementals
		"immune": []
	},
	
	DamageType.FIRE: {
		"strong_against": [TroopType.BEAST, TroopType.UNDEAD],  # Burns beasts and undead
		"weak_against": [TroopType.DRAGON, TroopType.DEMON, TroopType.ELEMENTAL],  # Dragons/Demons resist fire
		"immune": []
	},
	
	DamageType.ICE: {
		"strong_against": [TroopType.DRAGON, TroopType.BEAST],  # Freezes dragons and beasts
		"weak_against": [TroopType.ELEMENTAL, TroopType.UNDEAD],  # Frost giants shrug it off
		"immune": []
	},
	
	DamageType.DARK: {
		"strong_against": [TroopType.HUMANOID, TroopType.CELESTIAL],  # Dark corrupts mortals and holy
		"weak_against": [TroopType.DEMON, TroopType.UNDEAD],  # Demons/Undead are aligned
		"immune": []
	},
	
	DamageType.HOLY: {
		"strong_against": [TroopType.UNDEAD, TroopType.DEMON],  # Holy smites evil
		"weak_against": [TroopType.CELESTIAL],  # Celestials are aligned
		"immune": []
	},
	
	DamageType.NATURE: {
		"strong_against": [TroopType.HUMANOID, TroopType.ELEMENTAL],  # Poison affects mortals
		"weak_against": [TroopType.UNDEAD, TroopType.DEMON],  # Can't poison the dead
		"immune": []
	}
}


# =============================================================================
# TROOP RESISTANCES AND WEAKNESSES
# Override specific matchups for individual troops
# =============================================================================

const TROOP_RESISTANCES: Dictionary = {
	# Phase 6.2 - Troop Type Assignments (Resistances)
	# 6.2.1 Medieval Knight: resists Physical
	"medieval_knight": [DamageType.PHYSICAL],
	# 6.2.2 Stone Giant: resists Physical/Ice
	"stone_giant": [DamageType.PHYSICAL, DamageType.ICE],
	# 6.2.3 Four-Headed Hydra: resists Nature
	"four_headed_hydra": [DamageType.NATURE],
	# 6.2.4 Dark Blood Dragon: resists Fire
	"dark_blood_dragon": [DamageType.FIRE],
	# 6.2.5 Sky Serpent: resists Ice/Nature
	"sky_serpent": [DamageType.ICE, DamageType.NATURE],
	# 6.2.6 Frost Valkyrie: resists Ice
	"frost_valkyrie": [DamageType.ICE],
	# 6.2.7 Dark Magic Wizard: resists Dark
	"dark_magic_wizard": [DamageType.DARK],
	# 6.2.8 Demon of Darkness: resists Dark/Fire
	"demon_of_darkness": [DamageType.DARK, DamageType.FIRE],
	# 6.2.9 Elven Archer: resists Nature
	"elven_archer": [DamageType.NATURE],
	# 6.2.10 Celestial Cleric: resists Holy/Dark (no weakness)
	"celestial_cleric": [DamageType.HOLY, DamageType.DARK],
	# 6.2.11 Shadow Assassin: resists Dark
	"shadow_assassin": [DamageType.DARK],
	# 6.2.12 Infernal Soul: resists Fire
	"infernal_soul": [DamageType.FIRE],
	# Additional troops
	"phoenix": [DamageType.FIRE, DamageType.HOLY],
	"frost_giant": [DamageType.ICE],
	"necromancer": [DamageType.DARK],
	"griffin": [DamageType.NATURE],
	"frost_revenant": [DamageType.ICE, DamageType.DARK],
	"ironclad_golem": [DamageType.PHYSICAL]
}

const TROOP_WEAKNESSES: Dictionary = {
	# Phase 6.2 - Troop Type Assignments (Weaknesses)
	# 6.2.1 Medieval Knight: weak to Fire/Dark
	"medieval_knight": [DamageType.FIRE, DamageType.DARK],
	# 6.2.2 Stone Giant: weak to Nature
	"stone_giant": [DamageType.NATURE],
	# 6.2.3 Four-Headed Hydra: weak to Ice/Fire
	"four_headed_hydra": [DamageType.ICE, DamageType.FIRE],
	# 6.2.4 Dark Blood Dragon: weak to Ice
	"dark_blood_dragon": [DamageType.ICE],
	# 6.2.5 Sky Serpent: weak to Fire
	"sky_serpent": [DamageType.FIRE],
	# 6.2.6 Frost Valkyrie: weak to Fire/Dark
	"frost_valkyrie": [DamageType.FIRE, DamageType.DARK],
	# 6.2.7 Dark Magic Wizard: weak to Holy
	"dark_magic_wizard": [DamageType.HOLY],
	# 6.2.8 Demon of Darkness: weak to Holy
	"demon_of_darkness": [DamageType.HOLY],
	# 6.2.9 Elven Archer: weak to Dark/Fire
	"elven_archer": [DamageType.DARK, DamageType.FIRE],
	# 6.2.10 Celestial Cleric: no weakness (empty array)
	"celestial_cleric": [],
	# 6.2.11 Shadow Assassin: weak to Holy
	"shadow_assassin": [DamageType.HOLY],
	# 6.2.12 Infernal Soul: weak to Ice/Holy
	"infernal_soul": [DamageType.ICE, DamageType.HOLY],
	# Additional troops
	"phoenix": [DamageType.ICE, DamageType.DARK],
	"frost_giant": [DamageType.FIRE],
	"necromancer": [DamageType.HOLY, DamageType.FIRE],
	"griffin": [DamageType.ICE],
	"frost_revenant": [DamageType.FIRE, DamageType.HOLY],
	"ironclad_golem": [DamageType.NATURE]
}

const TROOP_IMMUNITIES: Dictionary = {
	"phoenix": [DamageType.FIRE],  # Phoenix is immune to fire
	"frost_giant": [DamageType.ICE]  # Frost Giant is immune to ice
}


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

## Get the troop type for a given troop ID
static func get_troop_type(troop_id: String) -> TroopType:
	return TROOP_TYPES.get(troop_id, TroopType.HUMANOID)


## Get effectiveness multiplier for a damage type against a troop
## Returns: float (0.0, 0.5, 1.0, or 1.5)
static func get_effectiveness(attack_type: DamageType, defender_id: String) -> float:
	# Check for immunity first (troop-specific)
	var immunities = TROOP_IMMUNITIES.get(defender_id, [])
	if attack_type in immunities:
		return IMMUNE
	
	# Check for troop-specific resistance
	var resistances = TROOP_RESISTANCES.get(defender_id, [])
	if attack_type in resistances:
		return NOT_EFFECTIVE
	
	# Check for troop-specific weakness
	var weaknesses = TROOP_WEAKNESSES.get(defender_id, [])
	if attack_type in weaknesses:
		return SUPER_EFFECTIVE
	
	# Fall back to type-based effectiveness
	var defender_type = get_troop_type(defender_id)
	var type_data = EFFECTIVENESS.get(attack_type, {})
	
	var strong_against = type_data.get("strong_against", [])
	var weak_against = type_data.get("weak_against", [])
	
	if defender_type in strong_against:
		return SUPER_EFFECTIVE
	elif defender_type in weak_against:
		return NOT_EFFECTIVE
	else:
		return NORMAL_EFFECTIVE


## Get effectiveness as a human-readable string
static func get_effectiveness_text(attack_type: DamageType, defender_id: String) -> String:
	var mult = get_effectiveness(attack_type, defender_id)
	
	if mult == IMMUNE:
		return "Immune"
	elif mult == NOT_EFFECTIVE:
		return "Not Very Effective"
	elif mult == SUPER_EFFECTIVE:
		return "Super Effective!"
	else:
		return "Normal"


## Get the damage type name as a string
static func get_damage_type_name(damage_type: DamageType) -> String:
	match damage_type:
		DamageType.PHYSICAL: return "Physical"
		DamageType.FIRE: return "Fire"
		DamageType.ICE: return "Ice"
		DamageType.DARK: return "Dark"
		DamageType.HOLY: return "Holy"
		DamageType.NATURE: return "Nature"
		_: return "Unknown"


## Get all damage types a troop resists
static func get_resistances(troop_id: String) -> Array:
	return TROOP_RESISTANCES.get(troop_id, [])


## Get all damage types a troop is weak to
static func get_weaknesses(troop_id: String) -> Array:
	return TROOP_WEAKNESSES.get(troop_id, [])


## Get all damage types a troop is immune to
static func get_immunities(troop_id: String) -> Array:
	return TROOP_IMMUNITIES.get(troop_id, [])


## Get a summary of a troop's type matchups
static func get_type_summary(troop_id: String) -> Dictionary:
	return {
		"troop_type": get_troop_type(troop_id),
		"resistances": get_resistances(troop_id),
		"weaknesses": get_weaknesses(troop_id),
		"immunities": get_immunities(troop_id)
	}
