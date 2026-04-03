## UITheme — Centralised Fantasy World UI theme helper
## All menus and overlays call these static functions to ensure
## a single consistent look across the entire game.
## Usage:  var style = UITheme.btn_normal()
class_name UITheme
extends RefCounted

# =============================================================================
# ASSET PATHS
# =============================================================================
const PATH_BTN_DEFAULT  = "res://assets/textures/ui/components/default_button.png"
const PATH_BTN_HOVERED  = "res://assets/textures/ui/components/hovered_button.png"
const PATH_BTN_DROPDOWN = "res://assets/textures/ui/components/button_dropdown.png"
const PATH_INPUT_BOX    = "res://assets/textures/ui/components/input_box.png"
const PATH_CONTENT_BOX  = "res://assets/textures/ui/components/menu_panel_border.png"
const PATH_RANDOMIZE    = "res://assets/textures/ui/components/randomize_button.png"
const PATH_SLIDER_H     = "res://assets/textures/ui/components/horizontal_bar.png"
const PATH_SLIDER_V     = "res://assets/textures/ui/components/verticle_bar.png"
const PATH_SLIDER_COMPS = "res://assets/textures/ui/components/slider_components.png"

const PATH_LOGO         = "res://assets/textures/logo/fantasy-world-main-screen-logo.png"

const PATH_FONT_REGULAR = "res://assets/fonts/Cinzel-Regular.ttf"
const PATH_FONT_BOLD    = "res://assets/fonts/Cinzel-Bold.ttf"
const PATH_FONT_BLACK   = "res://assets/fonts/Cinzel-Black.ttf"

# =============================================================================
# COLOUR PALETTE  (warm medieval gold / iron)
# =============================================================================
const C_GOLD         = Color(0.88, 0.76, 0.44, 1.0)   # Title / section gold
const C_GOLD_BRIGHT  = Color(1.00, 0.90, 0.55, 1.0)   # Hovered text / accent
const C_WARM_WHITE   = Color(0.72, 0.71, 0.68, 1.0)   # Tarnished silver body text
const C_DIM          = Color(0.55, 0.52, 0.48, 0.80)  # Disabled / version label
const C_SHADOW       = Color(0.00, 0.00, 0.00, 0.70)  # Drop shadow
const C_SCREEN_DIM   = Color(0.00, 0.00, 0.00, 0.60)  # Background vignette tint — increased for readability
const C_PANEL_FILL   = Color(0.0, 0.0, 0.0, 0.95)   # Pure black panel fill — high readability

# Role / Type Colors (Thematic Medieval Palette)
const C_ROLE_GROUND = Color("#912A2A") # Oxblood Red: Resilience, blood, and the frontline
const C_ROLE_AIR    = Color("#5B7382") # Slate Blue: Storm clouds, cold steel, and mobility
const C_ROLE_MAGIC  = Color("#664973") # Royal Amethyst: Arcane mystery and expensive dyes
const C_ROLE_FLEX   = Color("#C29B40") # Aged Gold: Divinity, utility, and high value

# =============================================================================
# GEOMETRY CONSTANTS  (all spacing is a multiple of 8 px)
# =============================================================================
# Primary menu buttons  (the pointed banner)
const BTN_W         = 308   # px (reduced by 30% from original 440)
const BTN_H         = 34    # px  (taller for breathing room around text)
const BTN_FONT_SIZE = 16    # pt

# Secondary / action buttons  (smaller, same texture)
const BTN_SM_W      = 220
const BTN_SM_H      = 38
const BTN_SM_FONT   = 17

# Input boxes
const INPUT_H       = 44
const INPUT_FONT    = 16

# Panel title font
const TITLE_FONT    = 42    # Screen header size (e.g. "SETTINGS")
const LOGO_W        = 1080  # Logo image max width (50% bigger than original 720)
const LOGO_H        = 383   # Logo image max height (50% bigger than original 255)

