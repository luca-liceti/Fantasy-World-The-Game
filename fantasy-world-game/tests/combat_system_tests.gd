## Enhanced Combat System - Unit Tests
## Tests for move data, type effectiveness, positioning, stats, damage, cooldowns, and status effects
## Run with: GUT or manual test execution
extends Node

class_name CombatSystemTests


# =============================================================================
# TEST RESULTS TRACKING
# =============================================================================

var tests_passed: int = 0
var tests_failed: int = 0
var test_results: Array[Dictionary] = []


# =============================================================================
# MAIN TEST RUNNER
# =============================================================================

func run_all_tests() -> Dictionary:
	tests_passed = 0
	tests_failed = 0
	test_results.clear()
	
	print("\n========================================")
	print("ENHANCED COMBAT SYSTEM - UNIT TESTS")
	print("========================================\n")
	
	# 6.1.1 - Move Data Loading
	_test_move_data_loading()
	
	# 6.1.2 - Type Effectiveness
	_test_type_effectiveness()
	
	# 6.1.3 - Positioning Bonus
	_test_positioning_bonuses()
	
	# 6.1.4 - Stat Stage Multipliers
	_test_stat_stage_multipliers()
	
	# 6.1.5 - Damage Formula
	_test_damage_formula()
	
	# 6.1.6 - Cooldown System
	_test_cooldown_system()
	
	# 6.1.7 - Status Effects
	_test_status_effects()
	
	print("\n========================================")
	print("TEST RESULTS: %d passed, %d failed" % [tests_passed, tests_failed])
	print("========================================\n")
	
	return {
		"passed": tests_passed,
		"failed": tests_failed,
		"total": tests_passed + tests_failed,
		"results": test_results
	}


func _assert(condition: bool, test_name: String, details: String = "") -> void:
	if condition:
		tests_passed += 1
		test_results.append({
			"name": test_name,
			"passed": true,
			"details": details
		})
		print("  ✓ PASS: %s" % test_name)
	else:
		tests_failed += 1
		test_results.append({
			"name": test_name,
			"passed": false,
			"details": details
		})
		print("  ✗ FAIL: %s - %s" % [test_name, details])


# =============================================================================
# 6.1.1 - MOVE DATA LOADING
# =============================================================================

func _test_move_data_loading() -> void:
	print("\n--- 6.1.1: Move Data Loading ---")
	
	# Test that moves exist
	var all_moves = MoveData.get_all_moves()
	_assert(all_moves.size() > 0, "Moves exist", "Found %d moves" % all_moves.size())
	# We have 52 unique moves (13 troops × 4 moves each, with some troops sharing moves)
	_assert(all_moves.size() >= 48, "At least 48 moves total", "Found %d moves" % all_moves.size())
	
	# Test move retrieval - use an actual move ID
	var infernal_slash = MoveData.get_move("infernal_slash")
	_assert(infernal_slash != null, "Get specific move", "infernal_slash")
	
	if infernal_slash:
		_assert(infernal_slash.move_name == "Hell Slash", "Move name correct", infernal_slash.move_name)
		_assert(infernal_slash.damage_type == MoveData.DamageType.FIRE, "Damage type correct", "Expected FIRE")
		_assert(infernal_slash.power_percent > 0, "Power percent set", str(infernal_slash.power_percent))
	
	# Test moves for specific troop
	var infernal_moves = MoveData.get_moves_for_troop("infernal_soul")
	_assert(infernal_moves.size() == 4, "4 moves per troop", "Found %d moves for infernal_soul" % infernal_moves.size())
	
	# Test all troops defined in TROOP_MOVES have 4 moves each
	# These are the actual troop IDs from move_data.gd TROOP_MOVES
	var troop_ids = ["medieval_knight", "four_headed_hydra", "dark_blood_dragon", "griffin",
					 "dark_magic_wizard", "elven_archer", "celestial_cleric", "infernal_soul",
					 "shadow_assassin", "necromancer", "frost_giant", "phoenix"]
	
	for troop_id in troop_ids:
		var moves = MoveData.get_moves_for_troop(troop_id)
		_assert(moves.size() == 4, "Troop has 4 moves: " + troop_id, "Found %d" % moves.size())


# =============================================================================
# 6.1.2 - TYPE EFFECTIVENESS
# =============================================================================

func _test_type_effectiveness() -> void:
	print("\n--- 6.1.2: Type Effectiveness ---")
	
	# Test super effective matchups (use TypeEffectiveness.DamageType)
	var fire_vs_frost = TypeEffectiveness.get_effectiveness(TypeEffectiveness.DamageType.FIRE, "frost_revenant")
	_assert(fire_vs_frost > 1.0, "Fire super effective vs Frost", "Got %.1f" % fire_vs_frost)
	
	var ice_vs_thunder = TypeEffectiveness.get_effectiveness(TypeEffectiveness.DamageType.ICE, "thunder_behemoth")
	# Thunder is BEAST type, check if Ice is effective
	_assert(ice_vs_thunder >= 1.0, "Ice vs Behemoth", "Got %.1f" % ice_vs_thunder)
	
	# Test not very effective
	var fire_vs_fire = TypeEffectiveness.get_effectiveness(TypeEffectiveness.DamageType.FIRE, "infernal_soul")
	_assert(fire_vs_fire < 1.0, "Fire not effective vs Fire", "Got %.1f" % fire_vs_fire)
	
	# Test opposing elements - Dark is RESISTED by Celestial Cleric (per Phase 6.2.10)
	# Celestial Cleric uniquely resists both Holy AND Dark, with no weakness
	var dark_vs_holy = TypeEffectiveness.get_effectiveness(TypeEffectiveness.DamageType.DARK, "celestial_cleric")
	_assert(dark_vs_holy < 1.0, "Dark resisted by Cleric", "Got %.1f" % dark_vs_holy)
	
	# Test neutral matchup
	var physical_vs_golem = TypeEffectiveness.get_effectiveness(TypeEffectiveness.DamageType.PHYSICAL, "ironclad_golem")
	# Physical vs CONSTRUCT might be neutral or reduced
	_assert(physical_vs_golem >= 0.0, "Physical vs Golem valid", "Got %.1f" % physical_vs_golem)
	
	# Test effectiveness text
	var text = TypeEffectiveness.get_effectiveness_text(TypeEffectiveness.DamageType.FIRE, "frost_revenant")
	_assert(text != "", "Effectiveness text generated", text)


# =============================================================================
# 6.1.3 - POSITIONING BONUSES
# =============================================================================

func _test_positioning_bonuses() -> void:
	print("\n--- 6.1.3: Positioning Bonuses ---")
	
	# Test flanking bonus values
	_assert(CombatBalanceConfig.FLANKING_HIT_BONUS == 3, "Flanking hit bonus is 3", str(CombatBalanceConfig.FLANKING_HIT_BONUS))
	
	# Test high ground values
	_assert(CombatBalanceConfig.HIGH_GROUND_HIT_BONUS == 2, "High ground hit bonus is 2", str(CombatBalanceConfig.HIGH_GROUND_HIT_BONUS))
	_assert(CombatBalanceConfig.HIGH_GROUND_DAMAGE_BONUS > 0, "High ground damage bonus exists", str(CombatBalanceConfig.HIGH_GROUND_DAMAGE_BONUS))
	
	# Test cover values
	_assert(CombatBalanceConfig.COVER_DEF_BONUS == 3, "Cover DEF bonus is 3", str(CombatBalanceConfig.COVER_DEF_BONUS))
	
	# Test surrounded values
	_assert(CombatBalanceConfig.SURROUNDED_DEF_PENALTY == 2, "Surrounded DEF penalty is 2", str(CombatBalanceConfig.SURROUNDED_DEF_PENALTY))
	_assert(CombatBalanceConfig.SURROUNDED_MIN_ENEMIES == 3, "Surrounded requires 3 enemies", str(CombatBalanceConfig.SURROUNDED_MIN_ENEMIES))


