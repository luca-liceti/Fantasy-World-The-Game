## Game UI
## Main in-game UI with action buttons, player info, turn state,
## item inventory, mine count, toast notifications, and keyboard shortcuts overlay
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
var top_bar: PanelContainer
var turn_label: Label
var timer_label: Label
var current_player_label: Label

# Quick action panel (bottom right)
var quick_action_panel: PanelContainer
var action_container: VBoxContainer
var move_button: Button
var attack_button: Button
var place_mine_button: Button
var upgrade_button: Button
var end_turn_button: Button

# Side panels — REMOVED (resources moved to top bar)
# Mine count labels — REMOVED (will be mine cards in hand later)

# Selected troop info
var selected_troop_panel: PanelContainer
var selected_troop_label: Label # Kept for backward compat (name header)
var _troop_hp_bar: ProgressBar
var _troop_hp_label: Label
var _troop_atk_label: Label
var _troop_def_label: Label
var _troop_range_label: Label
var _troop_speed_label: Label

# Troop cards panel (shows current player's troops)
var troop_cards_panel: PanelContainer
var troop_cards_container: Control
var troop_card_buttons: Array[Button] = []
var troop_card_art_rects: Array[TextureRect] = [] # Card art thumbnails in HUD

# Item inventory display
var item_inventory_panel: PanelContainer
var item_slot_labels: Array[Label] = []

# Top bar resource labels
var top_gold_label: Label
var top_xp_label: Label

# Layout Stacks
var _bl_stack: VBoxContainer # Bottom Left stack
var _br_stack: VBoxContainer # Bottom Right stack

# Info panel
var info_panel: PanelContainer
var info_label: Label

# Toast notification system
var toast_container: VBoxContainer
var active_toasts: Array[Control] = []
const MAX_TOASTS: int = 5
const TOAST_DURATION: float = 3.5

# Keyboard shortcuts overlay
var keyboard_overlay: Control = null
var keyboard_overlay_visible: bool = false

# =============================================================================
# COLORS
# =============================================================================
const PLAYER1_COLOR = Color(0.2, 0.5, 1.0) # Blue
const PLAYER2_COLOR = Color(1.0, 0.3, 0.2) # Red
const BUTTON_NORMAL = Color(0.12, 0.11, 0.10) # Neutral dark
const BUTTON_HOVER = Color(0.25, 0.22, 0.18) # Bronze-gray
const BUTTON_DISABLED = Color(0.08, 0.08, 0.08)


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
	
	# Structure containers
	_create_bottom_left_stack()
	_create_bottom_right_stack()
	
	_create_top_bar()
	_create_info_panel()
	_create_selected_troop_panel() # Added to stacks below
	_create_troop_cards_panel()
	_create_quick_action_panel() # Added to stacks below
	_create_item_inventory_panel() # Added to stacks below
	_create_toast_container()


func _create_top_bar() -> void:
	top_bar = PanelContainer.new()
	top_bar.custom_minimum_size = Vector2(0, 50)
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	main_container.add_child(top_bar)
	
	# Style — HUD bar (flush to top, no margins, no rounded corners)
	top_bar.add_theme_stylebox_override("panel", UITheme.hud_bar_style())
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 0)
	top_bar.add_child(hbox)
	
	# LEFT SIDE: Player resources
	var res_hbox = HBoxContainer.new()
	res_hbox.add_theme_constant_override("separation", 16)
	hbox.add_child(res_hbox)
	
	top_gold_label = Label.new()
	top_gold_label.text = "💰 150"
	UITheme.style_label(top_gold_label, 16, UITheme.C_GOLD, true)
	res_hbox.add_child(top_gold_label)
	
	top_xp_label = Label.new()
	top_xp_label.text = "⭐ 0"
	UITheme.style_label(top_xp_label, 16, Color(0.6, 0.8, 1.0), true)
	res_hbox.add_child(top_xp_label)
	
	# Expanding spacer pushes center content to the middle
	var spacer_left = Control.new()
	spacer_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer_left)
	
	# CENTER: Turn + Player
	turn_label = Label.new()
	turn_label.text = "TURN 1"
	UITheme.style_label(turn_label, 20, UITheme.C_WARM_WHITE, true)
	hbox.add_child(turn_label)
	
	var spacer_mid = Control.new()
	spacer_mid.custom_minimum_size = Vector2(24, 0)
	hbox.add_child(spacer_mid)
	
	current_player_label = Label.new()
	current_player_label.text = "PLAYER 1's TURN"
	UITheme.style_label(current_player_label, 24, PLAYER1_COLOR, true)
	hbox.add_child(current_player_label)
	
	# Expanding spacer pushes timer to the right
	var spacer_right = Control.new()
	spacer_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer_right)
	
	# RIGHT SIDE: Timer
	timer_label = Label.new()
	timer_label.text = "⏱ 60s"
	UITheme.style_label(timer_label, 20, UITheme.C_WARM_WHITE)
	hbox.add_child(timer_label)


