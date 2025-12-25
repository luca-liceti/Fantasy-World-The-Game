## Move Tooltip UI
## Displays detailed move information on hover
## Part of the D&D × Pokémon hybrid combat system
class_name MoveTooltipUI
extends PanelContainer

# =============================================================================
# UI ELEMENTS
# =============================================================================
var content_container: VBoxContainer
var move_name_label: Label
var move_type_label: Label
var stats_container: HBoxContainer
var power_label: Label
var accuracy_label: Label
var cooldown_label: Label
var damage_type_label: Label
var effect_label: Label
var description_label: Label

# =============================================================================
# COLORS
# =============================================================================
const TYPE_COLORS = {
	MoveData.MoveType.STANDARD: Color(0.7, 0.7, 0.8),
	MoveData.MoveType.POWER: Color(0.9, 0.3, 0.3),
	MoveData.MoveType.PRECISION: Color(0.3, 0.6, 0.9),
	MoveData.MoveType.SPECIAL: Color(0.7, 0.3, 0.9)
}

const DAMAGE_TYPE_COLORS = {
	MoveData.DamageType.PHYSICAL: Color(0.8, 0.8, 0.8),
	MoveData.DamageType.FIRE: Color(1.0, 0.4, 0.2),
	MoveData.DamageType.ICE: Color(0.4, 0.8, 1.0),
	MoveData.DamageType.DARK: Color(0.5, 0.3, 0.6),
	MoveData.DamageType.HOLY: Color(1.0, 0.95, 0.6),
	MoveData.DamageType.NATURE: Color(0.4, 0.8, 0.3)
}


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_create_ui()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _create_ui() -> void:
	# Panel styling
	custom_minimum_size = Vector2(280, 0)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.98)
	style.border_color = Color(0.4, 0.4, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 6
	add_theme_stylebox_override("panel", style)
	
	# Content container
	content_container = VBoxContainer.new()
	content_container.add_theme_constant_override("separation", 6)
	add_child(content_container)
	
	# Move name
	move_name_label = Label.new()
	move_name_label.text = "Move Name"
	move_name_label.add_theme_font_size_override("font_size", 18)
	move_name_label.add_theme_color_override("font_color", Color.WHITE)
	content_container.add_child(move_name_label)
	
	# Move type badge
	move_type_label = Label.new()
	move_type_label.text = "STANDARD"
	move_type_label.add_theme_font_size_override("font_size", 12)
	content_container.add_child(move_type_label)
	
	# Separator
	var sep1 = HSeparator.new()
	sep1.add_theme_color_override("separator", Color(0.3, 0.3, 0.4, 0.5))
	content_container.add_child(sep1)
	
	# Stats row
	stats_container = HBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 15)
	content_container.add_child(stats_container)
	
	# Power
	var power_vbox = VBoxContainer.new()
	stats_container.add_child(power_vbox)
	
	var power_title = Label.new()
	power_title.text = "Power"
	power_title.add_theme_font_size_override("font_size", 10)
	power_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	power_vbox.add_child(power_title)
	
	power_label = Label.new()
	power_label.text = "100%"
	power_label.add_theme_font_size_override("font_size", 16)
	power_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	power_vbox.add_child(power_label)
	
	# Accuracy
	var acc_vbox = VBoxContainer.new()
	stats_container.add_child(acc_vbox)
	
	var acc_title = Label.new()
	acc_title.text = "Accuracy"
	acc_title.add_theme_font_size_override("font_size", 10)
	acc_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	acc_vbox.add_child(acc_title)
	
	accuracy_label = Label.new()
	accuracy_label.text = "+0"
	accuracy_label.add_theme_font_size_override("font_size", 16)
	accuracy_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	acc_vbox.add_child(accuracy_label)
	
	# Cooldown
	var cd_vbox = VBoxContainer.new()
	stats_container.add_child(cd_vbox)
	
	var cd_title = Label.new()
	cd_title.text = "Cooldown"
	cd_title.add_theme_font_size_override("font_size", 10)
	cd_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	cd_vbox.add_child(cd_title)
	
	cooldown_label = Label.new()
	cooldown_label.text = "0"
	cooldown_label.add_theme_font_size_override("font_size", 16)
	cooldown_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	cd_vbox.add_child(cooldown_label)
	
	# Damage type
	damage_type_label = Label.new()
	damage_type_label.text = "⚔️ Physical Damage"
	damage_type_label.add_theme_font_size_override("font_size", 13)
	content_container.add_child(damage_type_label)
	
	# Effect (if any)
	effect_label = Label.new()
	effect_label.text = ""
	effect_label.add_theme_font_size_override("font_size", 12)
	effect_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.9))
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	content_container.add_child(effect_label)
	
	# Separator
	var sep2 = HSeparator.new()
	sep2.add_theme_color_override("separator", Color(0.3, 0.3, 0.4, 0.5))
	content_container.add_child(sep2)
	
	# Description
	description_label = Label.new()
	description_label.text = "Move description"
	description_label.add_theme_font_size_override("font_size", 11)
	description_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	description_label.custom_minimum_size.x = 260
	content_container.add_child(description_label)


