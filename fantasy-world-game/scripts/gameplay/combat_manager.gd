## Combat Manager
## Handles all combat logic: dice rolling, damage calculation, special abilities
## Enhanced with D&D × Pokémon hybrid move/stance system
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

# Enhanced Combat Signals
signal selection_phase_started(attacker: Node, defender: Node)
signal attacker_move_selected(move: MoveData.Move)
signal defender_stance_selected(stance: int)
signal moves_revealed(attacker_move: MoveData.Move, defender_stance: int)
signal selection_timeout()
signal counter_attack_triggered(defender: Node, damage: int)
signal status_effect_applied(target: Node, effect_id: String)
signal type_effectiveness_shown(multiplier: float, text: String)

# =============================================================================
# COMBAT STATE ENUM
# =============================================================================
enum CombatState {
	IDLE,              # No combat in progress
	SELECTING_MOVES,   # Players selecting move/stance
	RESOLVING,         # Combat is being resolved
	COMPLETE           # Combat finished, ready for cleanup
}

# =============================================================================
# CONSTANTS
# =============================================================================
const DEATH_BURST_DAMAGE: int = 30
const MAGIC_DEF_IGNORE: float = 0.25  # Magic ignores 25% DEF
const CRITICAL_THRESHOLD: int = 18    # Roll of 18-20 is critical
# Selection timeout is defined in CombatBalanceConfig.SELECTION_TIME_LIMIT
const CRITICAL_MISS_THRESHOLD: int = 1  # Roll of 1 is auto-miss

# =============================================================================
# PROPERTIES
# =============================================================================
## Reference to the hex board (for range/LOS checks)
var hex_board: Node = null

## Reference to player manager (for kill rewards)
var player_manager: PlayerManager = null

# =============================================================================
# ENHANCED COMBAT STATE
# =============================================================================
## Current combat state
var combat_state: CombatState = CombatState.IDLE

## Current combatants
var current_attacker: Node = null
var current_defender: Node = null

## Selection tracking
var attacker_selected_move: MoveData.Move = null
var defender_selected_stance: int = DefensiveStances.DefensiveStance.BRACE
var attacker_ready: bool = false
var defender_ready: bool = false

## Timer for selection phase
## NOTE: Since CombatManager is a RefCounted (not Node), it has no _process().
## The actual timer countdown is handled by CombatSelectionUI, which emits timeout
## when time expires. The UI calls handle_selection_timeout() on this manager.
## This variable is set for reference/sync but not actively decremented here.
var selection_timer: float = 0.0


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
# ENHANCED COMBAT - SELECTION FLOW
# =============================================================================

## Start enhanced combat with move/stance selection phase
func start_enhanced_combat(attacker: Node, defender: Node) -> void:
	# Validate combat first
	var can_attack = can_initiate_combat(attacker, defender)
	if not can_attack["can_attack"]:
		push_error("CombatManager: Cannot start combat - " + can_attack.get("error", "unknown error"))
		return
	
	# Set up combat state
	current_attacker = attacker
	current_defender = defender
	combat_state = CombatState.SELECTING_MOVES
	
	# Reset selection state
	attacker_selected_move = null
	defender_selected_stance = DefensiveStances.DefensiveStance.BRACE
	attacker_ready = false
	defender_ready = false
	selection_timer = CombatBalanceConfig.SELECTION_TIME_LIMIT
	
	# Emit signals
	combat_started.emit(attacker, defender)
	selection_phase_started.emit(attacker, defender)


## Set the attacker's selected move
func set_attacker_move(move: MoveData.Move) -> void:
	if combat_state != CombatState.SELECTING_MOVES:
		push_warning("CombatManager: Not in selection phase")
		return
	
	if move == null:
		push_warning("CombatManager: Null move selected")
		return
	
	# Check if move is on cooldown
	if current_attacker and not current_attacker.is_move_available(move.move_id):
		push_warning("CombatManager: Move is on cooldown")
		return
	
	attacker_selected_move = move
	attacker_ready = true
	attacker_move_selected.emit(move)
	
	_check_both_ready()


