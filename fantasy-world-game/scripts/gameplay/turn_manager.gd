## Turn Manager
## Handles turn flow, timing, and action tracking for the game
## Enhanced with D&D × Pokémon hybrid combat support
## Designed with networking in mind - action functions can be converted to RPCs
class_name TurnManager
extends RefCounted

# =============================================================================
# SIGNALS
# =============================================================================
signal turn_started(player_id: int, turn_number: int)
signal turn_ended(player_id: int, turn_number: int)
signal turn_timer_updated(seconds_remaining: float)
signal turn_timer_expired(player_id: int)
signal action_performed(player_id: int, action_type: String, data: Dictionary)
signal all_actions_used(player_id: int)
signal phase_changed(new_phase: Phase)

# Enhanced Combat Signals
signal enhanced_combat_started(attacker: Node, defender: Node)
signal combat_selection_required(attacker: Node, defender: Node, attacker_player_id: int, defender_player_id: int)
signal enhanced_combat_resolved(result: Dictionary)
signal status_effects_ticked(player_id: int, damages: Dictionary)

# =============================================================================
# ENUMS
# =============================================================================
enum Phase {
	WAITING,              # Game not started
	DECK_SELECTION,       # Players selecting decks
	GAME_START,           # Initial setup (dice roll for order)
	PLAYER_TURN,          # Active player's turn
	COMBAT_RESOLUTION,    # Legacy combat (pause for animation)
	ENHANCED_COMBAT,      # New D&D × Pokémon combat with selection
	GAME_OVER             # Game ended
}

enum ActionType {
	MOVE,
	ATTACK,
	ENHANCED_ATTACK,      # New: Attack with move selection
	PLACE_MINE,
	UPGRADE_MINE,
	UPGRADE_TROOP,
	USE_ITEM,
	HEAL,
	END_TURN
}

# =============================================================================
# PROPERTIES
# =============================================================================
## Reference to PlayerManager
var player_manager: PlayerManager = null

## Current game phase
var current_phase: Phase = Phase.WAITING:
	set(value):
		current_phase = value
		phase_changed.emit(current_phase)

## Turn timer settings
var turn_timer_enabled: bool = true
var turn_timer_duration: float = GameConfig.DEFAULT_TURN_TIMER  # seconds
var turn_timer_remaining: float = 0.0
var turn_timer_paused: bool = false

## Action history for the current turn (for undo/replay/networking)
var current_turn_actions: Array[Dictionary] = []

## Total turns elapsed in the game
var total_turns: int = 0


# =============================================================================
# INITIALIZATION
# =============================================================================

func _init(p_manager: PlayerManager = null) -> void:
	player_manager = p_manager


## Setup the turn manager with a player manager reference
func setup(p_manager: PlayerManager) -> void:
	player_manager = p_manager


## Set turn timer duration (in seconds)
func set_turn_timer(duration: int) -> void:
	turn_timer_duration = float(duration)
	if duration <= 0:
		turn_timer_enabled = false
	else:
		turn_timer_enabled = true


# =============================================================================
# GAME FLOW
# =============================================================================

## Start the game (after deck selection)
func start_game() -> void:
	if player_manager == null:
		push_error("TurnManager: No PlayerManager set!")
		return
	
	current_phase = Phase.GAME_START
	total_turns = 0
	
	# Roll for turn order
	player_manager.roll_for_turn_order()
	
	# Start the game
	player_manager.start_game()
	
	# Begin first turn
	_begin_new_turn()


## Begin a new turn for the active player
func _begin_new_turn() -> void:
	if player_manager == null:
		return
	
	var active_player = player_manager.get_active_player()
	if active_player == null:
		return
	
	current_phase = Phase.PLAYER_TURN
	total_turns += 1
	
	# Reset turn-specific state
	current_turn_actions.clear()
	
	# Reset turn timer
	if turn_timer_enabled:
		turn_timer_remaining = turn_timer_duration
		turn_timer_paused = false
	
	# Tick cooldowns and status effects for all player's troops
	var status_damages: Dictionary = {}
	for troop in active_player.troops:
		if troop and troop.is_alive:
			# start_turn() now handles cooldown ticking AND status effect ticking
			troop.start_turn()
			
			# Track any DoT damage for UI feedback
			var dot_damage = 0
			for effect in troop.active_status_effects:
				if "damage_per_turn" in effect and effect.damage_per_turn > 0:
					dot_damage += effect.damage_per_turn
			
			if dot_damage > 0:
				status_damages[troop.troop_id] = dot_damage
	
	# Emit status damage signal if any troops took DoT damage
	if not status_damages.is_empty():
		status_effects_ticked.emit(active_player.player_id, status_damages)
	
	# Emit turn started signal
	turn_started.emit(active_player.player_id, player_manager.turn_number)


