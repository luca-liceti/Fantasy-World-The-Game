## Combat Selection UI
## Handles the move selection for attacker and stance selection for defender
## Part of the D&D × Pokémon hybrid combat system
class_name CombatSelectionUI
extends CanvasLayer

# =============================================================================
# SIGNALS
# =============================================================================
signal move_selected(move: MoveData.Move)
signal stance_selected(stance: int)
signal ready_pressed()
signal timeout()

# =============================================================================
# UI ELEMENTS
# =============================================================================
var main_container: Control
var background_panel: PanelContainer
var content_container: VBoxContainer

# Header & Stats
var header_label: Label
var combatants_label: Label
var stats_container: HBoxContainer
var attacker_stats_label: Label
var defender_stats_label: Label

# Positioning Modifiers
var modifiers_label: Label

# Selection panels
var attacker_panel: PanelContainer
var defender_panel: PanelContainer

# Move buttons (for attacker)
var move_buttons: Array[Button] = []
var move_tooltips: Array[PanelContainer] = []

# Stance buttons (for defender)
var stance_buttons: Array[Button] = []

# Ready button and status
var ready_button: Button
var waiting_label: Label
var is_ready: bool = false

# Timer
var timer_bar: ProgressBar
var timer_label: Label
var current_time: float = CombatBalanceConfig.SELECTION_TIME_LIMIT
var max_time: float = CombatBalanceConfig.SELECTION_TIME_LIMIT
var timer_running: bool = false

var _bar_fill_normal: StyleBoxFlat
var _bar_fill_warning: StyleBoxFlat
var _bar_fill_critical: StyleBoxFlat

# State
var is_attacker: bool = true
var current_troop: Node = null
var current_target: Node = null  # Added for prediction
var selected_move: MoveData.Move = null
var selected_stance: int = DefensiveStances.DefensiveStance.BRACE

# Combat Mode (Simple vs Enhanced)
var combat_mode: int = GameConfig.CombatMode.ENHANCED
var mode_config: Dictionary = {}

# Recommended move index (for Simple Mode hints)
var recommended_move_index: int = -1

# =============================================================================
# COLORS & STYLING
# =============================================================================
const BG_COLOR = Color(0, 0, 0, 0)
const PANEL_COLOR = Color(0, 0, 0, 0)
const BORDER_COLOR = Color(0.3, 0.4, 0.5)
const MOVE_COLORS = {
	MoveData.MoveType.STANDARD: Color(0.6, 0.6, 0.7),
	MoveData.MoveType.POWER: Color(0.9, 0.3, 0.3),
	MoveData.MoveType.PRECISION: Color(0.3, 0.6, 0.9),
	MoveData.MoveType.SPECIAL: Color(0.7, 0.3, 0.9)
}
const STANCE_COLORS = {
	DefensiveStances.DefensiveStance.BRACE: Color(0.3, 0.5, 0.8),
	DefensiveStances.DefensiveStance.DODGE: Color(0.2, 0.8, 0.2),
	DefensiveStances.DefensiveStance.COUNTER: Color(0.9, 0.5, 0.1),
	DefensiveStances.DefensiveStance.ENDURE: Color(0.8, 0.2, 0.2)
}


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	visible = false
	_create_precomputed_styles()
	_create_ui()

func _create_precomputed_styles() -> void:
	_bar_fill_normal = StyleBoxFlat.new()
	_bar_fill_normal.bg_color = Color(0.2, 0.7, 0.3)
	_bar_fill_normal.set_corner_radius_all(4)
	
	_bar_fill_warning = StyleBoxFlat.new()
	_bar_fill_warning.bg_color = Color(0.9, 0.7, 0.2)
	_bar_fill_warning.set_corner_radius_all(4)
	
	_bar_fill_critical = StyleBoxFlat.new()
	_bar_fill_critical.bg_color = Color(0.9, 0.2, 0.2)
	_bar_fill_critical.set_corner_radius_all(4)


func _process(delta: float) -> void:
	if timer_running and visible:
		current_time -= delta
		_update_timer_display()
		
		if current_time <= 0:
			timer_running = false
			visible = false  # Hide UI immediately on timeout
			# Only emit timeout signal - main.gd will handle combat resolution
			# This prevents race conditions from emitting both timeout AND move/stance signals
			timeout.emit()


