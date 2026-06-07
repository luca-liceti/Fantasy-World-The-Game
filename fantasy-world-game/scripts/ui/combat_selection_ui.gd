## Combat Selection UI — Redesigned
## Bottom-anchored combat panel showing the two combatants in side-view,
## HP bars, a 2×2 move grid (attacker) and 4 stacked stance buttons (defender).
##
## Design language: dark near-black background, gold Cinzel typography,
## colour-coded move buttons, plain-English hook lines + stat rows.
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
# LAYOUT CONSTANTS
# =============================================================================
const PANEL_HEIGHT       : float = 460.0
const MOVE_BTN_H         : float = 90.0
const STANCE_BTN_H       : float = 62.0
const CORNER_R           : int   = 10
const PAD                : float = 10.0
const INFO_BAR_H         : float = 36.0

# Colour tokens
const C_BG               := Color(0.035, 0.035, 0.060, 0.97)
const C_BTN_BASE         := Color(0.055, 0.055, 0.090, 1.0)
const C_BORDER_GOLD      := Color(0.88, 0.76, 0.44, 0.45)
const C_HEADER_MOVE      := Color(0.78, 0.25, 0.25)   # red
const C_HEADER_STANCE    := Color(0.32, 0.52, 0.82)   # steel blue

# Move type border colours
const MOVE_TYPE_COLORS := {
	MoveData.MoveType.STANDARD : Color(0.52, 0.52, 0.60),   # silver-gray
	MoveData.MoveType.POWER    : Color(0.80, 0.20, 0.20),   # deep red
	MoveData.MoveType.PRECISION: Color(0.22, 0.44, 0.82),   # steel blue
	MoveData.MoveType.SPECIAL  : Color(0.55, 0.20, 0.80),   # royal purple
}

# Stance border colours
const STANCE_COLORS := {
	DefensiveStances.DefensiveStance.BRACE  : Color(0.28, 0.45, 0.75),
	DefensiveStances.DefensiveStance.DODGE  : Color(0.25, 0.70, 0.35),
	DefensiveStances.DefensiveStance.COUNTER: Color(0.85, 0.50, 0.10),
	DefensiveStances.DefensiveStance.ENDURE : Color(0.75, 0.20, 0.20),
}

# =============================================================================
# NODE REFERENCES
# =============================================================================
## Root control spanning the full screen (bottom-anchored panel lives inside)
var _root          : Control

## The dark panel itself
var _panel         : PanelContainer

## Info bar labels
var _info_label    : Label
var _timer_label   : Label
var _timer_bar     : ProgressBar

## HP bar rows (attacker + defender)
var _hp_bar_atk    : ProgressBar
var _hp_bar_def    : ProgressBar
var _hp_lbl_atk    : Label
var _hp_lbl_def    : Label

## Move column
var _move_header   : Label
var _move_buttons  : Array[Button] = []

## Stance column
var _stance_header : Label
var _stance_buttons: Array[Button] = []

## Confirm button + waiting label
var _confirm_btn   : Button
var _waiting_lbl   : Label

## Modifiers strip (Flanking, Cover…)
var _mod_label     : Label

# =============================================================================
# STATE
# =============================================================================
var is_attacker    : bool  = true
var current_troop  : Node  = null
var current_target : Node  = null

var selected_move  : MoveData.Move = null
var selected_stance: int = DefensiveStances.DefensiveStance.BRACE
var is_ready       : bool  = false

var current_time   : float = CombatBalanceConfig.SELECTION_TIME_LIMIT
var max_time       : float = CombatBalanceConfig.SELECTION_TIME_LIMIT
var timer_running  : bool  = false

var _last_timer_sec: int   = -1

# Precomputed timer fill styles
var _fill_normal   : StyleBoxFlat
var _fill_warn     : StyleBoxFlat
var _fill_crit     : StyleBoxFlat


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_precompute_styles()
	_build_ui()


