## Roll Resolution System
## Implements D&D-style d20 attack rolls with advantage/disadvantage
## Part of the D&D × Pokémon hybrid combat system
class_name RollResolution
extends RefCounted

# =============================================================================
# ENUMS
# =============================================================================

## Roll modes (normal, advantage, disadvantage)
enum RollMode {
	NORMAL,      # Roll 1d20
	ADVANTAGE,   # Roll 2d20, take higher
	DISADVANTAGE # Roll 2d20, take lower
}

## Roll result types
enum RollResult {
	CRITICAL_MISS,  # Natural 1
	MISS,           # Roll < DC
	HIT,            # Roll >= DC
	CRITICAL_HIT    # Natural 20
}

# =============================================================================
# CONSTANTS (mirrored from CombatBalanceConfig for clarity)
# =============================================================================

const DICE_TYPE: int = 20
const CRITICAL_HIT_THRESHOLD: int = 20    # Natural 20 only
const CRITICAL_MISS_THRESHOLD: int = 1    # Natural 1 only
const BASE_DC: int = 10                   # Base Defense Class
const STAT_DIVISOR: float = 10.0          # ATK/10, DEF/10 for modifiers

# =============================================================================
# ADVANTAGE SOURCES
# =============================================================================

## Check if attacker has advantage
## Returns: Dictionary with "has_advantage" and "sources" (array of reason strings)
static func check_advantage_sources(attacker: Node, defender: Node, hex_board: Node = null) -> Dictionary:
	var sources: Array[String] = []
	
	# 4.3.1 Flanking: Allied troop adjacent to target
	if hex_board and defender.current_hex and "coordinates" in defender.current_hex:
		var defender_neighbors = defender.current_hex.coordinates.get_all_neighbors()
		for coord in defender_neighbors:
			var tile = hex_board.get_tile_at(coord)
			if tile and tile.occupant and tile.occupant != attacker:
				if "owner_player_id" in tile.occupant and tile.occupant.owner_player_id == attacker.owner_player_id:
					sources.append("Flanking")
					break
	
	# 4.3.2 High Ground: Attacker on Hills/Peaks biome
	if attacker.current_hex and "biome_type" in attacker.current_hex:
		var biome = attacker.current_hex.biome_type
		if biome == Biomes.Type.HILLS or biome == Biomes.Type.PEAKS:
			sources.append("High Ground")
	
	# 4.3.3 Stealth: Attacker is invisible/hidden
	if attacker.has_method("is_stealthed") and attacker.is_stealthed():
		sources.append("Stealth")
	
	# 4.3.4 Target Stunned: Target has Stunned status
	if defender.has_method("has_status_effect") and defender.has_status_effect("stunned"):
		sources.append("Target Stunned")
	
	# 4.3.5 Target Surrounded: 3+ enemies adjacent to target
	if hex_board and defender.current_hex and "coordinates" in defender.current_hex:
		var enemy_count = 0
		var defender_neighbors = defender.current_hex.coordinates.get_all_neighbors()
		for coord in defender_neighbors:
			var tile = hex_board.get_tile_at(coord)
			if tile and tile.occupant:
				if "owner_player_id" in tile.occupant and tile.occupant.owner_player_id != defender.owner_player_id:
					enemy_count += 1
		if enemy_count >= 3:
			sources.append("Target Surrounded")
	
	return {
		"has_advantage": sources.size() > 0,
		"sources": sources
	}


