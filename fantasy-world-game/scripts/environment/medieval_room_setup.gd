## Medieval Room Setup
## Assembles the medieval room from downloaded asset packs
## Creates a scholar's study matching the HDRI reference
class_name MedievalRoomSetup
extends Node3D

# =============================================================================
# ASSET PATHS - Quaternius Packs
# =============================================================================

const FANTASY_PROPS_PATH := "res://assets/asset pack download/Fantasy_Props/Exports/glTF/"
const MEDIEVAL_VILLAGE_PATH := "res://assets/asset pack download/Medieval_Village/Medieval Village MegaKit[Standard]/glTF/"
const MODULAR_DUNGEON_PATH := "res://assets/asset pack download/Modular_Dungeon/.Updated Modular Dungeon - May 2019/FBX/"

# =============================================================================
# CONFIGURATION
# =============================================================================

## Scale factor for props (Quaternius models are typically at game-ready scale)
@export var prop_scale: float = 1.0

## Scale for Medieval Village assets (they use a different scale)
@export var village_scale: float = 1.0

## Scale for Dungeon assets (FBX models)
@export var dungeon_scale: float = 0.01

## Enable candle lights
@export var enable_candle_lights: bool = true

## Enable fireplace light
@export var enable_fireplace_light: bool = true

## Build room architecture from 3D models (vs using CSG in scene)
@export var build_room_architecture: bool = true

# =============================================================================
# ROOM DIMENSIONS
# =============================================================================

const ROOM_WIDTH := 12.0  # X axis
const ROOM_DEPTH := 12.0  # Z axis  
const ROOM_HEIGHT := 7.0  # Y axis
const WALL_SEGMENT_SIZE := 2.0  # Size of each wall segment

# =============================================================================
# ROOM LAYOUT CONFIGURATION
# Based on the HDRI reference image
# =============================================================================

## Table props positioned relative to table center (0, 0, 0)
## Format: [model_name, position, rotation_y_degrees, scale_override]
const TABLE_PROPS := [
	# === LEFT SIDE OF TABLE ===
	# Open book (grimoire)
	["Book_7", Vector3(-1.2, 0.05, -0.2), -15.0, 0.8],
	# Candle with holder
	["CandleStick", Vector3(-1.0, 0.0, 0.3), 0.0, 0.7],
	# Small chest/box
	["Chest_Wood", Vector3(-1.4, 0.0, -0.5), 25.0, 0.25],
	# Red book (closed)
	["Book_5", Vector3(-0.9, 0.05, -0.55), 10.0, 0.7],
	# Glass bottle
	["Bottle_1", Vector3(-0.65, 0.0, -0.4), 0.0, 0.6],
	
	# === CENTER OF TABLE ===
	# Hourglass - using book stand as substitute
	["BookStand", Vector3(-0.3, 0.0, -0.3), 0.0, 0.4],
	# Leather pouch
	["Pouch_Large", Vector3(-0.1, 0.0, 0.4), 45.0, 0.5],
	# Rolled scroll
	["Scroll_1", Vector3(0.2, 0.02, -0.35), 30.0, 0.6],
	# Dagger
	["Sword_Bronze", Vector3(0.0, 0.0, 0.55), -25.0, 0.35],
	
	# === RIGHT SIDE OF TABLE (where the decorative vase is) ===
	# Main pillar candle - using triple candlestick
	["CandleStick_Triple", Vector3(0.5, 0.0, 0.0), 0.0, 0.6],
	# Decorative vase (teal pottery from HDRI)
	["Vase_2", Vector3(0.4, 0.0, 0.35), 15.0, 0.7],
	# Chalice/goblet
	["Chalice", Vector3(0.7, 0.0, -0.25), 0.0, 0.6],
	# Unrolled scroll/map
	["Scroll_2", Vector3(0.9, 0.02, 0.2), -10.0, 0.55],
	# Bowl of fruit (using apple crate as substitute)
	["FarmCrate_Apple", Vector3(1.0, 0.0, 0.5), 5.0, 0.35],
	# Keys
	["Key_Gold", Vector3(0.75, 0.02, 0.4), 60.0, 0.4],
	["Key_Metal", Vector3(0.8, 0.02, 0.45), 30.0, 0.5],
	
	# === ADDITIONAL ATMOSPHERE ===
	# Second dagger
	["Axe_Bronze", Vector3(1.2, 0.0, -0.15), -45.0, 0.4],
	# Mug
	["Mug", Vector3(-0.5, 0.0, 0.5), 20.0, 0.6],
	# Plate
	["Table_Plate", Vector3(0.3, 0.0, -0.5), 0.0, 0.7],
	# Small bottles group
	["SmallBottles_1", Vector3(-0.7, 0.0, 0.6), 0.0, 0.5],
	# Coins
	["Coin_Pile", Vector3(0.6, 0.02, -0.4), 0.0, 0.5],
	# Another book stack
	["Book_Stack_1", Vector3(-1.3, 0.05, 0.1), 35.0, 0.6],
	# Potion
	["Potion_1", Vector3(-0.4, 0.0, -0.55), 0.0, 0.55],
]