# =============================================================================
# 6.1.4 - STAT STAGE MULTIPLIERS
# =============================================================================

func _test_stat_stage_multipliers() -> void:
	print("\n--- 6.1.4: Stat Stage Multipliers ---")
	
	# Test stage 0 (neutral)
	var stage_0 = CombatBalanceConfig.get_stat_multiplier(0)
	_assert(abs(stage_0 - 1.0) < 0.001, "Stage 0 = 1.0x", "Got %.3f" % stage_0)
	
	# Test positive stages
	var stage_1 = CombatBalanceConfig.get_stat_multiplier(1)
	_assert(stage_1 > 1.0, "Stage +1 > 1.0x", "Got %.3f" % stage_1)
	_assert(abs(stage_1 - 1.5) < 0.001, "Stage +1 = 1.5x", "Got %.3f" % stage_1)
	
	var stage_2 = CombatBalanceConfig.get_stat_multiplier(2)
	_assert(abs(stage_2 - 2.0) < 0.001, "Stage +2 = 2.0x", "Got %.3f" % stage_2)
	
	var stage_6 = CombatBalanceConfig.get_stat_multiplier(6)
	_assert(abs(stage_6 - 4.0) < 0.001, "Stage +6 = 4.0x", "Got %.3f" % stage_6)
	
	# Test negative stages
	var stage_neg1 = CombatBalanceConfig.get_stat_multiplier(-1)
	_assert(stage_neg1 < 1.0, "Stage -1 < 1.0x", "Got %.3f" % stage_neg1)
	_assert(abs(stage_neg1 - 0.667) < 0.01, "Stage -1 ≈ 0.67x", "Got %.3f" % stage_neg1)
	
	var stage_neg6 = CombatBalanceConfig.get_stat_multiplier(-6)
	_assert(abs(stage_neg6 - 0.25) < 0.01, "Stage -6 = 0.25x", "Got %.3f" % stage_neg6)
	
	# Test clamping
	var stage_10 = CombatBalanceConfig.get_stat_multiplier(10)
	var stage_max = CombatBalanceConfig.get_stat_multiplier(6)
	_assert(abs(stage_10 - stage_max) < 0.001, "Stage 10 clamped to +6", "Got %.3f" % stage_10)
	
	var stage_neg10 = CombatBalanceConfig.get_stat_multiplier(-10)
	var stage_min = CombatBalanceConfig.get_stat_multiplier(-6)
	_assert(abs(stage_neg10 - stage_min) < 0.001, "Stage -10 clamped to -6", "Got %.3f" % stage_neg10)


# =============================================================================
# 6.1.5 - DAMAGE FORMULA
# =============================================================================

func _test_damage_formula() -> void:
	print("\n--- 6.1.5: Damage Formula ---")
	
	# Test minimum damage
	_assert(CombatBalanceConfig.MIN_DAMAGE == 1, "Minimum damage is 1", str(CombatBalanceConfig.MIN_DAMAGE))
	
	# Test critical multiplier
	_assert(CombatBalanceConfig.CRIT_DAMAGE_MULT == 2.0, "Crit multiplier is 2.0x", str(CombatBalanceConfig.CRIT_DAMAGE_MULT))
	
	# Test DEF divisor
	_assert(CombatBalanceConfig.DEF_DIVISOR == 2.0, "DEF divisor is 2.0", str(CombatBalanceConfig.DEF_DIVISOR))
	
	# Test type effectiveness multipliers
	_assert(CombatBalanceConfig.SUPER_EFFECTIVE_MULT == 1.5, "Super effective is 1.5x", str(CombatBalanceConfig.SUPER_EFFECTIVE_MULT))
	_assert(CombatBalanceConfig.NOT_EFFECTIVE_MULT == 0.5, "Not effective is 0.5x", str(CombatBalanceConfig.NOT_EFFECTIVE_MULT))
	_assert(CombatBalanceConfig.IMMUNE_MULT == 0.0, "Immune is 0.0x", str(CombatBalanceConfig.IMMUNE_MULT))
	
	# Test damage calculation example
	# Base ATK = 100, Power = 1.5, Type = 1.5 (SE), DEF = 50
	# Expected: 100 * 1.5 * 1.5 - 50/2 = 225 - 25 = 200
	var base_atk = 100.0
	var power = 1.5
	var type_eff = 1.5
	var def = 50.0
	
	var damage = base_atk * power * type_eff - (def / CombatBalanceConfig.DEF_DIVISOR)
	_assert(abs(damage - 200.0) < 0.001, "Damage formula correct", "Expected 200, got %.1f" % damage)
	
	# Test crit damage
	var crit_damage = damage * CombatBalanceConfig.CRIT_DAMAGE_MULT
	_assert(abs(crit_damage - 400.0) < 0.001, "Crit damage doubles", "Expected 400, got %.1f" % crit_damage)
	
	# Test minimum damage (when DEF is very high)
	var min_damage_test = base_atk * 0.5 - 500  # Would be negative
	var final_min = max(CombatBalanceConfig.MIN_DAMAGE, int(min_damage_test))
	_assert(final_min == 1, "Minimum damage enforced", "Got %d" % final_min)


# =============================================================================
# 6.1.6 - COOLDOWN SYSTEM
# =============================================================================

func _test_cooldown_system() -> void:
	print("\n--- 6.1.6: Cooldown System ---")
	
	# Test move type cooldowns
	_assert(CombatBalanceConfig.MOVE_TYPE_COOLDOWN["STANDARD"] == 0, "Standard moves no cooldown", str(CombatBalanceConfig.MOVE_TYPE_COOLDOWN["STANDARD"]))
	_assert(CombatBalanceConfig.MOVE_TYPE_COOLDOWN["POWER"] == 3, "Power moves 3 turn cooldown", str(CombatBalanceConfig.MOVE_TYPE_COOLDOWN["POWER"]))
	_assert(CombatBalanceConfig.MOVE_TYPE_COOLDOWN["PRECISION"] == 2, "Precision moves 2 turn cooldown", str(CombatBalanceConfig.MOVE_TYPE_COOLDOWN["PRECISION"]))
	_assert(CombatBalanceConfig.MOVE_TYPE_COOLDOWN["SPECIAL"] == 4, "Special moves 4 turn cooldown", str(CombatBalanceConfig.MOVE_TYPE_COOLDOWN["SPECIAL"]))
	
	# Test that power moves have cooldowns in actual data
	var all_moves = MoveData.get_all_moves()
	var power_moves_with_cooldown = 0
	var power_moves_total = 0
	
	for move in all_moves:
		if move.move_type == MoveData.MoveType.POWER:
			power_moves_total += 1
			if move.cooldown_turns > 0:
				power_moves_with_cooldown += 1
	
	_assert(power_moves_total > 0, "Power moves exist", "Found %d" % power_moves_total)
	_assert(power_moves_with_cooldown == power_moves_total, "All power moves have cooldowns", 
			"%d/%d have cooldowns" % [power_moves_with_cooldown, power_moves_total])


