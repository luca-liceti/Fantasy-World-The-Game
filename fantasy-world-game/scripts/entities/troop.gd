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
# ENHANCED COMBAT SYSTEM - MOVES
# =============================================================================
## Available moves for this troop (loaded from MoveData)
var available_moves: Array = []

## Move cooldowns: {move_id: turns remaining}
var move_cooldowns: Dictionary = {}

# =============================================================================
# ENHANCED COMBAT SYSTEM - STATUS EFFECTS
# =============================================================================
## Active status effects: Array of StatusEffect objects
var active_status_effects: Array = []

## Endure stance uses remaining (resets per combat)
var endure_uses_remaining: int = 1

# =============================================================================
# ENHANCED COMBAT SYSTEM - STAT STAGES
# =============================================================================
## Stat stages: -6 to +6 (like Pokémon)
var stat_stages: Dictionary = {
	"atk": 0,
	"def": 0,
	"speed": 0
}

# =============================================================================
# ENHANCED COMBAT SYSTEM - TYPE DATA
# =============================================================================
## Primary damage type for this troop's attacks
var damage_type: String = "PHYSICAL"

## Damage types this troop resists (takes 0.5x damage)
var resistances: Array = []

## Damage types this troop is weak to (takes 1.5x damage)
var weaknesses: Array = []

## Damage types this troop is immune to (takes 0x damage)
var immunities: Array = []

# =============================================================================
# VISUAL COMPONENTS
# =============================================================================
var mesh_instance: MeshInstance3D
var health_bar: Node # Reference to health bar UI (set externally)

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
	
	# Load enhanced combat data
	damage_type = troop_data.get("damage_type", "PHYSICAL")
	resistances = troop_data.get("resistances", []).duplicate()
	weaknesses = troop_data.get("weaknesses", []).duplicate()
	immunities = troop_data.get("immunities", []).duplicate()
	
	# Initialize moves from MoveData
	_initialize_moves()
	
	# Initialize current stats
	_recalculate_stats()
	current_hp = max_hp
	
	# Reset state
	level = 1
	is_alive = true
	has_moved_this_turn = false
	has_attacked_this_turn = false
	active_buffs.clear()
	active_status_effects.clear()
	move_cooldowns.clear()
	stat_stages = {"atk": 0, "def": 0, "speed": 0}
	endure_uses_remaining = 1


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
		return Biomes.get_modifier_value(modifier) # -15% incoming damage
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
	var actual_damage = max(1, amount) # Minimum 1 damage
	current_hp -= actual_damage
	return actual_damage


## Heal HP
func heal(amount: int) -> int:
	var old_hp = current_hp
	current_hp = min(current_hp + amount, max_hp)
	return current_hp - old_hp # Return actual amount healed


## Check if this troop can attack a target
func can_attack(target: Node) -> bool:
	if not is_alive:
		return false
	
	if target == null or not ("is_alive" in target) or not target.is_alive:
		return false
	
	# Check range using hex distance calculation
	if current_hex == null or not ("coordinates" in current_hex):
		return false
	
	if not ("current_hex" in target) or target.current_hex == null:
		return false
	
	if not ("coordinates" in target.current_hex):
		return false
	
	var distance = current_hex.coordinates.distance_to(target.current_hex.coordinates)
	if distance > current_range:
		return false
	
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
	
	# Tick cooldowns at turn start
	tick_cooldowns()
	
	# Tick status effects at turn start
	tick_status_effects()


## Check if troop can still act this turn (accounts for status effects)
func can_act() -> bool:
	if not is_alive:
		return false
	
	# Check for status effects that prevent action
	for effect in active_status_effects:
		if effect.prevents_action:
			return false
	
	return not has_moved_this_turn or not has_attacked_this_turn


## Check if troop can move this turn (accounts for status effects)
func can_move() -> bool:
	if not is_alive:
		return false
	
	# Check for status effects that prevent movement
	for effect in active_status_effects:
		if effect.prevents_movement:
			return false
	
	return not has_moved_this_turn


