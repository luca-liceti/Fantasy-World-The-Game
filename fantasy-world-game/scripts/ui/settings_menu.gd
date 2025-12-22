## Settings Menu UI
## Tabbed settings interface accessible from start menu and in-game
## Features sections for Audio, Graphics, Controls, Gameplay, and Accessibility
class_name SettingsMenu
extends CanvasLayer

# =============================================================================
# SIGNALS
# =============================================================================
signal closed
signal settings_applied

# =============================================================================
# UI ELEMENTS
# =============================================================================
var overlay: ColorRect
var main_panel: PanelContainer
var header: HBoxContainer
var title_label: Label
var close_button: Button
var tab_container: HBoxContainer
var content_container: PanelContainer
var content_scroll: ScrollContainer
var content_vbox: VBoxContainer
var footer: HBoxContainer
var reset_button: Button
var apply_button: Button

# Tab buttons
var tabs: Dictionary = {}
var current_tab: String = "audio"

# Setting controls (for reading values)
var setting_controls: Dictionary = {}

# Pending changes (not yet applied)
var pending_changes: Dictionary = {}

# =============================================================================
# STYLING
# =============================================================================
const BG_OVERLAY = Color(0, 0, 0, 0.7)
const PANEL_BG = Color(0.08, 0.08, 0.12, 0.98)
const HEADER_BG = Color(0.12, 0.1, 0.18, 1.0)
const TAB_NORMAL = Color(0.15, 0.12, 0.2, 0.8)
const TAB_ACTIVE = Color(0.25, 0.2, 0.35, 1.0)
const TAB_HOVER = Color(0.2, 0.16, 0.28, 0.9)
const CONTENT_BG = Color(0.1, 0.1, 0.14, 1.0)
const ACCENT_COLOR = Color(0.4, 0.6, 1.0)
const TEXT_COLOR = Color(0.9, 0.9, 0.95)
const TEXT_DIM = Color(0.6, 0.6, 0.7)
const SECTION_COLOR = Color(0.7, 0.75, 0.9)

const TAB_ICONS: Dictionary = {
	"audio": "🔊",
	"graphics": "🖥️",
	"controls": "🎮",
	"gameplay": "⚔️",
	"accessibility": "♿"
}

const TAB_NAMES: Dictionary = {
	"audio": "Audio",
	"graphics": "Graphics",
	"controls": "Controls",
	"gameplay": "Gameplay",
	"accessibility": "Accessibility"
}


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	layer = 100 # Ensure it's on top
	_create_ui()
	_switch_tab("audio")
	_play_open_animation()


func _create_ui() -> void:
	# Dark overlay
	overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = BG_OVERLAY
	overlay.modulate.a = 0
	add_child(overlay)
	
	# Main panel
	main_panel = PanelContainer.new()
	main_panel.set_anchors_preset(Control.PRESET_CENTER)
	main_panel.custom_minimum_size = Vector2(900, 650)
	main_panel.position = Vector2(-450, -325)
	main_panel.modulate.a = 0
	add_child(main_panel)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = PANEL_BG
	panel_style.set_corner_radius_all(16)
	panel_style.set_border_width_all(2)
	panel_style.border_color = ACCENT_COLOR.darkened(0.5)
	main_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Main layout
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 0)
	main_panel.add_child(main_vbox)
	
	_create_header(main_vbox)
	_create_tabs(main_vbox)
	_create_content_area(main_vbox)
	_create_footer(main_vbox)


