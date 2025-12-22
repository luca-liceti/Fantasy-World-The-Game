## Lobby UI
## Multiplayer lobby for hosting/joining games
## Features: Host/Join buttons, IP input, player list, ready system
class_name LobbyUI
extends CanvasLayer

# =============================================================================
# SIGNALS
# =============================================================================
signal lobby_cancelled
signal game_starting

# =============================================================================
# CONSTANTS
# =============================================================================
const DEFAULT_PORT: int = 7777

# Colors matching start_menu.gd aesthetic
const BG_COLOR_TOP = Color(0.05, 0.08, 0.15, 1.0)
const BG_COLOR_BOTTOM = Color(0.12, 0.08, 0.18, 1.0)
const TITLE_COLOR = Color(0.95, 0.85, 0.55, 1.0)
const SUBTITLE_COLOR = Color(0.7, 0.75, 0.9, 1.0)
const BUTTON_BG = Color(0.15, 0.12, 0.25, 0.9)
const BUTTON_HOVER = Color(0.25, 0.2, 0.4, 0.95)
const BUTTON_TEXT = Color(0.9, 0.85, 0.7, 1.0)
const ACCENT_COLOR = Color(0.4, 0.6, 1.0, 1.0)
const ACCENT_HOST = Color(0.3, 0.8, 0.4, 1.0) # Green for host
const ACCENT_JOIN = Color(0.4, 0.6, 1.0, 1.0) # Blue for join
const ACCENT_READY = Color(0.3, 0.9, 0.3, 1.0) # Bright green
const ACCENT_NOT_READY = Color(0.6, 0.6, 0.6, 1.0) # Gray
const ACCENT_CANCEL = Color(0.8, 0.4, 0.4, 1.0) # Red
const PANEL_BG = Color(0.1, 0.08, 0.15, 0.95)
const PARTICLE_COLOR = Color(0.6, 0.7, 1.0, 0.3)

# =============================================================================
# UI STATES
# =============================================================================
enum LobbyState {
	MODE_SELECT, # Choose Host or Join
	HOSTING, # Waiting for players as host
	JOINING, # Entering IP to join
	CONNECTING, # Connecting to host
	IN_LOBBY, # In the lobby, waiting for ready
	GAME_STARTING # Both players ready, starting game
}

var current_state: LobbyState = LobbyState.MODE_SELECT

# =============================================================================
# UI ELEMENTS
# =============================================================================
var background: ColorRect
var main_container: Control
var title_label: Label
var status_label: Label

# Mode selection elements
var mode_panel: PanelContainer
var host_button: Button
var join_button: Button
var back_button: Button

# Join elements
var join_panel: PanelContainer
var ip_input: LineEdit
var port_input: LineEdit
var connect_button: Button
var join_back_button: Button

# Lobby elements
var lobby_panel: PanelContainer
var player_list_container: VBoxContainer
var player1_label: Label
var player2_label: Label
var player1_status: Label
var player2_status: Label
var ready_button: Button
var start_button: Button
var leave_button: Button
var connection_info_label: Label

# Particle effect
var particles: Array[Dictionary] = []
const NUM_PARTICLES: int = 30

# Network manager reference
var network_manager: NetworkManager = null

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	layer = 100
	_create_ui()
	_initialize_particles()
	_show_mode_selection()


func set_network_manager(manager: NetworkManager) -> void:
	network_manager = manager
	_connect_network_signals()


func _connect_network_signals() -> void:
	if network_manager == null:
		return
	
	network_manager.connection_succeeded.connect(_on_connection_succeeded)
	network_manager.connection_failed.connect(_on_connection_failed)
	network_manager.server_started.connect(_on_server_started)
	network_manager.player_connected.connect(_on_player_connected)
	network_manager.player_disconnected.connect(_on_player_disconnected)
	network_manager.all_players_ready.connect(_on_all_players_ready)


func _create_ui() -> void:
	# Dark overlay background
	background = ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = BG_COLOR_TOP
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background)
	
	# Main container
	main_container = Control.new()
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_container)
	
	# Title
	_create_title()
	
	# Create all panels (will be shown/hidden based on state)
	_create_mode_selection_panel()
	_create_join_panel()
	_create_lobby_panel()


