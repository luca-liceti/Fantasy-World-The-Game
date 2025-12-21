## Player Manager
## Manages all players in the game, handles turn order, and tracks game state
class_name PlayerManager
extends RefCounted

# =============================================================================
# SIGNALS
# =============================================================================
signal player_created(player: Player)
signal active_player_changed(player: Player)
signal player_turn_started(player: Player)
signal player_turn_ended(player: Player)
signal first_blood_claimed(player: Player)
signal player_eliminated(player: Player)
signal game_over(winner: Player)
signal game_draw()

# =============================================================================
# PROPERTIES
# =============================================================================
## All players in the game
var players: Array[Player] = []

## Index of the current active player
var active_player_index: int = 0

## Current turn number
var turn_number: int = 1

## Whether the game has started
var game_started: bool = false

## Whether the game has ended
var game_ended: bool = false

## The winning player (if any)
var winner: Player = null

## Initial dice roll results for turn order
var initial_dice_rolls: Dictionary = {}

## First blood tracking
var first_blood_awarded: bool = false


# =============================================================================
# INITIALIZATION
# =============================================================================

func _init() -> void:
	players = []


## Initialize players for a new game
func initialize_players(player_names: Array[String] = ["Player 1", "Player 2"]) -> void:
	players.clear()
	
	for i in range(GameConfig.NUM_PLAYERS):
		var player_name = player_names[i] if i < player_names.size() else "Player " + str(i + 1)
		var player = Player.new(i, player_name)
		player.initialize()
		players.append(player)
		player_created.emit(player)
	
	# Reset game state
	active_player_index = 0
	turn_number = 1
	game_started = false
	game_ended = false
	winner = null
	first_blood_awarded = false
	initial_dice_rolls.clear()


# =============================================================================
# TURN ORDER
# =============================================================================

## Roll dice to determine starting player
## Returns: Dictionary with player IDs and their roll results
func roll_for_turn_order() -> Dictionary:
	initial_dice_rolls.clear()
	
	for player in players:
		# Roll d20
		var roll = randi_range(1, GameConfig.DICE_TYPE)
		initial_dice_rolls[player.player_id] = roll
	
	# Determine who goes first (highest roll)
	var highest_roll: int = -1
	var first_player_index: int = 0
	
	for i in range(players.size()):
		var player = players[i]
		var roll = initial_dice_rolls[player.player_id]
		if roll > highest_roll:
			highest_roll = roll
			first_player_index = i
	
	# Handle ties - re-roll tied players
	var tied_indices: Array[int] = []
	for i in range(players.size()):
		if initial_dice_rolls[players[i].player_id] == highest_roll:
			tied_indices.append(i)
	
	# If there's a tie, the first tied player in order wins (simplified)
	# In a full implementation, you'd re-roll
	if tied_indices.size() > 1:
		first_player_index = tied_indices[0]
	
	active_player_index = first_player_index
	
	return initial_dice_rolls


## Set specific turn order (for loaded games)
func set_turn_order(first_player_id: int) -> void:
	for i in range(players.size()):
		if players[i].player_id == first_player_id:
			active_player_index = i
			break


# =============================================================================
# GAME FLOW
# =============================================================================

## Start the game
func start_game() -> void:
	if players.is_empty():
		push_error("Cannot start game without players!")
		return
	
	game_started = true
	game_ended = false
	turn_number = 1
	
	# Start first player's turn
	_start_player_turn(get_active_player())


## Get the currently active player
func get_active_player() -> Player:
	if players.is_empty():
		return null
	return players[active_player_index]


## Get player by ID
func get_player(player_id: int) -> Player:
	for player in players:
		if player.player_id == player_id:
			return player
	return null


## Get the opponent of a player
func get_opponent(player: Player) -> Player:
	for p in players:
		if p.player_id != player.player_id:
			return p
	return null


## End the current player's turn and start the next
func end_turn() -> void:
	if game_ended:
		return
	
	var current_player = get_active_player()
	
	# End current player's turn
	_end_player_turn(current_player)
	
	# Move to next player
	active_player_index = (active_player_index + 1) % players.size()
	
	# If we've gone through all players, increment turn number
	if active_player_index == 0:
		turn_number += 1
	
	# Check for game over conditions
	if _check_game_over():
		return
	
	# Start next player's turn
	_start_player_turn(get_active_player())


## Force end game with a specific winner
func force_end_game(winning_player: Player) -> void:
	game_ended = true
	winner = winning_player
	game_over.emit(winner)


## Private: Start a player's turn
func _start_player_turn(player: Player) -> void:
	# Collect gold from mines
	var gold_collected = player.collect_mine_gold()
	
	# Reset troop actions
	player.reset_troop_actions()
	
	# Emit signals
	active_player_changed.emit(player)
	player_turn_started.emit(player)


## Private: End a player's turn
func _end_player_turn(player: Player) -> void:
	player_turn_ended.emit(player)


