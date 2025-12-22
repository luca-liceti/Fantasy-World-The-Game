## Start Menu
## Main menu UI with Play, Settings, and Quit options
## Features animated background, title effects, and smooth transitions
class_name StartMenu
extends Control

# Preload dependencies
const SettingsMenuScene = preload("res://scripts/ui/settings_menu.gd")
const LobbyUIScene = preload("res://scripts/ui/lobby_ui.gd")

# =============================================================================
# SIGNALS
# =============================================================================
signal play_pressed
signal multiplayer_pressed
signal settings_pressed
signal quit_pressed

# =============================================================================
# UI ELEMENTS
# =============================================================================
var background: ColorRect
var particles_container: Control
var title_container: VBoxContainer
var title_label: Label
var subtitle_label: Label
var button_container: VBoxContainer
var play_button: Button
var multiplayer_button: Button
var settings_button: Button
var quit_button: Button
var lobby_ui: Node = null # LobbyUI instance
var version_label: Label

# Animation tweens
var title_tween: Tween
var button_tweens: Array[Tween] = []

# Particle effect
var particles: Array[Dictionary] = []
const NUM_PARTICLES: int = 50

# =============================================================================
# COLORS & STYLING
# =============================================================================
const BG_COLOR_TOP = Color(0.05, 0.08, 0.15, 1.0) # Deep dark blue
const BG_COLOR_BOTTOM = Color(0.12, 0.08, 0.18, 1.0) # Deep purple
const TITLE_COLOR = Color(0.95, 0.85, 0.55, 1.0) # Golden
const TITLE_GLOW = Color(1.0, 0.9, 0.5, 0.5) # Golden glow
const SUBTITLE_COLOR = Color(0.7, 0.75, 0.9, 1.0) # Light blue-silver
const BUTTON_BG = Color(0.15, 0.12, 0.25, 0.9) # Dark purple
const BUTTON_HOVER = Color(0.25, 0.2, 0.4, 0.95) # Lighter purple
const BUTTON_TEXT = Color(0.9, 0.85, 0.7, 1.0) # Warm white
const ACCENT_COLOR = Color(0.4, 0.6, 1.0, 1.0) # Blue accent
const PARTICLE_COLOR = Color(0.6, 0.7, 1.0, 0.3) # Soft blue particles


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_create_ui()
	_initialize_particles()
	_play_intro_animation()


func _create_ui() -> void:
	# Set anchors for full screen
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Create gradient background
	_create_background()
	
	# Create particle container
	_create_particles_container()
	
	# Create main content
	_create_title()
	_create_buttons()
	_create_version_label()


func _create_background() -> void:
	background = ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = BG_COLOR_TOP
	add_child(background)
	
	# Add a gradient overlay using a shader-like approach with multiple rects
	var gradient_overlay = ColorRect.new()
	gradient_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	gradient_overlay.color = Color(0, 0, 0, 0)
	add_child(gradient_overlay)
	
	# Create a vignette effect
	var vignette = ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0, 0, 0, 0.3)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)


func _create_particles_container() -> void:
	particles_container = Control.new()
	particles_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	particles_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(particles_container)


func _initialize_particles() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	if viewport_size == Vector2.ZERO:
		viewport_size = Vector2(1920, 1080)
	
	for i in range(NUM_PARTICLES):
		var particle = {
			"position": Vector2(randf() * viewport_size.x, randf() * viewport_size.y),
			"velocity": Vector2(randf_range(-20, 20), randf_range(-30, -10)),
			"size": randf_range(2, 6),
			"alpha": randf_range(0.1, 0.4),
			"pulse_speed": randf_range(1.0, 3.0),
			"pulse_offset": randf() * TAU
		}
		particles.append(particle)


func _create_title() -> void:
	title_container = VBoxContainer.new()
	title_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title_container.position = Vector2(-400, 120)
	title_container.custom_minimum_size = Vector2(800, 200)
	title_container.alignment = BoxContainer.ALIGNMENT_CENTER
	title_container.add_theme_constant_override("separation", 15)
	title_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_container)
	
	# Main title
	title_label = Label.new()
	title_label.text = "FANTASY WORLD"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 80)
	title_label.add_theme_color_override("font_color", TITLE_COLOR)
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	title_label.add_theme_constant_override("shadow_offset_x", 4)
	title_label.add_theme_constant_override("shadow_offset_y", 4)
	title_label.modulate.a = 0 # Start invisible for animation
	title_container.add_child(title_label)
	
	# Subtitle
	subtitle_label = Label.new()
	subtitle_label.text = "⚔️ The Board Game ⚔️"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 28)
	subtitle_label.add_theme_color_override("font_color", SUBTITLE_COLOR)
	subtitle_label.modulate.a = 0 # Start invisible for animation
	title_container.add_child(subtitle_label)