func _create_ui() -> void:
	# Main container - fullscreen overlay
	main_container = Control.new()
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_container)
	
	# Semi-transparent background — UITheme overlay
	var bg = UITheme.make_overlay_bg()
	main_container.add_child(bg)
	
	# Center panel
	background_panel = PanelContainer.new()
	background_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	background_panel.custom_minimum_size = Vector2(650, 500)
	background_panel.position = Vector2(-325, -520) # 20px padding from bottom
	main_container.add_child(background_panel)
	
	background_panel.add_theme_stylebox_override("panel", UITheme.overlay_panel(UITheme.C_GOLD))
	
	# Content container
	content_container = VBoxContainer.new()
	content_container.add_theme_constant_override("separation", 10)
	background_panel.add_child(content_container)
	
	_create_header()
	_create_stats_display()
	_create_timer()
	_create_modifiers_display()
	_create_selection_panels()
	_create_ready_section()


func _create_header() -> void:
	var header_container = VBoxContainer.new()
	header_container.add_theme_constant_override("separation", 4)
	content_container.add_child(header_container)
	
	# Title
	header_label = Label.new()
	header_label.text = "⚔️ COMBAT! ⚔️"
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(header_label, 28, UITheme.C_GOLD_BRIGHT, true)
	header_container.add_child(header_label)
	
	# Combatants
	combatants_label = Label.new()
	combatants_label.text = "Attacker vs Defender"
	combatants_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(combatants_label, 16, UITheme.C_WARM_WHITE)
	header_container.add_child(combatants_label)


func _create_stats_display() -> void:
	stats_container = HBoxContainer.new()
	stats_container.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_container.add_theme_constant_override("separation", 40)
	content_container.add_child(stats_container)
	
	attacker_stats_label = Label.new()
	attacker_stats_label.text = "ATK: -- | HP: --/--"
	UITheme.style_label(attacker_stats_label, 14, Color(0.9, 0.6, 0.6))
	stats_container.add_child(attacker_stats_label)
	
	var vs = Label.new()
	vs.text = "VS"
	UITheme.style_label(vs, 14, UITheme.C_DIM)
	stats_container.add_child(vs)
	
	defender_stats_label = Label.new()
	defender_stats_label.text = "DEF: -- | HP: --/--"
	UITheme.style_label(defender_stats_label, 14, Color(0.6, 0.6, 0.9))
	stats_container.add_child(defender_stats_label)


func _create_modifiers_display() -> void:
	modifiers_label = Label.new()
	modifiers_label.text = "Positioning: Normal"
	modifiers_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(modifiers_label, 12, UITheme.C_GOLD)


func _create_timer() -> void:
	var timer_container = HBoxContainer.new()
	timer_container.alignment = BoxContainer.ALIGNMENT_CENTER
	content_container.add_child(timer_container)
	
	# Timer icon
	var timer_icon = Label.new()
	timer_icon.text = "⏱️ "
	timer_icon.add_theme_font_size_override("font_size", 18)
	timer_container.add_child(timer_icon)
	
	# Progress bar
	timer_bar = ProgressBar.new()
	timer_bar.custom_minimum_size = Vector2(250, 20)
	timer_bar.max_value = max_time
	timer_bar.value = current_time
	timer_bar.show_percentage = false
	timer_container.add_child(timer_bar)
	
	# Style the progress bar
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.15, 0.15, 0.2)
	bar_bg.set_corner_radius_all(4)
	timer_bar.add_theme_stylebox_override("background", bar_bg)
	
	timer_bar.add_theme_stylebox_override("fill", _bar_fill_normal)
	
	# Timer label
	timer_label = Label.new()
	timer_label.text = " 10s"
	timer_label.add_theme_font_size_override("font_size", 16)
	timer_label.add_theme_color_override("font_color", Color.WHITE)
	timer_container.add_child(timer_label)


