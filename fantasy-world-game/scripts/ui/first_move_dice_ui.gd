## First Move Dice UI
## Shows the initial dice roll to determine which player moves first
## Displays animated rolling dice for both players and announces the winner
class_name FirstMoveDiceUI
extends CanvasLayer

# =============================================================================
# SIGNALS
# =============================================================================
signal roll_complete(first_player_id: int)

# =============================================================================
# CONSTANTS
# =============================================================================
const ROLL_DURATION: float = 2.0 # Total roll animation time
const ROLL_INTERVAL: float = 0.06 # Time between number changes
const RESULT_DISPLAY_TIME: float = 2.5 # How long to show winner
const DICE_TYPE: int = 20 # d20

# =============================================================================
# COLORS
# =============================================================================
const PLAYER1_COLOR = Color(0.2, 0.5, 1.0) # Blue
const PLAYER2_COLOR = Color(1.0, 0.3, 0.2) # Red
const COLOR_GOLD = Color(1.0, 0.84, 0.0) # Winner highlight
const COLOR_BG = Color(0.03, 0.03, 0.08, 0.97)
const COLOR_DIM = Color(0.5, 0.5, 0.5)

# =============================================================================
# UI ELEMENTS
# =============================================================================
var root_control: Control
var overlay: ColorRect
var main_panel: PanelContainer
var content_container: VBoxContainer

# Header
var title_label: Label
var subtitle_label: Label

# Dice display
var dice_container: HBoxContainer
var p1_dice_panel: PanelContainer
var p2_dice_panel: PanelContainer
var p1_roll_label: Label
var p2_roll_label: Label
var p1_name_label: Label
var p2_name_label: Label
var vs_label: Label

# Result
var result_label: Label
var instruction_label: Label

# Animation state
var is_rolling: bool = false
var roll_timer: Timer
var final_p1_roll: int = 0
var final_p2_roll: int = 0
var first_player_id: int = 0
var tween: Tween
var current_p1_display: int = 1
var current_p2_display: int = 1

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	visible = false # Start hidden
	layer = 110 # Above other UI
	_create_ui()


func _create_ui() -> void:
	print("FirstMoveDiceUI: Creating UI...")
	
	# Root control for everything
	root_control = Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	
	# Darkened background overlay
	overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(overlay)
	
	# Use CenterContainer to reliably center the panel
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(center_container)
	
	# Main panel inside the center container
	main_panel = PanelContainer.new()
	main_panel.custom_minimum_size = Vector2(600, 450)
	main_panel.pivot_offset = Vector2(300, 225)
	center_container.add_child(main_panel)
	
	# Style the main panel — UITheme overlay
	main_panel.add_theme_stylebox_override("panel", UITheme.overlay_panel(UITheme.C_GOLD))
	
	# Content container
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 35)
	margin.add_theme_constant_override("margin_bottom", 35)
	main_panel.add_child(margin)
	
	content_container = VBoxContainer.new()
	content_container.add_theme_constant_override("separation", 20)
	content_container.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(content_container)
	
	_create_header()
	_create_dice_display()
	_create_result_display()
	
	# Create roll timer
	roll_timer = Timer.new()
	roll_timer.one_shot = false
	roll_timer.timeout.connect(_on_roll_timer_tick)
	add_child(roll_timer)
	
	print("FirstMoveDiceUI: UI created successfully")


func _create_header() -> void:
	# Title
	title_label = Label.new()
	title_label.text = "🎲 FIRST MOVE ROLL 🎲"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(title_label, 32, UITheme.C_GOLD_BRIGHT, true)
	content_container.add_child(title_label)
	
	# Subtitle
	subtitle_label = Label.new()
	subtitle_label.text = "Rolling to see who moves first..."
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(subtitle_label, 16, UITheme.C_WARM_WHITE)
	content_container.add_child(subtitle_label)
	
	# Separator
	var sep = HSeparator.new()
	sep.add_theme_stylebox_override("separator", StyleBoxLine.new())
	content_container.add_child(sep)


