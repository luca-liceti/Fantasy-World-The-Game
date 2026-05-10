## Status Effects
## Defines all status effects for the D&D × Pokémon hybrid combat system
class_name StatusEffects
extends RefCounted

# =============================================================================
# STATUS EFFECT CLASS
# =============================================================================

class StatusEffect:
	var effect_id: String
	var effect_name: String
	var duration_turns: int
	var damage_per_turn: int
	var stat_modifiers: Dictionary  # e.g., {"atk": -0.2, "def": -0.1}
	var prevents_action: bool
	var prevents_movement: bool
	var remaining_turns: int
	
	func _init(data: Dictionary = {}) -> void:
		effect_id = data.get("effect_id", "")
		effect_name = data.get("effect_name", "Unknown")
		duration_turns = data.get("duration_turns", 1)
		damage_per_turn = data.get("damage_per_turn", 0)
		stat_modifiers = data.get("stat_modifiers", {})
		prevents_action = data.get("prevents_action", false)
		prevents_movement = data.get("prevents_movement", false)
		remaining_turns = duration_turns
	
	func tick() -> bool:
		remaining_turns -= 1
		return remaining_turns <= 0
	
	func is_expired() -> bool:
		return remaining_turns <= 0

# =============================================================================
# STATUS EFFECT DEFINITIONS
# =============================================================================

const EFFECTS: Dictionary = {
	# Phase 8.1.1 - Stunned: Skip next action, 1 turn, auto-cure
	"stunned": {
		"effect_id": "stunned",
		"effect_name": "Stunned",
		"duration_turns": 1,
		"damage_per_turn": 0,
		"stat_modifiers": {},
		"prevents_action": true,
		"prevents_movement": true,
		"description": "Cannot act or move. Auto-cures after 1 turn.",
		"color": Color(1.0, 1.0, 0.0)
	},
	# Burned: 10 damage at turn start, 3 turns (combat_reference.md)
	"burned": {
		"effect_id": "burned",
		"effect_name": "Burned",
		"duration_turns": 3,
		"damage_per_turn": 10,
		"stat_modifiers": {},
		"prevents_action": false,
		"prevents_movement": false,
		"description": "Takes 10 damage per turn for 3 turns.",
		"color": Color(1.0, 0.4, 0.0)
	},
	# Poisoned: 8 damage at turn start, 4 turns (combat_reference.md)
	"poisoned": {
		"effect_id": "poisoned",
		"effect_name": "Poisoned",
		"duration_turns": 4,
		"damage_per_turn": 8,
		"stat_modifiers": {},
		"prevents_action": false,
		"prevents_movement": false,
		"description": "Takes 8 damage per turn for 4 turns.",
		"color": Color(0.5, 0.0, 0.5)
	},
	# Slowed: -2 Speed (flat), 2 turns (combat_reference.md)
	"slowed": {
		"effect_id": "slowed",
		"effect_name": "Slowed",
		"duration_turns": 2,
		"damage_per_turn": 0,
		"stat_modifiers": {"speed": -2},
		"prevents_action": false,
		"prevents_movement": false,
		"description": "Movement speed reduced by 2.",
		"color": Color(0.0, 0.5, 1.0)
	},
	# Cursed: -25% ATK, 3 turns (combat_reference.md)
	"cursed": {
		"effect_id": "cursed",
		"effect_name": "Cursed",
		"duration_turns": 3,
		"damage_per_turn": 0,
		"stat_modifiers": {"atk": -0.25},
		"prevents_action": false,
		"prevents_movement": false,
		"description": "ATK reduced by 25% for 3 turns.",
		"color": Color(0.3, 0.0, 0.3)
	},
	# Terrified: -25% DEF, 2 turns (combat_reference.md)
	"terrified": {
		"effect_id": "terrified",
		"effect_name": "Terrified",
		"duration_turns": 2,
		"damage_per_turn": 0,
		"stat_modifiers": {"def": -0.25},
		"prevents_action": false,
		"prevents_movement": false,
		"description": "DEF reduced by 25% for 2 turns.",
		"color": Color(0.2, 0.2, 0.2)
	},
	# Phase 8.1.7 - Rooted: Cannot move (can still attack), 1-2 turns
	"rooted": {
		"effect_id": "rooted",
		"effect_name": "Rooted",
		"duration_turns": 2,
		"damage_per_turn": 0,
		"stat_modifiers": {},
		"prevents_action": false,
		"prevents_movement": true,
		"description": "Cannot move, but can still attack.",
		"color": Color(0.4, 0.3, 0.0)
	},
	# Stealth: 3 turns, next attack guaranteed crit, attacking ends it (combat_reference.md)
	"stealth": {
		"effect_id": "stealth",
		"effect_name": "Stealth",
		"duration_turns": 3,
		"damage_per_turn": 0,
		"stat_modifiers": {},
		"prevents_action": false,
		"prevents_movement": false,
		"description": "Stealth for 3 turns. Next attack is a guaranteed critical. Attacking ends Stealth.",
		"is_buff": true,
		"removed_on_attack": true,
		"color": Color(0.5, 0.5, 0.5)
	}
}

# =============================================================================
# IMMUNITY MAPPING
# Phase 8.2 - Condition Immunities
# =============================================================================

## Immunities per combat_reference.md Section 11.
## Shadow Assassin starts each match with Stealth (applied at spawn, not an immunity).
const IMMUNITIES: Dictionary = {
	"infernal_soul": ["burned"],
	"frost_valkyrie": ["slowed"],
	"celestial_cleric": ["cursed"]
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

static func get_effect_data(effect_id: String) -> Dictionary:
	return EFFECTS.get(effect_id, {})

static func create_effect(effect_id: String) -> StatusEffect:
	var data = get_effect_data(effect_id)
	if data.is_empty():
		push_error("StatusEffects: Unknown effect ID: " + effect_id)
		return null
	return StatusEffect.new(data)

static func is_immune(troop_id: String, effect_id: String) -> bool:
	var immune_list = IMMUNITIES.get(troop_id, [])
	return effect_id in immune_list

static func get_effect_color(effect_id: String) -> Color:
	return get_effect_data(effect_id).get("color", Color.WHITE)

static func is_debuff(effect_id: String) -> bool:
	var data = get_effect_data(effect_id)
	return not data.get("is_buff", false)

static func get_all_effect_ids() -> Array:
	return EFFECTS.keys()
