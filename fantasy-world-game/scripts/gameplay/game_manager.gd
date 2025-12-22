## Game Manager
## Main game coordinator - manages all systems and game state
## Designed with networking in mind - can sync state via RPCs
class_name GameManager
extends Node

# =============================================================================
# SIGNALS
# =============================================================================
signal game_initialized()
signal game_ready_to_start()
signal game_started()
signal game_ended(winner_id: int)
signal game_draw()
signal state_changed(new_state: GameState)
signal npc_spawned(npc: NPC, hex: Node)
signal troop_spawned(troop: Troop, hex: Node)
signal mine_placed(mine: GoldMine, hex: Node)

# =============================================================================
# ENUMS
# =============================================================================
enum GameState {
	UNINITIALIZED,
	LOBBY, # Waiting for players
	DECK_SELECTION, # Players choosing decks
	INITIALIZING, # Setting up board and spawning troops
	PLAYING, # Active gameplay
	PAUSED, # Game paused
	GAME_OVER # Game ended
}

# =============================================================================
# EXPORTS
# =============================================================================
@export var hex_board_scene: PackedScene
@export var troop_scene: PackedScene
@export var gold_mine_scene: PackedScene
@export var npc_scene: PackedScene

# =============================================================================
# CHILD NODES (will be created)
# =============================================================================
var hex_board: HexBoard
var player_manager: PlayerManager
var turn_manager: TurnManager
var combat_manager: CombatManager

# =============================================================================
# GAME STATE
# =============================================================================
var current_state: GameState = GameState.UNINITIALIZED:
	set(value):
		current_state = value
		state_changed.emit(current_state)

## Random seed for procedural generation (sync for networking)
var game_seed: int = 0

## All active NPCs
var active_npcs: Array[NPC] = []

## Game settings
var settings: Dictionary = {
	"turn_timer": GameConfig.DEFAULT_TURN_TIMER,
	"player_names": ["Player 1", "Player 2"]
}


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_create_managers()


func _process(delta: float) -> void:
	if current_state == GameState.PLAYING and turn_manager:
		turn_manager.update_timer(delta)


## Create all manager instances
func _create_managers() -> void:
	player_manager = PlayerManager.new()
	turn_manager = TurnManager.new(player_manager)
	combat_manager = CombatManager.new()
	
	# Connect signals
	_connect_manager_signals()


## Connect manager signals for coordination
func _connect_manager_signals() -> void:
	# Player manager signals
	player_manager.game_over.connect(_on_game_over)
	player_manager.game_draw.connect(_on_game_draw)
	player_manager.player_turn_started.connect(_on_player_turn_started)
	player_manager.player_turn_ended.connect(_on_player_turn_ended)
	
	# Turn manager signals
	turn_manager.action_performed.connect(_on_action_performed)
	turn_manager.phase_changed.connect(_on_turn_phase_changed)


# =============================================================================
# GAME SETUP
# =============================================================================

## Initialize a new game with settings
func initialize_game(game_settings: Dictionary = {}) -> void:
	# Apply settings
	settings.merge(game_settings, true)
	
	# Generate or use provided seed
	if "seed" in game_settings:
		game_seed = game_settings["seed"]
	else:
		game_seed = randi()
	
	# Set random seed for deterministic generation
	seed(game_seed)
	
	# Create hex board
	_create_hex_board()
	
	# Initialize players
	var player_names: Array[String] = []
	var raw_names = settings.get("player_names", ["Player 1", "Player 2"])
	for name in raw_names:
		player_names.append(name)
	player_manager.initialize_players(player_names)
	
	# Setup turn manager
	turn_manager.setup(player_manager)
	turn_manager.set_turn_timer(settings.get("turn_timer", GameConfig.DEFAULT_TURN_TIMER))
	
	# Setup combat manager
	combat_manager.setup(hex_board, player_manager)
	
	current_state = GameState.LOBBY
	game_initialized.emit()


## Create and generate the hex board
func _create_hex_board() -> void:
	# Skip if hex_board is already set externally
	if hex_board != null:
		print("Using existing hex board")
		return
	
	if hex_board_scene:
		hex_board = hex_board_scene.instantiate() as HexBoard
	else:
		hex_board = HexBoard.new()
	
	add_child(hex_board)
	hex_board.generate_board()


