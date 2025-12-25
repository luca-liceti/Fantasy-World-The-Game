## Dice UI
## Visual dice rolling interface for combat
## Shows animated d20 dice rolls for attacker and defender
class_name DiceUI
extends CanvasLayer

# =============================================================================
# SIGNALS
# =============================================================================
signal roll_animation_complete()
signal dice_dismissed()

# =============================================================================
# CONSTANTS
# =============================================================================
const ROLL_DURATION: float = 1.5 # Duration of rolling animation
const ROLL_INTERVAL: float = 0.08 # Time between number changes during roll
const RESULT_DISPLAY_TIME: float = 2.0 # How long to show result
const CRITICAL_THRESHOLD: int = 18 # 18-20 is critical

# =============================================================================
# COLORS
# =============================================================================
const COLOR_ATTACKER = Color(1.0, 0.3, 0.2) # Red
const COLOR_DEFENDER = Color(0.2, 0.5, 1.0) # Blue
const COLOR_CRITICAL = Color(1.0, 0.84, 0.0) # Gold
const COLOR_SUCCESS = Color(0.3, 0.9, 0.3) # Green
const COLOR_FAILURE = Color(0.5, 0.5, 0.5) # Gray
const COLOR_BG = Color(0.05, 0.05, 0.1, 0.95)

# =============================================================================
# UI ELEMENTS
# =============================================================================
var main_panel: PanelContainer
var content_container: VBoxContainer

# Header
var title_label: Label
var subtitle_label: Label

# Dice display
var dice_container: HBoxContainer
var attacker_dice_panel: PanelContainer
var defender_dice_panel: PanelContainer
var attacker_value_label: Label
var defender_value_label: Label
var attacker_stat_label: Label
var defender_stat_label: Label
var attacker_total_label: Label
var defender_total_label: Label

# Result display
var result_label: Label
var damage_label: Label
var vs_label: Label

# Reroll indicator
var reroll_label: Label

# Animation
var tween: Tween
var roll_timer: Timer
var is_rolling: bool = false
var current_attacker_display: int = 1
var current_defender_display: int = 1
var final_attacker_roll: int = 0
var final_defender_roll: int = 0
var attacker_stat: int = 0
var defender_stat: int = 0

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	layer = 100 # Above game UI
	_create_ui()
	hide_dice()


func _create_ui() -> void:
	# Darkened background overlay
	var overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	
	# Main centered panel
	main_panel = PanelContainer.new()
	# Set anchors to center (0.5, 0.5) for all corners
	main_panel.anchor_left = 0.5
	main_panel.anchor_top = 0.5
	main_panel.anchor_right = 0.5
	main_panel.anchor_bottom = 0.5
	# Set offsets to position the panel centered around the anchor point
	# Panel size is 500x400, so offsets are -250 to +250 horizontally and -200 to +200 vertically
	main_panel.offset_left = -250
	main_panel.offset_top = -200
	main_panel.offset_right = 250
	main_panel.offset_bottom = 200
	main_panel.custom_minimum_size = Vector2(500, 400)
	main_panel.pivot_offset = Vector2(250, 200)
	add_child(main_panel)
	
	# Style the main panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = COLOR_BG
	panel_style.border_color = Color(0.6, 0.5, 0.3)
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(15)
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 20
	main_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Content container
	content_container = VBoxContainer.new()
	content_container.add_theme_constant_override("separation", 15)
	content_container.alignment = BoxContainer.ALIGNMENT_CENTER
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	main_panel.add_child(margin)
	margin.add_child(content_container)
	
	_create_header()
	_create_dice_display()
	_create_result_display()
	
	# Create roll timer
	roll_timer = Timer.new()
	roll_timer.one_shot = false
	roll_timer.timeout.connect(_on_roll_timer_tick)
	add_child(roll_timer)


func _create_header() -> void:
	# Title
	title_label = Label.new()
	title_label.text = "⚔️ COMBAT ⚔️"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	content_container.add_child(title_label)
	
	# Subtitle (combatants)
	subtitle_label = Label.new()
	subtitle_label.text = "Attacker vs Defender"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 16)
	subtitle_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	content_container.add_child(subtitle_label)
	
	# Separator
	var sep = HSeparator.new()
	sep.add_theme_stylebox_override("separator", StyleBoxLine.new())
	content_container.add_child(sep)