func _create_header(parent: VBoxContainer) -> void:
	var header_panel = PanelContainer.new()
	header_panel.custom_minimum_size = Vector2(0, 60)
	parent.add_child(header_panel)
	
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = HEADER_BG
	header_style.corner_radius_top_left = 14
	header_style.corner_radius_top_right = 14
	header_panel.add_theme_stylebox_override("panel", header_style)
	
	header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	header_panel.add_child(header)
	
	# Spacer
	var left_margin = Control.new()
	left_margin.custom_minimum_size = Vector2(20, 0)
	header.add_child(left_margin)
	
	# Title
	title_label = Label.new()
	title_label.text = "⚙️  SETTINGS"
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", TEXT_COLOR)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title_label)
	
	# Close button
	close_button = Button.new()
	close_button.text = "✕"
	close_button.custom_minimum_size = Vector2(50, 50)
	close_button.add_theme_font_size_override("font_size", 24)
	close_button.pressed.connect(_on_close_pressed)
	header.add_child(close_button)
	
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = Color(0.5, 0.2, 0.2, 0.5)
	close_style.set_corner_radius_all(8)
	close_button.add_theme_stylebox_override("normal", close_style)
	
	var close_hover = StyleBoxFlat.new()
	close_hover.bg_color = Color(0.7, 0.3, 0.3, 0.8)
	close_hover.set_corner_radius_all(8)
	close_button.add_theme_stylebox_override("hover", close_hover)
	
	# Right margin
	var right_margin = Control.new()
	right_margin.custom_minimum_size = Vector2(10, 0)
	header.add_child(right_margin)


func _create_tabs(parent: VBoxContainer) -> void:
	tab_container = HBoxContainer.new()
	tab_container.custom_minimum_size = Vector2(0, 50)
	tab_container.add_theme_constant_override("separation", 5)
	tab_container.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(tab_container)
	
	# Left margin
	var margin = Control.new()
	margin.custom_minimum_size = Vector2(20, 0)
	tab_container.add_child(margin)
	
	for tab_id in ["audio", "graphics", "controls", "gameplay", "accessibility"]:
		var tab_btn = _create_tab_button(tab_id)
		tabs[tab_id] = tab_btn
		tab_container.add_child(tab_btn)
	
	# Right margin
	var margin2 = Control.new()
	margin2.custom_minimum_size = Vector2(20, 0)
	tab_container.add_child(margin2)


func _create_tab_button(tab_id: String) -> Button:
	var button = Button.new()
	button.text = TAB_ICONS[tab_id] + "  " + TAB_NAMES[tab_id]
	button.custom_minimum_size = Vector2(140, 40)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.pressed.connect(_switch_tab.bind(tab_id))
	
	_apply_tab_style(button, false)
	
	return button


func _apply_tab_style(button: Button, active: bool) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = TAB_ACTIVE if active else TAB_NORMAL
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	if active:
		style.border_color = ACCENT_COLOR
		style.border_width_bottom = 3
	button.add_theme_stylebox_override("normal", style)
	
	var hover = StyleBoxFlat.new()
	hover.bg_color = TAB_ACTIVE if active else TAB_HOVER
	hover.corner_radius_top_left = 8
	hover.corner_radius_top_right = 8
	if active:
		hover.border_color = ACCENT_COLOR
		hover.border_width_bottom = 3
	button.add_theme_stylebox_override("hover", hover)


func _create_content_area(parent: VBoxContainer) -> void:
	content_container = PanelContainer.new()
	content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(content_container)
	
	var content_style = StyleBoxFlat.new()
	content_style.bg_color = CONTENT_BG
	content_style.content_margin_left = 30
	content_style.content_margin_right = 30
	content_style.content_margin_top = 20
	content_style.content_margin_bottom = 20
	content_container.add_theme_stylebox_override("panel", content_style)
	
	content_scroll = ScrollContainer.new()
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_container.add_child(content_scroll)
	
	content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 15)
	content_scroll.add_child(content_vbox)


func _create_footer(parent: VBoxContainer) -> void:
	var footer_panel = PanelContainer.new()
	footer_panel.custom_minimum_size = Vector2(0, 60)
	parent.add_child(footer_panel)
	
	var footer_style = StyleBoxFlat.new()
	footer_style.bg_color = HEADER_BG
	footer_style.corner_radius_bottom_left = 14
	footer_style.corner_radius_bottom_right = 14
	footer_panel.add_theme_stylebox_override("panel", footer_style)
	
	footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 15)
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer_panel.add_child(footer)
	
	# Reset section button
	reset_button = _create_footer_button("Reset Section", Color(0.6, 0.5, 0.3))
	reset_button.pressed.connect(_on_reset_section)
	footer.add_child(reset_button)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	
	# Apply button
	apply_button = _create_footer_button("Apply & Close", ACCENT_COLOR)
	apply_button.pressed.connect(_on_apply_pressed)
	footer.add_child(apply_button)
	
	# Right margin
	var margin = Control.new()
	margin.custom_minimum_size = Vector2(20, 0)
	footer.add_child(margin)