func _create_selection_panels() -> void:
	# Attacker panel (moves)
	attacker_panel = _create_panel_section("🗡️ SELECT YOUR MOVE", Color(0.8, 0.4, 0.4))
	content_container.add_child(attacker_panel)
	
	var attacker_grid = GridContainer.new()
	attacker_grid.columns = 2
	attacker_grid.add_theme_constant_override("h_separation", 10)
	attacker_grid.add_theme_constant_override("v_separation", 10)
	attacker_panel.get_child(0).add_child(attacker_grid)
	
	# Create 4 move buttons
	for i in range(4):
		var move_btn = _create_move_button(i)
		move_buttons.append(move_btn)
		attacker_grid.add_child(move_btn)
	
	# Defender panel (stances)
	defender_panel = _create_panel_section("🛡️ SELECT YOUR STANCE", Color(0.4, 0.5, 0.8))
	content_container.add_child(defender_panel)
	
	var defender_grid = GridContainer.new()
	defender_grid.columns = 4
	defender_grid.add_theme_constant_override("h_separation", 10)
	defender_panel.get_child(0).add_child(defender_grid)
	
	# Create 4 stance buttons
	var stances = DefensiveStances.get_all_stances()
	for i in range(4):
		var stance_btn = _create_stance_button(stances[i])
		stance_buttons.append(stance_btn)
		defender_grid.add_child(stance_btn)


func _create_panel_section(title: String, accent_color: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	
	panel.add_theme_stylebox_override("panel", UITheme.section_panel(accent_color))
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	
	var title_label = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(title_label, 16, accent_color, true)
	vbox.add_child(title_label)
	
	return panel


func _create_move_button(index: int) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(300, 85)
	button.text = "Move %d" % (index + 1)
	button.add_theme_font_size_override("font_size", 12)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.15, 0.15, 0.2)
	normal_style.border_color = UITheme.C_GOLD.darkened(0.5)
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(8)
	normal_style.set_content_margin_all(8)
	button.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.2, 0.2, 0.28)
	hover_style.border_color = UITheme.C_GOLD
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(8)
	hover_style.set_content_margin_all(8)
	button.add_theme_stylebox_override("hover", hover_style)
	
	var disabled_style = StyleBoxFlat.new()
	disabled_style.bg_color = Color(0.1, 0.1, 0.12, 0.5)
	disabled_style.border_color = Color(0.2, 0.2, 0.2)
	disabled_style.set_border_width_all(1)
	disabled_style.set_corner_radius_all(8)
	disabled_style.set_content_margin_all(8)
	button.add_theme_stylebox_override("disabled", disabled_style)
	
	button.pressed.connect(_on_move_button_pressed.bind(index))
	
	return button


func _create_stance_button(stance: int) -> Button:
	var data = DefensiveStances.get_stance_data(stance)
	var color = STANCE_COLORS.get(stance, Color.WHITE)
	
	var button = Button.new()
	button.custom_minimum_size = Vector2(130, 85)
	button.text = data["name"] + "\n" + _get_stance_short_desc(stance)
	button.add_theme_font_size_override("font_size", 11)
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = color.darkened(0.7)
	normal_style.border_color = UITheme.C_GOLD.darkened(0.5)
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(8)
	normal_style.set_content_margin_all(8)
	button.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = color.darkened(0.5)
	hover_style.border_color = UITheme.C_GOLD
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(8)
	hover_style.set_content_margin_all(8)
	button.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = color.darkened(0.3)
	pressed_style.border_color = Color(1.0, 0.9, 0.5)
	pressed_style.set_border_width_all(3)
	pressed_style.set_corner_radius_all(8)
	pressed_style.set_content_margin_all(8)
	button.add_theme_stylebox_override("pressed", pressed_style)
	
	var disabled_style = StyleBoxFlat.new()
	disabled_style.bg_color = Color(0.1, 0.1, 0.12, 0.5)
	disabled_style.border_color = Color(0.2, 0.2, 0.2)
	disabled_style.set_border_width_all(1)
	disabled_style.set_corner_radius_all(8)
	disabled_style.set_content_margin_all(8)
	button.add_theme_stylebox_override("disabled", disabled_style)
	
	button.pressed.connect(_on_stance_button_pressed.bind(stance))
	
	return button


func _get_stance_short_desc(stance: int) -> String:
	match stance:
		DefensiveStances.DefensiveStance.BRACE:
			return "+3 DEF\n-20% DMG"
		DefensiveStances.DefensiveStance.DODGE:
			return "+5 Evasion"
		DefensiveStances.DefensiveStance.COUNTER:
			return "50% ATK\non miss"
		DefensiveStances.DefensiveStance.ENDURE:
			return "Survive\nat 1 HP"
	return ""


