## Combat Edge Cases Handler
## Handles special combat scenarios and edge cases
## Self-targeting, AoE, resurrection, self-destruct, etc.
class_name CombatEdgeCases
extends RefCounted


# =============================================================================
# 5.4.1 - SELECTION TIMEOUT
# =============================================================================

## Get default move for timeout (first available Standard move)
static func get_default_move(troop: Node) -> MoveData.Move:
	if troop == null or not "available_moves" in troop:
		return null
	
	# Find first available Standard move
	for move in troop.available_moves:
		if move.move_type == MoveData.MoveType.STANDARD:
			if troop.is_move_available(move.move_id):
				return move
	
	# Fall back to any available move
	for move in troop.available_moves:
		if troop.is_move_available(move.move_id):
			return move
	
	# No moves available (all on cooldown)
	return troop.available_moves[0] if troop.available_moves.size() > 0 else null


## Get default stance for timeout
static func get_default_stance() -> int:
	return DefensiveStances.DefensiveStance.BRACE


## Handle stunned defender (can't choose stance)
static func get_stunned_defender_stance() -> int:
	# Stunned units can only use Brace
	return DefensiveStances.DefensiveStance.BRACE


# =============================================================================
# 5.4.2 - TROOP DEATH DURING STATUS TICK
# =============================================================================

## Handle troop dying from status effect damage
static func handle_status_death(troop: Node, effect_id: String, player_manager) -> Dictionary:
	var result = {
		"troop_died": false,
		"killer_effect": effect_id,
		"xp_awarded": 0
	}
	
	if troop == null or not "is_alive" in troop:
		return result
	
	if not troop.is_alive:
		result["troop_died"] = true
		
		# Status effect kills don't award XP to anyone specific
		# But we might want to track it for stats
		result["xp_awarded"] = 0
		
		# Emit death signal if troop has it
		if troop.has_signal("died"):
			troop.died.emit(null)  # No killer
	
	return result


## Check if any troops died during status tick phase
static func process_status_tick_deaths(player: Node) -> Array[Node]:
	var dead_troops: Array[Node] = []
	
	if player == null or not "troops" in player:
		return dead_troops
	
	for troop in player.troops:
		if troop and not troop.is_alive:
			dead_troops.append(troop)
	
	return dead_troops


# =============================================================================
# 5.4.3 - SELF-TARGETING MOVES
# =============================================================================

## Check if a move targets self
static func is_self_targeting_move(move: MoveData.Move) -> bool:
	if move == null:
		return false
	return move.targets_self


## Execute self-targeting move (heal, buff, etc.)
static func execute_self_targeting_move(caster: Node, move: MoveData.Move) -> Dictionary:
	var result = {
		"success": false,
		"effect": "",
		"amount": 0
	}
	
	if caster == null or move == null:
		return result
	
	# Apply based on effect type
	var effect_id = move.effect_id
	
	match effect_id:
		"heal":
			# Self heal (like Celestial Blessing)
			var heal_amount = _calculate_heal_amount(caster, move)
			caster.heal(heal_amount)
			result["effect"] = "heal"
			result["amount"] = heal_amount
			result["success"] = true
		
		"stealth":
			# Gain stealth (like Shadow Veil)
			var stealth_effect = StatusEffects.create_effect("stealth")
			if stealth_effect:
				caster.apply_status_effect(stealth_effect)
				result["effect"] = "stealth"
				result["success"] = true
		
		"stat_boost":
			# Stat boost (various buffs)
			if "stat_modifiers" in move:
				for stat in move.stat_modifiers:
					caster.modify_stat_stage(stat, move.stat_modifiers[stat])
				result["effect"] = "stat_boost"
				result["success"] = true
		
		"remove_debuffs":
			# Cleanse debuffs (like Purifying Light)
			caster.remove_all_debuffs()
			result["effect"] = "cleanse"
			result["success"] = true
	
	# Apply cooldown
	if result["success"]:
		caster.use_move(move.move_id)
	
	return result


static func _calculate_heal_amount(caster: Node, move: MoveData.Move) -> int:
	# Heal is based on power_percent of max HP
	var base = caster.max_hp if caster else 100
	return int(base * move.power_percent * 0.5)  # 50% of power% of max HP


# =============================================================================
# 5.4.4 - AoE HITTING ALLIED TROOPS
# =============================================================================

## Get all valid targets for an AoE move
static func get_aoe_targets(center_hex: Node, aoe_pattern: String, hex_board: Node, exclude_allies: bool = true, caster_player_id: int = -1) -> Array[Node]:
	var targets: Array[Node] = []
	
	if center_hex == null or hex_board == null:
		return targets
	
	var affected_hexes = _get_hexes_in_pattern(center_hex, aoe_pattern, hex_board)
	
	for hex in affected_hexes:
		if hex.is_occupied():
			var occupant = hex.occupant
			
			# Check if we should exclude allies
			if exclude_allies and caster_player_id >= 0:
				if "owner_player_id" in occupant and occupant.owner_player_id == caster_player_id:
					continue
			
			targets.append(occupant)
	
	return targets


