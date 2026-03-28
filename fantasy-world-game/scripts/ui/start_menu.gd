## Start Menu — Fantasy World
## Full-screen main menu. Each sub-screen (Settings, Online Multiplayer, etc.)
## slides in as a CanvasLayer over the same revolving background so the
## background is always visible. Logo image replaces the text title.
## All text uses the Cinzel font via UITheme.
class_name StartMenu
extends Control

# Preload sub-screens
const SettingsMenuScene      = preload("res://scripts/ui/settings_menu.gd")
const LobbyUIScene           = preload("res://scripts/ui/lobby_ui.gd")
const PlayModeMenuScene      = preload("res://scripts/ui/menus/play_mode_menu.gd")
const CreateLocalMatchScene  = preload("res://scripts/ui/menus/create_local_match_menu.gd")

# =============================================================================
# SIGNALS
# =============================================================================
signal play_pressed
signal multiplayer_pressed
signal tutorial_pressed
signal archives_pressed
signal credits_pressed
signal settings_pressed
signal quit_pressed

# =============================================================================
# BACKGROUND CYCLING
# =============================================================================
const BG_PATHS: Array[String] = [
	"res://assets/textures/ui/main_menu_backgrounds/cozy_tavern_background.png",
	"res://assets/textures/ui/main_menu_backgrounds/battlefield_tent_background.png",
	"res://assets/textures/ui/main_menu_backgrounds/grand_dinning_hall_background.png",
	"res://assets/textures/ui/main_menu_backgrounds/deforested_woods_background.png",
]
const BG_HOLD:  float = 15.0   # seconds per background
const BG_FADE:  float = 2.0    # cross-fade duration

var _bg_textures: Array[Texture2D] = []
var _bg_current:  TextureRect = null
var _bg_next:     TextureRect = null
var _bg_index:    int   = 0
var _bg_timer:    float = 0.0
var _bg_fading:   bool  = false
var _bg_progress: float = 0.0

# Shared background CanvasLayer — kept alive when sub-screens open
var _bg_layer: CanvasLayer = null

# =============================================================================
# MAIN MENU NODES
# =============================================================================
var _logo:           TextureRect   = null
var _btn_container:  VBoxContainer = null
var _version_label:  Label         = null

var _intro_tween:    Tween         = null
var _menu_layer:     CanvasLayer   = null   # holds logo + buttons
var _menu_root:      Control       = null   # root Control inside _menu_layer (animatable)

# Active sub-screen
var _sub_screen: CanvasLayer = null
var _lobby_ui:   Node        = null


# =============================================================================
# READY
# =============================================================================

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_load_bg_textures()
	_build_bg_layer()          # always-visible background
	_build_menu_layer()        # logo + buttons on top
	_play_intro()


# =============================================================================
# BACKGROUND  (lives on its own CanvasLayer so sub-screens sit above it)
# =============================================================================

func _load_bg_textures() -> void:
	for p in BG_PATHS:
		if ResourceLoader.exists(p):
			var t = load(p) as Texture2D
			if t:
				_bg_textures.append(t)

func _make_bg_rect(tex: Texture2D) -> TextureRect:
	var r = TextureRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.texture      = tex
	r.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

func _build_bg_layer() -> void:
	_bg_layer = CanvasLayer.new()
	_bg_layer.layer = 0
	add_child(_bg_layer)

	if _bg_textures.is_empty():
		var fb = ColorRect.new()
		fb.set_anchors_preset(Control.PRESET_FULL_RECT)
		fb.color = Color(0.07, 0.05, 0.04, 1.0)
		fb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bg_layer.add_child(fb)
		return

	_bg_current = _make_bg_rect(_bg_textures[0])
	_bg_layer.add_child(_bg_current)

	if _bg_textures.size() > 1:
		_bg_next = _make_bg_rect(_bg_textures[1 % _bg_textures.size()])
		_bg_next.modulate.a = 0.0
		_bg_layer.add_child(_bg_next)



# =============================================================================
# MENU LAYER  (logo + buttons)
# =============================================================================

func _build_menu_layer() -> void:
	_menu_layer = CanvasLayer.new()
	_menu_layer.layer = 10
	add_child(_menu_layer)

	# Root control that fills the screen (CanvasLayer itself has no modulate,
	# so we animate this Control's modulate instead)
	_menu_root = Control.new()
	_menu_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_layer.add_child(_menu_root)

	_build_logo(_menu_root)
	_build_buttons(_menu_root)
	_build_version_label(_menu_root)


