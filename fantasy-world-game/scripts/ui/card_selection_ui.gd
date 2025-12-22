## Card Selection UI
## Pre-game deck builder for selecting 4 cards
## Enforces deck-building rules: 1 Ground Tank, 1 Air/Hybrid, 1 Ranged/Magic, 1 Flex
class_name CardSelectionUI
extends CanvasLayer

# =============================================================================
# SIGNALS
# =============================================================================
signal deck_confirmed(deck: Array[String])
signal selection_canceled()

# =============================================================================
# CONSTANTS
# =============================================================================
const MAX_DECK_SIZE: int = 4
const MAX_MANA_COST: int = 22
const SELECTION_TIME: float = 30.0 # 30 seconds to select

# Role slot indices
enum RoleSlot {GROUND_TANK = 0, AIR_HYBRID = 1, RANGED_MAGIC = 2, FLEX = 3}

# =============================================================================
# COLORS
# =============================================================================
const COLOR_GROUND_TANK = Color(0.7, 0.5, 0.3) # Brown/Bronze
const COLOR_AIR_HYBRID = Color(0.4, 0.7, 0.9) # Sky Blue
const COLOR_RANGED_MAGIC = Color(0.6, 0.3, 0.8) # Purple
const COLOR_FLEX = Color(0.4, 0.8, 0.4) # Green

const COLOR_BG = Color(0.05, 0.05, 0.1, 0.98)
const COLOR_SELECTED = Color(1.0, 0.84, 0.0)
const COLOR_VALID = Color(0.3, 0.9, 0.3)
const COLOR_INVALID = Color(0.9, 0.3, 0.3)

# =============================================================================
# UI ELEMENTS
# =============================================================================
var root_control: Control
var overlay: ColorRect
var main_panel: PanelContainer
var title_label: Label
var timer_label: Label
var mana_label: Label

# Card grid (4 columns for 4 roles)
var card_columns: Array[VBoxContainer] = []
var card_buttons: Dictionary = {} # card_id -> Button

# Selected deck display
var deck_slots: Array[PanelContainer] = []
var deck_slot_labels: Array[Label] = []

# Confirm button
var confirm_button: Button

# Timer
var selection_timer: Timer
var time_remaining: float = SELECTION_TIME

# State
var selected_deck: Array[String] = ["", "", "", ""] # One slot per role
var player_id: int = 0
var is_visible_ui: bool = false
var current_tween: Tween = null

# =============================================================================
# CARD DATA (organized by role)
# =============================================================================
const GROUND_TANK_CARDS = ["medieval_knight", "stone_giant", "four_headed_hydra"]
const AIR_HYBRID_CARDS = ["dark_blood_dragon", "sky_serpent", "frost_valkyrie"]
const RANGED_MAGIC_CARDS = ["dark_magic_wizard", "demon_of_darkness", "elven_archer"]
const FLEX_CARDS = ["celestial_cleric", "shadow_assassin", "infernal_soul"]


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	layer = 100
	_create_ui()
	# Hide initially - directly set visibility without tween
	if root_control:
		root_control.visible = false
	print("CardSelectionUI ready, root_control created: %s" % (root_control != null))


func _create_ui() -> void:
	# Root control that fills the viewport
	root_control = Control.new()
	root_control.name = "RootControl"
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	
	# Dark overlay
	overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(overlay)
	
	# Main panel
	main_panel = PanelContainer.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.offset_left = 50
	main_panel.offset_right = -50
	main_panel.offset_top = 50
	main_panel.offset_bottom = -50
	root_control.add_child(main_panel)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = COLOR_BG
	panel_style.border_color = Color(0.6, 0.5, 0.3)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(15)
	main_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Main layout
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	main_panel.add_child(margin)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 20)
	margin.add_child(main_vbox)
	
	_create_header(main_vbox)
	_create_card_grid(main_vbox)
	_create_deck_display(main_vbox)
	_create_footer(main_vbox)
	
	# Create timer
	selection_timer = Timer.new()
	selection_timer.one_shot = false
	selection_timer.timeout.connect(_on_timer_tick)
	add_child(selection_timer)


