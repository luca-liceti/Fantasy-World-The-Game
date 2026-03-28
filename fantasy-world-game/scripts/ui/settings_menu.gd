## Settings Menu — Fantasy World
## Full-screen settings overlay. Sits on CanvasLayer 20 over the revolving
## background. Title tab row matches the UI template (VIDEO / AUDIO /
## CONTROLS / GAMEPLAY). All styling via UITheme.
class_name SettingsMenu
extends CanvasLayer

# =============================================================================
# SIGNALS
# =============================================================================
signal closed
signal settings_applied

# =============================================================================
# GEOMETRY (from UITheme geometry standard — multiples of 8 px)
# =============================================================================
const TAB_W   = 180   # px per tab button
const TAB_H   = 48
const PANEL_W = 900   # inner content panel
const PANEL_H = 520

# =============================================================================
# TAB DEFINITIONS  (no emoji — labels match the UI template)
# =============================================================================
const TABS: Array[String] = ["VIDEO", "AUDIO", "CONTROLS", "GAMEPLAY"]

# =============================================================================
# NODES
# =============================================================================
var _root:            Control        = null
var _tab_buttons:     Dictionary     = {}   # tab_id -> Button
var _content_vbox:    VBoxContainer  = null
var _apply_btn:       Button         = null
var _current_tab:     String         = "VIDEO"
var _setting_ctrls:   Dictionary     = {}
var _pending:         Dictionary     = {}

var _is_showing_confirm: bool = false


# =============================================================================
# READY
# =============================================================================

func _ready() -> void:
	layer = 20
	_build_ui()
	_switch_tab("VIDEO")
	_animate_in()


# =============================================================================
# TOP-LEVEL UI BUILD
# =============================================================================

func _build_ui() -> void:
	# Full-screen root
	_root = Control.new()
	_root.name = "SettingsRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# Dark scrim for legibility over the revolving backgrounds
	var scrim = ColorRect.new()
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.0, 0.0, 0.0, 0.55)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(scrim)

	# Logo
	var sub_logo_scale = 0.50
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

	# Page title
	var title_top = lh + 32.0
	var title = Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.custom_minimum_size = Vector2(700, 56)
	title.position = Vector2(-350, title_top)
	UITheme.style_label(title, UITheme.TITLE_FONT, UITheme.C_GOLD, true)
	_root.add_child(title)

	# Separator under title
	var sep = UITheme.make_separator()
	sep.set_anchors_preset(Control.PRESET_CENTER_TOP)
	sep.custom_minimum_size = Vector2(640, 4)
	sep.position = Vector2(-320, title_top + 60)
	_root.add_child(sep)

	# Tab row
	var tab_top = title_top + 68.0
	_build_tab_row(tab_top)

	# Content panel
	var panel_top = tab_top + TAB_H + 4.0
	_build_content_panel(panel_top)

	# Footer (Apply Changes button)
	_build_footer()

	# BACK / close button — bottom left
	var back = Button.new()
	back.name = "BackBtn"
	back.text = "BACK"
	back.custom_minimum_size = Vector2(UITheme.BTN_SM_W, UITheme.BTN_SM_H)
	back.pivot_offset = Vector2(UITheme.BTN_SM_W * 0.5, UITheme.BTN_SM_H * 0.5)
	back.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	back.position = Vector2(UITheme.PAD * 2, -(UITheme.BTN_SM_H + UITheme.PAD * 2))
	UITheme.apply_menu_button(back, UITheme.BTN_SM_FONT)
	back.pressed.connect(_on_close_pressed)
	back.button_down.connect(func(): _btn_press_anim(back))
	back.button_up.connect(func(): _btn_release_anim(back))
	_root.add_child(back)




func _build_tab_row(top_y: float) -> void:
	var total_w = TABS.size() * TAB_W + (TABS.size() - 1) * 4
	var row = HBoxContainer.new()
	row.name = "TabRow"
	row.set_anchors_preset(Control.PRESET_CENTER_TOP)
	row.custom_minimum_size = Vector2(total_w, TAB_H)
	row.position = Vector2(-total_w * 0.5, top_y)
	row.add_theme_constant_override("separation", 4)
	_root.add_child(row)

	for tab_id in TABS:
		var btn = Button.new()
		btn.name = tab_id + "Tab"
		btn.text = tab_id
		btn.custom_minimum_size = Vector2(TAB_W, TAB_H)
		btn.pivot_offset = Vector2(TAB_W * 0.5, TAB_H * 0.5)
		UITheme.apply_menu_button(btn, UITheme.BTN_SM_FONT)
		btn.pressed.connect(_switch_tab.bind(tab_id))
		row.add_child(btn)
		_tab_buttons[tab_id] = btn