## Room furniture and props
const ROOM_PROPS := [
	# Chair behind table
	["Chair_1", Vector3(0.0, 0.0, -2.0), 180.0, 1.0],
	
	# Barrels in back left corner
	["Barrel", Vector3(-4.5, 0.0, -4.5), 15.0, 1.0],
	["Barrel", Vector3(-4.0, 0.0, -5.0), -10.0, 0.9],
	["Barrel", Vector3(-3.5, 0.0, -4.2), 25.0, 0.85],
	
	# Bookcase against back wall
	["Bookcase_2", Vector3(2.0, 0.0, -5.3), 0.0, 1.1],
	["Bookcase_2", Vector3(-2.0, 0.0, -5.3), 0.0, 1.1],
	
	# Crates in front right corner
	["Crate_Wooden", Vector3(4.2, 0.0, 4.5), 25.0, 0.8],
	["Crate_Wooden", Vector3(4.8, 0.0, 4.0), -15.0, 0.9],
	["Crate_Wooden", Vector3(4.5, 0.7, 4.2), 45.0, 0.7],
	
	# Bench against left wall
	["Bench", Vector3(-5.2, 0.0, 0.0), 90.0, 1.0],
	
	# Weapon stand against left wall
	["WeaponStand", Vector3(-5.0, 0.0, -2.5), 90.0, 0.9],
	
	# Shield leaning on wall
	["Shield_Wooden", Vector3(-5.5, 0.2, 2.5), 80.0, 0.9],
	
	# Cabinet against right wall
	["Cabinet", Vector3(5.2, 0.0, -2.0), -90.0, 1.0],
	
	# Shelf with bottles on right wall
	["Shelf_Small_Bottles", Vector3(5.5, 2.0, 1.0), -90.0, 0.8],
	
	# Chandelier (ceiling)
	["Chandelier", Vector3(0.0, 6.0, 0.0), 0.0, 0.8],
	
	# Bags and misc in corners
	["Bag", Vector3(-4.0, 0.0, 4.5), 45.0, 0.8],
	["Bag", Vector3(3.5, 0.0, -4.5), -30.0, 0.7],
	["Rope_1", Vector3(4.5, 0.1, -4.0), 0.0, 0.7],
	["Chain_Coil", Vector3(-4.5, 0.1, 3.5), 20.0, 0.5],
	
	# Stool near fireplace
	["Stool", Vector3(4.0, 0.0, 0.0), -45.0, 1.0],
	
	# Extra atmosphere
	["Cauldron", Vector3(4.5, 0.0, 2.0), 0.0, 0.7],
	["Bucket_Wooden_1", Vector3(-3.0, 0.0, 4.0), 15.0, 0.8],
]

## Wall decorations (higher placement)
const WALL_DECORATIONS := [
	# Wall lanterns
	["Lantern_Wall", Vector3(-5.8, 2.8, -2.0), 90.0, 0.9],
	["Lantern_Wall", Vector3(-5.8, 2.8, 2.0), 90.0, 0.9],
	["Lantern_Wall", Vector3(5.8, 2.8, -2.0), -90.0, 0.9],
	["Lantern_Wall", Vector3(5.8, 2.8, 2.0), -90.0, 0.9],
	
	# Torch on back wall (near door)
	["Torch_Metal", Vector3(0.0, 2.5, -5.8), 0.0, 0.8],
	["Torch_Metal", Vector3(-4.0, 2.5, -5.8), 0.0, 0.8],
	["Torch_Metal", Vector3(4.0, 2.5, -5.8), 0.0, 0.8],
	
	# Peg rack for hanging items
	["Peg_Rack", Vector3(-5.8, 1.8, 0.0), 90.0, 0.9],
]