func _create_ready_section() -> void:
	var ready_container = HBoxContainer.new()
	ready_container.alignment = BoxContainer.ALIGNMENT_CENTER
	ready_container.add_theme_constant_override("separation", 20)
	content_container.add_child(ready_container)
	
	# Ready button — styled via UITheme
	ready_button = Button.new()
	ready_button.text = "✅ READY"
	ready_button.custom_minimum_size = Vector2(160, 50)
	UITheme.apply_hud_button(ready_button, Color(0.3, 0.8, 0.4), 20)
	ready_button.pressed.connect(_on_ready_pressed)
	ready_container.add_child(ready_button)
	
	# Waiting label
	waiting_label = Label.new()
	waiting_label.text = ""
	UITheme.style_label(waiting_label, 16, UITheme.C_WARM_WHITE)
	ready_container.add_child(waiting_label)


# =============================================================================
# PUBLIC METHODS
# =============================================================================

## Set the combat mode (SIMPLE or ENHANCED)
func set_combat_mode(mode: int) -> void:
	combat_mode = mode
	mode_config = GameConfig.get_combat_mode_config(mode)
	
	# Update timer based on mode
	max_time = mode_config.get("timer_seconds", CombatBalanceConfig.SELECTION_TIME_LIMIT)


## Show the selection UI for the attacker
func show_attacker_selection(attacker: Node, defender: Node, modifiers: Array = []) -> void:
	is_attacker = true
	current_troop = attacker
	current_target = defender
	selected_move = null
	is_ready = false
	recommended_move_index = -1
	
	combatants_label.text = "%s ⚔️ %s" % [attacker.display_name, defender.display_name]
	
	# Update Stats Display
	var atk_val = attacker.get_modified_stat("atk")
	var hp_cur = attacker.current_hp
	var hp_max = attacker.max_hp
	attacker_stats_label.text = "ATK: %d | HP: %d/%d" % [atk_val, hp_cur, hp_max]
	
	var def_val = defender.get_modified_stat("def")
	var def_hp_cur = defender.current_hp
	var def_hp_max = defender.max_hp
	defender_stats_label.text = "DEF: %d | HP: %d/%d" % [def_val, def_hp_cur, def_hp_max]
	
	# Update Modifiers based on mode
	if mode_config.get("show_positioning", true):
		if modifiers.is_empty():
			modifiers_label.text = "Positioning: Normal"
		else:
			modifiers_label.text = "Modifiers: " + ", ".join(modifiers)
	else:
		# Simple Mode - hide positioning complexity
		modifiers_label.text = "Choose your attack!"
	
	# Show attacker panel, hide defender panel
	attacker_panel.visible = true
	defender_panel.visible = false
	
	# Populate move buttons (respects Simple Mode filtering)
	_populate_move_buttons(attacker)
	
	# Reset timer
	_start_timer()
	
	visible = true


## Show the selection UI for the defender
func show_defender_selection(attacker: Node, defender: Node) -> void:
	is_attacker = false
	current_troop = defender
	current_target = attacker # Opponent
	selected_stance = DefensiveStances.DefensiveStance.BRACE
	is_ready = false
	
	# Simple Mode: Auto-select stance and skip defender UI
	if mode_config.get("auto_defender_stance", false):
		# Auto-select Brace (safest option for new players)
		selected_stance = DefensiveStances.DefensiveStance.BRACE
		is_ready = true
		stance_selected.emit(selected_stance)
		ready_pressed.emit()
		return  # Don't show UI, auto-proceed
	
	combatants_label.text = "%s 🛡️ %s" % [defender.display_name, attacker.display_name]
	
	# Update Stats Display
	var def_val = defender.get_modified_stat("def")
	var hp_cur = defender.current_hp
	var hp_max = defender.max_hp
	attacker_stats_label.text = "DEF: %d | HP: %d/%d" % [def_val, hp_cur, hp_max]
	attacker_stats_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.9))
	
	var atk_val = attacker.get_modified_stat("atk")
	defender_stats_label.text = "ATK: %d" % atk_val
	defender_stats_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.6))
	
	modifiers_label.text = "Prepare to defend!"
	
	# Show defender panel, hide attacker panel
	attacker_panel.visible = false
	defender_panel.visible = true
	
	# Update stance buttons (check if Endure is available)
	_update_stance_buttons(defender)
	
	# Reset timer
	_start_timer()
	
	visible = true


## Hide the selection UI
func hide_selection() -> void:
	visible = false
	timer_running = false


## Set waiting state (after player is ready)
func set_waiting_state() -> void:
	waiting_label.text = "⏳ Waiting for opponent..."
	ready_button.disabled = true


