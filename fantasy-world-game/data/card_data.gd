## Card/Troop Definitions
## Contains all 12 troop types with their complete stats and abilities
class_name CardData
extends RefCounted

# =============================================================================
# ROLE ENUM
# =============================================================================
enum Role {
	GROUND_TANK,
	AIR_HYBRID,
	RANGED_MAGIC,
	FLEX_SUPPORT
}

# =============================================================================
# RANGE TYPE ENUM
# =============================================================================
enum RangeType {
	MELEE,
	RANGED,
	MAGIC,
	AIR,
	HYBRID,
	SUPPORT
}

# =============================================================================
# SPECIAL ABILITY ENUM
# =============================================================================
enum Ability {
	NONE,
	MULTI_STRIKE,    # Attacks 2 adjacent enemies
	ANTI_AIR,        # Can attack air units
	ANTI_AIR_2X,     # Deals double damage to air units
	MAGIC,           # Ignores 25% DEF
	HEAL,            # Heals ally in range
	DEATH_BURST      # Damage to adjacent enemies on death
}

# =============================================================================
# TROOP DATA - All 12 Troops
# =============================================================================
const TROOPS: Dictionary = {
	# =========================================================================
	# GROUND TANK ROLE (pick 1)
	# =========================================================================
	"medieval_knight": {
		"name": "Medieval Knight",
		"role": Role.GROUND_TANK,
		"hp": 150,
		"atk": 80,
		"def": 130,
		"range": 1,
		"range_type": RangeType.MELEE,
		"speed": 2,
		"mana": 5,
		"ability": Ability.NONE,
		"ability_description": "",
		"description": "A stalwart defender clad in heavy armor. Excels in holding the line.",
		"damage_type": "PHYSICAL",
		"resistances": [],
		"weaknesses": ["DARK"]
	},
	"stone_giant": {
		"name": "Stone Giant",
		"role": Role.GROUND_TANK,
		"hp": 220,
		"atk": 90,
		"def": 150,
		"range": 1,
		"range_type": RangeType.MELEE,
		"speed": 1,
		"mana": 8,
		"ability": Ability.NONE,
		"ability_description": "",
		"description": "A towering colossus of living rock. Slow but nearly indestructible.",
		"damage_type": "PHYSICAL",
		"resistances": ["PHYSICAL", "FIRE"],
		"weaknesses": ["NATURE"]
	},
	"four_headed_hydra": {
		"name": "Four-Headed Hydra",
		"role": Role.GROUND_TANK,
		"hp": 200,
		"atk": 120,
		"def": 120,
		"range": 1,
		"range_type": RangeType.MELEE,
		"speed": 1,
		"mana": 9,
		"ability": Ability.MULTI_STRIKE,
		"ability_description": "Multi-Strike: Attacks 2 adjacent enemies simultaneously.",
		"description": "A fearsome beast with four snapping heads. Can attack multiple foes at once.",
		"damage_type": "NATURE",
		"resistances": ["NATURE"],
		"weaknesses": ["FIRE"]
	},
	
	# =========================================================================
	# AIR/HYBRID ROLE (pick 1)
	# =========================================================================
	"dark_blood_dragon": {
		"name": "Dark Blood Dragon",
		"role": Role.AIR_HYBRID,
		"hp": 140,
		"atk": 110,
		"def": 70,
		"range": 2,
		"range_type": RangeType.AIR,
		"speed": 4,
		"mana": 8,
		"ability": Ability.NONE,
		"ability_description": "",
		"description": "A corrupted dragon wreathed in dark flames. Dominates the skies.",
		"damage_type": "FIRE",
		"resistances": ["FIRE", "DARK"],
		"weaknesses": ["ICE", "HOLY"]
	},
	"sky_serpent": {
		"name": "Sky Serpent",
		"role": Role.AIR_HYBRID,
		"hp": 100,
		"atk": 85,
		"def": 60,
		"range": 2,
		"range_type": RangeType.AIR,
		"speed": 5,
		"mana": 5,
		"ability": Ability.NONE,
		"ability_description": "",
		"description": "A swift aerial predator. Lightning fast but fragile.",
		"damage_type": "PHYSICAL",
		"resistances": [],
		"weaknesses": ["ICE"]
	},
	"frost_valkyrie": {
		"name": "Frost Valkyrie",
		"role": Role.AIR_HYBRID,
		"hp": 120,
		"atk": 95,
		"def": 85,
		"range": 2,
		"range_type": RangeType.HYBRID,
		"speed": 4,
		"mana": 6,
		"ability": Ability.ANTI_AIR,
		"ability_description": "Anti-Air: Can attack air units from ground or air.",
		"description": "A warrior of ice who can fight in both realms. Versatile and balanced.",
		"damage_type": "ICE",
		"resistances": ["ICE"],
		"weaknesses": ["FIRE"]
	},
	
	# =========================================================================
	# RANGED/MAGIC ROLE (pick 1) - All have Anti-Air
	# =========================================================================
	"dark_magic_wizard": {
		"name": "Dark Magic Wizard",
		"role": Role.RANGED_MAGIC,
		"hp": 75,
		"atk": 100,
		"def": 50,
		"range": 3,
		"range_type": RangeType.MAGIC,
		"speed": 2,
		"mana": 4,
		"ability": Ability.MAGIC,
		"ability_description": "Magic: Ignores 25% of target's DEF. Can attack air units.",
		"description": "A master of dark arts. Frail but devastating spell damage.",
		"damage_type": "DARK",
		"resistances": ["DARK"],
		"weaknesses": ["HOLY"]
	},
	"demon_of_darkness": {
		"name": "Demon of Darkness",
		"role": Role.RANGED_MAGIC,
		"hp": 130,
		"atk": 120,
		"def": 90,
		"range": 2,
		"range_type": RangeType.MAGIC,
		"speed": 2,
		"mana": 7,
		"ability": Ability.MAGIC,
		"ability_description": "Magic: Ignores 25% of target's DEF. Can attack air units.",
		"description": "A powerful demon from the shadow realm. High stats but expensive.",
		"damage_type": "DARK",
		"resistances": ["FIRE", "DARK"],
		"weaknesses": ["HOLY"]
	},
	"elven_archer": {
		"name": "Elven Archer",
		"role": Role.RANGED_MAGIC,
		"hp": 80,
		"atk": 90,
		"def": 55,
		"range": 3,
		"range_type": RangeType.RANGED,
		"speed": 3,
		"mana": 4,
		"ability": Ability.ANTI_AIR_2X,
		"ability_description": "Anti-Air 2x: Deals double damage to air units.",
		"description": "A skilled marksman with unmatched accuracy. Aerial units beware.",
		"damage_type": "PHYSICAL",
		"resistances": ["NATURE"],
		"weaknesses": ["DARK"]
	},
	
	# =========================================================================
	# FLEX ROLE - Support/Assassin (pick 1)
	# =========================================================================
	"celestial_cleric": {
		"name": "Celestial Cleric",
		"role": Role.FLEX_SUPPORT,
		"hp": 110,
		"atk": 55,
		"def": 100,
		"range": 2,
		"range_type": RangeType.SUPPORT,
		"speed": 2,
		"mana": 5,
		"ability": Ability.HEAL,
		"ability_description": "Heal: Restores 35 HP to ally in range.",
		"description": "A divine healer blessed by the heavens. Keeps allies fighting.",
		"damage_type": "HOLY",
		"resistances": ["HOLY"],
		"weaknesses": ["DARK"]
	},
	"shadow_assassin": {
		"name": "Shadow Assassin",
		"role": Role.FLEX_SUPPORT,
		"hp": 70,
		"atk": 115,
		"def": 45,
		"range": 1,
		"range_type": RangeType.MELEE,
		"speed": 5,
		"mana": 4,
		"ability": Ability.NONE,
		"ability_description": "",
		"description": "A deadly glass cannon. Strikes fast and hard but can't take hits.",
		"damage_type": "PHYSICAL",
		"resistances": ["DARK"],
		"weaknesses": ["HOLY"]
	},
	"infernal_soul": {
		"name": "Infernal Soul",
		"role": Role.FLEX_SUPPORT,
		"hp": 60,
		"atk": 85,
		"def": 40,
		"range": 1,
		"range_type": RangeType.MELEE,
		"speed": 5,
		"mana": 3,
		"ability": Ability.DEATH_BURST,
		"ability_description": "Death Burst: Deals 30 damage to all adjacent enemies on death.",
		"description": "A suicidal demon. Cheap and explosive, literally.",
		"damage_type": "FIRE",
		"resistances": ["FIRE", "DARK"],
		"weaknesses": ["HOLY", "ICE"]
	}
}

