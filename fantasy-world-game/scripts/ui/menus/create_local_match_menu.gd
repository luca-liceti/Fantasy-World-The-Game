## Custom Match Menu — Fantasy World
## Sub-screen opened from Play → Custom Match.
## Lets the player configure all match settings,
## then start the match.
## Uses UITheme for consistent medieval styling.
class_name CreateLocalMatchMenu
extends CanvasLayer

# =============================================================================
# SIGNALS
# =============================================================================
signal start_match(settings: Dictionary)
signal back_pressed

# =============================================================================
# UI ELEMENTS
# =============================================================================
var _root: Control = null
var _content_vbox: VBoxContainer = null

# Dropdown / option references
var _environment_option: OptionButton = null
var _terrain_toggle: CheckButton = null
var _timer_option: OptionButton = null
var _combat_option: OptionButton = null
var _combat_speed_option: OptionButton = null
var _gold_option: OptionButton = null
var _npc_toggle: CheckButton = null
var _bounty_toggle: CheckButton = null


# =============================================================================
# READY
# =============================================================================

func _ready() -> void:
	_build_ui()


# =============================================================================
# BUILD UI
# =============================================================================

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# ── Sub-logo (top centre) ──
	var sub_logo_scale = 0.50
	var slw = UITheme.LOGO_W * sub_logo_scale
	var slh = UITheme.LOGO_H * sub_logo_scale
	var logo = TextureRect.new()
	logo.texture      = UITheme.tex_logo()
	logo.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(slw, slh)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	logo.position = Vector2(-slw * 0.5, 20)
	_root.add_child(logo)

	# ── Page title ──
	var title_lbl = Label.new()
	title_lbl.text = "CUSTOM MATCH"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title_lbl.custom_minimum_size = Vector2(800, 60)
	title_lbl.position = Vector2(-400, slh + 32)
	UITheme.style_label(title_lbl, UITheme.TITLE_FONT, UITheme.C_GOLD, true)
	_root.add_child(title_lbl)

	# ── Gold separator ──
	var sep = UITheme.make_separator()
	sep.set_anchors_preset(Control.PRESET_CENTER_TOP)
	sep.custom_minimum_size = Vector2(640, 4)
	sep.position = Vector2(-320, slh + 32 + 62)
	_root.add_child(sep)

	# ── Content panel ──
	var panel_w = 700.0
	var panel_h = 500.0
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(panel_w, panel_h)
	panel.position = Vector2(-panel_w * 0.5, -panel_h * 0.5 + 32)
	UITheme.apply_panel(panel)
	_root.add_child(panel)

	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	_content_vbox = VBoxContainer.new()
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_vbox.add_theme_constant_override("separation", 14)
	scroll.add_child(_content_vbox)

	_build_settings_panels()
	_build_start_section()

	# ── BACK button ──
	var back_btn = Button.new()
	back_btn.text = "BACK"
	back_btn.name = "BackBtn"
	back_btn.custom_minimum_size = Vector2(UITheme.BTN_SM_W, UITheme.BTN_SM_H)
	back_btn.pivot_offset = Vector2(UITheme.BTN_SM_W * 0.5, UITheme.BTN_SM_H * 0.5)
	UITheme.apply_menu_button(back_btn, UITheme.BTN_SM_FONT)
	back_btn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	back_btn.position = Vector2(UITheme.PAD * 2, -(UITheme.BTN_SM_H + UITheme.PAD * 2))
	back_btn.pressed.connect(_on_back_pressed)
	_root.add_child(back_btn)


# =============================================================================
# SETTINGS PANELS  (always visible — no Default/Custom tabs)
# =============================================================================

func _build_settings_panels() -> void:
	# ── Panel 1: World & Atmosphere ──
	var world_panel = _make_settings_panel("WORLD & ATMOSPHERE")
	_content_vbox.add_child(world_panel)
	var world_vbox = world_panel.get_child(0).get_child(0)

	_environment_option = _make_option_row(world_vbox, "Environment",
		["Random", "Cozy Tavern", "Battlefield Tent", "Dining Hall", "Deforested Woods"])

	_terrain_toggle = _make_toggle_row(world_vbox, "Terrain Height Variation", true)

	# ── Panel 2: On The Rulebook ──
	var rules_panel = _make_settings_panel("ON THE RULEBOOK")
	_content_vbox.add_child(rules_panel)
	var rules_vbox = rules_panel.get_child(0).get_child(0)

	_timer_option = _make_option_row(rules_vbox, "Turn Timer",
		["30 seconds", "60 seconds", "90 seconds", "120 seconds", "No Timer"])
	_timer_option.selected = 1

	_combat_option = _make_option_row(rules_vbox, "Combat Complexity",
		["Enhanced (Full)", "Simple (Beginner)"])

	_combat_speed_option = _make_option_row(rules_vbox, "Combat Speed",
		["0.5\u00d7 Slow", "1\u00d7 Normal", "1.5\u00d7 Fast", "2\u00d7 Very Fast"])
	_combat_speed_option.selected = 1

	_gold_option = _make_option_row(rules_vbox, "Starting Gold",
		["50 Gold", "100 Gold (Default)", "200 Gold", "500 Gold"])
	_gold_option.selected = 1

	# ── Panel 3: Advanced Mechanics ──
	var advanced_panel = _make_settings_panel("ADVANCED MECHANICS")
	_content_vbox.add_child(advanced_panel)
	var advanced_vbox = advanced_panel.get_child(0).get_child(0)

	_npc_toggle = _make_toggle_row(advanced_vbox, "NPC Encounters", true)
	_bounty_toggle = _make_toggle_row(advanced_vbox, "Aggression Bounty System", true)