func _create_dice_display() -> void:
	# Container for both dice
	dice_container = HBoxContainer.new()
	dice_container.alignment = BoxContainer.ALIGNMENT_CENTER
	dice_container.add_theme_constant_override("separation", 40)
	content_container.add_child(dice_container)
	
	# Attacker dice
	attacker_dice_panel = _create_dice_panel("ATTACKER", COLOR_ATTACKER)
	dice_container.add_child(attacker_dice_panel)
	
	# VS label
	vs_label = Label.new()
	vs_label.text = "VS"
	vs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs_label.add_theme_font_size_override("font_size", 24)
	vs_label.add_theme_color_override("font_color", Color.YELLOW)
	dice_container.add_child(vs_label)
	
	# Defender dice
	defender_dice_panel = _create_dice_panel("DEFENDER", COLOR_DEFENDER)
	dice_container.add_child(defender_dice_panel)
	
	# Reroll indicator
	reroll_label = Label.new()
	reroll_label.text = ""
	reroll_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reroll_label.add_theme_font_size_override("font_size", 18)
	reroll_label.add_theme_color_override("font_color", Color.ORANGE)
	reroll_label.visible = false
	content_container.add_child(reroll_label)


func _create_dice_panel(label_text: String, color: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(160, 200)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15)
	style.border_color = color
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(margin)
	margin.add_child(vbox)
	
	# Role label
	var role_label = Label.new()
	role_label.text = label_text
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_label.add_theme_font_size_override("font_size", 14)
	role_label.add_theme_color_override("font_color", color)
	vbox.add_child(role_label)
	
	# Dice value (the big number)
	var value_label = Label.new()
	value_label.text = "?"
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 48)
	value_label.add_theme_color_override("font_color", Color.WHITE)
	value_label.custom_minimum_size = Vector2(80, 60)
	vbox.add_child(value_label)
	
	# Stat bonus label
	var stat_label = Label.new()
	stat_label.text = "+ ATK 0"
	stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat_label.add_theme_font_size_override("font_size", 14)
	stat_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	vbox.add_child(stat_label)
	
	# Total label
	var total_label = Label.new()
	total_label.text = "= 0"
	total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total_label.add_theme_font_size_override("font_size", 22)
	total_label.add_theme_color_override("font_color", color)
	vbox.add_child(total_label)
	
	# Store references based on which panel this is
	if label_text == "ATTACKER":
		attacker_value_label = value_label
		attacker_stat_label = stat_label
		attacker_total_label = total_label
	else:
		defender_value_label = value_label
		defender_stat_label = stat_label
		defender_total_label = total_label
	
	return panel


func _create_result_display() -> void:
	# Separator
	var sep = HSeparator.new()
	sep.add_theme_stylebox_override("separator", StyleBoxLine.new())
	content_container.add_child(sep)
	
	# Result label
	result_label = Label.new()
	result_label.text = "Rolling..."
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 26)
	result_label.add_theme_color_override("font_color", Color.WHITE)
	content_container.add_child(result_label)
	
	# Damage label
	damage_label = Label.new()
	damage_label.text = ""
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_label.add_theme_font_size_override("font_size", 18)
	damage_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	content_container.add_child(damage_label)


# =============================================================================
# PUBLIC METHODS
# =============================================================================