## Set the defender's selected stance
func set_defender_stance(stance: int) -> void:
	if combat_state != CombatState.SELECTING_MOVES:
		push_warning("CombatManager: Not in selection phase")
		return
	
	# Check if Endure can be used
	if stance == DefensiveStances.DefensiveStance.ENDURE:
		if current_defender and current_defender.endure_uses_remaining <= 0:
			push_warning("CombatManager: Endure already used this combat")
			return
	
	defender_selected_stance = stance
	defender_ready = true
	defender_stance_selected.emit(stance)
	
	_check_both_ready()


## Check if both players are ready, resolve if so
func _check_both_ready() -> void:
	if attacker_ready and defender_ready:
		# Both ready - reveal selections and resolve
		moves_revealed.emit(attacker_selected_move, defender_selected_stance)
		_resolve_enhanced_combat()


## Handle selection timeout
func handle_selection_timeout() -> void:
	if combat_state != CombatState.SELECTING_MOVES:
		return
	
	# Default selections for anyone not ready
	if not attacker_ready:
		# Default to first available move (should be Standard move)
		if current_attacker and current_attacker.available_moves.size() > 0:
			attacker_selected_move = current_attacker.available_moves[0]
		attacker_ready = true
	
	if not defender_ready:
		# Default to Brace stance
		defender_selected_stance = DefensiveStances.DefensiveStance.BRACE
		defender_ready = true
	
	selection_timeout.emit()
	_check_both_ready()


## Cancel current combat (for interrupts/disconnects)
func cancel_combat() -> void:
	combat_state = CombatState.IDLE
	current_attacker = null
	current_defender = null
	attacker_selected_move = null
	attacker_ready = false
	defender_ready = false


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