func _build_logo(parent: Control) -> void:
	var tex = UITheme.tex_logo()
	_logo = TextureRect.new()
	_logo.name = "Logo"
	_logo.texture      = tex
	_logo.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.custom_minimum_size = Vector2(UITheme.LOGO_W, UITheme.LOGO_H)
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Centre-top anchor
	_logo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_logo.position = Vector2(-UITheme.LOGO_W * 0.5, 120)
	_logo.modulate.a = 0.0
	parent.add_child(_logo)

func _build_buttons(parent: Control) -> void:
	_btn_container = VBoxContainer.new()
	_btn_container.name = "ButtonContainer"
	_btn_container.set_anchors_preset(Control.PRESET_CENTER)
	_btn_container.custom_minimum_size = Vector2(UITheme.BTN_W, 0)
	_btn_container.position = Vector2(-UITheme.BTN_W * 0.5, -40)
	_btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_btn_container.add_theme_constant_override("separation", -2)
	parent.add_child(_btn_container)

	# 7 buttons — order and labels match the UI template exactly
	_make_btn("PLAY",               true).pressed.connect(_on_play_pressed)
	_make_btn("MULTIPLAYER",        false).pressed.connect(_on_multiplayer_pressed)
	_make_btn("THE ARCHIVES",       false).pressed.connect(_on_archives_pressed)
	_make_btn("TUTORIAL",           false).pressed.connect(_on_tutorial_pressed)
	_make_btn("SETTINGS",           false).pressed.connect(_on_settings_pressed)
	_make_btn("CREDITS",            false).pressed.connect(_on_credits_pressed)
	_make_btn("QUIT GAME",          false).pressed.connect(_on_quit_pressed)

func _make_btn(label: String, primary: bool) -> Button:
	var btn = Button.new()
	btn.name = label.replace(" ", "") + "Btn"
	btn.text = label
	btn.custom_minimum_size = Vector2(UITheme.BTN_W, UITheme.BTN_H)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.modulate.a = 0.0
	btn.clip_text = false
	# Set pivot to centre so scale animations shrink evenly from the middle
	btn.pivot_offset = Vector2(UITheme.BTN_W * 0.5, UITheme.BTN_H * 0.5)

	UITheme.apply_menu_button(btn, UITheme.BTN_FONT_SIZE)

	# Bright gold text for the primary (Play) button
	if primary:
		btn.add_theme_color_override("font_color", UITheme.C_GOLD_BRIGHT)

	# Hover: highlight only (texture swap via UITheme), NO scale change
	# Press: shrink like a real button being pushed down
	btn.button_down.connect(_on_btn_press.bind(btn))
	btn.button_up.connect(_on_btn_release.bind(btn))
	_btn_container.add_child(btn)
	return btn

func _build_version_label(parent: Control) -> void:
	_version_label = Label.new()
	_version_label.name = "VersionLabel"
	_version_label.text = "v0.1.0 — Development Build"
	_version_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_version_label.position = Vector2(-240, -52)
	UITheme.style_label(_version_label, 13, UITheme.C_DIM)
	parent.add_child(_version_label)




# =============================================================================
# INTRO ANIMATION
# =============================================================================

func _play_intro() -> void:
	if _intro_tween:
		_intro_tween.kill()
	_intro_tween = create_tween()
	_intro_tween.set_ease(Tween.EASE_OUT)
	_intro_tween.set_trans(Tween.TRANS_CUBIC)

	# Logo fades in + gentle upward settle
	_intro_tween.tween_property(_logo, "modulate:a", 1.0, 1.0)
	_intro_tween.parallel().tween_property(_logo, "position:y", 120.0, 1.0).from(144.0)

	# Buttons cascade in left-to-right
	var buttons = _btn_container.get_children()
	for i in range(buttons.size()):
		var btn = buttons[i]
		if not btn is Button:
			continue
		var delay = 0.55 + i * 0.10
		_intro_tween.parallel().tween_property(btn, "modulate:a", 1.0, 0.4).set_delay(delay)
		_intro_tween.parallel().tween_property(btn, "position:x", 0.0, 0.45).from(-28.0).set_delay(delay)