func _build_content_panel(top_y: float) -> void:
	var panel = PanelContainer.new()
	panel.name = "ContentPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.custom_minimum_size = Vector2(PANEL_W, PANEL_H)
	panel.position = Vector2(-PANEL_W * 0.5, top_y)
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


func _build_footer() -> void:
	_apply_btn = Button.new()
	_apply_btn.name = "ApplyBtn"
	_apply_btn.text = "APPLY CHANGES"
	_apply_btn.custom_minimum_size = Vector2(280, UITheme.BTN_SM_H)
	_apply_btn.pivot_offset = Vector2(140, UITheme.BTN_SM_H * 0.5)
	_apply_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_apply_btn.position = Vector2(-140, -(UITheme.BTN_SM_H + UITheme.PAD * 2))
	UITheme.apply_menu_button(_apply_btn, UITheme.BTN_SM_FONT)
	_apply_btn.add_theme_color_override("font_color", UITheme.C_GOLD_BRIGHT)
	_apply_btn.pressed.connect(_on_apply_pressed)
	_apply_btn.button_down.connect(func(): _btn_press_anim(_apply_btn))
	_apply_btn.button_up.connect(func(): _btn_release_anim(_apply_btn))
	_root.add_child(_apply_btn)


# =============================================================================
# TAB SWITCHING
# =============================================================================

func _switch_tab(tab_id: String) -> void:
	_current_tab = tab_id

	# Update tab button styles — active tab uses hover (gold) texture
	for id in _tab_buttons:
		var btn: Button = _tab_buttons[id]
		if id == tab_id:
			btn.add_theme_stylebox_override("normal",  UITheme.btn_hover())
			btn.add_theme_color_override("font_color", UITheme.C_GOLD_BRIGHT)
		else:
			btn.add_theme_stylebox_override("normal",  UITheme.btn_normal())
			btn.add_theme_color_override("font_color", UITheme.C_WARM_WHITE)

	# Clear and rebuild content
	for child in _content_vbox.get_children():
		child.queue_free()
	_setting_ctrls.clear()

	match tab_id:
		"VIDEO":      _build_video_tab()
		"AUDIO":      _build_audio_tab()
		"CONTROLS":   _build_controls_tab()
		"GAMEPLAY":   _build_gameplay_tab()


# =============================================================================
# TAB CONTENT BUILDERS
# =============================================================================

func _build_video_tab() -> void:
	_add_section("Display")
	_add_dropdown("graphics/display_mode", "WINDOW MODE",
			["Windowed", "Borderless Fullscreen", "Fullscreen"])

	var res_names = ["1280x720", "1920x1080", "2560x1440", "3840x2160"]
	if SettingsManager:
		var rn = SettingsManager.get_resolution_names()
		if not rn.is_empty():
			res_names = rn
	_add_dropdown("graphics/resolution_index", "RESOLUTION", res_names)
	_add_toggle("graphics/vsync",        "VSYNC")

	_add_section("Quality")
	_add_dropdown("graphics/quality_preset", "QUALITY PRESET",
			["Low", "Medium", "High", "Ultra"])
	_add_section("Advanced Graphics")
	_add_dropdown("graphics/msaa",        "ANTI-ALIASING",
			["Off", "FXAA", "TAA", "MSAA 2x", "MSAA 4x", "MSAA 8x"])
	_add_dropdown("graphics/shadow_quality", "SHADOW QUALITY",
			["Off", "Low", "Medium", "High"])
	_add_toggle("graphics/ambient_occlusion", "AMBIENT OCCLUSION")
	_add_toggle("graphics/bloom",             "BLOOM EFFECTS")
	_add_slider("graphics/particle_effects",  "PARTICLE EFFECTS", 25, 100, 25, "%")
	_add_toggle("graphics/terrain_height",    "TERRAIN HEIGHT VARIATION")
	_add_toggle("graphics/camera_shake",      "CAMERA SHAKE")
	_add_dropdown("graphics/fps_limit",       "FPS LIMIT",
			["Unlimited", "30", "60", "120", "144"])


func _build_audio_tab() -> void:
	_add_section("Volume Controls")
	_add_slider("audio/master_volume", "MASTER VOLUME", 0, 100, 1, "%")
	_add_slider("audio/music_volume",  "MUSIC VOLUME",  0, 100, 1, "%")
	_add_slider("audio/sfx_volume",    "SFX VOLUME",    0, 100, 1, "%")
	_add_slider("audio/voice_volume",  "VOICE VOLUME",  0, 100, 1, "%")
	_add_section("Options")
	_add_toggle("audio/mute_when_unfocused", "MUTE WHEN UNFOCUSED")


