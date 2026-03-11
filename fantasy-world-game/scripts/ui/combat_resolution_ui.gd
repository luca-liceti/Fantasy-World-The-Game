## Combat Resolution UI
## Displays combat resolution: dice rolls, damage, effects
## Part of the D&D × Pokémon hybrid combat system
class_name CombatResolutionUI
extends CanvasLayer

# =============================================================================
# SIGNALS
# =============================================================================
signal resolution_complete()

# =============================================================================
# UI ELEMENTS
# =============================================================================
var main_container: Control
var resolution_panel: PanelContainer
var content_container: VBoxContainer

# Header
var header_label: Label

# Roll display
var roll_container: HBoxContainer
var attacker_roll_panel: PanelContainer
var defender_roll_panel: PanelContainer
var attacker_roll_label: Label
var defender_roll_label: Label
var vs_label: Label

# Result display
var result_label: Label
var damage_label: Label
var damage_breakdown_label: Label # Added for Phase 12.2
var effectiveness_label: Label
var status_label: Label
var triggers_label: Label # Added for Phase 12.2 (Reactions)
var counter_label: Label

# Damage popup container
var popup_container: Control
var active_popups: Array[Node] = []

# Animation state
var is_animating: bool = false
var animation_timer: float = 0.0
const ANIMATION_DURATION: float = 3.5 # Slightly increased reading time


# =============================================================================
# COLORS
# =============================================================================
const HIT_COLOR = Color(0.3, 0.9, 0.3)
const MISS_COLOR = Color(0.9, 0.3, 0.3)
const CRIT_COLOR = Color(1.0, 0.85, 0.0)
const NORMAL_DAMAGE_COLOR = Color.WHITE
const SUPER_EFFECTIVE_COLOR = Color(0.4, 1.0, 0.4)
const NOT_EFFECTIVE_COLOR = Color(0.6, 0.6, 0.6)


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	visible = false
	_create_ui()


func _process(delta: float) -> void:
	if is_animating:
		animation_timer -= delta
		if animation_timer <= 0:
			is_animating = false
			_on_animation_complete()


func _create_ui() -> void:
	# Main container
	main_container = Control.new()
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(main_container)
	
	# Semi-transparent overlay
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_container.add_child(overlay)
	
	# Popup container (for floating damage numbers)
	popup_container = Control.new()
	popup_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_container.add_child(popup_container)
	
	# Resolution panel (center)
	resolution_panel = PanelContainer.new()
	resolution_panel.set_anchors_preset(Control.PRESET_CENTER)
	resolution_panel.custom_minimum_size = Vector2(550, 450)
	resolution_panel.position = Vector2(-275, -225)
	main_container.add_child(resolution_panel)
	
	resolution_panel.add_theme_stylebox_override("panel", UITheme.overlay_panel(UITheme.C_GOLD))
	
	# Content
	content_container = VBoxContainer.new()
	content_container.add_theme_constant_override("separation", 10)
	resolution_panel.add_child(content_container)
	
	_create_header()
	_create_roll_display()
	_create_result_display()


func _create_header() -> void:
	header_label = Label.new()
	header_label.text = "⚔️ COMBAT RESOLUTION ⚔️"
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(header_label, 24, UITheme.C_GOLD_BRIGHT, true)
	content_container.add_child(header_label)


func _create_roll_display() -> void:
	roll_container = HBoxContainer.new()
	roll_container.alignment = BoxContainer.ALIGNMENT_CENTER
	roll_container.add_theme_constant_override("separation", 20)
	content_container.add_child(roll_container)
	
	# Attacker roll panel
	attacker_roll_panel = _create_roll_panel("ATTACKER", Color(0.9, 0.4, 0.4))
	roll_container.add_child(attacker_roll_panel)
	attacker_roll_label = attacker_roll_panel.get_node("VBox/RollLabel")
	
	# VS label
	vs_label = Label.new()
	vs_label.text = "VS"
	vs_label.add_theme_font_size_override("font_size", 28)
	vs_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	roll_container.add_child(vs_label)
	
	# Defender roll panel
	defender_roll_panel = _create_roll_panel("DEFENDER", Color(0.4, 0.5, 0.9))
	roll_container.add_child(defender_roll_panel)
	defender_roll_label = defender_roll_panel.get_node("VBox/RollLabel")