# =============================================================================
# BUTTON HOVER MICRO-ANIMATIONS
# =============================================================================

## Press: shrink the button like it’s being physically pushed
func _on_btn_press(btn: Button) -> void:
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.08)

## Release: pop back to normal size
func _on_btn_release(btn: Button) -> void:
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12)


# =============================================================================
# PROCESS — BACKGROUND CYCLING + LOGO GLOW
# =============================================================================

func _process(delta: float) -> void:
	_cycle_background(delta)
	_pulse_logo()

func _cycle_background(delta: float) -> void:
	if _bg_textures.size() <= 1 or _bg_next == null:
		return
	if _bg_fading:
		_bg_progress += delta / BG_FADE
		if _bg_progress >= 1.0:
			# swap: next becomes current
			_bg_current.texture   = _bg_next.texture
			_bg_current.modulate.a = 1.0
			_bg_index = (_bg_index + 1) % _bg_textures.size()
			var coming = (_bg_index + 1) % _bg_textures.size()
			_bg_next.texture    = _bg_textures[coming]
			_bg_next.modulate.a = 0.0
			_bg_fading   = false
			_bg_progress = 0.0
			_bg_timer    = 0.0
		else:
			_bg_next.modulate.a = _bg_progress
	else:
		_bg_timer += delta
		if _bg_timer >= BG_HOLD:
			_bg_fading   = true
			_bg_progress = 0.0

func _pulse_logo() -> void:
	if not _logo or _logo.modulate.a < 0.5:
		return
	var t = Time.get_ticks_msec() / 1000.0
	var p = 0.95 + 0.05 * sin(t * 1.3)
	_logo.modulate = Color(p, p * 0.98, p * 0.92, _logo.modulate.a)


# =============================================================================
# SHOW / HIDE MENU LAYER  (hide when a sub-screen is active)
# =============================================================================

func _show_main_menu() -> void:
	_menu_layer.visible = true
	_menu_root.modulate.a = 0.0
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_menu_root, "modulate:a", 1.0, 0.3)

func _hide_main_menu() -> void:
	var tw = create_tween()
	tw.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_menu_root, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func(): _menu_layer.visible = false)


# =============================================================================
# SUB-SCREEN MANAGEMENT
# Each sub-screen is a CanvasLayer at layer 20. Opening one hides the menu
# buttons but keeps the background (layers 0-1) visible.
# =============================================================================

func _open_sub_screen(screen: CanvasLayer) -> void:
	if _sub_screen:
		_sub_screen.queue_free()
	_sub_screen = screen
	_hide_main_menu()
	screen.layer = 20
	add_child(screen)
	# CanvasLayer has no modulate — find its first Control child to animate
	var ctrl = _get_canvas_root(screen)
	if ctrl:
		ctrl.modulate.a = 0.0
		var tw = create_tween()
		tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(ctrl, "modulate:a", 1.0, 0.35)

func _close_sub_screen() -> void:
	if not _sub_screen:
		return
	var dying = _sub_screen
	_sub_screen = null
	var ctrl = _get_canvas_root(dying)
	if ctrl:
		var tw = create_tween()
		tw.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(ctrl, "modulate:a", 0.0, 0.25)
		tw.tween_callback(dying.queue_free)
	else:
		dying.queue_free()
	_show_main_menu()

## Returns the first Control child of a CanvasLayer (its animatable root).
func _get_canvas_root(layer: CanvasLayer) -> Control:
	for child in layer.get_children():
		if child is Control:
			return child
	return null


# =============================================================================
# BUTTON CALLBACKS
# =============================================================================

func _on_play_pressed() -> void:
	play_pressed.emit()
	_open_play_mode_screen()

func _on_multiplayer_pressed() -> void:
	multiplayer_pressed.emit()
	_open_lobby_screen()

func _on_archives_pressed() -> void:
	archives_pressed.emit()
	_open_coming_soon("THE ARCHIVES",
		"The Archives will contain:\n\n" +
		"  • Troop Card Gallery (all 12 troops)\n" +
		"  • Rules & Lore Reference\n" +
		"  • Type Effectiveness Chart\n" +
		"  • Defensive Stances Guide\n" +
		"  • Item Catalog")