## Room architecture pieces from Medieval Village pack
## Format: [model_name, position, rotation_y_degrees, scale, asset_pack]
## asset_pack: "village", "dungeon", "props"
const ARCHITECTURE_PIECES := [
	# === FLOOR TILES ===
	# Using dark wood floor tiles arranged in a grid
	["Floor_WoodDark", Vector3(-4.0, 0.0, -4.0), 0.0, 1.0, "village"],
	["Floor_WoodDark", Vector3(-2.0, 0.0, -4.0), 0.0, 1.0, "village"],
	["Floor_WoodDark", Vector3(0.0, 0.0, -4.0), 0.0, 1.0, "village"],
	["Floor_WoodDark", Vector3(2.0, 0.0, -4.0), 0.0, 1.0, "village"],
	["Floor_WoodDark", Vector3(4.0, 0.0, -4.0), 0.0, 1.0, "village"],
	["Floor_WoodDark", Vector3(-4.0, 0.0, -2.0), 0.0, 1.0, "village"],
	["Floor_WoodDark", Vector3(-2.0, 0.0, -2.0), 0.0, 1.0, "village"],
	["Floor_WoodDark", Vector3(0.0, 0.0, -2.0), 0.0, 1.0, "village"],
	["Floor_WoodDark", Vector3(2.0, 0.0, -2.0), 0.0, 1.0, "village"],
	["Floor_WoodDark", Vector3(4.0, 0.0, -2.0), 0.0, 1.0, "village"],
	["Floor_WoodDark", Vector3(-4.0, 0.0, 0.0), 0.0, 1.0, "village"],
	["Floor_WoodDark", Vector3(-2.0, 0.0, 0.0), 0.0, 1.0, "village"],
	["Floor_WoodDark", Vector3(0.0, 0.0, 0.0), 0.0, 1.0, "village"],
	["Floor_WoodDark", Vector3(2.0, 0.0, 0.0), 0.0, 1.0, "village"],
	["Floor_WoodDark", Vector3(4.0, 0.0, 0.0), 0.0, 1.0, "village"],
	["Floor_WoodDark", Vector3(-4.0, 0.0, 2.0), 0.0, 1.0, "village"],
	["Floor_WoodDark", Vector3(-2.0, 0.0, 2.0), 0.0, 1.0, "village"],
	["Floor_WoodDark", Vector3(0.0, 0.0, 2.0), 0.0, 1.0, "village"],
	["Floor_WoodDark", Vector3(2.0, 0.0, 2.0), 0.0, 1.0, "village"],
	["Floor_WoodDark", Vector3(4.0, 0.0, 2.0), 0.0, 1.0, "village"],
	["Floor_WoodDark", Vector3(-4.0, 0.0, 4.0), 0.0, 1.0, "village"],
	["Floor_WoodDark", Vector3(-2.0, 0.0, 4.0), 0.0, 1.0, "village"],
	["Floor_WoodDark", Vector3(0.0, 0.0, 4.0), 0.0, 1.0, "village"],
	["Floor_WoodDark", Vector3(2.0, 0.0, 4.0), 0.0, 1.0, "village"],
	["Floor_WoodDark", Vector3(4.0, 0.0, 4.0), 0.0, 1.0, "village"],
	
	# === BACK WALL (with door) - Uneven brick for stone look ===
	["Wall_UnevenBrick_Straight", Vector3(-4.0, 0.0, -6.0), 0.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(-2.0, 0.0, -6.0), 0.0, 1.0, "village"],
	["Wall_UnevenBrick_Door_Round", Vector3(0.0, 0.0, -6.0), 0.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(2.0, 0.0, -6.0), 0.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(4.0, 0.0, -6.0), 0.0, 1.0, "village"],
	# Upper wall sections
	["Wall_UnevenBrick_Straight", Vector3(-4.0, 2.0, -6.0), 0.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(-2.0, 2.0, -6.0), 0.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(0.0, 2.0, -6.0), 0.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(2.0, 2.0, -6.0), 0.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(4.0, 2.0, -6.0), 0.0, 1.0, "village"],
	# Third row
	["Wall_UnevenBrick_Straight", Vector3(-4.0, 4.0, -6.0), 0.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(-2.0, 4.0, -6.0), 0.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(0.0, 4.0, -6.0), 0.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(2.0, 4.0, -6.0), 0.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(4.0, 4.0, -6.0), 0.0, 1.0, "village"],
	
	# === LEFT WALL (with window) ===
	["Wall_UnevenBrick_Straight", Vector3(-6.0, 0.0, -4.0), 90.0, 1.0, "village"],
	["Wall_UnevenBrick_Window_Wide_Round", Vector3(-6.0, 0.0, -2.0), 90.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(-6.0, 0.0, 0.0), 90.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(-6.0, 0.0, 2.0), 90.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(-6.0, 0.0, 4.0), 90.0, 1.0, "village"],
	# Upper sections
	["Wall_UnevenBrick_Straight", Vector3(-6.0, 2.0, -4.0), 90.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(-6.0, 2.0, -2.0), 90.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(-6.0, 2.0, 0.0), 90.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(-6.0, 2.0, 2.0), 90.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(-6.0, 2.0, 4.0), 90.0, 1.0, "village"],
	# Third row
	["Wall_UnevenBrick_Straight", Vector3(-6.0, 4.0, -4.0), 90.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(-6.0, 4.0, -2.0), 90.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(-6.0, 4.0, 0.0), 90.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(-6.0, 4.0, 2.0), 90.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(-6.0, 4.0, 4.0), 90.0, 1.0, "village"],
	
	# === RIGHT WALL (fireplace side) ===
	["Wall_UnevenBrick_Straight", Vector3(6.0, 0.0, -4.0), -90.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(6.0, 0.0, -2.0), -90.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(6.0, 0.0, 0.0), -90.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(6.0, 0.0, 2.0), -90.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(6.0, 0.0, 4.0), -90.0, 1.0, "village"],
	# Upper sections
	["Wall_UnevenBrick_Straight", Vector3(6.0, 2.0, -4.0), -90.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(6.0, 2.0, -2.0), -90.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(6.0, 2.0, 0.0), -90.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(6.0, 2.0, 2.0), -90.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(6.0, 2.0, 4.0), -90.0, 1.0, "village"],
	# Third row
	["Wall_UnevenBrick_Straight", Vector3(6.0, 4.0, -4.0), -90.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(6.0, 4.0, -2.0), -90.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(6.0, 4.0, 0.0), -90.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(6.0, 4.0, 2.0), -90.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(6.0, 4.0, 4.0), -90.0, 1.0, "village"],
	
	# === FRONT WALL (player-facing, minimal) ===
	["Wall_UnevenBrick_Straight", Vector3(-4.0, 0.0, 6.0), 180.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(-2.0, 0.0, 6.0), 180.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(0.0, 0.0, 6.0), 180.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(2.0, 0.0, 6.0), 180.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(4.0, 0.0, 6.0), 180.0, 1.0, "village"],
	# Upper sections
	["Wall_UnevenBrick_Straight", Vector3(-4.0, 2.0, 6.0), 180.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(-2.0, 2.0, 6.0), 180.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(0.0, 2.0, 6.0), 180.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(2.0, 2.0, 6.0), 180.0, 1.0, "village"],
	["Wall_UnevenBrick_Straight", Vector3(4.0, 2.0, 6.0), 180.0, 1.0, "village"],
	
	# === DOOR ===
	["Door_2_Round", Vector3(0.0, 0.0, -5.9), 0.0, 1.0, "village"],
	
	# === WINDOW ===
	["Window_Wide_Round1", Vector3(-5.9, 1.0, -2.0), 90.0, 1.0, "village"],
	
	# === ARCH near fireplace ===
	["Wall_Arch", Vector3(5.5, 0.0, 0.0), -90.0, 1.0, "village"],
	
	# === DUNGEON ELEMENTS ===
	# Column/pillars for atmosphere
	["Column", Vector3(-5.5, 0.0, -5.5), 0.0, 1.0, "dungeon"],
	["Column", Vector3(5.5, 0.0, -5.5), 0.0, 1.0, "dungeon"],
	
	# Fireplace/Woodfire
	["Woodfire", Vector3(5.7, 0.0, 0.0), -90.0, 1.0, "dungeon"],
	
	# Wall-mounted torches from dungeon pack
	["Torch", Vector3(-5.7, 2.0, 0.0), 90.0, 1.0, "dungeon"],
	["Torch", Vector3(-5.7, 2.0, -4.0), 90.0, 1.0, "dungeon"],
	
	# Banner on wall
	["Banner_wall", Vector3(0.0, 3.5, -5.8), 0.0, 1.0, "dungeon"],
	
	# Cobwebs in corners (atmosphere)
	["Cobweb", Vector3(-5.8, 5.5, -5.8), 0.0, 1.0, "dungeon"],
	["Cobweb2", Vector3(5.8, 5.5, -5.8), 0.0, 1.0, "dungeon"],
	["Cobweb", Vector3(-5.8, 5.5, 5.8), 180.0, 1.0, "dungeon"],
]