func _create_title() -> void:
	var title_container = VBoxContainer.new()
	title_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title_container.position = Vector2(-300, 60)
	title_container.custom_minimum_size = Vector2(600, 100)
	title_container.alignment = BoxContainer.ALIGNMENT_CENTER
	main_container.add_child(title_container)
	
	title_label = Label.new()
	title_label.text = "⚔️ MULTIPLAYER LOBBY ⚔️"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", TITLE_COLOR)
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	title_label.add_theme_constant_override("shadow_offset_x", 3)
	title_label.add_theme_constant_override("shadow_offset_y", 3)
	title_container.add_child(title_label)
	
	status_label = Label.new()
	status_label.text = "Choose how to play"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 20)
	status_label.add_theme_color_override("font_color", SUBTITLE_COLOR)
	title_container.add_child(status_label)


func _create_mode_selection_panel() -> void:
	mode_panel = _create_styled_panel()
	mode_panel.set_anchors_preset(Control.PRESET_CENTER)
	mode_panel.position = Vector2(-200, -100)
	mode_panel.custom_minimum_size = Vector2(400, 300)
	main_container.add_child(mode_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	mode_panel.add_child(vbox)
	
	# Mode selection label
	var label = Label.new()
	label.text = "SELECT GAME MODE"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", SUBTITLE_COLOR)
	vbox.add_child(label)
	
	# Host button
	host_button = _create_lobby_button("🏠  HOST GAME", ACCENT_HOST)
	host_button.pressed.connect(_on_host_pressed)
	vbox.add_child(host_button)
	
	# Join button
	join_button = _create_lobby_button("🔗  JOIN GAME", ACCENT_JOIN)
	join_button.pressed.connect(_on_join_pressed)
	vbox.add_child(join_button)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)
	
	# Back button
	back_button = _create_lobby_button("← BACK", ACCENT_CANCEL)
	back_button.custom_minimum_size = Vector2(200, 45)
	back_button.pressed.connect(_on_back_pressed)
	vbox.add_child(back_button)


func _create_join_panel() -> void:
	join_panel = _create_styled_panel()
	join_panel.set_anchors_preset(Control.PRESET_CENTER)
	join_panel.position = Vector2(-200, -120)
	join_panel.custom_minimum_size = Vector2(400, 320)
	join_panel.visible = false
	main_container.add_child(join_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	join_panel.add_child(vbox)
	
	# Title
	var label = Label.new()
	label.text = "JOIN A GAME"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", SUBTITLE_COLOR)
	vbox.add_child(label)
	
	# IP Address input
	var ip_container = VBoxContainer.new()
	ip_container.add_theme_constant_override("separation", 5)
	vbox.add_child(ip_container)
	
	var ip_label = Label.new()
	ip_label.text = "Host IP Address:"
	ip_label.add_theme_font_size_override("font_size", 16)
	ip_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	ip_container.add_child(ip_label)
	
	ip_input = LineEdit.new()
	ip_input.placeholder_text = "127.0.0.1"
	ip_input.custom_minimum_size = Vector2(350, 45)
	ip_input.add_theme_font_size_override("font_size", 18)
	_style_line_edit(ip_input)
	ip_container.add_child(ip_input)
	
	# Port input
	var port_container = VBoxContainer.new()
	port_container.add_theme_constant_override("separation", 5)
	vbox.add_child(port_container)
	
	var port_label = Label.new()
	port_label.text = "Port:"
	port_label.add_theme_font_size_override("font_size", 16)
	port_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	port_container.add_child(port_label)
	
	port_input = LineEdit.new()
	port_input.placeholder_text = str(DEFAULT_PORT)
	port_input.text = str(DEFAULT_PORT)
	port_input.custom_minimum_size = Vector2(350, 45)
	port_input.add_theme_font_size_override("font_size", 18)
	_style_line_edit(port_input)
	port_container.add_child(port_input)
	
	# Button container
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 15)
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(button_container)
	
	# Back button
	join_back_button = _create_lobby_button("← BACK", ACCENT_CANCEL)
	join_back_button.custom_minimum_size = Vector2(160, 50)
	join_back_button.pressed.connect(_on_join_back_pressed)
	button_container.add_child(join_back_button)
	
	# Connect button
	connect_button = _create_lobby_button("CONNECT →", ACCENT_JOIN)
	connect_button.custom_minimum_size = Vector2(160, 50)
	connect_button.pressed.connect(_on_connect_pressed)
	button_container.add_child(connect_button)