## Private: Check for game over conditions
func _check_game_over() -> bool:
	var alive_players: Array[Player] = []
	
	for player in players:
		if player.has_troops():
			alive_players.append(player)
	
	# One player left standing
	if alive_players.size() == 1:
		game_ended = true
		winner = alive_players[0]
		game_over.emit(winner)
		return true
	
	# No players left (draw)
	if alive_players.is_empty():
		game_ended = true
		winner = null
		game_draw.emit()
		return true
	
	return false


# =============================================================================
# FIRST BLOOD & BOUNTY SYSTEM
# =============================================================================

## Award first blood bonus
func award_first_blood(player: Player) -> void:
	if first_blood_awarded:
		return
	
	first_blood_awarded = true
	player.has_first_blood = true
	player.add_gold(GameConfig.FIRST_BLOOD_GOLD)
	first_blood_claimed.emit(player)


## Process a kill for bounty rewards
## Returns: Dictionary with gold and XP awarded
func process_kill(killer: Player, victim_player: Player, killed_troop: Node) -> Dictionary:
	var rewards = {
		"gold": 0,
		"xp": 0,
		"first_blood": false,
		"revenge": false
	}
	
	# First blood check
	if not first_blood_awarded:
		award_first_blood(killer)
		rewards["first_blood"] = true
		rewards["gold"] += GameConfig.FIRST_BLOOD_GOLD
	
	# Register kill for streak
	killer.register_kill()
	
	# Calculate base XP (would come from troop data in full implementation)
	var base_xp: int = 25  # Default, should come from killed troop
	
	# Apply kill streak bonus
	var streak_bonus = killer.get_kill_streak_bonus()
	var bonus_xp = int(base_xp * streak_bonus)
	var total_xp = base_xp + bonus_xp
	
	# Check for revenge kill
	if killer.last_killer_id == victim_player.player_id:
		var revenge_gold = int(20 * GameConfig.REVENGE_KILL_GOLD_BONUS)  # Base 20 gold
		rewards["gold"] += revenge_gold
		rewards["revenge"] = true
		killer.last_killer_id = -1  # Reset revenge target
	
	# Apply rewards
	killer.add_xp(total_xp)
	killer.add_gold(rewards["gold"])
	
	rewards["xp"] = total_xp
	
	# Reset victim's kill streak
	victim_player.reset_kill_streak()
	victim_player.last_killer_id = killer.player_id
	
	return rewards


# =============================================================================
# DECK VALIDATION
# =============================================================================

## Validate all players' decks
## Returns: Dictionary with player IDs and their validation results
func validate_all_decks() -> Dictionary:
	var results: Dictionary = {}
	
	for player in players:
		results[player.player_id] = player.is_deck_valid()
	
	return results


## Check if all players have valid decks
func all_decks_valid() -> bool:
	for player in players:
		if not player.is_deck_valid():
			return false
	return true


# =============================================================================
# PLAYER ELIMINATION
# =============================================================================

## Handle player elimination (all troops destroyed)
func handle_player_elimination(player: Player) -> void:
	player_eliminated.emit(player)
	_check_game_over()


# =============================================================================
# UTILITY
# =============================================================================

## Get total gold across all players
func get_total_gold() -> int:
	var total: int = 0
	for player in players:
		total += player.gold
	return total


## Get total XP across all players
func get_total_xp() -> int:
	var total: int = 0
	for player in players:
		total += player.xp
	return total


## Get current turn info
func get_turn_info() -> Dictionary:
	return {
		"turn_number": turn_number,
		"active_player_id": get_active_player().player_id if get_active_player() else -1,
		"active_player_name": get_active_player().player_name if get_active_player() else "",
		"game_started": game_started,
		"game_ended": game_ended
	}


# =============================================================================
# SERIALIZATION
# =============================================================================

## Convert manager state to dictionary for saving
func to_dict() -> Dictionary:
	var players_data: Array = []
	for player in players:
		players_data.append(player.to_dict())
	
	return {
		"players": players_data,
		"active_player_index": active_player_index,
		"turn_number": turn_number,
		"game_started": game_started,
		"game_ended": game_ended,
		"winner_id": winner.player_id if winner else -1,
		"first_blood_awarded": first_blood_awarded,
		"initial_dice_rolls": initial_dice_rolls
	}


## Load manager state from dictionary
func from_dict(data: Dictionary) -> void:
	players.clear()
	
	var players_data = data.get("players", [])
	for player_data in players_data:
		var player = Player.new()
		player.from_dict(player_data)
		players.append(player)
	
	active_player_index = data.get("active_player_index", 0)
	turn_number = data.get("turn_number", 1)
	game_started = data.get("game_started", false)
	game_ended = data.get("game_ended", false)
	first_blood_awarded = data.get("first_blood_awarded", false)
	initial_dice_rolls = data.get("initial_dice_rolls", {})
	
	# Restore winner reference
	var winner_id = data.get("winner_id", -1)
	if winner_id >= 0:
		winner = get_player(winner_id)
	else:
		winner = null