func _create_header(parent: VBoxContainer) -> void:
	var header_box = HBoxContainer.new()
	header_box.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(header_box)
	
	# Title
	title_label = Label.new()
	title_label.text = "⚔️ SELECT YOUR DECK ⚔️"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_box.add_child(title_label)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_box.add_child(spacer)
	
	# Timer
	timer_label = Label.new()
	timer_label.text = "⏱ 30s"
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	timer_label.add_theme_font_size_override("font_size", 24)
	timer_label.add_theme_color_override("font_color", Color.YELLOW)
	header_box.add_child(timer_label)
	
	# Instructions
	var instructions = Label.new()
	instructions.text = "Pick 1 card from each role. Your deck must cost ≤ 22 mana total."
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.add_theme_font_size_override("font_size", 16)
	instructions.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	parent.add_child(instructions)


func _create_card_grid(parent: VBoxContainer) -> void:
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	
	var grid = HBoxContainer.new()
	grid.add_theme_constant_override("separation", 30)
	grid.alignment = BoxContainer.ALIGNMENT_CENTER
	scroll.add_child(grid)
	
	# Create 4 columns for 4 roles
	var role_data = [
		{"name": "GROUND TANK", "color": COLOR_GROUND_TANK, "cards": GROUND_TANK_CARDS, "icon": "🛡️"},
		{"name": "AIR/HYBRID", "color": COLOR_AIR_HYBRID, "cards": AIR_HYBRID_CARDS, "icon": "🐲"},
		{"name": "RANGED/MAGIC", "color": COLOR_RANGED_MAGIC, "cards": RANGED_MAGIC_CARDS, "icon": "✨"},
		{"name": "FLEX/SUPPORT", "color": COLOR_FLEX, "cards": FLEX_CARDS, "icon": "⚡"}
	]
	
	for i in range(4):
		var column = _create_role_column(role_data[i], i)
		card_columns.append(column)
		grid.add_child(column)


func _create_role_column(role_info: Dictionary, slot_index: int) -> VBoxContainer:
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.custom_minimum_size = Vector2(250, 0)
	
	# Role header
	var header_panel = PanelContainer.new()
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = role_info["color"].darkened(0.5)
	header_style.border_color = role_info["color"]
	header_style.set_border_width_all(2)
	header_style.set_corner_radius_all(8)
	header_panel.add_theme_stylebox_override("panel", header_style)
	column.add_child(header_panel)
	
	var header_label = Label.new()
	header_label.text = "%s %s" % [role_info["icon"], role_info["name"]]
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_label.add_theme_font_size_override("font_size", 18)
	header_label.add_theme_color_override("font_color", role_info["color"])
	var header_margin = MarginContainer.new()
	header_margin.add_theme_constant_override("margin_top", 8)
	header_margin.add_theme_constant_override("margin_bottom", 8)
	header_margin.add_child(header_label)
	header_panel.add_child(header_margin)
	
	# Cards in this role
	for card_id in role_info["cards"]:
		var card_button = _create_card_button(card_id, role_info["color"], slot_index)
		column.add_child(card_button)
		card_buttons[card_id] = card_button
	
	return column


func _create_card_button(card_id: String, role_color: Color, slot_index: int) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(240, 120)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	# Get card data
	var card_data = CardData.get_troop(card_id)
	var display_name = card_data.get("display_name", card_id.replace("_", " ").capitalize())
	var mana_cost = card_data.get("mana_cost", 5)
	var hp = card_data.get("hp", 100)
	var atk = card_data.get("atk", 50)
	var def = card_data.get("def", 50)
	var range_val = card_data.get("range", 1)
	var speed = card_data.get("speed", 2)
	var ability = card_data.get("ability_description", "")
	
	# Button text
	var text = "%s\n" % display_name
	text += "💎 %d Mana\n" % mana_cost
	text += "❤️ %d  ⚔️ %d  🛡️ %d  📍 %d  🏃 %d\n" % [hp, atk, def, range_val, speed]
	if ability:
		text += "✨ %s" % ability
	
	button.text = text
	button.add_theme_font_size_override("font_size", 12)
	
	# Style
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.1, 0.1, 0.15)
	normal_style.border_color = role_color.darkened(0.3)
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(8)
	button.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.15, 0.15, 0.2)
	hover_style.border_color = role_color
	hover_style.set_border_width_all(3)
	hover_style.set_corner_radius_all(8)
	button.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = role_color.darkened(0.6)
	pressed_style.border_color = COLOR_SELECTED
	pressed_style.set_border_width_all(3)
	pressed_style.set_corner_radius_all(8)
	button.add_theme_stylebox_override("pressed", pressed_style)
	
	# Connect signal
	button.pressed.connect(_on_card_selected.bind(card_id, slot_index))
	
	return button