func _build_controls_tab() -> void:
	_add_section("Camera")
	_add_slider("controls/camera_sensitivity", "CAMERA SENSITIVITY", 10, 100, 5, "%")
	_add_toggle("controls/invert_camera_y",    "INVERT CAMERA Y-AXIS")
	_add_toggle("controls/edge_pan_enabled",   "EDGE PANNING")
	_add_slider("controls/edge_pan_speed",     "EDGE PAN SPEED", 10, 100, 5, "%")
	_add_section("Interface")
	_add_toggle("controls/show_tile_coordinates", "SHOW TILE COORDINATES")
	_add_toggle("controls/confirm_end_turn",      "CONFIRM BEFORE ENDING TURN")
	_add_section("Keybindings")
	_add_info("Keybinding customisation coming soon.")


func _build_gameplay_tab() -> void:
	_add_section("Turn Behaviour")
	_add_toggle("gameplay/auto_end_turn", "AUTO-END TURN WHEN NO ACTIONS")
	_add_section("Combat Visuals")
	_add_toggle("gameplay/show_damage_numbers",     "SHOW DAMAGE NUMBERS")
	_add_toggle("gameplay/show_combat_animations",  "SHOW COMBAT ANIMATIONS")
	_add_section("Information")
	_add_toggle("gameplay/show_biome_tooltips",    "SHOW BIOME TOOLTIPS")
	_add_toggle("gameplay/show_contextual_hints",  "SHOW CONTEXTUAL HINTS")
	_add_section("AI")
	_add_dropdown("gameplay/ai_difficulty", "AI LEVEL", ["Easy", "Normal", "Hard"])
	_add_toggle("gameplay/smooth_zoom", "SMOOTH SCROLLING ZOOM")


# =============================================================================
# SETTING CONTROL BUILDERS
# =============================================================================

func _add_section(title: String) -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	_content_vbox.add_child(spacer)

	var lbl = Label.new()
	lbl.text = title.to_upper()
	UITheme.style_label(lbl, 13, UITheme.C_GOLD, true)
	_content_vbox.add_child(lbl)

	_content_vbox.add_child(UITheme.make_separator())


func _add_slider(path: String, label_text: String,
		min_val: float, max_val: float, step: float, suffix: String = "") -> void:
	var row = _make_row(label_text)

	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	row.add_child(hb)

	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step      = step
	slider.custom_minimum_size = Vector2(220, 24)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cur = _get_val(path)
	slider.value = cur if cur != null else min_val
	hb.add_child(slider)

	var val_lbl = Label.new()
	val_lbl.custom_minimum_size = Vector2(64, 0)
	val_lbl.text = str(int(slider.value)) + suffix
	UITheme.style_label(val_lbl, UITheme.INPUT_FONT, UITheme.C_WARM_WHITE)
	hb.add_child(val_lbl)

	slider.value_changed.connect(func(v):
		val_lbl.text = str(int(v)) + suffix
		_on_changed(path, v)
	)

	_setting_ctrls[path] = slider
	_content_vbox.add_child(row)


func _add_toggle(path: String, label_text: String) -> void:
	var row = _make_row(label_text)

	var toggle = CheckButton.new()
	toggle.text = ""
	var cur = _get_val(path)
	toggle.button_pressed = cur if cur != null else false
	toggle.toggled.connect(func(v): _on_changed(path, v))

	row.add_child(toggle)
	_setting_ctrls[path] = toggle
	_content_vbox.add_child(row)


func _add_dropdown(path: String, label_text: String, options: Array) -> void:
	var row = _make_row(label_text)

	var opt = OptionButton.new()
	opt.custom_minimum_size = Vector2(240, UITheme.INPUT_H)
	for i in range(options.size()):
		opt.add_item(str(options[i]), i)

	var cur = _get_val(path)
	var idx = _resolve_dropdown_index(path, cur)
	if idx >= 0 and idx < options.size():
		opt.select(idx)

	UITheme.apply_dropdown(opt, UITheme.INPUT_FONT)
	opt.item_selected.connect(func(i): _on_changed(path, _convert_dropdown(path, i)))

	row.add_child(opt)
	_setting_ctrls[path] = opt
	_content_vbox.add_child(row)


func _add_info(text: String) -> void:
	var lbl = Label.new()
	lbl.text = text
	UITheme.style_label(lbl, 14, UITheme.C_DIM)
	_content_vbox.add_child(lbl)


