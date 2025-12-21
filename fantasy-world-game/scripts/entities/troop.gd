## Troop
## Represents a single troop unit on the game board
## Contains stats, abilities, and state management
class_name Troop
extends Node3D

# =============================================================================
# SIGNALS
# =============================================================================
signal hp_changed(current_hp: int, max_hp: int)
signal troop_died(troop: Troop)
signal troop_attacked(target: Node)
signal troop_moved(from_hex: Node, to_hex: Node)
signal troop_upgraded(new_level: int)
signal buff_applied(buff_type: String, duration: int)
signal buff_removed(buff_type: String)

# =============================================================================
# TROOP IDENTITY
# =============================================================================
## The card/troop type ID (e.g., "medieval_knight")
@export var troop_id: String = ""

## Reference to the troop's static data
var troop_data: Dictionary = {}

## Owner player ID
var owner_player_id: int = -1

## Display name
var display_name: String = "Unknown Troop"

# =============================================================================
# BASE STATS (from CardData)
# =============================================================================
var base_hp: int = 100
var base_atk: int = 50
var base_def: int = 50
var base_range: int = 1
var base_speed: int = 2
var mana_cost: int = 5
var range_type: CardData.RangeType = CardData.RangeType.MELEE
var role: CardData.Role = CardData.Role.GROUND_TANK
var ability: CardData.Ability = CardData.Ability.NONE
var ability_description: String = ""

# =============================================================================
# CURRENT STATS (modified by level, buffs, biome)
# =============================================================================
var current_hp: int = 100:
	set(value):
		var old_hp = current_hp
		current_hp = clamp(value, 0, max_hp)
		hp_changed.emit(current_hp, max_hp)
		if current_hp <= 0 and old_hp > 0:
			_on_death()

var max_hp: int = 100
var current_atk: int = 50
var current_def: int = 50
var current_range: int = 1
var current_speed: int = 2

# =============================================================================
# LEVEL & UPGRADES
# =============================================================================
var level: int = 1

# =============================================================================
# POSITION & STATE
# =============================================================================
## Reference to the hex tile this troop occupies
var current_hex: Node = null

## Whether this troop has moved this turn
var has_moved_this_turn: bool = false

## Whether this troop has attacked this turn
var has_attacked_this_turn: bool = false

## Whether this troop is alive
var is_alive: bool = true

# =============================================================================
# BUFFS & DEBUFFS
# =============================================================================
## Active buffs: {buff_type: {value: X, duration: Y}}
var active_buffs: Dictionary = {}

# =============================================================================
# VISUAL COMPONENTS
# =============================================================================
var mesh_instance: MeshInstance3D
var health_bar: Node  # Reference to health bar UI (set externally)

# Team color tint
var team_color: Color = Color.WHITE


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_create_placeholder_visual()


## Initialize troop from card data
func initialize(card_id: String, player_id: int) -> void:
	troop_id = card_id
	owner_player_id = player_id
	
	# Load data from CardData
	troop_data = CardData.get_troop(card_id)
	if troop_data.is_empty():
		push_error("Troop: Invalid card ID: " + card_id)
		return
	
	# Set identity
	display_name = troop_data.get("name", "Unknown")
	
	# Set base stats
	base_hp = troop_data.get("hp", 100)
	base_atk = troop_data.get("atk", 50)
	base_def = troop_data.get("def", 50)
	base_range = troop_data.get("range", 1)
	base_speed = troop_data.get("speed", 2)
	mana_cost = troop_data.get("mana", 5)
	range_type = troop_data.get("range_type", CardData.RangeType.MELEE)
	role = troop_data.get("role", CardData.Role.GROUND_TANK)
	ability = troop_data.get("ability", CardData.Ability.NONE)
	ability_description = troop_data.get("ability_description", "")
	
	# Initialize current stats
	_recalculate_stats()
	current_hp = max_hp
	
	# Reset state
	level = 1
	is_alive = true
	has_moved_this_turn = false
	has_attacked_this_turn = false
	active_buffs.clear()


## Set team color for visual distinction
func set_team_color(color: Color) -> void:
	team_color = color
	_update_visual()


