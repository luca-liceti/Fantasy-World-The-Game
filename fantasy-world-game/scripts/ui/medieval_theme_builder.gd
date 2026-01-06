## Medieval Theme Builder
## Generates a medieval-styled Theme resource for the UI
## Creates stone/wood/iron aesthetic as per the asset integration master plan
class_name MedievalThemeBuilder
extends RefCounted

# =============================================================================
# COLORS (Manor Lords-inspired palette)
# =============================================================================

## Primary colors
const COLOR_STONE_DARK := Color(0.16, 0.14, 0.13, 1.0)      # Dark stone background
const COLOR_STONE_LIGHT := Color(0.28, 0.24, 0.22, 1.0)     # Lighter stone
const COLOR_WOOD := Color(0.25, 0.18, 0.12, 1.0)             # Weathered wood
const COLOR_WOOD_LIGHT := Color(0.35, 0.26, 0.18, 1.0)       # Lighter wood (hover)
const COLOR_IRON := Color(0.35, 0.33, 0.32, 1.0)             # Weathered iron/metal

## Text colors
const COLOR_TEXT := Color(0.96, 0.91, 0.84, 1.0)             # Cream/parchment (#F5E6D3)
const COLOR_TEXT_MUTED := Color(0.75, 0.70, 0.65, 1.0)       # Muted text
const COLOR_TEXT_GOLD := Color(0.83, 0.69, 0.22, 1.0)        # Gold accent

## State colors
const COLOR_PRESSED := Color(0.18, 0.14, 0.10, 1.0)          # Pressed state (darker)
const COLOR_DISABLED := Color(0.2, 0.18, 0.16, 0.5)          # Disabled (muted)
const COLOR_FOCUS := Color(0.83, 0.69, 0.22, 0.8)            # Focus border (gold)

# =============================================================================
# THEME GENERATION
# =============================================================================

## Generate the complete medieval theme
static func create_theme() -> Theme:
	var theme := Theme.new()
	
	# Configure fonts
	_setup_fonts(theme)
	
	# Configure Button styles
	_setup_button_styles(theme)
	
	# Configure Label styles
	_setup_label_styles(theme)
	
	# Configure Panel styles
	_setup_panel_styles(theme)
	
	# Configure LineEdit styles
	_setup_line_edit_styles(theme)
	
	# Configure ProgressBar styles
	_setup_progress_bar_styles(theme)
	
	# Configure HSlider styles  
	_setup_slider_styles(theme)
	
	# Configure TabContainer/TabBar styles
	_setup_tab_styles(theme)
	
	return theme


## Save theme to file
static func save_theme_to_file(theme: Theme, path: String := "res://assets/themes/medieval_theme.tres") -> Error:
	return ResourceSaver.save(theme, path)


# =============================================================================
# STYLE CONFIGURATIONS
# =============================================================================

static func _setup_fonts(theme: Theme) -> void:
	# Set default font colors
	theme.set_color("font_color", "Button", COLOR_TEXT)
	theme.set_color("font_hover_color", "Button", COLOR_TEXT_GOLD)
	theme.set_color("font_pressed_color", "Button", COLOR_TEXT)
	theme.set_color("font_disabled_color", "Button", COLOR_TEXT_MUTED)
	theme.set_color("font_focus_color", "Button", COLOR_TEXT_GOLD)
	
	theme.set_color("font_color", "Label", COLOR_TEXT)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.5))
	
	# Font sizes
	theme.set_font_size("font_size", "Button", 16)
	theme.set_font_size("font_size", "Label", 14)


static func _setup_button_styles(theme: Theme) -> void:
	# Normal state - wood texture appearance
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_WOOD
	normal.border_color = COLOR_IRON
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(4)
	normal.set_content_margin_all(12)
	normal.shadow_color = Color(0, 0, 0, 0.4)
	normal.shadow_size = 2
	normal.shadow_offset = Vector2(1, 2)
	
	# Hover state - lighter wood
	var hover := StyleBoxFlat.new()
	hover.bg_color = COLOR_WOOD_LIGHT
	hover.border_color = COLOR_TEXT_GOLD
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(4)
	hover.set_content_margin_all(12)
	hover.shadow_color = Color(0, 0, 0, 0.5)
	hover.shadow_size = 3
	hover.shadow_offset = Vector2(1, 2)
	
	# Pressed state - darker, inset
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = COLOR_PRESSED
	pressed.border_color = COLOR_IRON
	pressed.set_border_width_all(2)
	pressed.set_corner_radius_all(4)
	pressed.set_content_margin_all(12)
	pressed.shadow_size = 0  # No shadow when pressed (appears inset)
	
	# Disabled state
	var disabled := StyleBoxFlat.new()
	disabled.bg_color = COLOR_DISABLED
	disabled.border_color = Color(0.3, 0.28, 0.26, 0.5)
	disabled.set_border_width_all(1)
	disabled.set_corner_radius_all(4)
	disabled.set_content_margin_all(12)
	
	# Focus state (golden highlight)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0, 0, 0, 0)  # Transparent
	focus.border_color = COLOR_FOCUS
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(5)
	focus.draw_center = false
	
	theme.set_stylebox("normal", "Button", normal)
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", pressed)
	theme.set_stylebox("disabled", "Button", disabled)
	theme.set_stylebox("focus", "Button", focus)