func _create_quick_action_panel() -> void:
	# Create a floating quick action panel in bottom right corner
	quick_action_panel = PanelContainer.new()
	quick_action_panel.custom_minimum_size = Vector2(130, 260)
	_br_stack.add_child(quick_action_panel)
	
	# Style — UITheme HUD panel with subtle gold border
	quick_action_panel.add_theme_stylebox_override("panel", UITheme.hud_panel(UITheme.C_GOLD.darkened(0.5)))
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 6)
	quick_action_panel.add_child(main_vbox)
	
	# Header
	var header = Label.new()
	header.text = "⚡ ACTIONS"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(header, 12, UITheme.C_GOLD)
	main_vbox.add_child(header)
	
	# Action buttons container
	action_container = VBoxContainer.new()
	action_container.add_theme_constant_override("separation", 6)
	main_vbox.add_child(action_container)
	
	# Create compact action buttons
	move_button = _create_quick_action_button("🚶 Move", "M", Color(0.3, 0.6, 1.0))
	move_button.pressed.connect(func(): action_move_pressed.emit())
	
	attack_button = _create_quick_action_button("⚔️ Attack", "T", Color(1.0, 0.3, 0.3))
	attack_button.pressed.connect(func(): action_attack_pressed.emit())
	
	place_mine_button = _create_quick_action_button("⛏️ Mine", "", Color(1.0, 0.8, 0.2))
	place_mine_button.pressed.connect(func(): action_place_mine_pressed.emit())
	
	upgrade_button = _create_quick_action_button("⬆️ Upgrade", "", Color(0.5, 1.0, 0.5))
	upgrade_button.pressed.connect(func(): action_upgrade_pressed.emit())
	
	# Separator
	var separator = HSeparator.new()
	separator.add_theme_color_override("separator", Color(0.3, 0.3, 0.4, 0.5))
	action_container.add_child(separator)
	
	end_turn_button = _create_quick_action_button("⏭️ End Turn", "Space", Color(0.7, 0.5, 0.3))
	end_turn_button.pressed.connect(func(): action_end_turn_pressed.emit())


func _create_quick_action_button(text: String, hotkey: String, color: Color) -> Button:
	var button = Button.new()
	button.focus_mode = Control.FOCUS_NONE
	if hotkey != "":
		button.text = text + " [" + hotkey + "]"
	else:
		button.text = text
	button.custom_minimum_size = Vector2(110, 36)
	
	# Style — UITheme HUD button with accent colour
	UITheme.apply_hud_button(button, color, 11)
	
	action_container.add_child(button)
	return button


# Side panels removed — resources now in top bar


# _create_player_panel removed — resources now in top bar


func _create_info_panel() -> void:
	info_panel = PanelContainer.new()
	info_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	info_panel.position = Vector2(10, 60)
	info_panel.custom_minimum_size = Vector2(300, 0)
	info_panel.visible = false
	main_container.add_child(info_panel)
	
	info_panel.add_theme_stylebox_override("panel", UITheme.hud_panel())
	
	info_label = Label.new()
	info_label.text = ""
	UITheme.style_label(info_label, 14, UITheme.C_WARM_WHITE)
	info_panel.add_child(info_label)