func _precompute_styles() -> void:
	_fill_normal = StyleBoxFlat.new()
	_fill_normal.bg_color = Color(0.20, 0.72, 0.32)
	_fill_normal.set_corner_radius_all(3)

	_fill_warn = StyleBoxFlat.new()
	_fill_warn.bg_color = Color(0.92, 0.72, 0.18)
	_fill_warn.set_corner_radius_all(3)

	_fill_crit = StyleBoxFlat.new()
	_fill_crit.bg_color = Color(0.90, 0.20, 0.20)
	_fill_crit.set_corner_radius_all(3)


# =============================================================================
# UI CONSTRUCTION
# =============================================================================

func _build_ui() -> void:
	# ── Full-screen root (mouse passthrough) ──────────────────────────────────
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# ── Bottom panel ──────────────────────────────────────────────────────────
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.custom_minimum_size = Vector2(0, PANEL_HEIGHT)
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.add_child(_panel)

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = C_BG
	panel_style.border_color = C_BORDER_GOLD
	panel_style.set_border_width(SIDE_TOP, 2)
	panel_style.set_border_width(SIDE_LEFT, 0)
	panel_style.set_border_width(SIDE_RIGHT, 0)
	panel_style.set_border_width(SIDE_BOTTOM, 0)
	_panel.add_theme_stylebox_override("panel", panel_style)

	# ── Inner margin ──────────────────────────────────────────────────────────
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   int(PAD))
	margin.add_theme_constant_override("margin_right",  int(PAD))
	margin.add_theme_constant_override("margin_top",    4)
	margin.add_theme_constant_override("margin_bottom", int(PAD))
	_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	_build_info_bar(vbox)
	_build_mod_strip(vbox)
	_build_body(vbox)
	_build_hp_bars(vbox)


func _build_info_bar(parent: VBoxContainer) -> void:
	var bar = HBoxContainer.new()
	bar.custom_minimum_size = Vector2(0, INFO_BAR_H)
	bar.add_theme_constant_override("separation", 12)
	parent.add_child(bar)

	# Combatant label
	_info_label = Label.new()
	_info_label.text = "⚔️  — vs —"
	_info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_info_label.clip_text = true
	UITheme.style_label(_info_label, 13, UITheme.C_GOLD)
	bar.add_child(_info_label)

	# Timer label
	_timer_label = Label.new()
	_timer_label.text = "10s"
	_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.style_label(_timer_label, 14, UITheme.C_GOLD_BRIGHT, true)
	bar.add_child(_timer_label)

	# Timer progress bar
	_timer_bar = ProgressBar.new()
	_timer_bar.custom_minimum_size = Vector2(140, 10)
	_timer_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_timer_bar.max_value = max_time
	_timer_bar.value = max_time
	_timer_bar.show_percentage = false

	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.12, 0.12, 0.18)
	bar_bg.set_corner_radius_all(3)
	_timer_bar.add_theme_stylebox_override("background", bar_bg)
	_timer_bar.add_theme_stylebox_override("fill", _fill_normal)
	bar.add_child(_timer_bar)


func _build_mod_strip(parent: VBoxContainer) -> void:
	_mod_label = Label.new()
	_mod_label.text = ""
	_mod_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mod_label.visible = false
	UITheme.style_label(_mod_label, 11, UITheme.C_GOLD)
	parent.add_child(_mod_label)


func _build_body(parent: VBoxContainer) -> void:
	# Two-column layout: moves (65%) | stances (35%)
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", int(PAD))
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(hbox)

	_build_move_column(hbox)
	_build_stance_column(hbox)

	# Confirm button row below columns
	var confirm_row = HBoxContainer.new()
	confirm_row.alignment = BoxContainer.ALIGNMENT_END
	confirm_row.add_theme_constant_override("separation", 12)
	confirm_row.visible = false # Hidden since we now auto-confirm
	parent.add_child(confirm_row)

	_waiting_lbl = Label.new()
	_waiting_lbl.text = ""
	_waiting_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_waiting_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.style_label(_waiting_lbl, 13, UITheme.C_DIM)
	confirm_row.add_child(_waiting_lbl)

	_confirm_btn = Button.new()
	_confirm_btn.text = "✅  CONFIRM"
	_confirm_btn.custom_minimum_size = Vector2(150, 42)
	UITheme.apply_hud_button(_confirm_btn, Color(0.25, 0.75, 0.38), 16)
	_confirm_btn.pressed.connect(_on_confirm_pressed)
	confirm_row.add_child(_confirm_btn)