func _create_footer_button(text: String, color: Color) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(140, 40)
	button.add_theme_font_size_override("font_size", 16)
	
	var style = StyleBoxFlat.new()
	style.bg_color = color.darkened(0.5)
	style.set_corner_radius_all(8)
	style.set_border_width_all(2)
	style.border_color = color.darkened(0.3)
	button.add_theme_stylebox_override("normal", style)
	
	var hover = StyleBoxFlat.new()
	hover.bg_color = color.darkened(0.3)
	hover.set_corner_radius_all(8)
	hover.set_border_width_all(2)
	hover.border_color = color
	button.add_theme_stylebox_override("hover", hover)
	
	return button


# =============================================================================
# TAB SWITCHING
# =============================================================================

func _switch_tab(tab_id: String) -> void:
	current_tab = tab_id
	
	# Update tab button styles
	for id in tabs.keys():
		_apply_tab_style(tabs[id], id == tab_id)
	
	# Clear content
	for child in content_vbox.get_children():
		child.queue_free()
	setting_controls.clear()
	
	# Populate new content
	match tab_id:
		"audio":
			_create_audio_settings()
		"graphics":
			_create_graphics_settings()
		"controls":
			_create_controls_settings()
		"gameplay":
			_create_gameplay_settings()
		"accessibility":
			_create_accessibility_settings()


# =============================================================================
# AUDIO SETTINGS
# =============================================================================

func _create_audio_settings() -> void:
	_add_section_header("Volume Controls")
	_add_slider("audio/master_volume", "Master Volume", 0, 100, 1, "%")
	_add_slider("audio/music_volume", "Music Volume", 0, 100, 1, "%")
	_add_slider("audio/sfx_volume", "Sound Effects", 0, 100, 1, "%")
	_add_slider("audio/voice_volume", "Voice Volume", 0, 100, 1, "%")
	
	_add_section_header("Audio Options")
	_add_toggle("audio/mute_when_unfocused", "Mute When Game Unfocused")


# =============================================================================
# GRAPHICS SETTINGS
# =============================================================================

func _create_graphics_settings() -> void:
	_add_section_header("Display")
	_add_dropdown("graphics/display_mode", "Display Mode", ["Windowed", "Borderless", "Fullscreen"])
	
	var res_names = SettingsManager.get_resolution_names() if SettingsManager else ["1920x1080", "2560x1440", "3840x2160"]
	_add_dropdown("graphics/resolution_index", "Resolution", res_names)
	
	_add_toggle("graphics/vsync", "VSync")
	_add_dropdown("graphics/fps_limit", "FPS Limit", ["Unlimited", "30", "60", "120", "144"])
	
	_add_section_header("Quality")
	_add_dropdown("graphics/msaa", "Anti-Aliasing (MSAA)", ["Off", "2x", "4x", "8x"])
	_add_dropdown("graphics/shadow_quality", "Shadow Quality", ["Off", "Low", "Medium", "High"])
	_add_toggle("graphics/ambient_occlusion", "Ambient Occlusion")
	_add_toggle("graphics/bloom", "Bloom Effects")
	
	_add_section_header("Effects")
	_add_toggle("graphics/camera_shake", "Camera Shake")


# =============================================================================
# CONTROLS SETTINGS
# =============================================================================

func _create_controls_settings() -> void:
	_add_section_header("Camera")
	_add_slider("controls/camera_sensitivity", "Camera Sensitivity", 10, 100, 5, "%")
	_add_toggle("controls/invert_camera_y", "Invert Camera Y-Axis")
	_add_toggle("controls/edge_pan_enabled", "Edge Panning")
	_add_slider("controls/edge_pan_speed", "Edge Pan Speed", 10, 100, 5, "%")
	
	_add_section_header("Interface")
	_add_toggle("controls/show_tile_coordinates", "Show Tile Coordinates")
	_add_toggle("controls/confirm_end_turn", "Confirm Before Ending Turn")
	
	_add_section_header("Keybindings")
	_add_info_label("Keybinding customization coming soon!")