## Resolve enhanced combat using selected move and stance
func _resolve_enhanced_combat() -> void:
	combat_state = CombatState.RESOLVING
	
	var attacker = current_attacker
	var defender = current_defender
	var move = attacker_selected_move
	var stance = defender_selected_stance
	
	# Check for self-targeting moves (heals, buffs, stealth)
	if move and move.targets_self:
		var self_result = CombatEdgeCases.execute_self_targeting_move(attacker, move)
		var result = {
			"success": self_result.get("success", false),
			"attacker": attacker,
			"defender": null,  # No defender for self-targeting
			"move": move,
			"stance": -1,
			"attack_succeeded": self_result.get("success", false),
			"damage_dealt": 0,
			"is_self_targeting": true,
			"self_effect": self_result.get("effect", ""),
			"self_amount": self_result.get("amount", 0),
			"defender_killed": false,
			"modifiers": {}
		}
		combat_state = CombatState.COMPLETE
		combat_resolved.emit(result)
		current_attacker = null
		current_defender = null
		return
	
	# TODO: AoE moves should use CombatEdgeCases.get_aoe_targets() and loop over all targets
	# For now, only single-target offensive moves are fully supported after this point
	
	# Build comprehensive result dictionary
	var result = {
		"success": false,
		"attacker": attacker,
		"defender": defender,
		"move": move,
		"stance": stance,
		"natural_roll": 0,
		"total_attack_roll": 0,
		"defense_dc": 0,
		"is_critical_hit": false,
		"is_critical_miss": false,
		"attack_succeeded": false,
		"damage_dealt": 0,
		"type_effectiveness": 1.0,
		"effectiveness_text": "Normal",
		"counter_damage": 0,
		"status_applied": "",
		"defender_killed": false,
		"survived_lethal": false,
		"modifiers": {}
	}
	
	# Get biomes for positioning
	var attacker_biome = _get_unit_biome(attacker)
	var defender_biome = _get_unit_biome(defender)
	
	# Calculate all modifiers (Phase 2.3)
	var modifiers = calculate_final_modifiers(attacker, defender, move, stance)
	result["modifiers"] = modifiers
	
	# Calculate attack roll (Phase 2.4)
	var attack_result = calculate_attack_roll(attacker, move, modifiers)
	result["natural_roll"] = attack_result["natural_roll"]
	result["total_attack_roll"] = attack_result["total_roll"]
	result["is_critical_hit"] = attack_result["is_critical_hit"]
	result["is_critical_miss"] = attack_result["is_critical_miss"]
	
	# Calculate defense DC
	result["defense_dc"] = calculate_defense_dc(defender, stance, modifiers)
	
	# Determine hit/miss
	if result["is_critical_miss"]:
		result["attack_succeeded"] = false
	elif result["is_critical_hit"]:
		result["attack_succeeded"] = true
	else:
		result["attack_succeeded"] = result["total_attack_roll"] > result["defense_dc"]
	
	# Apply move cooldown
	attacker.use_move(move.move_id)
	
	# Use Endure if selected
	if stance == DefensiveStances.DefensiveStance.ENDURE:
		defender.endure_uses_remaining -= 1
	
	if result["attack_succeeded"]:
		# Calculate type effectiveness (using helper that converts enum types)
		var effectiveness = calculate_type_effectiveness(move, defender)
		result["type_effectiveness"] = effectiveness
		
		# Get effectiveness text using converted type
		var te_damage_type := _convert_damage_type(move.damage_type)
		result["effectiveness_text"] = TypeEffectiveness.get_effectiveness_text(te_damage_type, defender.troop_id)
		type_effectiveness_shown.emit(effectiveness, result["effectiveness_text"])
		
		# Calculate damage
		var damage = calculate_enhanced_damage(attacker, move, defender, modifiers, result["is_critical_hit"], effectiveness)
		
		# Apply stance damage reduction
		var stance_result = DefensiveStances.apply_stance_to_damage(stance, damage, defender.current_hp)
		damage = stance_result["damage"]
		result["survived_lethal"] = stance_result["survived_lethal"]
		
		result["damage_dealt"] = damage
		
		# Apply damage
		defender.take_damage(damage)
		damage_dealt.emit(defender, damage, result["is_critical_hit"])
		
		# Check for status effect application
		if move.effect_id != "" and move.effect_chance > 0:
			if randf() <= move.effect_chance:
				var effect = StatusEffects.create_effect(move.effect_id)
				if effect and defender.apply_status_effect(effect):
					result["status_applied"] = move.effect_id
					status_effect_applied.emit(defender, move.effect_id)
		
		# Check if defender died
		if not defender.is_alive:
			result["defender_killed"] = true
			troop_killed.emit(defender, attacker)
			
			# Handle death burst
			if defender.has_death_burst():
				var burst_result = _trigger_death_burst(defender)
				result["death_burst_triggered"] = true
				result["death_burst_targets"] = burst_result["targets"]
				result["death_burst_damage"] = burst_result["damage_per_target"]
	else:
		# Attack missed - check for Counter stance
		if stance == DefensiveStances.DefensiveStance.COUNTER:
			var counter_dmg = DefensiveStances.calculate_counter_damage(stance, int(defender.get_modified_stat("atk")))
			if counter_dmg > 0:
				result["counter_damage"] = counter_dmg
				attacker.take_damage(counter_dmg)
				counter_attack_triggered.emit(defender, counter_dmg)
				damage_dealt.emit(attacker, counter_dmg, false)
				
				# Check if attacker died from counter
				if not attacker.is_alive:
					troop_killed.emit(attacker, defender)
	
	result["success"] = true
	combat_state = CombatState.COMPLETE
	combat_resolved.emit(result)
	
	# Clean up
	current_attacker = null
	current_defender = null
	combat_state = CombatState.IDLE


# =============================================================================
# PHASE 2.3 - MODIFIER CALCULATION SYSTEM
# =============================================================================