static func _setup_label_styles(theme: Theme) -> void:
	var label_settings := LabelSettings.new()
	label_settings.font_color = COLOR_TEXT
	label_settings.shadow_color = Color(0, 0, 0, 0.6)
	label_settings.shadow_size = 1
	label_settings.shadow_offset = Vector2(1, 1)
	
	# Note: Theme doesn't directly use LabelSettings, but we set colors
	theme.set_color("font_color", "Label", COLOR_TEXT)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.6))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)
	theme.set_constant("outline_size", "Label", 0)


static func _setup_panel_styles(theme: Theme) -> void:
	# Standard panel - dark stone
	var panel := StyleBoxFlat.new()
	panel.bg_color = COLOR_STONE_DARK
	panel.border_color = COLOR_IRON
	panel.set_border_width_all(3)
	panel.set_corner_radius_all(6)
	panel.set_content_margin_all(10)
	
	theme.set_stylebox("panel", "Panel", panel)
	theme.set_stylebox("panel", "PanelContainer", panel)
	
	# Popup panel - slightly raised
	var popup := StyleBoxFlat.new()
	popup.bg_color = COLOR_STONE_LIGHT
	popup.border_color = COLOR_IRON
	popup.set_border_width_all(3)
	popup.set_corner_radius_all(6)
	popup.set_content_margin_all(12)
	popup.shadow_color = Color(0, 0, 0, 0.6)
	popup.shadow_size = 8
	
	theme.set_stylebox("panel", "PopupPanel", popup)


static func _setup_line_edit_styles(theme: Theme) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.10, 0.09, 1.0)
	normal.border_color = COLOR_IRON
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(3)
	normal.set_content_margin_all(8)
	
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0.14, 0.12, 0.10, 1.0)
	focus.border_color = COLOR_TEXT_GOLD
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(3)
	focus.set_content_margin_all(8)
	
	theme.set_stylebox("normal", "LineEdit", normal)
	theme.set_stylebox("focus", "LineEdit", focus)
	theme.set_color("font_color", "LineEdit", COLOR_TEXT)
	theme.set_color("font_placeholder_color", "LineEdit", COLOR_TEXT_MUTED)
	theme.set_color("caret_color", "LineEdit", COLOR_TEXT_GOLD)
	theme.set_color("selection_color", "LineEdit", Color(0.83, 0.69, 0.22, 0.3))


static func _setup_progress_bar_styles(theme: Theme) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = COLOR_STONE_DARK
	background.border_color = COLOR_IRON
	background.set_border_width_all(2)
	background.set_corner_radius_all(4)
	
	var fill := StyleBoxFlat.new()
	fill.bg_color = COLOR_TEXT_GOLD
	fill.set_corner_radius_all(3)
	
	theme.set_stylebox("background", "ProgressBar", background)
	theme.set_stylebox("fill", "ProgressBar", fill)


static func _setup_slider_styles(theme: Theme) -> void:
	var slider_style := StyleBoxFlat.new()
	slider_style.bg_color = COLOR_STONE_DARK
	slider_style.border_color = COLOR_IRON
	slider_style.set_border_width_all(1)
	slider_style.set_corner_radius_all(3)
	
	var grabber_area := StyleBoxFlat.new()
	grabber_area.bg_color = COLOR_TEXT_GOLD
	grabber_area.set_corner_radius_all(3)
	
	theme.set_stylebox("slider", "HSlider", slider_style)
	theme.set_stylebox("grabber_area", "HSlider", grabber_area)
	theme.set_stylebox("slider", "VSlider", slider_style)
	theme.set_stylebox("grabber_area", "VSlider", grabber_area)


static func _setup_tab_styles(theme: Theme) -> void:
	# Tab container panel
	var tab_panel := StyleBoxFlat.new()
	tab_panel.bg_color = COLOR_STONE_DARK
	tab_panel.border_color = COLOR_IRON
	tab_panel.set_border_width_all(2)
	tab_panel.set_corner_radius_all(0)
	tab_panel.corner_radius_top_left = 0
	tab_panel.corner_radius_top_right = 0
	tab_panel.corner_radius_bottom_left = 6
	tab_panel.corner_radius_bottom_right = 6
	
	theme.set_stylebox("panel", "TabContainer", tab_panel)
	
	# Tab unselected
	var tab_unselected := StyleBoxFlat.new()
	tab_unselected.bg_color = COLOR_STONE_LIGHT
	tab_unselected.border_color = COLOR_IRON
	tab_unselected.set_border_width_all(1)
	tab_unselected.set_corner_radius_all(4)
	tab_unselected.corner_radius_bottom_left = 0
	tab_unselected.corner_radius_bottom_right = 0
	
	# Tab selected
	var tab_selected := StyleBoxFlat.new()
	tab_selected.bg_color = COLOR_STONE_DARK
	tab_selected.border_color = COLOR_TEXT_GOLD
	tab_selected.border_width_top = 2
	tab_selected.border_width_left = 1
	tab_selected.border_width_right = 1
	tab_selected.border_width_bottom = 0
	tab_selected.set_corner_radius_all(4)
	tab_selected.corner_radius_bottom_left = 0
	tab_selected.corner_radius_bottom_right = 0
	
	theme.set_stylebox("tab_unselected", "TabContainer", tab_unselected)
	theme.set_stylebox("tab_selected", "TabContainer", tab_selected)
	theme.set_stylebox("tab_hovered", "TabContainer", tab_unselected)
	
	theme.set_color("font_unselected_color", "TabContainer", COLOR_TEXT_MUTED)
	theme.set_color("font_selected_color", "TabContainer", COLOR_TEXT)
	theme.set_color("font_hovered_color", "TabContainer", COLOR_TEXT_GOLD)