func _create_deck_display(parent: VBoxContainer) -> void:
	var deck_container = HBoxContainer.new()
	deck_container.alignment = BoxContainer.ALIGNMENT_CENTER
	deck_container.add_theme_constant_override("separation", 20)
	parent.add_child(deck_container)
	
	var deck_label = Label.new()
	deck_label.text = "YOUR DECK: "
	deck_label.add_theme_font_size_override("font_size", 18)
	deck_label.add_theme_color_override("font_color", Color.WHITE)
	deck_container.add_child(deck_label)
	
	var role_colors = [COLOR_GROUND_TANK, COLOR_AIR_HYBRID, COLOR_RANGED_MAGIC, COLOR_FLEX]
	
	for i in range(4):
		var slot = PanelContainer.new()
		slot.custom_minimum_size = Vector2(150, 50)
		
		var slot_style = StyleBoxFlat.new()
		slot_style.bg_color = Color(0.15, 0.15, 0.2)
		slot_style.border_color = role_colors[i].darkened(0.3)
		slot_style.set_border_width_all(2)
		slot_style.set_corner_radius_all(6)
		slot.add_theme_stylebox_override("panel", slot_style)
		
		var slot_label = Label.new()
		slot_label.text = "Empty"
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_label.add_theme_font_size_override("font_size", 14)
		slot_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		
		var slot_margin = MarginContainer.new()
		slot_margin.add_theme_constant_override("margin_left", 10)
		slot_margin.add_theme_constant_override("margin_right", 10)
		slot_margin.add_child(slot_label)
		slot.add_child(slot_margin)
		
		deck_container.add_child(slot)
		deck_slots.append(slot)
		deck_slot_labels.append(slot_label)
	
	# Mana total
	mana_label = Label.new()
	mana_label.text = "  💎 0 / 22 Mana"
	mana_label.add_theme_font_size_override("font_size", 18)
	mana_label.add_theme_color_override("font_color", COLOR_VALID)
	deck_container.add_child(mana_label)


func _create_footer(parent: VBoxContainer) -> void:
	var footer = HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 30)
	parent.add_child(footer)
	
	# Cancel button
	var cancel_button = Button.new()
	cancel_button.text = "❌ CANCEL"
	cancel_button.custom_minimum_size = Vector2(150, 50)
	cancel_button.add_theme_font_size_override("font_size", 18)
	
	var cancel_style = StyleBoxFlat.new()
	cancel_style.bg_color = COLOR_INVALID.darkened(0.5)
	cancel_style.border_color = COLOR_INVALID
	cancel_style.set_border_width_all(2)
	cancel_style.set_corner_radius_all(8)
	cancel_button.add_theme_stylebox_override("normal", cancel_style)
	cancel_button.pressed.connect(_on_cancel_pressed)
	footer.add_child(cancel_button)
	
	# Confirm button
	confirm_button = Button.new()
	confirm_button.text = "✅ CONFIRM DECK"
	confirm_button.custom_minimum_size = Vector2(200, 50)
	confirm_button.add_theme_font_size_override("font_size", 18)
	confirm_button.disabled = true
	
	var confirm_style = StyleBoxFlat.new()
	confirm_style.bg_color = COLOR_VALID.darkened(0.5)
	confirm_style.border_color = COLOR_VALID
	confirm_style.set_border_width_all(2)
	confirm_style.set_corner_radius_all(8)
	confirm_button.add_theme_stylebox_override("normal", confirm_style)
	
	var confirm_disabled = StyleBoxFlat.new()
	confirm_disabled.bg_color = Color(0.2, 0.2, 0.2)
	confirm_disabled.border_color = Color(0.4, 0.4, 0.4)
	confirm_disabled.set_border_width_all(2)
	confirm_disabled.set_corner_radius_all(8)
	confirm_button.add_theme_stylebox_override("disabled", confirm_disabled)
	
	confirm_button.pressed.connect(_on_confirm_pressed)
	footer.add_child(confirm_button)


