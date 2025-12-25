## Damage Calculation System
## Implements the damage formula for the D&D × Pokémon hybrid combat system
## Formula: BASE × Type × Position ÷ (1 + DEF/80) × Crit
class_name DamageCalculation
extends RefCounted

# =============================================================================
# CONSTANTS
# =============================================================================

## Defense divisor constant (DEF / 80 in denominator)
const DEF_DIVISOR_BASE: float = 80.0

## Minimum damage (even with perfect defense)
const MIN_DAMAGE: int = 1

## Critical hit damage multiplier (1.5x per plan Phase 5.1.5)
const CRIT_MULTIPLIER: float = 1.5

## Magic damage ignores this percentage of DEF
const MAGIC_DEF_IGNORE: float = 0.25

# =============================================================================
# DAMAGE FORMULA STEPS
# =============================================================================

## Step 1: Calculate BASE DAMAGE
## BASE DAMAGE = ATK × Move Power%
static func calculate_base_damage(atk: float, power_percent: float) -> float:
	return atk * power_percent


## Step 2: Calculate TYPE DAMAGE
## TYPE DAMAGE = BASE DAMAGE × Type Effectiveness Multiplier
static func calculate_type_damage(base_damage: float, type_effectiveness: float) -> float:
	return base_damage * type_effectiveness


## Step 3: Calculate DEFENSE REDUCTION
## DEFENSE REDUCTION = TYPE DAMAGE ÷ (1 + DEF / 80)
## This formula ensures damage is never reduced to 0
static func calculate_defense_reduction(type_damage: float, defender_def: float, is_magic: bool = false) -> float:
	var effective_def = defender_def
	
	# Magic damage ignores 25% of DEF
	if is_magic:
		effective_def = defender_def * (1.0 - MAGIC_DEF_IGNORE)
	
	# Divisor-based defense (never reduces damage to 0)
	var divisor = 1.0 + (effective_def / DEF_DIVISOR_BASE)
	return type_damage / divisor


## Step 4: Calculate FINAL DAMAGE
## FINAL DAMAGE = max(DEFENSE REDUCTION, 1)
static func calculate_final_damage(defense_reduction: float) -> int:
	return max(MIN_DAMAGE, int(defense_reduction))


## Step 5: Calculate CRITICAL DAMAGE
## CRITICAL DAMAGE = FINAL DAMAGE × 1.5
static func apply_critical_multiplier(damage: int) -> int:
	return int(float(damage) * CRIT_MULTIPLIER)


# =============================================================================
# COMPLETE DAMAGE PIPELINE
# =============================================================================

## Calculate damage using the complete formula
## Returns: Dictionary with all damage components for UI display
static func calculate_damage(
	attacker_atk: float,
	move_power_percent: float,
	type_effectiveness: float,
	defender_def: float,
	is_critical: bool,
	is_magic: bool = false,
	positioning_bonus: float = 0.0
) -> Dictionary:
	# Step 1: BASE DAMAGE = ATK × Move Power%
	var base_damage = calculate_base_damage(attacker_atk, move_power_percent)
	
	# Apply positioning bonus (e.g., +10% from high ground)
	var positioned_damage = base_damage * (1.0 + positioning_bonus)
	
	# Step 2: TYPE DAMAGE = BASE × Type Effectiveness
	var type_damage = calculate_type_damage(positioned_damage, type_effectiveness)
	
	# Step 3: DEFENSE REDUCTION = TYPE DAMAGE ÷ (1 + DEF / 80)
	var reduced_damage = calculate_defense_reduction(type_damage, defender_def, is_magic)
	
	# Step 4: FINAL DAMAGE = max(reduced, 1)
	var final_damage = calculate_final_damage(reduced_damage)
	
	# Step 5: Apply critical multiplier if applicable
	var crit_damage = final_damage
	if is_critical:
		crit_damage = apply_critical_multiplier(final_damage)
	
	return {
		# Damage values at each step
		"base_damage": base_damage,
		"positioned_damage": positioned_damage,
		"type_damage": type_damage,
		"reduced_damage": reduced_damage,
		"final_damage": final_damage if not is_critical else crit_damage,
		
		# Input values (for display)
		"attacker_atk": attacker_atk,
		"move_power_percent": move_power_percent,
		"type_effectiveness": type_effectiveness,
		"defender_def": defender_def,
		"positioning_bonus": positioning_bonus,
		
		# Flags
		"is_critical": is_critical,
		"is_magic": is_magic,
		
		# For critical hits, also store the non-crit value
		"pre_crit_damage": final_damage,
		"crit_multiplier": CRIT_MULTIPLIER if is_critical else 1.0
	}


## Simplified calculation for quick damage computation
## Returns just the final damage number
static func quick_calculate(
	attacker_atk: float,
	move_power_percent: float,
	type_effectiveness: float,
	defender_def: float,
	is_critical: bool = false,
	is_magic: bool = false
) -> int:
	var result = calculate_damage(
		attacker_atk,
		move_power_percent,
		type_effectiveness,
		defender_def,
		is_critical,
		is_magic,
		0.0
	)
	return result["final_damage"]


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