func _make_row(label_text: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)

	var lbl = Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.style_label(lbl, UITheme.INPUT_FONT, UITheme.C_WARM_WHITE)
	row.add_child(lbl)

	return row


# =============================================================================
# SETTING VALUE HELPERS
# =============================================================================

func _get_val(path: String) -> Variant:
	if SettingsManager:
		return SettingsManager.get_setting(path)
	return null

func _on_changed(path: String, value: Variant) -> void:
	_pending[path] = value
	if SettingsManager:
		SettingsManager.set_setting(path, value, false)

func _resolve_dropdown_index(path: String, cur) -> int:
	match path:
		"gameplay/turn_timer":
			match cur:
				60:  return 0
				120: return 1
				180: return 2
				300: return 3
				_:   return 1
		"gameplay/combat_speed":
			match cur:
				0.5: return 0
				1.0: return 1
				1.5: return 2
				2.0: return 3
				_:   return 1
		"graphics/fps_limit":
			match cur:
				0:   return 0
				30:  return 1
				60:  return 2
				120: return 3
				144: return 4
				_:   return 0
		_:
			if cur == null:
				return 0
			return int(cur)

func _convert_dropdown(path: String, idx: int) -> Variant:
	match path:
		"gameplay/turn_timer":   return [60, 120, 180, 300][idx]
		"gameplay/combat_speed": return [0.5, 1.0, 1.5, 2.0][idx]
		"graphics/fps_limit":    return [0, 30, 60, 120, 144][idx]
		_:                       return idx


# =============================================================================
# CALLBACKS
# =============================================================================

func _on_apply_pressed() -> void:
	if SettingsManager:
		SettingsManager.save_settings()
	_pending.clear()
	settings_applied.emit()
	_close()

func _on_close_pressed() -> void:
	if _pending.size() > 0:
		_show_discard_confirm()
	else:
		_close()

func _discard_changes() -> void:
	if SettingsManager:
		SettingsManager.discard_changes()
	_close()

func _show_discard_confirm() -> void:
	var confirm_layer = CanvasLayer.new()
	confirm_layer.layer = 150
	confirm_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = UITheme.C_OVERLAY_DIM
	confirm_layer.add_child(bg)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	confirm_layer.add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 240)
	panel.add_theme_stylebox_override("panel", UITheme.overlay_panel(UITheme.C_GOLD))
	center.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "DISCARD CHANGES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(title, 24, UITheme.C_GOLD, true)
	vbox.add_child(title)
	
	var msg = Label.new()
	msg.text = "Are you sure you want to discard your unsaved changes?"
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.style_label(msg, 16, UITheme.C_WARM_WHITE)
	vbox.add_child(msg)
	
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 24)
	vbox.add_child(btn_row)
	
	var yes_btn = Button.new()
	yes_btn.text = "YES"
	yes_btn.custom_minimum_size = Vector2(160, 50)
	yes_btn.pivot_offset = Vector2(80, 25)
	yes_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	UITheme.apply_menu_button(yes_btn, 18)
	yes_btn.pressed.connect(func():
		_is_showing_confirm = false
		confirm_layer.queue_free()
		_discard_changes()
	)
	btn_row.add_child(yes_btn)
	
	var no_btn = Button.new()
	no_btn.text = "NO"
	no_btn.custom_minimum_size = Vector2(160, 50)
	no_btn.pivot_offset = Vector2(80, 25)
	no_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	UITheme.apply_menu_button(no_btn, 18)
	no_btn.pressed.connect(func():
		_is_showing_confirm = false
		confirm_layer.queue_free()
	)
	btn_row.add_child(no_btn)
	
	_is_showing_confirm = true
	add_child(confirm_layer)

func _close() -> void:
	_animate_out()


# =============================================================================
# ANIMATIONS
# =============================================================================

func _animate_in() -> void:
	if _root:
		_root.modulate.a = 0.0
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_root, "modulate:a", 1.0, 0.30)

func _animate_out() -> void:
	var tw = create_tween()
	tw.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_root, "modulate:a", 0.0, 0.22)
	tw.tween_callback(func():
		closed.emit()
		queue_free()
	)

## Press: shrink button like a real button being pushed
func _btn_press_anim(btn: Button) -> void:
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.08)

## Release: pop back to normal size
func _btn_release_anim(btn: Button) -> void:
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12)


# =============================================================================
# INPUT
# =============================================================================

func _input(event: InputEvent) -> void:
	if _is_showing_confirm:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_close_pressed()
			get_viewport().set_input_as_handled()