func _create_lobby_panel() -> void:
	lobby_panel = _create_styled_panel()
	lobby_panel.set_anchors_preset(Control.PRESET_CENTER)
	lobby_panel.position = Vector2(-250, -180)
	lobby_panel.custom_minimum_size = Vector2(500, 400)
	lobby_panel.visible = false
	main_container.add_child(lobby_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	lobby_panel.add_child(vbox)
	
	# Title
	var label = Label.new()
	label.text = "GAME LOBBY"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", TITLE_COLOR)
	vbox.add_child(label)
	
	# Connection info
	connection_info_label = Label.new()
	connection_info_label.text = "Waiting for connection..."
	connection_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	connection_info_label.add_theme_font_size_override("font_size", 14)
	connection_info_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	vbox.add_child(connection_info_label)
	
	# Player list container
	player_list_container = VBoxContainer.new()
	player_list_container.add_theme_constant_override("separation", 10)
	vbox.add_child(player_list_container)
	
	# Player 1 slot
	var p1_container = _create_player_slot("PLAYER 1", true)
	player1_label = p1_container.get_node("NameLabel")
	player1_status = p1_container.get_node("StatusLabel")
	player_list_container.add_child(p1_container)
	
	# Player 2 slot
	var p2_container = _create_player_slot("PLAYER 2", false)
	player2_label = p2_container.get_node("NameLabel")
	player2_status = p2_container.get_node("StatusLabel")
	player_list_container.add_child(p2_container)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)
	
	# Button container
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 15)
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(button_container)
	
	# Leave button
	leave_button = _create_lobby_button("🚪 LEAVE", ACCENT_CANCEL)
	leave_button.custom_minimum_size = Vector2(140, 50)
	leave_button.pressed.connect(_on_leave_pressed)
	button_container.add_child(leave_button)
	
	# Ready button
	ready_button = _create_lobby_button("✓ READY", ACCENT_READY)
	ready_button.custom_minimum_size = Vector2(140, 50)
	ready_button.pressed.connect(_on_ready_pressed)
	button_container.add_child(ready_button)
	
	# Start button (host only)
	start_button = _create_lobby_button("▶ START", ACCENT_HOST)
	start_button.custom_minimum_size = Vector2(140, 50)
	start_button.visible = false
	start_button.disabled = true
	start_button.pressed.connect(_on_start_pressed)
	button_container.add_child(start_button)


func _create_player_slot(default_name: String, is_host: bool) -> HBoxContainer:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 10)
	container.custom_minimum_size = Vector2(450, 60)
	
	# Player panel
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(450, 60)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.1, 0.18, 0.9)
	panel_style.border_color = ACCENT_COLOR.darkened(0.3) if not is_host else ACCENT_HOST.darkened(0.3)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 15
	panel_style.content_margin_right = 15
	panel_style.content_margin_top = 10
	panel_style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", panel_style)
	container.add_child(panel)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)
	
	# Player icon
	var icon = Label.new()
	icon.text = "👑" if is_host else "⚔️"
	icon.add_theme_font_size_override("font_size", 24)
	hbox.add_child(icon)
	
	# Name label
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = default_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", BUTTON_TEXT)
	hbox.add_child(name_label)
	
	# Status label
	var status = Label.new()
	status.name = "StatusLabel"
	status.text = "Waiting..."
	status.add_theme_font_size_override("font_size", 16)
	status.add_theme_color_override("font_color", ACCENT_NOT_READY)
	hbox.add_child(status)
	
	return container


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

func _create_styled_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = ACCENT_COLOR.darkened(0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 25
	style.content_margin_bottom = 25
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _create_lobby_button(text: String, accent: Color) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(350, 55)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", BUTTON_TEXT)
	
	# Normal style
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = BUTTON_BG
	normal_style.border_color = accent.darkened(0.3)
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(10)
	normal_style.content_margin_left = 20
	normal_style.content_margin_right = 20
	normal_style.content_margin_top = 12
	normal_style.content_margin_bottom = 12
	button.add_theme_stylebox_override("normal", normal_style)
	
	# Hover style
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = BUTTON_HOVER
	hover_style.border_color = accent
	hover_style.set_border_width_all(3)
	hover_style.set_corner_radius_all(10)
	hover_style.content_margin_left = 20
	hover_style.content_margin_right = 20
	hover_style.content_margin_top = 12
	hover_style.content_margin_bottom = 12
	button.add_theme_stylebox_override("hover", hover_style)
	
	# Pressed style
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = accent.darkened(0.4)
	pressed_style.border_color = accent.lightened(0.2)
	pressed_style.set_border_width_all(3)
	pressed_style.set_corner_radius_all(10)
	pressed_style.content_margin_left = 20
	pressed_style.content_margin_right = 20
	pressed_style.content_margin_top = 12
	pressed_style.content_margin_bottom = 12
	button.add_theme_stylebox_override("pressed", pressed_style)
	
	# Disabled style
	var disabled_style = StyleBoxFlat.new()
	disabled_style.bg_color = Color(0.15, 0.15, 0.15, 0.8)
	disabled_style.border_color = Color(0.3, 0.3, 0.3)
	disabled_style.set_border_width_all(2)
	disabled_style.set_corner_radius_all(10)
	disabled_style.content_margin_left = 20
	disabled_style.content_margin_right = 20
	disabled_style.content_margin_top = 12
	disabled_style.content_margin_bottom = 12
	button.add_theme_stylebox_override("disabled", disabled_style)
	button.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))
	
	# Focus style (same as hover)
	button.add_theme_stylebox_override("focus", hover_style)
	
	# Hover animation
	button.mouse_entered.connect(_on_button_hover.bind(button))
	button.mouse_exited.connect(_on_button_unhover.bind(button))
	
	return button