## Check if attacker has disadvantage
## Returns: Dictionary with "has_disadvantage" and "sources" (array of reason strings)
static func check_disadvantage_sources(attacker: Node, defender: Node, hex_board: Node = null, attack_range: int = 1, max_range: int = 1) -> Dictionary:
	var sources: Array[String] = []
	
	# 4.4.1 Cover: Target on Forest/Swamp hex
	if defender.current_hex and "biome_type" in defender.current_hex:
		var biome = defender.current_hex.biome_type
		if biome == Biomes.Type.FOREST or biome == Biomes.Type.SWAMP:
			sources.append("Cover")
	
	# 4.4.2 Attacker Slowed: Attacker has Slowed status
	if attacker.has_method("has_status_effect") and attacker.has_status_effect("slowed"):
		sources.append("Attacker Slowed")
	
	# 4.4.3 Attacker Cursed: Attacker has Cursed status
	if attacker.has_method("has_status_effect") and attacker.has_status_effect("cursed"):
		sources.append("Attacker Cursed")
	
	# 4.4.4 Long Range: Ranged attack at maximum range
	if attack_range > 1 and attack_range >= max_range:
		sources.append("Long Range")
	
	# 4.4.5 Target Evasion: Target has active evasion buff
	if defender.has_method("has_evasion_buff") and defender.has_evasion_buff():
		sources.append("Target Evasion")
	elif defender.has_method("has_status_effect") and defender.has_status_effect("evasion"):
		sources.append("Target Evasion")
	
	return {
		"has_disadvantage": sources.size() > 0,
		"sources": sources
	}


## Determine final roll mode based on advantage/disadvantage
## Advantage and disadvantage cancel each other out
static func determine_roll_mode(attacker: Node, defender: Node, hex_board: Node = null, attack_range: int = 1, max_range: int = 1) -> Dictionary:
	var adv = check_advantage_sources(attacker, defender, hex_board)
	var dis = check_disadvantage_sources(attacker, defender, hex_board, attack_range, max_range)
	
	var mode: RollMode
	if adv["has_advantage"] and dis["has_disadvantage"]:
		# Cancel out
		mode = RollMode.NORMAL
	elif adv["has_advantage"]:
		mode = RollMode.ADVANTAGE
	elif dis["has_disadvantage"]:
		mode = RollMode.DISADVANTAGE
	else:
		mode = RollMode.NORMAL
	
	return {
		"mode": mode,
		"advantage_sources": adv["sources"],
		"disadvantage_sources": dis["sources"],
		"cancelled_out": adv["has_advantage"] and dis["has_disadvantage"]
	}


# =============================================================================
# ROLL MECHANICS
# =============================================================================

## Roll a single d20
static func roll_d20() -> int:
	return randi_range(1, DICE_TYPE)


## Roll with advantage (2d20 take higher)
static func roll_with_advantage() -> Dictionary:
	var roll1 = roll_d20()
	var roll2 = roll_d20()
	return {
		"rolls": [roll1, roll2],
		"result": max(roll1, roll2),
		"mode": RollMode.ADVANTAGE
	}


## Roll with disadvantage (2d20 take lower)
static func roll_with_disadvantage() -> Dictionary:
	var roll1 = roll_d20()
	var roll2 = roll_d20()
	return {
		"rolls": [roll1, roll2],
		"result": min(roll1, roll2),
		"mode": RollMode.DISADVANTAGE
	}


## Roll based on mode
static func roll_for_mode(mode: RollMode) -> Dictionary:
	match mode:
		RollMode.ADVANTAGE:
			return roll_with_advantage()
		RollMode.DISADVANTAGE:
			return roll_with_disadvantage()
		_:  # NORMAL
			var roll = roll_d20()
			return {
				"rolls": [roll],
				"result": roll,
				"mode": RollMode.NORMAL
			}


# =============================================================================
# ATTACK ROLL FORMULA
# =============================================================================