func _on_tutorial_pressed() -> void:
	tutorial_pressed.emit()
	_open_coming_soon("TUTORIAL",
		"The tutorial system is coming soon!\n\nLessons planned:\n\n" +
		"  1. Basic Attack\n  2. Move Variety\n  3. Type Effectiveness\n" +
		"  4. Defensive Stances\n  5. Positioning & Cover\n  6. Full Combat Simulation")

func _on_settings_pressed() -> void:
	settings_pressed.emit()
	var sm = SettingsMenuScene.new()
	sm.closed.connect(_close_sub_screen)
	_open_sub_screen(sm)

func _on_credits_pressed() -> void:
	credits_pressed.emit()
	_open_credits_screen()

func _on_quit_pressed() -> void:
	quit_pressed.emit()
	_open_quit_confirm()


# =============================================================================
# LOBBY  (Online Multiplayer)
# =============================================================================

func _open_lobby_screen() -> void:
	if _lobby_ui != null:
		return
	var lobby = LobbyUIScene.new()
	lobby.lobby_cancelled.connect(_on_lobby_cancelled)
	lobby.game_starting.connect(_on_mp_game_starting)
	_lobby_ui = lobby
	_open_sub_screen(lobby)

func _on_lobby_cancelled() -> void:
	_lobby_ui = null
	_close_sub_screen()

func _on_mp_game_starting() -> void:
	_lobby_ui = null


# =============================================================================
# PLAY MODE FLOW  (Play → Mode Select → Local Match Setup → Game)
# =============================================================================

func _open_play_mode_screen() -> void:
	var mode_menu = PlayModeMenuScene.new()
	mode_menu.quick_play_pressed.connect(_on_quick_play_pressed)
	mode_menu.custom_match_pressed.connect(_on_custom_match_pressed)
	mode_menu.achievements_pressed.connect(_on_achievements_pressed)
	mode_menu.back_pressed.connect(_close_sub_screen)
	_open_sub_screen(mode_menu)


func _on_quick_play_pressed() -> void:
	# Skip config — start game with default settings
	if _sub_screen:
		_sub_screen.queue_free()
		_sub_screen = null
	var default_settings = {
		"custom_mode": false,
		"environment": 0,
		"terrain_height": true,
		"turn_timer": 60,
		"combat_mode": 0,
		"combat_speed": 1.0,
		"starting_gold": 100,
		"npc_activity": true,
		"bounty_system": true,
	}
	print("[StartMenu] Quick Play with defaults: %s" % str(default_settings))
	_play_transition_to_game()


func _on_custom_match_pressed() -> void:
	# Close the play mode screen and open the custom match config
	if _sub_screen:
		_sub_screen.queue_free()
		_sub_screen = null
	var match_menu = CreateLocalMatchScene.new()
	match_menu.start_match.connect(_on_local_match_start)
	match_menu.back_pressed.connect(_on_local_match_back)
	_sub_screen = match_menu
	match_menu.layer = 20
	add_child(match_menu)
	var ctrl = _get_canvas_root(match_menu)
	if ctrl:
		ctrl.modulate.a = 0.0
		var tw = create_tween()
		tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(ctrl, "modulate:a", 1.0, 0.35)


func _on_achievements_pressed() -> void:
	# Close play mode screen and show achievements
	if _sub_screen:
		_sub_screen.queue_free()
		_sub_screen = null
	_open_achievements_screen()


func _open_achievements_screen() -> void:
	var layer = CanvasLayer.new()
	var root  = _make_fullscreen_root(layer)
	var content = _make_page_content(root, "ACHIEVEMENTS", 600, 480)

	var desc = Label.new()
	desc.text = (
		"Your accomplishments and milestones in Fantasy World!\n\n" +
		"Achievements will track:\n\n" +
		"  \u2022 Combat milestones (First Blood, 100 Kills, etc.)\n" +
		"  \u2022 Strategic mastery (Win without losing a troop, etc.)\n" +
		"  \u2022 Exploration rewards (Visit all biomes, etc.)\n" +
		"  \u2022 Collection goals (Use every troop, etc.)\n" +
		"  \u2022 Challenge runs (Win in under 10 turns, etc.)")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.style_label(desc, 16, UITheme.C_WARM_WHITE)
	content.add_child(desc)

	_add_back_button(root, func():
		if _sub_screen:
			_sub_screen.queue_free()
			_sub_screen = null
		_open_play_mode_screen()
	)
	_open_sub_screen(layer)