# =============================================================================
# REFERENCES
# =============================================================================

var table_node: Node3D
var architecture_container: Node3D
var props_container: Node3D
var lights_container: Node3D


# =============================================================================
# SETUP
# =============================================================================

func _ready() -> void:
	_create_containers()
	_setup_room()


func _create_containers() -> void:
	architecture_container = Node3D.new()
	architecture_container.name = "Architecture"
	add_child(architecture_container)
	
	props_container = Node3D.new()
	props_container.name = "Props"
	add_child(props_container)
	
	lights_container = Node3D.new()
	lights_container.name = "Lights"
	add_child(lights_container)


func _setup_room() -> void:
	print("[MedievalRoomSetup] Setting up medieval room...")
	
	# Build room architecture from 3D models
	if build_room_architecture:
		_build_architecture()
	
	# Create the table first
	_create_table()
	
	# Add props to the table
	_setup_table_props()
	
	# Add room props
	_setup_room_props()
	
	# Add wall decorations
	_setup_wall_decorations()
	
	# Setup lighting
	_setup_lighting()
	
	print("[MedievalRoomSetup] Room setup complete!")


# =============================================================================
# ARCHITECTURE
# =============================================================================

func _build_architecture() -> void:
	print("[MedievalRoomSetup] Building room architecture...")
	
	var loaded_count := 0
	var failed_count := 0
	
	for piece_data in ARCHITECTURE_PIECES:
		var model_name: String = piece_data[0]
		var pos: Vector3 = piece_data[1]
		var rot_y: float = piece_data[2]
		var scale_mult: float = piece_data[3]
		var asset_pack: String = piece_data[4]
		
		var piece = _spawn_architecture_piece(model_name, pos, rot_y, scale_mult, asset_pack)
		if piece:
			architecture_container.add_child(piece)
			loaded_count += 1
		else:
			failed_count += 1
	
	print("[MedievalRoomSetup] Architecture: loaded %d pieces, %d failed" % [loaded_count, failed_count])