# =============================================================================
# STAT CALCULATIONS
# =============================================================================

## Recalculate all current stats based on level and buffs
func _recalculate_stats() -> void:
	# Level bonuses
	var level_bonus = level - 1
	var hp_multiplier = 1.0 + (level_bonus * GameConfig.HP_INCREASE_PERCENT)
	var atk_bonus = level_bonus * GameConfig.ATK_INCREASE_FLAT
	var def_bonus = level_bonus * GameConfig.DEF_INCREASE_FLAT
	
	# Calculate base stats with level
	max_hp = int(base_hp * hp_multiplier)
	current_atk = base_atk + atk_bonus
	current_def = base_def + def_bonus
	current_range = base_range
	current_speed = base_speed
	
	# Apply buffs
	_apply_buff_modifiers()


## Apply active buff modifiers to stats
func _apply_buff_modifiers() -> void:
	for buff_type in active_buffs:
		var buff = active_buffs[buff_type]
		match buff_type:
			"speed_buff":
				current_speed += buff.get("value", 0)
			"atk_buff":
				current_atk += buff.get("value", 0)


## Get effective attack value (including biome modifier)
func get_effective_atk(biome_type: Biomes.Type) -> int:
	var modifier = Biomes.get_troop_modifier(troop_id, biome_type)
	var modifier_value = Biomes.get_modifier_value(modifier)
	
	# Only A, S, W affect attack damage
	if modifier in ["A", "S", "W"]:
		return int(current_atk * (1.0 + modifier_value))
	
	return current_atk


## Get effective defense value (including biome modifier)
func get_effective_def(biome_type: Biomes.Type) -> int:
	var modifier = Biomes.get_troop_modifier(troop_id, biome_type)
	
	# D modifier affects incoming damage (handled in combat, not here)
	return current_def


## Get biome defense modifier (for damage reduction)
func get_biome_defense_modifier(biome_type: Biomes.Type) -> float:
	var modifier = Biomes.get_troop_modifier(troop_id, biome_type)
	if modifier == "D":
		return Biomes.get_modifier_value(modifier)  # -15% incoming damage
	return 0.0


# =============================================================================
# LEVEL & UPGRADES
# =============================================================================

## Upgrade the troop to the next level
func upgrade() -> bool:
	if level >= GameConfig.MAX_TROOP_LEVEL:
		return false
	
	level += 1
	_recalculate_stats()
	
	# Heal to new max HP (optional: could heal proportionally instead)
	current_hp = max_hp
	
	troop_upgraded.emit(level)
	return true


## Get upgrade cost for next level
func get_upgrade_cost() -> Dictionary:
	if level >= GameConfig.MAX_TROOP_LEVEL:
		return {"gold": 0, "xp": 0, "can_upgrade": false}
	
	var next_level = level + 1
	var cost = GameConfig.TROOP_UPGRADE_COSTS.get(next_level, {})
	return {
		"gold": cost.get("gold", 0),
		"xp": cost.get("xp", 0),
		"can_upgrade": true
	}


# =============================================================================
# COMBAT
# =============================================================================

## Take damage (after all modifiers applied externally)
func take_damage(amount: int) -> int:
	var actual_damage = max(1, amount)  # Minimum 1 damage
	current_hp -= actual_damage
	return actual_damage


## Heal HP
func heal(amount: int) -> int:
	var old_hp = current_hp
	current_hp = min(current_hp + amount, max_hp)
	return current_hp - old_hp  # Return actual amount healed


## Check if this troop can attack a target
func can_attack(target: Node) -> bool:
	if not is_alive:
		return false
	
	if target == null or not ("is_alive" in target) or not target.is_alive:
		return false
	
	# Check range (would need hex distance calculation)
	# This is a placeholder - actual check needs HexCoordinates
	
	# Check air vs ground rules
	if _is_target_air(target) and not _can_hit_air():
		return false
	
	return true


## Check if target is an air unit
func _is_target_air(target: Node) -> bool:
	if "range_type" in target:
		return target.range_type == CardData.RangeType.AIR
	return false