## Calculate positioning bonus modifiers
func calculate_positioning_bonus(attacker: Node, defender: Node) -> Dictionary:
	var bonus = {
		"hit_bonus": 0,
		"damage_bonus": 0.0,
		"def_bonus": 0,
		"flanking": false,
		"high_ground": false,
		"surrounded": false,
		"cover": false
	}
	
	if hex_board == null or attacker.current_hex == null or defender.current_hex == null:
		return bonus
	
	var attacker_coord = attacker.current_hex.coordinates
	var defender_coord = defender.current_hex.coordinates
	
	# Check flanking: ally adjacent to defender
	var defender_neighbors = defender_coord.get_all_neighbors()
	for coord in defender_neighbors:
		var tile = hex_board.get_tile_at(coord)
		if tile and tile.occupant and tile.occupant != attacker:
			if "owner_player_id" in tile.occupant and tile.occupant.owner_player_id == attacker.owner_player_id:
				bonus["flanking"] = true
				bonus["hit_bonus"] += 3
				break
	
	# Check high ground (Hills/Peaks biome)
	var attacker_biome = _get_unit_biome(attacker)
	if attacker_biome in [Biomes.Type.HILLS, Biomes.Type.PEAKS]:
		bonus["high_ground"] = true
		bonus["hit_bonus"] += 2
		bonus["damage_bonus"] += 0.1
	
	# Check cover (defender on Forest - provides natural cover)
	var defender_biome = _get_unit_biome(defender)
	if defender_biome == Biomes.Type.FOREST:
		bonus["cover"] = true
		bonus["def_bonus"] += 3
	
	# Check surrounded (3+ enemies adjacent to defender)
	var enemy_count = 0
	for coord in defender_neighbors:
		var tile = hex_board.get_tile_at(coord)
		if tile and tile.occupant:
			if "owner_player_id" in tile.occupant and tile.occupant.owner_player_id != defender.owner_player_id:
				enemy_count += 1
	
	if enemy_count >= 3:
		bonus["surrounded"] = true
		bonus["def_bonus"] -= 2
	
	return bonus


## Calculate type effectiveness multiplier
func calculate_type_effectiveness(move: MoveData.Move, defender: Node) -> float:
	if move == null or defender == null:
		return 1.0
	
	var te_damage_type := _convert_damage_type(move.damage_type)
	return TypeEffectiveness.get_effectiveness(te_damage_type, defender.troop_id)


## Convert MoveData.DamageType to TypeEffectiveness.DamageType
func _convert_damage_type(move_damage_type: MoveData.DamageType) -> TypeEffectiveness.DamageType:
	match move_damage_type:
		MoveData.DamageType.PHYSICAL: return TypeEffectiveness.DamageType.PHYSICAL
		MoveData.DamageType.FIRE: return TypeEffectiveness.DamageType.FIRE
		MoveData.DamageType.ICE: return TypeEffectiveness.DamageType.ICE
		MoveData.DamageType.DARK: return TypeEffectiveness.DamageType.DARK
		MoveData.DamageType.HOLY: return TypeEffectiveness.DamageType.HOLY
		MoveData.DamageType.NATURE: return TypeEffectiveness.DamageType.NATURE
		_: return TypeEffectiveness.DamageType.PHYSICAL


## Calculate stat stage multiplier
func calculate_stat_stage_multiplier(stage: int) -> float:
	if stage >= 0:
		return (2.0 + stage) / 2.0
	else:
		return 2.0 / (2.0 - stage)