# =============================================================================
# GAMEPLAY SETTINGS
# =============================================================================

func _create_gameplay_settings() -> void:
	_add_section_header("Turn Settings")
	_add_dropdown("gameplay/turn_timer", "Turn Timer", ["1 Minute", "2 Minutes", "3 Minutes", "5 Minutes"])
	_add_toggle("gameplay/auto_end_turn", "Auto-End Turn When No Actions")
	
	_add_section_header("Combat")
	_add_toggle("gameplay/show_damage_numbers", "Show Damage Numbers")
	_add_toggle("gameplay/show_combat_animations", "Show Combat Animations")
	_add_dropdown("gameplay/combat_speed", "Combat Speed", ["0.5x (Slow)", "1x (Normal)", "1.5x (Fast)", "2x (Very Fast)"])
	
	_add_section_header("Information")
	_add_toggle("gameplay/show_biome_tooltips", "Show Biome Tooltips")


# =============================================================================
# ACCESSIBILITY SETTINGS
# =============================================================================

func _create_accessibility_settings() -> void:
	_add_section_header("Visual")
	_add_dropdown("accessibility/text_size", "Text Size", ["Small (80%)", "Normal (100%)", "Large (120%)", "Extra Large (140%)"])
	_add_toggle("accessibility/high_contrast", "High Contrast Mode")
	_add_dropdown("accessibility/colorblind_mode", "Colorblind Mode", ["Off", "Protanopia", "Deuteranopia", "Tritanopia"])
	
	_add_section_header("Motion")
	_add_toggle("accessibility/reduce_motion", "Reduce Motion & Animations")
	
	_add_section_header("Assistance")
	_add_toggle("accessibility/screen_reader_hints", "Screen Reader Hints")


# =============================================================================
# SETTING CONTROL BUILDERS
# =============================================================================

func _add_section_header(text: String) -> void:
	var label = Label.new()
	label.text = text.to_upper()
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", SECTION_COLOR)
	content_vbox.add_child(label)
	
	var separator = HSeparator.new()
	separator.add_theme_stylebox_override("separator", StyleBoxFlat.new())
	separator.add_theme_constant_override("separation", 10)
	content_vbox.add_child(separator)


func _add_slider(setting_path: String, label_text: String, min_val: float, max_val: float, step: float, suffix: String = "") -> void:
	var row = _create_setting_row(label_text)
	
	var slider_container = HBoxContainer.new()
	slider_container.add_theme_constant_override("separation", 15)
	row.add_child(slider_container)
	
	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = step
	slider.custom_minimum_size = Vector2(200, 20)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Get current value
	var current_value = _get_setting_value(setting_path)
	slider.value = current_value if current_value != null else min_val
	
	slider_container.add_child(slider)
	
	# Value label
	var value_label = Label.new()
	value_label.custom_minimum_size = Vector2(60, 0)
	value_label.text = str(int(slider.value)) + suffix
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.add_theme_color_override("font_color", TEXT_COLOR)
	slider_container.add_child(value_label)
	
	# Update label when slider changes
	slider.value_changed.connect(func(val):
		value_label.text = str(int(val)) + suffix
		_on_setting_changed(setting_path, val)
	)
	
	setting_controls[setting_path] = slider
	content_vbox.add_child(row)


func _add_toggle(setting_path: String, label_text: String) -> void:
	var row = _create_setting_row(label_text)
	
	var toggle = CheckButton.new()
	toggle.text = ""
	
	var current_value = _get_setting_value(setting_path)
	toggle.button_pressed = current_value if current_value != null else false
	
	toggle.toggled.connect(func(pressed):
		_on_setting_changed(setting_path, pressed)
	)
	
	row.add_child(toggle)
	setting_controls[setting_path] = toggle
	content_vbox.add_child(row)