func _create_dice_display() -> void:
	# Container for both dice
	dice_container = HBoxContainer.new()
	dice_container.alignment = BoxContainer.ALIGNMENT_CENTER
	dice_container.add_theme_constant_override("separation", 50)
	content_container.add_child(dice_container)
	
	# Player 1 dice
	p1_dice_panel = _create_player_dice_panel("PLAYER 1", PLAYER1_COLOR)
	dice_container.add_child(p1_dice_panel)
	
	# VS label
	vs_label = Label.new()
	vs_label.text = "VS"
	vs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs_label.add_theme_font_size_override("font_size", 28)
	vs_label.add_theme_color_override("font_color", Color.YELLOW)
	dice_container.add_child(vs_label)
	
	# Player 2 dice
	p2_dice_panel = _create_player_dice_panel("PLAYER 2", PLAYER2_COLOR)
	dice_container.add_child(p2_dice_panel)


func _create_player_dice_panel(player_name: String, color: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 180)
	
	panel.add_theme_stylebox_override("panel", UITheme.section_panel(color))
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	# Player name label
	var name_label = Label.new()
	name_label.text = player_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(name_label, 18, color, true)
	vbox.add_child(name_label)
	
	# Dice roll value (the big number)
	var roll_label = Label.new()
	roll_label.text = "?"
	roll_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	roll_label.custom_minimum_size = Vector2(100, 80)
	UITheme.style_label(roll_label, 64, Color.WHITE, true)
	vbox.add_child(roll_label)
	
	# d20 indicator
	var dice_type_label = Label.new()
	dice_type_label.text = "d20"
	dice_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(dice_type_label, 14, UITheme.C_DIM)
	vbox.add_child(dice_type_label)
	
	# Store references based on player
	if player_name == "PLAYER 1":
		p1_roll_label = roll_label
		p1_name_label = name_label
	else:
		p2_roll_label = roll_label
		p2_name_label = name_label
	
	return panel


func _create_result_display() -> void:
	# Separator
	var sep = HSeparator.new()
	sep.add_theme_stylebox_override("separator", StyleBoxLine.new())
	content_container.add_child(sep)
	
	# Result label (who goes first)
	result_label = Label.new()
	result_label.text = ""
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(result_label, 24, UITheme.C_GOLD_BRIGHT, true)
	content_container.add_child(result_label)
	
	# Instruction label
	instruction_label = Label.new()
	instruction_label.text = ""
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(instruction_label, 14, UITheme.C_DIM)
	content_container.add_child(instruction_label)


# =============================================================================
# PUBLIC METHODS
# =============================================================================