func _create_selected_troop_panel() -> void:
	selected_troop_panel = PanelContainer.new()
	selected_troop_panel.custom_minimum_size = Vector2(240, 160)
	selected_troop_panel.visible = false
	_bl_stack.add_child(selected_troop_panel)
	
	selected_troop_panel.add_theme_stylebox_override("panel", UITheme.hud_panel())
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	selected_troop_panel.add_child(vbox)
	
	# Name + Level header
	selected_troop_label = Label.new()
	selected_troop_label.text = ""
	selected_troop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	UITheme.style_label(selected_troop_label, 16, UITheme.C_GOLD, true)
	vbox.add_child(selected_troop_label)
	
	# HP Bar — ProgressBar with label overlay
	var hp_container = Control.new()
	hp_container.custom_minimum_size = Vector2(200, 18)
	vbox.add_child(hp_container)
	
	_troop_hp_bar = ProgressBar.new()
	_troop_hp_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	_troop_hp_bar.min_value = 0
	_troop_hp_bar.max_value = 100
	_troop_hp_bar.value = 100
	_troop_hp_bar.show_percentage = false
	# Style the bar background
	var bar_bg_style = StyleBoxFlat.new()
	bar_bg_style.bg_color = Color(0.15, 0.08, 0.08, 0.9)
	bar_bg_style.set_corner_radius_all(4)
	_troop_hp_bar.add_theme_stylebox_override("background", bar_bg_style)
	# Style the bar fill
	var bar_fill_style = StyleBoxFlat.new()
	bar_fill_style.bg_color = Color(0.2, 0.85, 0.3) # Green — will be updated dynamically
	bar_fill_style.set_corner_radius_all(4)
	_troop_hp_bar.add_theme_stylebox_override("fill", bar_fill_style)
	hp_container.add_child(_troop_hp_bar)
	
	# HP label (overlaid on the bar)
	_troop_hp_label = Label.new()
	_troop_hp_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_troop_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_troop_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_troop_hp_label.text = "HP 100 / 100"
	UITheme.style_hud_label(_troop_hp_label, 11, Color.WHITE)
	hp_container.add_child(_troop_hp_label)
	
	# Separator
	var sep = HSeparator.new()
	sep.add_theme_color_override("separator", Color(0.3, 0.3, 0.4, 0.4))
	vbox.add_child(sep)
	
	# Stats grid: 2×2 layout
	var stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 16)
	stats_grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(stats_grid)
	
	_troop_atk_label = _make_stat_label("⚔️ ATK: 0")
	stats_grid.add_child(_troop_atk_label)
	_troop_def_label = _make_stat_label("🛡️ DEF: 0")
	stats_grid.add_child(_troop_def_label)
	_troop_range_label = _make_stat_label("🎯 RNG: 0")
	stats_grid.add_child(_troop_range_label)
	_troop_speed_label = _make_stat_label("👟 SPD: 0")
	stats_grid.add_child(_troop_speed_label)


func _make_stat_label(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.custom_minimum_size = Vector2(90, 0)
	UITheme.style_hud_label(lbl, 12, UITheme.C_WARM_WHITE)
	return lbl


func _create_troop_cards_panel() -> void:
	# Create panel for troop cards at absolute bottom center of screen
	troop_cards_panel = PanelContainer.new()
	troop_cards_panel.custom_minimum_size = Vector2(500, 140)
	troop_cards_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	troop_cards_panel.offset_bottom = -5
	troop_cards_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	troop_cards_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	main_container.add_child(troop_cards_panel)
	
	# Style — Make transparent to remove the black box and gold border
	troop_cards_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	troop_cards_panel.add_child(vbox)
	
	# Header with player-specific color (will be updated dynamically)
	var header = Label.new()
	header.name = "TroopCardHeader"
	header.text = "YOUR TROOPS (Press 1-4)"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(header, 13, UITheme.C_GOLD)
	vbox.add_child(header)
	
	# Card container
	troop_cards_container = Control.new()
	troop_cards_container.custom_minimum_size = Vector2(0, 140)
	troop_cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(troop_cards_container)
	
	# Create 4 card slots
	for i in range(4):
		var card_slot = _create_troop_card_slot(i)
		troop_card_buttons.append(card_slot["button"])
		troop_card_art_rects.append(card_slot["art_rect"])
		troop_cards_container.add_child(card_slot["container"])

	# --- snip: keep existing _create_troop_card_slot below ---


func _create_troop_card_slot(slot_index: int) -> Dictionary:
	# Container panel that holds both the card art and the button
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(110, 110)
	
	# Container style
	var container_style = StyleBoxFlat.new()
	container_style.bg_color = Color(0.05, 0.05, 0.05) # Neutral black
	container_style.border_color = UITheme.C_GOLD.darkened(0.5)
	container_style.set_border_width_all(2)
	container_style.set_corner_radius_all(8)
	container_style.set_content_margin_all(4)
	container.add_theme_stylebox_override("panel", container_style)
	
	# VBox inside: card art on top, button text below
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	container.add_child(vbox)
	
	# Card art thumbnail (small portrait)
	var art_rect = TextureRect.new()
	art_rect.custom_minimum_size = Vector2(106, 50)
	art_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(art_rect)
	
	# Button for interaction and stats display
	var button = Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(106, 55)
	button.clip_text = true
	
	# Default style
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.12, 0.12, 0.16, 0.0) # Transparent
	normal_style.border_color = Color(0.0, 0.0, 0.0, 0.0)
	normal_style.set_border_width_all(0)
	normal_style.set_corner_radius_all(0)
	button.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.18, 0.18, 0.24, 0.5)
	hover_style.border_color = Color(0.5, 0.5, 0.6, 0.0)
	hover_style.set_border_width_all(0)
	hover_style.set_corner_radius_all(0)
	button.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.2, 0.25, 0.35, 0.5)
	pressed_style.border_color = Color(0.6, 0.7, 1.0, 0.0)
	pressed_style.set_border_width_all(0)
	pressed_style.set_corner_radius_all(0)
	button.add_theme_stylebox_override("pressed", pressed_style)
	
	var focus_style = StyleBoxFlat.new()
	focus_style.bg_color = Color(0.2, 0.25, 0.35, 0.0)
	focus_style.border_color = Color(0.0, 0.0, 0.0, 0.0)
	focus_style.set_border_width_all(0)
	focus_style.set_corner_radius_all(0)
	button.add_theme_stylebox_override("focus", focus_style)
	
	var disabled_style = StyleBoxFlat.new()
	disabled_style.bg_color = Color(0.1, 0.1, 0.1, 0.3)
	disabled_style.border_color = Color(0.0, 0.0, 0.0, 0.0)
	disabled_style.set_border_width_all(0)
	disabled_style.set_corner_radius_all(0)
	button.add_theme_stylebox_override("disabled", disabled_style)
	
	UITheme.style_button_text(button, 10, UITheme.C_GOLD)
	
	vbox.add_child(button)
	
	# Connect signal
	button.pressed.connect(_on_troop_card_pressed.bind(slot_index))
	
	return {"container": container, "button": button, "art_rect": art_rect}