## End the current player's turn
## This function will later be an RPC for network sync
func end_turn() -> void:
	if current_phase != Phase.PLAYER_TURN:
		print("WARNING: end_turn blocked - current phase is %s, not PLAYER_TURN" % Phase.keys()[current_phase])
		return
	
	var active_player = player_manager.get_active_player()
	if active_player == null:
		return
	
	# Record end turn action
	_record_action(ActionType.END_TURN, {})
	
	# Emit signal before switching
	turn_ended.emit(active_player.player_id, player_manager.turn_number)
	
	# Tell player manager to advance turn
	player_manager.end_turn()
	
	# Check if game is over
	if player_manager.game_ended:
		current_phase = Phase.GAME_OVER
		return
	
	# Begin next player's turn
	_begin_new_turn()


## Force end turn (e.g., timer expired)
func force_end_turn() -> void:
	var active_player = player_manager.get_active_player()
	if active_player:
		turn_timer_expired.emit(active_player.player_id)
	end_turn()


# =============================================================================
# TIMER MANAGEMENT
# =============================================================================

## Update the turn timer (call this from _process in game manager)
## Returns true if timer expired
func update_timer(delta: float) -> bool:
	if not turn_timer_enabled:
		return false
	
	if turn_timer_paused:
		return false
	
	if current_phase != Phase.PLAYER_TURN:
		return false
	
	turn_timer_remaining -= delta
	turn_timer_updated.emit(turn_timer_remaining)
	
	if turn_timer_remaining <= 0.0:
		turn_timer_remaining = 0.0
		force_end_turn()
		return true
	
	return false


## Pause the turn timer (e.g., during combat animation)
func pause_timer() -> void:
	turn_timer_paused = true


## Resume the turn timer
func resume_timer() -> void:
	turn_timer_paused = false


## Get remaining time as formatted string (MM:SS)
func get_timer_string() -> String:
	var seconds = int(turn_timer_remaining)
	var mins = seconds / 60
	var secs = seconds % 60
	return "%d:%02d" % [mins, secs]


# =============================================================================
# ACTION VALIDATION & EXECUTION
# =============================================================================

## Check if a troop can perform any action this turn
func can_troop_act(troop: Node) -> bool:
	if current_phase != Phase.PLAYER_TURN:
		return false
	
	var active_player = player_manager.get_active_player()
	if active_player == null:
		return false
	
	# Check if troop belongs to active player
	if troop not in active_player.troops:
		return false
	
	# Check if troop already acted
	return not active_player.has_troop_acted(troop)


## Validate and perform a move action
## Returns: Dictionary with "success" and optional "error" message
func perform_move(troop: Node, target_hex: Node) -> Dictionary:
	if not can_troop_act(troop):
		return {"success": false, "error": "Troop cannot act this turn"}
	
	# Validate move (actual pathfinding validation done elsewhere)
	# This is a placeholder - real validation needs HexBoard reference
	
	var result = {
		"success": true,
		"action": ActionType.MOVE,
		"troop": troop,
		"from": null,  # Would be troop's current hex
		"to": target_hex
	}
	
	# Record action
	_record_action(ActionType.MOVE, {
		"troop_id": troop.get_instance_id() if troop else -1,
		"target_hex": target_hex.get_instance_id() if target_hex else -1
	})
	
	# Mark troop as having acted
	var active_player = player_manager.get_active_player()
	active_player.mark_troop_acted(troop)
	
	# Check if all troops have acted
	_check_all_actions_used()
	
	action_performed.emit(active_player.player_id, "MOVE", result)
	
	return result


