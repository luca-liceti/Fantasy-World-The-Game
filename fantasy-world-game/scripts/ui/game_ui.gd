## Game UI
## Main in-game UI with action buttons, player info, and turn state
class_name GameUI
extends CanvasLayer

# =============================================================================
# SIGNALS
# =============================================================================
signal action_move_pressed
signal action_attack_pressed
signal action_place_mine_pressed
signal action_upgrade_pressed
signal action_end_turn_pressed
signal troop_slot_selected(slot_index: int)

# =============================================================================
# UI ELEMENTS
# =============================================================================
var main_container: Control

# Top bar
var turn_label: Label
var timer_label: Label
var current_player_label: Label

# Bottom bar
var action_container: HBoxContainer
var move_button: Button
var attack_button: Button
var place_mine_button: Button
var upgrade_button: Button
var end_turn_button: Button

# Side panels
var player1_panel: PanelContainer
var player2_panel: PanelContainer
var p1_gold_label: Label
var p1_xp_label: Label
var p2_gold_label: Label
var p2_xp_label: Label

# Info panel
var info_panel: PanelContainer
var info_label: Label

# Selected troop info
var selected_troop_panel: PanelContainer
var selected_troop_label: Label

# =============================================================================
# COLORS
# =============================================================================
const PLAYER1_COLOR = Color(0.2, 0.5, 1.0) # Blue
const PLAYER2_COLOR = Color(1.0, 0.3, 0.2) # Red
const BUTTON_NORMAL = Color(0.15, 0.15, 0.2)
const BUTTON_HOVER = Color(0.25, 0.25, 0.35)
const BUTTON_DISABLED = Color(0.1, 0.1, 0.12)


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_create_ui()


func _create_ui() -> void:
	# Main container
	main_container = Control.new()
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(main_container)
	
	_create_top_bar()
	_create_bottom_bar()
	_create_side_panels()
	_create_info_panel()
	_create_selected_troop_panel()


func _create_top_bar() -> void:
	var top_bar = PanelContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.custom_minimum_size = Vector2(0, 50)
	main_container.add_child(top_bar)
	
	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	top_bar.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_child(hbox)
	
	# Turn indicator
	turn_label = Label.new()
	turn_label.text = "TURN 1"
	turn_label.add_theme_font_size_override("font_size", 20)
	turn_label.add_theme_color_override("font_color", Color.WHITE)
	hbox.add_child(turn_label)
	
	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(50, 0)
	hbox.add_child(spacer1)
	
	# Current player
	current_player_label = Label.new()
	current_player_label.text = "PLAYER 1's TURN"
	current_player_label.add_theme_font_size_override("font_size", 24)
	current_player_label.add_theme_color_override("font_color", PLAYER1_COLOR)
	hbox.add_child(current_player_label)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(50, 0)
	hbox.add_child(spacer2)
	
	# Timer
	timer_label = Label.new()
	timer_label.text = "⏱ 60s"
	timer_label.add_theme_font_size_override("font_size", 20)
	timer_label.add_theme_color_override("font_color", Color.WHITE)
	hbox.add_child(timer_label)


func _create_bottom_bar() -> void:
	var bottom_bar = PanelContainer.new()
	bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_bar.custom_minimum_size = Vector2(0, 80)
	main_container.add_child(bottom_bar)
	
	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	bottom_bar.add_theme_stylebox_override("panel", style)
	
	action_container = HBoxContainer.new()
	action_container.alignment = BoxContainer.ALIGNMENT_CENTER
	action_container.add_theme_constant_override("separation", 20)
	bottom_bar.add_child(action_container)
	
	# Create action buttons
	move_button = _create_action_button("MOVE", "🚶", Color(0.3, 0.6, 1.0))
	move_button.pressed.connect(func(): action_move_pressed.emit())
	
	attack_button = _create_action_button("ATTACK", "⚔️", Color(1.0, 0.3, 0.3))
	attack_button.pressed.connect(func(): action_attack_pressed.emit())
	
	place_mine_button = _create_action_button("MINE", "⛏️", Color(1.0, 0.8, 0.2))
	place_mine_button.pressed.connect(func(): action_place_mine_pressed.emit())
	
	upgrade_button = _create_action_button("UPGRADE", "⬆️", Color(0.5, 1.0, 0.5))
	upgrade_button.pressed.connect(func(): action_upgrade_pressed.emit())
	
	end_turn_button = _create_action_button("END TURN", "⏭️", Color(0.7, 0.7, 0.7))
	end_turn_button.pressed.connect(func(): action_end_turn_pressed.emit())


func _create_action_button(text: String, icon: String, color: Color) -> Button:
	var button = Button.new()
	button.text = icon + " " + text
	button.custom_minimum_size = Vector2(120, 50)
	button.add_theme_font_size_override("font_size", 16)
	
	# Style
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = color.darkened(0.5)
	normal_style.set_corner_radius_all(8)
	button.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = color.darkened(0.3)
	hover_style.set_corner_radius_all(8)
	button.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = color.darkened(0.6)
	pressed_style.set_corner_radius_all(8)
	button.add_theme_stylebox_override("pressed", pressed_style)
	
	var disabled_style = StyleBoxFlat.new()
	disabled_style.bg_color = Color(0.2, 0.2, 0.2, 0.5)
	disabled_style.set_corner_radius_all(8)
	button.add_theme_stylebox_override("disabled", disabled_style)
	
	action_container.add_child(button)
	return button