func _spawn_architecture_piece(model_name: String, pos: Vector3, rot_y: float, 
							   scale_mult: float, asset_pack: String) -> Node3D:
	var path: String
	var base_scale: float
	
	match asset_pack:
		"village":
			path = MEDIEVAL_VILLAGE_PATH + model_name + ".gltf"
			base_scale = village_scale
		"dungeon":
			path = MODULAR_DUNGEON_PATH + model_name + ".fbx"
			base_scale = dungeon_scale
		"props":
			path = FANTASY_PROPS_PATH + model_name + ".gltf"
			base_scale = prop_scale
		_:
			push_warning("[MedievalRoomSetup] Unknown asset pack: " + asset_pack)
			return null
	
	var scene = _load_model(path)
	if not scene:
		return null
	
	var instance = scene.instantiate()
	instance.name = model_name
	instance.position = pos
	instance.rotation.y = deg_to_rad(rot_y)
	instance.scale = Vector3.ONE * base_scale * scale_mult
	
	return instance


# =============================================================================
# TABLE CREATION
# =============================================================================

func _create_table() -> void:
	# Try to load large table from Fantasy Props
	var table_path = FANTASY_PROPS_PATH + "Table_Large.gltf"
	var table_scene = _load_model(table_path)
	
	if table_scene:
		table_node = table_scene.instantiate()
		table_node.name = "MainTable"
		table_node.scale = Vector3.ONE * prop_scale * 1.5  # Make table larger
		table_node.position = Vector3(0, 0, 0)
		props_container.add_child(table_node)
		print("[MedievalRoomSetup] Loaded main table")
	else:
		# Fallback: use dungeon table
		var dungeon_table_path = MODULAR_DUNGEON_PATH + "Table_Big.fbx"
		table_scene = _load_model(dungeon_table_path)
		if table_scene:
			table_node = table_scene.instantiate()
			table_node.name = "MainTable"
			table_node.scale = Vector3.ONE * dungeon_scale * 2.0
			table_node.position = Vector3(0, 0, 0)
			props_container.add_child(table_node)
			print("[MedievalRoomSetup] Loaded dungeon table (fallback)")
		else:
			push_warning("[MedievalRoomSetup] Could not load table model!")