## Validate and perform an attack action
## Returns: Dictionary with "success" and combat data
func perform_attack(attacker: Node, defender: Node) -> Dictionary:
	# Block if not in player turn phase
	if current_phase != Phase.PLAYER_TURN:
		return {"success": false, "error": "Cannot attack during this phase"}
	
	if not can_troop_act(attacker):
		return {"success": false, "error": "Troop cannot act this turn"}
	
	# Pause timer during combat
	pause_timer()
	current_phase = Phase.COMBAT_RESOLUTION
	
	var result = {
		"success": true,
		"action": ActionType.ATTACK,
		"attacker": attacker,
		"defender": defender
	}
	
	# Record action
	_record_action(ActionType.ATTACK, {
		"attacker_id": attacker.get_instance_id() if attacker else -1,
		"defender_id": defender.get_instance_id() if defender else -1
	})
	
	# Mark troop as having acted
	var active_player = player_manager.get_active_player()
	active_player.mark_troop_acted(attacker)
	
	action_performed.emit(active_player.player_id, "ATTACK", result)
	
	return result


## Validate and perform an ENHANCED attack (D&D × Pokémon combat)
## This initiates the move/stance selection phase
## Returns: Dictionary with "success" - combat resolved via signals
func perform_enhanced_attack(attacker: Node, defender: Node) -> Dictionary:
	# Block if not in player turn phase
	if current_phase != Phase.PLAYER_TURN:
		return {"success": false, "error": "Cannot attack during this phase"}
	
	if not can_troop_act(attacker):
		return {"success": false, "error": "Troop cannot act this turn"}
	
	# Check if defender can participate (has status effects that prevent action?)
	# Stunned units can still be attacked, but can't select a stance - auto-Brace
	
	# Pause timer during combat selection and resolution
	pause_timer()
	current_phase = Phase.ENHANCED_COMBAT
	
	# Record action
	_record_action(ActionType.ENHANCED_ATTACK, {
		"attacker_id": attacker.get_instance_id() if attacker else -1,
		"defender_id": defender.get_instance_id() if defender else -1
	})
	
	# Mark troop as having acted
	var active_player = player_manager.get_active_player()
	active_player.mark_troop_acted(attacker)
	
	# Emit signals to trigger UI
	enhanced_combat_started.emit(attacker, defender)
	
	# Get player IDs for UI routing
	var attacker_player_id = attacker.owner_player_id if "owner_player_id" in attacker else -1
	var defender_player_id = defender.owner_player_id if "owner_player_id" in defender else -1
	
	# Emit signal for combat selection UI
	combat_selection_required.emit(attacker, defender, attacker_player_id, defender_player_id)
	
	var result = {
		"success": true,
		"action": ActionType.ENHANCED_ATTACK,
		"attacker": attacker,
		"defender": defender,
		"phase": "selection"  # UI should wait for combat resolution
	}
	
	action_performed.emit(active_player.player_id, "ENHANCED_ATTACK", result)
	
	return result


## Called when enhanced combat resolution is complete
func on_enhanced_combat_complete(result: Dictionary) -> void:
	# Emit result for UI/networking
	enhanced_combat_resolved.emit(result)
	
	# Resume normal gameplay
	resume_timer()
	current_phase = Phase.PLAYER_TURN
	_check_all_actions_used()


## Called when combat resolution is complete (legacy)
func on_combat_complete() -> void:
	resume_timer()
	current_phase = Phase.PLAYER_TURN
	_check_all_actions_used()


## Validate and perform mine placement
func perform_place_mine(troop: Node, target_hex: Node) -> Dictionary:
	if not can_troop_act(troop):
		return {"success": false, "error": "Troop cannot act this turn"}
	
	var active_player = player_manager.get_active_player()
	
	# Check if player can afford
	if not active_player.can_afford_gold(GameConfig.MINE_PLACEMENT_COST):
		return {"success": false, "error": "Not enough gold"}
	
	# Check if player has room for more mines
	if active_player.get_mine_count() >= GameConfig.MAX_MINES_PER_PLAYER:
		return {"success": false, "error": "Maximum mines reached"}
	
	var result = {
		"success": true,
		"action": ActionType.PLACE_MINE,
		"troop": troop,
		"hex": target_hex
	}
	
	# Record action
	_record_action(ActionType.PLACE_MINE, {
		"troop_id": troop.get_instance_id() if troop else -1,
		"hex_id": target_hex.get_instance_id() if target_hex else -1
	})
	
	# Mark troop as having acted
	active_player.mark_troop_acted(troop)
	
	_check_all_actions_used()
	
	action_performed.emit(active_player.player_id, "PLACE_MINE", result)
	
	return result