# 9-slice inset sizes for each texture (pixels from edge that contain the
# non-stretchable art — pointed tips, border corners, etc.)
const SLICE_BTN     = 60    # horizontal tip width preserved on both sides
const SLICE_BTN_V   = 16    # vertical margin preserved top & bottom

const SLICE_INPUT_H = 40    # display px protected on each horizontal edge (pointed tips)
const SLICE_INPUT_V = 15    # display px protected on each vertical edge (top/bottom border rim)
# Content margins are decoupled from slice so the box never collapses in narrow panels
const INPUT_CONTENT_H = 14  # inner horizontal padding for text cursor
const INPUT_CONTENT_V = 6   # inner vertical padding for text cursor

const SLICE_PANEL_H = 48    # border thickness of the newly spliced bars
const SLICE_PANEL_V = 48    # border thickness of the newly spliced bars
const PANEL_BANNER  = 48    # top border length of the newly spliced bars

# Content padding inside panels
const PAD           = 24    # standard inner margin
const PAD_SM        = 16


# =============================================================================
# FONT LOADERS  (cached once per session via static vars)
# =============================================================================
static var _font_regular: FontFile = null
static var _font_bold:    FontFile = null
static var _font_black:   FontFile = null

static func font_regular() -> FontFile:
	if _font_regular == null and ResourceLoader.exists(PATH_FONT_REGULAR):
		_font_regular = load(PATH_FONT_REGULAR)
	return _font_regular

static func font_bold() -> FontFile:
	if _font_bold == null and ResourceLoader.exists(PATH_FONT_BOLD):
		_font_bold = load(PATH_FONT_BOLD)
	return _font_bold

static func font_black() -> FontFile:
	if _font_black == null and ResourceLoader.exists(PATH_FONT_BLACK):
		_font_black = load(PATH_FONT_BLACK)
	return _font_black


# =============================================================================
# TEXTURE LOADERS  (cached once)
# =============================================================================
static var _tex_btn_def:  Texture2D = null
static var _tex_btn_hov:  Texture2D = null
static var _tex_dropdown: Texture2D = null
static var _tex_input:    Texture2D = null
static var _tex_content:  Texture2D = null
static var _tex_random:   Texture2D = null
static var _tex_logo:     Texture2D = null
static var _tex_slider_h: Texture2D = null
static var _tex_slider_v: Texture2D = null
static var _tex_slider_comps: Texture2D = null

static func tex_btn_default() -> Texture2D:
	if _tex_btn_def == null and ResourceLoader.exists(PATH_BTN_DEFAULT):
		_tex_btn_def = load(PATH_BTN_DEFAULT)
	return _tex_btn_def

static func tex_btn_hovered() -> Texture2D:
	if _tex_btn_hov == null and ResourceLoader.exists(PATH_BTN_HOVERED):
		_tex_btn_hov = load(PATH_BTN_HOVERED)
	return _tex_btn_hov

static func tex_dropdown() -> Texture2D:
	if _tex_dropdown == null and ResourceLoader.exists(PATH_BTN_DROPDOWN):
		_tex_dropdown = load(PATH_BTN_DROPDOWN)
	return _tex_dropdown

static func tex_input() -> Texture2D:
	if _tex_input == null and ResourceLoader.exists(PATH_INPUT_BOX):
		_tex_input = load(PATH_INPUT_BOX)
	return _tex_input

static func tex_content() -> Texture2D:
	if _tex_content == null and ResourceLoader.exists(PATH_CONTENT_BOX):
		_tex_content = load(PATH_CONTENT_BOX)
	return _tex_content

static func tex_random() -> Texture2D:
	if _tex_random == null and ResourceLoader.exists(PATH_RANDOMIZE):
		_tex_random = load(PATH_RANDOMIZE)
	return _tex_random

static func tex_slider_h() -> Texture2D:
	if _tex_slider_h == null and ResourceLoader.exists(PATH_SLIDER_H):
		_tex_slider_h = load(PATH_SLIDER_H)
	return _tex_slider_h

