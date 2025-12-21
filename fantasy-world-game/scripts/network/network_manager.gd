## Network Manager
## Handles peer-to-peer multiplayer connections using Godot's High-Level Multiplayer API (ENet)
## Architecture: Host acts as server (peer_id = 1), Client joins host
class_name NetworkManager
extends Node

# =============================================================================
# SIGNALS
# =============================================================================
signal connection_succeeded()
signal connection_failed(reason: String)
signal server_started(port: int)
signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal all_players_ready()
signal game_seed_received(seed_value: int)
signal player_deck_received(peer_id: int, deck: Array)
signal action_received(peer_id: int, action_type: String, data: Dictionary)

# =============================================================================
# CONSTANTS
# =============================================================================
const DEFAULT_PORT: int = 7777
const MAX_PLAYERS: int = 2  # 1v1 game

# =============================================================================
# PROPERTIES
# =============================================================================
## Whether this instance is the host (server)
var is_host: bool = false

## Current connection state
enum ConnectionState {
	DISCONNECTED,
	CONNECTING,
	CONNECTED,
	IN_LOBBY,
	READY,
	IN_GAME
}
var connection_state: ConnectionState = ConnectionState.DISCONNECTED

## Connected players (peer_id -> player_data)
var connected_players: Dictionary = {}

## Ready status per player
var players_ready: Dictionary = {}

## Game seed (synced from host)
var synced_game_seed: int = 0

## Player decks (peer_id -> deck array)
var player_decks: Dictionary = {}

## Local peer ID
var local_peer_id: int = 0


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	# Connect multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


# =============================================================================
# HOST / JOIN
# =============================================================================

## Start hosting a game
func host_game(port: int = DEFAULT_PORT) -> Error:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_PLAYERS)
	
	if error != OK:
		push_error("Failed to create server: " + str(error))
		connection_failed.emit("Failed to create server")
		return error
	
	multiplayer.multiplayer_peer = peer
	is_host = true
	connection_state = ConnectionState.IN_LOBBY
	local_peer_id = 1  # Host is always peer 1
	
	# Add host to connected players
	connected_players[1] = {
		"peer_id": 1,
		"player_name": "Host",
		"is_ready": false
	}
	
	print("Server started on port ", port)
	server_started.emit(port)
	
	return OK


## Join an existing game
func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	
	if error != OK:
		push_error("Failed to create client: " + str(error))
		connection_failed.emit("Failed to connect to server")
		return error
	
	multiplayer.multiplayer_peer = peer
	is_host = false
	connection_state = ConnectionState.CONNECTING
	
	print("Connecting to ", address, ":", port)
	
	return OK


## Disconnect from the current game
func disconnect_game() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	is_host = false
	connection_state = ConnectionState.DISCONNECTED
	connected_players.clear()
	players_ready.clear()
	player_decks.clear()
	local_peer_id = 0
	
	print("Disconnected from game")


# =============================================================================
# CONNECTION CALLBACKS
# =============================================================================

func _on_peer_connected(peer_id: int) -> void:
	print("Peer connected: ", peer_id)
	
	connected_players[peer_id] = {
		"peer_id": peer_id,
		"player_name": "Player " + str(peer_id),
		"is_ready": false
	}
	
	player_connected.emit(peer_id)
	
	# If host, send game seed to new player
	if is_host:
		_send_game_seed_to_peer.rpc_id(peer_id, synced_game_seed)


func _on_peer_disconnected(peer_id: int) -> void:
	print("Peer disconnected: ", peer_id)
	
	connected_players.erase(peer_id)
	players_ready.erase(peer_id)
	player_decks.erase(peer_id)
	
	player_disconnected.emit(peer_id)


func _on_connected_to_server() -> void:
	print("Connected to server!")
	
	connection_state = ConnectionState.IN_LOBBY
	local_peer_id = multiplayer.get_unique_id()
	
	connection_succeeded.emit()


func _on_connection_failed() -> void:
	print("Connection failed!")
	
	connection_state = ConnectionState.DISCONNECTED
	connection_failed.emit("Connection to server failed")


func _on_server_disconnected() -> void:
	print("Server disconnected!")
	
	disconnect_game()
	connection_failed.emit("Server disconnected")


# =============================================================================
# GAME SEED SYNC
# =============================================================================

## Generate and broadcast game seed (host only)
func generate_and_sync_seed() -> int:
	if not is_host:
		push_error("Only host can generate game seed")
		return synced_game_seed
	
	synced_game_seed = randi()
	
	# Send to all clients
	_send_game_seed.rpc(synced_game_seed)
	
	return synced_game_seed