# =============================================================================
# PRIVATE METHODS
# =============================================================================

func _populate_move_buttons(troop: Node) -> void:
	var moves = troop.available_moves if troop else []
	var moves_visible = mode_config.get("moves_visible", 4)
	var show_damage_types = mode_config.get("show_damage_types", true)
	var hint_recommended = mode_config.get("hint_recommended_move", false)
	
	# Calculate recommended move for Simple Mode
	if hint_recommended and current_target:
		recommended_move_index = _calculate_recommended_move(troop, current_target)
	
	# Filter moves for Simple Mode (show Standard + best Special)
	var filtered_moves = _get_filtered_moves(moves, moves_visible)
	
	for i in range(4):
		var button = move_buttons[i]
		
		# In Simple Mode, hide extra buttons
		if i >= moves_visible:
			button.visible = false
			continue
		else:
			button.visible = true
		
		if i < filtered_moves.size():
			var move = filtered_moves[i]
			var cooldown = troop.get_move_cooldown(move.move_id)
			var is_available = cooldown <= 0
			
			# Build button text based on mode
			var text = ""
			if combat_mode == GameConfig.CombatMode.SIMPLE:
				# Simplified display for new players
				text = _build_simple_move_text(move, troop, cooldown)
			else:
				# Full display for Enhanced Mode
				var type_str = ["STD", "PWR", "PRC", "SPC"][move.move_type]
				var power_str = str(int(move.power_percent * 100)) + "%"
				var acc_str = ("+" if move.accuracy_modifier >= 0 else "") + str(move.accuracy_modifier)
				
				text = "%s\n%s | %s PWR | %s ACC" % [move.move_name, type_str, power_str, acc_str]
				
				# Add Effectiveness Preview
				if current_target and show_damage_types:
					var target_id = current_target.troop_id
					var damage_type = move.damage_type
					var effectiveness_text = _get_matchup_text(damage_type, target_id)
					text += "\n" + effectiveness_text
				
				if cooldown > 0:
					text += "\n⏳ %d turns" % cooldown
			
			button.text = text
			button.disabled = not is_available
			
			# Color based on move type, with recommendation highlight
			var color = MOVE_COLORS.get(move.move_type, Color.WHITE)
			var is_recommended = hint_recommended and (i == recommended_move_index)
			_style_move_button_with_recommendation(button, color, is_available, is_recommended)
		else:
			button.text = "---"
			button.disabled = true
			button.visible = false


func _get_matchup_text(damage_type: int, target_id: String) -> String:
	var effectiveness = TypeEffectiveness.get_effectiveness(damage_type, target_id)
	
	if effectiveness >= 1.5:
		return "✨ Super Effective!"
	elif effectiveness == 0.0:
		return "🛡️ Immune"
	elif effectiveness <= 0.5:
		return "🛡️ Resisted"
	else:
		return ""


func _style_move_button(button: Button, color: Color, enabled: bool) -> void:
	if enabled:
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = color.darkened(0.7)
		normal_style.border_color = color.darkened(0.4)
		normal_style.set_border_width_all(2)
		normal_style.set_corner_radius_all(8)
		button.add_theme_stylebox_override("normal", normal_style)
		
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = color.darkened(0.5)
		hover_style.border_color = color
		hover_style.set_border_width_all(2)
		hover_style.set_corner_radius_all(8)
		button.add_theme_stylebox_override("hover", hover_style)


func _update_stance_buttons(defender: Node) -> void:
	for i in range(stance_buttons.size()):
		var button = stance_buttons[i]
		var stance = DefensiveStances.get_all_stances()[i]
		
		# Check if Endure is available
		if stance == DefensiveStances.DefensiveStance.ENDURE:
			var can_use = defender.endure_uses_remaining > 0 if defender else true
			button.disabled = not can_use
			if not can_use:
				button.text = "Endure\n(USED)"


func _start_timer() -> void:
	current_time = max_time
	timer_running = true
	waiting_label.text = ""
	ready_button.disabled = false
	is_ready = false
	_update_timer_display()


var _last_timer_seconds: int = -1

