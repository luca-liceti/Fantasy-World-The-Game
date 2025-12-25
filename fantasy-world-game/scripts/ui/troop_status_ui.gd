## Troop Status UI
## Displays status effects, cooldowns, and stat modifiers on troops
## Part of the D&D × Pokémon hybrid combat system
class_name TroopStatusUI
extends Control

# =============================================================================
# UI ELEMENTS
# =============================================================================
var status_container: HBoxContainer
var status_icons: Dictionary = {}  # effect_id -> TextureRect or Label

var stat_indicator_container: HBoxContainer
var atk_indicator: Label
var def_indicator: Label
var spd_indicator: Label

var cooldown_container: VBoxContainer
var cooldown_labels: Dictionary = {}  # move_id -> Label

# Reference to troop
var tracked_troop: Node = null


# =============================================================================
# COLORS
# =============================================================================
const BUFF_COLOR = Color(0.3, 0.8, 0.5)
const DEBUFF_COLOR = Color(0.9, 0.3, 0.3)
const NEUTRAL_COLOR = Color(0.7, 0.7, 0.8)


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_create_ui()
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _create_ui() -> void:
	# Main vertical layout
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	add_child(vbox)
	
	# Status effect icons (horizontal row above troop)
	status_container = HBoxContainer.new()
	status_container.alignment = BoxContainer.ALIGNMENT_CENTER
	status_container.add_theme_constant_override("separation", 4)
	vbox.add_child(status_container)
	
	# Stat stage indicators
	stat_indicator_container = HBoxContainer.new()
	stat_indicator_container.alignment = BoxContainer.ALIGNMENT_CENTER
	stat_indicator_container.add_theme_constant_override("separation", 8)
	vbox.add_child(stat_indicator_container)
	
	_create_stat_indicators()


func _create_stat_indicators() -> void:
	# ATK indicator
	atk_indicator = _create_stat_label("ATK")
	stat_indicator_container.add_child(atk_indicator)
	
	# DEF indicator
	def_indicator = _create_stat_label("DEF")
	stat_indicator_container.add_child(def_indicator)
	
	# SPD indicator
	spd_indicator = _create_stat_label("SPD")
	stat_indicator_container.add_child(spd_indicator)


func _create_stat_label(stat_name: String) -> Label:
	var label = Label.new()
	label.text = ""
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", NEUTRAL_COLOR)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.visible = false
	return label


# =============================================================================
# PUBLIC METHODS
# =============================================================================

## Attach to a troop and start tracking
func attach_to_troop(troop: Node) -> void:
	tracked_troop = troop
	update_display()


## Detach from current troop
func detach() -> void:
	tracked_troop = null
	_clear_status_icons()
	_hide_stat_indicators()


## Update the display based on troop state
func update_display() -> void:
	if tracked_troop == null:
		return
	
	_update_status_effects()
	_update_stat_indicators()


## Force update (call each frame or on change)
func _process(_delta: float) -> void:
	if tracked_troop and is_instance_valid(tracked_troop):
		# Keep positioned above troop
		if tracked_troop.current_hex:
			var world_pos = tracked_troop.global_position + Vector3(0, 2.0, 0)
			var camera = get_viewport().get_camera_3d()
			if camera:
				var screen_pos = camera.unproject_position(world_pos)
				global_position = screen_pos - Vector2(size.x / 2, size.y)
	else:
		visible = false


# =============================================================================
# STATUS EFFECTS
# =============================================================================

func _update_status_effects() -> void:
	if tracked_troop == null or not "active_status_effects" in tracked_troop:
		return
	
	# Get current active effects
	var current_effects: Array = []
	for effect in tracked_troop.active_status_effects:
		current_effects.append(effect.effect_id)
	
	# Remove icons for expired effects
	var to_remove: Array = []
	for effect_id in status_icons:
		if effect_id not in current_effects:
			to_remove.append(effect_id)
	
	for effect_id in to_remove:
		if status_icons[effect_id]:
			status_icons[effect_id].queue_free()
		status_icons.erase(effect_id)
	
	# Add icons for new effects
	for effect in tracked_troop.active_status_effects:
		if effect.effect_id not in status_icons:
			_add_status_icon(effect)
		else:
			# Update duration display
			var icon = status_icons[effect.effect_id]
			if icon and "remaining_turns" in effect:
				icon.tooltip_text = "%s (%d turns)" % [effect.effect_name, effect.remaining_turns]