# =============================================================================
# SETTINGS PANEL BUILDER
# =============================================================================

func _make_settings_panel(title: String) -> PanelContainer:
	var panel = PanelContainer.new()
	var style = _make_section_style()
	panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Panel title
	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(title_lbl, 16, UITheme.C_GOLD, true)
	vbox.add_child(title_lbl)

	vbox.add_child(UITheme.make_separator())

	return panel


func _make_section_style() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.07, 0.06, 0.85)
	s.border_color = UITheme.C_GOLD.darkened(0.5)
	s.set_border_width_all(1)
	s.set_corner_radius_all(8)
	return s


func _make_option_row(parent: VBoxContainer, label_text: String, options: Array) -> OptionButton:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	var lbl = Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(220, 0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UITheme.style_label(lbl, 14, UITheme.C_WARM_WHITE)
	row.add_child(lbl)

	var opt = OptionButton.new()
	opt.custom_minimum_size = Vector2(280, 36)
	for option_text in options:
		opt.add_item(option_text)
	UITheme.apply_dropdown(opt)
	row.add_child(opt)

	return opt


func _make_toggle_row(parent: VBoxContainer, label_text: String, default_on: bool) -> CheckButton:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	var lbl = Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(220, 0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UITheme.style_label(lbl, 14, UITheme.C_WARM_WHITE)
	row.add_child(lbl)

	var toggle = CheckButton.new()
	toggle.button_pressed = default_on
	toggle.text = "ON" if default_on else "OFF"
	var f = UITheme.font_regular()
	if f:
		toggle.add_theme_font_override("font", f)
	toggle.add_theme_font_size_override("font_size", 14)
	toggle.add_theme_color_override("font_color", UITheme.C_WARM_WHITE)
	toggle.toggled.connect(func(on: bool): toggle.text = "ON" if on else "OFF")
	row.add_child(toggle)

	return toggle


# =============================================================================
# START MATCH SECTION
# =============================================================================

func _build_start_section() -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	_content_vbox.add_child(spacer)

	# START MATCH button — primary CTA
	var start_btn = Button.new()
	start_btn.text = "START MATCH"
	start_btn.name = "StartMatchBtn"
	start_btn.custom_minimum_size = Vector2(UITheme.BTN_W, UITheme.BTN_H + 8)
	start_btn.pivot_offset = Vector2(UITheme.BTN_W * 0.5, (UITheme.BTN_H + 8) * 0.5)
	UITheme.apply_menu_button(start_btn, UITheme.BTN_FONT_SIZE + 2)
	start_btn.add_theme_color_override("font_color", UITheme.C_GOLD_BRIGHT)

	# Center the button
	var btn_center = HBoxContainer.new()
	btn_center.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_center.add_child(start_btn)
	_content_vbox.add_child(btn_center)

	start_btn.pressed.connect(_on_start_pressed)


# =============================================================================
# SETTINGS GATHERING
# =============================================================================

func _gather_settings() -> Dictionary:
	var timer_values = [30, 60, 90, 120, 0]
	var speed_values = [0.5, 1.0, 1.5, 2.0]
	var gold_values = [50, 100, 200, 500]

	return {
		"custom_mode": true,
		"environment": _environment_option.selected if _environment_option else 0,
		"terrain_height": _terrain_toggle.button_pressed if _terrain_toggle else true,
		"turn_timer": timer_values[_timer_option.selected] if _timer_option else 60,
		"combat_mode": _combat_option.selected if _combat_option else 0,
		"combat_speed": speed_values[_combat_speed_option.selected] if _combat_speed_option else 1.0,
		"starting_gold": gold_values[_gold_option.selected] if _gold_option else 100,
		"npc_activity": _npc_toggle.button_pressed if _npc_toggle else true,
		"bounty_system": _bounty_toggle.button_pressed if _bounty_toggle else true,
	}


# =============================================================================
# CALLBACKS
# =============================================================================

func _on_start_pressed() -> void:
	var settings = _gather_settings()
	start_match.emit(settings)

func _on_back_pressed() -> void:
	back_pressed.emit()