static func tex_slider_v() -> Texture2D:
	if _tex_slider_v == null and ResourceLoader.exists(PATH_SLIDER_V):
		_tex_slider_v = load(PATH_SLIDER_V)
	return _tex_slider_v

static func tex_slider_comps() -> Texture2D:
	if _tex_slider_comps == null and ResourceLoader.exists(PATH_SLIDER_COMPS):
		_tex_slider_comps = load(PATH_SLIDER_COMPS)
	return _tex_slider_comps

static func tex_logo() -> Texture2D:
	if _tex_logo == null and ResourceLoader.exists(PATH_LOGO):
		_tex_logo = load(PATH_LOGO)
	return _tex_logo


# =============================================================================
# STYLE BOX BUILDERS
# =============================================================================

## Normal (dark) button — pointed banner texture, 9-sliced
static func btn_normal() -> StyleBoxTexture:
	var s = StyleBoxTexture.new()
	s.texture = tex_btn_default()
	s.texture_margin_left   = SLICE_BTN
	s.texture_margin_right  = SLICE_BTN
	s.texture_margin_top    = SLICE_BTN_V
	s.texture_margin_bottom = SLICE_BTN_V
	s.content_margin_left   = SLICE_BTN + 12
	s.content_margin_right  = SLICE_BTN + 12
	s.content_margin_top    = SLICE_BTN_V + 2
	s.content_margin_bottom = SLICE_BTN_V + 2
	# Prevent the stylebox from ever expanding the button's layout size
	s.expand_margin_left   = 0
	s.expand_margin_right  = 0
	s.expand_margin_top    = 0
	s.expand_margin_bottom = 0
	return s

## Hovered (bronze/gold) button — same shape, lighter texture
static func btn_hover() -> StyleBoxTexture:
	var s = StyleBoxTexture.new()
	s.texture = tex_btn_hovered()
	s.texture_margin_left   = SLICE_BTN
	s.texture_margin_right  = SLICE_BTN
	s.texture_margin_top    = SLICE_BTN_V
	s.texture_margin_bottom = SLICE_BTN_V
	s.content_margin_left   = SLICE_BTN + 12
	s.content_margin_right  = SLICE_BTN + 12
	s.content_margin_top    = SLICE_BTN_V + 2
	s.content_margin_bottom = SLICE_BTN_V + 2
	# Prevent the stylebox from ever expanding the button's layout size
	s.expand_margin_left   = 0
	s.expand_margin_right  = 0
	s.expand_margin_top    = 0
	s.expand_margin_bottom = 0
	return s

## Pressed — same as hover but tinted slightly darker
static func btn_pressed() -> StyleBoxTexture:
	var s = btn_hover()
	s.modulate_color = Color(0.75, 0.70, 0.55, 1.0)
	return s

## Disabled button
static func btn_disabled() -> StyleBoxTexture:
	var s = btn_normal()
	s.modulate_color = Color(0.45, 0.42, 0.38, 0.60)
	return s

## Dropdown / OptionButton normal state
static func dropdown_normal() -> StyleBoxTexture:
	var s = StyleBoxTexture.new()
	s.texture = tex_dropdown()
	s.texture_margin_left   = SLICE_BTN
	s.texture_margin_right  = SLICE_BTN
	s.texture_margin_top    = SLICE_BTN_V
	s.texture_margin_bottom = SLICE_BTN_V
	s.content_margin_left   = SLICE_BTN + 4
	s.content_margin_right  = SLICE_BTN + 48  # room for the ▼ arrow on the right
	s.content_margin_top    = SLICE_BTN_V + 2
	s.content_margin_bottom = SLICE_BTN_V + 2
	return s

