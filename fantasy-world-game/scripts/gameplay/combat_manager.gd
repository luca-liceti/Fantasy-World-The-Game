## Combat Manager
## Handles all combat logic: dice rolling, damage calculation, special abilities
## Designed for networking - combat results are deterministic from seed/rolls
class_name CombatManager
extends RefCounted

# =============================================================================
# SIGNALS
# =============================================================================
signal combat_started(attacker: Node, defender: Node)
signal dice_rolled(attacker_roll: int, defender_roll: int, attacker_total: int, defender_total: int)
signal dice_reroll(roll_number: int, reason: String)
signal combat_resolved(result: Dictionary)
signal damage_dealt(target: Node, amount: int, is_critical: bool)
signal troop_killed(troop: Node, killer: Node)
signal death_burst_triggered(source: Node, targets: Array, damage: int)

# =============================================================================
# CONSTANTS
# =============================================================================
const DEATH_BURST_DAMAGE: int = 30
const MAGIC_DEF_IGNORE: float = 0.25  # Magic ignores 25% DEF
const CRITICAL_THRESHOLD: int = 18    # Roll of 18-20 is critical

# =============================================================================
# PROPERTIES
# =============================================================================
## Reference to the hex board (for range/LOS checks)
var hex_board: Node = null

## Reference to player manager (for kill rewards)
var player_manager: PlayerManager = null


# =============================================================================
# INITIALIZATION
# =============================================================================

func _init(board: Node = null, p_manager: PlayerManager = null) -> void:
	hex_board = board
	player_manager = p_manager


func setup(board: Node, p_manager: PlayerManager) -> void:
	hex_board = board
	player_manager = p_manager


# =============================================================================
# COMBAT INITIATION
# =============================================================================

## Check if attacker can attack defender
## Returns: Dictionary with "can_attack" and optional "error"
func can_initiate_combat(attacker: Node, defender: Node) -> Dictionary:
	# Basic validation
	if attacker == null or defender == null:
		return {"can_attack": false, "error": "Invalid units"}
	
	if not attacker.is_alive:
		return {"can_attack": false, "error": "Attacker is dead"}
	
	if not defender.is_alive:
		return {"can_attack": false, "error": "Target is dead"}
	
	# Check if same team
	if attacker.owner_player_id == defender.owner_player_id:
		return {"can_attack": false, "error": "Cannot attack friendly units"}
	
	# Check range
	var distance = _get_distance(attacker, defender)
	if distance < 0:
		return {"can_attack": false, "error": "Cannot calculate distance"}
	
	if distance > attacker.current_range:
		return {"can_attack": false, "error": "Target out of range"}
	
	# Check air vs ground rules
	if defender.is_air_unit() and not attacker._can_hit_air():
		return {"can_attack": false, "error": "Cannot attack air units"}
	
	# Check line of sight for ranged/magic attacks
	if attacker.current_range > 1:
		if hex_board and not _has_line_of_sight(attacker, defender):
			return {"can_attack": false, "error": "No line of sight"}
	
	return {"can_attack": true}


## Get distance between two units
func _get_distance(unit_a: Node, unit_b: Node) -> int:
	if unit_a.current_hex == null or unit_b.current_hex == null:
		return -1
	
	if "coordinates" in unit_a.current_hex and "coordinates" in unit_b.current_hex:
		return unit_a.current_hex.coordinates.distance_to(unit_b.current_hex.coordinates)
	
	return -1


## Check line of sight between two units
func _has_line_of_sight(unit_a: Node, unit_b: Node) -> bool:
	if hex_board == null:
		return true  # Assume clear if no board reference
	
	if unit_a.current_hex == null or unit_b.current_hex == null:
		return false
	
	if "coordinates" in unit_a.current_hex and "coordinates" in unit_b.current_hex:
		return hex_board.has_line_of_sight(
			unit_a.current_hex.coordinates,
			unit_b.current_hex.coordinates
		)
	
	return true


# =============================================================================
# COMBAT RESOLUTION
# =============================================================================