## Calculate attack roll
## ATTACK ROLL = d20 + (ATK ÷ 10) + Move Accuracy Modifier
static func calculate_attack_roll(attacker: Node, move: MoveData.Move, roll_mode: RollMode) -> Dictionary:
	# Roll the dice
	var dice_result = roll_for_mode(roll_mode)
	var natural_roll = dice_result["result"]
	
	# Get ATK stat and divide by 10
	var atk_stat: float = 0.0
	if attacker.has_method("get_modified_stat"):
		atk_stat = attacker.get_modified_stat("atk")
	elif "current_atk" in attacker:
		atk_stat = float(attacker.current_atk)
	var atk_modifier: int = int(atk_stat / STAT_DIVISOR)
	
	# Get move accuracy modifier
	var accuracy_modifier: int = 0
	if move:
		accuracy_modifier = move.accuracy_modifier
	
	# Calculate total
	var total_roll = natural_roll + atk_modifier + accuracy_modifier
	
	# Check critical states (based on natural roll, before modifiers)
	var is_crit_hit = natural_roll >= CRITICAL_HIT_THRESHOLD
	var is_crit_miss = natural_roll <= CRITICAL_MISS_THRESHOLD
	
	# Stealth guarantees crit (removes stealth after use)
	if attacker.has_method("is_stealthed") and attacker.is_stealthed():
		is_crit_hit = true
		if attacker.has_method("remove_status_effect"):
			attacker.remove_status_effect("stealth")
	
	return {
		"natural_roll": natural_roll,
		"dice_rolls": dice_result["rolls"],
		"roll_mode": roll_mode,
		"atk_modifier": atk_modifier,
		"accuracy_modifier": accuracy_modifier,
		"total_roll": total_roll,
		"is_critical_hit": is_crit_hit,
		"is_critical_miss": is_crit_miss
	}


## Calculate defense DC (Difficulty Class)
## TARGET DC = 10 + (DEF ÷ 10) + Cover Modifier + Stance Bonus
static func calculate_defense_dc(defender: Node, stance: int = 0, modifiers: Dictionary = {}) -> Dictionary:
	# Base DC
	var base_dc: int = BASE_DC
	
	# Get DEF stat and divide by 10
	var def_stat: float = 0.0
	if defender.has_method("get_modified_stat"):
		def_stat = defender.get_modified_stat("def")
	elif "current_def" in defender:
		def_stat = float(defender.current_def)
	var def_modifier: int = int(def_stat / STAT_DIVISOR)
	
	# Stance bonus (from DefensiveStances)
	var stance_bonus: int = 0
	if stance >= 0:
		stance_bonus = DefensiveStances.get_defense_bonus(stance) + DefensiveStances.get_evasion_bonus(stance)
	
	# Cover/positioning bonus from modifiers
	var positioning_bonus: int = modifiers.get("positioning_def_bonus", 0)
	
	# Calculate total DC
	var total_dc = base_dc + def_modifier + stance_bonus + positioning_bonus
	
	return {
		"base_dc": base_dc,
		"def_modifier": def_modifier,
		"stance_bonus": stance_bonus,
		"positioning_bonus": positioning_bonus,
		"total_dc": total_dc
	}


# =============================================================================
# HIT RESOLUTION
# =============================================================================

## Determine if attack hits and what type of result
## HIT CONDITION: ATTACK ROLL ≥ TARGET DC
static func resolve_hit(attack_result: Dictionary, defense_result: Dictionary) -> Dictionary:
	var natural_roll = attack_result["natural_roll"]
	var total_attack = attack_result["total_roll"]
	var total_dc = defense_result["total_dc"]
	var is_crit_hit = attack_result["is_critical_hit"]
	var is_crit_miss = attack_result["is_critical_miss"]
	
	var result_type: RollResult
	var hits: bool
	var damage_multiplier: float = 1.0
	var bypass_reactions: bool = false
	
	# 4.5.1 Natural 1 (Critical Miss): Attack automatically fails
	if is_crit_miss:
		result_type = RollResult.CRITICAL_MISS
		hits = false
		damage_multiplier = 0.0
	# 4.5.3 Natural 20 (Critical Hit): Auto-hit, ×1.5 damage, bypass reactions
	elif is_crit_hit:
		result_type = RollResult.CRITICAL_HIT
		hits = true
		damage_multiplier = CombatBalanceConfig.CRIT_DAMAGE_MULT  # 1.5x or 2.0x based on config
		bypass_reactions = true
	# 4.5.2 Normal roll: Compare to DC
	elif total_attack >= total_dc:
		result_type = RollResult.HIT
		hits = true
	else:
		result_type = RollResult.MISS
		hits = false
	
	return {
		"result_type": result_type,
		"hits": hits,
		"natural_roll": natural_roll,
		"total_attack": total_attack,
		"total_dc": total_dc,
		"margin": total_attack - total_dc,
		"damage_multiplier": damage_multiplier,
		"bypass_reactions": bypass_reactions,
		"is_critical_hit": is_crit_hit,
		"is_critical_miss": is_crit_miss
	}