## Text input / LineEdit — image is pre-cropped, scale uniformly with no 9-slicing
static func input_normal() -> StyleBoxTexture:
	var s = StyleBoxTexture.new()
	s.texture = tex_input()
	# No 9-slicing — the texture is already the correct shape, just let it scale to fit
	s.texture_margin_left   = 0
	s.texture_margin_right  = 0
	s.texture_margin_top    = 0
	s.texture_margin_bottom = 0
	# Small content margins so the text cursor has breathing room from the edges
	s.content_margin_left   = INPUT_CONTENT_H
	s.content_margin_right  = INPUT_CONTENT_H
	s.content_margin_top    = INPUT_CONTENT_V
	s.content_margin_bottom = INPUT_CONTENT_V
	s.expand_margin_left   = 0
	s.expand_margin_right  = 0
	s.expand_margin_top    = 0
	s.expand_margin_bottom = 0
	return s

## Focused input — same texture, gold modulate
static func input_focused() -> StyleBoxTexture:
	var s = input_normal()
	s.modulate_color = Color(1.0, 0.90, 0.55, 1.0)
	return s

## Content panel (the iron-frame box with banner header)
static func panel_content() -> StyleBoxTexture:
	var s = StyleBoxTexture.new()
	s.texture = tex_content()
	s.texture_margin_left   = SLICE_PANEL_H
	s.texture_margin_right  = SLICE_PANEL_H
	s.texture_margin_top    = PANEL_BANNER
	s.texture_margin_bottom = SLICE_PANEL_V
	s.content_margin_left   = SLICE_PANEL_H + PAD_SM
	s.content_margin_right  = SLICE_PANEL_H + PAD_SM
	s.content_margin_top    = PANEL_BANNER + PAD_SM
	s.content_margin_bottom = SLICE_PANEL_V + PAD_SM
	return s

## Flat fallback (when textures haven't loaded yet) — keeps the colour palette
static func fallback_btn_flat(col: Color = C_GOLD) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color     = Color(0.10, 0.08, 0.06, 0.90)
	s.border_color = col.darkened(0.2)
	s.set_border_width_all(2)
	s.set_corner_radius_all(4)
	s.content_margin_left   = 20
	s.content_margin_right  = 20
	s.content_margin_top    = 10
	s.content_margin_bottom = 10
	return s

## Slider track (horizontal)
static func slider_h() -> StyleBoxTexture:
	var s = StyleBoxTexture.new()
	s.texture = tex_slider_h()
	s.texture_margin_left   = 8
	s.texture_margin_right  = 8
	s.texture_margin_top    = 0
	s.texture_margin_bottom = 0
	return s

## Slider track (vertical)
static func slider_v() -> StyleBoxTexture:
	var s = StyleBoxTexture.new()
	s.texture = tex_slider_v()
	s.texture_margin_left   = 0
	s.texture_margin_right  = 0
	s.texture_margin_top    = 8
	s.texture_margin_bottom = 8
	return s


# =============================================================================
# LABEL STYLING HELPERS  (apply font + colour in one call)
# =============================================================================

## Apply Cinzel Regular + colour to any Label
static func style_label(lbl: Label, size: int, col: Color = C_WARM_WHITE,
		bold: bool = false) -> void:
	var f = font_bold() if bold else font_regular()
	if f:
		lbl.add_theme_font_override("font", f)
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_shadow_color", C_SHADOW)
	lbl.add_theme_constant_override("shadow_offset_x", 2)
	lbl.add_theme_constant_override("shadow_offset_y", 2)

## Apply Cinzel Regular to a Button's text
static func style_button_text(btn: Button, size: int,
		col: Color = C_WARM_WHITE) -> void:
	var f = font_regular()
	if f:
		btn.add_theme_font_override("font", f)
	btn.add_theme_font_size_override("font_size", size)
	btn.add_theme_color_override("font_color", col)
	btn.add_theme_color_override("font_hover_color", C_GOLD_BRIGHT)
	btn.add_theme_color_override("font_pressed_color", C_GOLD)
	btn.add_theme_color_override("font_disabled_color", C_DIM)