# =============================================================================
# ENHANCED COMBAT - MOVE SYSTEM
# =============================================================================

## Initialize moves from MoveData
func _initialize_moves() -> void:
	available_moves = MoveData.get_moves_for_troop(troop_id)
	move_cooldowns.clear()


## Check if a move is available (not on cooldown)
func is_move_available(move_id: String) -> bool:
	var remaining = move_cooldowns.get(move_id, 0)
	return remaining <= 0


## Use a move (starts its cooldown)
func use_move(move_id: String) -> void:
	var move = MoveData.get_move(move_id)
	if move and move.cooldown_turns > 0:
		move_cooldowns[move_id] = move.cooldown_turns


## Tick all move cooldowns (called at turn start)
func tick_cooldowns() -> void:
	var to_remove: Array = []
	for move_id in move_cooldowns:
		move_cooldowns[move_id] -= 1
		if move_cooldowns[move_id] <= 0:
			to_remove.append(move_id)
	
	for move_id in to_remove:
		move_cooldowns.erase(move_id)


## Get remaining cooldown for a move
func get_move_cooldown(move_id: String) -> int:
	return move_cooldowns.get(move_id, 0)


## Get all available moves (not on cooldown)
func get_available_moves() -> Array:
	var result: Array = []
	for move in available_moves:
		if is_move_available(move.move_id):
			result.append(move)
	return result


# =============================================================================
# ENHANCED COMBAT - STATUS EFFECTS
# =============================================================================

## Apply a status effect
func apply_status_effect(effect: StatusEffects.StatusEffect) -> bool:
	if effect == null:
		return false
	
	# Check immunity
	if StatusEffects.is_immune(troop_id, effect.effect_id):
		return false
	
	# Check if already has this effect - refresh duration if so
	for existing in active_status_effects:
		if existing.effect_id == effect.effect_id:
			existing.remaining_turns = effect.duration_turns
			return true
	
	# Add new effect
	active_status_effects.append(effect)
	_recalculate_stats()
	return true


## Remove a status effect by ID
func remove_status_effect(effect_id: String) -> void:
	for i in range(active_status_effects.size() - 1, -1, -1):
		if active_status_effects[i].effect_id == effect_id:
			active_status_effects.remove_at(i)
	_recalculate_stats()


## Remove all negative status effects
func remove_all_debuffs() -> void:
	for i in range(active_status_effects.size() - 1, -1, -1):
		if StatusEffects.is_debuff(active_status_effects[i].effect_id):
			active_status_effects.remove_at(i)
	_recalculate_stats()


## Tick all status effects (called at turn start)
## Returns total damage taken from DoT effects
func tick_status_effects() -> int:
	var total_damage: int = 0
	var to_remove: Array = []
	
	for effect in active_status_effects:
		# Apply damage over time
		if effect.damage_per_turn > 0:
			total_damage += effect.damage_per_turn
		
		# Tick duration
		if effect.tick():
			to_remove.append(effect)
	
	# Remove expired effects
	for effect in to_remove:
		active_status_effects.erase(effect)
	
	# Apply DoT damage
	if total_damage > 0:
		take_damage(total_damage)
	
	_recalculate_stats()
	return total_damage


## Check if troop has a specific status effect
func has_status_effect(effect_id: String) -> bool:
	for effect in active_status_effects:
		if effect.effect_id == effect_id:
			return true
	return false


## Check if troop is in stealth
func is_stealthed() -> bool:
	return has_status_effect("stealth")


# =============================================================================
# ENHANCED COMBAT - STAT STAGES
# =============================================================================

## Modify a stat stage (clamped to -6 to +6)
func modify_stat_stage(stat: String, amount: int) -> void:
	if stat in stat_stages:
		stat_stages[stat] = clamp(stat_stages[stat] + amount, -6, 6)
		_recalculate_stats()


## Reset all stat stages to 0
func reset_stat_stages() -> void:
	stat_stages = {"atk": 0, "def": 0, "speed": 0}
	_recalculate_stats()