# =============================================================================
# PUBLIC METHODS
# =============================================================================

## Show the card selection UI
func show_selection(for_player_id: int = 0, timer_enabled: bool = true) -> void:
	print("CardSelectionUI.show_selection called for player %d" % for_player_id)
	print("  root_control exists: %s" % (root_control != null))
	print("  main_panel exists: %s" % (main_panel != null))
	
	# Kill any existing tween to prevent conflicts
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		current_tween = null
	
	player_id = for_player_id
	selected_deck = ["", "", "", ""]
	is_visible_ui = true
	
	# Update title to show which player is selecting
	var player_color = Color(0.2, 0.5, 1.0) if player_id == 0 else Color(1.0, 0.3, 0.2)
	var player_name = "PLAYER 1" if player_id == 0 else "PLAYER 2"
	title_label.text = "⚔️ %s - SELECT YOUR DECK ⚔️" % player_name
	title_label.add_theme_color_override("font_color", player_color)
	
	# Reset UI state
	_update_deck_display()
	_update_card_highlights()
	
	if timer_enabled:
		time_remaining = SELECTION_TIME
		timer_label.text = "⏱ %ds" % int(time_remaining)
		timer_label.visible = true
		timer_label.add_theme_color_override("font_color", Color.YELLOW) # Reset timer color
		selection_timer.start(1.0)
	else:
		timer_label.visible = false
	
	# Show the root control (which contains overlay and main panel)
	if root_control:
		root_control.visible = true
	
	# Reset panel state before animation
	main_panel.modulate.a = 0
	main_panel.scale = Vector2(0.9, 0.9)
	main_panel.pivot_offset = main_panel.size / 2
	
	# Animate entrance
	current_tween = create_tween()
	current_tween.set_parallel(true)
	current_tween.tween_property(main_panel, "modulate:a", 1.0, 0.3)
	current_tween.tween_property(main_panel, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


## Hide the card selection UI
func hide_selection() -> void:
	is_visible_ui = false
	
	if selection_timer:
		selection_timer.stop()
	
	# Kill any existing tween first
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	
	# Simply hide the root control
	if root_control:
		if is_inside_tree() and main_panel:
			current_tween = create_tween()
			current_tween.tween_property(main_panel, "modulate:a", 0.0, 0.2)
			current_tween.tween_callback(func():
				root_control.visible = false
			)
		else:
			root_control.visible = false


## Get the currently selected deck
func get_selected_deck() -> Array[String]:
	var deck: Array[String] = []
	for card_id in selected_deck:
		if card_id != "":
			deck.append(card_id)
	return deck


## Check if deck is valid and complete
func is_deck_valid() -> bool:
	# Check if all 4 slots are filled
	for card_id in selected_deck:
		if card_id == "":
			return false
	
	# Check mana cost
	if _get_total_mana() > MAX_MANA_COST:
		return false
	
	return true


# =============================================================================
# INTERNAL METHODS
# =============================================================================

func _on_card_selected(card_id: String, slot_index: int) -> void:
	# Toggle selection
	if selected_deck[slot_index] == card_id:
		# Deselect
		selected_deck[slot_index] = ""
	else:
		# Select (replacing any previous selection in this slot)
		selected_deck[slot_index] = card_id
	
	_update_deck_display()
	_update_card_highlights()
	
	print("Deck: %s" % str(selected_deck))


func _update_deck_display() -> void:
	var role_colors = [COLOR_GROUND_TANK, COLOR_AIR_HYBRID, COLOR_RANGED_MAGIC, COLOR_FLEX]
	
	for i in range(4):
		var card_id = selected_deck[i]
		if card_id != "":
			var card_data = CardData.get_troop(card_id)
			var display_name = card_data.get("display_name", card_id.replace("_", " ").capitalize())
			var mana = card_data.get("mana_cost", 5)
			deck_slot_labels[i].text = "%s (💎%d)" % [display_name, mana]
			deck_slot_labels[i].add_theme_color_override("font_color", role_colors[i])
			
			# Update slot border
			var slot_style = deck_slots[i].get_theme_stylebox("panel").duplicate() as StyleBoxFlat
			slot_style.border_color = COLOR_SELECTED
			deck_slots[i].add_theme_stylebox_override("panel", slot_style)
		else:
			deck_slot_labels[i].text = "Empty"
			deck_slot_labels[i].add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			
			var slot_style = deck_slots[i].get_theme_stylebox("panel").duplicate() as StyleBoxFlat
			slot_style.border_color = role_colors[i].darkened(0.3)
			deck_slots[i].add_theme_stylebox_override("panel", slot_style)
	
	# Update mana display
	var total_mana = _get_total_mana()
	mana_label.text = "  💎 %d / %d Mana" % [total_mana, MAX_MANA_COST]
	
	if total_mana > MAX_MANA_COST:
		mana_label.add_theme_color_override("font_color", COLOR_INVALID)
	elif total_mana == MAX_MANA_COST:
		mana_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		mana_label.add_theme_color_override("font_color", COLOR_VALID)
	
	# Update confirm button
	confirm_button.disabled = not is_deck_valid()


func _update_card_highlights() -> void:
	var role_cards = [GROUND_TANK_CARDS, AIR_HYBRID_CARDS, RANGED_MAGIC_CARDS, FLEX_CARDS]
	var role_colors = [COLOR_GROUND_TANK, COLOR_AIR_HYBRID, COLOR_RANGED_MAGIC, COLOR_FLEX]
	
	for slot_index in range(4):
		var selected_id = selected_deck[slot_index]
		
		for card_id in role_cards[slot_index]:
			var button = card_buttons.get(card_id)
			if button == null:
				continue
			
			# Update button style based on selection
			if card_id == selected_id:
				# Selected - golden border
				var style = button.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
				style.border_color = COLOR_SELECTED
				style.border_width_left = 4
				style.border_width_right = 4
				style.border_width_top = 4
				style.border_width_bottom = 4
				style.bg_color = role_colors[slot_index].darkened(0.6)
				button.add_theme_stylebox_override("normal", style)
				button.add_theme_color_override("font_color", COLOR_SELECTED)
			else:
				# Not selected - default style
				var style = StyleBoxFlat.new()
				style.bg_color = Color(0.1, 0.1, 0.15)
				style.border_color = role_colors[slot_index].darkened(0.3)
				style.set_border_width_all(2)
				style.set_corner_radius_all(8)
				button.add_theme_stylebox_override("normal", style)
				button.remove_theme_color_override("font_color")


func _get_total_mana() -> int:
	var total = 0
	for card_id in selected_deck:
		if card_id != "":
			var card_data = CardData.get_troop(card_id)
			total += card_data.get("mana_cost", 5)
	return total


func _on_timer_tick() -> void:
	time_remaining -= 1.0
	timer_label.text = "⏱ %ds" % int(time_remaining)
	
	if time_remaining <= 10:
		timer_label.add_theme_color_override("font_color", COLOR_INVALID)
	
	if time_remaining <= 0:
		selection_timer.stop()
		# Auto-confirm if deck is valid, otherwise select random cards
		if is_deck_valid():
			_on_confirm_pressed()
		else:
			_auto_select_remaining()
			_on_confirm_pressed()


func _auto_select_remaining() -> void:
	# Fill any empty slots with random cards from their role
	var role_cards = [GROUND_TANK_CARDS, AIR_HYBRID_CARDS, RANGED_MAGIC_CARDS, FLEX_CARDS]
	
	for i in range(4):
		if selected_deck[i] == "":
			# Pick random card from this role
			var cards = role_cards[i]
			selected_deck[i] = cards[randi() % cards.size()]
	
	_update_deck_display()


func _on_confirm_pressed() -> void:
	if not is_deck_valid():
		return
	
	var final_deck: Array[String] = []
	for card_id in selected_deck:
		final_deck.append(card_id)
	
	hide_selection()
	deck_confirmed.emit(final_deck)


func _on_cancel_pressed() -> void:
	hide_selection()
	selection_canceled.emit()


# =============================================================================
# INPUT
# =============================================================================

func _input(event: InputEvent) -> void:
	if not is_visible_ui:
		return
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_cancel_pressed()
		elif event.keycode == KEY_ENTER:
			if is_deck_valid():
				_on_confirm_pressed()