## Execute combat between attacker and defender
## Returns: Dictionary with full combat results
func execute_combat(attacker: Node, defender: Node) -> Dictionary:
	var result = {
		"success": false,
		"attacker": attacker,
		"defender": defender,
		"attacker_rolls": [],
		"defender_rolls": [],
		"final_attacker_roll": 0,
		"final_defender_roll": 0,
		"attack_succeeded": false,
		"damage_dealt": 0,
		"defender_killed": false,
		"is_critical": false,
		"death_burst_triggered": false,
		"death_burst_targets": [],
		"death_burst_damage": 0
	}
	
	# Validate combat
	var can_attack = can_initiate_combat(attacker, defender)
	if not can_attack["can_attack"]:
		result["error"] = can_attack["error"]
		return result
	
	combat_started.emit(attacker, defender)
	
	# Get attacker's biome (for modifiers)
	var attacker_biome = _get_unit_biome(attacker)
	var defender_biome = _get_unit_biome(defender)
	
	# Roll dice
	var roll_result = _roll_combat_dice(attacker, defender)
	result["attacker_rolls"] = roll_result["attacker_rolls"]
	result["defender_rolls"] = roll_result["defender_rolls"]
	result["final_attacker_roll"] = roll_result["attacker_total"]
	result["final_defender_roll"] = roll_result["defender_total"]
	result["is_critical"] = roll_result["is_critical"]
	
	# Determine if attack hits
	result["attack_succeeded"] = roll_result["attacker_total"] > roll_result["defender_total"]
	
	if result["attack_succeeded"]:
		# Calculate damage
		var damage = _calculate_damage(attacker, defender, attacker_biome, defender_biome, result["is_critical"])
		result["damage_dealt"] = damage
		
		# Apply damage
		defender.take_damage(damage)
		damage_dealt.emit(defender, damage, result["is_critical"])
		
		# Check if defender died
		if not defender.is_alive:
			result["defender_killed"] = true
			troop_killed.emit(defender, attacker)
			
			# Handle death burst if defender has it
			if defender.has_death_burst():
				var burst_result = _trigger_death_burst(defender)
				result["death_burst_triggered"] = true
				result["death_burst_targets"] = burst_result["targets"]
				result["death_burst_damage"] = burst_result["damage_per_target"]
	
	result["success"] = true
	combat_resolved.emit(result)
	
	return result


## Roll combat dice with rerolls for ties
func _roll_combat_dice(attacker: Node, defender: Node) -> Dictionary:
	var attacker_rolls: Array[int] = []
	var defender_rolls: Array[int] = []
	var roll_count = 0
	var attacker_total = 0
	var defender_total = 0
	var is_critical = false
	
	while roll_count < GameConfig.MAX_REROLLS + 1:
		roll_count += 1
		
		# Roll d20 for each
		var attacker_die = randi_range(1, GameConfig.DICE_TYPE)
		var defender_die = randi_range(1, GameConfig.DICE_TYPE)
		
		attacker_rolls.append(attacker_die)
		defender_rolls.append(defender_die)
		
		# Add stat modifiers
		attacker_total = attacker_die + attacker.current_atk
		defender_total = defender_die + defender.current_def
		
		# Check for critical (18-20 on d20)
		if attacker_die >= CRITICAL_THRESHOLD:
			is_critical = true
		
		# Emit roll event
		dice_rolled.emit(attacker_die, defender_die, attacker_total, defender_total)
		
		# Check for tie
		if attacker_total == defender_total:
			if roll_count < GameConfig.MAX_REROLLS + 1:
				dice_reroll.emit(roll_count, "Tie - Rerolling")
				continue
			else:
				# Max rerolls reached, defender wins
				defender_total += 1  # Give defender advantage
				break
		else:
			break
	
	return {
		"attacker_rolls": attacker_rolls,
		"defender_rolls": defender_rolls,
		"attacker_total": attacker_total,
		"defender_total": defender_total,
		"is_critical": is_critical,
		"roll_count": roll_count
	}


## Calculate damage based on stats and modifiers
func _calculate_damage(attacker: Node, defender: Node, attacker_biome: Biomes.Type, defender_biome: Biomes.Type, is_critical: bool) -> int:
	# Get effective ATK (with biome modifier)
	var effective_atk = attacker.get_effective_atk(attacker_biome)
	
	# Get base DEF
	var effective_def = defender.current_def
	
	# Apply magic damage (ignores 25% DEF)
	if attacker.has_magic_damage():
		effective_def = int(effective_def * (1.0 - MAGIC_DEF_IGNORE))
	
	# Apply anti-air bonus
	if defender.is_air_unit():
		var anti_air_mult = attacker.get_anti_air_multiplier()
		effective_atk = int(effective_atk * anti_air_mult)
	
	# Base damage formula: ATK - DEF/2
	var base_damage = effective_atk - int(effective_def / 2.0)
	
	# Apply defender's biome defense modifier
	var def_modifier = defender.get_biome_defense_modifier(defender_biome)
	if def_modifier != 0.0:
		# Negative modifier = damage reduction
		base_damage = int(base_damage * (1.0 + def_modifier))
	
	# Critical hit bonus (optional: +50% damage)
	if is_critical:
		base_damage = int(base_damage * 1.5)
	
	# Minimum damage is always 1
	return max(GameConfig.MIN_DAMAGE, base_damage)


## Get the biome type of the hex a unit is on
func _get_unit_biome(unit: Node) -> Biomes.Type:
	if unit.current_hex and "biome_type" in unit.current_hex:
		return unit.current_hex.biome_type
	return Biomes.Type.PLAINS  # Default


# =============================================================================
# SPECIAL ABILITIES
# =============================================================================