# =============================================================================
# TABLE PROPS
# =============================================================================

func _setup_table_props() -> void:
	print("[MedievalRoomSetup] Setting up table props...")
	
	var table_props_container = Node3D.new()
	table_props_container.name = "TableProps"
	props_container.add_child(table_props_container)
	
	# Position above table surface
	table_props_container.position.y = 0.85
	
	var loaded_count = 0
	for prop_data in TABLE_PROPS:
		var model_name: String = prop_data[0]
		var pos: Vector3 = prop_data[1]
		var rot_y: float = prop_data[2]
		var scale_mult: float = prop_data[3]
		
		var prop = _spawn_prop(model_name, pos, rot_y, scale_mult)
		if prop:
			table_props_container.add_child(prop)
			loaded_count += 1
	
	print("[MedievalRoomSetup] Loaded %d/%d table props" % [loaded_count, TABLE_PROPS.size()])


func _setup_room_props() -> void:
	print("[MedievalRoomSetup] Setting up room props...")
	
	var room_props_container = Node3D.new()
	room_props_container.name = "RoomProps"
	props_container.add_child(room_props_container)
	
	var loaded_count = 0
	for prop_data in ROOM_PROPS:
		var model_name: String = prop_data[0]
		var pos: Vector3 = prop_data[1]
		var rot_y: float = prop_data[2]
		var scale_mult: float = prop_data[3]
		
		var prop = _spawn_prop(model_name, pos, rot_y, scale_mult)
		if prop:
			room_props_container.add_child(prop)
			loaded_count += 1
	
	print("[MedievalRoomSetup] Loaded %d/%d room props" % [loaded_count, ROOM_PROPS.size()])


func _setup_wall_decorations() -> void:
	print("[MedievalRoomSetup] Setting up wall decorations...")
	
	var wall_decor_container = Node3D.new()
	wall_decor_container.name = "WallDecorations"
	props_container.add_child(wall_decor_container)
	
	var loaded_count = 0
	for decor_data in WALL_DECORATIONS:
		var model_name: String = decor_data[0]
		var pos: Vector3 = decor_data[1]
		var rot_y: float = decor_data[2]
		var scale_mult: float = decor_data[3]
		
		var decor = _spawn_prop(model_name, pos, rot_y, scale_mult)
		if decor:
			wall_decor_container.add_child(decor)
			loaded_count += 1
	
	print("[MedievalRoomSetup] Loaded %d/%d wall decorations" % [loaded_count, WALL_DECORATIONS.size()])


func _spawn_prop(model_name: String, pos: Vector3, rot_y: float, scale_mult: float) -> Node3D:
	# Try Fantasy Props first (GLTF)
	var path = FANTASY_PROPS_PATH + model_name + ".gltf"
	var scene = _load_model(path)
	
	if not scene:
		# Try Medieval Village (GLTF)
		path = MEDIEVAL_VILLAGE_PATH + model_name + ".gltf"
		scene = _load_model(path)
	
	if not scene:
		# Try Modular Dungeon (FBX)
		path = MODULAR_DUNGEON_PATH + model_name + ".fbx"
		scene = _load_model(path)
		if scene:
			# FBX needs different scale
			var instance = scene.instantiate()
			instance.name = model_name
			instance.position = pos
			instance.rotation.y = deg_to_rad(rot_y)
			instance.scale = Vector3.ONE * dungeon_scale * scale_mult
			return instance
	
	if not scene:
		push_warning("[MedievalRoomSetup] Could not load prop: " + model_name)
		return null
	
	var instance = scene.instantiate()
	instance.name = model_name
	instance.position = pos
	instance.rotation.y = deg_to_rad(rot_y)
	instance.scale = Vector3.ONE * prop_scale * scale_mult
	
	return instance


