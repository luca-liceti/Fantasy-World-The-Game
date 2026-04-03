## Lobby UI — Fantasy World
## Online Multiplayer lobby. Full-screen over the revolving background.
## Left panel: JOIN GAME / HOST GAME switching flow.
## Right panel: MY STATUS (player name, region).
## All styling via UITheme (Cinzel font, banner textures, content_box panels).
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

# Panel geometry
const LEFT_W  = 440
const RIGHT_W = 320
const PANEL_H = 480
const GAP     = 24       # gap between left and right panels

# =============================================================================
# STATES
# =============================================================================
enum LobbyState { MODE_SELECT, HOSTING, JOINING, CONNECTING, IN_LOBBY, GAME_STARTING }
var current_state: LobbyState = LobbyState.MODE_SELECT

# =============================================================================
# NODES
# =============================================================================
var _root:            Control       = null
var _status_lbl:      Label         = null

# Left panel content areas (swapped out by state)
var _left_panel:      PanelContainer = null
var _left_inner:      VBoxContainer  = null

# Right panel (always visible)
var _right_panel:     PanelContainer = null

# Join sub-view
var _ip_input:        LineEdit = null
var _port_input:      LineEdit = null
var _connect_btn:     Button   = null
var _join_back_btn:   Button   = null

# Lobby sub-view
var _player1_lbl:     Label    = null
var _player2_lbl:     Label    = null
var _player1_status:  Label    = null
var _player2_status:  Label    = null
var _ready_btn:       Button   = null
var _start_btn:       Button   = null
var _conn_info_lbl:   Label    = null

# Right panel widgets (always present)
var _player_name_input: LineEdit = null
var _region_opt:        OptionButton = null

# Network
var network_manager: NetworkManager = null


# =============================================================================
# READY
# =============================================================================

func _ready() -> void:
	layer = 20
	_build_ui()
	_show_mode_selection()

func set_network_manager(manager: NetworkManager) -> void:
	network_manager = manager
	_connect_network_signals()


# =============================================================================
# UI BUILD
# =============================================================================

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# Dark scrim for legibility over the revolving backgrounds
	var scrim = ColorRect.new()
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.0, 0.0, 0.0, 0.55)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(scrim)

	_build_logo()
	_build_page_title()
	_build_panels()
	_build_back_btn()


func _build_logo() -> void:
	var sub_logo_scale = 0.30
	var lw = UITheme.LOGO_W * sub_logo_scale
	var lh = UITheme.LOGO_H * sub_logo_scale
	var logo = TextureRect.new()
	logo.texture      = UITheme.tex_logo()
	logo.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(lw, lh)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	logo.position = Vector2(-lw * 0.5, 20)
	_root.add_child(logo)

func _build_page_title() -> void:
	# Base title positioning on a safer estimated logo height
	var title_top = 160.0

	var title = Label.new()
	title.text = "MULTIPLAYER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.custom_minimum_size = Vector2(800, 56)
	title.position = Vector2(-400, title_top)
	UITheme.style_label(title, UITheme.TITLE_FONT, UITheme.C_GOLD, true)
	_root.add_child(title)

	_status_lbl = Label.new()
	_status_lbl.text = "Choose how to play"
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_status_lbl.custom_minimum_size = Vector2(600, 32)
	_status_lbl.position = Vector2(-300, title_top + 68)
	UITheme.style_label(_status_lbl, 16, UITheme.C_DIM)
	_root.add_child(_status_lbl)

	var sep = UITheme.make_separator()
	sep.set_anchors_preset(Control.PRESET_CENTER_TOP)
	sep.custom_minimum_size = Vector2(640, 4)
	sep.position = Vector2(-320, title_top + 116)
	_root.add_child(sep)

