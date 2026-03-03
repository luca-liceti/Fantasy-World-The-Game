## Environment Builder
## Loads and positions a pre-made 3D environment model around the game board.
## Each environment is a single .glb file that already contains all geometry,
## furniture, and decoration. No procedural building — just load, scale, and place.
##
## Auto-alignment: The script searches for a mesh named "Main_Table" inside the
## .glb model and automatically positions the environment so that the table
## center sits at the board's world position (board_center). position_offset
## can be used for manual fine-tuning on top of the auto-alignment.
##
## To add a new environment:
##   1. Drop the .glb file into res://assets/models/rooms/
##   2. Ensure the table mesh is named "Main_Table" with its origin at center
##   3. Add an entry to EnvironmentType, ENVIRONMENT_PATHS, and ENVIRONMENT_NAMES
class_name EnvironmentBuilder
extends Node3D


# =============================================================================
# ENVIRONMENT REGISTRY
# =============================================================================

enum EnvironmentType {
	TAVERN,
	CASTLE_DINING_HALL,
	FOREST_CLEARING,
	MOUNTAIN,
	FORTRESS,
	UNDERGROUND_CAVE,
	FIELD_TENT,
}

## .glb file path for each environment
const ENVIRONMENT_PATHS: Dictionary = {
	EnvironmentType.TAVERN: "res://assets/models/rooms/grand_tavern.glb",
	EnvironmentType.CASTLE_DINING_HALL: "res://assets/models/rooms/castle_dining_hall.glb",
	EnvironmentType.FOREST_CLEARING: "res://assets/models/rooms/forest_clearing.glb",
	EnvironmentType.MOUNTAIN: "res://assets/models/rooms/mountain.glb",
	EnvironmentType.FORTRESS: "res://assets/models/rooms/fortress.glb",
	EnvironmentType.UNDERGROUND_CAVE: "res://assets/models/rooms/underground_cave.glb",
	EnvironmentType.FIELD_TENT: "res://assets/models/rooms/field_tent.glb",
}

## Human-readable names (used in UI / logs)
const ENVIRONMENT_NAMES: Dictionary = {
	EnvironmentType.TAVERN: "Tavern",
	EnvironmentType.CASTLE_DINING_HALL: "Castle Dining Hall",
	EnvironmentType.FOREST_CLEARING: "Forest Clearing",
	EnvironmentType.MOUNTAIN: "Mountain",
	EnvironmentType.FORTRESS: "Fortress",
	EnvironmentType.UNDERGROUND_CAVE: "Underground Cave",
	EnvironmentType.FIELD_TENT: "Field Tent",
}

## Name of the table mesh to search for inside the .glb model.
## The mesh origin should be set to the center of the table in Blender.
const TABLE_MESH_NAME: String = "Main_Table"


# =============================================================================
# CONFIGURATION — Adjust in the Inspector to align the model with the board
# =============================================================================

## Which environment to load when the scene starts
@export var selected_environment: EnvironmentType = EnvironmentType.TAVERN

## World position where the table center should end up (matches the HexBoard position)
## Note: main.gd overrides the board Y to 0.0 at runtime for BOARD_LIFT math
@export var board_center: Vector3 = Vector3(0.0, 0.0, 0.0)

## Manual fine-tuning offset applied AFTER auto-alignment to the table mesh
@export var position_offset: Vector3 = Vector3(0.0, -8, 0.0)

## Y-axis rotation in degrees — orient the model relative to the cameras
@export var rotation_degrees_y: float = 75.0

## Uniform scale multiplier — scale the entire environment model
@export var environment_scale: float = 25.0


# =============================================================================
# STATE
# =============================================================================

## The currently loaded environment model instance
var _environment_instance: Node3D = null


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	load_environment(selected_environment)


# =============================================================================
# PUBLIC API
# =============================================================================

## Load and display the specified environment. Removes any previously loaded one.
func load_environment(env: EnvironmentType) -> void:
	_clear_environment()
	selected_environment = env

	var path: String = ENVIRONMENT_PATHS.get(env, "")
	if path.is_empty():
		push_error("[EnvironmentBuilder] No path defined for environment: %d" % env)
		return

	if not ResourceLoader.exists(path):
		push_warning(("[EnvironmentBuilder] Model not found at '%s' — skipping. "
			+ "Add the .glb file to load this environment.") % path)
		return

	var scene := load(path) as PackedScene
	if not scene:
		push_error("[EnvironmentBuilder] Failed to load scene: %s" % path)
		return

	_environment_instance = scene.instantiate()
	_environment_instance.name = "EnvironmentModel"
	add_child(_environment_instance)
	_apply_transform()
	# Defer table alignment so all child transforms are propagated first
	call_deferred("_align_to_table")
	# Defer camera collision generation so transforms are resolved
	call_deferred("_generate_camera_collision_for_environment")

	print("[EnvironmentBuilder] Loaded environment: %s" % ENVIRONMENT_NAMES.get(env, "Unknown"))