## Full button theme application (texture styles + Cinzel text)
static func apply_menu_button(btn: Button, size: int = BTN_FONT_SIZE) -> void:
	btn.add_theme_stylebox_override("normal",   btn_normal())
	btn.add_theme_stylebox_override("hover",    btn_hover())
	btn.add_theme_stylebox_override("pressed",  btn_pressed())
	btn.add_theme_stylebox_override("disabled", btn_disabled())
	btn.add_theme_stylebox_override("focus",    btn_hover())
	style_button_text(btn, size)
	connect_hover_sound(btn)

## Flat hover/focus style for dropdowns — avoids the banner texture popping up on hover
static func dropdown_hover() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color     = Color(0.18, 0.15, 0.10, 0.85)
	s.border_color = C_GOLD.darkened(0.2)
	s.set_border_width_all(1)
	s.content_margin_left   = SLICE_BTN + 4
	s.content_margin_right  = SLICE_BTN + 48
	s.content_margin_top    = SLICE_BTN_V + 2
	s.content_margin_bottom = SLICE_BTN_V + 2
	return s

## Full OptionButton / dropdown theme application
static func apply_dropdown(opt: OptionButton, size: int = INPUT_FONT) -> void:
	opt.add_theme_stylebox_override("normal",   dropdown_normal())
	opt.add_theme_stylebox_override("hover",    dropdown_hover())
	opt.add_theme_stylebox_override("pressed",  dropdown_hover())
	opt.add_theme_stylebox_override("focus",    StyleBoxEmpty.new())
	var f = font_regular()
	if f:
		opt.add_theme_font_override("font", f)
	opt.add_theme_font_size_override("font_size", size)
	opt.add_theme_color_override("font_color", C_WARM_WHITE)
	opt.add_theme_color_override("font_hover_color", C_GOLD_BRIGHT)
	connect_hover_sound(opt)

## Full LineEdit theme application
static func apply_input(le: LineEdit, size: int = INPUT_FONT) -> void:
	le.add_theme_stylebox_override("normal", input_normal())
	le.add_theme_stylebox_override("focus",  input_focused())
	var f = font_regular()
	if f:
		le.add_theme_font_override("font", f)
	le.add_theme_font_size_override("font_size", size)
	le.add_theme_color_override("font_color", C_WARM_WHITE)
	le.add_theme_color_override("font_placeholder_color", C_DIM)