func _on_troop_card_pressed(slot_index: int) -> void:
	troop_slot_selected.emit(slot_index)


func _tween_card(card: Control, target_pos: Vector2, target_rot: float, target_scale: float, duration: float) -> void:
	var tween = card.get_meta("tween", null) as Tween
	if tween and tween.is_valid():
		tween.kill()
		
	tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	card.set_meta("tween", tween)
	card.pivot_offset = Vector2(card.size.x / 2.0, card.size.y)
	
	tween.tween_property(card, "position", target_pos, duration)
	tween.tween_property(card, "rotation", target_rot, duration)
	tween.tween_property(card, "scale", Vector2(target_scale, target_scale), duration)


func _layout_hand() -> void:
	var visible_cards = []
	for child in troop_cards_container.get_children():
		if child.visible:
			visible_cards.append(child)
			
	var count = visible_cards.size()
	if count == 0: return
	
	# We rely on the container size. If it's 0 (like on first frame), fallback to parent panel size.
	var c_width = troop_cards_container.size.x
	if c_width <= 0: c_width = 500.0
	
	var container_center = c_width / 2.0
	var card_overlap_width = 80.0
	var max_angle = 6.0
	var base_y = 5.0
	
	var total_width = (count - 1) * card_overlap_width + 110.0 # 110 is card width
	var start_x = container_center - (total_width / 2.0) + (110.0 / 2.0)
	
	for i in range(count):
		var card = visible_cards[i]
		var t = 0.0
		if count > 1:
			t = float(i) / float(count - 1)
			
		var normalized_pos = (t * 2.0) - 1.0
		var angle_deg = normalized_pos * max_angle
		var y_offset = base_y + (normalized_pos * normalized_pos) * 10.0
		
		# start_x is the center of the first card, so we subtract half card width to get standard pos
		var target_x = start_x + (i * card_overlap_width) - (110.0 / 2.0)
		var target_pos = Vector2(target_x, y_offset)
		
		var is_selected = card.get_meta("is_selected") if card.has_meta("is_selected") else false
		
		if is_selected:
			card.z_index = 100
			var popup_pos = target_pos + Vector2(0, -10)
			_tween_card(card, popup_pos, deg_to_rad(angle_deg) * 0.5, 1.05, 0.15)
		else:
			card.z_index = i
			_tween_card(card, target_pos, deg_to_rad(angle_deg), 1.0, 0.3)


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