func _build_move_column(parent: HBoxContainer) -> void:
	var col = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_stretch_ratio = 0.65
	col.add_theme_constant_override("separation", 6)
	parent.add_child(col)

	_move_header = Label.new()
	_move_header.text = "YOUR MOVE"
	UITheme.style_label(_move_header, 12, C_HEADER_MOVE, true)
	col.add_child(_move_header)

	var grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	col.add_child(grid)

	for i in range(4):
		var btn = _make_move_button(i)
		_move_buttons.append(btn)
		grid.add_child(btn)


func _build_stance_column(parent: HBoxContainer) -> void:
	var col = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_stretch_ratio = 0.35
	col.add_theme_constant_override("separation", 6)
	parent.add_child(col)

	_stance_header = Label.new()
	_stance_header.text = "YOUR STANCE"
	UITheme.style_label(_stance_header, 12, C_HEADER_STANCE, true)
	col.add_child(_stance_header)

	var stances = DefensiveStances.get_all_stances()
	for i in range(4):
		var btn = _make_stance_button(stances[i])
		_stance_buttons.append(btn)
		col.add_child(btn)


func _build_hp_bars(parent: VBoxContainer) -> void:
	# Thin HP bars shown at the very bottom — not visible until show_* called
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	# Attacker HP
	_hp_lbl_atk = Label.new()
	_hp_lbl_atk.text = ""
	_hp_lbl_atk.custom_minimum_size = Vector2(110, 0)
	_hp_lbl_atk.clip_text = true
	UITheme.style_label(_hp_lbl_atk, 11, Color(0.90, 0.50, 0.50))
	row.add_child(_hp_lbl_atk)

	_hp_bar_atk = _make_hp_bar(Color(0.82, 0.24, 0.24))
	row.add_child(_hp_bar_atk)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(20, 0)
	row.add_child(spacer)

	_hp_bar_def = _make_hp_bar(Color(0.24, 0.44, 0.82))
	row.add_child(_hp_bar_def)

	_hp_lbl_def = Label.new()
	_hp_lbl_def.text = ""
	_hp_lbl_def.custom_minimum_size = Vector2(110, 0)
	_hp_lbl_def.clip_text = true
	_hp_lbl_def.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UITheme.style_label(_hp_lbl_def, 11, Color(0.50, 0.62, 0.90))
	row.add_child(_hp_lbl_def)


func _make_hp_bar(fill_color: Color) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 10)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false

	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.10, 0.10, 0.14)
	bg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg)

	var fill = StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


# =============================================================================
# BUTTON FACTORIES
# =============================================================================

func _make_move_button(index: int) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, MOVE_BTN_H)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.clip_text = false
	btn.text = "Move %d" % (index + 1)

	# Ensure font-size is small by default (will be styled per-move)
	btn.add_theme_font_size_override("font_size", 11)
	if UITheme.font_regular():
		btn.add_theme_font_override("font", UITheme.font_regular())

	_apply_move_btn_style(btn, Color(0.52, 0.52, 0.60), true)
	btn.pressed.connect(_on_move_pressed.bind(index))
	return btn