func _load_model(path: String) -> PackedScene:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as PackedScene


# =============================================================================
# LIGHTING
# =============================================================================

func _setup_lighting() -> void:
	print("[MedievalRoomSetup] Setting up lighting...")
	
	if enable_candle_lights:
		# Main candle on table (triple candlestick position)
		_create_candle_light(Vector3(0.5, 1.2, 0.0), 2.5, 7.0, "MainTableCandle")
		
		# Secondary candle (single candlestick)
		_create_candle_light(Vector3(-1.0, 1.1, 0.3), 1.5, 5.0, "SecondaryCandle")
		
		# Chandelier light
		_create_candle_light(Vector3(0.0, 5.5, 0.0), 4.0, 14.0, "ChandelierLight")
		
		# Wall lanterns
		_create_candle_light(Vector3(-5.5, 2.8, -2.0), 1.8, 6.0, "WallLantern1")
		_create_candle_light(Vector3(-5.5, 2.8, 2.0), 1.8, 6.0, "WallLantern2")
		_create_candle_light(Vector3(5.5, 2.8, -2.0), 1.8, 6.0, "WallLantern3")
		_create_candle_light(Vector3(5.5, 2.8, 2.0), 1.8, 6.0, "WallLantern4")
		
		# Wall torches
		_create_candle_light(Vector3(0.0, 2.5, -5.5), 2.0, 6.0, "WallTorch1")
		_create_candle_light(Vector3(-4.0, 2.5, -5.5), 1.5, 5.0, "WallTorch2")
		_create_candle_light(Vector3(4.0, 2.5, -5.5), 1.5, 5.0, "WallTorch3")
		_create_candle_light(Vector3(-5.5, 2.0, 0.0), 1.5, 5.0, "DungeonTorch1")
		_create_candle_light(Vector3(-5.5, 2.0, -4.0), 1.5, 5.0, "DungeonTorch2")
	
	if enable_fireplace_light:
		_create_fireplace_light(Vector3(5.5, 0.8, 0.0), "FireplaceMain")
		# Secondary fire glow higher up
		_create_candle_light(Vector3(5.3, 1.5, 0.0), 1.5, 4.0, "FireplaceGlow")
	
	# Window light (cool blue moonlight)
	_create_window_light(Vector3(-5.5, 2.5, -2.0))
	
	print("[MedievalRoomSetup] Lighting setup complete")


func _create_candle_light(pos: Vector3, energy: float, light_range: float, light_name: String = "CandleLight") -> OmniLight3D:
	var light = OmniLight3D.new()
	light.name = light_name
	light.position = pos
	light.light_color = Color(1.0, 0.85, 0.6)  # Warm candle color
	light.light_energy = energy
	light.omni_range = light_range
	light.omni_attenuation = 1.2
	light.shadow_enabled = true
	light.light_indirect_energy = 0.5
	lights_container.add_child(light)
	return light


func _create_fireplace_light(pos: Vector3, light_name: String = "FireplaceLight") -> OmniLight3D:
	var light = OmniLight3D.new()
	light.name = light_name
	light.position = pos
	light.light_color = Color(1.0, 0.45, 0.15)  # Deep orange fire color
	light.light_energy = 5.0
	light.omni_range = 12.0
	light.omni_attenuation = 0.9
	light.shadow_enabled = true
	light.light_indirect_energy = 1.0
	lights_container.add_child(light)
	return light


func _create_window_light(pos: Vector3) -> SpotLight3D:
	var light = SpotLight3D.new()
	light.name = "WindowLight"
	light.position = pos
	light.rotation.y = deg_to_rad(90)  # Point into room
	light.light_color = Color(0.6, 0.7, 0.9)  # Cool moonlight blue
	light.light_energy = 2.0
	light.spot_range = 10.0
	light.spot_angle = 45.0
	light.shadow_enabled = true
	light.light_indirect_energy = 0.3
	lights_container.add_child(light)
	return light