## Show dice with combatant info and start rolling animation
func show_combat(attacker_name: String, defender_name: String, atk_stat: int, def_stat: int) -> void:
	subtitle_label.text = "%s vs %s" % [attacker_name, defender_name]
	attacker_stat = atk_stat
	defender_stat = def_stat
	
	# Reset display
	attacker_value_label.text = "?"
	defender_value_label.text = "?"
	attacker_stat_label.text = "+ ATK %d" % atk_stat
	defender_stat_label.text = "+ DEF %d" % def_stat
	attacker_total_label.text = "= ?"
	defender_total_label.text = "= ?"
	result_label.text = "Rolling..."
	result_label.add_theme_color_override("font_color", Color.WHITE)
	damage_label.text = ""
	reroll_label.visible = false
	
	visible = true
	
	# Animate panel entrance
	main_panel.scale = Vector2(0.8, 0.8)
	main_panel.modulate.a = 0
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(main_panel, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(main_panel, "modulate:a", 1.0, 0.2)


## Start the dice rolling animation
func start_roll() -> void:
	is_rolling = true
	roll_timer.start(ROLL_INTERVAL)


## Show the final roll result
func show_result(atk_roll: int, def_roll: int, atk_total: int, def_total: int, attack_succeeded: bool, damage: int, is_critical: bool) -> void:
	is_rolling = false
	roll_timer.stop()
	
	final_attacker_roll = atk_roll
	final_defender_roll = def_roll
	
	# Update dice displays
	attacker_value_label.text = str(atk_roll)
	defender_value_label.text = str(def_roll)
	
	# Style critical rolls
	if atk_roll >= CRITICAL_THRESHOLD:
		attacker_value_label.add_theme_color_override("font_color", COLOR_CRITICAL)
		_pulse_label(attacker_value_label)
	else:
		attacker_value_label.add_theme_color_override("font_color", Color.WHITE)
	
	if def_roll >= CRITICAL_THRESHOLD:
		defender_value_label.add_theme_color_override("font_color", COLOR_CRITICAL)
	else:
		defender_value_label.add_theme_color_override("font_color", Color.WHITE)
	
	# Update totals
	attacker_total_label.text = "= %d" % atk_total
	defender_total_label.text = "= %d" % def_total
	
	# Show result
	if attack_succeeded:
		if is_critical:
			result_label.text = "💥 CRITICAL HIT! 💥"
			result_label.add_theme_color_override("font_color", COLOR_CRITICAL)
			damage_label.text = "%d DAMAGE!" % damage
			damage_label.add_theme_color_override("font_color", COLOR_CRITICAL)
		else:
			result_label.text = "✓ HIT!"
			result_label.add_theme_color_override("font_color", COLOR_SUCCESS)
			damage_label.text = "%d damage dealt" % damage
			damage_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		result_label.text = "✗ BLOCKED!"
		result_label.add_theme_color_override("font_color", COLOR_FAILURE)
		damage_label.text = "Attack deflected"
		damage_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	
	_pulse_label(result_label)
	
	# Emit completion
	roll_animation_complete.emit()


## Show reroll indicator
func show_reroll(roll_number: int, reason: String) -> void:
	reroll_label.text = "🎲 Reroll #%d - %s" % [roll_number, reason]
	reroll_label.visible = true
	
	# Reset dice for new roll
	attacker_value_label.text = "?"
	defender_value_label.text = "?"
	attacker_total_label.text = "= ?"
	defender_total_label.text = "= ?"


## Hide the dice UI
func hide_dice() -> void:
	if tween and tween.is_running():
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(main_panel, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): visible = false)
	tween.tween_callback(func(): dice_dismissed.emit())


## Instant hide (no animation)
func hide_immediate() -> void:
	visible = false


# =============================================================================
# ANIMATION
# =============================================================================

func _on_roll_timer_tick() -> void:
	if not is_rolling:
		return
	
	# Randomize displayed numbers
	current_attacker_display = randi_range(1, 20)
	current_defender_display = randi_range(1, 20)
	
	attacker_value_label.text = str(current_attacker_display)
	defender_value_label.text = str(current_defender_display)
	
	# Update totals during roll
	attacker_total_label.text = "= %d" % (current_attacker_display + attacker_stat)
	defender_total_label.text = "= %d" % (current_defender_display + defender_stat)


func _pulse_label(label: Label) -> void:
	var pulse = create_tween()
	pulse.tween_property(label, "scale", Vector2(1.2, 1.2), 0.1)
	pulse.tween_property(label, "scale", Vector2(1.0, 1.0), 0.1)


# =============================================================================
# INPUT HANDLING
# =============================================================================

func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	# Allow dismissing with click or any key after result is shown
	if not is_rolling:
		if event is InputEventMouseButton and event.pressed:
			hide_dice()
		elif event is InputEventKey and event.pressed:
			hide_dice()


# =============================================================================
# QUICK COMBAT DISPLAY
# =============================================================================

## Convenience method to show full combat sequence
func display_combat_sequence(
	attacker_name: String,
	defender_name: String,
	atk_stat: int,
	def_stat: int,
	atk_roll: int,
	def_roll: int,
	attack_succeeded: bool,
	damage: int,
	is_critical: bool
) -> void:
	show_combat(attacker_name, defender_name, atk_stat, def_stat)
	
	# Start rolling, then show result after animation
	start_roll()
	
	# Use a timer to show the result after roll duration
	var result_timer = get_tree().create_timer(ROLL_DURATION)
	result_timer.timeout.connect(func():
		var atk_total = atk_roll + atk_stat
		var def_total = def_roll + def_stat
		show_result(atk_roll, def_roll, atk_total, def_total, attack_succeeded, damage, is_critical)
	)
