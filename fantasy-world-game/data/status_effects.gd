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
	# Phase 8.1.2 - Burned: 20 damage at turn start, -10% ATK, 3 turns
	"burned": {
		"effect_id": "burned",
		"effect_name": "Burned",
		"duration_turns": 3,
		"damage_per_turn": 20,  # Updated from 10 to 20 per Phase 8.1.2
		"stat_modifiers": {"atk": -0.1},
		"prevents_action": false,
		"prevents_movement": false,
		"description": "Takes 20 damage per turn. ATK reduced by 10%.",
		"color": Color(1.0, 0.4, 0.0)
	},
	# Phase 8.1.3 - Poisoned: 15 damage at turn start, 3 turns
	"poisoned": {
		"effect_id": "poisoned",
		"effect_name": "Poisoned",
		"duration_turns": 3,  # Updated from 4 to 3 per Phase 8.1.3
		"damage_per_turn": 15,  # Updated from 8 to 15 per Phase 8.1.3
		"stat_modifiers": {},
		"prevents_action": false,
		"prevents_movement": false,
		"description": "Takes 15 damage per turn.",
		"color": Color(0.5, 0.0, 0.5)
	},
	# Phase 8.1.4 - Slowed: -1 to -2 Speed, Disadvantage on attacks, 2 turns
	"slowed": {
		"effect_id": "slowed",
		"effect_name": "Slowed",
		"duration_turns": 2,
		"damage_per_turn": 0,
		"stat_modifiers": {"speed": -0.5},
		"prevents_action": false,
		"prevents_movement": false,
		"gives_disadvantage": true,  # Added per Phase 8.1.4
		"description": "Movement speed halved. Attacks have disadvantage.",
		"color": Color(0.0, 0.5, 1.0)
	},
	# Phase 8.1.5 - Cursed: Take +30% damage from all sources, 2 turns
	"cursed": {
		"effect_id": "cursed",
		"effect_name": "Cursed",
		"duration_turns": 2,  # Updated from 3 to 2 per Phase 8.1.5
		"damage_per_turn": 0,
		"stat_modifiers": {},
		"damage_taken_multiplier": 1.3,  # +30% damage received per Phase 8.1.5
		"prevents_action": false,
		"prevents_movement": false,
		"description": "Takes +30% damage from all sources.",
		"color": Color(0.3, 0.0, 0.3)
	},
	# Phase 8.1.6 - Terrified: -25% ATK, 2 turns
	"terrified": {
		"effect_id": "terrified",
		"effect_name": "Terrified",
		"duration_turns": 2,
		"damage_per_turn": 0,
		"stat_modifiers": {"atk": -0.25},  # Updated to -25% per Phase 8.1.6
		"prevents_action": false,
		"prevents_movement": false,
		"description": "ATK reduced by 25%.",
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
	# Phase 8.1.8 - Stealth: Cannot be targeted, 1 turn, attacking ends it
	"stealth": {
		"effect_id": "stealth",
		"effect_name": "Stealth",
		"duration_turns": 1,
		"damage_per_turn": 0,
		"stat_modifiers": {},
		"prevents_action": false,
		"prevents_movement": false,
		"description": "Invisible. Next attack is guaranteed critical. Attacking ends stealth.",
		"is_buff": true,
		"removed_on_attack": true,  # Added per Phase 8.1.8
		"color": Color(0.5, 0.5, 0.5)
	}
}

# =============================================================================
# IMMUNITY MAPPING
# Phase 8.2 - Condition Immunities
# =============================================================================

const IMMUNITIES: Dictionary = {
	# Phase 8.2.1 - Tanks immune to Terrified
	"medieval_knight": ["terrified"],
	"stone_giant": ["terrified"],
	"four_headed_hydra": ["terrified", "poisoned"],
	
	# Phase 8.2.2 - Undead/Demon immune to Poisoned
	"demon_of_darkness": ["poisoned"],
	"infernal_soul": ["burned", "poisoned"],
	"necromancer": ["poisoned", "cursed"],
	
	# Phase 8.2.3 - Air Units immune to Rooted
	"dark_blood_dragon": ["rooted", "burned", "terrified"],
	"sky_serpent": ["rooted"],
	"frost_valkyrie": ["rooted"],
	
	# Other immunities
	"phoenix": ["burned", "rooted", "poisoned"],
	"frost_giant": ["slowed"],
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