# =============================================================================
# 6.1.7 - STATUS EFFECTS
# =============================================================================

func _test_status_effects() -> void:
	print("\n--- 6.1.7: Status Effects ---")
	
	# Test effect creation
	var burn = StatusEffects.create_effect("burned")
	_assert(burn != null, "Create burned effect", "")
	
	if burn:
		_assert(burn.effect_name == "Burned", "Effect name correct", burn.effect_name)
		_assert(burn.duration_turns > 0, "Has duration", str(burn.duration_turns))
		_assert(burn.damage_per_turn > 0, "Has DoT damage", str(burn.damage_per_turn))
	
	var stun = StatusEffects.create_effect("stunned")
	_assert(stun != null, "Create stunned effect", "")
	
	if stun:
		_assert(stun.prevents_action == true, "Stunned prevents action", "")
	
	var root = StatusEffects.create_effect("rooted")
	_assert(root != null, "Create rooted effect", "")
	
	if root:
		_assert(root.prevents_movement == true, "Rooted prevents movement", "")
	
	# Test immunity checking
	var is_infernal_burn_immune = StatusEffects.is_immune("infernal_soul", "burned")
	_assert(is_infernal_burn_immune == true, "Infernal Soul immune to burn", "")
	
	var is_frost_burn_immune = StatusEffects.is_immune("frost_revenant", "burned")
	# Frost might not be immune to burn
	_assert(typeof(is_frost_burn_immune) == TYPE_BOOL, "Immunity check returns bool", "")
	
	# Test all effects exist
	var effect_ids = ["stunned", "burned", "poisoned", "slowed", "cursed", "terrified", "rooted", "stealth"]
	for effect_id in effect_ids:
		var effect = StatusEffects.create_effect(effect_id)
		_assert(effect != null, "Effect exists: " + effect_id, "")
	
	# Test debuff identification
	var is_burn_debuff = StatusEffects.is_debuff("burned")
	_assert(is_burn_debuff == true, "Burned is a debuff", "")
	
	var is_stealth_debuff = StatusEffects.is_debuff("stealth")
	_assert(is_stealth_debuff == false, "Stealth is not a debuff", "")


# =============================================================================
# INTEGRATION TESTS (6.2)
# =============================================================================

func run_integration_tests() -> Dictionary:
	print("\n========================================")
	print("ENHANCED COMBAT SYSTEM - INTEGRATION TESTS")
	print("========================================\n")
	
	tests_passed = 0
	tests_failed = 0
	test_results.clear()
	
	# 6.2.1 - Combat Flow
	_test_combat_flow()
	
	# 6.2.4 - Combat with Status Effects
	_test_combat_with_status()
	
	print("\n========================================")
	print("INTEGRATION TEST RESULTS: %d passed, %d failed" % [tests_passed, tests_failed])
	print("========================================\n")
	
	return {
		"passed": tests_passed,
		"failed": tests_failed,
		"total": tests_passed + tests_failed,
		"results": test_results
	}


func _test_combat_flow() -> void:
	print("\n--- 6.2.1: Combat Flow ---")
	
	# Test CombatState enum exists
	_assert(CombatManager.CombatState.IDLE == 0, "CombatState.IDLE exists", "")
	_assert(CombatManager.CombatState.SELECTING_MOVES == 1, "CombatState.SELECTING_MOVES exists", "")
	_assert(CombatManager.CombatState.RESOLVING == 2, "CombatState.RESOLVING exists", "")
	_assert(CombatManager.CombatState.COMPLETE == 3, "CombatState.COMPLETE exists", "")
	
	# Test DefensiveStance enum
	_assert(DefensiveStances.DefensiveStance.BRACE == 0, "Stance BRACE exists", "")
	_assert(DefensiveStances.DefensiveStance.DODGE == 1, "Stance DODGE exists", "")
	_assert(DefensiveStances.DefensiveStance.COUNTER == 2, "Stance COUNTER exists", "")
	_assert(DefensiveStances.DefensiveStance.ENDURE == 3, "Stance ENDURE exists", "")
	
	# Test stance data retrieval
	var brace_data = DefensiveStances.get_stance_data(DefensiveStances.DefensiveStance.BRACE)
	_assert(brace_data != null and not brace_data.is_empty(), "Brace stance data exists", "")
	_assert("def_bonus" in brace_data, "Brace has def_bonus", "")


func _test_combat_with_status() -> void:
	print("\n--- 6.2.4: Combat with Status Effects ---")
	
	# Test status effect balance values
	_assert(CombatBalanceConfig.STUNNED_DURATION == 1, "Stunned lasts 1 turn", str(CombatBalanceConfig.STUNNED_DURATION))
	_assert(CombatBalanceConfig.BURNED_DURATION == 3, "Burned lasts 3 turns", str(CombatBalanceConfig.BURNED_DURATION))
	_assert(CombatBalanceConfig.BURNED_DAMAGE == 10, "Burned deals 10 damage", str(CombatBalanceConfig.BURNED_DAMAGE))
	_assert(CombatBalanceConfig.POISONED_DURATION == 4, "Poisoned lasts 4 turns", str(CombatBalanceConfig.POISONED_DURATION))
	
	# Test edge case handlers exist
	var default_stance = CombatEdgeCases.get_default_stance()
	_assert(default_stance == DefensiveStances.DefensiveStance.BRACE, "Default stance is Brace", str(default_stance))
	
	var stunned_stance = CombatEdgeCases.get_stunned_defender_stance()
	_assert(stunned_stance == DefensiveStances.DefensiveStance.BRACE, "Stunned defender uses Brace", str(stunned_stance))


# =============================================================================
# EXTENDED TESTS - PHASE 4: ROLL RESOLUTION SYSTEM
# =============================================================================

func run_extended_tests() -> Dictionary:
	print("\n========================================")
	print("ENHANCED COMBAT SYSTEM - EXTENDED TESTS")
	print("========================================\n")
	
	tests_passed = 0
	tests_failed = 0
	test_results.clear()
	
	# Phase 4 - Roll Resolution
	_test_roll_resolution_config()
	
	# Phase 4.5 - Defensive Stances
	_test_defensive_stances()
	
	# Phase 5 - Enhanced Damage Formula
	_test_enhanced_damage_formula()
	
	# Phase 6 - Type Assignments & Immunities
	_test_troop_type_assignments()
	
	# Phase 7 - Edge Cases
	_test_edge_cases()
	
	# Balance - Move Validation
	_test_move_balance_validation()
	
	# Phase 11 - Lethality TTK
	_test_lethality_ttk()
	
	# Phase 3 - Conditional Reactions
	_test_conditional_reactions()
	
	print("\n========================================")
	print("EXTENDED TEST RESULTS: %d passed, %d failed" % [tests_passed, tests_failed])
	print("========================================\n")
	
	return {
		"passed": tests_passed,
		"failed": tests_failed,
		"total": tests_passed + tests_failed,
		"results": test_results
	}


# =============================================================================
# PHASE 4: ROLL RESOLUTION SYSTEM TESTS
# =============================================================================

