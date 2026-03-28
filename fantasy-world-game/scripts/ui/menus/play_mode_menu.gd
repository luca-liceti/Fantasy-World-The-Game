## Play Menu — Fantasy World
## Sub-screen opened from PLAY on the main menu.
## Lets the player choose between Quick Play, Custom Match, VS Bot (future),
## Story Mode (future), and view Achievements.
## Uses UITheme for consistent medieval styling.
class_name PlayModeMenu
extends CanvasLayer

# =============================================================================
# SIGNALS
# =============================================================================
signal quick_play_pressed
signal custom_match_pressed
signal achievements_pressed
signal back_pressed

# =============================================================================
# UI ELEMENTS
# =============================================================================
var _root: Control = null


# =============================================================================
# READY
# =============================================================================

func _ready() -> void:
	_build_ui()


# =============================================================================
# BUILD UI
# =============================================================================

func _build_ui() -> void:
	# Root control fills the screen
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

	# ── Sub-logo (top centre, 50 % of full logo) ──
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
	title_lbl.text = "PLAY"
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
	var panel_w = 560
	var panel_h = 520
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

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	scroll.add_child(vbox)

	# ── Subtitle ──
	var subtitle = Label.new()
	subtitle.text = "Choose your play mode"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(subtitle, 18, UITheme.C_WARM_WHITE)
	vbox.add_child(subtitle)

	var spacer_top = Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(spacer_top)

	# ── QUICK PLAY BUTTON ──
	var quick_btn = _make_mode_button(
		"QUICK PLAY",
		"Jump straight in with standard rules and a random map.",
		true)
	quick_btn.pressed.connect(_on_quick_play_pressed)
	vbox.add_child(quick_btn)

	# ── CUSTOM MATCH BUTTON ──
	var custom_btn = _make_mode_button(
		"CUSTOM MATCH",
		"Configure world, rules, and mechanics to your liking.",
		true)
	custom_btn.pressed.connect(_on_custom_match_pressed)
	vbox.add_child(custom_btn)

	# ── VS BOT / AI  (COMING SOON) ──
	var bot_btn = _make_mode_button(
		"VS BOT / AI",
		"Play against the computer with varying difficulties.\n(Coming Soon)",
		false)
	bot_btn.disabled = true
	vbox.add_child(bot_btn)

	# ── STORY MODE  (COMING SOON) ──
	var story_btn = _make_mode_button(
		"STORY MODE",
		"Embark on an epic single-player campaign.\n(Coming Soon)",
		false)
	story_btn.disabled = true
	vbox.add_child(story_btn)

	# ── Separator before achievements ──
	vbox.add_child(UITheme.make_separator())

	# ── ACHIEVEMENTS ──
	var achieve_btn = _make_mode_button(
		"ACHIEVEMENTS",
		"Track your milestones and accomplishments.",
		true)
	achieve_btn.pressed.connect(_on_achievements_pressed)
	vbox.add_child(achieve_btn)

	# ── BACK button (bottom-left) ──
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
# MODE BUTTON BUILDER
# =============================================================================

func _make_mode_button(title: String, desc: String, available: bool) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(460, 80)
	btn.clip_text = false
	btn.text = ""  # We'll use a child label instead for rich content
	btn.pivot_offset = Vector2(230, 40)

	# Apply UITheme banner textures
	UITheme.apply_menu_button(btn, UITheme.BTN_FONT_SIZE)

	if not available:
		btn.modulate = Color(0.6, 0.6, 0.6, 0.7)

	# Rich content container
	var content = VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 2)
	btn.add_child(content)

	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.style_label(title_lbl, 20, UITheme.C_GOLD_BRIGHT if available else UITheme.C_DIM, true)
	content.add_child(title_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = desc
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.style_label(desc_lbl, 12, UITheme.C_WARM_WHITE if available else UITheme.C_DIM)
	content.add_child(desc_lbl)

	return btn


# =============================================================================
# CALLBACKS
# =============================================================================

func _on_quick_play_pressed() -> void:
	quick_play_pressed.emit()

func _on_custom_match_pressed() -> void:
	custom_match_pressed.emit()

func _on_achievements_pressed() -> void:
	achievements_pressed.emit()

func _on_back_pressed() -> void:
	back_pressed.emit()
