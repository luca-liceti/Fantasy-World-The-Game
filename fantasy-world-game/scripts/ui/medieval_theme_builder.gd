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
	
	# Configure CheckButton styles (Toggles)
	_setup_check_button_styles(theme)
	
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
	var h_empty = UITheme.slider_empty_style()
	var h_filled = UITheme.slider_filled_style()
	var grabber = UITheme.tex_slider_handle()
	
	theme.set_stylebox("slider", "HSlider", h_empty)
	theme.set_stylebox("grabber_area", "HSlider", h_filled)
	theme.set_stylebox("grabber_area_highlight", "HSlider", h_filled)
	
	if grabber:
		theme.set_icon("grabber", "HSlider", grabber)
		theme.set_icon("grabber_highlight", "HSlider", grabber)
	
	# VSlider uses fallback or the old style for now as we only have HSlider components
	theme.set_stylebox("slider", "VSlider", UITheme.slider_v())
	theme.set_stylebox("grabber_area", "VSlider", StyleBoxEmpty.new())


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
	

static func _setup_check_button_styles(theme: Theme) -> void:
	var on_tex = UITheme.tex_toggle_on()
	var off_tex = UITheme.tex_toggle_off()
	
	if on_tex and off_tex:
		# For theme-wide icons, we can't easily resize per-resolution here 
		# as cleanly as in apply_toggle, but we can set the default icons.
		# Note: The theme will use the textures as-is unless we create ImageTextures here.
		# However, for consistency with apply_toggle, we'll try to provide scaled versions.
		
		var img_on = on_tex.get_image()
		var img_off = off_tex.get_image()
		
		var target_h = 22
		var target_w = int(target_h * (792.0 / 243.0))
		
		img_on.resize(target_w, target_h, Image.INTERPOLATE_LANCZOS)
		img_off.resize(target_w, target_h, Image.INTERPOLATE_LANCZOS)
		
		# Apply same programmatical gold tint for "Glow"
		for y in range(img_on.get_height()):
			for x in range(img_on.get_width()):
				var c = img_on.get_pixel(x, y)
				if c.a > 0.01:
					c.r = min(1.0, c.r * 1.25)
					c.g = min(1.0, c.g * 1.15)
					c.b = min(1.0, c.b * 0.90)
					img_on.set_pixel(x, y, c)
		
		var scaled_on = ImageTexture.create_from_image(img_on)
		var scaled_off = ImageTexture.create_from_image(img_off)
		
		theme.set_icon("switch_on", "CheckButton", scaled_on)
		theme.set_icon("switch_off", "CheckButton", scaled_off)
		theme.set_icon("switch_on_disabled", "CheckButton", scaled_on)
		theme.set_icon("switch_off_disabled", "CheckButton", scaled_off)
		
		# Also set Checked icons just in case it falls back
		theme.set_icon("checked", "CheckButton", scaled_on)
		theme.set_icon("unchecked", "CheckButton", scaled_off)
		theme.set_icon("checked_disabled", "CheckButton", scaled_on)
		theme.set_icon("unchecked_disabled", "CheckButton", scaled_off)
	
	theme.set_color("font_color", "CheckButton", COLOR_TEXT)
	theme.set_color("font_hover_color", "CheckButton", COLOR_TEXT_GOLD)
