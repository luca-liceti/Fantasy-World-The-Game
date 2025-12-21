## Network Test Scene
## Simple scene to test Host/Join functionality
## Run two instances of this scene to test multiplayer
extends Control

# =============================================================================
# NODES
# =============================================================================
var network_manager: NetworkManager
var status_label: Label
var host_button: Button
var join_button: Button
var ip_input: LineEdit
var ready_button: Button
var disconnect_button: Button
var log_output: RichTextLabel

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_create_ui()
	_setup_network_manager()
	_log("Network Test Ready. Host or Join a game.")


func _setup_network_manager() -> void:
	network_manager = NetworkManager.new()
	add_child(network_manager)
	
	# Connect signals
	network_manager.server_started.connect(_on_server_started)
	network_manager.connection_succeeded.connect(_on_connection_succeeded)
	network_manager.connection_failed.connect(_on_connection_failed)
	network_manager.player_connected.connect(_on_player_connected)
	network_manager.player_disconnected.connect(_on_player_disconnected)
	network_manager.all_players_ready.connect(_on_all_players_ready)
	network_manager.game_seed_received.connect(_on_game_seed_received)


# =============================================================================
# UI CREATION
# =============================================================================

func _create_ui() -> void:
	# Main container
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)
	
	# Margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	vbox.add_child(margin)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(inner_vbox)
	
	# Title
	var title = Label.new()
	title.text = "Fantasy World - Network Test"
	title.add_theme_font_size_override("font_size", 24)
	inner_vbox.add_child(title)
	
	# Status
	status_label = Label.new()
	status_label.text = "Status: Disconnected"
	status_label.add_theme_color_override("font_color", Color.YELLOW)
	inner_vbox.add_child(status_label)
	
	# Separator
	inner_vbox.add_child(HSeparator.new())
	
	# Host button
	host_button = Button.new()
	host_button.text = "Host Game (Port 7777)"
	host_button.pressed.connect(_on_host_pressed)
	inner_vbox.add_child(host_button)
	
	# Join section
	var join_hbox = HBoxContainer.new()
	inner_vbox.add_child(join_hbox)
	
	var ip_label = Label.new()
	ip_label.text = "IP Address:"
	join_hbox.add_child(ip_label)
	
	ip_input = LineEdit.new()
	ip_input.text = "127.0.0.1"
	ip_input.custom_minimum_size.x = 150
	join_hbox.add_child(ip_input)
	
	join_button = Button.new()
	join_button.text = "Join Game"
	join_button.pressed.connect(_on_join_pressed)
	join_hbox.add_child(join_button)
	
	# Separator
	inner_vbox.add_child(HSeparator.new())
	
	# Ready button
	ready_button = Button.new()
	ready_button.text = "Toggle Ready"
	ready_button.disabled = true
	ready_button.pressed.connect(_on_ready_pressed)
	inner_vbox.add_child(ready_button)
	
	# Disconnect button
	disconnect_button = Button.new()
	disconnect_button.text = "Disconnect"
	disconnect_button.disabled = true
	disconnect_button.pressed.connect(_on_disconnect_pressed)
	inner_vbox.add_child(disconnect_button)
	
	# Separator
	inner_vbox.add_child(HSeparator.new())
	
	# Log output
	var log_label = Label.new()
	log_label.text = "Log:"
	inner_vbox.add_child(log_label)
	
	log_output = RichTextLabel.new()
	log_output.custom_minimum_size = Vector2(400, 200)
	log_output.bbcode_enabled = true
	log_output.scroll_following = true
	inner_vbox.add_child(log_output)


# =============================================================================
# BUTTON HANDLERS
# =============================================================================

func _on_host_pressed() -> void:
	_log("Starting server...")
	var error = network_manager.host_game()
	
	if error == OK:
		host_button.disabled = true
		join_button.disabled = true
		ready_button.disabled = false
		disconnect_button.disabled = false
		
		# Generate game seed
		var seed_val = network_manager.generate_and_sync_seed()
		_log("Generated game seed: " + str(seed_val))
	else:
		_log("[color=red]Failed to start server![/color]")


func _on_join_pressed() -> void:
	var ip = ip_input.text.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1"
	
	_log("Connecting to " + ip + "...")
	var error = network_manager.join_game(ip)
	
	if error == OK:
		host_button.disabled = true
		join_button.disabled = true
	else:
		_log("[color=red]Failed to initiate connection![/color]")


var is_ready: bool = false

func _on_ready_pressed() -> void:
	is_ready = not is_ready
	network_manager.set_ready(is_ready)
	
	if is_ready:
		ready_button.text = "Ready ✓"
		_log("[color=green]You are READY[/color]")
	else:
		ready_button.text = "Toggle Ready"
		_log("[color=yellow]You are NOT ready[/color]")


func _on_disconnect_pressed() -> void:
	network_manager.disconnect_game()
	
	host_button.disabled = false
	join_button.disabled = false
	ready_button.disabled = true
	disconnect_button.disabled = true
	is_ready = false
	ready_button.text = "Toggle Ready"
	
	_update_status("Disconnected")
	_log("Disconnected from game")


# =============================================================================
# NETWORK CALLBACKS
# =============================================================================

func _on_server_started(port: int) -> void:
	_update_status("Hosting on port " + str(port))
	_log("[color=green]Server started on port " + str(port) + "[/color]")
	_log("Waiting for player to join...")


func _on_connection_succeeded() -> void:
	_update_status("Connected to server")
	_log("[color=green]Connected to server![/color]")
	
	ready_button.disabled = false
	disconnect_button.disabled = false


func _on_connection_failed(reason: String) -> void:
	_update_status("Connection failed")
	_log("[color=red]Connection failed: " + reason + "[/color]")
	
	host_button.disabled = false
	join_button.disabled = false


func _on_player_connected(peer_id: int) -> void:
	_log("[color=cyan]Player connected: Peer " + str(peer_id) + "[/color]")
	_log("Players in lobby: " + str(network_manager.get_player_count()) + "/" + str(NetworkManager.MAX_PLAYERS))


func _on_player_disconnected(peer_id: int) -> void:
	_log("[color=orange]Player disconnected: Peer " + str(peer_id) + "[/color]")


func _on_all_players_ready() -> void:
	_log("[color=lime]*** ALL PLAYERS READY! Game can start! ***[/color]")
	_update_status("All players ready!")


func _on_game_seed_received(seed_val: int) -> void:
	_log("Received game seed: " + str(seed_val))


# =============================================================================
# UTILITY
# =============================================================================

func _update_status(text: String) -> void:
	status_label.text = "Status: " + text


func _log(message: String) -> void:
	var timestamp = Time.get_time_string_from_system()
	log_output.append_text("[" + timestamp + "] " + message + "\n")
	print("[NetworkTest] " + message)