## Get hex coordinates affected by an AoE pattern
static func _get_hexes_in_pattern(center_hex: Node, pattern: String, hex_board: Node) -> Array[Node]:
	var hexes: Array[Node] = []
	
	var center_coord = center_hex.coordinates
	
	match pattern:
		"adjacent":
			# All 6 adjacent hexes
			for neighbor_coord in center_coord.get_all_neighbors():
				var tile = hex_board.get_tile_at(neighbor_coord)
				if tile:
					hexes.append(tile)
		
		"ring":
			# Ring at distance 2
			for neighbor_coord in center_coord.get_all_neighbors():
				for outer_coord in neighbor_coord.get_all_neighbors():
					if outer_coord.distance_to(center_coord) == 2:
						var tile = hex_board.get_tile_at(outer_coord)
						if tile and tile not in hexes:
							hexes.append(tile)
		
		"line_3":
			# 3 hexes in a line (need direction)
			# For now, just do adjacent
			for neighbor_coord in center_coord.get_all_neighbors():
				var tile = hex_board.get_tile_at(neighbor_coord)
				if tile:
					hexes.append(tile)
					break  # Only one direction
		
		"cross":
			# + pattern (4 directions)
			var directions = [
				HexCoordinates.new(0, -1), HexCoordinates.new(0, 1),
				HexCoordinates.new(-1, 0), HexCoordinates.new(1, 0)
			]
			for dir in directions:
				var coord = HexCoordinates.new(center_coord.q + dir.q, center_coord.r + dir.r)
				var tile = hex_board.get_tile_at(coord)
				if tile:
					hexes.append(tile)
	
	return hexes


## Check if AoE would hit any allies (for warning)
static func would_aoe_hit_allies(center_hex: Node, aoe_pattern: String, hex_board: Node, caster_player_id: int) -> bool:
	var all_targets = get_aoe_targets(center_hex, aoe_pattern, hex_board, false, -1)
	
	for target in all_targets:
		if "owner_player_id" in target and target.owner_player_id == caster_player_id:
			return true
	
	return false


# =============================================================================
# 5.4.5 - RESURRECTION (Cleric Ultimate)
# =============================================================================

## Check if resurrection is possible
static func can_resurrect(caster: Node, player: Node) -> Dictionary:
	var result = {
		"can_resurrect": false,
		"available_targets": [],
		"error": ""
	}
	
	if caster == null or player == null:
		result["error"] = "Invalid caster or player"
		return result
	
	# Check for dead troops
	if not "dead_troops" in player or player.dead_troops.is_empty():
		result["error"] = "No dead troops to resurrect"
		return result
	
	# Check for available spawn tiles
	var hex_board = caster.get_tree().get_first_node_in_group("hex_board")
	if hex_board == null:
		result["error"] = "No hex board found"
		return result
	
	var spawn_tiles = hex_board.get_available_spawn_tiles(player.player_id)
	if spawn_tiles.is_empty():
		result["error"] = "No spawn tiles available"
		return result
	
	result["can_resurrect"] = true
	result["available_targets"] = player.dead_troops.duplicate()
	result["spawn_tiles"] = spawn_tiles
	
	return result


## Execute resurrection
static func resurrect_troop(troop_id: String, player: Node, spawn_tile: Node) -> Dictionary:
	var result = {
		"success": false,
		"troop": null,
		"error": ""
	}
	
	# This would normally spawn a new troop instance
	# For now, return the data needed
	result["success"] = true
	result["troop_id"] = troop_id
	result["spawn_tile"] = spawn_tile
	result["hp_percent"] = 0.5  # Resurrect at 50% HP
	
	return result


# =============================================================================
# 5.4.6 - SELF-DESTRUCT (Infernal Soul)
# =============================================================================

## Check if self-destruct is valid
static func can_self_destruct(caster: Node) -> bool:
	if caster == null:
		return false
	
	# Must be alive
	if not caster.is_alive:
		return false
	
	# Check if troop has self-destruct ability
	if "has_death_burst" in caster:
		return caster.has_death_burst()
	
	return false


## Execute self-destruct
static func execute_self_destruct(caster: Node, hex_board: Node) -> Dictionary:
	var result = {
		"success": false,
		"caster_died": false,
		"targets_hit": [],
		"damage_dealt": []
	}
	
	if caster == null or hex_board == null:
		return result
	
	# Calculate self-destruct damage (percentage of caster's max HP)
	var damage = int(caster.max_hp * 0.5)  # 50% of max HP as damage
	
	# Get all adjacent units
	var center_hex = caster.current_hex
	if center_hex == null:
		return result
	
	var targets = get_aoe_targets(center_hex, "adjacent", hex_board, false, -1)
	
	# Deal damage to all targets
	for target in targets:
		if target and "take_damage" in target:
			target.take_damage(damage)
			result["targets_hit"].append(target)
			result["damage_dealt"].append(damage)
	
	# Kill the caster
	caster.current_hp = 0
	caster.is_alive = false
	result["caster_died"] = true
	result["success"] = true
	
	return result


# =============================================================================
# UTILITY METHODS
# =============================================================================

## Check if a combat scenario has any edge cases that need special handling
static func analyze_combat(attacker: Node, defender: Node, move: MoveData.Move) -> Dictionary:
	var analysis = {
		"is_self_targeting": false,
		"is_aoe": false,
		"hits_allies": false,
		"defender_stunned": false,
		"defender_can_endure": false,
		"special_handling_required": false,
		"notes": []
	}
	
	if move:
		analysis["is_self_targeting"] = move.targets_self
		analysis["is_aoe"] = move.is_aoe
	
	if defender and "has_status_effect" in defender:
		analysis["defender_stunned"] = defender.has_status_effect("stunned")
		analysis["defender_can_endure"] = defender.endure_uses_remaining > 0 if "endure_uses_remaining" in defender else true
	
	# Check if special handling is needed
	if analysis["is_self_targeting"] or analysis["is_aoe"] or analysis["defender_stunned"]:
		analysis["special_handling_required"] = true
	
	if analysis["is_self_targeting"]:
		analysis["notes"].append("Self-targeting move - skip attack roll")
	
	if analysis["defender_stunned"]:
		analysis["notes"].append("Defender is stunned - auto-Brace")
	
	if analysis["is_aoe"]:
		analysis["notes"].append("AoE move - multiple targets")
	
	return analysis