## Start the first move dice roll animation
## p1_roll and p2_roll should be pre-calculated for deterministic results
func show_roll(p1_roll: int, p2_roll: int) -> void:
	print("FirstMoveDiceUI.show_roll called with P1=%d, P2=%d" % [p1_roll, p2_roll])
	
	final_p1_roll = p1_roll
	final_p2_roll = p2_roll
	
	# Determine winner
	if p1_roll > p2_roll:
		first_player_id = 0
	elif p2_roll > p1_roll:
		first_player_id = 1
	else:
		# Tie - player 1 goes first (could be re-rolled in full implementation)
		first_player_id = 0
	
	# Reset display
	p1_roll_label.text = "?"
	p2_roll_label.text = "?"
	p1_roll_label.add_theme_color_override("font_color", Color.WHITE)
	p2_roll_label.add_theme_color_override("font_color", Color.WHITE)
	result_label.text = ""
	instruction_label.text = ""
	subtitle_label.text = "Rolling to see who moves first..."
	
	# Reset panel borders to default colors
	_reset_panel_border(p1_dice_panel, PLAYER1_COLOR)
	_reset_panel_border(p2_dice_panel, PLAYER2_COLOR)
	
	# Show with animation
	visible = true # Show the CanvasLayer
	root_control.visible = true
	main_panel.modulate.a = 0
	main_panel.scale = Vector2(0.85, 0.85)
	
	print("FirstMoveDiceUI: root_control visible=%s, main_panel=%s" % [root_control.visible, main_panel != null])
	
	if tween and tween.is_running():
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(main_panel, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(main_panel, "modulate:a", 1.0, 0.3)
	
	print("FirstMoveDiceUI: Tween started, waiting for animation...")
	
	# Start rolling animation after entrance
	tween.chain().tween_callback(_start_rolling)


func _start_rolling() -> void:
	is_rolling = true
	roll_timer.start(ROLL_INTERVAL)
	
	# Stop rolling after duration and show results
	var result_timer = get_tree().create_timer(ROLL_DURATION)
	result_timer.timeout.connect(_show_final_result)


func _show_final_result() -> void:
	is_rolling = false
	roll_timer.stop()
	
	# Show final values
	p1_roll_label.text = str(final_p1_roll)
	p2_roll_label.text = str(final_p2_roll)
	
	# Highlight the winner
	var winner_name = "PLAYER 1" if first_player_id == 0 else "PLAYER 2"
	var _winner_color = PLAYER1_COLOR if first_player_id == 0 else PLAYER2_COLOR
	
	if first_player_id == 0:
		p1_roll_label.add_theme_color_override("font_color", COLOR_GOLD)
		p2_roll_label.add_theme_color_override("font_color", COLOR_DIM)
		_highlight_winner_panel(p1_dice_panel)
		_dim_loser_panel(p2_dice_panel)
	else:
		p2_roll_label.add_theme_color_override("font_color", COLOR_GOLD)
		p1_roll_label.add_theme_color_override("font_color", COLOR_DIM)
		_highlight_winner_panel(p2_dice_panel)
		_dim_loser_panel(p1_dice_panel)
	
	# Announce winner
	if final_p1_roll == final_p2_roll:
		result_label.text = "🎲 TIE! %s goes first (d20 advantage) 🎲" % winner_name
	else:
		result_label.text = "🏆 %s MOVES FIRST! 🏆" % winner_name
	
	subtitle_label.text = "%s rolled %d — %s rolled %d" % [
		"Player 1", final_p1_roll,
		"Player 2", final_p2_roll
	]
	
	instruction_label.text = "Click anywhere or press any key to continue..."
	
	_pulse_label(result_label)
	
	# Enable dismissal input after a short delay
	var dismiss_timer = get_tree().create_timer(0.5)
	dismiss_timer.timeout.connect(func(): _enable_dismiss())


var _can_dismiss: bool = false

func _enable_dismiss() -> void:
	_can_dismiss = true


func _highlight_winner_panel(panel: PanelContainer) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.08)
	style.border_color = COLOR_GOLD
	style.set_border_width_all(4)
	style.set_corner_radius_all(15)
	style.shadow_color = Color(1.0, 0.8, 0.0, 0.3)
	style.shadow_size = 10
	panel.add_theme_stylebox_override("panel", style)


func _dim_loser_panel(panel: PanelContainer) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.08)
	style.border_color = Color(0.3, 0.3, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(15)
	panel.add_theme_stylebox_override("panel", style)


func _reset_panel_border(panel: PanelContainer, color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12)
	style.border_color = color
	style.set_border_width_all(3)
	style.set_corner_radius_all(15)
	panel.add_theme_stylebox_override("panel", style)


func _pulse_label(label: Label) -> void:
	# Use modulate animation instead of scale (Labels don't scale well without pivot)
	var pulse = create_tween()
	var _original_color = label.get_theme_color("font_color")
	pulse.tween_property(label, "modulate", Color(1.3, 1.3, 1.0, 1.0), 0.12)
	pulse.tween_property(label, "modulate", Color.WHITE, 0.12)


func _hide_immediate() -> void:
	if root_control:
		root_control.visible = false
	visible = false # Also hide the CanvasLayer itself
	_can_dismiss = false


func hide_ui() -> void:
	_can_dismiss = false
	
	if tween and tween.is_running():
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(main_panel, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func():
		root_control.visible = false
		visible = false # Also hide the CanvasLayer
		roll_complete.emit(first_player_id)
	)


# =============================================================================
# ANIMATION
# =============================================================================

func _on_roll_timer_tick() -> void:
	if not is_rolling:
		return
	
	# Randomize displayed numbers
	current_p1_display = randi_range(1, DICE_TYPE)
	current_p2_display = randi_range(1, DICE_TYPE)
	
	p1_roll_label.text = str(current_p1_display)
	p2_roll_label.text = str(current_p2_display)


# =============================================================================
# INPUT
# =============================================================================

func _input(event: InputEvent) -> void:
	if not root_control.visible:
		return
	
	if not _can_dismiss:
		return
	
	# Dismiss with click or key press
	if event is InputEventMouseButton and event.pressed:
		hide_ui()
	elif event is InputEventKey and event.pressed:
		if event.keycode != KEY_ESCAPE: # Don't dismiss with Escape
			hide_ui()
