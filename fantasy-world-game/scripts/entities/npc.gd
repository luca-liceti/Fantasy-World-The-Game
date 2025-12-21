## NPC
## Represents a neutral NPC unit on the game board
## Spawns randomly when troops move, drops loot when defeated
class_name NPC
extends Node3D

# =============================================================================
# SIGNALS
# =============================================================================
signal hp_changed(current_hp: int, max_hp: int)
signal npc_died(npc: NPC, killer: Node)
signal npc_attacked(target: Node)
signal loot_dropped(gold: int, xp: int, item: String)

# =============================================================================
# NPC IDENTITY
# =============================================================================
## NPC type ID ("goblin", "orc", "troll")
@export var npc_id: String = ""

## Reference to the NPC's static data
var npc_data: Dictionary = {}

## Display name
var display_name: String = "Unknown NPC"

# =============================================================================
# STATS
# =============================================================================
var max_hp: int = 50
var current_hp: int = 50:
	set(value):
		var old_hp = current_hp
		current_hp = clamp(value, 0, max_hp)
		hp_changed.emit(current_hp, max_hp)
		if current_hp <= 0 and old_hp > 0:
			_on_death()

var atk: int = 30
var def: int = 20

# Attack range (NPCs attack nearest player unit in range)
const ATTACK_RANGE: int = 2

# =============================================================================
# LOOT
# =============================================================================
var gold_reward: int = 5
var xp_reward: int = 10
var rare_drop: String = ""
var drop_chance: float = 0.10

# =============================================================================
# STATE
# =============================================================================
## Reference to the hex tile this NPC occupies
var current_hex: Node = null

## Whether this NPC is alive
var is_alive: bool = true

## The last unit this NPC was killed by (for loot attribution)
var killed_by: Node = null

# =============================================================================
# VISUAL COMPONENTS
# =============================================================================
var mesh_instance: MeshInstance3D


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_create_placeholder_visual()


## Initialize NPC from type ID
func initialize(type_id: String, hex: Node) -> void:
	npc_id = type_id
	current_hex = hex
	
	# Load data from CardData
	npc_data = CardData.get_npc(type_id)
	if npc_data.is_empty():
		push_error("NPC: Invalid NPC type: " + type_id)
		return
	
	# Set stats
	display_name = npc_data.get("name", "Unknown")
	max_hp = npc_data.get("hp", 50)
	current_hp = max_hp
	atk = npc_data.get("atk", 30)
	def = npc_data.get("def", 20)
	
	# Set loot
	gold_reward = npc_data.get("gold_reward", 5)
	xp_reward = npc_data.get("xp_reward", 10)
	rare_drop = npc_data.get("rare_drop", "")
	drop_chance = npc_data.get("drop_chance", 0.10)
	
	# Set position
	if hex:
		position = hex.position + Vector3(0, 0.1, 0)
		
		# Register with hex
		if hex.has_method("set_occupant"):
			hex.set_occupant(self)
	
	is_alive = true
	_update_visual()


# =============================================================================
# COMBAT
# =============================================================================

## Take damage
func take_damage(amount: int) -> int:
	var actual_damage = max(1, amount)
	current_hp -= actual_damage
	return actual_damage


## NPC attack behavior (called during NPC phase)
## Returns: The target attacked, or null if no target
func try_attack(hex_board: Node) -> Node:
	if not is_alive or current_hex == null:
		return null
	
	if not "coordinates" in current_hex:
		return null
	
	var my_coord = current_hex.coordinates
	var nearest_target: Node = null
	var nearest_distance: int = 999
	
	# Find nearest player unit in range
	var hexes_in_range = my_coord.get_hexes_in_range(ATTACK_RANGE)
	
	for coord in hexes_in_range:
		var tile = hex_board.get_tile_at(coord)
		if tile == null or tile.occupant == null:
			continue
		
		var occupant = tile.occupant
		
		# Check if it's a player troop (not another NPC or mine)
		if not "owner_player_id" in occupant:
			continue
		if occupant.owner_player_id < 0:
			continue  # Skip other NPCs
		
		# Check if alive
		if "is_alive" in occupant and not occupant.is_alive:
			continue
		
		# Calculate distance
		var distance = my_coord.distance_to(coord)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_target = occupant
	
	if nearest_target:
		npc_attacked.emit(nearest_target)
	
	return nearest_target


## Calculate NPC attack damage
func calculate_attack_damage(target: Node) -> int:
	var target_def = 0
	if "current_def" in target:
		target_def = target.current_def
	
	# Simple damage formula: ATK - DEF/2, minimum 1
	return max(1, atk - int(target_def / 2.0))