func _apply_move_btn_style(btn: Button, accent: Color, enabled: bool, selected: bool = false) -> void:
	var base_col = accent if enabled else Color(0.28, 0.28, 0.30)

	var normal_s = StyleBoxFlat.new()
	normal_s.bg_color = C_BTN_BASE if enabled else Color(0.040, 0.040, 0.060, 0.6)
	normal_s.border_color = UITheme.C_GOLD_BRIGHT if selected else base_col
	normal_s.set_border_width_all(3 if selected else 2)
	normal_s.set_corner_radius_all(CORNER_R)
	normal_s.set_content_margin_all(int(PAD))
	btn.add_theme_stylebox_override("normal", normal_s)

	var hover_s = StyleBoxFlat.new()
	hover_s.bg_color = base_col.darkened(0.55) if enabled else Color(0.040, 0.040, 0.060, 0.6)
	hover_s.border_color = base_col.lightened(0.3) if enabled else Color(0.28, 0.28, 0.30)
	hover_s.set_border_width_all(2)
	hover_s.set_corner_radius_all(CORNER_R)
	hover_s.set_content_margin_all(int(PAD))
	btn.add_theme_stylebox_override("hover", hover_s)
	btn.add_theme_stylebox_override("focus", hover_s)

	var pressed_s = StyleBoxFlat.new()
	pressed_s.bg_color = UITheme.C_GOLD.darkened(0.5)
	pressed_s.border_color = UITheme.C_GOLD_BRIGHT
	pressed_s.set_border_width_all(3)
	pressed_s.set_corner_radius_all(CORNER_R)
	pressed_s.set_content_margin_all(int(PAD))
	btn.add_theme_stylebox_override("pressed", pressed_s)

	var disabled_s = StyleBoxFlat.new()
	disabled_s.bg_color = Color(0.040, 0.040, 0.060, 0.55)
	disabled_s.border_color = Color(0.25, 0.25, 0.28)
	disabled_s.set_border_width_all(1)
	disabled_s.set_corner_radius_all(CORNER_R)
	disabled_s.set_content_margin_all(int(PAD))
	btn.add_theme_stylebox_override("disabled", disabled_s)


func _make_stance_button(stance: int) -> Button:
	var color = STANCE_COLORS.get(stance, Color.WHITE)

	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, STANCE_BTN_H)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.text = _build_stance_text(stance)
	btn.add_theme_font_size_override("font_size", 11)
	if UITheme.font_regular():
		btn.add_theme_font_override("font", UITheme.font_regular())

	_apply_stance_btn_style(btn, color, true, false)
	btn.pressed.connect(_on_stance_pressed.bind(stance))
	return btn


func _apply_stance_btn_style(btn: Button, accent: Color, enabled: bool, selected: bool) -> void:
	var border_col = UITheme.C_GOLD_BRIGHT if selected else accent

	var normal_s = StyleBoxFlat.new()
	normal_s.bg_color = accent.darkened(0.78) if enabled else Color(0.04, 0.04, 0.06, 0.5)
	normal_s.border_color = border_col
	normal_s.set_border_width_all(3 if selected else 2)
	normal_s.set_corner_radius_all(CORNER_R)
	normal_s.set_content_margin_all(int(PAD))
	btn.add_theme_stylebox_override("normal", normal_s)

	var hover_s = StyleBoxFlat.new()
	hover_s.bg_color = accent.darkened(0.62)
	hover_s.border_color = accent.lightened(0.3)
	hover_s.set_border_width_all(2)
	hover_s.set_corner_radius_all(CORNER_R)
	hover_s.set_content_margin_all(int(PAD))
	btn.add_theme_stylebox_override("hover", hover_s)
	btn.add_theme_stylebox_override("focus", hover_s)

	var pressed_s = StyleBoxFlat.new()
	pressed_s.bg_color = accent.darkened(0.40)
	pressed_s.border_color = UITheme.C_GOLD_BRIGHT
	pressed_s.set_border_width_all(3)
	pressed_s.set_corner_radius_all(CORNER_R)
	pressed_s.set_content_margin_all(int(PAD))
	btn.add_theme_stylebox_override("pressed", pressed_s)

	var disabled_s = StyleBoxFlat.new()
	disabled_s.bg_color = Color(0.04, 0.04, 0.06, 0.5)
	disabled_s.border_color = Color(0.25, 0.25, 0.28)
	disabled_s.set_border_width_all(1)
	disabled_s.set_corner_radius_all(CORNER_R)
	disabled_s.set_content_margin_all(int(PAD))
	btn.add_theme_stylebox_override("disabled", disabled_s)


# =============================================================================
# TEXT BUILDERS
# =============================================================================