## Get type effectiveness from move and defender
static func get_type_effectiveness(move: MoveData.Move, defender_troop_id: String) -> float:
	if move == null:
		return 1.0
	
	# Convert MoveData.DamageType to TypeEffectiveness.DamageType
	var te_damage_type: TypeEffectiveness.DamageType
	match move.damage_type:
		MoveData.DamageType.PHYSICAL: te_damage_type = TypeEffectiveness.DamageType.PHYSICAL
		MoveData.DamageType.FIRE: te_damage_type = TypeEffectiveness.DamageType.FIRE
		MoveData.DamageType.ICE: te_damage_type = TypeEffectiveness.DamageType.ICE
		MoveData.DamageType.DARK: te_damage_type = TypeEffectiveness.DamageType.DARK
		MoveData.DamageType.HOLY: te_damage_type = TypeEffectiveness.DamageType.HOLY
		MoveData.DamageType.NATURE: te_damage_type = TypeEffectiveness.DamageType.NATURE
		_: te_damage_type = TypeEffectiveness.DamageType.PHYSICAL
	
	return TypeEffectiveness.get_effectiveness(te_damage_type, defender_troop_id)


## Check if move deals magic damage (ignores DEF)
static func is_magic_damage(move: MoveData.Move) -> bool:
	if move == null:
		return false
	
	# Dark, Holy, and Nature are considered magic damage
	return move.damage_type in [
		MoveData.DamageType.DARK,
		MoveData.DamageType.HOLY,
		MoveData.DamageType.NATURE
	]


## Calculate damage from a move against a defender troop
## High-level helper that gets all needed values from nodes
static func calculate_move_damage(attacker: Node, move: MoveData.Move, defender: Node, is_critical: bool = false, positioning_bonus: float = 0.0) -> Dictionary:
	# Get ATK (with stat stages)
	var atk: float = 50.0
	if attacker and attacker.has_method("get_modified_stat"):
		atk = attacker.get_modified_stat("atk")
	elif attacker and "current_atk" in attacker:
		atk = float(attacker.current_atk)
	
	# Get move power
	var power: float = 1.0
	if move:
		power = move.power_percent
	
	# Get type effectiveness
	var type_eff: float = 1.0
	if move and defender and "troop_id" in defender:
		type_eff = get_type_effectiveness(move, defender.troop_id)
	
	# Get DEF (with stat stages)
	var def: float = 0.0
	if defender and defender.has_method("get_modified_stat"):
		def = defender.get_modified_stat("def")
	elif defender and "current_def" in defender:
		def = float(defender.current_def)
	
	# Check if magic damage
	var is_magic = is_magic_damage(move)
	
	return calculate_damage(atk, power, type_eff, def, is_critical, is_magic, positioning_bonus)


# =============================================================================
# DAMAGE DISPLAY HELPERS
# =============================================================================

## Generate a human-readable breakdown of the damage calculation
static func get_damage_breakdown(result: Dictionary) -> String:
	var lines: Array[String] = []
	
	lines.append("=== Damage Calculation ===")
	lines.append("ATK: %.0f × Power: %.0f%% = %.1f (Base)" % [
		result["attacker_atk"],
		result["move_power_percent"] * 100,
		result["base_damage"]
	])
	
	if result["positioning_bonus"] > 0:
		lines.append("+ Positioning: +%.0f%% = %.1f" % [
			result["positioning_bonus"] * 100,
			result["positioned_damage"]
		])
	
	var type_text = _get_type_effectiveness_text(result["type_effectiveness"])
	lines.append("× Type: %.1fx (%s) = %.1f" % [
		result["type_effectiveness"],
		type_text,
		result["type_damage"]
	])
	
	lines.append("÷ Defense: (1 + %.0f/80) = %.1f" % [
		result["defender_def"],
		result["reduced_damage"]
	])
	
	if result["is_critical"]:
		lines.append("× Critical: %.1fx = %d" % [
			result["crit_multiplier"],
			result["final_damage"]
		])
	
	lines.append("FINAL DAMAGE: %d" % result["final_damage"])
	
	return "\n".join(lines)


## Get text for type effectiveness
static func _get_type_effectiveness_text(mult: float) -> String:
	if mult >= 1.5:
		return "Super Effective!"
	elif mult <= 0.5 and mult > 0:
		return "Not Very Effective"
	elif mult == 0:
		return "Immune"
	else:
		return "Normal"


## Get effectiveness color for UI (returns hex code)
static func get_effectiveness_color(mult: float) -> String:
	if mult >= 1.5:
		return "#00FF00"  # Green - Super Effective
	elif mult <= 0.5 and mult > 0:
		return "#FF6600"  # Orange - Not Very Effective
	elif mult == 0:
		return "#888888"  # Gray - Immune
	else:
		return "#FFFFFF"  # White - Normal