# Prevent expensive style invalidation by tracking current state
var _last_timer_color: Color = Color.TRANSPARENT
var _last_timer_text: String = ""

## Update timer display
func update_timer(seconds_remaining: float) -> void:
	var mins = int(seconds_remaining / 60.0)
	var secs = int(seconds_remaining) % 60
	var new_text = "⏱ %d:%02d" % [mins, secs]
	
	if new_text != _last_timer_text:
		timer_label.text = new_text
		_last_timer_text = new_text
	
	# Color changes based on time
	var target_color: Color
	if seconds_remaining < 30:
		target_color = Color.RED
	elif seconds_remaining < 60:
		target_color = Color.YELLOW
	else:
		target_color = Color.WHITE
		
	if target_color != _last_timer_color:
		timer_label.add_theme_color_override("font_color", target_color)
		_last_timer_color = target_color


## Update player resources (shown in top bar for the active player)
func update_player_resources(player_id: int, gold: int, xp: int) -> void:
	# Only update top bar for the active player
	var active_id = 0
	if get_parent() and get_parent().get_parent(): # walk up to main
		var main_node = get_parent().get_parent()
		if main_node.has_method("get") and main_node.game_manager and main_node.game_manager.turn_manager:
			active_id = main_node.game_manager.turn_manager.get_active_player_id()
	if player_id == active_id:
		top_gold_label.text = "💰 %d" % gold
		top_xp_label.text = "⭐ %d" % xp


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


## Show selected troop or mine info with visual stats
func show_selected_troop(entity: Node) -> void:
	if entity == null:
		selected_troop_panel.visible = false
		return
	
	selected_troop_panel.visible = true
	
	if entity is Troop:
		# Name + Level header
		selected_troop_label.text = "%s  Lv.%d" % [entity.display_name, entity.level]
		
		# HP bar
		var hp_pct = (float(entity.current_hp) / float(entity.max_hp)) * 100.0 if entity.max_hp > 0 else 0.0
		_troop_hp_bar.value = hp_pct
		_troop_hp_label.text = "HP  %d / %d" % [entity.current_hp, entity.max_hp]
		
		# Dynamic bar color: green → yellow → red
		var bar_color: Color
		if hp_pct > 60.0:
			bar_color = Color(0.2, 0.85, 0.3) # Green
		elif hp_pct > 30.0:
			bar_color = Color(0.9, 0.75, 0.15) # Yellow
		else:
			bar_color = Color(0.9, 0.2, 0.15) # Red
		
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = bar_color
		fill_style.set_corner_radius_all(4)
		_troop_hp_bar.add_theme_stylebox_override("fill", fill_style)
		
		# Stat labels
		_troop_atk_label.text = "⚔️ ATK: %d" % entity.current_atk
		_troop_def_label.text = "🛡️ DEF: %d" % entity.current_def
		_troop_range_label.text = "🎯 RNG: %d" % entity.current_range
		_troop_speed_label.text = "👟 SPD: %d" % entity.current_speed
	elif "card_id" in entity and entity.card_id.begins_with("mine_"):
		# Name + Level header
		selected_troop_label.text = "Gold Mine  Lv.%d" % entity.level
		
		# Simulated 'HP' bar (full gold color)
		_troop_hp_bar.value = 100
		_troop_hp_label.text = "Active Generation"
		
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = Color(1.0, 0.84, 0.0)
		fill_style.set_corner_radius_all(4)
		_troop_hp_bar.add_theme_stylebox_override("fill", fill_style)
		
		# Mine specific stats
		_troop_atk_label.text = "💰 +%d /turn" % entity.get_gold_per_turn()
		var cost = GameConfig.MINE_UPGRADE_COSTS.get(entity.level + 1, 0)
		if entity.level < 5:
			_troop_def_label.text = "⬆️ Gold: %d" % cost
			_troop_range_label.text = "⬆️ XP: 0"
		else:
			_troop_def_label.text = "⬆️ MAX"
			_troop_range_label.text = "⬆️ MAX"
		_troop_speed_label.text = ""


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