func _create_roll_panel(title: String, color: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(140, 100)
	
	panel.add_theme_stylebox_override("panel", UITheme.section_panel(color))
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	
	var title_label = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(title_label, 12, color)
	vbox.add_child(title_label)
	
	var roll_label = Label.new()
	roll_label.name = "RollLabel"
	roll_label.text = "0"
	roll_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(roll_label, 36, Color.WHITE, true)
	vbox.add_child(roll_label)
	
	var detail_label = Label.new()
	detail_label.name = "DetailLabel"
	detail_label.text = "(d20 + ATK)"
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(detail_label, 10, UITheme.C_DIM)
	vbox.add_child(detail_label)
	
	return panel


func _create_result_display() -> void:
	# Result (HIT/MISS)
	result_label = Label.new()
	result_label.text = "HIT!"
	result_label.add_theme_font_size_override("font_size", 36)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_container.add_child(result_label)
	
	# Triggers (Reactions)
	triggers_label = Label.new()
	triggers_label.text = ""
	triggers_label.add_theme_font_size_override("font_size", 14)
	triggers_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	triggers_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_container.add_child(triggers_label)
	
	# Damage Final
	damage_label = Label.new()
	damage_label.text = ""
	damage_label.add_theme_font_size_override("font_size", 24)
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_container.add_child(damage_label)
	
	# Damage Breakdown
	damage_breakdown_label = Label.new()
	damage_breakdown_label.text = ""
	damage_breakdown_label.add_theme_font_size_override("font_size", 12)
	damage_breakdown_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	damage_breakdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_container.add_child(damage_breakdown_label)
	
	# Type effectiveness
	effectiveness_label = Label.new()
	effectiveness_label.text = ""
	effectiveness_label.add_theme_font_size_override("font_size", 16)
	effectiveness_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_container.add_child(effectiveness_label)
	
	# Status effect
	status_label = Label.new()
	status_label.text = ""
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.9))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_container.add_child(status_label)
	
	# Counter damage
	counter_label = Label.new()
	counter_label.text = ""
	counter_label.add_theme_font_size_override("font_size", 16)
	counter_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
	counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_container.add_child(counter_label)


# =============================================================================
# PUBLIC METHODS
# =============================================================================

## Show combat resolution with full result data
func show_resolution(result: Dictionary) -> void:
	_clear_state()
	
	# Get combatant names
	var attacker_name = result["attacker"].display_name if result.get("attacker") else "Attacker"
	var defender_name = result["defender"].display_name if result.get("defender") else "Defender"
	
	header_label.text = "%s ⚔️ %s" % [attacker_name, defender_name]
	
	# Roll display
	var natural_roll = result.get("natural_roll", 0)
	var total_roll = result.get("total_attack_roll", 0)
	var defense_dc = result.get("defense_dc", 0)
	
	# Animate roll values
	attacker_roll_label.text = str(total_roll)
	defender_roll_label.text = str(defense_dc)
	
	# Update detail labels
	var atk_detail = attacker_roll_panel.get_node("VBox/DetailLabel")
	atk_detail.text = "(🎲%d + ATK)" % natural_roll
	
	var def_detail = defender_roll_panel.get_node("VBox/DetailLabel")
	def_detail.text = "(10 + DEF)"
	
	# Show result
	var is_hit = result.get("attack_succeeded", false)
	var is_crit = result.get("is_critical_hit", false)
	var is_crit_miss = result.get("is_critical_miss", false)
	
	if is_crit_miss:
		result_label.text = "💀 CRITICAL MISS!"
		result_label.add_theme_color_override("font_color", MISS_COLOR)
	elif is_crit:
		result_label.text = "⚡ CRITICAL HIT! ⚡"
		result_label.add_theme_color_override("font_color", CRIT_COLOR)
	elif is_hit:
		result_label.text = "✓ HIT!"
		result_label.add_theme_color_override("font_color", HIT_COLOR)
	else:
		result_label.text = "✗ MISS!"
		result_label.add_theme_color_override("font_color", MISS_COLOR)
	
	# Triggers (Reactions)
	var triggered_reactions = result.get("triggered_reactions", [])
	if not triggered_reactions.is_empty():
		var reaction_texts = []
		for reaction in triggered_reactions:
			reaction_texts.append("! %s !" % reaction)
		triggers_label.text = "\n".join(reaction_texts)
	else:
		triggers_label.text = ""
	
	# Damage display
	if is_hit:
		var damage = result.get("damage_dealt", 0)
		if is_crit:
			damage_label.text = "💥 %d DAMAGE!" % damage
			damage_label.add_theme_color_override("font_color", CRIT_COLOR)
		else:
			damage_label.text = "⚔️ %d Damage" % damage
			damage_label.add_theme_color_override("font_color", NORMAL_DAMAGE_COLOR)
		
		# Damage Breakdown
		var breakdown = result.get("damage_breakdown", "")
		if breakdown != "":
			damage_breakdown_label.text = breakdown
		
		# Type effectiveness
		var effectiveness = result.get("type_effectiveness", 1.0)
		if effectiveness > 1.0:
			effectiveness_label.text = "✨ Super Effective!"
			effectiveness_label.add_theme_color_override("font_color", SUPER_EFFECTIVE_COLOR)
		elif effectiveness < 1.0 and effectiveness > 0.0:
			effectiveness_label.text = "↓ Not Very Effective..."
			effectiveness_label.add_theme_color_override("font_color", NOT_EFFECTIVE_COLOR)
		elif effectiveness == 0.0:
			effectiveness_label.text = "🛡️ Immune!"
			effectiveness_label.add_theme_color_override("font_color", NOT_EFFECTIVE_COLOR)
		else:
			effectiveness_label.text = ""
		
		# Status effect
		var status = result.get("status_applied", "")
		if status != "":
			var effect_data = StatusEffects.get_effect_data(status)
			var effect_name = effect_data.get("effect_name", status)
			status_label.text = "💫 Applied %s!" % effect_name
		else:
			status_label.text = ""
		
		# Survived lethal
		if result.get("survived_lethal", false):
			status_label.text += "\n🛡️ Endured at 1 HP!"
		
		# Defender killed
		if result.get("defender_killed", false):
			damage_label.text += "\n💀 DEFEATED!"
	else:
		damage_label.text = ""
		damage_breakdown_label.text = ""
		effectiveness_label.text = ""
		status_label.text = ""
		
		# Counter damage
		var counter_dmg = result.get("counter_damage", 0)
		if counter_dmg > 0:
			counter_label.text = "↩️ Counter Attack! %d damage!" % counter_dmg
		else:
			counter_label.text = ""
	
	# Start animation
	is_animating = true
	animation_timer = ANIMATION_DURATION
	visible = true