func _create_buttons() -> void:
	button_container = VBoxContainer.new()
	button_container.set_anchors_preset(Control.PRESET_CENTER)
	button_container.position = Vector2(-150, 50)
	button_container.custom_minimum_size = Vector2(300, 250)
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 20)
	add_child(button_container)
	
	# Play Button (Local/Singleplayer)
	play_button = _create_menu_button("⚔️  PLAY GAME  ⚔️", ACCENT_COLOR)
	play_button.pressed.connect(_on_play_pressed)
	play_button.modulate.a = 0
	
	# Multiplayer Button
	multiplayer_button = _create_menu_button("🌐  MULTIPLAYER", Color(0.3, 0.8, 0.4))
	multiplayer_button.pressed.connect(_on_multiplayer_pressed)
	multiplayer_button.modulate.a = 0
	
	# Settings Button
	settings_button = _create_menu_button("⚙️  SETTINGS", Color(0.6, 0.6, 0.7))
	settings_button.pressed.connect(_on_settings_pressed)
	settings_button.modulate.a = 0
	
	# Quit Button
	quit_button = _create_menu_button("🚪  QUIT", Color(0.8, 0.4, 0.4))
	quit_button.pressed.connect(_on_quit_pressed)
	quit_button.modulate.a = 0


func _create_menu_button(text: String, accent: Color) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(300, 60)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", BUTTON_TEXT)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Normal style
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = BUTTON_BG
	normal_style.border_color = accent.darkened(0.3)
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(12)
	normal_style.content_margin_left = 20
	normal_style.content_margin_right = 20
	normal_style.content_margin_top = 10
	normal_style.content_margin_bottom = 10
	button.add_theme_stylebox_override("normal", normal_style)
	
	# Hover style
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = BUTTON_HOVER
	hover_style.border_color = accent
	hover_style.set_border_width_all(3)
	hover_style.set_corner_radius_all(12)
	hover_style.content_margin_left = 20
	hover_style.content_margin_right = 20
	hover_style.content_margin_top = 10
	hover_style.content_margin_bottom = 10
	button.add_theme_stylebox_override("hover", hover_style)
	
	# Pressed style
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = accent.darkened(0.4)
	pressed_style.border_color = accent.lightened(0.2)
	pressed_style.set_border_width_all(3)
	pressed_style.set_corner_radius_all(12)
	pressed_style.content_margin_left = 20
	pressed_style.content_margin_right = 20
	pressed_style.content_margin_top = 10
	pressed_style.content_margin_bottom = 10
	button.add_theme_stylebox_override("pressed", pressed_style)
	
	# Focus style (same as hover)
	button.add_theme_stylebox_override("focus", hover_style)
	
	# Connect hover signals for animation
	button.mouse_entered.connect(_on_button_hover.bind(button))
	button.mouse_exited.connect(_on_button_unhover.bind(button))
	
	button_container.add_child(button)
	return button


func _create_version_label() -> void:
	version_label = Label.new()
	version_label.text = "v0.1.0 - Development Build"
	version_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	version_label.position = Vector2(-200, -40)
	version_label.add_theme_font_size_override("font_size", 14)
	version_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 0.7))
	add_child(version_label)


# =============================================================================
# ANIMATIONS
# =============================================================================

func _play_intro_animation() -> void:
	# Title fade in
	if title_tween:
		title_tween.kill()
	title_tween = create_tween()
	title_tween.set_ease(Tween.EASE_OUT)
	title_tween.set_trans(Tween.TRANS_CUBIC)
	
	# Title animation with scale bounce
	title_label.pivot_offset = title_label.size / 2
	title_tween.tween_property(title_label, "modulate:a", 1.0, 0.8)
	title_tween.parallel().tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.8).from(Vector2(0.8, 0.8))
	
	# Subtitle with delay
	title_tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.6).set_delay(0.2)
	
	# Buttons appear one by one
	var buttons = [play_button, multiplayer_button, settings_button, quit_button]
	for i in range(buttons.size()):
		var button = buttons[i]
		var delay = 0.6 + (i * 0.15)
		title_tween.parallel().tween_property(button, "modulate:a", 1.0, 0.4).set_delay(delay)
		title_tween.parallel().tween_property(button, "position:x", 0.0, 0.5).from(-50.0).set_delay(delay)