## Pick a random environment from those whose .glb files exist on disk.
func load_random_environment() -> void:
	var available := _get_available_ids()
	if available.is_empty():
		push_error("[EnvironmentBuilder] No environment models found on disk!")
		return
	load_environment(available[randi() % available.size()])


## Return metadata for every environment whose .glb file is present on disk.
## Each entry: { "id": EnvironmentType, "name": String, "path": String }
func get_available_environments() -> Array:
	var result: Array = []
	for env_id in ENVIRONMENT_PATHS:
		if ResourceLoader.exists(ENVIRONMENT_PATHS[env_id]):
			result.append({
				"id": env_id,
				"name": ENVIRONMENT_NAMES.get(env_id, "Unknown"),
				"path": ENVIRONMENT_PATHS[env_id],
			})
	return result


## Get the display name of the currently loaded environment.
func get_current_environment_name() -> String:
	return ENVIRONMENT_NAMES.get(selected_environment, "Unknown")


# =============================================================================
# PRIVATE
# =============================================================================

func _clear_environment() -> void:
	if _environment_instance:
		_environment_instance.queue_free()
		_environment_instance = null


## Apply scale and rotation first (position is set by _align_to_table).
func _apply_transform() -> void:
	if not _environment_instance:
		return
	_environment_instance.position = Vector3.ZERO
	_environment_instance.rotation_degrees.y = rotation_degrees_y
	_environment_instance.scale = Vector3.ONE * environment_scale


## Find the table mesh and offset the model so the table center sits at board_center.
## Called deferred after load so child transforms are up to date.
func _align_to_table() -> void:
	if not _environment_instance:
		return

	var table := _environment_instance.find_child(TABLE_MESH_NAME, true, false)
	if table and table is Node3D:
		# With the model at origin, the table's global_position is its effective
		# position in world space (already includes scale and rotation).
		var table_world_pos: Vector3 = table.global_position
		var auto_offset: Vector3 = board_center - table_world_pos
		_environment_instance.position = auto_offset + position_offset
		print("[EnvironmentBuilder] Auto-aligned '%s' → table at %s" % [
			TABLE_MESH_NAME, board_center + position_offset])
	else:
		# No table mesh found — fall back to manual offset only
		_environment_instance.position = position_offset
		push_warning(("[EnvironmentBuilder] Table mesh '%s' not found in model. "
			+ "Using manual position_offset only.") % TABLE_MESH_NAME)


func _get_available_ids() -> Array:
	var ids: Array = []
	for env_id in ENVIRONMENT_PATHS:
		if ResourceLoader.exists(ENVIRONMENT_PATHS[env_id]):
			ids.append(env_id)
	return ids


# =============================================================================
# CAMERA COLLISION (Layer 16)
# =============================================================================

## Generate camera collision bodies for the loaded environment model.
## Walks every MeshInstance3D in the .glb scene tree and creates a trimesh
## StaticBody3D collider on Layer 16 so the camera can't clip through walls,
## furniture, shelves, and other room geometry.
func _generate_camera_collision_for_environment() -> void:
	if not _environment_instance:
		return
	
	var mesh_count := 0
	_add_camera_collision_recursive(_environment_instance, mesh_count)
	print("[EnvironmentBuilder] Camera collision: generated for %d meshes (Layer 16)" % mesh_count)


## Recursively traverse a node tree and add trimesh colliders to every MeshInstance3D.
func _add_camera_collision_recursive(node: Node, count: int) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh:
			# Godot's built-in method generates a perfectly fitting StaticBody3D child
			mi.create_trimesh_collision()
			
			# The newly created StaticBody3D is the last child of this MeshInstance3D
			var body_idx := mi.get_child_count() - 1
			if body_idx >= 0:
				var body := mi.get_child(body_idx)
				if body is StaticBody3D:
					body.collision_layer = 1 << 15  # Layer 16 — camera collision only
					body.collision_mask = 0          # Doesn't detect anything itself
					count += 1
	
	# Recurse into children
	for child in node.get_children():
		_add_camera_collision_recursive(child, count)