## Calculate all final modifiers combined
func calculate_final_modifiers(attacker: Node, defender: Node, move: MoveData.Move, stance: int) -> Dictionary:
	var positioning = calculate_positioning_bonus(attacker, defender)
	
	var modifiers = {
		# Hit modifiers
		"accuracy_modifier": move.accuracy_modifier if move else 0,
		"positioning_hit_bonus": positioning["hit_bonus"],
		"flanking": positioning["flanking"],
		"high_ground": positioning["high_ground"],
		
		# Damage modifiers
		"power_percent": move.power_percent if move else 1.0,
		"positioning_damage_bonus": positioning["damage_bonus"],
		"atk_stage_multiplier": attacker.get_stat_stage_multiplier("atk") if attacker else 1.0,
		
		# Defense modifiers
		"stance_def_bonus": DefensiveStances.get_defense_bonus(stance),
		"stance_evasion_bonus": DefensiveStances.get_evasion_bonus(stance),
		"positioning_def_bonus": positioning["def_bonus"],
		"def_stage_multiplier": defender.get_stat_stage_multiplier("def") if defender else 1.0,
		"cover": positioning["cover"],
		"surrounded": positioning["surrounded"],
		
		# Damage reduction
		"stance_damage_multiplier": DefensiveStances.get_damage_multiplier(stance)
	}
	
	return modifiers


# =============================================================================
# PHASE 2.4 - ENHANCED DICE RESOLUTION
# =============================================================================

## Calculate attack roll with natural roll tracking
func calculate_attack_roll(attacker: Node, move: MoveData.Move, modifiers: Dictionary) -> Dictionary:
	var natural_roll = randi_range(1, GameConfig.DICE_TYPE)
	
	var atk_stat = int(attacker.get_modified_stat("atk")) if attacker else 0
	var accuracy_mod = modifiers.get("accuracy_modifier", 0)
	var position_bonus = modifiers.get("positioning_hit_bonus", 0)
	
	var total_roll = natural_roll + atk_stat + accuracy_mod + position_bonus
	
	# Check for critical hit (natural 18-20)
	var is_crit = natural_roll >= CRITICAL_THRESHOLD
	
	# Check for critical miss (natural 1)
	var is_miss = natural_roll <= CRITICAL_MISS_THRESHOLD
	
	# Stealth bonus: guaranteed crit
	if attacker and attacker.is_stealthed():
		is_crit = true
		attacker.remove_status_effect("stealth")
	
	return {
		"natural_roll": natural_roll,
		"total_roll": total_roll,
		"is_critical_hit": is_crit,
		"is_critical_miss": is_miss
	}


## Calculate defense DC (Difficulty Class to hit)
func calculate_defense_dc(defender: Node, stance: int, modifiers: Dictionary) -> int:
	var base_dc = 10  # Base DC
	
	var def_stat = int(defender.get_modified_stat("def")) if defender else 0
	var stance_bonus = modifiers.get("stance_def_bonus", 0) + modifiers.get("stance_evasion_bonus", 0)
	var position_bonus = modifiers.get("positioning_def_bonus", 0)
	
	return base_dc + def_stat + stance_bonus + position_bonus


## Calculate enhanced damage with all modifiers
func calculate_enhanced_damage(attacker: Node, move: MoveData.Move, defender: Node, modifiers: Dictionary, is_crit: bool, type_effectiveness: float) -> int:
	# Base ATK with stat stages
	var base_atk = attacker.get_modified_stat("atk") if attacker else 50
	
	# Apply move power percent
	var power_mult = modifiers.get("power_percent", 1.0)
	var damage = base_atk * power_mult
	
	# Apply type effectiveness
	damage *= type_effectiveness
	
	# Apply positioning damage bonus
	damage *= (1.0 + modifiers.get("positioning_damage_bonus", 0.0))
	
	# Apply DEF reduction (DEF / 2)
	var defender_def = defender.get_modified_stat("def") if defender else 0
	damage -= defender_def / 2.0
	
	# Apply magic damage (ignores 25% DEF)
	if move and move.damage_type == MoveData.DamageType.DARK:
		if attacker and attacker.has_magic_damage():
			damage += defender_def * MAGIC_DEF_IGNORE / 2.0
	
	# Critical hit doubles damage
	if is_crit:
		damage *= 2.0
	
	# Minimum damage is 1
	return max(1, int(damage))


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