## Validate and perform troop upgrade
func perform_upgrade_troop(troop: Node) -> Dictionary:
	if not can_troop_act(troop):
		return {"success": false, "error": "Troop cannot act this turn"}
	
	var active_player = player_manager.get_active_player()
	
	# Get troop's current level (would need troop to have level property)
	var current_level = 1
	if "level" in troop:
		current_level = troop.level
	
	if current_level >= GameConfig.MAX_TROOP_LEVEL:
		return {"success": false, "error": "Troop is max level"}
	
	var next_level = current_level + 1
	var cost = GameConfig.TROOP_UPGRADE_COSTS.get(next_level, {})
	var gold_cost = cost.get("gold", 0)
	var xp_cost = cost.get("xp", 0)
	
	if not active_player.can_afford(gold_cost, xp_cost):
		return {"success": false, "error": "Not enough gold or XP"}
	
	var result = {
		"success": true,
		"action": ActionType.UPGRADE_TROOP,
		"troop": troop,
		"new_level": next_level,
		"gold_cost": gold_cost,
		"xp_cost": xp_cost
	}
	
	# Record action
	_record_action(ActionType.UPGRADE_TROOP, {
		"troop_id": troop.get_instance_id() if troop else -1,
		"new_level": next_level
	})
	
	# Mark troop as having acted
	active_player.mark_troop_acted(troop)
	
	_check_all_actions_used()
	
	action_performed.emit(active_player.player_id, "UPGRADE_TROOP", result)
	
	return result


## Validate and perform mine upgrade
func perform_upgrade_mine(mine: Node) -> Dictionary:
	if current_phase != Phase.PLAYER_TURN:
		return {"success": false, "error": "Cannot upgrade during this phase"}
	
	var active_player = player_manager.get_active_player()
	
	if mine not in active_player.gold_mines:
		return {"success": false, "error": "Mine does not belong to active player"}
	
	var current_level = mine.level if "level" in mine else 1
	
	if current_level >= GameConfig.MAX_TROOP_LEVEL:
		return {"success": false, "error": "Mine is max level"}
	
	var next_level = current_level + 1
	var gold_cost = GameConfig.MINE_UPGRADE_COSTS.get(next_level, 0)
	
	if not active_player.can_afford_gold(gold_cost):
		return {"success": false, "error": "Not enough gold"}
	
	var result = {
		"success": true,
		"action": ActionType.UPGRADE_MINE,
		"mine": mine,
		"new_level": next_level,
		"gold_cost": gold_cost
	}
	
	# Record action
	_record_action(ActionType.UPGRADE_MINE, {
		"mine_id": mine.get_instance_id() if mine else -1,
		"new_level": next_level
	})
	
	action_performed.emit(active_player.player_id, "UPGRADE_MINE", result)
	
	return result


## Validate and perform item use (e.g., Phoenix Feather)
func perform_use_item(troop: Node, item_id: String, target: Node = null) -> Dictionary:
	if not can_troop_act(troop):
		return {"success": false, "error": "Troop cannot act this turn"}
	
	var active_player = player_manager.get_active_player()
	
	if not active_player.has_item(item_id):
		return {"success": false, "error": "Item not in inventory"}
	
	var result = {
		"success": true,
		"action": ActionType.USE_ITEM,
		"troop": troop,
		"item_id": item_id,
		"target": target
	}
	
	# Record action
	_record_action(ActionType.USE_ITEM, {
		"troop_id": troop.get_instance_id() if troop else -1,
		"item_id": item_id,
		"target_id": target.get_instance_id() if target else -1
	})
	
	# Mark troop as having acted
	active_player.mark_troop_acted(troop)
	
	_check_all_actions_used()
	
	action_performed.emit(active_player.player_id, "USE_ITEM", result)
	
	return result