## Update troop cards display
func update_troop_cards(player: Player, selected_troop: Node = null) -> void:
	if not player:
		return
	
	# Ensure UI has enough slots
	while troop_card_buttons.size() < player.deck.size():
		var slot_index = troop_card_buttons.size()
		var card_slot = _create_troop_card_slot(slot_index)
		troop_card_buttons.append(card_slot["button"])
		troop_card_art_rects.append(card_slot["art_rect"])
		troop_cards_container.add_child(card_slot["container"])
	
	for i in range(troop_card_buttons.size()):
		var button = troop_card_buttons[i]
		var art_rect = troop_card_art_rects[i]
		var container = troop_cards_container.get_child(i)
		
		# Check if there's an entity for this slot
		if i < player.deck.size():
			container.visible = true
			var entity_id = player.deck[i]
			var is_mine = entity_id.begins_with("mine_")
			var entity = null
			
			if is_mine:
				entity = _find_mine_by_id(player, entity_id)
				var level = 1
				if entity:
					level = entity.level
				var mine_art_path = "res://assets/textures/cards/mine_pics/gold_mine_lvl_%d.png" % clamp(level, 1, 5)
				art_rect.texture = load(mine_art_path) as Texture2D
				art_rect.visible = true
				
				if entity and entity.is_active:
					# Mine is alive
					button.disabled = false
					button.text = "[%d] Gold Mine\nLv.%d  +💰%d" % [i + 1, entity.level, entity.get_gold_per_turn()]
					button.add_theme_font_size_override("font_size", 10)
					
					# Highlight if selected
					if entity == selected_troop:
						_highlight_troop_card(button, true, player.team_color, i)
					else:
						_highlight_troop_card(button, false, player.team_color, i)
				else:
					# Mine is destroyed
					button.disabled = true
					button.text = "[%d] Gold Mine\n💀 DESTROYED" % (i + 1)
					button.add_theme_font_size_override("font_size", 10)
					_highlight_troop_card(button, false, Color.GRAY, i)
					# Dim the card art for destroyed mines
					art_rect.modulate = Color(0.3, 0.3, 0.3)
			else:
				entity = _find_troop_by_id(player, entity_id)
				
				# Load card art for this troop
				var card_art = CharacterModelLoader.load_card_art(entity_id)
				if card_art:
					art_rect.texture = card_art
					art_rect.visible = true
				else:
					art_rect.visible = false
				
				if entity and entity.is_alive:
					# Troop is alive - show info
					button.disabled = false
					button.text = "[%d] %s\n❤️ %d/%d" % [i + 1, entity.display_name, entity.current_hp, entity.max_hp]
					button.add_theme_font_size_override("font_size", 10)
					
					# Highlight if selected
					if entity == selected_troop:
						_highlight_troop_card(button, true, player.team_color, i)
					else:
						_highlight_troop_card(button, false, player.team_color, i)
					
					# Show status indicators
					if entity.has_moved_this_turn or entity.has_attacked_this_turn:
						button.text += "\n✓ Done"
				else:
					# Troop is dead
					button.disabled = true
					var card_data = CardData.get_troop(entity_id)
					var dead_name = card_data.get("name", entity_id) if not card_data.is_empty() else entity_id
					button.text = "[%d] %s\n💀 DEAD" % [i + 1, dead_name]
					button.add_theme_font_size_override("font_size", 10)
					_highlight_troop_card(button, false, Color.GRAY, i)
					# Dim the card art for dead troops
					art_rect.modulate = Color(0.3, 0.3, 0.3)
		else:
			# No troop at this slot
			container.visible = false
			button.disabled = true
			button.text = "[%d]\nEmpty" % (i + 1)
			art_rect.visible = false
			_highlight_troop_card(button, false, Color.GRAY, i)
	
	_layout_hand()


func _find_troop_by_id(player: Player, troop_id: String) -> Troop:
	for troop in player.troops:
		if troop and troop.troop_id == troop_id:
			return troop
	return null


func _find_mine_by_id(player: Player, mine_id: String) -> GoldMine:
	for mine in player.gold_mines:
		if mine and mine.card_id == mine_id:
			return mine
	return null


func _highlight_troop_card(_button: Button, is_selected: bool, team_color: Color, slot_index: int = -1) -> void:
	# Update the parent container's border to show selection state
	var container: PanelContainer = null
	if slot_index >= 0 and slot_index < troop_cards_container.get_child_count():
		container = troop_cards_container.get_child(slot_index) as PanelContainer
	
	if container:
		container.set_meta("is_selected", is_selected)
		var container_style = StyleBoxFlat.new()
		if is_selected:
			container_style.bg_color = team_color.darkened(0.6)
			container_style.border_color = UITheme.C_GOLD_BRIGHT
			container_style.set_border_width_all(3)
		else:
			container_style.bg_color = Color(0.05, 0.05, 0.05)
			container_style.border_color = UITheme.C_GOLD.darkened(0.3)
			container_style.set_border_width_all(2)
		container_style.set_corner_radius_all(8)
		container_style.set_content_margin_all(4)
		container.add_theme_stylebox_override("panel", container_style)
	
	# Also reset the card art modulate for living troops
	if slot_index >= 0 and slot_index < troop_card_art_rects.size():
		var art_rect = troop_card_art_rects[slot_index]
		if team_color != Color.GRAY:
			art_rect.modulate = Color.WHITE # Full color for alive troops


