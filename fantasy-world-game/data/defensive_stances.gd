## Defensive Stances
## Defines the 4 defensive stance options for defenders in combat
class_name DefensiveStances
extends RefCounted

# =============================================================================
# DEFENSIVE STANCE ENUM
# =============================================================================

enum DefensiveStance {
	BRACE,      # +3 DEF, 0.8x damage taken
	DODGE,      # +5 to evasion roll
	COUNTER,    # 50% ATK damage on miss
	ENDURE      # Survive at 1 HP (once per combat)
}

# =============================================================================
# STANCE DATA
# =============================================================================

const STANCE_DATA: Dictionary = {
	DefensiveStance.BRACE: {
		"name": "Brace",
		"description": "Hunker down and brace for impact. Reduces incoming damage.",
		"def_bonus": 3,
		"evasion_bonus": 0,
		"damage_multiplier": 0.8,
		"counter_damage_percent": 0.0,
		"survives_lethal": false,
		"uses_per_combat": -1,
		"color": Color(0.3, 0.5, 0.8)
	},
	DefensiveStance.DODGE: {
		"name": "Dodge",
		"description": "Attempt to dodge the incoming attack entirely.",
		"def_bonus": 0,
		"evasion_bonus": 5,
		"damage_multiplier": 1.0,
		"counter_damage_percent": 0.0,
		"survives_lethal": false,
		"uses_per_combat": -1,
		"color": Color(0.2, 0.8, 0.2)
	},
	DefensiveStance.COUNTER: {
		"name": "Counter",
		"description": "Prepare a counterattack. If the enemy misses, deal 50% ATK damage.",
		"def_bonus": 0,
		"evasion_bonus": 0,
		"damage_multiplier": 1.0,
		"counter_damage_percent": 0.5,
		"survives_lethal": false,
		"uses_per_combat": -1,
		"color": Color(0.8, 0.4, 0.1)
	},
	DefensiveStance.ENDURE: {
		"name": "Endure",
		"description": "If killed, survive at 1 HP instead. Once per combat.",
		"def_bonus": 0,
		"evasion_bonus": 0,
		"damage_multiplier": 1.0,
		"counter_damage_percent": 0.0,
		"survives_lethal": true,
		"uses_per_combat": 1,
		"color": Color(0.8, 0.2, 0.2)
	}
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

static func get_stance_data(stance: DefensiveStance) -> Dictionary:
	return STANCE_DATA.get(stance, STANCE_DATA[DefensiveStance.BRACE])

static func get_stance_name(stance: DefensiveStance) -> String:
	return get_stance_data(stance).get("name", "Unknown")

static func get_defense_bonus(stance: DefensiveStance) -> int:
	return get_stance_data(stance).get("def_bonus", 0)

static func get_evasion_bonus(stance: DefensiveStance) -> int:
	return get_stance_data(stance).get("evasion_bonus", 0)

static func get_damage_multiplier(stance: DefensiveStance) -> float:
	return get_stance_data(stance).get("damage_multiplier", 1.0)

static func get_counter_damage_percent(stance: DefensiveStance) -> float:
	return get_stance_data(stance).get("counter_damage_percent", 0.0)

static func survives_lethal(stance: DefensiveStance) -> bool:
	return get_stance_data(stance).get("survives_lethal", false)

static func get_uses_per_combat(stance: DefensiveStance) -> int:
	return get_stance_data(stance).get("uses_per_combat", -1)

static func can_use_stance(stance: DefensiveStance, uses_remaining: int) -> bool:
	var max_uses = get_uses_per_combat(stance)
	if max_uses == -1:
		return true
	return uses_remaining > 0

static func get_stance_color(stance: DefensiveStance) -> Color:
	return get_stance_data(stance).get("color", Color.WHITE)

static func get_all_stances() -> Array:
	return [DefensiveStance.BRACE, DefensiveStance.DODGE, DefensiveStance.COUNTER, DefensiveStance.ENDURE]

static func calculate_dc_modifier(stance: DefensiveStance) -> int:
	var data = get_stance_data(stance)
	return data.get("def_bonus", 0) + data.get("evasion_bonus", 0)

static func apply_stance_to_damage(stance: DefensiveStance, base_damage: int, current_hp: int) -> Dictionary:
	var data = get_stance_data(stance)
	var modified_damage = int(base_damage * data["damage_multiplier"])
	var survived_lethal = false
	if data["survives_lethal"] and current_hp - modified_damage <= 0:
		modified_damage = current_hp - 1
		survived_lethal = true
	return {"damage": max(1, modified_damage), "survived_lethal": survived_lethal}

static func calculate_counter_damage(stance: DefensiveStance, defender_atk: int) -> int:
	var counter_percent = get_counter_damage_percent(stance)
	if counter_percent > 0:
		return int(defender_atk * counter_percent)
	return 0