func _build_move_text(move: MoveData.Move, troop: Node) -> String:
	# Line 1: icon + name
	var icon = _move_icon(move.move_type)
	var line1 = "%s %s" % [icon, move.move_name]

	# Line 2: plain-English hook
	var line2 = _move_hook(move.move_type)

	# Line 3: stats
	var parts: Array[String] = []
	var pct = int(move.power_percent * 100.0)
	parts.append("%d%% DMG" % pct)

	if move.accuracy_modifier > 0:
		parts.append("+%d ACC" % move.accuracy_modifier)
	elif move.accuracy_modifier < 0:
		parts.append("%d ACC" % move.accuracy_modifier)

	var cd = troop.get_move_cooldown(move.move_id) if troop else 0
	if cd > 0:
		parts.append("⏳ %d-turn cooldown" % cd)
	else:
		parts.append("No cooldown")

	# Optional effectiveness append (kept on line 3 if space — else own line)
	if current_target:
		var eff_text = _get_effectiveness_tag(move.damage_type, current_target.troop_id)
		if eff_text != "":
			return "%s\n%s\n%s\n%s" % [line1, line2, "  ".join(parts), eff_text]

	return "%s\n%s\n%s" % [line1, line2, "  ·  ".join(parts)]


func _move_icon(move_type: int) -> String:
	match move_type:
		MoveData.MoveType.STANDARD : return "⚔️"
		MoveData.MoveType.POWER    : return "💥"
		MoveData.MoveType.PRECISION: return "🎯"
		MoveData.MoveType.SPECIAL  : return "✨"
	return "❓"


func _move_hook(move_type: int) -> String:
	match move_type:
		MoveData.MoveType.STANDARD : return "Reliable strike — safe every turn"
		MoveData.MoveType.POWER    : return "Heavy blow — risky but hits hard"
		MoveData.MoveType.PRECISION: return "Careful strike — high accuracy"
		MoveData.MoveType.SPECIAL  : return "Unique ability — use it wisely"
	return ""


func _get_effectiveness_tag(damage_type: int, target_id: String) -> String:
	var eff = TypeEffectiveness.get_effectiveness(damage_type, target_id)
	if eff >= 1.5:
		return "✨ Super Effective!"
	elif eff == 0.0:
		return "🛡️ Immune"
	elif eff <= 0.5:
		return "↓ Resisted"
	return ""


func _build_stance_text(stance: int) -> String:
	match stance:
		DefensiveStances.DefensiveStance.BRACE:
			return "🛡️  Brace\nTank the hit — less damage, no knockback.\n+3 DEF  ·  −20% damage"
		DefensiveStances.DefensiveStance.DODGE:
			return "⚡  Dodge\nTry to sidestep — harder to hit you.\n+5 Evasion"
		DefensiveStances.DefensiveStance.COUNTER:
			return "↩️  Counter\nGamble — if they miss, you hit back.\n50% ATK on miss"
		DefensiveStances.DefensiveStance.ENDURE:
			return "💪  Endure\nLast resort — survive a fatal blow at 1 HP.\nOnce per match"
	return ""


func _build_stance_text_used() -> String:
	return "💪  Endure\nAlready used this match.\n(Unavailable)"


# =============================================================================
# PUBLIC API
# =============================================================================

## Show move selection for the attacking player
func show_attacker_selection(attacker: Node, defender: Node, modifiers: Array = []) -> void:
	is_attacker    = true
	current_troop  = attacker
	current_target = defender
	selected_move  = null
	is_ready       = false

	# Info bar
	var atk_name = attacker.display_name if attacker else "Attacker"
	var def_name = defender.display_name if defender else "Defender"
	_info_label.text = "⚔️  %s  →  %s" % [atk_name, def_name]

	# HP bars
	if attacker:
		_hp_lbl_atk.text = "%s  %d/%d HP" % [atk_name, attacker.current_hp, attacker.max_hp]
		_hp_bar_atk.max_value = attacker.max_hp
		_hp_bar_atk.value    = attacker.current_hp
	if defender:
		_hp_lbl_def.text = "%d/%d HP  %s" % [defender.current_hp, defender.max_hp, def_name]
		_hp_bar_def.max_value = defender.max_hp
		_hp_bar_def.value    = defender.current_hp

	# Modifiers strip
	if not modifiers.is_empty():
		_mod_label.text    = _build_modifiers_text(modifiers)
		_mod_label.visible = true
	else:
		_mod_label.visible = false

	# Show/hide panels
	_move_header.visible   = true
	_stance_header.visible = false
	for btn in _move_buttons:
		btn.get_parent().visible = true
	for btn in _stance_buttons:
		btn.visible = false

	_populate_moves(attacker)
	_refresh_confirm(false)
	_start_timer()
	visible = true