# =============================================================================
# ITEM INVENTORY DISPLAY
# =============================================================================

func _create_item_inventory_panel() -> void:
	item_inventory_panel = PanelContainer.new()
	item_inventory_panel.custom_minimum_size = Vector2(240, 75)
	_bl_stack.add_child(item_inventory_panel)
	
	item_inventory_panel.add_theme_stylebox_override("panel", UITheme.hud_panel(Color(0.5, 0.7, 0.4, 0.7)))
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	item_inventory_panel.add_child(vbox)
	
	# Header
	var header = Label.new()
	header.text = "🎒 ITEMS (0/3)"
	header.name = "ItemHeader"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(header, 11, Color(0.5, 0.7, 0.4))
	vbox.add_child(header)
	
	# Item slots row
	var slots_row = HBoxContainer.new()
	slots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	slots_row.add_theme_constant_override("separation", 6)
	vbox.add_child(slots_row)
	
	for i in range(3):
		var slot_panel = PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(58, 32)
		
		var slot_style = StyleBoxFlat.new()
		slot_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
		slot_style.border_color = Color(0.3, 0.3, 0.4, 0.5)
		slot_style.set_border_width_all(1)
		slot_style.set_corner_radius_all(4)
		slot_panel.add_theme_stylebox_override("panel", slot_style)
		
		var slot_label = Label.new()
		slot_label.text = "Empty"
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UITheme.style_label(slot_label, 9, Color(0.4, 0.4, 0.5))
		slot_panel.add_child(slot_label)
		
		slots_row.add_child(slot_panel)
		item_slot_labels.append(slot_label)


## Update item inventory display
func update_item_inventory(items: Array) -> void:
	# Update header count
	var header = item_inventory_panel.get_child(0).get_child(0) # VBox -> Header label
	header.text = "🎒 ITEMS (%d/3)" % items.size()
	
	for i in range(3):
		if i < items.size() and items[i] != "":
			var item_name = items[i]
			match item_name:
				"speed_potion":
					item_slot_labels[i].text = "🧴 Spd"
					item_slot_labels[i].add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
				"whetstone":
					item_slot_labels[i].text = "🗡️ Whet"
					item_slot_labels[i].add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
				"phoenix_feather":
					item_slot_labels[i].text = "🪶 Phnx"
					item_slot_labels[i].add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
				_:
					item_slot_labels[i].text = item_name.substr(0, 4)
					item_slot_labels[i].add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
		else:
			item_slot_labels[i].text = "Empty"
			item_slot_labels[i].add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))


# =============================================================================
# MINE COUNT
# =============================================================================

## Update mine count for a player (no-op — mine cards feature pending)
func update_mine_count(_player_id: int, _mine_count: int) -> void:
	pass # Will be replaced by mine cards in the troop hand


# =============================================================================
# TOAST NOTIFICATION SYSTEM
# =============================================================================

func _create_toast_container() -> void:
	toast_container = VBoxContainer.new()
	toast_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	toast_container.position = Vector2(-320, 60)
	toast_container.custom_minimum_size = Vector2(300, 0)
	toast_container.add_theme_constant_override("separation", 6)
	toast_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_container.add_child(toast_container)