func _on_button_hover(button: Button) -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.15)
	button_tweens.append(tween)


func _on_button_unhover(button: Button) -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
	button_tweens.append(tween)


# =============================================================================
# PROCESS (Particle Animation)
# =============================================================================

func _process(delta: float) -> void:
	_update_particles(delta)
	_update_title_glow(delta)
	queue_redraw()


func _update_particles(delta: float) -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	if viewport_size == Vector2.ZERO:
		return
	
	for particle in particles:
		# Update position
		particle["position"] += particle["velocity"] * delta
		
		# Wrap around screen
		if particle["position"].y < -20:
			particle["position"].y = viewport_size.y + 20
			particle["position"].x = randf() * viewport_size.x
		if particle["position"].x < -20:
			particle["position"].x = viewport_size.x + 20
		if particle["position"].x > viewport_size.x + 20:
			particle["position"].x = -20
		
		# Pulse alpha
		var time = Time.get_ticks_msec() / 1000.0
		var pulse = sin(time * particle["pulse_speed"] + particle["pulse_offset"])
		particle["current_alpha"] = particle["alpha"] * (0.5 + 0.5 * pulse)


func _update_title_glow(delta: float) -> void:
	# Subtle pulsing glow on title
	var time = Time.get_ticks_msec() / 1000.0
	var glow_intensity = 0.85 + 0.15 * sin(time * 2.0)
	title_label.modulate = Color(glow_intensity, glow_intensity, glow_intensity, title_label.modulate.a)


func _draw() -> void:
	# Draw gradient background
	var viewport_size = get_viewport().get_visible_rect().size
	if viewport_size == Vector2.ZERO:
		viewport_size = Vector2(1920, 1080)
	
	# Draw multiple gradient layers for depth
	for i in range(20):
		var t = float(i) / 20.0
		var color = BG_COLOR_TOP.lerp(BG_COLOR_BOTTOM, t)
		var rect = Rect2(0, viewport_size.y * t, viewport_size.x, viewport_size.y / 20.0 + 1)
		draw_rect(rect, color)
	
	# Draw particles
	for particle in particles:
		var alpha = particle.get("current_alpha", particle["alpha"])
		var color = PARTICLE_COLOR
		color.a = alpha
		var pos = particle["position"]
		var size = particle["size"]
		draw_circle(pos, size, color)


# =============================================================================
# BUTTON CALLBACKS
# =============================================================================

func _on_play_pressed() -> void:
	print("Play button pressed!")
	_play_transition_out()
	play_pressed.emit()


func _on_multiplayer_pressed() -> void:
	print("Multiplayer button pressed!")
	multiplayer_pressed.emit()
	_open_lobby_ui()


func _on_settings_pressed() -> void:
	print("Settings button pressed!")
	settings_pressed.emit()
	_open_settings_menu()


func _open_settings_menu() -> void:
	var settings_menu = SettingsMenuScene.new()
	add_child(settings_menu)


func _open_lobby_ui() -> void:
	if lobby_ui != null:
		return # Already open
	
	lobby_ui = LobbyUIScene.new()
	lobby_ui.lobby_cancelled.connect(_on_lobby_cancelled)
	lobby_ui.game_starting.connect(_on_multiplayer_game_starting)
	add_child(lobby_ui)


func _on_lobby_cancelled() -> void:
	lobby_ui = null


func _on_multiplayer_game_starting() -> void:
	print("Multiplayer game starting!")
	# Transition to the game scene
	_play_transition_out()


func _on_quit_pressed() -> void:
	print("Quit button pressed!")
	quit_pressed.emit()
	get_tree().quit()


func _play_transition_out() -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Fade out all elements
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	
	# After transition, switch to game scene
	tween.tween_callback(_switch_to_game)


func _switch_to_game() -> void:
	# Switch to the main game scene
	get_tree().change_scene_to_file("res://scenes/main.tscn")