func _build_panels() -> void:
	var panel_top = 300.0
	var total_w   = LEFT_W + GAP + RIGHT_W
	
	# Create a centering anchor that covers the screen width at the target Y
	# Even if the content grows (like the 3-button host lobby), it stays centered.
	var anchor = CenterContainer.new()
	anchor.set_anchors_preset(Control.PRESET_CENTER_TOP)
	anchor.custom_minimum_size = Vector2(1920, PANEL_H) # Full screen width for centering
	anchor.position = Vector2(-960, panel_top)
	_root.add_child(anchor)

	var holder = HBoxContainer.new()
	holder.name = "PanelHolder"
	holder.add_theme_constant_override("separation", GAP)
	anchor.add_child(holder)

	# === LEFT PANEL ===
	_left_panel = PanelContainer.new()
	_left_panel.name = "LeftPanel"
	_left_panel.custom_minimum_size = Vector2(LEFT_W, PANEL_H)
	UITheme.apply_panel(_left_panel)
	holder.add_child(_left_panel)

	# Scroll inside left
	var lscroll = ScrollContainer.new()
	lscroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	lscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_left_panel.add_child(lscroll)

	_left_inner = VBoxContainer.new()
	_left_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left_inner.add_theme_constant_override("separation", 18)
	lscroll.add_child(_left_inner)

	# === RIGHT PANEL (MY STATUS) ===
	_right_panel = PanelContainer.new()
	_right_panel.name = "RightPanel"
	_right_panel.custom_minimum_size = Vector2(RIGHT_W, PANEL_H)
	UITheme.apply_panel(_right_panel)
	holder.add_child(_right_panel)

	_build_right_panel_content()

func _build_right_panel_content() -> void:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20) # More breathing room
	_right_panel.add_child(vbox)

	_add_panel_title(vbox, "MY STATUS")

	# Player name
	_add_field_label(vbox, "PLAYER NAME")
	_player_name_input = LineEdit.new()
	_player_name_input.placeholder_text = "Enter your name…"
	_player_name_input.custom_minimum_size = Vector2(0, UITheme.INPUT_H)
	_player_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_input(_player_name_input)
	vbox.add_child(_player_name_input)

	vbox.add_child(UITheme.make_separator())

	# Region
	_add_field_label(vbox, "REGION")
	_region_opt = OptionButton.new()
	_region_opt.custom_minimum_size = Vector2(0, UITheme.INPUT_H)
	_region_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for r in ["Auto-Detect", "North America", "Europe", "Asia", "South America", "Oceania"]:
		_region_opt.add_item(r)
	UITheme.apply_dropdown(_region_opt)
	vbox.add_child(_region_opt)

	vbox.add_child(UITheme.make_separator())

	# Connection status decoration
	var conn_lbl = Label.new()
	conn_lbl.text = "CONNECTION STATUS"
	UITheme.style_label(conn_lbl, 12, UITheme.C_GOLD, true)
	vbox.add_child(conn_lbl)

	_conn_info_lbl = Label.new()
	_conn_info_lbl.text = "Not connected"
	_conn_info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.style_label(_conn_info_lbl, 13, UITheme.C_DIM)
	vbox.add_child(_conn_info_lbl)

func _build_back_btn() -> void:
	var back = Button.new()
	back.name  = "BackBtn"
	back.text  = "BACK"
	back.custom_minimum_size = Vector2(UITheme.BTN_SM_W, UITheme.BTN_SM_H)
	back.pivot_offset = Vector2(UITheme.BTN_SM_W * 0.5, UITheme.BTN_SM_H * 0.5)
	back.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	back.position = Vector2(UITheme.PAD * 2, -(UITheme.BTN_SM_H + UITheme.PAD * 2))
	UITheme.apply_menu_button(back, UITheme.BTN_SM_FONT)
	back.pressed.connect(_on_back_pressed)
	back.button_down.connect(func(): _hover_press(back))
	back.button_up.connect(func():  _hover_release(back))
	_root.add_child(back)




# =============================================================================
# LEFT PANEL STATES
# =============================================================================

func _show_mode_selection() -> void:
	current_state = LobbyState.MODE_SELECT
	_status_lbl.text = "Choose how to play"
	_clear_left()

	_add_panel_title(_left_inner, "JOIN GAME")
	_add_info(_left_inner, "Connect to a friend's hosted game\nor browse public sessions.")

	var host_btn = _make_panel_btn("HOST GAME")
	host_btn.pressed.connect(_on_host_pressed)
	_left_inner.add_child(host_btn)

	var join_btn = _make_panel_btn("JOIN GAME")
	join_btn.pressed.connect(_on_join_pressed)
	_left_inner.add_child(join_btn)