## Apply content-box panel texture to a PanelContainer
static func apply_panel(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", panel_content())

## Create a gold ornamental HSeparator
static func make_separator() -> HSeparator:
	var sep = HSeparator.new()
	var st  = StyleBoxFlat.new()
	st.bg_color = C_GOLD.darkened(0.5)
	st.set_content_margin_all(1)
	sep.add_theme_stylebox_override("separator", st)
	sep.add_theme_constant_override("separation", 2)
	return sep


# =============================================================================
# IN-GAME HUD / OVERLAY STYLE HELPERS
# =============================================================================

## Colours used by in-game HUD elements (darker, less opaque than menu panels)
const C_HUD_BG      = Color(0.0, 0.0, 0.0, 0.95)
const C_HUD_BORDER  = Color(0.40, 0.34, 0.24, 0.80)
const C_OVERLAY_DIM = Color(0.00, 0.00, 0.00, 0.75)

## Semi-transparent panel for in-game HUD elements (top bar, side panels, etc.)
static func hud_panel(border_col: Color = C_HUD_BORDER) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color     = C_HUD_BG
	s.border_color = border_col
	s.set_border_width_all(2)
	s.set_corner_radius_all(8)
	s.content_margin_left   = 12
	s.content_margin_right  = 12
	s.content_margin_top    = 8
	s.content_margin_bottom = 8
	return s

## Specialized style for the top bar (no top/side borders, no rounded corners)
static func hud_bar_style(border_col: Color = C_HUD_BORDER) -> StyleBoxFlat:
	var s = hud_panel(border_col)
	s.set_corner_radius_all(0)
	s.set_border_width(SIDE_TOP, 0)
	s.set_border_width(SIDE_LEFT, 0)
	s.set_border_width(SIDE_RIGHT, 0)
	s.set_border_width(SIDE_BOTTOM, 2)
	return s

## Full-screen overlay panel for dialogs/combat (centred, with shadow)
static func overlay_panel(accent: Color = C_GOLD) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color     = Color(0.0, 0.0, 0.0, 0.0)
	s.border_color = accent.darkened(0.3)
	s.set_border_width_all(0)
	s.set_corner_radius_all(16)
	s.shadow_size  = 0
	s.content_margin_left   = 20
	s.content_margin_right  = 20
	s.content_margin_top    = 16
	s.content_margin_bottom = 16
	return s

## Section panel inside an overlay (attacker panel, defender panel, etc.)
static func section_panel(accent: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color     = accent.darkened(0.75)
	s.border_color = C_GOLD.darkened(0.35)
	s.set_border_width_all(2)
	s.set_corner_radius_all(10)
	s.content_margin_left   = 10
	s.content_margin_right  = 10
	s.content_margin_top    = 8
	s.content_margin_bottom = 8
	return s

## Compact button for in-game HUD actions (move, attack, mine, etc.)
static func hud_action_button(_accent: Color) -> void:
	# caller should pass the button; this is kept for symmetry
	pass  # Use apply_hud_button() instead

## Apply HUD action button styling (compact, dark, accent-bordered)
static func apply_hud_button(btn: Button, accent: Color, size: int = 13) -> void:
	var normal_s = StyleBoxFlat.new()
	normal_s.bg_color     = Color(0.10, 0.09, 0.08, 0.90)
	normal_s.border_color = C_GOLD.darkened(0.5)
	normal_s.set_border_width_all(2)
	normal_s.set_corner_radius_all(6)
	normal_s.content_margin_left   = 8
	normal_s.content_margin_right  = 8
	normal_s.content_margin_top    = 6
	normal_s.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", normal_s)

	var hover_s = normal_s.duplicate()
	hover_s.bg_color     = accent.darkened(0.60)
	hover_s.border_color = C_GOLD
	hover_s.set_border_width_all(3)
	btn.add_theme_stylebox_override("hover", hover_s)

	var pressed_s = normal_s.duplicate()
	pressed_s.bg_color     = accent.darkened(0.50)
	pressed_s.border_color = C_GOLD_BRIGHT
	pressed_s.set_border_width_all(3)
	btn.add_theme_stylebox_override("pressed", pressed_s)

	var disabled_s = normal_s.duplicate()
	disabled_s.bg_color     = Color(0.08, 0.07, 0.06, 0.55)
	disabled_s.border_color = Color(0.20, 0.18, 0.16, 0.40)
	disabled_s.set_border_width_all(1)
	btn.add_theme_stylebox_override("disabled", disabled_s)

	style_button_text(btn, size)
	connect_hover_sound(btn)

## Apply Cinzel font and colour to any Label — convenience for in-game use
static func style_hud_label(lbl: Label, size: int, col: Color = C_WARM_WHITE) -> void:
	style_label(lbl, size, col)

## Dark background ColorRect for full-screen overlays (combat, dice, etc.)
static func make_overlay_bg() -> ColorRect:
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = C_OVERLAY_DIM
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	return bg


# =============================================================================
# AUDIO HELPERS
# =============================================================================

## Safely connects a button's mouse_entered signal to the UI hover sound
static func connect_hover_sound(btn: Button) -> void:
	if not btn.mouse_entered.is_connected(_on_button_hover):
		btn.mouse_entered.connect(_on_button_hover)

static func _on_button_hover() -> void:
	# Access AudioManager via root to ensure compatibility in static context
	var root = Engine.get_main_loop().root if Engine.get_main_loop() else null
	if root and root.has_node("AudioManager"):
		var am = root.get_node("AudioManager")
		if am.has_method("play_ui_hover"):
			am.play_ui_hover()