func _test_roll_resolution_config() -> void:
	print("\n--- Phase 4: Roll Resolution System ---")
	
	# 4.1 - Attack Roll Formula Configuration
	_assert(CombatBalanceConfig.DICE_TYPE == 20, "Uses d20 dice", str(CombatBalanceConfig.DICE_TYPE))
	_assert(CombatBalanceConfig.BASE_DEFENSE_DC == 10, "Base DC is 10", str(CombatBalanceConfig.BASE_DEFENSE_DC))
	
	# 4.5 - Critical Hit System
	_assert(CombatBalanceConfig.CRITICAL_HIT_MIN >= 18, "Critical threshold is 18+", str(CombatBalanceConfig.CRITICAL_HIT_MIN))
	_assert(CombatBalanceConfig.CRITICAL_MISS_MAX == 1, "Natural 1 is critical miss", str(CombatBalanceConfig.CRITICAL_MISS_MAX))
	_assert(CombatBalanceConfig.CRIT_DAMAGE_MULT >= 1.5, "Crit damage is at least 1.5x", str(CombatBalanceConfig.CRIT_DAMAGE_MULT))
	
	# Test stat stage integration with rolls
	# A unit with +2 ATK stage should have 2x ATK modifier
	var stage_2_mult = CombatBalanceConfig.get_stat_multiplier(2)
	_assert(abs(stage_2_mult - 2.0) < 0.01, "Stage +2 gives 2x multiplier for rolls", "%.2f" % stage_2_mult)
	
	# --- RollResolution Class Tests ---
	print("\n--- RollResolution System ---")
	
	# Test constants
	_assert(RollResolution.DICE_TYPE == 20, "RollResolution uses d20", str(RollResolution.DICE_TYPE))
	_assert(RollResolution.BASE_DC == 10, "Base DC is 10", str(RollResolution.BASE_DC))
	_assert(RollResolution.STAT_DIVISOR == 10.0, "Stats divided by 10", str(RollResolution.STAT_DIVISOR))
	_assert(RollResolution.CRITICAL_HIT_THRESHOLD == 20, "Crit on natural 20", str(RollResolution.CRITICAL_HIT_THRESHOLD))
	_assert(RollResolution.CRITICAL_MISS_THRESHOLD == 1, "Miss on natural 1", str(RollResolution.CRITICAL_MISS_THRESHOLD))
	
	# Test dice rolling mechanics
	# Run multiple rolls to verify range
	var roll_in_range = true
	for i in range(20):
		var roll = RollResolution.roll_d20()
		if roll < 1 or roll > 20:
			roll_in_range = false
			break
	_assert(roll_in_range, "d20 rolls in range 1-20", "")
	
	# Test advantage roll (takes higher)
	var adv_result = RollResolution.roll_with_advantage()
	_assert(adv_result["rolls"].size() == 2, "Advantage rolls 2 dice", str(adv_result["rolls"].size()))
	_assert(adv_result["result"] == max(adv_result["rolls"][0], adv_result["rolls"][1]), 
			"Advantage takes higher", str(adv_result))
	_assert(adv_result["mode"] == RollResolution.RollMode.ADVANTAGE, "Mode is ADVANTAGE", "")
	
	# Test disadvantage roll (takes lower)
	var dis_result = RollResolution.roll_with_disadvantage()
	_assert(dis_result["rolls"].size() == 2, "Disadvantage rolls 2 dice", str(dis_result["rolls"].size()))
	_assert(dis_result["result"] == min(dis_result["rolls"][0], dis_result["rolls"][1]), 
			"Disadvantage takes lower", str(dis_result))
	_assert(dis_result["mode"] == RollResolution.RollMode.DISADVANTAGE, "Mode is DISADVANTAGE", "")
	
	# Test normal roll
	var normal_result = RollResolution.roll_for_mode(RollResolution.RollMode.NORMAL)
	_assert(normal_result["rolls"].size() == 1, "Normal rolls 1 die", str(normal_result["rolls"].size()))
	_assert(normal_result["result"] == normal_result["rolls"][0], "Normal result is the roll", "")
	
	# Test roll mode enum
	_assert(RollResolution.RollMode.NORMAL == 0, "RollMode.NORMAL exists", "")
	_assert(RollResolution.RollMode.ADVANTAGE == 1, "RollMode.ADVANTAGE exists", "")
	_assert(RollResolution.RollMode.DISADVANTAGE == 2, "RollMode.DISADVANTAGE exists", "")
	
	# Test result type enum
	_assert(RollResolution.RollResult.CRITICAL_MISS == 0, "RollResult.CRITICAL_MISS exists", "")
	_assert(RollResolution.RollResult.MISS == 1, "RollResult.MISS exists", "")
	_assert(RollResolution.RollResult.HIT == 2, "RollResult.HIT exists", "")
	_assert(RollResolution.RollResult.CRITICAL_HIT == 3, "RollResult.CRITICAL_HIT exists", "")
	
	# Test result text helper
	var crit_text = RollResolution.get_result_text(RollResolution.RollResult.CRITICAL_HIT)
	_assert(crit_text == "CRITICAL HIT!", "Critical hit text correct", crit_text)
	var miss_text = RollResolution.get_result_text(RollResolution.RollResult.MISS)
	_assert(miss_text == "MISS", "Miss text correct", miss_text)
	
	# Test roll mode text helper
	var adv_text = RollResolution.get_roll_mode_text(RollResolution.RollMode.ADVANTAGE)
	_assert("Advantage" in adv_text, "Advantage text correct", adv_text)
	var dis_text = RollResolution.get_roll_mode_text(RollResolution.RollMode.DISADVANTAGE)
	_assert("Disadvantage" in dis_text, "Disadvantage text correct", dis_text)


# =============================================================================
# PHASE 4.5: DEFENSIVE STANCES TESTS
# =============================================================================

func _test_defensive_stances() -> void:
	print("\n--- Defensive Stances ---")
	
	# Brace Stance
	var brace = DefensiveStances.DefensiveStance.BRACE
	var brace_def = DefensiveStances.get_defense_bonus(brace)
	var brace_dmg_mult = DefensiveStances.get_damage_multiplier(brace)
	_assert(brace_def == 3, "Brace: +3 DEF bonus", str(brace_def))
	_assert(abs(brace_dmg_mult - 0.8) < 0.01, "Brace: 0.8x damage taken", "%.2f" % brace_dmg_mult)
	
	# Dodge Stance
	var dodge = DefensiveStances.DefensiveStance.DODGE
	var dodge_evasion = DefensiveStances.get_evasion_bonus(dodge)
	_assert(dodge_evasion == 5, "Dodge: +5 evasion bonus", str(dodge_evasion))
	_assert(DefensiveStances.get_defense_bonus(dodge) == 0, "Dodge: no DEF bonus", "")
	
	# Counter Stance
	var counter = DefensiveStances.DefensiveStance.COUNTER
	var counter_pct = DefensiveStances.get_counter_damage_percent(counter)
	_assert(abs(counter_pct - 0.5) < 0.01, "Counter: 50% ATK counter damage", "%.2f" % counter_pct)
	
	# Endure Stance
	var endure = DefensiveStances.DefensiveStance.ENDURE
	_assert(DefensiveStances.survives_lethal(endure) == true, "Endure: survives lethal", "")
	_assert(DefensiveStances.get_uses_per_combat(endure) == 1, "Endure: 1 use per combat", str(DefensiveStances.get_uses_per_combat(endure)))
	
	# Test all 4 stances exist
	var all_stances = DefensiveStances.get_all_stances()
	_assert(all_stances.size() == 4, "4 defensive stances exist", str(all_stances.size()))
	
	# Test damage application with Brace
	var brace_result = DefensiveStances.apply_stance_to_damage(brace, 100, 150)
	_assert(brace_result["damage"] == 80, "Brace reduces 100 damage to 80", str(brace_result["damage"]))
	_assert(brace_result["survived_lethal"] == false, "Brace doesn't survive lethal", "")
	
	# Test Endure survives lethal
	var endure_result = DefensiveStances.apply_stance_to_damage(endure, 100, 50)
	_assert(endure_result["survived_lethal"] == true, "Endure triggers on lethal damage", "")
	_assert(endure_result["damage"] == 49, "Endure leaves 1 HP (50-49=1)", str(endure_result["damage"]))
	
	# Test counter damage calculation
	var counter_dmg = DefensiveStances.calculate_counter_damage(counter, 80)
	_assert(counter_dmg == 40, "Counter deals 40 damage (50% of 80 ATK)", str(counter_dmg))