## Validate and perform heal action (Celestial Cleric)
func perform_heal(healer: Node, target: Node) -> Dictionary:
	if not can_troop_act(healer):
		return {"success": false, "error": "Troop cannot act this turn"}
	
	# Validate healer has HEAL ability (would check troop data)
	
	var result = {
		"success": true,
		"action": ActionType.HEAL,
		"healer": healer,
		"target": target,
		"heal_amount": GameConfig.CLERIC_HEAL_AMOUNT
	}
	
	# Record action
	_record_action(ActionType.HEAL, {
		"healer_id": healer.get_instance_id() if healer else -1,
		"target_id": target.get_instance_id() if target else -1
	})
	
	# Mark troop as having acted
	var active_player = player_manager.get_active_player()
	active_player.mark_troop_acted(healer)
	
	_check_all_actions_used()
	
	action_performed.emit(active_player.player_id, "HEAL", result)
	
	return result


# =============================================================================
# ACTION TRACKING
# =============================================================================

## Record an action for history/networking
func _record_action(action_type: ActionType, data: Dictionary) -> void:
	var action_record = {
		"type": action_type,
		"timestamp": Time.get_unix_time_from_system(),
		"turn": player_manager.turn_number if player_manager else 0,
		"player_id": player_manager.get_active_player().player_id if player_manager and player_manager.get_active_player() else -1,
		"data": data
	}
	current_turn_actions.append(action_record)


## Check if all troops have used their actions
func _check_all_actions_used() -> void:
	var active_player = player_manager.get_active_player()
	if active_player == null:
		return
	
	var available = active_player.get_available_troops()
	if available.is_empty():
		all_actions_used.emit(active_player.player_id)


## Get list of actions performed this turn
func get_current_turn_actions() -> Array[Dictionary]:
	return current_turn_actions.duplicate()


## Get count of actions performed this turn
func get_action_count() -> int:
	return current_turn_actions.size()


# =============================================================================
# STATE QUERIES
# =============================================================================

## Check if it's currently a player's turn to act
func is_player_turn(player_id: int) -> bool:
	if current_phase != Phase.PLAYER_TURN:
		return false
	
	var active = player_manager.get_active_player()
	return active != null and active.player_id == player_id


## Get the ID of the currently active player
func get_active_player_id() -> int:
	var active = player_manager.get_active_player()
	return active.player_id if active else -1


## Get current phase as string
func get_phase_name() -> String:
	match current_phase:
		Phase.WAITING: return "Waiting"
		Phase.DECK_SELECTION: return "Deck Selection"
		Phase.GAME_START: return "Game Start"
		Phase.PLAYER_TURN: return "Player Turn"
		Phase.COMBAT_RESOLUTION: return "Combat"
		Phase.GAME_OVER: return "Game Over"
		_: return "Unknown"


# =============================================================================
# SERIALIZATION (for save/load and network sync)
# =============================================================================

## Convert turn state to dictionary
func to_dict() -> Dictionary:
	return {
		"current_phase": current_phase,
		"turn_timer_enabled": turn_timer_enabled,
		"turn_timer_duration": turn_timer_duration,
		"turn_timer_remaining": turn_timer_remaining,
		"turn_timer_paused": turn_timer_paused,
		"total_turns": total_turns,
		"current_turn_actions": current_turn_actions.duplicate()
	}


## Load turn state from dictionary
func from_dict(data: Dictionary) -> void:
	current_phase = data.get("current_phase", Phase.WAITING)
	turn_timer_enabled = data.get("turn_timer_enabled", true)
	turn_timer_duration = data.get("turn_timer_duration", GameConfig.DEFAULT_TURN_TIMER)
	turn_timer_remaining = data.get("turn_timer_remaining", turn_timer_duration)
	turn_timer_paused = data.get("turn_timer_paused", false)
	total_turns = data.get("total_turns", 0)
	
	var actions = data.get("current_turn_actions", [])
	current_turn_actions.clear()
	for action in actions:
		current_turn_actions.append(action)