func _show_join_panel() -> void:
	current_state = LobbyState.JOINING
	_status_lbl.text = "Enter the host IP address"
	_clear_left()

	_add_panel_title(_left_inner, "JOIN A GAME")

	_add_field_label(_left_inner, "HOST IP ADDRESS")
	_ip_input = LineEdit.new()
	_ip_input.placeholder_text = "e.g. 192.168.1.10"
	_ip_input.custom_minimum_size = Vector2(0, UITheme.INPUT_H)
	_ip_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_input(_ip_input)
	_left_inner.add_child(_ip_input)

	_add_field_label(_left_inner, "PORT")
	_port_input = LineEdit.new()
	_port_input.text = str(DEFAULT_PORT)
	_port_input.custom_minimum_size = Vector2(0, UITheme.INPUT_H)
	_port_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_input(_port_input)
	_left_inner.add_child(_port_input)

	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_left_inner.add_child(row)

	_join_back_btn = _make_small_btn("BACK")
	_join_back_btn.pressed.connect(_show_mode_selection)
	row.add_child(_join_back_btn)

	_connect_btn = _make_small_btn("CONNECT")
	_connect_btn.add_theme_color_override("font_color", UITheme.C_GOLD_BRIGHT)
	_connect_btn.pressed.connect(_on_connect_pressed)
	row.add_child(_connect_btn)

	_ip_input.grab_focus()

func _show_lobby(as_host: bool) -> void:
	current_state = LobbyState.IN_LOBBY
	_clear_left()

	_add_panel_title(_left_inner, "GAME LOBBY")
	_inner_conn_info_update(as_host)

	# Player slots
	_add_field_label(_left_inner, "PLAYERS")
	var p1_row = _make_player_row("PLAYER 1 (HOST)", true)
	_player1_lbl    = p1_row.get_node("Name")
	_player1_status = p1_row.get_node("Status")
	_left_inner.add_child(p1_row)

	var p2_row = _make_player_row("PLAYER 2", false)
	_player2_lbl    = p2_row.get_node("Name")
	_player2_status = p2_row.get_node("Status")
	_left_inner.add_child(p2_row)

	_left_inner.add_child(UITheme.make_separator())

	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_left_inner.add_child(row)

	# Leave
	var leave_btn = _make_small_btn("LEAVE")
	leave_btn.pressed.connect(_on_leave_pressed)
	row.add_child(leave_btn)

	# Ready
	_ready_btn = _make_small_btn("READY")
	_ready_btn.pressed.connect(_on_ready_pressed)
	row.add_child(_ready_btn)

	# Start (host only)
	_start_btn = _make_small_btn("START")
	_start_btn.add_theme_color_override("font_color", UITheme.C_GOLD_BRIGHT)
	_start_btn.visible  = as_host
	_start_btn.disabled = true
	_start_btn.pressed.connect(_on_start_pressed)
	row.add_child(_start_btn)

	if as_host:
		_status_lbl.text = "Waiting for players to join…"
		if _player1_lbl:
			_player1_lbl.text = "YOU (Host)"
		if _player1_status:
			_player1_status.text = "Connected"
			_player1_status.add_theme_color_override("font_color", UITheme.C_GOLD)
		if _player2_lbl:
			_player2_lbl.text = "Waiting…"
		if _player2_status:
			_player2_status.text = ""
	else:
		_status_lbl.text = "Connected to host"
		if _player1_lbl:
			_player1_lbl.text = "Host"
		if _player2_lbl:
			_player2_lbl.text = "YOU"
		if _player2_status:
			_player2_status.text = "Ready?"