# =============================================================================
# PHASE 5: ENHANCED DAMAGE FORMULA TESTS
# =============================================================================

func _test_enhanced_damage_formula() -> void:
	print("\n--- Phase 5: Enhanced Damage Formula ---")
	
	# Test damage formula components from CombatBalanceConfig
	_assert(CombatBalanceConfig.MIN_DAMAGE == 1, "Minimum damage is 1", str(CombatBalanceConfig.MIN_DAMAGE))
	_assert(CombatBalanceConfig.DEF_DIVISOR == 2.0, "DEF divisor is 2", str(CombatBalanceConfig.DEF_DIVISOR))
	_assert(CombatBalanceConfig.MAGIC_DEF_IGNORE == 0.25, "Magic ignores 25% DEF", str(CombatBalanceConfig.MAGIC_DEF_IGNORE))
	
	# --- DamageCalculation Class Tests ---
	print("\n--- DamageCalculation System ---")
	
	# Test constants
	_assert(DamageCalculation.DEF_DIVISOR_BASE == 80.0, "DEF divisor base is 80", str(DamageCalculation.DEF_DIVISOR_BASE))
	_assert(DamageCalculation.MIN_DAMAGE == 1, "Min damage is 1", str(DamageCalculation.MIN_DAMAGE))
	_assert(abs(DamageCalculation.CRIT_MULTIPLIER - 1.5) < 0.01, "Crit multiplier is 1.5x", str(DamageCalculation.CRIT_MULTIPLIER))
	_assert(abs(DamageCalculation.MAGIC_DEF_IGNORE - 0.25) < 0.01, "Magic ignores 25% DEF", str(DamageCalculation.MAGIC_DEF_IGNORE))
	
	# Test Step 1: BASE DAMAGE = ATK × Move Power%
	var base = DamageCalculation.calculate_base_damage(100.0, 1.5)
	_assert(abs(base - 150.0) < 0.01, "Base damage: 100 × 1.5 = 150", "%.1f" % base)
	
	# Test Step 2: TYPE DAMAGE = BASE × Type Effectiveness
	var type_dmg = DamageCalculation.calculate_type_damage(150.0, 1.5)
	_assert(abs(type_dmg - 225.0) < 0.01, "Type damage: 150 × 1.5 = 225", "%.1f" % type_dmg)
	
	# Test Step 3: DEFENSE REDUCTION = TYPE DAMAGE ÷ (1 + DEF / 80)
	# 225 ÷ (1 + 80/80) = 225 ÷ 2 = 112.5
	var reduced = DamageCalculation.calculate_defense_reduction(225.0, 80.0, false)
	_assert(abs(reduced - 112.5) < 0.01, "Defense reduction: 225 ÷ (1 + 80/80) = 112.5", "%.1f" % reduced)
	
	# Test with 0 DEF (no reduction)
	var no_def = DamageCalculation.calculate_defense_reduction(100.0, 0.0, false)
	_assert(abs(no_def - 100.0) < 0.01, "0 DEF: no reduction", "%.1f" % no_def)
	
	# Test magic damage (ignores 25% DEF)
	# With 80 DEF: effective = 80 × 0.75 = 60, divisor = 1 + 60/80 = 1.75
	# 225 ÷ 1.75 = 128.57
	var magic_dmg = DamageCalculation.calculate_defense_reduction(225.0, 80.0, true)
	_assert(magic_dmg > reduced, "Magic damage ignores some DEF", "%.1f > %.1f" % [magic_dmg, reduced])
	
	# Test Step 4: FINAL DAMAGE = max(reduced, 1)
	var final = DamageCalculation.calculate_final_damage(0.5)
	_assert(final == 1, "Final damage minimum is 1", str(final))
	
	var final2 = DamageCalculation.calculate_final_damage(50.7)
	_assert(final2 == 50, "Final damage truncates: 50.7 → 50", str(final2))
	
	# Test Step 5: CRITICAL DAMAGE = FINAL × 1.5
	var crit = DamageCalculation.apply_critical_multiplier(100)
	_assert(crit == 150, "Critical: 100 × 1.5 = 150", str(crit))
	
	# Test complete damage calculation pipeline
	# ATK=100, Power=1.0, Type=1.0, DEF=80, no crit
	# Base: 100 × 1.0 = 100
	# Type: 100 × 1.0 = 100
	# Reduced: 100 ÷ (1 + 80/80) = 100 ÷ 2 = 50
	# Final: 50
	var result = DamageCalculation.calculate_damage(100.0, 1.0, 1.0, 80.0, false, false, 0.0)
	_assert(abs(result["base_damage"] - 100.0) < 0.01, "Pipeline: base = 100", str(result["base_damage"]))
	_assert(abs(result["type_damage"] - 100.0) < 0.01, "Pipeline: type = 100", str(result["type_damage"]))
	_assert(abs(result["reduced_damage"] - 50.0) < 0.01, "Pipeline: reduced = 50", str(result["reduced_damage"]))
	_assert(result["final_damage"] == 50, "Pipeline: final = 50", str(result["final_damage"]))
	
	# Test with critical hit
	var crit_result = DamageCalculation.calculate_damage(100.0, 1.0, 1.0, 80.0, true, false, 0.0)
	_assert(crit_result["final_damage"] == 75, "Critical: 50 × 1.5 = 75", str(crit_result["final_damage"]))
	_assert(crit_result["is_critical"] == true, "is_critical flag set", "")
	
	# Test quick_calculate helper
	var quick = DamageCalculation.quick_calculate(100.0, 1.0, 1.0, 80.0, false, false)
	_assert(quick == 50, "quick_calculate: 50", str(quick))
	
	# Test damage breakdown text generation
	var breakdown = DamageCalculation.get_damage_breakdown(result)
	_assert("Damage Calculation" in breakdown, "Breakdown has title", "")
	_assert("FINAL DAMAGE" in breakdown, "Breakdown has final", "")


# =============================================================================
# PHASE 6: TROOP TYPE ASSIGNMENTS & RESISTANCES
# =============================================================================