func _on_local_match_back() -> void:
	# Go back from custom match config to play mode selection
	if _sub_screen:
		_sub_screen.queue_free()
		_sub_screen = null
	_open_play_mode_screen()


func _on_local_match_start(settings: Dictionary) -> void:
	print("[StartMenu] Starting custom match with settings: %s" % str(settings))
	# TODO: Pass settings to the game scene for configuration
	_play_transition_to_game()


# =============================================================================
# CREDITS SUB-SCREEN
# =============================================================================

func _open_credits_screen() -> void:
	var layer = CanvasLayer.new()
	layer.layer = 20

	var root = _make_fullscreen_root(layer)

	var content = _make_page_content(root, "CREDITS", 640, 640)

	_add_credits_section(content, "DEVELOPMENT TEAM")
	_add_credits_entry(content,   "Game Design & Development", "Luca Liceti")
	_add_credits_entry(content,   "Art Direction",             "Luca Liceti")
	_add_credits_entry(content,   "Game Engine",               "Godot 4.x")

	_add_credits_section(content, "ASSET SOURCES")
	_add_credits_text(content, "3D Character Models — various artists on Sketchfab")
	_add_credits_text(content, "Card art & UI elements — original work for the project")
	_add_credits_text(content, "Environment models — curated community resources")

	_add_credits_section(content, "TOOLS & MIDDLEWARE")
	_add_credits_text(content, "Godot Engine 4.x — game engine")
	_add_credits_text(content, "Blender — 3D modelling & animation")
	_add_credits_text(content, "GIMP / Photoshop — texture & UI art")
	_add_credits_text(content, "Git — version control")

	_add_credits_section(content, "SPECIAL THANKS")
	_add_credits_text(content, "The Godot community for documentation and support")
	_add_credits_text(content, "Playtesters and friends who provided feedback")
	_add_credits_text(content, "You — for playing Fantasy World!")

	_add_back_button(root, func(): _close_sub_screen())

	_open_sub_screen(layer)


# =============================================================================
# COMING SOON SUB-SCREEN  (Archives / Tutorial)
# =============================================================================

func _open_coming_soon(title: String, description: String) -> void:
	var layer = CanvasLayer.new()
	var root  = _make_fullscreen_root(layer)
	var content = _make_page_content(root, title, 560, 420)

	var desc = Label.new()
	desc.text = description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.style_label(desc, 16, UITheme.C_WARM_WHITE)
	content.add_child(desc)

	_add_back_button(root, func(): _close_sub_screen())
	_open_sub_screen(layer)


# =============================================================================
# QUIT CONFIRMATION SUB-SCREEN
# =============================================================================

func _open_quit_confirm() -> void:
	var confirm_layer = CanvasLayer.new()
	confirm_layer.layer = 150
	
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
	title.text = "QUIT GAME"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(title, 24, UITheme.C_GOLD, true)
	vbox.add_child(title)
	
	var msg = Label.new()
	msg.text = "Are you sure you want to exit Fantasy World?"
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
	UITheme.apply_menu_button(yes_btn, 18)
	yes_btn.pressed.connect(func():
		confirm_layer.queue_free()
		get_tree().quit()
	)
	yes_btn.button_down.connect(func(): _on_btn_press(yes_btn))
	yes_btn.button_up.connect(func(): _on_btn_release(yes_btn))
	btn_row.add_child(yes_btn)
	
	var no_btn = Button.new()
	no_btn.text = "NO"
	no_btn.custom_minimum_size = Vector2(160, 50)
	no_btn.pivot_offset = Vector2(80, 25)
	UITheme.apply_menu_button(no_btn, 18)
	no_btn.pressed.connect(func():
		confirm_layer.queue_free()
	)
	no_btn.button_down.connect(func(): _on_btn_press(no_btn))
	no_btn.button_up.connect(func(): _on_btn_release(no_btn))
	btn_row.add_child(no_btn)
	
	add_child(confirm_layer)


# =============================================================================
# SHARED SUB-SCREEN BUILDERS
# =============================================================================