# =============================================================================
# PUBLIC METHODS
# =============================================================================

## Show tooltip for a move at the specified position
func show_for_move(move: MoveData.Move, pos: Vector2) -> void:
	if move == null:
		hide()
		return
	
	# Update content
	move_name_label.text = move.move_name
	
	# Move type
	var type_names = ["Standard", "Power", "Precision", "Special"]
	var type_color = TYPE_COLORS.get(move.move_type, Color.WHITE)
	move_type_label.text = type_names[move.move_type]
	move_type_label.add_theme_color_override("font_color", type_color)
	
	# Stats
	power_label.text = "%d%%" % int(move.power_percent * 100)
	
	var acc_sign = "+" if move.accuracy_modifier >= 0 else ""
	accuracy_label.text = acc_sign + str(move.accuracy_modifier)
	
	if move.cooldown_turns > 0:
		cooldown_label.text = "%d turns" % move.cooldown_turns
	else:
		cooldown_label.text = "None"
	
	# Damage type
	var dmg_names = ["Physical", "Fire", "Ice", "Dark", "Holy", "Nature"]
	var dmg_icons = ["⚔️", "🔥", "❄️", "🌑", "✨", "🌿"]
	var dmg_color = DAMAGE_TYPE_COLORS.get(move.damage_type, Color.WHITE)
	damage_type_label.text = "%s %s Damage" % [dmg_icons[move.damage_type], dmg_names[move.damage_type]]
	damage_type_label.add_theme_color_override("font_color", dmg_color)
	
	# Effect
	if move.effect_id != "" and move.effect_chance > 0:
		var effect_data = StatusEffects.get_effect_data(move.effect_id)
		var effect_name = effect_data.get("effect_name", move.effect_id)
		var chance = int(move.effect_chance * 100)
		effect_label.text = "💫 %d%% chance to apply %s" % [chance, effect_name]
		effect_label.visible = true
	else:
		effect_label.visible = false
	
	# AoE indicator
	if move.is_aoe:
		effect_label.text += "\n🎯 Area of Effect"
		effect_label.visible = true
	
	# Self-targeting indicator
	if move.targets_self:
		effect_label.text += "\n👤 Targets Self"
		effect_label.visible = true
	
	# Description
	description_label.text = move.description
	
	# Position tooltip
	position = pos + Vector2(15, 15)
	
	# Keep on screen
	var viewport_size = get_viewport().get_visible_rect().size
	if position.x + size.x > viewport_size.x:
		position.x = pos.x - size.x - 15
	if position.y + size.y > viewport_size.y:
		position.y = viewport_size.y - size.y - 10
	
	visible = true


## Hide the tooltip
func hide_tooltip() -> void:
	visible = false