## Set player decks (called after deck selection)
func set_player_deck(player_id: int, deck: Array[String]) -> Dictionary:
	var player = player_manager.get_player(player_id)
	if player == null:
		return {"success": false, "error": "Invalid player"}
	
	return player.set_deck(deck)


## Start the game after decks are selected
func start_game() -> void:
	if not player_manager.all_decks_valid():
		push_error("Cannot start game: Not all decks are valid")
		return
	
	current_state = GameState.INITIALIZING
	
	# Spawn troops for all players
	_spawn_all_troops()
	
	# Start the game
	current_state = GameState.PLAYING
	turn_manager.start_game()
	
	game_started.emit()


## Spawn troops for all players at spawn points
func _spawn_all_troops() -> void:
	for player in player_manager.players:
		var spawn_tiles = hex_board.get_available_spawn_tiles(player.player_id)
		
		# For Player 2 (ID 1), reverse spawn tiles so Deck Slot 0 -> Visual Top
		if player.player_id == 1:
			spawn_tiles.reverse()
		
		var deck_index = 0
		for card_id in player.deck:
			if deck_index >= spawn_tiles.size():
				push_warning("Not enough spawn tiles for all troops")
				break
			
			var spawn_tile = spawn_tiles[deck_index]
			var troop = spawn_troop(card_id, player.player_id, spawn_tile)
			
			if troop:
				player.add_troop(troop)
			
			deck_index += 1


## Spawn a single troop
func spawn_troop(card_id: String, player_id: int, hex_tile: HexTile) -> Troop:
	var troop: Troop
	
	if troop_scene:
		troop = troop_scene.instantiate() as Troop
	else:
		troop = Troop.new()
	
	add_child(troop)
	troop.initialize(card_id, player_id)
	
	# Set team color
	var player = player_manager.get_player(player_id)
	if player:
		troop.set_team_color(player.team_color)
	
	# Place on hex
	troop.move_to_hex(hex_tile)
	
	troop_spawned.emit(troop, hex_tile)
	
	return troop


# =============================================================================
# PLAYER ACTIONS (Network-ready functions)
# =============================================================================

## Move a troop to a target hex
## Returns: Dictionary with result
func action_move(troop: Troop, target_hex: HexTile) -> Dictionary:
	if current_state != GameState.PLAYING:
		return {"success": false, "error": "Game not in playing state"}
	
	# Validate through turn manager
	var result = turn_manager.perform_move(troop, target_hex)
	
	if result["success"]:
		# Actually move the troop
		troop.move_to_hex(target_hex)
		
		# Check for NPC spawn
		_try_spawn_npc(target_hex)
	
	return result


## Attack a target
func action_attack(attacker: Troop, defender: Node) -> Dictionary:
	if current_state != GameState.PLAYING:
		return {"success": false, "error": "Game not in playing state"}
	
	# Validate through turn manager
	var turn_result = turn_manager.perform_attack(attacker, defender)
	
	if not turn_result["success"]:
		return turn_result
	
	# Execute combat
	var combat_result = combat_manager.execute_combat(attacker, defender)
	
	# Handle kill rewards
	if combat_result["defender_killed"]:
		var defender_player_id = defender.owner_player_id if "owner_player_id" in defender else -1
		
		if defender_player_id >= 0:
			# Player troop killed
			var killer_player = player_manager.get_player(attacker.owner_player_id)
			var victim_player = player_manager.get_player(defender_player_id)
			
			if killer_player and victim_player:
				player_manager.process_kill(killer_player, victim_player, defender)
				victim_player.remove_troop(defender)
		else:
			# NPC killed
			if defender is NPC:
				var loot = defender.get_loot()
				var killer_player = player_manager.get_player(attacker.owner_player_id)
				if killer_player:
					killer_player.add_gold(loot["gold"])
					killer_player.add_xp(loot["xp"])
					if not loot["item"].is_empty():
						killer_player.add_item(loot["item"])
				
				active_npcs.erase(defender)
				defender.remove()
	
	# Combat resolution complete
	turn_manager.on_combat_complete()
	
	return combat_result