# =============================================================================
# DEATH & LOOT
# =============================================================================

## Handle NPC death
func _on_death() -> void:
	is_alive = false
	
	# Calculate loot
	var dropped_item = ""
	if randf() < drop_chance and not rare_drop.is_empty():
		dropped_item = rare_drop
	
	loot_dropped.emit(gold_reward, xp_reward, dropped_item)
	npc_died.emit(self, killed_by)


## Get loot rewards
func get_loot() -> Dictionary:
	var dropped_item = ""
	if randf() < drop_chance and not rare_drop.is_empty():
		dropped_item = rare_drop
	
	return {
		"gold": gold_reward,
		"xp": xp_reward,
		"item": dropped_item
	}


# =============================================================================
# SPAWNING (Static)
# =============================================================================

## Check if an NPC should spawn (5% chance when troop moves)
static func should_spawn() -> bool:
	return randf() < GameConfig.NPC_SPAWN_CHANCE


## Get random NPC type to spawn
static func get_random_npc_type() -> String:
	var types = CardData.NPCS.keys()
	if types.is_empty():
		return "goblin"
	
	# Weighted random based on difficulty (goblin > orc > troll)
	var roll = randf()
	if roll < 0.5:
		return "goblin"
	elif roll < 0.85:
		return "orc"
	else:
		return "troll"


## Try to spawn an NPC at a hex
## Returns: The spawned NPC or null if spawn failed
static func try_spawn_at(hex: Node, hex_board: Node) -> NPC:
	# Cannot spawn on occupied hex
	if hex.is_occupied():
		return null
	
	# Roll for spawn
	if not should_spawn():
		return null
	
	# Create NPC
	var npc = NPC.new()
	var npc_type = get_random_npc_type()
	npc.initialize(npc_type, hex)
	
	return npc


# =============================================================================
# CLEANUP
# =============================================================================

## Remove NPC from the game
func remove() -> void:
	# Clear hex occupant
	if current_hex and current_hex.has_method("clear_occupant"):
		current_hex.clear_occupant()
	
	queue_free()


# =============================================================================
# VISUAL
# =============================================================================

## Create placeholder visual
func _create_placeholder_visual() -> void:
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	# Create a sphere as placeholder
	var sphere = SphereMesh.new()
	sphere.radius = 0.25
	sphere.height = 0.5
	mesh_instance.mesh = sphere
	mesh_instance.position.y = 0.25
	
	# Red color for enemies
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.2, 0.2)
	mesh_instance.material_override = material


## Update visual based on NPC type
func _update_visual() -> void:
	if mesh_instance == null or mesh_instance.material_override == null:
		return
	
	# Color based on NPC type
	match npc_id:
		"goblin":
			mesh_instance.material_override.albedo_color = Color(0.4, 0.7, 0.3)  # Green
			mesh_instance.scale = Vector3(0.8, 0.8, 0.8)
		"orc":
			mesh_instance.material_override.albedo_color = Color(0.5, 0.4, 0.3)  # Brown
			mesh_instance.scale = Vector3(1.0, 1.0, 1.0)
		"troll":
			mesh_instance.material_override.albedo_color = Color(0.6, 0.5, 0.7)  # Purple
			mesh_instance.scale = Vector3(1.3, 1.3, 1.3)


# =============================================================================
# SERIALIZATION
# =============================================================================

## Convert NPC state to dictionary
func to_dict() -> Dictionary:
	var hex_coords = {}
	if current_hex and "coordinates" in current_hex:
		hex_coords = {
			"q": current_hex.coordinates.q,
			"r": current_hex.coordinates.r
		}
	
	return {
		"npc_id": npc_id,
		"current_hp": current_hp,
		"is_alive": is_alive,
		"hex_coords": hex_coords
	}


## Load NPC state from dictionary
func from_dict(data: Dictionary) -> void:
	npc_id = data.get("npc_id", "goblin")
	is_alive = data.get("is_alive", true)
	
	# Reinitialize from type
	npc_data = CardData.get_npc(npc_id)
	if not npc_data.is_empty():
		display_name = npc_data.get("name", "Unknown")
		max_hp = npc_data.get("hp", 50)
		atk = npc_data.get("atk", 30)
		def = npc_data.get("def", 20)
		gold_reward = npc_data.get("gold_reward", 5)
		xp_reward = npc_data.get("xp_reward", 10)
		rare_drop = npc_data.get("rare_drop", "")
		drop_chance = npc_data.get("drop_chance", 0.10)
	
	current_hp = data.get("current_hp", max_hp)
	_update_visual()