func _update_timer_display() -> void:
	timer_bar.value = current_time
	var display_seconds = int(current_time)
	
	if display_seconds != _last_timer_seconds:
		_last_timer_seconds = display_seconds
		timer_label.text = " %ds" % display_seconds
		
		if display_seconds <= 3:
			timer_bar.add_theme_stylebox_override("fill", _bar_fill_critical)
			timer_label.add_theme_color_override("font_color", Color.RED)
		elif display_seconds <= 5:
			timer_bar.add_theme_stylebox_override("fill", _bar_fill_warning)
			timer_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			timer_bar.add_theme_stylebox_override("fill", _bar_fill_normal)
			timer_label.add_theme_color_override("font_color", Color.WHITE)


func _on_move_button_pressed(index: int) -> void:
	if current_troop and index < current_troop.available_moves.size():
		selected_move = current_troop.available_moves[index]
		
		# Highlight selected button
		for i in range(move_buttons.size()):
			var button = move_buttons[i]
			if i == index:
				var style = StyleBoxFlat.new()
				style.bg_color = Color(0.3, 0.5, 0.3)
				style.border_color = Color(0.5, 1.0, 0.5)
				style.set_border_width_all(3)
				style.set_corner_radius_all(8)
				button.add_theme_stylebox_override("normal", style)
			elif not button.disabled:
				var move = current_troop.available_moves[i] if i < current_troop.available_moves.size() else null
				if move:
					var color = MOVE_COLORS.get(move.move_type, Color.WHITE)
					_style_move_button(button, color, true)


func _on_stance_button_pressed(stance: int) -> void:
	selected_stance = stance
	
	# Highlight selected button
	var stances = DefensiveStances.get_all_stances()
	for i in range(stance_buttons.size()):
		var button = stance_buttons[i]
		var btn_stance = stances[i]
		var color = STANCE_COLORS.get(btn_stance, Color.WHITE)
		
		if btn_stance == stance:
			var style = StyleBoxFlat.new()
			style.bg_color = color.darkened(0.3)
			style.border_color = Color(1.0, 0.9, 0.5)
			style.set_border_width_all(3)
			style.set_corner_radius_all(8)
			button.add_theme_stylebox_override("normal", style)
		elif not button.disabled:
			var normal_style = StyleBoxFlat.new()
			normal_style.bg_color = color.darkened(0.7)
			normal_style.border_color = UITheme.C_GOLD.darkened(0.5)
			normal_style.set_border_width_all(2)
			normal_style.set_corner_radius_all(8)
			button.add_theme_stylebox_override("normal", normal_style)


func _on_ready_pressed() -> void:
	if is_ready:
		return
	
	is_ready = true
	timer_running = false
	
	if is_attacker:
		if selected_move:
			move_selected.emit(selected_move)
		else:
			# Default to first available move
			if current_troop and current_troop.available_moves.size() > 0:
				selected_move = current_troop.available_moves[0]
				move_selected.emit(selected_move)
	else:
		stance_selected.emit(selected_stance)
	
	ready_pressed.emit()
	set_waiting_state()


func _on_timeout() -> void:
	if is_ready:
		return
	
	is_ready = true
	
	# Auto-select defaults
	if is_attacker:
		if current_troop and current_troop.available_moves.size() > 0:
			selected_move = current_troop.available_moves[0]
			move_selected.emit(selected_move)
	else:
		selected_stance = DefensiveStances.DefensiveStance.BRACE
		stance_selected.emit(selected_stance)
	
	ready_pressed.emit()


# =============================================================================
# SIMPLE MODE HELPER METHODS
# =============================================================================

## Get filtered moves for Simple Mode
## Returns Standard move + best available special move
func _get_filtered_moves(moves: Array, max_count: int) -> Array:
	if max_count >= 4 or moves.size() <= max_count:
		return moves
	
	var filtered = []
	var standard_move = null
	var best_special = null
	var best_special_score = -1.0
	
	for move in moves:
		if move.move_type == MoveData.MoveType.STANDARD:
			standard_move = move
		else:
			# Score special moves by power * (1 + accuracy/10)
			var score = move.power_percent * (1.0 + float(move.accuracy_modifier) / 10.0)
			if score > best_special_score:
				best_special_score = score
				best_special = move
	
	# Always include Standard first
	if standard_move:
		filtered.append(standard_move)
	
	# Add best special move
	if best_special and filtered.size() < max_count:
		filtered.append(best_special)
	
	# Fill remaining slots if needed
	for move in moves:
		if filtered.size() >= max_count:
			break
		if move not in filtered:
			filtered.append(move)
	
	return filtered


