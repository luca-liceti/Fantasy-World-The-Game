## Medieval Theme Builder
## Generates a medieval-styled Theme resource for the UI
## Creates stone/wood/iron aesthetic as per the asset integration master plan
class_name MedievalThemeBuilder
extends RefCounted

# =============================================================================
# COLORS (Manor Lords-inspired palette)
# =============================================================================

## Primary colors
const COLOR_STONE_DARK := Color(0.16, 0.14, 0.13, 1.0) # Dark stone background
const COLOR_STONE_LIGHT := Color(0.28, 0.24, 0.22, 1.0) # Lighter stone
const COLOR_WOOD := Color(0.25, 0.18, 0.12, 1.0) # Weathered wood
const COLOR_WOOD_LIGHT := Color(0.35, 0.26, 0.18, 1.0) # Lighter wood (hover)
const COLOR_IRON := Color(0.35, 0.33, 0.32, 1.0) # Weathered iron/metal

## Text colors
const COLOR_TEXT := Color(0.96, 0.91, 0.84, 1.0) # Cream/parchment (#F5E6D3)
const COLOR_TEXT_MUTED := Color(0.75, 0.70, 0.65, 1.0) # Muted text
const COLOR_TEXT_GOLD := Color(0.83, 0.69, 0.22, 1.0) # Gold accent

## State colors
const COLOR_PRESSED := Color(0.18, 0.14, 0.10, 1.0) # Pressed state (darker)
const COLOR_DISABLED := Color(0.2, 0.18, 0.16, 0.5) # Disabled (muted)
const COLOR_FOCUS := Color(0.83, 0.69, 0.22, 0.8) # Focus border (gold)

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
static func save_theme_to_file(theme: Theme, path: String = "res://assets/themes/medieval_theme.tres") -> Error:
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
	var normal := UITheme.btn_normal()
	var hover := UITheme.btn_hover()
	var pressed := UITheme.btn_pressed()
	var disabled := UITheme.btn_disabled()
	var focus := StyleBoxEmpty.new()
	
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
	var panel := UITheme.panel_content()
	theme.set_stylebox("panel", "Panel", panel)
	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_stylebox("panel", "PopupPanel", panel)


static func _setup_line_edit_styles(theme: Theme) -> void:
	var normal := UITheme.input_normal()
	var focus := UITheme.input_focused()
	
	theme.set_stylebox("normal", "LineEdit", normal)
	theme.set_stylebox("focus", "LineEdit", focus)
	theme.set_color("font_color", "LineEdit", COLOR_TEXT)
	theme.set_color("font_placeholder_color", "LineEdit", COLOR_TEXT_MUTED)
	theme.set_color("caret_color", "LineEdit", COLOR_TEXT_GOLD)
	theme.set_color("selection_color", "LineEdit", Color(0.83, 0.69, 0.22, 0.3))


static func _setup_progress_bar_styles(theme: Theme) -> void:
	var background := UITheme.input_normal() # Input boxes work beautifully as progress BG
	var fill := UITheme.btn_hover() # Golden button works magically for fill
	
	theme.set_stylebox("background", "ProgressBar", background)
	theme.set_stylebox("fill", "ProgressBar", fill)


static func _setup_slider_styles(theme: Theme) -> void:
	var slider_style := UITheme.slider_h()
	var v_slider_style := UITheme.slider_v()
	
	var grabber_area := StyleBoxEmpty.new()
	
	theme.set_stylebox("slider", "HSlider", slider_style)
	theme.set_stylebox("grabber_area", "HSlider", grabber_area)
	theme.set_stylebox("slider", "VSlider", v_slider_style)
	theme.set_stylebox("grabber_area", "VSlider", grabber_area)
	
	var slider_comps = UITheme.tex_slider_comps()
	if slider_comps:
		var grabber_tex = AtlasTexture.new()
		grabber_tex.atlas = slider_comps
		# Generic assumption for horizontal layout in grabber atlas: top left sprite
		grabber_tex.region = Rect2(0, 0, 48, 48)
		theme.set_icon("grabber", "HSlider", grabber_tex)
		theme.set_icon("grabber_highlight", "HSlider", grabber_tex)
		theme.set_icon("grabber", "VSlider", grabber_tex)
		theme.set_icon("grabber_highlight", "VSlider", grabber_tex)


static func _setup_tab_styles(theme: Theme) -> void:
	var tab_panel := UITheme.panel_content()
	
	var tab_unselected := UITheme.btn_normal()
	var tab_selected := UITheme.btn_hover()
	
	theme.set_stylebox("panel", "TabContainer", tab_panel)
	theme.set_stylebox("tab_unselected", "TabContainer", tab_unselected)
	theme.set_stylebox("tab_selected", "TabContainer", tab_selected)
	theme.set_stylebox("tab_hovered", "TabContainer", tab_unselected)
	
	theme.set_color("font_unselected_color", "TabContainer", COLOR_TEXT_MUTED)
	theme.set_color("font_selected_color", "TabContainer", COLOR_TEXT)
	theme.set_color("font_hovered_color", "TabContainer", COLOR_TEXT_GOLD)