## Show stance selection for the defending player
func show_defender_selection(attacker: Node, defender: Node) -> void:
	is_attacker    = false
	current_troop  = defender
	current_target = attacker
	selected_stance = DefensiveStances.DefensiveStance.BRACE
	is_ready       = false

	# Info bar
	var atk_name = attacker.display_name if attacker else "Attacker"
	var def_name = defender.display_name if defender else "Defender"
	_info_label.text = "🛡️  %s  defending against  %s" % [def_name, atk_name]

	# HP bars
	if attacker:
		_hp_lbl_atk.text = "%s  %d/%d HP" % [atk_name, attacker.current_hp, attacker.max_hp]
		_hp_bar_atk.max_value = attacker.max_hp
		_hp_bar_atk.value    = attacker.current_hp
	if defender:
		_hp_lbl_def.text = "%d/%d HP  %s" % [defender.current_hp, defender.max_hp, def_name]
		_hp_bar_def.max_value = defender.max_hp
		_hp_bar_def.value    = defender.current_hp

	_mod_label.visible = false

	# Show/hide panels
	_move_header.visible   = false
	_stance_header.visible = true
	for btn in _move_buttons:
		btn.get_parent().visible = false
	for btn in _stance_buttons:
		btn.visible = true

	_update_stance_availability(defender)
	_highlight_selected_stance(selected_stance)
	_refresh_confirm(true)  # Brace pre-selected so confirm is immediately available
	_start_timer()
	visible = true


## Hide the UI
func hide_selection() -> void:
	visible       = false
	timer_running = false


## Switch to waiting state after confirming
func set_waiting_state() -> void:
	_waiting_lbl.text      = "⏳  Waiting for opponent…"
	_confirm_btn.disabled  = true
	_confirm_btn.text      = "⏳  Waiting…"


# =============================================================================
# PRIVATE METHODS
# =============================================================================

func _populate_moves(troop: Node) -> void:
	var moves = troop.available_moves if troop else []

	for i in range(4):
		var btn = _move_buttons[i]

		if i >= moves.size():
			btn.text     = "---"
			btn.visible  = false
			btn.disabled = true
			continue

		btn.visible = true
		var move     = moves[i]
		var cooldown = troop.get_move_cooldown(move.move_id) if troop else 0
		var available = cooldown <= 0

		btn.text     = _build_move_text(move, troop)
		btn.disabled = not available

		var color = MOVE_TYPE_COLORS.get(move.move_type, Color(0.52, 0.52, 0.60))
		_apply_move_btn_style(btn, color, available)

	# Colour labels
	for btn in _move_buttons:
		btn.add_theme_color_override("font_color",          UITheme.C_GOLD)
		btn.add_theme_color_override("font_hover_color",    UITheme.C_GOLD_BRIGHT)
		btn.add_theme_color_override("font_pressed_color",  UITheme.C_GOLD_BRIGHT)
		btn.add_theme_color_override("font_disabled_color", UITheme.C_DIM)


func _update_stance_availability(defender: Node) -> void:
	var stances = DefensiveStances.get_all_stances()
	for i in range(_stance_buttons.size()):
		var btn     = _stance_buttons[i]
		var stance  = stances[i]
		var color   = STANCE_COLORS.get(stance, Color.WHITE)
		var enabled = true

		if stance == DefensiveStances.DefensiveStance.ENDURE:
			var has_uses = defender.endure_uses_remaining > 0 if defender else true
			enabled = has_uses
			if not has_uses:
				btn.text = _build_stance_text_used()
			else:
				btn.text = _build_stance_text(stance)
		else:
			btn.text = _build_stance_text(stance)

		btn.disabled = not enabled
		_apply_stance_btn_style(btn, color, enabled, stance == selected_stance)

	# Font colours
	for btn in _stance_buttons:
		btn.add_theme_color_override("font_color",          UITheme.C_WARM_WHITE)
		btn.add_theme_color_override("font_hover_color",    UITheme.C_GOLD_BRIGHT)
		btn.add_theme_color_override("font_pressed_color",  UITheme.C_GOLD_BRIGHT)
		btn.add_theme_color_override("font_disabled_color", UITheme.C_DIM)