func _style_line_edit(line_edit: LineEdit) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.12, 0.95)
	style.border_color = ACCENT_COLOR.darkened(0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	line_edit.add_theme_stylebox_override("normal", style)
	
	var focus_style = style.duplicate()
	focus_style.border_color = ACCENT_COLOR
	line_edit.add_theme_stylebox_override("focus", focus_style)
	
	line_edit.add_theme_color_override("font_color", Color.WHITE)
	line_edit.add_theme_color_override("font_placeholder_color", Color(0.5, 0.5, 0.5))


# =============================================================================
# STATE MANAGEMENT
# =============================================================================

func _show_mode_selection() -> void:
	current_state = LobbyState.MODE_SELECT
	status_label.text = "Choose how to play"
	mode_panel.visible = true
	join_panel.visible = false
	lobby_panel.visible = false


func _show_join_panel() -> void:
	current_state = LobbyState.JOINING
	status_label.text = "Enter host IP address"
	mode_panel.visible = false
	join_panel.visible = true
	lobby_panel.visible = false
	ip_input.grab_focus()


func _show_lobby(as_host: bool) -> void:
	current_state = LobbyState.IN_LOBBY
	mode_panel.visible = false
	join_panel.visible = false
	lobby_panel.visible = true
	
	if as_host:
		status_label.text = "Waiting for players to join..."
		start_button.visible = true
		start_button.disabled = true
		player1_label.text = "YOU (Host)"
		player1_status.text = "Connected"
		player1_status.add_theme_color_override("font_color", ACCENT_HOST)
		player2_label.text = "Waiting..."
		player2_status.text = ""
		
		# Show connection info
		var ip_info = "Your IP: " + _get_local_ip() + ":" + str(DEFAULT_PORT)
		connection_info_label.text = ip_info
	else:
		status_label.text = "Connected to host"
		start_button.visible = false
		player1_label.text = "Host"
		player1_status.text = "Connected"
		player1_status.add_theme_color_override("font_color", ACCENT_HOST)
		player2_label.text = "YOU"
		player2_status.text = "Ready?"
		connection_info_label.text = ""


func _update_player_list() -> void:
	if network_manager == null:
		return
	
	var players = network_manager.connected_players
	var is_host = network_manager.is_host
	
	# Update based on connected players
	if players.size() >= 2:
		status_label.text = "All players connected!"
		start_button.disabled = false if is_host else true
	else:
		status_label.text = "Waiting for players..."
		start_button.disabled = true
	
	# Update player statuses based on ready state
	for peer_id in players:
		var player_data = players[peer_id]
		var is_ready = network_manager.players_ready.get(peer_id, false)
		
		if peer_id == 1: # Host
			player1_label.text = player_data.get("player_name", "Host")
			if is_host:
				player1_label.text += " (You)"
			player1_status.text = "READY" if is_ready else "Not Ready"
			player1_status.add_theme_color_override("font_color", ACCENT_READY if is_ready else ACCENT_NOT_READY)
		else: # Client
			player2_label.text = player_data.get("player_name", "Player 2")
			if not is_host:
				player2_label.text += " (You)"
			player2_status.text = "READY" if is_ready else "Not Ready"
			player2_status.add_theme_color_override("font_color", ACCENT_READY if is_ready else ACCENT_NOT_READY)


func _get_local_ip() -> String:
	var addresses = IP.get_local_addresses()
	for addr in addresses:
		# Filter for IPv4 addresses that aren't localhost
		if addr.begins_with("192.168.") or addr.begins_with("10.") or addr.begins_with("172."):
			return addr
	return "127.0.0.1"


# =============================================================================
# BUTTON CALLBACKS
# =============================================================================

func _on_host_pressed() -> void:
	print("Host button pressed")
	
	if network_manager == null:
		network_manager = NetworkManager.new()
		add_child(network_manager)
		_connect_network_signals()
	
	var error = network_manager.host_game(DEFAULT_PORT)
	if error == OK:
		_show_lobby(true)
	else:
		status_label.text = "Failed to start server!"
		status_label.add_theme_color_override("font_color", ACCENT_CANCEL)


func _on_join_pressed() -> void:
	print("Join button pressed")
	_show_join_panel()


func _on_back_pressed() -> void:
	print("Back button pressed")
	lobby_cancelled.emit()
	queue_free()


func _on_join_back_pressed() -> void:
	print("Join back button pressed")
	_show_mode_selection()


func _on_connect_pressed() -> void:
	var address = ip_input.text.strip_edges()
	if address.is_empty():
		address = "127.0.0.1"
	
	var port = int(port_input.text.strip_edges())
	if port == 0:
		port = DEFAULT_PORT
	
	print("Connecting to: ", address, ":", port)
	
	if network_manager == null:
		network_manager = NetworkManager.new()
		add_child(network_manager)
		_connect_network_signals()
	
	current_state = LobbyState.CONNECTING
	status_label.text = "Connecting to " + address + "..."
	connect_button.disabled = true
	
	var error = network_manager.join_game(address, port)
	if error != OK:
		status_label.text = "Failed to connect!"
		status_label.add_theme_color_override("font_color", ACCENT_CANCEL)
		connect_button.disabled = false


func _on_leave_pressed() -> void:
	print("Leave button pressed")
	
	if network_manager:
		network_manager.disconnect_game()
	
	_show_mode_selection()


func _on_ready_pressed() -> void:
	if network_manager == null:
		return
	
	# Toggle ready state
	var is_ready = network_manager.players_ready.get(network_manager.local_peer_id, false)
	network_manager.set_ready(!is_ready)
	
	# Update button text
	if !is_ready:
		ready_button.text = "✗ NOT READY"
		ready_button.add_theme_color_override("font_color", ACCENT_CANCEL)
	else:
		ready_button.text = "✓ READY"
		ready_button.add_theme_color_override("font_color", ACCENT_READY)
	
	_update_player_list()


func _on_start_pressed() -> void:
	if network_manager == null or not network_manager.is_host:
		return
	
	print("Starting game!")
	current_state = LobbyState.GAME_STARTING
	
	# Generate and sync the game seed
	network_manager.generate_and_sync_seed()
	
	game_starting.emit()


# =============================================================================
# NETWORK CALLBACKS
# =============================================================================

func _on_connection_succeeded() -> void:
	print("Connection succeeded!")
	_show_lobby(false)


func _on_connection_failed(reason: String) -> void:
	print("Connection failed: ", reason)
	status_label.text = "Connection failed: " + reason
	status_label.add_theme_color_override("font_color", ACCENT_CANCEL)
	connect_button.disabled = false
	current_state = LobbyState.JOINING


func _on_server_started(port: int) -> void:
	print("Server started on port: ", port)


func _on_player_connected(peer_id: int) -> void:
	print("Player connected: ", peer_id)
	_update_player_list()


func _on_player_disconnected(peer_id: int) -> void:
	print("Player disconnected: ", peer_id)
	_update_player_list()


func _on_all_players_ready() -> void:
	print("All players ready!")
	if network_manager and network_manager.is_host:
		start_button.disabled = false
		status_label.text = "All players ready! Start the game!"
		status_label.add_theme_color_override("font_color", ACCENT_READY)


# =============================================================================
# PARTICLE ANIMATION
# =============================================================================

func _initialize_particles() -> void:
	# Note: Particles are not drawn since CanvasLayer doesn't support _draw
	# The background ColorRect provides the visual instead
	pass


func _process(_delta: float) -> void:
	# No particle animation needed - using solid background
	pass


# =============================================================================
# BUTTON HOVER ANIMATIONS
# =============================================================================

func _on_button_hover(button: Button) -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "scale", Vector2(1.03, 1.03), 0.12)


func _on_button_unhover(button: Button) -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.08)