## Create a floating damage popup at world position
func spawn_damage_popup(world_pos: Vector3, damage: int, is_crit: bool, effectiveness: float) -> void:
	var camera = get_viewport().get_camera_3d()
	if camera == null:
		return
	
	# Convert world to screen position
	var screen_pos = camera.unproject_position(world_pos)
	
	# Create popup label
	var popup = Label.new()
	popup.text = str(damage)
	popup.position = screen_pos - Vector2(30, 20)
	popup.z_index = 100
	
	# Style based on damage type
	if is_crit:
		popup.text = "💥 " + str(damage) + "!"
		popup.add_theme_font_size_override("font_size", 32)
		popup.add_theme_color_override("font_color", CRIT_COLOR)
	elif effectiveness > 1.0:
		popup.add_theme_font_size_override("font_size", 26)
		popup.add_theme_color_override("font_color", SUPER_EFFECTIVE_COLOR)
	elif effectiveness < 1.0:
		popup.add_theme_font_size_override("font_size", 22)
		popup.add_theme_color_override("font_color", NOT_EFFECTIVE_COLOR)
	else:
		popup.add_theme_font_size_override("font_size", 24)
		popup.add_theme_color_override("font_color", NORMAL_DAMAGE_COLOR)
	
	popup_container.add_child(popup)
	active_popups.append(popup)
	
	# Animate popup
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 80, 1.5).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 0.0, 1.5).set_delay(0.5)
	tween.chain().tween_callback(popup.queue_free)


## Hide the resolution UI
func hide_resolution() -> void:
	visible = false
	is_animating = false
	_clear_popups()


# =============================================================================
# PRIVATE METHODS
# =============================================================================

func _clear_state() -> void:
	damage_label.text = ""
	damage_breakdown_label.text = ""
	effectiveness_label.text = ""
	status_label.text = ""
	counter_label.text = ""
	triggers_label.text = ""


func _clear_popups() -> void:
	for popup in active_popups:
		if is_instance_valid(popup):
			popup.queue_free()
	active_popups.clear()


func _on_animation_complete() -> void:
	resolution_complete.emit()
	# Auto-hide after a short delay
	await get_tree().create_timer(0.5).timeout
	hide_resolution()