## Trigger death burst ability (30 damage to adjacent enemies)
func _trigger_death_burst(dying_unit: Node) -> Dictionary:
	var targets: Array = []
	var damage_per_target = DEATH_BURST_DAMAGE
	
	if dying_unit.current_hex == null:
		return {"targets": targets, "damage_per_target": 0}
	
	if not "coordinates" in dying_unit.current_hex:
		return {"targets": targets, "damage_per_target": 0}
	
	# Get adjacent hexes
	var adj_coords = dying_unit.current_hex.coordinates.get_all_neighbors()
	
	for coord in adj_coords:
		if hex_board == null:
			continue
		
		var tile = hex_board.get_tile_at(coord)
		if tile == null:
			continue
		
		if tile.occupant == null:
			continue
		
		var occupant = tile.occupant
		
		# Only damage enemies
		if "owner_player_id" in occupant and occupant.owner_player_id != dying_unit.owner_player_id:
			if "take_damage" in occupant:
				occupant.take_damage(damage_per_target)
				targets.append(occupant)
				damage_dealt.emit(occupant, damage_per_target, false)
				
				# Check if this also killed them
				if "is_alive" in occupant and not occupant.is_alive:
					troop_killed.emit(occupant, dying_unit)
	
	if not targets.is_empty():
		death_burst_triggered.emit(dying_unit, targets, damage_per_target)
	
	return {"targets": targets, "damage_per_target": damage_per_target}


## Execute multi-strike attack (Hydra attacking 2 adjacent enemies)
## Returns: Array of combat results
func execute_multi_strike(attacker: Node, targets: Array) -> Array:
	var results: Array = []
	
	# Limit to 2 targets max
	var actual_targets = targets.slice(0, 2)
	
	for target in actual_targets:
		var result = execute_combat(attacker, target)
		results.append(result)
	
	return results


## Execute heal action (Celestial Cleric)
func execute_heal(healer: Node, target: Node) -> Dictionary:
	var result = {
		"success": false,
		"healer": healer,
		"target": target,
		"heal_amount": 0,
		"target_hp_before": 0,
		"target_hp_after": 0
	}
	
	# Validate
	if healer == null or target == null:
		result["error"] = "Invalid units"
		return result
	
	if not healer.can_heal():
		result["error"] = "Unit cannot heal"
		return result
	
	# Check range
	var distance = _get_distance(healer, target)
	if distance < 0 or distance > GameConfig.CLERIC_HEAL_RANGE:
		result["error"] = "Target out of range"
		return result
	
	# Check if same team
	if healer.owner_player_id != target.owner_player_id:
		result["error"] = "Can only heal friendly units"
		return result
	
	# Apply heal
	result["target_hp_before"] = target.current_hp
	var actual_heal = target.heal(GameConfig.CLERIC_HEAL_AMOUNT)
	result["heal_amount"] = actual_heal
	result["target_hp_after"] = target.current_hp
	result["success"] = true
	
	return result


# =============================================================================
# NPC COMBAT
# =============================================================================

## Execute combat against an NPC
## Returns: Dictionary with combat results and loot
func execute_npc_combat(attacker: Node, npc: Node) -> Dictionary:
	# Use standard combat
	var combat_result = execute_combat(attacker, npc)
	
	# If NPC was killed, calculate rewards
	if combat_result["defender_killed"] and "npc_id" in npc:
		var npc_data = CardData.get_npc(npc.npc_id)
		
		combat_result["gold_reward"] = npc_data.get("gold_reward", 0)
		combat_result["xp_reward"] = npc_data.get("xp_reward", 0)
		
		# Roll for rare drop
		var drop_chance = npc_data.get("drop_chance", 0.0)
		if randf() < drop_chance:
			combat_result["rare_drop"] = npc_data.get("rare_drop", "")
		else:
			combat_result["rare_drop"] = ""
	
	return combat_result


# =============================================================================
# UTILITY
# =============================================================================

## Get all valid attack targets for a unit
func get_valid_targets(attacker: Node) -> Array:
	var targets: Array = []
	
	if hex_board == null or attacker.current_hex == null:
		return targets
	
	if not "coordinates" in attacker.current_hex:
		return targets
	
	# Get all hexes in range
	var in_range = attacker.current_hex.coordinates.get_hexes_in_range(attacker.current_range)
	
	for coord in in_range:
		var tile = hex_board.get_tile_at(coord)
		if tile == null or tile.occupant == null:
			continue
		
		var occupant = tile.occupant
		
		# Check if valid target
		var can_attack = can_initiate_combat(attacker, occupant)
		if can_attack["can_attack"]:
			targets.append(occupant)
	
	return targets


## Get all valid heal targets for a healer
func get_valid_heal_targets(healer: Node) -> Array:
	var targets: Array = []
	
	if hex_board == null or healer.current_hex == null:
		return targets
	
	if not healer.can_heal():
		return targets
	
	if not "coordinates" in healer.current_hex:
		return targets
	
	# Get all hexes in heal range
	var in_range = healer.current_hex.coordinates.get_hexes_in_range(GameConfig.CLERIC_HEAL_RANGE)
	
	for coord in in_range:
		var tile = hex_board.get_tile_at(coord)
		if tile == null or tile.occupant == null:
			continue
		
		var occupant = tile.occupant
		
		# Must be friendly unit
		if "owner_player_id" in occupant and occupant.owner_player_id == healer.owner_player_id:
			# Must be able to receive healing (not at max HP)
			if "current_hp" in occupant and "max_hp" in occupant:
				if occupant.current_hp < occupant.max_hp:
					targets.append(occupant)
	
	return targets