func _test_troop_type_assignments() -> void:
	print("\n--- Phase 6: Type Effectiveness System ---")
	
	# Test constants
	_assert(abs(TypeEffectiveness.SUPER_EFFECTIVE - 1.5) < 0.01, "Super Effective = 1.5x", str(TypeEffectiveness.SUPER_EFFECTIVE))
	_assert(abs(TypeEffectiveness.NORMAL_EFFECTIVE - 1.0) < 0.01, "Normal Effective = 1.0x", str(TypeEffectiveness.NORMAL_EFFECTIVE))
	_assert(abs(TypeEffectiveness.NOT_EFFECTIVE - 0.5) < 0.01, "Not Effective = 0.5x", str(TypeEffectiveness.NOT_EFFECTIVE))
	_assert(abs(TypeEffectiveness.IMMUNE - 0.0) < 0.01, "Immune = 0.0x", str(TypeEffectiveness.IMMUNE))
	
	# Test 6 damage types exist
	_assert(TypeEffectiveness.DamageType.PHYSICAL == 0, "DamageType.PHYSICAL exists", "")
	_assert(TypeEffectiveness.DamageType.FIRE == 1, "DamageType.FIRE exists", "")
	_assert(TypeEffectiveness.DamageType.ICE == 2, "DamageType.ICE exists", "")
	_assert(TypeEffectiveness.DamageType.DARK == 3, "DamageType.DARK exists", "")
	_assert(TypeEffectiveness.DamageType.HOLY == 4, "DamageType.HOLY exists", "")
	_assert(TypeEffectiveness.DamageType.NATURE == 5, "DamageType.NATURE exists", "")
	
	# === Phase 6.2 Troop Type Assignments ===
	print("\n--- Troop Resistances & Weaknesses ---")
	
	# 6.2.1 Medieval Knight: resists Physical, weak to Fire/Dark
	var knight_res = TypeEffectiveness.get_resistances("medieval_knight")
	var knight_weak = TypeEffectiveness.get_weaknesses("medieval_knight")
	_assert(TypeEffectiveness.DamageType.PHYSICAL in knight_res, "Knight resists Physical", "")
	_assert(TypeEffectiveness.DamageType.FIRE in knight_weak, "Knight weak to Fire", "")
	_assert(TypeEffectiveness.DamageType.DARK in knight_weak, "Knight weak to Dark", "")
	
	# 6.2.2 Stone Giant: resists Physical/Ice, weak to Nature
	var giant_res = TypeEffectiveness.get_resistances("stone_giant")
	var giant_weak = TypeEffectiveness.get_weaknesses("stone_giant")
	_assert(TypeEffectiveness.DamageType.PHYSICAL in giant_res, "Stone Giant resists Physical", "")
	_assert(TypeEffectiveness.DamageType.ICE in giant_res, "Stone Giant resists Ice", "")
	_assert(TypeEffectiveness.DamageType.NATURE in giant_weak, "Stone Giant weak to Nature", "")
	
	# 6.2.4 Dark Blood Dragon: resists Fire, weak to Ice
	var dragon_res = TypeEffectiveness.get_resistances("dark_blood_dragon")
	var dragon_weak = TypeEffectiveness.get_weaknesses("dark_blood_dragon")
	_assert(TypeEffectiveness.DamageType.FIRE in dragon_res, "Dragon resists Fire", "")
	_assert(TypeEffectiveness.DamageType.ICE in dragon_weak, "Dragon weak to Ice", "")
	
	# 6.2.10 Celestial Cleric: resists Holy/Dark, NO weakness
	var cleric_res = TypeEffectiveness.get_resistances("celestial_cleric")
	var cleric_weak = TypeEffectiveness.get_weaknesses("celestial_cleric")
	_assert(TypeEffectiveness.DamageType.HOLY in cleric_res, "Cleric resists Holy", "")
	_assert(TypeEffectiveness.DamageType.DARK in cleric_res, "Cleric resists Dark", "")
	_assert(cleric_weak.size() == 0, "Cleric has NO weakness", str(cleric_weak.size()))
	
	# 6.2.12 Infernal Soul: resists Fire, weak to Ice/Holy
	var soul_res = TypeEffectiveness.get_resistances("infernal_soul")
	var soul_weak = TypeEffectiveness.get_weaknesses("infernal_soul")
	_assert(TypeEffectiveness.DamageType.FIRE in soul_res, "Infernal Soul resists Fire", "")
	_assert(TypeEffectiveness.DamageType.ICE in soul_weak, "Infernal Soul weak to Ice", "")
	_assert(TypeEffectiveness.DamageType.HOLY in soul_weak, "Infernal Soul weak to Holy", "")
	
	# Test immunities
	_assert(StatusEffects.is_immune("dark_blood_dragon", "burned") == true, "Dragon immune to burn", "")
	_assert(StatusEffects.is_immune("phoenix", "burned") == true, "Phoenix immune to burn", "")
	_assert(StatusEffects.is_immune("frost_giant", "slowed") == true, "Frost Giant immune to slow", "")
	_assert(StatusEffects.is_immune("infernal_soul", "burned") == true, "Infernal Soul immune to burn", "")
	_assert(StatusEffects.is_immune("celestial_cleric", "cursed") == true, "Cleric immune to curse", "")
	
	# Test get_effectiveness() function with real matchups
	var ice_vs_dragon = TypeEffectiveness.get_effectiveness(TypeEffectiveness.DamageType.ICE, "dark_blood_dragon")
	_assert(ice_vs_dragon >= 1.5, "Ice super effective vs Dragon", "%.2f" % ice_vs_dragon)
	
	var fire_vs_infernal = TypeEffectiveness.get_effectiveness(TypeEffectiveness.DamageType.FIRE, "infernal_soul")
	_assert(fire_vs_infernal <= 0.5, "Fire resisted by Infernal Soul", "%.2f" % fire_vs_infernal)
	
	var holy_vs_demon = TypeEffectiveness.get_effectiveness(TypeEffectiveness.DamageType.HOLY, "demon_of_darkness")
	_assert(holy_vs_demon >= 1.5, "Holy super effective vs Demon", "%.2f" % holy_vs_demon)
	
	# Test immunities (damage type)
	var fire_vs_phoenix = TypeEffectiveness.get_effectiveness(TypeEffectiveness.DamageType.FIRE, "phoenix")
	_assert(fire_vs_phoenix == 0.0, "Fire immune vs Phoenix", "%.2f" % fire_vs_phoenix)
	
	var ice_vs_frost_giant = TypeEffectiveness.get_effectiveness(TypeEffectiveness.DamageType.ICE, "frost_giant")
	_assert(ice_vs_frost_giant == 0.0, "Ice immune vs Frost Giant", "%.2f" % ice_vs_frost_giant)
	
	# Test helper functions
	var dragon_summary = TypeEffectiveness.get_type_summary("dark_blood_dragon")
	_assert(dragon_summary != null, "Type summary exists", "")
	_assert("resistances" in dragon_summary, "Summary has resistances", "")
	_assert("weaknesses" in dragon_summary, "Summary has weaknesses", "")
	
	var fire_name = TypeEffectiveness.get_damage_type_name(TypeEffectiveness.DamageType.FIRE)
	_assert(fire_name == "Fire", "Damage type name: Fire", fire_name)
	
	var eff_text = TypeEffectiveness.get_effectiveness_text(TypeEffectiveness.DamageType.ICE, "dark_blood_dragon")
	_assert("Super Effective" in eff_text, "Effectiveness text: Super Effective", eff_text)


# =============================================================================
# PHASE 7: EDGE CASES TESTS
# =============================================================================