func _add_dropdown(setting_path: String, label_text: String, options: Array) -> void:
	var row = _create_setting_row(label_text)
	
	var dropdown = OptionButton.new()
	dropdown.custom_minimum_size = Vector2(200, 35)
	dropdown.add_theme_font_size_override("font_size", 14)
	
	for i in range(options.size()):
		dropdown.add_item(str(options[i]), i)
	
	var current_value = _get_setting_value(setting_path)
	
	# Handle special cases for turn_timer and combat_speed
	if setting_path == "gameplay/turn_timer":
		match current_value:
			60: dropdown.select(0)
			120: dropdown.select(1)
			180: dropdown.select(2)
			300: dropdown.select(3)
			_: dropdown.select(1)
	elif setting_path == "gameplay/combat_speed":
		match current_value:
			0.5: dropdown.select(0)
			1.0: dropdown.select(1)
			1.5: dropdown.select(2)
			2.0: dropdown.select(3)
			_: dropdown.select(1)
	elif setting_path == "accessibility/text_size":
		match current_value:
			0.8: dropdown.select(0)
			1.0: dropdown.select(1)
			1.2: dropdown.select(2)
			1.4: dropdown.select(3)
			_: dropdown.select(1)
	elif setting_path == "graphics/fps_limit":
		match current_value:
			0: dropdown.select(0)
			30: dropdown.select(1)
			60: dropdown.select(2)
			120: dropdown.select(3)
			144: dropdown.select(4)
			_: dropdown.select(0)
	else:
		var idx = current_value if current_value != null else 0
		if idx >= 0 and idx < options.size():
			dropdown.select(idx)
	
	dropdown.item_selected.connect(func(idx):
		var value = _convert_dropdown_value(setting_path, idx)
		_on_setting_changed(setting_path, value)
	)
	
	row.add_child(dropdown)
	setting_controls[setting_path] = dropdown
	content_vbox.add_child(row)


func _convert_dropdown_value(setting_path: String, idx: int) -> Variant:
	match setting_path:
		"gameplay/turn_timer":
			return [60, 120, 180, 300][idx]
		"gameplay/combat_speed":
			return [0.5, 1.0, 1.5, 2.0][idx]
		"accessibility/text_size":
			return [0.8, 1.0, 1.2, 1.4][idx]
		"graphics/fps_limit":
			return [0, 30, 60, 120, 144][idx]
		_:
			return idx


func _add_info_label(text: String) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", TEXT_DIM)
	label.add_theme_constant_override("line_spacing", 5)
	content_vbox.add_child(label)


func _create_setting_row(label_text: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	
	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	
	return row


func _get_setting_value(path: String) -> Variant:
	if SettingsManager:
		return SettingsManager.get_setting(path)
	return null


func _on_setting_changed(path: String, value: Variant) -> void:
	pending_changes[path] = value
	# Apply immediately for preview
	if SettingsManager:
		SettingsManager.set_setting(path, value, false)


# =============================================================================
# CALLBACKS
# =============================================================================

func _on_close_pressed() -> void:
	_play_close_animation()


func _on_apply_pressed() -> void:
	# Save all settings
	if SettingsManager:
		SettingsManager.save_settings()
	settings_applied.emit()
	_play_close_animation()


func _on_reset_section() -> void:
	if SettingsManager:
		SettingsManager.reset_section(current_tab)
	# Refresh the current tab
	_switch_tab(current_tab)


# =============================================================================
# ANIMATIONS
# =============================================================================

func _play_open_animation() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property(overlay, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(main_panel, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(main_panel, "scale", Vector2(1.0, 1.0), 0.3).from(Vector2(0.9, 0.9))


func _play_close_animation() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property(overlay, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(main_panel, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(main_panel, "scale", Vector2(0.95, 0.95), 0.2)
	
	tween.tween_callback(_close)


func _close() -> void:
	closed.emit()
	queue_free()


# =============================================================================
# INPUT
# =============================================================================

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_close_pressed()
			get_viewport().set_input_as_handled()