@rpc("authority", "call_local", "reliable")
func _send_game_seed(seed_value: int) -> void:
	synced_game_seed = seed_value
	print("Game seed synced: ", seed_value)
	game_seed_received.emit(seed_value)


@rpc("authority", "reliable")
func _send_game_seed_to_peer(seed_value: int) -> void:
	synced_game_seed = seed_value
	print("Received game seed: ", seed_value)
	game_seed_received.emit(seed_value)


# =============================================================================
# READY SYSTEM
# =============================================================================

## Mark local player as ready
func set_ready(is_ready: bool) -> void:
	players_ready[local_peer_id] = is_ready
	
	# Notify all players
	_notify_ready_state.rpc(local_peer_id, is_ready)
	
	_check_all_ready()


@rpc("any_peer", "call_local", "reliable")
func _notify_ready_state(peer_id: int, is_ready: bool) -> void:
	players_ready[peer_id] = is_ready
	
	if peer_id in connected_players:
		connected_players[peer_id]["is_ready"] = is_ready
	
	_check_all_ready()


func _check_all_ready() -> void:
	# Need exactly 2 players (1v1)
	if connected_players.size() != MAX_PLAYERS:
		return
	
	# Check if all are ready
	for peer_id in connected_players:
		if not players_ready.get(peer_id, false):
			return
	
	print("All players ready!")
	all_players_ready.emit()


# =============================================================================
# DECK SYNC
# =============================================================================

## Send local player's deck to all peers
func send_deck(deck: Array[String]) -> void:
	player_decks[local_peer_id] = deck
	
	# Notify all players
	_sync_deck.rpc(local_peer_id, deck)


@rpc("any_peer", "call_local", "reliable")
func _sync_deck(peer_id: int, deck: Array) -> void:
	player_decks[peer_id] = deck
	player_deck_received.emit(peer_id, deck)
	print("Received deck from peer ", peer_id, ": ", deck)


## Check if all decks are received
func all_decks_received() -> bool:
	return player_decks.size() >= MAX_PLAYERS


# =============================================================================
# GAME ACTIONS (RPCs)
# =============================================================================

## Send a game action to all peers
func send_action(action_type: String, data: Dictionary) -> void:
	_sync_action.rpc(action_type, data)


@rpc("any_peer", "call_local", "reliable")
func _sync_action(action_type: String, data: Dictionary) -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = local_peer_id  # Local call
	
	action_received.emit(sender_id, action_type, data)


## Specific action RPCs for common operations

func send_move_action(troop_id: int, target_q: int, target_r: int) -> void:
	send_action("MOVE", {
		"troop_id": troop_id,
		"target_q": target_q,
		"target_r": target_r
	})


func send_attack_action(attacker_id: int, defender_id: int) -> void:
	send_action("ATTACK", {
		"attacker_id": attacker_id,
		"defender_id": defender_id
	})


func send_end_turn_action() -> void:
	send_action("END_TURN", {})


func send_place_mine_action(troop_id: int, target_q: int, target_r: int) -> void:
	send_action("PLACE_MINE", {
		"troop_id": troop_id,
		"target_q": target_q,
		"target_r": target_r
	})


func send_upgrade_troop_action(troop_id: int) -> void:
	send_action("UPGRADE_TROOP", {
		"troop_id": troop_id
	})


func send_use_item_action(troop_id: int, item_id: String, target_id: int = -1) -> void:
	send_action("USE_ITEM", {
		"troop_id": troop_id,
		"item_id": item_id,
		"target_id": target_id
	})


func send_heal_action(healer_id: int, target_id: int) -> void:
	send_action("HEAL", {
		"healer_id": healer_id,
		"target_id": target_id
	})


# =============================================================================
# UTILITY
# =============================================================================

## Get player count
func get_player_count() -> int:
	return connected_players.size()


## Check if lobby is full
func is_lobby_full() -> bool:
	return connected_players.size() >= MAX_PLAYERS


## Get local player's peer ID
func get_local_peer_id() -> int:
	return local_peer_id


## Check if this is the host
func is_server() -> bool:
	return is_host


## Get player index (0 or 1) from peer ID
func get_player_index(peer_id: int) -> int:
	var index = 0
	var sorted_peers = connected_players.keys()
	sorted_peers.sort()
	
	for p_id in sorted_peers:
		if p_id == peer_id:
			return index
		index += 1
	
	return -1


## Get peer ID from player index
func get_peer_id_for_player(player_index: int) -> int:
	var sorted_peers = connected_players.keys()
	sorted_peers.sort()
	
	if player_index >= 0 and player_index < sorted_peers.size():
		return sorted_peers[player_index]
	
	return -1