## Check if this troop can hit air units
func _can_hit_air() -> bool:
	# Air units can always hit other air units
	if range_type == CardData.RangeType.AIR:
		return true
	
	# Ranged and Magic can hit air
	if range_type in [CardData.RangeType.RANGED, CardData.RangeType.MAGIC]:
		return true
	
	# Units with Anti-Air ability
	if ability in [CardData.Ability.ANTI_AIR, CardData.Ability.ANTI_AIR_2X]:
		return true
	
	# Hybrid can hit air
	if range_type == CardData.RangeType.HYBRID:
		return true
	
	return false


## Check if this troop is an air unit
func is_air_unit() -> bool:
	return range_type == CardData.RangeType.AIR


## Get Anti-Air damage multiplier
func get_anti_air_multiplier() -> float:
	if ability == CardData.Ability.ANTI_AIR_2X:
		return 2.0
	return 1.0


## Check if this troop has magic damage (ignores 25% DEF)
func has_magic_damage() -> bool:
	return ability == CardData.Ability.MAGIC


## Check if this troop can multi-strike
func can_multi_strike() -> bool:
	return ability == CardData.Ability.MULTI_STRIKE


## Check if this troop has death burst
func has_death_burst() -> bool:
	return ability == CardData.Ability.DEATH_BURST


## Check if this troop can heal
func can_heal() -> bool:
	return ability == CardData.Ability.HEAL


# =============================================================================
# BUFFS & DEBUFFS
# =============================================================================

## Apply a buff
func apply_buff(buff_type: String, value: int, duration: int) -> void:
	active_buffs[buff_type] = {
		"value": value,
		"duration": duration
	}
	_recalculate_stats()
	buff_applied.emit(buff_type, duration)


## Remove a buff
func remove_buff(buff_type: String) -> void:
	if buff_type in active_buffs:
		active_buffs.erase(buff_type)
		_recalculate_stats()
		buff_removed.emit(buff_type)


## Tick all buff durations (call at end of turn)
func tick_buffs() -> void:
	var to_remove: Array[String] = []
	
	for buff_type in active_buffs:
		active_buffs[buff_type]["duration"] -= 1
		if active_buffs[buff_type]["duration"] <= 0:
			to_remove.append(buff_type)
	
	for buff_type in to_remove:
		remove_buff(buff_type)


# =============================================================================
# TURN MANAGEMENT
# =============================================================================

## Reset turn-based flags (called at start of owner's turn)
func start_turn() -> void:
	has_moved_this_turn = false
	has_attacked_this_turn = false


## Check if troop can still act this turn
func can_act() -> bool:
	return is_alive and (not has_moved_this_turn or not has_attacked_this_turn)


# =============================================================================
# DEATH & CLEANUP
# =============================================================================

## Handle troop death
func _on_death() -> void:
	is_alive = false
	
	# Handle Death Burst ability
	if has_death_burst():
		# Death burst damage will be handled by CombatManager
		pass
	
	troop_died.emit(self)


# =============================================================================
# MOVEMENT
# =============================================================================

## Move to a new hex
func move_to_hex(new_hex: Node) -> void:
	var old_hex = current_hex
	
	# Clear old hex
	if current_hex and current_hex.has_method("clear_occupant"):
		current_hex.clear_occupant()
	
	# Set new hex
	current_hex = new_hex
	if new_hex and new_hex.has_method("set_occupant"):
		new_hex.set_occupant(self)
	
	# Update position
	if new_hex:
		position = new_hex.position + Vector3(0, 0.1, 0)  # Slightly above hex
	
	has_moved_this_turn = true
	troop_moved.emit(old_hex, new_hex)


# =============================================================================
# VISUAL
# =============================================================================