func _inner_conn_info_update(as_host: bool) -> void:
	if as_host:
		_conn_info_lbl.text = "Your IP: " + _local_ip() + ":%d" % DEFAULT_PORT
	else:
		_conn_info_lbl.text = "Connected to host"
	_conn_info_lbl.add_theme_color_override("font_color", UITheme.C_GOLD)


# =============================================================================
# PANEL BUILDER HELPERS
# =============================================================================

func _clear_left() -> void:
	for c in _left_inner.get_children():
		c.queue_free()

func _add_panel_title(parent: VBoxContainer, text: String) -> void:
	var lbl = Label.new()
	lbl.text = text
	UITheme.style_label(lbl, 20, UITheme.C_GOLD, true)
	parent.add_child(lbl)
	parent.add_child(UITheme.make_separator())

func _add_field_label(parent: Control, text: String) -> void:
	var lbl = Label.new()
	lbl.text = text
	UITheme.style_label(lbl, 12, UITheme.C_GOLD, true)
	parent.add_child(lbl)

func _add_info(parent: VBoxContainer, text: String) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.style_label(lbl, 14, UITheme.C_DIM)
	parent.add_child(lbl)

## Full-width panel button
func _make_panel_btn(text: String) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, UITheme.BTN_H)
	# Pivot at centre for even scale animations
	btn.pivot_offset = Vector2(btn.custom_minimum_size.x * 0.5 if btn.custom_minimum_size.x > 0 else 180, UITheme.BTN_H * 0.5)
	UITheme.apply_menu_button(btn, UITheme.BTN_FONT_SIZE)
	btn.button_down.connect(func(): _hover_press(btn))
	btn.button_up.connect(func():  _hover_release(btn))
	return btn

## Compact button (half-width pair)
func _make_small_btn(text: String) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(200, UITheme.BTN_SM_H)
	# Pivot at centre for even scale animations
	btn.pivot_offset = Vector2(100, UITheme.BTN_SM_H * 0.5)
	UITheme.apply_menu_button(btn, UITheme.BTN_SM_FONT)
	btn.button_down.connect(func(): _hover_press(btn))
	btn.button_up.connect(func():  _hover_release(btn))
	return btn

func _make_player_row(default_name: String, _is_host: bool) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.custom_minimum_size = Vector2(0, 32)

	var name_lbl = Label.new()
	name_lbl.name = "Name"
	name_lbl.text = default_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.style_label(name_lbl, 16, UITheme.C_WARM_WHITE)
	row.add_child(name_lbl)

	var status_lbl = Label.new()
	status_lbl.name = "Status"
	status_lbl.text = "Waiting…"
	status_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.style_label(status_lbl, 14, UITheme.C_DIM)
	row.add_child(status_lbl)

	return row

func _hover_press(btn: Button) -> void:
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.08)

func _hover_release(btn: Button) -> void:
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12)


# =============================================================================
# NETWORK HELPERS
# =============================================================================

func _connect_network_signals() -> void:
	if network_manager == null: return
	network_manager.connection_succeeded.connect(_on_connection_succeeded)
	network_manager.connection_failed.connect(_on_connection_failed)
	network_manager.server_started.connect(_on_server_started)
	network_manager.player_connected.connect(_on_player_connected)
	network_manager.player_disconnected.connect(_on_player_disconnected)
	network_manager.all_players_ready.connect(_on_all_players_ready)

func _update_player_list() -> void:
	if network_manager == null: return
	var players  = network_manager.connected_players
	var is_host  = network_manager.is_host

	if players.size() >= 2:
		_status_lbl.text = "All players connected!"
		if _start_btn: _start_btn.disabled = not is_host
	else:
		_status_lbl.text = "Waiting for players…"
		if _start_btn: _start_btn.disabled = true

	for peer_id in players:
		var pd       = players[peer_id]
		var is_ready = network_manager.players_ready.get(peer_id, false)
		var col      = UITheme.C_GOLD if is_ready else UITheme.C_DIM

		if peer_id == 1:
			if _player1_lbl:
				_player1_lbl.text = pd.get("player_name", "Host")
				if is_host: _player1_lbl.text += " (You)"
			if _player1_status:
				_player1_status.text = "READY" if is_ready else "Not Ready"
				_player1_status.add_theme_color_override("font_color", col)
		else:
			if _player2_lbl:
				_player2_lbl.text = pd.get("player_name", "Player 2")
				if not is_host: _player2_lbl.text += " (You)"
			if _player2_status:
				_player2_status.text = "READY" if is_ready else "Not Ready"
				_player2_status.add_theme_color_override("font_color", col)

