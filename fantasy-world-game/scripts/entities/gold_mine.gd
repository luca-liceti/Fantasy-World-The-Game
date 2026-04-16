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

## Unique ID for the deck hand representation
var card_id: String = ""

## Reference to the hex tile this mine occupies
var current_hex: Node = null

## Whether this mine is active (not destroyed)
var is_active: bool = true

## Visual components
var current_model: Node3D = null
var team_color: Color = Color.WHITE
var click_area: Area3D # Input detection for clicking the mine directly

const MINE_MODELS = [
	preload("res://assets/models/mines/gold_mine_lvl_1_still.glb"),
	preload("res://assets/models/mines/gold_mine_lvl_2_still.glb"),
	preload("res://assets/models/mines/gold_mine_lvl_3_still.glb"),
	preload("res://assets/models/mines/gold_mine_lvl_4_still.glb"),
	preload("res://assets/models/mines/gold_mine_lvl_5_still.glb")
]


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_setup_collision()
	_update_visual()
	_create_click_area()


## Initialize the mine
func initialize(player_id: int, hex: Node) -> void:
	owner_player_id = player_id
	current_hex = hex
	level = 1
	is_active = true
	card_id = "mine_" + str(get_instance_id())
	_update_visual()
	
	# Set position
	if hex:
		var surface_height: float = 0.0
		if hex.has_method("get_surface_height"):
			surface_height = hex.get_surface_height()
		elif "tile_height" in hex:
			surface_height = hex.tile_height + 0.05
			
		position = hex.position + Vector3(0, surface_height, 0)
		
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
static func _check_mine_distance(hex: Node, player: Player, _hex_board: Node) -> bool:
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

## Setup camera collision
func _setup_collision() -> void:
	# --- Camera collision (Layer 16) ---
	var cam_body = StaticBody3D.new()
	cam_body.name = "CameraCollision"
	cam_body.collision_layer = 1 << 15  # Layer 16
	cam_body.collision_mask = 0
	add_child(cam_body)
	
	var cam_col = CollisionShape3D.new()
	var cam_box = BoxShape3D.new()
	cam_box.size = Vector3(0.5, 0.4, 0.5)
	cam_col.shape = cam_box
	cam_col.position.y = 0.2
	cam_body.add_child(cam_col)


## Update visual based on level
func _update_visual() -> void:
	if current_model:
		current_model.queue_free()
		remove_child(current_model)
		current_model = null
		
	var model_index = clamp(level - 1, 0, 4)
	if MINE_MODELS[model_index]:
		current_model = MINE_MODELS[model_index].instantiate()
		
		# Apply a vertical offset because the 3D model's origin is centered, causing it to clip below the tile.
		current_model.position.y = 0.4 
		
		# Rotate the mine 180 degrees for player 1 as requested.
		if owner_player_id == 0:
			current_model.rotation_degrees.y = 180
		
		add_child(current_model)
		_fix_model_materials(current_model)
		# Optionally apply team color if needed on model instances here


## Fix common GLB material artifacts: removes unintended transparency, shimmer,
## and ghosting caused by AI-generated models baking incorrect PBR values.
func _fix_model_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_inst := node as MeshInstance3D
		if mesh_inst.mesh:
			var surface_count = mesh_inst.mesh.get_surface_count()
			for i in range(surface_count):
				var mat: Material = mesh_inst.get_surface_override_material(i)
				if mat == null:
					mat = mesh_inst.mesh.surface_get_material(i)
				if mat == null:
					continue
				
				if mat is BaseMaterial3D:
					var fixed: BaseMaterial3D = mat.duplicate() as BaseMaterial3D
					fixed.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
					fixed.cull_mode = BaseMaterial3D.CULL_BACK
					fixed.metallic = 0.0
					fixed.metallic_specular = 0.0
					fixed.emission_enabled = false
					fixed.roughness = 1.0
					mesh_inst.set_surface_override_material(i, fixed)
	
	for child in node.get_children():
		_fix_model_materials(child)


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


# =============================================================================
# INPUT HANDLING (Mine click redirection)
# =============================================================================

## Create an invisible cylinder around the mine to capture mouse clicks,
## forwarding them to the hex tile underneath.
func _create_click_area() -> void:
	if click_area: return
	
	click_area = Area3D.new()
	click_area.name = "MineClickArea"
	click_area.collision_layer = 1 # Layer 1 — same as hex tile mouse picking
	click_area.collision_mask = 0
	
	var col_shape = CollisionShape3D.new()
	var cylinder = CylinderShape3D.new()
	cylinder.radius = 0.8
	cylinder.height = 3.5
	col_shape.shape = cylinder
	col_shape.position.y = 1.75
	
	click_area.add_child(col_shape)
	add_child(click_area)
	
	# Connect signals to forward to current_hex
	click_area.input_event.connect(_on_click_area_input_event)
	click_area.mouse_entered.connect(_on_click_area_mouse_entered)
	click_area.mouse_exited.connect(_on_click_area_mouse_exited)


func _on_click_area_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if current_hex and current_hex.has_method("on_mouse_clicked"):
				current_hex.on_mouse_clicked()


func _on_click_area_mouse_entered() -> void:
	if current_hex and current_hex.has_method("on_mouse_entered"):
		current_hex.on_mouse_entered()


func _on_click_area_mouse_exited() -> void:
	if current_hex and current_hex.has_method("on_mouse_exited"):
		current_hex.on_mouse_exited()