## Build simplified move text for Simple Mode
func _build_simple_move_text(move: MoveData.Move, troop: Node, cooldown: int) -> String:
	var text = move.move_name + "\n"
	
	# Show power as simple stars
	var power_stars = _get_power_stars(move.power_percent)
	text += "Power: %s\n" % power_stars
	
	# Show simple hit chance if we have a target
	if current_target:
		var hit_chance = _estimate_hit_chance(troop, current_target, move)
		text += "Hit: ~%d%%\n" % hit_chance
		
		# Show simple effectiveness
		var eff_text = CombatBalanceConfig.get_simple_effectiveness_text(
			move.damage_type, current_target.troop_id
		)
		if eff_text == "STRONG":
			text += "✅ STRONG"
		elif eff_text == "WEAK":
			text += "⚠️ WEAK"
	
	if cooldown > 0:
		text += "\n⏳ Wait %d" % cooldown
	
	return text


## Convert power percent to star rating
func _get_power_stars(power: float) -> String:
	if power >= 1.5:
		return "⭐⭐⭐"  # High power
	elif power >= 1.0:
		return "⭐⭐"    # Medium power
	elif power >= 0.5:
		return "⭐"      # Low power
	else:
		return "—"       # Utility (no damage)


## Estimate hit chance for Simple Mode display
func _estimate_hit_chance(attacker: Node, defender: Node, move: MoveData.Move) -> int:
	# Simplified calculation for display purposes
	var atk = attacker.get_modified_stat("atk") if attacker else 50
	var def = defender.get_modified_stat("def") if defender else 50
	
	var atk_mod = int(atk / 10.0) + move.accuracy_modifier
	var dc = 10 + int(def / 10.0)
	
	# On d20: need to roll >= (dc - atk_mod) to hit
	var min_roll_needed = dc - atk_mod
	
	# Clamp to valid d20 range
	min_roll_needed = clamp(min_roll_needed, 1, 20)
	
	# Calculate probability: (21 - min_roll_needed) / 20 * 100
	var hit_chance = int((21.0 - float(min_roll_needed)) / 20.0 * 100.0)
	
	return clamp(hit_chance, 5, 95)  # Never show 0% or 100%


## Calculate recommended move for Simple Mode hints
func _calculate_recommended_move(troop: Node, target: Node) -> int:
	if not troop or not target:
		return 0
	
	var moves = troop.available_moves
	var best_index = 0
	var best_score = -1.0
	
	for i in range(moves.size()):
		var move = moves[i]
		var cooldown = troop.get_move_cooldown(move.move_id)
		
		if cooldown > 0:
			continue  # Skip moves on cooldown
		
		# Score = power * effectiveness * hit_chance_factor
		var effectiveness = TypeEffectiveness.get_effectiveness(move.damage_type, target.troop_id)
		var hit_factor = 1.0 + float(move.accuracy_modifier) / 10.0
		var score = move.power_percent * effectiveness * hit_factor
		
		# Bonus for Standard moves (reliable)
		if move.move_type == MoveData.MoveType.STANDARD:
			score *= 1.1
		
		if score > best_score:
			best_score = score
			best_index = i
	
	return best_index


## Style move button with optional recommendation highlight
func _style_move_button_with_recommendation(button: Button, color: Color, enabled: bool, is_recommended: bool) -> void:
	if not enabled:
		var disabled_style = StyleBoxFlat.new()
		disabled_style.bg_color = Color(0.1, 0.1, 0.12, 0.5)
		disabled_style.border_color = Color(0.2, 0.2, 0.2)
		disabled_style.set_border_width_all(1)
		disabled_style.set_corner_radius_all(8)
		button.add_theme_stylebox_override("normal", disabled_style)
		return
	
	if is_recommended:
		# Golden highlight for recommended move
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.3, 0.35, 0.15)
		normal_style.border_color = Color(1.0, 0.85, 0.3)
		normal_style.set_border_width_all(3)
		normal_style.set_corner_radius_all(8)
		button.add_theme_stylebox_override("normal", normal_style)
		
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(0.4, 0.45, 0.2)
		hover_style.border_color = Color(1.0, 0.9, 0.5)
		hover_style.set_border_width_all(3)
		hover_style.set_corner_radius_all(8)
		button.add_theme_stylebox_override("hover", hover_style)
	else:
		# Normal styling
		_style_move_button(button, color, enabled)