func _local_ip() -> String:
	for addr in IP.get_local_addresses():
		if addr.begins_with("192.168.") or addr.begins_with("10.") or addr.begins_with("172."):
			return addr
	return "127.0.0.1"


# =============================================================================
# BUTTON CALLBACKS
# =============================================================================

func _on_host_pressed() -> void:
	if network_manager == null:
		network_manager = NetworkManager.new()
		add_child(network_manager)
		_connect_network_signals()
	var err = network_manager.host_game(DEFAULT_PORT)
	if err == OK:
		_show_lobby(true)
	else:
		_status_lbl.text = "Failed to start server!"
		_status_lbl.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))

func _on_join_pressed() -> void:
	_show_join_panel()

func _on_back_pressed() -> void:
	lobby_cancelled.emit()

func _on_connect_pressed() -> void:
	var address = _ip_input.text.strip_edges()
	if address.is_empty():
		address = "127.0.0.1"
	var port = int(_port_input.text.strip_edges())
	if port == 0:
		port = DEFAULT_PORT

	if network_manager == null:
		network_manager = NetworkManager.new()
		add_child(network_manager)
		_connect_network_signals()

	current_state = LobbyState.CONNECTING
	_status_lbl.text = "Connecting to " + address + "…"
	if _connect_btn: _connect_btn.disabled = true

	var err = network_manager.join_game(address, port)
	if err != OK:
		_status_lbl.text = "Failed to connect!"
		_status_lbl.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		if _connect_btn: _connect_btn.disabled = false

func _on_leave_pressed() -> void:
	if network_manager:
		network_manager.disconnect_game()
	_show_mode_selection()

func _on_ready_pressed() -> void:
	if network_manager == null: return
	var is_ready = network_manager.players_ready.get(network_manager.local_peer_id, false)
	network_manager.set_ready(!is_ready)
	if _ready_btn:
		_ready_btn.text = "NOT READY" if is_ready else "READY ✓"
		_ready_btn.add_theme_color_override("font_color",
				UITheme.C_DIM if is_ready else UITheme.C_GOLD_BRIGHT)
	_update_player_list()

func _on_start_pressed() -> void:
	if network_manager == null or not network_manager.is_host: return
	current_state = LobbyState.GAME_STARTING
	network_manager.generate_and_sync_seed()
	game_starting.emit()


# =============================================================================
# NETWORK CALLBACKS
# =============================================================================

func _on_connection_succeeded() -> void:
	_show_lobby(false)

func _on_connection_failed(reason: String) -> void:
	_status_lbl.text = "Connection failed: " + reason
	_status_lbl.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	if _connect_btn: _connect_btn.disabled = false
	current_state = LobbyState.JOINING

func _on_server_started(_port: int) -> void:
	pass

func _on_player_connected(_peer_id: int) -> void:
	_update_player_list()

func _on_player_disconnected(_peer_id: int) -> void:
	_update_player_list()

func _on_all_players_ready() -> void:
	if network_manager and network_manager.is_host:
		if _start_btn: _start_btn.disabled = false
		_status_lbl.text = "All players ready — start the game!"
		_status_lbl.add_theme_color_override("font_color", UITheme.C_GOLD)

# =============================================================================
# INPUT
# =============================================================================

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if current_state == LobbyState.MODE_SELECT:
			_on_back_pressed()
			get_viewport().set_input_as_handled()
		elif current_state == LobbyState.JOINING or current_state == LobbyState.CONNECTING:
			_show_mode_selection()
			get_viewport().set_input_as_handled()
		elif current_state == LobbyState.IN_LOBBY:
			_on_leave_pressed()
			get_viewport().set_input_as_handled()