## Place a gold mine
func action_place_mine(troop: Troop, target_hex: HexTile) -> Dictionary:
	if current_state != GameState.PLAYING:
		return {"success": false, "error": "Game not in playing state"}
	
	var player = player_manager.get_player(troop.owner_player_id)
	if player == null:
		return {"success": false, "error": "Invalid player"}
	
	# Validate placement
	var can_place = GoldMine.can_place_at(target_hex, player, hex_board)
	if not can_place["can_place"]:
		return {"success": false, "error": can_place["error"]}
	
	# Validate through turn manager
	var turn_result = turn_manager.perform_place_mine(troop, target_hex)
	
	if not turn_result["success"]:
		return turn_result
	
	# Spend gold
	player.spend_gold(GameConfig.MINE_PLACEMENT_COST)
	
	# Create mine
	var mine: GoldMine
	if gold_mine_scene:
		mine = gold_mine_scene.instantiate() as GoldMine
	else:
		mine = GoldMine.new()
	
	add_child(mine)
	mine.initialize(player.player_id, target_hex)
	mine.set_team_color(player.team_color)
	
	# Add to player
	player.add_gold_mine(mine)
	
	mine_placed.emit(mine, target_hex)
	
	return {"success": true, "mine": mine}


## Upgrade a troop
func action_upgrade_troop(troop: Troop) -> Dictionary:
	if current_state != GameState.PLAYING:
		return {"success": false, "error": "Game not in playing state"}
	
	var player = player_manager.get_player(troop.owner_player_id)
	if player == null:
		return {"success": false, "error": "Invalid player"}
	
	# Get upgrade cost
	var cost = troop.get_upgrade_cost()
	if not cost["can_upgrade"]:
		return {"success": false, "error": "Cannot upgrade further"}
	
	if not player.can_afford(cost["gold"], cost["xp"]):
		return {"success": false, "error": "Not enough resources"}
	
	# Validate through turn manager
	var turn_result = turn_manager.perform_upgrade_troop(troop)
	
	if not turn_result["success"]:
		return turn_result
	
	# Spend resources
	player.spend_resources(cost["gold"], cost["xp"])
	
	# Upgrade troop
	troop.upgrade()
	
	return {"success": true, "new_level": troop.level}


## Use an item
func action_use_item(troop: Troop, item_id: String, target: Node = null) -> Dictionary:
	if current_state != GameState.PLAYING:
		return {"success": false, "error": "Game not in playing state"}
	
	var player = player_manager.get_player(troop.owner_player_id)
	if player == null:
		return {"success": false, "error": "Invalid player"}
	
	# Validate through turn manager
	var turn_result = turn_manager.perform_use_item(troop, item_id, target)
	
	if not turn_result["success"]:
		return turn_result
	
	# Apply item effect
	var item_data = CardData.get_item(item_id)
	var effect = item_data.get("effect_type", "")
	
	match effect:
		"speed_buff":
			var buff_target = target if target else troop
			buff_target.apply_buff("speed_buff", item_data.get("value", 1), item_data.get("duration", 3))
		"atk_buff":
			var buff_target = target if target else troop
			buff_target.apply_buff("atk_buff", item_data.get("value", 10), item_data.get("duration", 1))
		"respawn":
			# Phoenix Feather - respawn troop
			if player.can_respawn_troop():
				var respawn_id = player.get_respawnable_troops()[0]
				var spawn_tiles = hex_board.get_available_spawn_tiles(player.player_id)
				if not spawn_tiles.is_empty():
					player.use_respawn(respawn_id)
					var new_troop = spawn_troop(respawn_id, player.player_id, spawn_tiles[0])
					player.add_troop(new_troop)
	
	# Remove item from inventory
	player.remove_item(item_id)
	
	return {"success": true}


## Heal a target
func action_heal(healer: Troop, target: Troop) -> Dictionary:
	if current_state != GameState.PLAYING:
		return {"success": false, "error": "Game not in playing state"}
	
	# Validate through turn manager
	var turn_result = turn_manager.perform_heal(healer, target)
	
	if not turn_result["success"]:
		return turn_result
	
	# Execute heal
	var heal_result = combat_manager.execute_heal(healer, target)
	
	return heal_result