func _highlight_selected_stance(stance: int) -> void:
	var stances = DefensiveStances.get_all_stances()
	for i in range(_stance_buttons.size()):
		var btn    = _stance_buttons[i]
		var s      = stances[i]
		var color  = STANCE_COLORS.get(s, Color.WHITE)
		var enabled = not btn.disabled
		_apply_stance_btn_style(btn, color, enabled, s == stance)


func _highlight_selected_move(index: int) -> void:
	var moves = current_troop.available_moves if current_troop else []
	for i in range(_move_buttons.size()):
		var btn   = _move_buttons[i]
		var color : Color
		if i < moves.size():
			color = MOVE_TYPE_COLORS.get(moves[i].move_type, Color(0.52, 0.52, 0.60))
		else:
			color = Color(0.52, 0.52, 0.60)
		_apply_move_btn_style(btn, color, not btn.disabled, i == index)


func _build_modifiers_text(modifiers: Array) -> String:
	var parts: Array[String] = []
	for m in modifiers:
		match m:
			"flanking"  : parts.append("⚔️ Flanking (+3 to hit)")
			"cover"     : parts.append("🌲 In cover (+3 their DEF)")
			"surrounded": parts.append("😰 Surrounded (–3 DEF)")
			_           : parts.append(str(m))
	return "  ·  ".join(parts)


func _refresh_confirm(enabled: bool) -> void:
	_confirm_btn.disabled = not enabled
	_confirm_btn.text     = "✅  CONFIRM"
	_waiting_lbl.text     = ""


func _start_timer() -> void:
	current_time = max_time
	timer_running = true
	_waiting_lbl.text    = ""
	_confirm_btn.disabled = false
	_confirm_btn.text    = "✅  CONFIRM"
	_last_timer_sec      = -1
	_update_timer_display()


func _update_timer_display() -> void:
	_timer_bar.value = current_time
	var secs = int(current_time)

	if secs != _last_timer_sec:
		_last_timer_sec = secs
		_timer_label.text = "%ds" % secs

		if secs <= 3:
			_timer_bar.add_theme_stylebox_override("fill", _fill_crit)
			_timer_label.add_theme_color_override("font_color", Color(1.0, 0.30, 0.30))
		elif secs <= 5:
			_timer_bar.add_theme_stylebox_override("fill", _fill_warn)
			_timer_label.add_theme_color_override("font_color", Color(0.95, 0.80, 0.20))
		else:
			_timer_bar.add_theme_stylebox_override("fill", _fill_normal)
			_timer_label.add_theme_color_override("font_color", UITheme.C_GOLD_BRIGHT)


# =============================================================================
# PROCESS
# =============================================================================

func _process(delta: float) -> void:
	if not visible or not timer_running:
		return

	current_time -= delta
	_update_timer_display()

	if current_time <= 0.0:
		timer_running = false
		visible = false
		timeout.emit()


# =============================================================================
# BUTTON CALLBACKS
# =============================================================================

func _on_move_pressed(index: int) -> void:
	if not current_troop:
		return
	if index >= current_troop.available_moves.size():
		return

	selected_move = current_troop.available_moves[index]
	_highlight_selected_move(index)
	_on_confirm_pressed()


func _on_stance_pressed(stance: int) -> void:
	selected_stance = stance
	_highlight_selected_stance(stance)
	_on_confirm_pressed()


func _on_confirm_pressed() -> void:
	if is_ready:
		return

	is_ready      = true
	timer_running = false

	# Call this first so we don't overwrite UI if the emitted signal triggers another UI phase
	ready_pressed.emit()
	set_waiting_state()

	if is_attacker:
		if selected_move:
			move_selected.emit(selected_move)
		elif current_troop and current_troop.available_moves.size() > 0:
			# Default to first available move
			selected_move = current_troop.available_moves[0]
			move_selected.emit(selected_move)
	else:
		stance_selected.emit(selected_stance)