## Creates a full-screen Control on the given CanvasLayer.
## Includes a semi-transparent dark backdrop for legibility over the
## revolving cinematic backgrounds.
func _make_fullscreen_root(layer: CanvasLayer) -> Control:
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	# Dark scrim for legibility over the revolving backgrounds
	var scrim = ColorRect.new()
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.color = Color(0.0, 0.0, 0.0, 0.55)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(scrim)

	return root

## Creates the standard page layout:
##   logo (top-center) + page title label + a content VBoxContainer inside a
##   content_box panel centred on screen.
## Returns the inner VBoxContainer for callers to populate.
func _make_page_content(root: Control, page_title: String,
		panel_w: float, panel_h: float) -> VBoxContainer:

	# Logo at top of every sub-screen (smaller than main menu logo)
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
	root.add_child(logo)

	# Page title (e.g. "SETTINGS")
	var title_lbl = Label.new()
	title_lbl.text = page_title
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title_lbl.custom_minimum_size = Vector2(800, 60)
	title_lbl.position = Vector2(-400, slh + 32)
	UITheme.style_label(title_lbl, UITheme.TITLE_FONT, UITheme.C_GOLD, true)
	root.add_child(title_lbl)

	# Gold separator under title
	var sep = UITheme.make_separator()
	sep.set_anchors_preset(Control.PRESET_CENTER_TOP)
	sep.custom_minimum_size = Vector2(640, 4)
	sep.position = Vector2(-320, slh + 32 + 62)
	root.add_child(sep)

	# Content panel — centred
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(panel_w, panel_h)
	panel.position = Vector2(-panel_w * 0.5, -panel_h * 0.5 + 32)
	UITheme.apply_panel(panel)
	root.add_child(panel)

	# Scroll inside panel
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	# Inner VBox for content
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(vbox)

	return vbox

## Action button for sub-screens (uses same texture, smaller size)
func _make_action_btn(label: String) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(UITheme.BTN_SM_W, UITheme.BTN_SM_H)
	# Set pivot to centre so scale animations shrink evenly
	btn.pivot_offset = Vector2(UITheme.BTN_SM_W * 0.5, UITheme.BTN_SM_H * 0.5)
	UITheme.apply_menu_button(btn, UITheme.BTN_SM_FONT)
	btn.button_down.connect(_on_btn_press.bind(btn))
	btn.button_up.connect(_on_btn_release.bind(btn))
	return btn

## BACK button anchored bottom-left — used on every sub-screen
func _add_back_button(root: Control, callback: Callable) -> void:
	var back = _make_action_btn("BACK")
	back.name = "BackBtn"
	back.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	back.position = Vector2(UITheme.PAD * 2, -(UITheme.BTN_SM_H + UITheme.PAD * 2))
	back.pressed.connect(callback)
	root.add_child(back)





# =============================================================================
# CREDITS CONTENT HELPERS
# =============================================================================

func _add_credits_section(parent: VBoxContainer, text: String) -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	parent.add_child(spacer)

	var lbl = Label.new()
	lbl.text = text
	UITheme.style_label(lbl, 14, UITheme.C_GOLD, true)
	parent.add_child(lbl)

	parent.add_child(UITheme.make_separator())

func _add_credits_entry(parent: VBoxContainer, role: String, name_text: String) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var role_lbl = Label.new()
	role_lbl.text = role
	role_lbl.custom_minimum_size = Vector2(220, 0)
	role_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UITheme.style_label(role_lbl, 13, UITheme.C_DIM)
	row.add_child(role_lbl)

	var name_lbl = Label.new()
	name_lbl.text = name_text
	UITheme.style_label(name_lbl, 13, UITheme.C_WARM_WHITE)
	row.add_child(name_lbl)

	parent.add_child(row)

func _add_credits_text(parent: VBoxContainer, text: String) -> void:
	var lbl = Label.new()
	lbl.text = "  •  " + text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.style_label(lbl, 13, UITheme.C_WARM_WHITE)
	parent.add_child(lbl)


# =============================================================================
# SCENE TRANSITION TO GAME
# =============================================================================

func _play_transition_to_game() -> void:
	var tw = create_tween()
	tw.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	tw.tween_callback(_switch_to_game)

func _switch_to_game() -> void:
	if SceneManagerAutoload:
		SceneManagerAutoload.change_scene("main", false)
	else:
		push_warning("StartMenu: SceneManagerAutoload not found — direct scene change.")
		get_tree().change_scene_to_file("res://scenes/main.tscn")