## End current player's turn
func action_end_turn() -> void:
	if current_state != GameState.PLAYING:
		return
	
	turn_manager.end_turn()


# =============================================================================
# NPC MANAGEMENT
# =============================================================================

## Try to spawn an NPC at a hex
func _try_spawn_npc(hex: HexTile) -> void:
	if hex.is_occupied():
		return
	
	var npc = NPC.try_spawn_at(hex, hex_board)
	if npc:
		add_child(npc)
		active_npcs.append(npc)
		npc_spawned.emit(npc, hex)


## Process NPC actions (called during NPC phase or at turn end)
func process_npc_actions() -> void:
	for npc in active_npcs:
		if not npc.is_alive:
			continue
		
		var target = npc.try_attack(hex_board)
		if target:
			# NPC attacks target
			var damage = npc.calculate_attack_damage(target)
			target.take_damage(damage)


# =============================================================================
# GAME EVENTS
# =============================================================================

func _on_player_turn_started(player: Player) -> void:
	# Tick buffs for player's troops
	for troop in player.troops:
		troop.tick_buffs()


func _on_player_turn_ended(player: Player) -> void:
	# Process NPC actions at end of each turn
	process_npc_actions()


func _on_action_performed(player_id: int, action_type: String, data: Dictionary) -> void:
	# Can be used for logging, replay, or network sync
	pass


func _on_turn_phase_changed(new_phase: TurnManager.Phase) -> void:
	pass


func _on_game_over(winner: Player) -> void:
	current_state = GameState.GAME_OVER
	game_ended.emit(winner.player_id if winner else -1)


func _on_game_draw() -> void:
	current_state = GameState.GAME_OVER
	game_draw.emit()


# =============================================================================
# PAUSE / RESUME
# =============================================================================

func pause_game() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		turn_manager.pause_timer()


func resume_game() -> void:
	if current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		turn_manager.resume_timer()


# =============================================================================
# SERIALIZATION
# =============================================================================

## Save game state to dictionary
func save_game() -> Dictionary:
	var troops_data: Array = []
	for player in player_manager.players:
		for troop in player.troops:
			troops_data.append(troop.to_dict())
	
	var npcs_data: Array = []
	for npc in active_npcs:
		npcs_data.append(npc.to_dict())
	
	return {
		"game_seed": game_seed,
		"current_state": current_state,
		"settings": settings.duplicate(),
		"player_manager": player_manager.to_dict(),
		"turn_manager": turn_manager.to_dict(),
		"troops": troops_data,
		"npcs": npcs_data
	}


## Load game state from dictionary
func load_game(data: Dictionary) -> void:
	game_seed = data.get("game_seed", 0)
	seed(game_seed)
	
	settings = data.get("settings", {}).duplicate()
	
	# Recreate board with same seed
	_create_hex_board()
	
	# Load player manager
	player_manager.from_dict(data.get("player_manager", {}))
	
	# Load turn manager
	turn_manager.from_dict(data.get("turn_manager", {}))
	
	# Recreate troops
	var troops_data = data.get("troops", [])
	for troop_data in troops_data:
		var player = player_manager.get_player(troop_data.get("owner_player_id", -1))
		if player == null:
			continue
		
		var hex_coords = troop_data.get("hex_coords", {})
		var hex_tile = hex_board.get_tile_at_qr(
			hex_coords.get("q", 0),
			hex_coords.get("r", 0)
		)
		
		if hex_tile:
			var troop = spawn_troop(troop_data.get("troop_id", ""), player.player_id, hex_tile)
			if troop:
				troop.from_dict(troop_data)
				player.add_troop(troop)
	
	# Recreate NPCs
	var npcs_data = data.get("npcs", [])
	for npc_data in npcs_data:
		var hex_coords = npc_data.get("hex_coords", {})
		var hex_tile = hex_board.get_tile_at_qr(
			hex_coords.get("q", 0),
			hex_coords.get("r", 0)
		)
		
		if hex_tile:
			var npc = NPC.new()
			add_child(npc)
			npc.initialize(npc_data.get("npc_id", "goblin"), hex_tile)
			npc.from_dict(npc_data)
			active_npcs.append(npc)
	
	current_state = data.get("current_state", GameState.PLAYING)