func _create_side_panels() -> void:
	# Player 1 panel (left side)
	player1_panel = _create_player_panel("PLAYER 1", PLAYER1_COLOR)
	player1_panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	player1_panel.position = Vector2(10, -75)
	main_container.add_child(player1_panel)
	
	var p1_vbox = player1_panel.get_child(0)
	p1_gold_label = p1_vbox.get_child(1)
	p1_xp_label = p1_vbox.get_child(2)
	
	# Player 2 panel (right side)
	player2_panel = _create_player_panel("PLAYER 2", PLAYER2_COLOR)
	player2_panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	player2_panel.position = Vector2(-160, -75)
	main_container.add_child(player2_panel)
	
	var p2_vbox = player2_panel.get_child(0)
	p2_gold_label = p2_vbox.get_child(1)
	p2_xp_label = p2_vbox.get_child(2)


func _create_player_panel(title: String, color: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(150, 150)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.85)
	style.border_color = color
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	
	# Title
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", color)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	
	# Gold
	var gold_label = Label.new()
	gold_label.text = "💰 150 Gold"
	gold_label.add_theme_font_size_override("font_size", 14)
	gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(gold_label)
	
	# XP
	var xp_label = Label.new()
	xp_label.text = "⭐ 0 XP"
	xp_label.add_theme_font_size_override("font_size", 14)
	xp_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	vbox.add_child(xp_label)
	
	return panel


func _create_info_panel() -> void:
	info_panel = PanelContainer.new()
	info_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	info_panel.position = Vector2(10, 60)
	info_panel.custom_minimum_size = Vector2(300, 0)
	info_panel.visible = false
	main_container.add_child(info_panel)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	style.set_corner_radius_all(8)
	info_panel.add_theme_stylebox_override("panel", style)
	
	info_label = Label.new()
	info_label.text = ""
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.add_theme_color_override("font_color", Color.WHITE)
	info_panel.add_child(info_label)


func _create_selected_troop_panel() -> void:
	selected_troop_panel = PanelContainer.new()
	selected_troop_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	selected_troop_panel.position = Vector2(10, -180)
	selected_troop_panel.custom_minimum_size = Vector2(200, 100)
	selected_troop_panel.visible = false
	main_container.add_child(selected_troop_panel)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	style.border_color = Color(0.5, 0.5, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	selected_troop_panel.add_theme_stylebox_override("panel", style)
	
	selected_troop_label = Label.new()
	selected_troop_label.text = ""
	selected_troop_label.add_theme_font_size_override("font_size", 14)
	selected_troop_label.add_theme_color_override("font_color", Color.WHITE)
	selected_troop_panel.add_child(selected_troop_label)


# =============================================================================
# UPDATE METHODS
# =============================================================================

## Update turn display
func update_turn(turn_number: int, current_player_id: int) -> void:
	turn_label.text = "TURN %d" % turn_number
	
	if current_player_id == 0:
		current_player_label.text = "PLAYER 1's TURN"
		current_player_label.add_theme_color_override("font_color", PLAYER1_COLOR)
	else:
		current_player_label.text = "PLAYER 2's TURN"
		current_player_label.add_theme_color_override("font_color", PLAYER2_COLOR)


## Update timer display
func update_timer(seconds_remaining: float) -> void:
	var mins = int(seconds_remaining) / 60
	var secs = int(seconds_remaining) % 60
	timer_label.text = "⏱ %d:%02d" % [mins, secs]
	
	# Color changes based on time
	if seconds_remaining < 30:
		timer_label.add_theme_color_override("font_color", Color.RED)
	elif seconds_remaining < 60:
		timer_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		timer_label.add_theme_color_override("font_color", Color.WHITE)


## Update player resources
func update_player_resources(player_id: int, gold: int, xp: int) -> void:
	if player_id == 0:
		p1_gold_label.text = "💰 %d Gold" % gold
		p1_xp_label.text = "⭐ %d XP" % xp
	else:
		p2_gold_label.text = "💰 %d Gold" % gold
		p2_xp_label.text = "⭐ %d XP" % xp


## Update action button states
func update_action_buttons(can_move: bool, can_attack: bool, can_place_mine: bool, can_upgrade: bool) -> void:
	move_button.disabled = not can_move
	attack_button.disabled = not can_attack
	place_mine_button.disabled = not can_place_mine
	upgrade_button.disabled = not can_upgrade


## Show info message
func show_info(message: String) -> void:
	info_label.text = message
	info_panel.visible = true


## Hide info message
func hide_info() -> void:
	info_panel.visible = false


## Show selected troop info
func show_selected_troop(troop: Troop) -> void:
	if troop == null:
		selected_troop_panel.visible = false
		return
	
	selected_troop_panel.visible = true
	var info = """
%s (Lv.%d)
HP: %d / %d
ATK: %d | DEF: %d
Range: %d | Speed: %d
""" % [troop.display_name, troop.level, troop.current_hp, troop.max_hp,
       troop.current_atk, troop.current_def, troop.current_range, troop.current_speed]
	selected_troop_label.text = info.strip_edges()


## Hide selected troop info
func hide_selected_troop() -> void:
	selected_troop_panel.visible = false


## Show action mode indicator
func show_action_mode(mode: String) -> void:
	match mode:
		"move":
			show_info("MOVE MODE: Click a highlighted tile to move")
		"attack":
			show_info("ATTACK MODE: Click an enemy to attack")
		"mine":
			show_info("MINE MODE: Click a tile to place a gold mine")
		_:
			hide_info()