## Get the multiplier for a stat stage (-6 to +6)
## Uses Pokémon-style formula: stages >= 0: (2 + stage) / 2, stages < 0: 2 / (2 - stage)
func get_stat_stage_multiplier(stat: String) -> float:
	var stage = stat_stages.get(stat, 0)
	if stage >= 0:
		return (2.0 + stage) / 2.0
	else:
		return 2.0 / (2.0 - stage)


## Get the modified stat value after applying stat stages
func get_modified_stat(stat: String) -> float:
	var base_value: float = 0.0
	match stat:
		"atk": base_value = current_atk
		"def": base_value = current_def
		"speed": base_value = current_speed
	
	return base_value * get_stat_stage_multiplier(stat)


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
## Uses vertex averaging for Y position (no raycasting needed)
func move_to_hex(new_hex: Node) -> void:
	var old_hex = current_hex
	
	# Clear old hex
	if current_hex and current_hex.has_method("clear_occupant"):
		current_hex.clear_occupant()
	
	# Set new hex
	current_hex = new_hex
	if new_hex and new_hex.has_method("set_occupant"):
		new_hex.set_occupant(self)
	
	# Update position using vertex averaging method
	# This calculates Y from the average of the 6 vertex heights + buffer
	# Much faster than raycasting, calculated once per spawn/move
	if new_hex:
		var surface_height: float = 0.0
		
		# Use vertex-averaged surface height if available
		if new_hex.has_method("get_surface_height"):
			surface_height = new_hex.get_surface_height()
		elif "tile_height" in new_hex:
			# Fallback to tile_height + buffer
			surface_height = new_hex.tile_height + 0.1
		
		position = new_hex.position + Vector3(0, surface_height, 0)
	
	has_moved_this_turn = true
	troop_moved.emit(old_hex, new_hex)


# =============================================================================
# VISUAL
# =============================================================================

## Create placeholder visual (will be replaced with actual model)
## Uses 1:1 scale: 1 unit = 1 meter, human troops ~1.8-2.0m tall
func _create_placeholder_visual() -> void:
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	# Create different shapes based on role for easy identification
	# Scale follows 1:1 world scale (1 unit = 1 meter)
	var mesh: Mesh
	match role:
		CardData.Role.GROUND_TANK:
			# Box for tanks - sturdy knight ~2m tall, broad shoulders
			var box = BoxMesh.new()
			box.size = Vector3(0.8, 2.0, 0.6) # Wide, tall, not too deep
			mesh = box
			mesh_instance.position.y = 1.0 # Center at half height
		CardData.Role.AIR_HYBRID:
			# Cone (pointing up) for air units - winged creature ~3m wingspan
			var prism = PrismMesh.new()
			prism.size = Vector3(1.2, 1.8, 1.2) # Wider, slightly shorter
			mesh = prism
			mesh_instance.position.y = 0.9
		CardData.Role.RANGED_MAGIC:
			# Cylinder for ranged - like a mage/archer ~1.9m tall
			var cylinder = CylinderMesh.new()
			cylinder.top_radius = 0.35
			cylinder.bottom_radius = 0.4
			cylinder.height = 1.9
			mesh = cylinder
			mesh_instance.position.y = 0.95
		CardData.Role.FLEX_SUPPORT:
			# Sphere for flex/support - cleric/support ~1.6m 
			var sphere = SphereMesh.new()
			sphere.radius = 0.5
			sphere.height = 1.6
			mesh = sphere
			mesh_instance.position.y = 0.8
		_:
			# Default capsule - generic humanoid ~1.8m
			var capsule = CapsuleMesh.new()
			capsule.radius = 0.4
			capsule.height = 1.8
			mesh = capsule
			mesh_instance.position.y = 0.9
	
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
	
	# Position above the troop (troops are now ~2m tall)
	name_label.position.y = 2.5
	
	# Billboard mode - always face camera
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	# Styling
	name_label.font_size = 64
	name_label.outline_size = 10
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