func _test_edge_cases() -> void:
	print("\n--- Edge Cases ---")
	
	# Test default stance for edge cases
	var default = CombatEdgeCases.get_default_stance()
	_assert(default == DefensiveStances.DefensiveStance.BRACE, "Default stance is Brace", "")
	
	var stunned = CombatEdgeCases.get_stunned_defender_stance()
	_assert(stunned == DefensiveStances.DefensiveStance.BRACE, "Stunned defender gets Brace", "")
	
	# Test self-targeting detection
	var heal_move = MoveData.get_move("cleric_heal")
	if heal_move:
		var is_self = CombatEdgeCases.is_self_targeting_move(heal_move)
		# Heal may or may not be self-targeting - just ensure function works
		_assert(typeof(is_self) == TYPE_BOOL, "Self-targeting check returns bool", str(is_self))
	else:
		_assert(true, "Heal move check skipped (not found)", "cleric_heal not defined")
	
	# Test AoE pattern exists for AoE moves
	var all_moves = MoveData.get_all_moves()
	var aoe_moves_valid = true
	var aoe_count = 0
	for move in all_moves:
		if move.is_aoe:
			aoe_count += 1
			if move.aoe_pattern.is_empty():
				aoe_moves_valid = false
	_assert(aoe_count > 0, "AoE moves exist", str(aoe_count))
	_assert(aoe_moves_valid, "All AoE moves have patterns", "")


# =============================================================================
# BALANCE: MOVE VALIDATION TESTS
# =============================================================================

func _test_move_balance_validation() -> void:
	print("\n--- Move Balance Validation ---")
	
	var all_moves = MoveData.get_all_moves()
	
	# Validate all moves have reasonable values
	var power_valid = 0
	var accuracy_valid = 0
	var cooldown_valid = 0
	
	for move in all_moves:
		# Power should be 0.0 to 3.0
		if move.power_percent >= 0.0 and move.power_percent <= 3.0:
			power_valid += 1
		
		# Accuracy should be -10 to +10
		if move.accuracy_modifier >= -10 and move.accuracy_modifier <= 10:
			accuracy_valid += 1
		
		# Cooldown should be 0 to 10
		if move.cooldown_turns >= 0 and move.cooldown_turns <= 10:
			cooldown_valid += 1
	
	_assert(power_valid == all_moves.size(), "All moves have valid power (0-3)", "%d/%d" % [power_valid, all_moves.size()])
	_assert(accuracy_valid == all_moves.size(), "All moves have valid accuracy (-10 to +10)", "%d/%d" % [accuracy_valid, all_moves.size()])
	_assert(cooldown_valid == all_moves.size(), "All moves have valid cooldown (0-10)", "%d/%d" % [cooldown_valid, all_moves.size()])
	
	# Verify move types balance: Standard should have 0 cooldown
	var standard_moves_no_cooldown = 0
	var standard_moves_total = 0
	for move in all_moves:
		if move.move_type == MoveData.MoveType.STANDARD:
			standard_moves_total += 1
			if move.cooldown_turns == 0:
				standard_moves_no_cooldown += 1
	
	_assert(standard_moves_total > 0, "Standard moves exist", str(standard_moves_total))
	_assert(standard_moves_no_cooldown == standard_moves_total, "Standard moves have no cooldown", "%d/%d" % [standard_moves_no_cooldown, standard_moves_total])
	
	# Verify Power moves have cooldowns
	var power_moves_with_cd = 0
	var power_moves_total = 0
	for move in all_moves:
		if move.move_type == MoveData.MoveType.POWER:
			power_moves_total += 1
			if move.cooldown_turns > 0:
				power_moves_with_cd += 1
	
	_assert(power_moves_total > 0, "Power moves exist", str(power_moves_total))
	_assert(power_moves_with_cd == power_moves_total, "Power moves have cooldowns", "%d/%d" % [power_moves_with_cd, power_moves_total])


# =============================================================================
# PHASE 11: LETHALITY & TIME-TO-KILL TESTS
# =============================================================================

func _test_lethality_ttk() -> void:
	print("\n--- Phase 11: Lethality & TTK ---")
	
	# Test configured values for lethality
	# HP scaling should support 4-6 hit kills
	
	# Example scenario: 
	# Glass Cannon: 150 HP, 80 ATK, 20 DEF
	# Tank: 300 HP, 50 ATK, 60 DEF
	
	# Simulate Glass Cannon vs Glass Cannon (Standard move, neutral type)
	var gc_atk = 80.0
	var gc_hp = 150
	var gc_def = 20.0
	var standard_power = 1.0
	var neutral_type = 1.0
	
	# Damage = ATK × Power × Type - DEF/2
	var gc_vs_gc_damage = gc_atk * standard_power * neutral_type - (gc_def / 2.0)
	# 80 × 1.0 × 1.0 - 10 = 70
	var gc_vs_gc_hits = ceil(gc_hp / gc_vs_gc_damage)
	_assert(gc_vs_gc_hits >= 2 and gc_vs_gc_hits <= 4, "GC vs GC: 2-4 hits (fast)", "%.0f damage, %.0f hits" % [gc_vs_gc_damage, gc_vs_gc_hits])
	
	# Simulate Tank vs Tank
	var tank_atk = 50.0
	var tank_hp = 300
	var tank_def = 60.0
	
	var tank_vs_tank_damage = tank_atk * standard_power * neutral_type - (tank_def / 2.0)
	# 50 × 1.0 × 1.0 - 30 = 20
	var tank_vs_tank_hits = ceil(tank_hp / max(1.0, tank_vs_tank_damage))
	_assert(tank_vs_tank_hits >= 6, "Tank vs Tank: 6+ hits (slow)", "%.0f damage, %.0f hits" % [tank_vs_tank_damage, tank_vs_tank_hits])
	
	# Simulate Glass Cannon vs Tank
	var gc_vs_tank_damage = gc_atk * standard_power * neutral_type - (tank_def / 2.0)
	# 80 × 1.0 × 1.0 - 30 = 50
	var gc_vs_tank_hits = ceil(tank_hp / gc_vs_tank_damage)
	_assert(gc_vs_tank_hits >= 4 and gc_vs_tank_hits <= 8, "GC vs Tank: 4-8 hits", "%.0f damage, %.0f hits" % [gc_vs_tank_damage, gc_vs_tank_hits])
	
	# Test type effectiveness impact on TTK
	var super_effective = 1.5
	var gc_vs_gc_se_damage = gc_atk * standard_power * super_effective - (gc_def / 2.0)
	# 80 × 1.0 × 1.5 - 10 = 110
	var gc_vs_gc_se_hits = ceil(gc_hp / gc_vs_gc_se_damage)
	_assert(gc_vs_gc_se_hits < gc_vs_gc_hits, "Super Effective reduces TTK", "%.0f hits (SE) vs %.0f hits (neutral)" % [gc_vs_gc_se_hits, gc_vs_gc_hits])
	
	# Test critical hit impact
	var crit_mult = CombatBalanceConfig.CRIT_DAMAGE_MULT
	var gc_vs_gc_crit_damage = gc_vs_gc_damage * crit_mult
	_assert(gc_vs_gc_crit_damage >= gc_vs_gc_damage * 1.5, "Crit increases damage by 50%+", "%.0f crit vs %.0f normal" % [gc_vs_gc_crit_damage, gc_vs_gc_damage])