# =============================================================================
# NPC DATA
# =============================================================================
const NPCS: Dictionary = {
	"goblin": {
		"name": "Goblin",
		"hp": 50,
		"atk": 30,
		"def": 20,
		"gold_reward": 5,
		"xp_reward": 10,
		"rare_drop": "speed_potion",
		"drop_chance": 0.10  # 10%
	},
	"orc": {
		"name": "Orc",
		"hp": 100,
		"atk": 60,
		"def": 40,
		"gold_reward": 15,
		"xp_reward": 25,
		"rare_drop": "whetstone",
		"drop_chance": 0.15  # 15%
	},
	"troll": {
		"name": "Troll",
		"hp": 200,
		"atk": 80,
		"def": 60,
		"gold_reward": 30,
		"xp_reward": 50,
		"rare_drop": "phoenix_feather",
		"drop_chance": 0.20  # 20%
	}
}

# =============================================================================
# ITEMS DATA
# =============================================================================
const ITEMS: Dictionary = {
	"speed_potion": {
		"name": "Speed Potion",
		"description": "+1 Speed for 3 turns",
		"effect_type": "speed_buff",
		"value": 1,
		"duration": 3
	},
	"whetstone": {
		"name": "Whetstone",
		"description": "+10 ATK for next attack",
		"effect_type": "atk_buff",
		"value": 10,
		"duration": 1  # Next attack only
	},
	"phoenix_feather": {
		"name": "Phoenix Feather",
		"description": "Respawn one destroyed troop at spawn point",
		"effect_type": "respawn",
		"value": 0,
		"duration": 0
	}
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

## Get troop data by ID
static func get_troop(troop_id: String) -> Dictionary:
	return TROOPS.get(troop_id, {})


## Get all troops by role
static func get_troops_by_role(role: Role) -> Array:
	var result: Array = []
	for troop_id in TROOPS:
		if TROOPS[troop_id]["role"] == role:
			result.append({"id": troop_id, "data": TROOPS[troop_id]})
	return result


## Validate deck composition
## Returns: {"valid": bool, "errors": Array[String]}
static func validate_deck(troop_ids: Array) -> Dictionary:
	var errors: Array[String] = []
	
	# Must have exactly 4 cards
	if troop_ids.size() != 4:
		errors.append("Deck must contain exactly 4 cards")
	
	# Track roles selected
	var roles_selected: Dictionary = {
		Role.GROUND_TANK: 0,
		Role.AIR_HYBRID: 0,
		Role.RANGED_MAGIC: 0,
		Role.FLEX_SUPPORT: 0
	}
	
	var total_mana: int = 0
	
	for troop_id in troop_ids:
		var troop = get_troop(troop_id)
		if troop.is_empty():
			errors.append("Invalid troop: " + troop_id)
			continue
		
		roles_selected[troop["role"]] += 1
		total_mana += troop["mana"]
	
	# Check role requirements
	if roles_selected[Role.GROUND_TANK] != 1:
		errors.append("Must select exactly 1 Ground Tank")
	if roles_selected[Role.AIR_HYBRID] != 1:
		errors.append("Must select exactly 1 Air/Hybrid")
	if roles_selected[Role.RANGED_MAGIC] != 1:
		errors.append("Must select exactly 1 Ranged/Magic")
	if roles_selected[Role.FLEX_SUPPORT] != 1:
		errors.append("Must select exactly 1 Flex/Support")
	
	# Check mana limit
	if total_mana > GameConfig.MAX_DECK_MANA:
		errors.append("Total mana (" + str(total_mana) + ") exceeds maximum of " + str(GameConfig.MAX_DECK_MANA))
	
	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"total_mana": total_mana
	}


## Get NPC data by ID
static func get_npc(npc_id: String) -> Dictionary:
	return NPCS.get(npc_id, {})


## Get item data by ID
static func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})


## Get all troop IDs
static func get_all_troop_ids() -> Array:
	return TROOPS.keys()