# =============================================================================
# FULL RESOLUTION PIPELINE
# =============================================================================

## Complete attack resolution from start to finish
## Returns comprehensive result dictionary
static func resolve_attack(attacker: Node, defender: Node, move: MoveData.Move, stance: int = 0, hex_board: Node = null) -> Dictionary:
	# Step 1: Determine roll mode (advantage/disadvantage)
	var attack_range = 1
	var max_range = 1
	if attacker.has_method("get_attack_range"):
		attack_range = attacker.get_attack_range()
		max_range = attack_range
	elif "current_range" in attacker:
		attack_range = attacker.current_range
		max_range = attack_range
	
	var roll_mode_result = determine_roll_mode(attacker, defender, hex_board, attack_range, max_range)
	var roll_mode: RollMode = roll_mode_result["mode"]
	
	# Step 2: Calculate positioning modifiers
	var positioning = {
		"positioning_def_bonus": 0
	}
	# Add cover bonus if defender in forest/swamp (already checked in disadvantage)
	if defender.current_hex and "biome_type" in defender.current_hex:
		var biome = defender.current_hex.biome_type
		if biome == Biomes.Type.FOREST or biome == Biomes.Type.SWAMP:
			positioning["positioning_def_bonus"] = CombatBalanceConfig.COVER_DEF_BONUS
	
	# Step 3: Roll attack
	var attack_result = calculate_attack_roll(attacker, move, roll_mode)
	
	# Step 4: Calculate defense DC
	var defense_result = calculate_defense_dc(defender, stance, positioning)
	
	# Step 5: Resolve hit/miss
	var hit_result = resolve_hit(attack_result, defense_result)
	
	# Build comprehensive result
	return {
		# Roll mode info
		"roll_mode": roll_mode,
		"advantage_sources": roll_mode_result["advantage_sources"],
		"disadvantage_sources": roll_mode_result["disadvantage_sources"],
		"cancelled_out": roll_mode_result["cancelled_out"],
		
		# Dice info
		"dice_rolls": attack_result["dice_rolls"],
		"natural_roll": attack_result["natural_roll"],
		
		# Attack calculation
		"atk_modifier": attack_result["atk_modifier"],
		"accuracy_modifier": attack_result["accuracy_modifier"],
		"total_attack_roll": attack_result["total_roll"],
		
		# Defense calculation
		"base_dc": defense_result["base_dc"],
		"def_modifier": defense_result["def_modifier"],
		"stance_bonus": defense_result["stance_bonus"],
		"positioning_bonus": defense_result["positioning_bonus"],
		"total_defense_dc": defense_result["total_dc"],
		
		# Result
		"result_type": hit_result["result_type"],
		"hits": hit_result["hits"],
		"margin": hit_result["margin"],
		"is_critical_hit": hit_result["is_critical_hit"],
		"is_critical_miss": hit_result["is_critical_miss"],
		"damage_multiplier": hit_result["damage_multiplier"],
		"bypass_reactions": hit_result["bypass_reactions"]
	}


# =============================================================================
# UTILITY
# =============================================================================

## Get a human-readable string for the result type
static func get_result_text(result_type: RollResult) -> String:
	match result_type:
		RollResult.CRITICAL_MISS:
			return "CRITICAL MISS!"
		RollResult.MISS:
			return "MISS"
		RollResult.HIT:
			return "HIT"
		RollResult.CRITICAL_HIT:
			return "CRITICAL HIT!"
		_:
			return "UNKNOWN"


## Get a human-readable string for the roll mode
static func get_roll_mode_text(mode: RollMode) -> String:
	match mode:
		RollMode.ADVANTAGE:
			return "Advantage (2d20 take higher)"
		RollMode.DISADVANTAGE:
			return "Disadvantage (2d20 take lower)"
		_:
			return "Normal (1d20)"