## Create placeholder visual (will be replaced with actual model)
func _create_placeholder_visual() -> void:
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	# Create different shapes based on role for easy identification
	var mesh: Mesh
	match role:
		CardData.Role.GROUND_TANK:
			# Box for tanks - sturdy looking
			var box = BoxMesh.new()
			box.size = Vector3(0.6, 0.8, 0.6)
			mesh = box
			mesh_instance.position.y = 0.4
		CardData.Role.AIR_HYBRID:
			# Cone (pointing up) for air units - represents flight
			var prism = PrismMesh.new()
			prism.size = Vector3(0.5, 0.9, 0.5)
			mesh = prism
			mesh_instance.position.y = 0.45
		CardData.Role.RANGED_MAGIC:
			# Cylinder for ranged - like a tower/staff
			var cylinder = CylinderMesh.new()
			cylinder.top_radius = 0.25
			cylinder.bottom_radius = 0.25
			cylinder.height = 1.0
			mesh = cylinder
			mesh_instance.position.y = 0.5
		CardData.Role.FLEX_SUPPORT:
			# Sphere for flex/support - versatile
			var sphere = SphereMesh.new()
			sphere.radius = 0.35
			sphere.height = 0.7
			mesh = sphere
			mesh_instance.position.y = 0.35
		_:
			# Default capsule
			var capsule = CapsuleMesh.new()
			capsule.radius = 0.3
			capsule.height = 1.0
			mesh = capsule
			mesh_instance.position.y = 0.5
	
	mesh_instance.mesh = mesh
	
	# Create material with team color
	var material = StandardMaterial3D.new()
	material.albedo_color = team_color
	mesh_instance.material_override = material
	
	# Add a 3D label above the troop showing abbreviated name
	_create_name_label()


## Create 3D label above the troop
var name_label: Label3D
func _create_name_label() -> void:
	name_label = Label3D.new()
	add_child(name_label)
	
	# Create abbreviated name (first word or acronym)
	var abbrev = _get_abbreviated_name()
	name_label.text = abbrev
	
	# Position above the troop
	name_label.position.y = 1.3
	
	# Billboard mode - always face camera
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	# Styling
	name_label.font_size = 48
	name_label.outline_size = 8
	name_label.modulate = team_color
	name_label.outline_modulate = Color.BLACK


## Get abbreviated name for display
func _get_abbreviated_name() -> String:
	if display_name.is_empty():
		return troop_id.to_upper().substr(0, 6)
	
	# Get key identifier from name
	var words = display_name.split(" ")
	if words.size() >= 2:
		# Use last word for most troops (Knight, Dragon, Wizard, etc)
		return words[-1].to_upper().substr(0, 8)
	return display_name.to_upper().substr(0, 8)


## Update visual based on current state
func _update_visual() -> void:
	if mesh_instance and mesh_instance.material_override:
		mesh_instance.material_override.albedo_color = team_color
	if name_label:
		name_label.modulate = team_color


# =============================================================================
# SERIALIZATION
# =============================================================================

## Convert troop state to dictionary
func to_dict() -> Dictionary:
	return {
		"troop_id": troop_id,
		"owner_player_id": owner_player_id,
		"level": level,
		"current_hp": current_hp,
		"max_hp": max_hp,
		"is_alive": is_alive,
		"has_moved_this_turn": has_moved_this_turn,
		"has_attacked_this_turn": has_attacked_this_turn,
		"active_buffs": active_buffs.duplicate(),
		"hex_coords": _get_hex_coords_dict()
	}


## Get hex coordinates as dictionary (for serialization)
func _get_hex_coords_dict() -> Dictionary:
	if current_hex and "coordinates" in current_hex:
		var coords = current_hex.coordinates
		if coords:
			return {"q": coords.q, "r": coords.r}
	return {}


## Load troop state from dictionary
func from_dict(data: Dictionary) -> void:
	troop_id = data.get("troop_id", "")
	owner_player_id = data.get("owner_player_id", -1)
	level = data.get("level", 1)
	is_alive = data.get("is_alive", true)
	has_moved_this_turn = data.get("has_moved_this_turn", false)
	has_attacked_this_turn = data.get("has_attacked_this_turn", false)
	
	# Reinitialize from card data
	if not troop_id.is_empty():
		initialize(troop_id, owner_player_id)
		
		# Override with saved values
		level = data.get("level", 1)
		_recalculate_stats()
		current_hp = data.get("current_hp", max_hp)
	
	# Restore buffs
	active_buffs = data.get("active_buffs", {}).duplicate()
	_recalculate_stats()
	
	# Note: hex position needs to be restored by GameManager