## Show a toast notification
func show_toast(message: String, color: Color = Color(0.3, 0.6, 1.0), duration: float = TOAST_DURATION) -> void:
	# Remove oldest if at max
	if active_toasts.size() >= MAX_TOASTS:
		var oldest = active_toasts.pop_front()
		if oldest and is_instance_valid(oldest):
			oldest.queue_free()
	
	# Create toast panel
	var toast = PanelContainer.new()
	toast.custom_minimum_size = Vector2(300, 36)
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.92)
	style.border_color = color.darkened(0.2)
	style.set_border_width_all(1)
	style.border_width_left = 4 # Accent bar on left side
	style.border_color = color
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	toast.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.style_label(label, 13, Color(0.9, 0.9, 0.95))
	toast.add_child(label)
	
	toast_container.add_child(toast)
	active_toasts.append(toast)
	
	# Slide in animation
	toast.modulate.a = 0
	toast.position.x = 50
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(toast, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(toast, "position:x", 0.0, 0.3)
	
	# Auto-dismiss after duration
	tween.tween_interval(duration)
	tween.tween_property(toast, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func():
		active_toasts.erase(toast)
		toast.queue_free()
	)


## Convenience toast methods
func show_toast_mine(message: String) -> void:
	show_toast(message, Color(1.0, 0.85, 0.3))

func show_toast_combat(message: String) -> void:
	show_toast(message, Color(1.0, 0.3, 0.3))

func show_toast_item(message: String) -> void:
	show_toast(message, Color(0.3, 0.8, 0.5))

func show_toast_npc(message: String) -> void:
	show_toast(message, Color(0.8, 0.5, 0.9))

func show_toast_warning(message: String) -> void:
	show_toast(message, Color(0.9, 0.6, 0.2))

func show_toast_error(message: String) -> void:
	show_toast(message, Color(0.9, 0.2, 0.2))


# =============================================================================
# KEYBOARD SHORTCUTS OVERLAY (F1)
# =============================================================================

func toggle_keyboard_overlay() -> void:
	if keyboard_overlay_visible:
		_hide_keyboard_overlay()
	else:
		_show_keyboard_overlay()


func _show_keyboard_overlay() -> void:
	if keyboard_overlay != null:
		return
	
	keyboard_overlay_visible = true
	keyboard_overlay = Control.new()
	keyboard_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	keyboard_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_container.add_child(keyboard_overlay)
	
	# Semi-transparent panel at center
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(400, 340)
	panel.position = Vector2(-200, -170)
	keyboard_overlay.add_child(panel)
	
	panel.add_theme_stylebox_override("panel", UITheme.overlay_panel(Color(0.4, 0.6, 1.0)))
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "🎮  KEYBOARD SHORTCUTS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(title, 18, UITheme.C_GOLD, true)
	vbox.add_child(title)
	
	var sep = UITheme.make_separator()
	vbox.add_child(sep)
	
	# Shortcut entries
	var shortcuts = [
		["WASD", "Camera Pan"],
		["Q / E", "Camera Rotate"],
		["Scroll", "Zoom In/Out"],
		["1-4", "Select Troop"],
		["M", "Move Mode"],
		["T", "Attack Mode"],
		["Space", "End Turn"],
		["Esc", "Pause Menu"],
		["F1", "Toggle This Overlay"]
	]
	
	for entry in shortcuts:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		
		# Key badge
		var key_lbl = Label.new()
		key_lbl.text = entry[0]
		key_lbl.custom_minimum_size = Vector2(80, 0)
		key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		UITheme.style_label(key_lbl, 13, UITheme.C_GOLD)
		row.add_child(key_lbl)
		
		# Separator dot
		var dot = Label.new()
		dot.text = "•"
		UITheme.style_label(dot, 13, UITheme.C_DIM)
		row.add_child(dot)
		
		# Action
		var action_lbl = Label.new()
		action_lbl.text = entry[1]
		UITheme.style_label(action_lbl, 13, UITheme.C_WARM_WHITE)
		row.add_child(action_lbl)
		
		vbox.add_child(row)
	
	# Footer hint
	var hint = Label.new()
	hint.text = "Press F1 to close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	vbox.add_child(hint)
	
	# Animate in
	panel.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)


func _hide_keyboard_overlay() -> void:
	keyboard_overlay_visible = false
	if keyboard_overlay and is_instance_valid(keyboard_overlay):
		var tween = create_tween()
		tween.tween_property(keyboard_overlay, "modulate:a", 0.0, 0.15)
		tween.tween_callback(func():
			if keyboard_overlay:
				keyboard_overlay.queue_free()
				keyboard_overlay = null
		)

# =============================================================================
# LAYOUT HELPERS
# =============================================================================

func _create_bottom_left_stack() -> void:
	_bl_stack = VBoxContainer.new()
	_bl_stack.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_bl_stack.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_bl_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bl_stack.add_theme_constant_override("separation", 0) # No space between components
	main_container.add_child(_bl_stack)

func _create_bottom_right_stack() -> void:
	_br_stack = VBoxContainer.new()
	_br_stack.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_br_stack.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_br_stack.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_br_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_br_stack.add_theme_constant_override("separation", 0)
	main_container.add_child(_br_stack)
