## Gold Mine
## Represents a gold mine placed on the game board
## Generates gold per turn based on upgrade level
class_name GoldMine
extends Node3D

# =============================================================================
# SIGNALS
# =============================================================================
signal gold_generated(amount: int)
signal mine_upgraded(new_level: int)
signal mine_destroyed(mine: GoldMine)

# =============================================================================
# PROPERTIES
# =============================================================================
## Owner player ID
var owner_player_id: int = -1

## Current upgrade level (1-5)
var level: int = 1

## Reference to the hex tile this mine occupies
var current_hex: Node = null

## Whether this mine is active (not destroyed)
var is_active: bool = true

## Visual components
var mesh_instance: MeshInstance3D
var team_color: Color = Color.WHITE


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_create_placeholder_visual()


## Initialize the mine
func initialize(player_id: int, hex: Node) -> void:
	owner_player_id = player_id
	current_hex = hex
	level = 1
	is_active = true
	
	# Set position
	if hex:
		position = hex.position + Vector3(0, 0.05, 0)
		
		# Register with hex
		if hex.has_method("set_occupant"):
			hex.set_occupant(self)


## Set team color for visual distinction
func set_team_color(color: Color) -> void:
	team_color = color
	_update_visual()


# =============================================================================
# GOLD GENERATION
# =============================================================================

## Get gold generation rate for current level
func get_gold_per_turn() -> int:
	return GameConfig.MINE_GENERATION_RATES.get(level, 0)


## Generate gold (called at start of owner's turn)
## Returns: Amount of gold generated
func generate_gold() -> int:
	if not is_active:
		return 0
	
	var amount = get_gold_per_turn()
	gold_generated.emit(amount)
	return amount


# =============================================================================
# UPGRADES
# =============================================================================

## Get upgrade cost for next level
func get_upgrade_cost() -> int:
	if level >= GameConfig.MAX_TROOP_LEVEL:
		return 0
	
	var next_level = level + 1
	return GameConfig.MINE_UPGRADE_COSTS.get(next_level, 0)


## Check if mine can be upgraded
func can_upgrade() -> bool:
	return level < GameConfig.MAX_TROOP_LEVEL


## Upgrade the mine to next level
func upgrade() -> bool:
	if not can_upgrade():
		return false
	
	level += 1
	mine_upgraded.emit(level)
	_update_visual()
	return true


# =============================================================================
# DESTRUCTION
# =============================================================================

## Destroy the mine (takes 1 hit from any troop)
func destroy() -> void:
	is_active = false
	
	# Clear hex occupant
	if current_hex and current_hex.has_method("clear_occupant"):
		current_hex.clear_occupant()
	
	mine_destroyed.emit(self)
	
	# Remove from scene
	queue_free()


# =============================================================================
# PLACEMENT VALIDATION (Static)
# =============================================================================

## Check if a mine can be placed at the given hex
## Returns: Dictionary with "can_place" and optional "error"
static func can_place_at(hex: Node, player: Player, hex_board: Node) -> Dictionary:
	# Check if hex is valid
	if hex == null:
		return {"can_place": false, "error": "Invalid hex"}
	
	# Check if hex is occupied
	if hex.is_occupied():
		return {"can_place": false, "error": "Hex is occupied"}
	
	# Check biome (cannot place on Peaks)
	if "biome_type" in hex and not Biomes.can_place_mine(hex.biome_type):
		return {"can_place": false, "error": "Cannot place mine on this biome"}
	
	# Check player's mine count
	if player.get_mine_count() >= GameConfig.MAX_MINES_PER_PLAYER:
		return {"can_place": false, "error": "Maximum mines reached"}
	
	# Check player's gold
	if not player.can_afford_gold(GameConfig.MINE_PLACEMENT_COST):
		return {"can_place": false, "error": "Not enough gold"}
	
	# Check minimum distance from other mines (3 hexes)
	if not _check_mine_distance(hex, player, hex_board):
		return {"can_place": false, "error": "Too close to another mine (min 3 hexes)"}
	
	return {"can_place": true}


## Check if hex is at least MIN_DISTANCE_BETWEEN_MINES away from all player mines
static func _check_mine_distance(hex: Node, player: Player, hex_board: Node) -> bool:
	if not "coordinates" in hex:
		return true
	
	var hex_coord = hex.coordinates
	
	for mine in player.gold_mines:
		if mine.current_hex == null:
			continue
		
		if not "coordinates" in mine.current_hex:
			continue
		
		var mine_coord = mine.current_hex.coordinates
		var distance = hex_coord.distance_to(mine_coord)
		
		if distance < GameConfig.MIN_DISTANCE_BETWEEN_MINES:
			return false
	
	return true


# =============================================================================
# VISUAL
# =============================================================================

## Create placeholder visual
func _create_placeholder_visual() -> void:
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	# Create a small box as placeholder
	var box = BoxMesh.new()
	box.size = Vector3(0.4, 0.3, 0.4)
	mesh_instance.mesh = box
	mesh_instance.position.y = 0.15  # Half height above ground
	
	# Material with gold color
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.75, 0.2)  # Gold color
	material.metallic = 0.8
	material.roughness = 0.3
	mesh_instance.material_override = material


## Update visual based on level
func _update_visual() -> void:
	if mesh_instance and mesh_instance.mesh:
		# Scale up slightly based on level
		var scale_factor = 1.0 + (level - 1) * 0.1
		mesh_instance.scale = Vector3(scale_factor, scale_factor, scale_factor)


# =============================================================================
# SERIALIZATION
# =============================================================================

## Convert mine state to dictionary
func to_dict() -> Dictionary:
	var hex_coords = {}
	if current_hex and "coordinates" in current_hex:
		hex_coords = {
			"q": current_hex.coordinates.q,
			"r": current_hex.coordinates.r
		}
	
	return {
		"owner_player_id": owner_player_id,
		"level": level,
		"is_active": is_active,
		"hex_coords": hex_coords
	}


## Load mine state from dictionary
func from_dict(data: Dictionary) -> void:
	owner_player_id = data.get("owner_player_id", -1)
	level = data.get("level", 1)
	is_active = data.get("is_active", true)
	
	# Note: hex position needs to be restored by GameManager
	_update_visual()