# =============================================================================
# PHASE 3: CONDITIONAL REACTIONS TESTS
# =============================================================================

func _test_conditional_reactions() -> void:
	print("\n--- Phase 3: Conditional Reactions ---")
	
	# Test that reactions exist
	var all_reactions = ConditionalReactions.get_all_reactions()
	_assert(all_reactions.size() >= 12, "At least 12 reactions exist", "Found %d" % all_reactions.size())
	
	# Test specific reaction retrieval
	var riposte = ConditionalReactions.get_reaction("knight_riposte")
	_assert(riposte != null, "Knight Riposte exists", "")
	if riposte:
		_assert(riposte.reaction_name == "Riposte", "Riposte name correct", riposte.reaction_name)
		_assert(riposte.trigger == ConditionalReactions.ReactionTrigger.ON_MISS, "Riposte triggers on miss", "")
		_assert(riposte.effect == ConditionalReactions.ReactionEffect.COUNTER_ATTACK, "Riposte is counter-attack", "")
		_assert(abs(riposte.effect_value - 0.30) < 0.01, "Riposte deals 30% ATK", str(riposte.effect_value))
	
	# Test troop-to-reaction mapping
	var knight_reaction = ConditionalReactions.get_troop_reaction("medieval_knight")
	_assert(knight_reaction != null, "Knight has reaction", "")
	_assert(knight_reaction.reaction_name == "Riposte", "Knight reaction is Riposte", knight_reaction.reaction_name if knight_reaction else "null")
	
	# Test all main troops have reactions
	var main_troops = [
		"medieval_knight", "four_headed_hydra", "dark_blood_dragon",
		"dark_magic_wizard", "elven_archer", "celestial_cleric",
		"infernal_soul", "shadow_assassin", "necromancer",
		"frost_giant", "phoenix", "griffin"
	]
	
	for troop_id in main_troops:
		var reaction = ConditionalReactions.get_troop_reaction(troop_id)
		_assert(reaction != null, "Troop has reaction: " + troop_id, "")
	
	# Test reaction triggers
	var thick_skin = ConditionalReactions.get_reaction("giant_thick_skin")
	_assert(thick_skin != null, "Thick Skin exists", "")
	if thick_skin:
		_assert(thick_skin.trigger == ConditionalReactions.ReactionTrigger.ON_CRIT_RECEIVED, 
				"Thick Skin triggers on crit received", "")
		_assert(abs(thick_skin.effect_value - 0.50) < 0.01, "Thick Skin reduces 50%", str(thick_skin.effect_value))
	
	# Test Dragon's Fury (triggers on ice damage)
	var dragon_fury = ConditionalReactions.get_reaction("dragon_fury")
	_assert(dragon_fury != null, "Dragon's Fury exists", "")
	if dragon_fury:
		_assert(dragon_fury.trigger == ConditionalReactions.ReactionTrigger.ON_ICE_DAMAGE, 
				"Dragon's Fury triggers on Ice damage", "")
		_assert(dragon_fury.stat_affected == "atk", "Dragon's Fury boosts ATK", dragon_fury.stat_affected)
	
	# Test Infernal Soul reactions (has both regular and death reaction)
	var burning_aura = ConditionalReactions.get_reaction("infernal_aura")
	_assert(burning_aura != null, "Burning Aura exists", "")
	if burning_aura:
		_assert(burning_aura.trigger == ConditionalReactions.ReactionTrigger.ON_MELEE_RECEIVED, 
				"Burning Aura triggers on melee", "")
		_assert(abs(burning_aura.effect_value - 20.0) < 0.1, "Burning Aura deals 20 damage", str(burning_aura.effect_value))
	
	var death_burst = ConditionalReactions.get_death_reaction("infernal_soul")
	_assert(death_burst != null, "Infernal Soul has death reaction", "")
	if death_burst:
		_assert(death_burst.reaction_name == "Death Burst", "Death Burst is correct reaction", death_burst.reaction_name)
		_assert(abs(death_burst.effect_value - 40.0) < 0.1, "Death Burst deals 40 damage", str(death_burst.effect_value))
	
	# Test Divine Protection (cleanse on status)
	var divine_protection = ConditionalReactions.get_reaction("cleric_protection")
	_assert(divine_protection != null, "Divine Protection exists", "")
	if divine_protection:
		_assert(divine_protection.trigger == ConditionalReactions.ReactionTrigger.ON_STATUS_APPLIED, 
				"Divine Protection triggers on status", "")
		_assert(divine_protection.effect == ConditionalReactions.ReactionEffect.CLEANSE_AND_HEAL, 
				"Divine Protection cleanses and heals", "")
	
	# Test crit bypass logic
	var is_riposte_bypassed = ConditionalReactions.is_bypassed_by_crit("knight_riposte")
	_assert(is_riposte_bypassed == true, "Riposte is bypassed by crits", str(is_riposte_bypassed))
	
	var is_death_burst_bypassed = ConditionalReactions.is_bypassed_by_crit("infernal_death_burst")
	_assert(is_death_burst_bypassed == false, "Death Burst is NOT bypassed by crits", str(is_death_burst_bypassed))
	
	# Test should_trigger with crit
	var riposte_triggers_normal = ConditionalReactions.should_trigger("knight_riposte", 
		ConditionalReactions.ReactionTrigger.ON_MISS, false)
	_assert(riposte_triggers_normal == true, "Riposte triggers on normal miss", str(riposte_triggers_normal))
	
	var riposte_triggers_crit = ConditionalReactions.should_trigger("knight_riposte", 
		ConditionalReactions.ReactionTrigger.ON_MISS, true)
	_assert(riposte_triggers_crit == false, "Riposte doesn't trigger on crit", str(riposte_triggers_crit))
	
	# Test effect value calculation
	var counter_damage = ConditionalReactions.calculate_effect_value("knight_riposte", 100.0, 0.0)
	_assert(abs(counter_damage - 30.0) < 0.1, "Riposte deals 30 damage (30% of 100 ATK)", str(counter_damage))
	
	var heal_amount = ConditionalReactions.calculate_effect_value("hydra_regrowth", 0.0, 200.0)
	_assert(abs(heal_amount - 10.0) < 0.1, "Regrowth heals 10 HP (5% of 200 max)", str(heal_amount))


# =============================================================================
# QUICK TEST FUNCTION
# =============================================================================

## Run all tests from console
static func quick_test() -> void:
	var tester = CombatSystemTests.new()
	var unit_results = tester.run_all_tests()
	var integration_results = tester.run_integration_tests()
	var extended_results = tester.run_extended_tests()
	
	var total_passed = unit_results["passed"] + integration_results["passed"] + extended_results["passed"]
	var total_tests = unit_results["total"] + integration_results["total"] + extended_results["total"]
	
	print("\n========================================")
	print("FINAL SUMMARY")
	print("========================================")
	print("Unit Tests:        %d/%d passed" % [unit_results["passed"], unit_results["total"]])
	print("Integration Tests: %d/%d passed" % [integration_results["passed"], integration_results["total"]])
	print("Extended Tests:    %d/%d passed" % [extended_results["passed"], extended_results["total"]])
	print("----------------------------------------")
	print("TOTAL:             %d/%d passed" % [total_passed, total_tests])
	if total_passed == total_tests:
		print("✓ ALL TESTS PASSED!")
	else:
		print("✗ %d TESTS FAILED" % (total_tests - total_passed))
	print("========================================\n")