func _add_status_icon(effect) -> void:
	var icon_container = PanelContainer.new()
	icon_container.custom_minimum_size = Vector2(24, 24)
	
	# Style based on buff/debuff
	var is_debuff = StatusEffects.is_debuff(effect.effect_id)
	var color = StatusEffects.get_effect_color(effect.effect_id)
	
	var style = StyleBoxFlat.new()
	style.bg_color = color.darkened(0.6)
	style.border_color = color
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	icon_container.add_theme_stylebox_override("panel", style)
	
	# Icon/emoji
	var icon_label = Label.new()
	icon_label.text = _get_effect_icon(effect.effect_id)
	icon_label.add_theme_font_size_override("font_size", 14)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_container.add_child(icon_label)
	
	# Tooltip
	icon_container.tooltip_text = "%s (%d turns)" % [effect.effect_name, effect.remaining_turns]
	
	status_container.add_child(icon_container)
	status_icons[effect.effect_id] = icon_container


func _get_effect_icon(effect_id: String) -> String:
	match effect_id:
		"stunned": return "⚡"
		"burned": return "🔥"
		"poisoned": return "☠️"
		"slowed": return "🐢"
		"cursed": return "💀"
		"terrified": return "😱"
		"rooted": return "🌿"
		"stealth": return "👻"
		_: return "❓"


func _clear_status_icons() -> void:
	for effect_id in status_icons:
		if status_icons[effect_id]:
			status_icons[effect_id].queue_free()
	status_icons.clear()


# =============================================================================
# STAT STAGE INDICATORS
# =============================================================================

func _update_stat_indicators() -> void:
	if tracked_troop == null or not "stat_stages" in tracked_troop:
		_hide_stat_indicators()
		return
	
	_update_single_stat(atk_indicator, "ATK", tracked_troop.stat_stages.get("atk", 0))
	_update_single_stat(def_indicator, "DEF", tracked_troop.stat_stages.get("def", 0))
	_update_single_stat(spd_indicator, "SPD", tracked_troop.stat_stages.get("speed", 0))


func _update_single_stat(label: Label, stat_name: String, stage: int) -> void:
	if stage == 0:
		label.visible = false
		return
	
	label.visible = true
	
	if stage > 0:
		label.text = "%s +%d" % [stat_name, stage]
		label.add_theme_color_override("font_color", BUFF_COLOR)
		# Add up arrows based on magnitude
		var arrows = ""
		for i in range(min(stage, 3)):
			arrows += "↑"
		label.text = arrows + " " + label.text
	else:
		label.text = "%s %d" % [stat_name, stage]
		label.add_theme_color_override("font_color", DEBUFF_COLOR)
		# Add down arrows based on magnitude
		var arrows = ""
		for i in range(min(abs(stage), 3)):
			arrows += "↓"
		label.text = arrows + " " + label.text


func _hide_stat_indicators() -> void:
	atk_indicator.visible = false
	def_indicator.visible = false
	spd_indicator.visible = false


# =============================================================================
# COOLDOWN DISPLAY
# =============================================================================

## Get formatted cooldown text for a troop's moves
static func get_cooldown_text(troop: Node) -> String:
	if troop == null or not "move_cooldowns" in troop:
		return ""
	
	var text = ""
	for move_id in troop.move_cooldowns:
		var remaining = troop.move_cooldowns[move_id]
		if remaining > 0:
			var move = MoveData.get_move(move_id)
			if move:
				text += "⏳ %s: %d turns\n" % [move.move_name, remaining]
	
	return text.strip_edges()
