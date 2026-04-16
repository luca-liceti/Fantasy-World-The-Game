## Main Game Entry Point
## Sets up the game and coordinates all systems
## This is the playable test scene with GameManager integration
extends Node3D

const DEBUG_ENABLED := true

func debug_print(msg: String) -> void:
	if DEBUG_ENABLED:
		print(msg)

# Preload dependencies
const SettingsMenuScene = preload("res://scripts/ui/settings_menu.gd")
const CardSelectionUIScene = preload("res://scripts/ui/card_selection_ui.gd")
const FirstMoveDiceUIScene = preload("res://scripts/ui/first_move_dice_ui.gd")
const CombatSelectionUIScene = preload("res://scripts/ui/combat_selection_ui.gd")
const CombatResolutionUIScene = preload("res://scripts/ui/combat_resolution_ui.gd")

# =============================================================================
# NODE REFERENCES
# =============================================================================
var hex_board: HexBoard
var camera: Camera3D
var camera_pivot: Node3D
var camera_body: CharacterBody3D # Physical camera carrier (collision)
var game_manager: GameManager
var game_ui: GameUI
var dice_ui: DiceUI
var card_selection_ui: Node # CardSelectionUI
var first_move_dice_ui: FirstMoveDiceUI # UI for initial turn order roll
var combat_selection_ui: CombatSelectionUI # Enhanced combat UI for move/stance selection
var combat_resolution_ui: Node # Enhanced combat resolution display
var terrain_loading_screen: CanvasLayer = null # Loading screen during terrain generation

# Dynamic lighting state
var board_world_env: WorldEnvironment = null  # World environment for board lighting
var _current_biome_environment: Biomes.Type = Biomes.Type.PLAINS  # Current active biome
const BIOME_ENVIRONMENT_TRANSITION_SPEED: float = 2.0  # Smooth transition speed
const BIOME_DETECTION_RADIUS: float = 8.0  # Radius to detect dominant biome
const BIOME_DETECTION_INTERVAL: float = 0.5  # Detection check interval (seconds)
var _last_biome_detection_time: float = 0.0  # Last detection time

# Deck selection state
var is_selecting_decks: bool = false
var current_selecting_player: int = 0
var player_decks: Array[Array] = [[], []] # Stores selected decks for both players
var board_generation_complete: bool = false

# Alternating Draft state
## { player_id: { slot_index: card_id } }  — built pick-by-pick
var _draft_picks: Dictionary = {0: {}, 1: {}}
var _draft_turn_count: int = 0 # 0-7 (8 picks total, 4 per player)
var _draft_starting_player: int = 0 # rolled randomly at start

# =============================================================================
# CAMERA SETTINGS
# =============================================================================
const ZOOM_MIN: float = 3.0 # Closest zoom (to see characters up close)
const ZOOM_MAX: float = 40.0 # Farthest zoom (see whole board)
const ZOOM_SPEED: float = 0.15 # Zoom sensitivity
const PAN_SPEED: float = 15.0 # WASD pan speed
const ROTATE_SPEED: float = 0.3 # Mouse rotation sensitivity (degrees per pixel)
const PAN_SPEED_SHIFT: float = 30.0 # Faster pan when holding Shift
const CAMERA_TRANSITION_SPEED: float = 3.0 # Smooth camera movement speed

# Camera Collision Settings
const CAMERA_COLLISION_SPHERE_RADIUS: float = 0.3 # Physical camera body radius
const CAMERA_COLLISION_LAYER: int = 1 << 15 # Physics Layer 16 (0-indexed bit 15)

var camera_distance: float = 25.0 # Current zoom distance (closer for immersive view)
var _camera_body_initialized: bool = false # First-frame teleport flag
var camera_yaw: float = 0.0 # Horizontal rotation (Y-axis)
var camera_pitch: float = 35.0 # Vertical rotation (X-axis), lower for grounded view

var is_rotating: bool = false # Is right-click drag active?
var is_panning_mouse: bool = false # Is middle-click drag active?

# Focus point for camera orbit (where camera looks at)
var focus_point: Vector3 = Vector3.ZERO

# Camera view presets
enum CameraView {
	OVERVIEW, # Full board view from behind player's troops
	TACTICAL, # Closer tactical view centered on action
	TROOP_FOCUS, # Close-up on selected troop
	FRONT_QUARTER, # Zoomed view from front quarter 45° CW
	TOP_DOWN, # Bird's eye view
	CINEMATIC # Low angle dramatic view
}

var current_view: CameraView = CameraView.OVERVIEW
var target_focus_point: Vector3 = Vector3.ZERO
var target_distance: float = 25.0
var target_yaw: float = 0.0
var target_pitch: float = 35.0
var is_camera_transitioning: bool = false

# Smooth transition variables
var transition_progress: float = 0.0
var transition_duration: float = 1.5 # Duration in seconds for player switch
var start_focus_point: Vector3 = Vector3.ZERO
var start_distance: float = 35.0
var start_yaw: float = 0.0
var start_pitch: float = 45.0
var is_player_switch_transition: bool = false # Special cinematic transition

# Combat camera — saved state to restore after combat ends
var _pre_combat_focus: Vector3 = Vector3.ZERO
var _pre_combat_distance: float = 25.0
var _pre_combat_yaw: float = 0.0
var _pre_combat_pitch: float = 35.0
var _pre_combat_view: CameraView = CameraView.OVERVIEW
var _in_combat_camera: bool = false
## When true the dice-roll cinematic is active; all game input is locked
## except ESC (pause) and ENTER (roll).  Set by FirstMoveDiceUI / DiceUI.
var dice_roll_active: bool = false

# View preset definitions: {distance, pitch, yaw_offset from base position}
# yaw_offset: 0 = directly behind player, positive = rotate right, negative = rotate left
const VIEW_PRESETS: Dictionary = {
	"OVERVIEW": {"distance": 32.0, "pitch": 35.0, "yaw_offset": 0.0},
	"TACTICAL": {"distance": 16.0, "pitch": 40.0, "yaw_offset": 0.0},
	"TROOP_FOCUS": {"distance": 8.0, "pitch": 25.0, "yaw_offset": 15.0},
	"FRONT_QUARTER": {"distance": 5.0, "pitch": 25.0, "yaw_offset": 165.0},
	"TOP_DOWN": {"distance": 35.0, "pitch": 90.0, "yaw_offset": 0.0},
	"CINEMATIC": {"distance": 12.0, "pitch": 15.0, "yaw_offset": 25.0}
}

const VIEW_NAMES: Array[String] = ["Overview", "Tactical", "Troop Focus", "Front Quarter View", "Top-Down", "Cinematic"]

# =============================================================================
# GAME STATE
# =============================================================================
var game_started: bool = false
var decks_confirmed: bool = false
var selected_troop: Node = null
var troops: Array[Troop] = []

# Action mode: "none", "move", "attack", "mine"
var action_mode: String = "none"

# Pause state
var is_paused: bool = false
var pause_menu: CanvasLayer = null
var ignore_camera_process: bool = false
var _last_timer_update: float = 0.0
const TIMER_UPDATE_INTERVAL: float = 0.1

# Team Colors
const PLAYER1_COLOR = Color(0.2, 0.5, 1.0) # Blue
const PLAYER2_COLOR = Color(1.0, 0.3, 0.2) # Red

# =============================================================================
# DEBUG FLAGS - Set these to skip game phases during development
# =============================================================================
const DEBUG_SKIP_DECK_SELECTION: bool = true
const DEBUG_SKIP_FIRST_MOVE_DICE: bool = true
const DEBUG_DEFAULT_DECK: Array[String] = ["medieval_knight", "elven_archer", "celestial_cleric", "frost_valkyrie"] # Default deck when skipping

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	print("Fantasy World Game - Starting...")
	print("Godot Version: %s" % Engine.get_version_info().string)
	
	# Find or create camera system
	_setup_camera_system()
	
	# Handle pause menu input
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Find hex board
	hex_board = get_node_or_null("HexBoard")
	if hex_board:
		# Ensure the board pauses when the game is paused
		hex_board.process_mode = Node.PROCESS_MODE_PAUSABLE
		# Ensure board is at origin so BOARD_LIFT (1.0) is accurate world height
		hex_board.position.y = 0.0
		# Board generation is deferred to _finalize_game_start() (after deck selection)
	else:
		push_error("HexBoard node not found!")
	
	# Create game UI
	_setup_game_ui()
	
	# Start test game (deck selection — board generation deferred until after)
	_start_test_game()
	
	print("Game initialization complete!")
	print("")
	_print_controls()


func _print_controls() -> void:
	print("=== CONTROLS ===")
	print("Right-Click + Drag: Rotate camera")
	print("Middle-Click + Drag: Pan camera")
	print("WASD: Move camera (relative to view)")
	print("Q/E: Move camera up/down")
	print("Scroll: Zoom in/out")
	print("Shift: Move faster")
	print("V: Cycle camera views")
	print("F: Focus on selected troop/tile")
	print("Home: Reset camera")
	print("")
	print("=== GAMEPLAY ===")
	print("Left-Click tile: Select")
	print("1-4: Select troop by slot")
	print("Space: End turn")
	print("M: Toggle move mode")
	print("T: Toggle attack mode")
	print("================")


func _setup_camera_system() -> void:
	# Create camera pivot (for reference / compatibility)
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	add_child(camera_pivot)
	
	# Create camera as child of pivot
	camera = Camera3D.new()
	camera.name = "MainCamera"
	camera.current = true
	camera.fov = 60.0
	camera.near = 0.1 # Near-clip buffer
	camera_pivot.add_child(camera)
	
	# Create CharacterBody3D as the physical camera carrier.
	# The camera's eye position IS this body's position.
	# move_and_collide() prevents it from entering any solid geometry
	# on Layer 16 — walls, floor, ceiling, decorations, troops, board, etc.
	# The camera can ONLY travel through air.
	camera_body = CharacterBody3D.new()
	camera_body.name = "CameraBody"
	camera_body.collision_layer = 0 # Invisible to other objects
	camera_body.collision_mask = 0 # Collision disabled
	add_child(camera_body)
	
	var cam_col = CollisionShape3D.new()
	var cam_sphere = SphereShape3D.new()
	cam_sphere.radius = CAMERA_COLLISION_SPHERE_RADIUS
	cam_col.shape = cam_sphere
	camera_body.add_child(cam_col)
	
	# Remove old camera if it exists
	var old_camera = get_node_or_null("CameraPivot/GameCamera")
	if old_camera:
		old_camera.queue_free()
	var old_pivot = get_node_or_null("CameraPivot")
	if old_pivot and old_pivot != camera_pivot:
		old_pivot.queue_free()
	old_camera = get_node_or_null("GameCamera")
	if old_camera:
		old_camera.queue_free()
	
	# Apply initial transform (first call teleports the body)
	_camera_body_initialized = false
	_update_camera_transform()
	print("Camera system initialized (CharacterBody3D collision, radius=%.2f)" % CAMERA_COLLISION_SPHERE_RADIUS)


func _generate_board_concurrently() -> void:
	await hex_board.generate_board_async()
	hex_board.print_board_stats()
	
	# Connect board signals
	hex_board.tile_selected.connect(_on_tile_selected)
	hex_board.tile_hovered.connect(_on_tile_hovered)
	
	# Always create the stone border frame around the hex board
	var board_radius = GameConfig.BOARD_SIZE - 1
	var perimeter = hex_board.get_perimeter_points()
	
	# Check if an environment model provides the table
	var medieval_room = get_node_or_null("MedievalRoom")
	var physical_room = get_node_or_null("PhysicalRoom")
	if medieval_room or physical_room:
		# Environment model provides the table and surroundings  
		# Still create the stone border frame (but skip the wooden table surface)
		var board_environment = BoardEnvironment.create_for_board(board_radius, hex_board.hex_size, perimeter, true)
		add_child(board_environment)
		move_child(board_environment, 0)
		print("Using environment model - created stone border only (no table)")
	else:
		# Create standalone board environment (wooden table + stone frame)
		var board_environment = BoardEnvironment.create_for_board(board_radius, hex_board.hex_size, perimeter)
		add_child(board_environment)
		# Move it behind the hex board in the scene tree but keep it at same position
		move_child(board_environment, 0)
		
		# Add lighting for standalone board setup
		_setup_board_lighting()
	
	print("Board generated successfully!")
	board_generation_complete = true
	
	# Generation is always triggered from _finalize_game_start, so proceed now
	_hide_terrain_loading_screen()
	_proceed_to_first_move()


func _setup_board_lighting() -> void:
	# Create main directional light for the board
	var main_light = LightingManager.create_directional_light()
	add_child(main_light)
	
	# Create a secondary fill light for softer shadows
	var fill_light = LightingManager.create_fill_light()
	add_child(fill_light)
	
	# Set up world environment for atmospheric golden hour lighting
	board_world_env = WorldEnvironment.new()
	var environment = LightingManager.create_environment()
	
	# Apply to world
	board_world_env.environment = environment
	add_child(board_world_env)
	
	print("Board lighting setup complete!")


func _setup_game_ui() -> void:
	# Create GameUI as child of existing GameUI CanvasLayer
	var ui_layer = get_node_or_null("GameUI")
	if ui_layer:
		game_ui = GameUI.new()
		ui_layer.add_child(game_ui)
		
		# Connect UI signals
		game_ui.action_move_pressed.connect(_on_action_move)
		game_ui.action_attack_pressed.connect(_on_action_attack)
		game_ui.action_place_mine_pressed.connect(_on_action_place_mine)
		game_ui.action_upgrade_pressed.connect(_on_action_upgrade)
		game_ui.action_end_turn_pressed.connect(_on_action_end_turn)
		game_ui.troop_slot_selected.connect(_on_troop_slot_selected)
		
		# Create Dice UI for combat visualization (3D d20 die toss)
		dice_ui = DiceUI.new()
		dice_ui.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(dice_ui)
		dice_ui.set_camera(camera, self )


		# Create Card Selection UI
		card_selection_ui = CardSelectionUIScene.new()
		card_selection_ui.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(card_selection_ui)
		card_selection_ui.deck_confirmed.connect(_on_deck_confirmed)
		card_selection_ui.pick_made.connect(_on_pick_made)
		card_selection_ui.selection_canceled.connect(_on_deck_selection_canceled)
		
		# DEBUG: Set to true to disable the first move dice UI completely
		var disable_first_move_dice_ui := false
		
		# Create First Move Dice UI for turn order roll
		if not disable_first_move_dice_ui:
			first_move_dice_ui = FirstMoveDiceUIScene.new()
			first_move_dice_ui.process_mode = Node.PROCESS_MODE_PAUSABLE
			add_child(first_move_dice_ui)
			first_move_dice_ui.roll_complete.connect(_on_first_move_roll_complete)
			# Inject camera + root refs so the cinematic can drive camera & spawn dice
			first_move_dice_ui.set_camera(camera, self )
		else:
			print("DEBUG: FirstMoveDiceUI creation disabled")
		
		# Create Enhanced Combat Selection UI
		combat_selection_ui = CombatSelectionUIScene.new()
		combat_selection_ui.process_mode = Node.PROCESS_MODE_PAUSABLE
		combat_selection_ui.layer = 120 # Above most UI
		add_child(combat_selection_ui)
		combat_selection_ui.move_selected.connect(_on_enhanced_move_selected)
		combat_selection_ui.stance_selected.connect(_on_enhanced_stance_selected)
		combat_selection_ui.timeout.connect(_on_enhanced_combat_timeout)
		# Initialize with Enhanced mode by default (will be updated when game starts)
		combat_selection_ui.set_combat_mode(GameConfig.CombatMode.ENHANCED)
		print("Enhanced Combat Selection UI created")
	else:
		push_error("GameUI CanvasLayer not found!")


# =============================================================================
# TEST GAME SETUP
# =============================================================================

func _start_test_game() -> void:
	print("Starting test game...")
	
	# Create GameManager
	game_manager = GameManager.new()
	# Ensure the GameManager (and its children) pause when the game is paused
	game_manager.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(game_manager)
	
	# Initialize game - don't create new board, use existing
	game_manager.hex_board = hex_board
	game_manager.initialize_game({
		"turn_timer": 180.0, # 3 minutes per turn
		"starting_gold": 150,
		"starting_xp": 0
	})
	
	# Connect signals AFTER initialization
	game_manager.turn_manager.turn_started.connect(_on_turn_started)
	game_manager.turn_manager.turn_ended.connect(_on_turn_ended)
	game_manager.game_ended.connect(_on_game_over)
	
	# Connect enhanced combat signals
	game_manager.combat_selection_started.connect(_on_combat_selection_started)
	game_manager.combat_manager.combat_resolved.connect(_on_combat_resolved)
	
	# Hide game UI during deck selection
	if game_ui and game_ui.main_container:
		game_ui.main_container.visible = false
	
	# DEBUG: Skip deck selection for faster testing
	if DEBUG_SKIP_DECK_SELECTION:
		print("DEBUG: Skipping deck selection - using default decks")
		player_decks[0] = DEBUG_DEFAULT_DECK.duplicate()
		player_decks[1] = DEBUG_DEFAULT_DECK.duplicate()
		game_manager.set_player_deck(0, player_decks[0])
		game_manager.set_player_deck(1, player_decks[1])
		_finalize_game_start()
		return
	
	# Choose draft mode from GameConfig
	if GameConfig.deck_selection_mode == GameConfig.DeckSelectionMode.ALTERNATING_DRAFT:
		_start_draft_selection()
	else:
		# Legacy mode: Player 1 picks whole deck, then Player 2
		_start_deck_selection(0)


## Start deck selection phase for a player (SEQUENTIAL mode)
func _start_deck_selection(player_id: int) -> void:
	is_selecting_decks = true
	current_selecting_player = player_id
	game_manager.current_state = GameManager.GameState.DECK_SELECTION
	
	print("=== DECK SELECTION (Sequential) ===")
	print("Player %d - Select your deck!" % (player_id + 1))
	print("card_selection_ui exists: %s" % (card_selection_ui != null))
	
	# Show card selection UI (sequential mode — no draft mode flag)
	if card_selection_ui:
		print("Calling show_selection...")
		card_selection_ui.show_selection(player_id, true)
		print("show_selection called!")
	else:
		push_error("ERROR: card_selection_ui is NULL!")


# =============================================================================
# ALTERNATING DRAFT
# =============================================================================

## Kick off the alternating draft. Rolls a random first player.
func _start_draft_selection() -> void:
	is_selecting_decks = true
	game_manager.current_state = GameManager.GameState.DECK_SELECTION
	_draft_picks = {0: {}, 1: {}}
	_draft_turn_count = 0
	_draft_starting_player = randi() % 2 # Random first picker
	print("=== ALTERNATING DRAFT — Player %d goes first ===" % (_draft_starting_player + 1))
	_show_draft_pick_for_turn()


## Determine whose turn it is and which slot (if any) is restricted,
## then open the card selection UI for one pick.
func _show_draft_pick_for_turn() -> void:
	# Turn order: 0,1,1,0,0,1,1,0 (snake/alternating pairs)
	# Each player makes 4 picks total (8 picks across both players).
	# After the first pick the opponent may pick from the SAME slot or switch freely.
	# Implementation: each pick is completely free (no slot restriction after pick 1)
	# because the user spec says the opponent can "pick from the same category OR another".
	var picker: int = (_draft_starting_player + _draft_turn_count) % 2
	current_selecting_player = picker
	
	# The slot restriction only applies on the VERY FIRST pick of a new category
	# i.e. when a slot has exactly 0 existing picks for BOTH players — it has no restriction.
	# The opponent is free to continue in the same category or open a new one.
	# -> No hard restriction; the UI simply greys out already-taken cards.
	
	# Build the opponent_picks dict to pass to the UI
	var opp_picks_for_ui: Dictionary = _draft_picks.duplicate(true) # deep copy
	
	print("Draft turn %d: Player %d picks" % [_draft_turn_count, picker + 1])
	
	if card_selection_ui:
		card_selection_ui.show_selection(
			picker,
			true, # timer enabled
			opp_picks_for_ui,
			-1, # no slot restriction (free choice)
			true # draft_mode = true
		)
	else:
		push_error("ERROR: card_selection_ui is NULL!")


## Called each time a player makes a single draft pick.
func _on_pick_made(picker_id: int, slot_index: int, card_id: String) -> void:
	print("Draft pick: Player %d → slot %d → %s" % [picker_id + 1, slot_index, card_id])
	
	# Store the pick
	_draft_picks[picker_id][slot_index] = card_id
	_draft_turn_count += 1
	
	# Check if both players have filled all 4 slots
	var p0_done = (_draft_picks[0].size() == 4)
	var p1_done = (_draft_picks[1].size() == 4)
	
	if p0_done and p1_done:
		# Draft complete — convert dicts to ordered arrays
		var deck0: Array[String] = ["", "", "", ""]
		var deck1: Array[String] = ["", "", "", ""]
		for slot in _draft_picks[0]:
			deck0[slot] = _draft_picks[0][slot]
		for slot in _draft_picks[1]:
			deck1[slot] = _draft_picks[1][slot]
		player_decks[0] = deck0
		player_decks[1] = deck1
		game_manager.set_player_deck(0, deck0)
		game_manager.set_player_deck(1, deck1)
		print("Draft complete! P0 deck: %s | P1 deck: %s" % [str(deck0), str(deck1)])
		_finalize_game_start()
		return
	
	# Continue with the next picker
	_show_draft_pick_for_turn()


## Called when a player confirms their deck
func _on_deck_confirmed(deck: Array[String]) -> void:
	print("Player %d confirmed deck: %s" % [current_selecting_player + 1, str(deck)])
	
	# Store the deck
	player_decks[current_selecting_player] = deck
	
	# Set the deck in game manager
	var result = game_manager.set_player_deck(current_selecting_player, deck)
	print("set_player_deck result for player %d: %s" % [current_selecting_player, str(result)])
	
	# Ensure deck is set even if validation returned issues
	var player = game_manager.player_manager.get_player(current_selecting_player)
	if player:
		if player.deck.size() == 0 and deck.size() > 0:
			print("WARNING: Deck was not set, forcing assignment...")
			player.deck = deck.duplicate()
		print("Player %d deck after set: %s" % [current_selecting_player, str(player.deck)])
	
	if current_selecting_player == 0:
		# Player 1 done, now Player 2 selects
		_start_deck_selection(1)
	else:
		# Both players have selected, start the game
		_finalize_game_start()


## Called when a player cancels deck selection
func _on_deck_selection_canceled() -> void:
	print("Deck selection canceled - returning to main menu")
	
	# Fade out tavern music quickly when returning to main menu
	if AudioManager and AudioManager.has_method("fade_out_music"):
		AudioManager.fade_out_music(0.8)
		
	# Return to main menu or handle cancellation
	if card_selection_ui:
		card_selection_ui.hide_selection()
	# Use SceneManager for smooth transition
	if SceneManagerAutoload:
		SceneManagerAutoload.change_scene("start_menu")
	else:
		get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn")


## Finalize game start after both players selected decks.
## Board generation is DEFERRED to here so deck selection loads instantly.
func _finalize_game_start() -> void:
	is_selecting_decks = false
	decks_confirmed = true
	
	print("=== FINALIZE GAME START ===")
	
	# Hide deck selection immediately
	if card_selection_ui:
		card_selection_ui.hide_immediate()
	
	# Show the terrain loading screen, then start board + environment generation
	_show_terrain_loading_screen()
	
	if hex_board:
		_generate_board_concurrently()
	else:
		push_error("HexBoard node not found — cannot generate board!")


# =============================================================================
# TERRAIN GENERATION LOADING SCREEN
# =============================================================================

## Build and display the terrain loading screen
func _show_terrain_loading_screen() -> void:
	if terrain_loading_screen:
		return # Already showing
	
	terrain_loading_screen = CanvasLayer.new()
	terrain_loading_screen.name = "TerrainLoadingScreen"
	terrain_loading_screen.layer = 50 # Above card selection and game UI
	add_child(terrain_loading_screen)
	
	# Fullscreen root
	var root = Control.new()
	root.name = "LoadingRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP # Block all input
	terrain_loading_screen.add_child(root)
	
	# Dark background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 0.95) # Pure black loading background
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	
	# Center container
	var center = VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.custom_minimum_size = Vector2(800, 500)
	center.position = Vector2(-400, -250)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 24)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	
	# Logo (larger)
	var logo = TextureRect.new()
	logo.texture = UITheme.tex_logo()
	logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(720, 256)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(logo)
	
	# Separator
	center.add_child(UITheme.make_separator())
	
	# Title
	var title = Label.new()
	title.name = "LoadingTitle"
	title.text = "FORGING THE WORLD"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(title, 28, UITheme.C_GOLD, true)
	center.add_child(title)
	
	# Status label
	var status = Label.new()
	status.name = "LoadingStatus"
	status.text = "Generating terrain, biomes, and elevation..."
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(status, 16, UITheme.C_WARM_WHITE)
	center.add_child(status)
	
	# Progress indicator — pulsing gold bar
	var bar_container = CenterContainer.new()
	bar_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(bar_container)
	
	var bar_bg = PanelContainer.new()
	bar_bg.custom_minimum_size = Vector2(400, 8)
	var bar_style = StyleBoxFlat.new()
	bar_style.bg_color = Color(0.15, 0.13, 0.10, 0.80)
	bar_style.set_corner_radius_all(4)
	bar_bg.add_theme_stylebox_override("panel", bar_style)
	bar_container.add_child(bar_bg)
	
	var bar_fill = ColorRect.new()
	bar_fill.name = "LoadingBarFill"
	bar_fill.custom_minimum_size = Vector2(40, 6)
	bar_fill.color = UITheme.C_GOLD
	bar_bg.add_child(bar_fill)
	
	# Subtle tip text
	var tip = Label.new()
	tip.text = "397 hexagonal tiles  •  7 biomes  •  Procedural elevation"
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(tip, 12, UITheme.C_DIM)
	center.add_child(tip)
	
	# Fade in
	root.modulate.a = 0.0
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(root, "modulate:a", 1.0, 0.4)
	
	# Pulsing bar animation.
	# IMPORTANT: tween_property on layout properties (custom_minimum_size) with
	# set_loops() can trigger "Infinite loop detected" (tween.cpp:406) on freshly-
	# added nodes whose layout hasn't flushed yet.  Use tween_method instead.
	var bar_tw = bar_fill.create_tween()
	bar_tw.set_loops()
	bar_tw.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	bar_tw.tween_method(
		func(v: Vector2) -> void:
			if is_instance_valid(bar_fill):
				bar_fill.custom_minimum_size = v,
		Vector2(40.0, 6.0), Vector2(398.0, 6.0), 1.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bar_tw.tween_method(
		func(v: Vector2) -> void:
			if is_instance_valid(bar_fill):
				bar_fill.custom_minimum_size = v,
		Vector2(398.0, 6.0), Vector2(40.0, 6.0), 1.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	print("[TerrainLoadingScreen] Shown")


## Hide and free the terrain loading screen
func _hide_terrain_loading_screen() -> void:
	if not terrain_loading_screen:
		return
	
	var screen = terrain_loading_screen
	terrain_loading_screen = null
	
	# Find the root Control to animate fade-out
	var root = screen.get_node_or_null("LoadingRoot")
	if root:
		var tw = create_tween()
		tw.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(root, "modulate:a", 0.0, 0.35)
		tw.tween_callback(screen.queue_free)
	else:
		screen.queue_free()
	
	print("[TerrainLoadingScreen] Hidden")


## Proceed after board generation and deck selection are both done
func _proceed_to_first_move() -> void:
	_hide_terrain_loading_screen()
	print("Both players have selected decks and board is ready - showing first move roll...")
	
	# DEBUG: Check what CanvasLayers exist
	print("DEBUG: Checking all CanvasLayers...")
	for child in get_children():
		if child is CanvasLayer:
			print("  - CanvasLayer: %s, layer=%d, visible=%s" % [child.name, child.layer, child.visible])
	
	# Make sure card selection UI is fully hidden (immediate, no animation)
	print("DEBUG: Hiding card selection UI...")
	if card_selection_ui:
		card_selection_ui.hide_immediate()
		print("DEBUG: Card selection UI hidden. Visible=%s" % card_selection_ui.visible)
	else:
		print("DEBUG: card_selection_ui is NULL!")
	
	# Spawn troops based on selected decks (do this before the dice roll so they appear in background)
	print("DEBUG: Spawning troops...")
	_spawn_troops_from_decks()
	print("DEBUG: Troops spawned")
	
	# Roll for turn order (calculate the results)
	var roll_results = game_manager.player_manager.roll_for_turn_order()
	var p1_roll = roll_results.get(0, randi_range(1, 20))
	var p2_roll = roll_results.get(1, randi_range(1, 20))
	
	print("First move roll: Player 1 = %d, Player 2 = %d" % [p1_roll, p2_roll])
	
	# DEBUG: Use constant to skip the dice roll UI animation
	var skip_dice_roll_ui := DEBUG_SKIP_FIRST_MOVE_DICE
	
	# Show the first move dice roll UI  
	if first_move_dice_ui and not skip_dice_roll_ui:
		print("Showing first move dice UI...")
		first_move_dice_ui.show_roll(p1_roll, p2_roll)
	else:
		# Skip UI - proceed directly
		if skip_dice_roll_ui:
			print("DEBUG: Skipping first move dice UI")
		else:
			push_warning("FirstMoveDiceUI not available, starting game directly")
		print("DEBUG: Calling _on_first_move_roll_complete...")
		_on_first_move_roll_complete(game_manager.player_manager.active_player_index)


## Called when the first move dice roll animation completes
func _on_first_move_roll_complete(first_player_id: int) -> void:
	print("=== FIRST MOVE ROLL COMPLETE ===")
	print("First move decided: Player %d goes first!" % (first_player_id + 1))
	
	# Set the turn order based on roll result
	game_manager.player_manager.set_turn_order(first_player_id)
	
	# Now start the actual game
	print("DEBUG: Calling _start_game_after_roll...")
	_start_game_after_roll()


## Actually start the game after the first move roll is complete
func _start_game_after_roll() -> void:
	print("=== START GAME AFTER ROLL ===")
	
	# Show game UI
	if game_ui and game_ui.main_container:
		print("DEBUG: Showing game UI main_container")
		game_ui.main_container.visible = true
		print("DEBUG: game_ui.main_container.visible = %s" % game_ui.main_container.visible)
	else:
		print("ERROR: game_ui or main_container is NULL!")
	
	# Properly start the game (set phase to PLAYING and begin first turn)
	print("DEBUG: Setting game state to PLAYING...")
	game_manager.current_state = GameManager.GameState.PLAYING
	game_manager.turn_manager.current_phase = TurnManager.Phase.PLAYER_TURN
	game_manager.turn_manager._begin_new_turn()
	
	game_started = true
	print("DEBUG: Updating UI...")
	_update_ui()
	
	# DEBUG: Check all CanvasLayers again
	print("DEBUG: Final CanvasLayer check:")
	for child in get_children():
		if child is CanvasLayer:
			print("  - CanvasLayer: %s, layer=%d, visible=%s" % [child.name, child.layer, child.visible])
	
	# Set up initial camera view - behind the first player's troops looking at the board
	# Defer this to ensure all node transforms are updated
	print("DEBUG: Setting up initial camera view...")
	call_deferred("_setup_initial_camera_view")
	
	print("=== Game started! ===")
	print("Player 1 (Blue): %s" % str(player_decks[0]))
	print("Player 2 (Red): %s" % str(player_decks[1]))


## Spawn troops based on the selected decks
func _spawn_troops_from_decks() -> void:
	# Get spawn positions
	var p1_spawns = hex_board.get_player_spawn_positions(0)
	var p2_spawns = hex_board.get_player_spawn_positions(1)
	
	# Reverse Player 2's spawn positions so that from their perspective,
	# troop 1 is on their left and troop 4 is on their right
	p2_spawns.reverse()
	
	print("Player 1 spawn positions: %d" % p1_spawns.size())
	print("Player 2 spawn positions: %d" % p2_spawns.size())
	
	# Player 1 troops (Blue)
	var p1_deck = player_decks[0]
	for i in range(min(p1_deck.size(), p1_spawns.size())):
		var troop = _create_troop(p1_deck[i], 0, p1_spawns[i])
		if troop:
			troops.append(troop)
	
	# Player 2 troops (Red)
	var p2_deck = player_decks[1]
	for i in range(min(p2_deck.size(), p2_spawns.size())):
		var troop = _create_troop(p2_deck[i], 1, p2_spawns[i])
		if troop:
			troops.append(troop)
	
	print("Spawned %d troops total" % troops.size())


func _create_troop(troop_id: String, player_id: int, coord: HexCoordinates) -> Troop:
	var tile = hex_board.get_tile_at(coord)
	if not tile:
		push_error("No tile at spawn position!")
		return null
	
	var troop = Troop.new()
	# Ensure troops pause when the game is paused
	troop.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(troop)
	
	# Set team color before initialization
	if player_id == 0:
		troop.team_color = PLAYER1_COLOR
	else:
		troop.team_color = PLAYER2_COLOR
	
	# Initialize troop data
	troop.initialize(troop_id, player_id)
	
	# Move to hex and update visual
	troop.move_to_hex(tile)
	
	# Rotate troops to face toward the opponent's side of the board.
	# Player 2 is turned 150° CW from default, Player 1 mirrors that + 180° flip.
	if player_id == 0:
		troop.rotation_degrees.y = 210.0 # Faces toward Player 2
	else:
		troop.rotation_degrees.y = 30.0 # Faces toward Player 1
	
	# IMPORTANT: Reset move/attack flags since this is initial spawn, not a move action
	troop.has_moved_this_turn = false
	troop.has_attacked_this_turn = false
	
	# Add to GameManager's player
	var player = game_manager.player_manager.get_player(player_id)
	if player:
		player.add_troop(troop)
	
	print("Spawned %s for Player %d at %s" % [troop.display_name, player_id + 1, coord._to_string()])
	return troop


# =============================================================================
# UI UPDATE
# =============================================================================

func _update_ui() -> void:
	if not game_ui or not game_manager:
		return
	
	# Update turn info
	var turn_mgr = game_manager.turn_manager
	var player_mgr = game_manager.player_manager
	if turn_mgr and player_mgr:
		game_ui.update_turn(player_mgr.turn_number, turn_mgr.get_active_player_id())
		game_ui.update_timer(turn_mgr.turn_timer_remaining)
	
	# Update player resources
	for i in range(2):
		var player = game_manager.player_manager.get_player(i)
		if player:
			game_ui.update_player_resources(i, player.gold, player.xp)
	
	# Update action buttons based on selected troop
	if selected_troop:
		var can_move = ("has_moved_this_turn" in selected_troop) and not selected_troop.has_moved_this_turn
		var can_attack = ("has_attacked_this_turn" in selected_troop) and not selected_troop.has_attacked_this_turn
		var can_mine = game_manager.player_manager.get_player(selected_troop.owner_player_id).gold >= 100 if selected_troop is Troop else false
		var can_upgrade = selected_troop.level < 5 if "level" in selected_troop else false
		game_ui.update_action_buttons(can_move, can_attack, can_mine, can_upgrade)
		game_ui.show_selected_troop(selected_troop)
	else:
		game_ui.update_action_buttons(false, false, false, false)
		game_ui.hide_selected_troop()
	
	# Update troop cards for active player
	if game_manager.turn_manager:
		var current_player_id = game_manager.turn_manager.get_active_player_id()
		var current_player = game_manager.player_manager.get_player(current_player_id)
		if current_player:
			# Debug: Check deck and troops
			if Engine.get_frames_drawn() % 300 == 0: # Print every ~5 seconds at 60fps
				print("DEBUG - Player %d deck: %s" % [current_player_id, str(current_player.deck)])
				print("DEBUG - Player %d troops: %d" % [current_player_id, current_player.troops.size()])
			game_ui.update_troop_cards(current_player, selected_troop)


# =============================================================================
# CAMERA SYSTEM (3D Editor Style)
# =============================================================================

func _update_camera_transform() -> void:
	if not camera or not camera_pivot or not camera_body:
		return
	
	# Clamp pitch - allowed to look straight down (90)
	camera_pitch = clamp(camera_pitch, 10.0, 90.0)
	
	# Position pivot at focus point (for reference)
	camera_pivot.global_position = focus_point
	
	var pitch_rad = deg_to_rad(camera_pitch)
	var yaw_rad = deg_to_rad(camera_yaw)
	
	# Direction unit vector from focus point toward camera
	var dir = Vector3(
		cos(pitch_rad) * sin(yaw_rad),
		sin(pitch_rad),
		cos(pitch_rad) * cos(yaw_rad)
	)
	
	# Desired camera world position (from orbit math)
	var desired_pos = focus_point + dir * camera_distance
	
	# --- Simple Camera Positioning (Collision Disabled) ---
	camera_body.global_position = desired_pos
	_camera_body_initialized = true
	
	# Camera renders from the physics body's final position
	camera.global_position = camera_body.global_position
	
	# Handle straight-down view (pitch = 90) by using an UP vector derived from yaw.
	# This keeps the orientation consistent with the regular orbital view.
	var up_vec = Vector3.UP
	if camera_pitch > 89.5:
		up_vec = Vector3(-sin(yaw_rad), 0, -cos(yaw_rad))
		
	camera.look_at(focus_point, up_vec)


func _zoom_camera(direction: float) -> void:
	target_distance += direction * target_distance * ZOOM_SPEED
	target_distance = clamp(target_distance, ZOOM_MIN, ZOOM_MAX)


func _rotate_camera_view(delta_x: float, delta_y: float) -> void:
	camera_yaw += delta_x * ROTATE_SPEED
	camera_pitch += delta_y * ROTATE_SPEED
	_update_camera_transform()


func _pan_camera(direction: Vector3, delta: float) -> void:
	if not camera:
		return
	
	# Get camera's right and forward vectors (projected to horizontal plane)
	var cam_transform = camera.global_transform
	var right = cam_transform.basis.x
	right.y = 0
	right = right.normalized()
	
	var forward = - cam_transform.basis.z
	forward.y = 0
	
	# Fallback for straight-down view (where forward.y = 0 makes it zero)
	if forward.length() < 0.001:
		forward = - cam_transform.basis.y
		forward.y = 0
		
	forward = forward.normalized()
	
	# Calculate movement relative to camera facing
	var movement = Vector3.ZERO
	movement += forward * direction.z # W/S
	movement += right * direction.x # A/D
	movement.y = direction.y # Q/E
	
	# Apply speed modifier if Shift is held
	var speed = PAN_SPEED_SHIFT if Input.is_key_pressed(KEY_SHIFT) else PAN_SPEED
	focus_point += movement * speed * delta
	
	# Prevent focus point from going below the board level
	# Board is at Y=0, so keep focus point at least 0.5 units above it
	const MIN_FOCUS_HEIGHT = 0.5
	focus_point.y = max(focus_point.y, MIN_FOCUS_HEIGHT)
	
	_update_camera_transform()


# =============================================================================
# INPUT HANDLING
# =============================================================================

func _process(delta: float) -> void:
	if is_paused:
		return
		
	_handle_keyboard_movement(delta)
	
	if not ignore_camera_process:
		if not is_camera_transitioning and abs(camera_distance - target_distance) > 0.001:
			camera_distance = lerp(camera_distance, target_distance, 15.0 * delta)
			_update_camera_transform()
			
		_update_camera_smooth(delta)
	else:
		# Exclusively controlled by UI tweens
		_update_camera_transform()
	
	# Camera collision is handled inside _update_camera_transform() via
	# CharacterBody3D.move_and_collide() — no separate step needed.
	
	# Update timer display periodically instead of every frame
	_last_timer_update += delta
	if _last_timer_update >= TIMER_UPDATE_INTERVAL:
		_last_timer_update = 0.0
		if game_ui and game_manager and game_manager.turn_manager:
			game_ui.update_timer(game_manager.turn_manager.turn_timer_remaining)
	
	# Update dynamic biome lighting
	_update_biome_lighting(delta)


func _update_biome_lighting(delta: float) -> void:
	if not board_world_env or not hex_board or not board_generation_complete:
		return
	
	if not camera:
		camera = get_viewport().get_camera_3d()
	if not camera:
		return
	
	_last_biome_detection_time += delta
	if _last_biome_detection_time < BIOME_DETECTION_INTERVAL:
		return
	
	_last_biome_detection_time = 0.0
	var camera_pos = camera.global_position
	var dominant_biome = _get_dominant_biome_near_position(camera_pos)
	
	if dominant_biome != _current_biome_environment:
		_current_biome_environment = dominant_biome
		_apply_biome_environment(dominant_biome, delta)


func _get_dominant_biome_near_position(world_pos: Vector3) -> Biomes.Type:
	if not hex_board:
		return Biomes.Type.PLAINS
	
	var biome_counts = {}
	var search_radius = BIOME_DETECTION_RADIUS
	
	var all_tiles = hex_board.get_all_tiles()
	for i in range(all_tiles.size()):
		var tile = all_tiles[i]
		var tile_pos = tile.global_position
		var dist = world_pos.distance_to(tile_pos)
		if dist <= search_radius:
			var biome = tile.biome_type
			if not biome_counts.has(biome):
				biome_counts[biome] = 0
			biome_counts[biome] = biome_counts[biome] + 1
	
	if biome_counts.is_empty():
		return Biomes.Type.PLAINS
	
	var max_count = 0
	var dominant = Biomes.Type.PLAINS
	var biome_keys = biome_counts.keys()
	for i in range(biome_keys.size()):
		var biome = biome_keys[i]
		var count = biome_counts[biome]
		if count > max_count:
			max_count = count
			dominant = biome
	
	return dominant


func _apply_biome_environment(biome: Biomes.Type, delta: float) -> void:
	if not board_world_env:
		return
	
	var current_env = board_world_env.environment
	if not current_env:
		return
	
	var target_env = LightingManager.create_environment_for_biome(biome)
	if not target_env:
		return
	
	var t = delta * BIOME_ENVIRONMENT_TRANSITION_SPEED
	
	current_env.ambient_light_energy = lerp(current_env.ambient_light_energy, target_env.ambient_light_energy, t)
	current_env.ambient_light_color = current_env.ambient_light_color.lerp(target_env.ambient_light_color, t)
	current_env.fog_density = lerp(current_env.fog_density, target_env.fog_density, t)
	current_env.fog_light_color = current_env.fog_light_color.lerp(target_env.fog_light_color, t)
	current_env.adjustment_saturation = lerp(current_env.adjustment_saturation, target_env.adjustment_saturation, t)
	current_env.ssao_intensity = lerp(current_env.ssao_intensity, target_env.ssao_intensity, t)
	current_env.glow_intensity = lerp(current_env.glow_intensity, target_env.glow_intensity, t)


func _handle_keyboard_movement(delta: float) -> void:
	# No camera panning during dice-roll cinematics
	if dice_roll_active: return

	var direction = Vector3.ZERO
	
	# WASD for panning (relative to camera facing)
	if Input.is_key_pressed(KEY_W):
		direction.z += 1
	if Input.is_key_pressed(KEY_S):
		direction.z -= 1
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_key_pressed(KEY_D):
		direction.x += 1
	
	# Q/E for up/down
	if Input.is_key_pressed(KEY_Q):
		direction.y -= 1
	if Input.is_key_pressed(KEY_E):
		direction.y += 1
	
	if direction != Vector3.ZERO:
		_pan_camera(direction.normalized(), delta)
		is_camera_transitioning = false # User manual control overrides transitions


func _input(event: InputEvent) -> void:
	# Mouse button events — blocked during dice roll
	if event is InputEventMouseButton:
		if not dice_roll_active:
			_handle_mouse_button(event)

	# Mouse motion events — blocked during dice roll
	if event is InputEventMouseMotion:
		if not dice_roll_active:
			_handle_mouse_motion(event)

	# Keyboard events
	if event is InputEventKey and event.pressed:
		# Always allow ESC (pause menu, mouse release)
		if event.keycode == KEY_ESCAPE:
			_handle_key_press(event)
			return
		# During dice roll, block everything else
		if dice_roll_active:
			return
		# Normal gameplay key handling
		if is_paused:
			return
		_handle_key_press(event)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	match event.button_index:
		MOUSE_BUTTON_RIGHT:
			# Right-click to rotate view
			is_rotating = event.pressed
			if is_rotating:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		MOUSE_BUTTON_MIDDLE:
			# Middle-click to pan
			is_panning_mouse = event.pressed
			if is_panning_mouse:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(-1)
		
		MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(1)


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if is_rotating:
		# Rotate camera with right-click drag (Y inverted)
		_rotate_camera_view(-event.relative.x, event.relative.y)
		is_camera_transitioning = false # User manual control overrides transitions
	
	elif is_panning_mouse:
		# Pan with middle-click drag
		var pan_sensitivity = 0.02 * (camera_distance / 10.0)
		var right = camera.global_transform.basis.x
		var up = camera.global_transform.basis.y
		
		focus_point -= right * event.relative.x * pan_sensitivity
		focus_point += up * event.relative.y * pan_sensitivity
		
		# Prevent focus point from going below the board level
		const MIN_FOCUS_HEIGHT = 0.5
		focus_point.y = max(focus_point.y, MIN_FOCUS_HEIGHT)
		
		_update_camera_transform()


func _handle_key_press(event: InputEventKey) -> void:
	# Handle escape key regardless of deck selection state
	if event.keycode == KEY_ESCAPE:
		# Release mouse if captured, otherwise cancel action mode
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			is_rotating = false
			is_panning_mouse = false
		elif action_mode != "none":
			_cancel_action_mode()
		elif not is_selecting_decks:
			_toggle_pause_menu()
		return
	
	# Block gameplay inputs during deck selection
	if is_selecting_decks:
		return
	
	match event.keycode:
		KEY_F:
			# Focus on selected tile
			_focus_on_selection()
		
		KEY_HOME:
			# Reset camera to default
			_reset_camera()
		
		KEY_1:
			_select_troop_by_slot_for_current_player(0)
		KEY_2:
			_select_troop_by_slot_for_current_player(1)
		KEY_3:
			_select_troop_by_slot_for_current_player(2)
		KEY_4:
			_select_troop_by_slot_for_current_player(3)
		
		KEY_SPACE:
			_on_action_end_turn()
		
		KEY_M:
			_on_action_move()
		
		KEY_T:
			_on_action_attack()
		
		KEY_V:
			# Cycle camera views
			_cycle_camera_view()
		
		KEY_F1:
			# Toggle keyboard shortcuts overlay
			if game_ui:
				game_ui.toggle_keyboard_overlay()


## Selects troop based on slot number (1-4 keys select troops 1-4)
func _select_troop_by_slot_for_current_player(slot: int) -> void:
	if not game_manager or not game_manager.turn_manager:
		return
	
	# Simply select the troop at the given slot (no inversion)
	_select_troop_by_slot(slot)


func _select_troop_by_slot(slot: int) -> void:
	if not game_manager or not game_manager.turn_manager:
		return
	
	# Block troop selection during combat
	if game_manager.current_state == GameManager.GameState.ENHANCED_COMBAT:
		return
	
	var current_player_id = game_manager.turn_manager.get_active_player_id()
	var player = game_manager.player_manager.get_player(current_player_id)
	
	if not player:
		return
	
	# Find troop by deck slot (same as UI card order)
	if slot < player.deck.size():
		var entity_id = player.deck[slot]
		var entity = null
		
		# Check if it's a mine
		if entity_id.begins_with("mine_"):
			for mine in player.gold_mines:
				if mine and mine.card_id == entity_id:
					entity = mine
					break
		else:
			entity = _find_troop_by_id_for_player(player, entity_id)
		
		var is_selectable = false
		if entity:
			if entity is Troop and entity.is_alive:
				is_selectable = true
			elif "is_active" in entity and entity.is_active:
				is_selectable = true
		
		if is_selectable:
			# Cancel any active action mode when selecting a new troop
			_cancel_action_mode()
			
			if selected_troop == entity:
				selected_troop = null
				print("Deselected Slot %d" % (slot + 1))
			else:
				selected_troop = entity
				var display_name = entity.display_name if "display_name" in entity else "Gold Mine"
				print("Selected %s (Slot %d)" % [display_name, slot + 1])
				
				# Smart camera focus on troop for tactical view
				_focus_on_troop_tactical(selected_troop)
				
				# Audio feedback (only play if it's a new selection)
				if AudioManager and AudioManager.has_method("play_card_pick"):
					AudioManager.play_card_pick()
			
			_update_ui()


## Find a troop by its ID for a given player
func _find_troop_by_id_for_player(player: Player, troop_id: String) -> Troop:
	for troop in player.troops:
		if troop and troop.troop_id == troop_id:
			return troop
	return null


## Handler for troop card button clicks from the UI
func _on_troop_slot_selected(slot_index: int) -> void:
	# Apply same inversion logic as keyboard selection
	_select_troop_by_slot_for_current_player(slot_index)


func _focus_on_selection() -> void:
	if selected_troop and selected_troop.current_hex:
		# Use tactical camera focus for best move/attack view
		_focus_on_troop_tactical(selected_troop)
		var display_name = selected_troop.display_name if "display_name" in selected_troop else "Gold Mine"
		print("Camera focused on %s (tactical view)" % display_name)
	elif hex_board and hex_board.selected_tile:
		target_focus_point = hex_board.selected_tile.global_position
		target_distance = 15.0
		target_pitch = 45.0
		is_camera_transitioning = true
		print("Camera focused on selected tile")
	else:
		print("No tile or troop selected - click a tile first, then press F")


func _reset_camera() -> void:
	_set_camera_view(CameraView.OVERVIEW, false)
	print("Camera reset to Overview")


## Set up the initial camera view - behind the current player's troops
func _setup_initial_camera_view() -> void:
	var current_player_id = 0
	if game_manager and game_manager.turn_manager:
		current_player_id = game_manager.turn_manager.get_active_player_id()
	
	# Calculate the center point of player's troops
	var player_center = _get_player_troops_center(current_player_id)
	var opponent_center = _get_player_troops_center(1 - current_player_id)
	
	print("DEBUG Camera: Player %d center = %s, Opponent center = %s" % [current_player_id, player_center, opponent_center])
	
	# If we have both positions, calculate proper camera angle
	if player_center != Vector3.ZERO and opponent_center != Vector3.ZERO:
		# Direction from player to opponent (where we want to LOOK)
		var to_opponent = (opponent_center - player_center).normalized()
		
		# Focus point: slightly ahead of player troops towards center
		focus_point = player_center.lerp(opponent_center, 0.25)
		
		# Camera yaw: we want camera BEHIND player, so opposite of to_opponent direction
		# atan2(x, z) gives angle where:
		#   0° = looking at +Z
		#   90° = looking at +X
		#   -90° = looking at -X
		# We want camera BEHIND player, so it should be on the opposite side of to_opponent
		var camera_dir = - to_opponent # Opposite direction
		camera_yaw = rad_to_deg(atan2(camera_dir.x, camera_dir.z))
		
		print("DEBUG Camera: to_opponent = %s, camera_yaw = %f" % [to_opponent, camera_yaw])
	elif player_center != Vector3.ZERO:
		# Only player troops exist, point towards center
		focus_point = player_center.lerp(Vector3.ZERO, 0.3)
		var to_center = (Vector3.ZERO - player_center).normalized()
		var camera_dir = - to_center
		camera_yaw = rad_to_deg(atan2(camera_dir.x, camera_dir.z))
	else:
		# Fallback to default overview
		focus_point = Vector3.ZERO
		camera_yaw = 0.0
	
	print("DEBUG Camera: Focus point = %s" % focus_point)
	
	camera_pitch = 20.0 # Standard tactical angle, adjusted to 20 per request
	camera_distance = 32.0 # Pull back to see board and troops
	target_distance = 32.0
	current_view = CameraView.OVERVIEW
	
	print("DEBUG Camera: yaw=%f, pitch=%f, distance=%f" % [camera_yaw, camera_pitch, camera_distance])
	
	_update_camera_transform()
	print("Initial camera view set - Behind Player %d's troops" % (current_player_id + 1))


## Get the center position of a player's troops
func _get_player_troops_center(player_id: int) -> Vector3:
	var center = Vector3.ZERO
	var count = 0
	
	for troop in troops:
		if troop and troop.owner_player_id == player_id and troop.current_hex:
			center += troop.current_hex.global_position
			count += 1
	
	if count > 0:
		return center / count
	return Vector3.ZERO


## Cycle to the next camera view (V key)
func _cycle_camera_view() -> void:
	var next_view = (current_view + 1) % CameraView.size()
	
	# Skip FRONT_QUARTER if no troop or mine is selected
	if next_view == CameraView.FRONT_QUARTER and (not selected_troop or (not (selected_troop is Troop) and not (selected_troop is GoldMine))):
		next_view = (next_view + 1) % CameraView.size()
		
	_set_camera_view(next_view, true)


## Set a specific camera view with optional smooth transition
func _set_camera_view(view: CameraView, smooth: bool = true) -> void:
	current_view = view
	
	var preset_name = CameraView.keys()[view]
	var preset = VIEW_PRESETS.get(preset_name, VIEW_PRESETS["OVERVIEW"])
	
	# Get current player for yaw calculation
	var current_player_id = 0
	if game_manager and game_manager.turn_manager:
		current_player_id = game_manager.turn_manager.get_active_player_id()
	
	# Calculate target distance based on preset and entity size
	target_distance = preset["distance"]
	
	# Apply dynamic zoom based on entity height for focused views
	var focused_entity = selected_troop
	if focused_entity and (view == CameraView.TROOP_FOCUS or view == CameraView.FRONT_QUARTER or view == CameraView.CINEMATIC):
		var entity_height = 1.0
		if focused_entity is Troop:
			if focused_entity.character_model_node:
				# Use the actual model scale height
				entity_height = focused_entity.character_model_node.scale.y
		elif focused_entity is GoldMine:
			entity_height = 1.5 # Standard height for mines
			
		# Calibrate distance based on view type
		match view:
			CameraView.TROOP_FOCUS:
				# Original was 8.0 for ~1.8-2.0m height => multiplier ≈ 4.0
				target_distance = entity_height * 4.5
			CameraView.FRONT_QUARTER:
				# Tight framing (FOV 60)
				target_distance = entity_height * 1.5
			CameraView.CINEMATIC:
				# Original 12.0 for ~2.0m height => multiplier ≈ 6.0
				target_distance = entity_height * 7.0
	
	target_pitch = preset["pitch"]
	
	# Yaw: position camera behind current player's side
	# Player 0 at -X needs yaw = -90, Player 1 at +X needs yaw = 90
	var base_yaw = -90.0 if current_player_id == 0 else 90.0
	
	var yaw_offset = preset["yaw_offset"]
	# Flip camera for mines in Front Quarter view as requested
	if view == CameraView.FRONT_QUARTER and focused_entity is GoldMine:
		yaw_offset += 180.0
		
	target_yaw = base_yaw + yaw_offset
	
	# Focus point depends on view type
	match view:
		CameraView.OVERVIEW:
			target_focus_point = Vector3.ZERO
		CameraView.TACTICAL:
			if selected_troop and selected_troop.current_hex:
				target_focus_point = selected_troop.current_hex.global_position
			else:
				target_focus_point = _get_player_troops_center(current_player_id)
		CameraView.TROOP_FOCUS:
			if selected_troop and selected_troop.current_hex:
				target_focus_point = selected_troop.current_hex.global_position
			else:
				target_focus_point = _get_player_troops_center(current_player_id)
		CameraView.FRONT_QUARTER:
			if selected_troop and (selected_troop is Troop or selected_troop is GoldMine):
				var entity_height = 1.0
				if selected_troop is Troop:
					if selected_troop.character_model_node:
						entity_height = selected_troop.character_model_node.scale.y
				elif selected_troop is GoldMine:
					entity_height = 1.5
				# Focus on the vertical center of the entity
				target_focus_point = selected_troop.global_position + Vector3(0, entity_height * 0.5, 0)
			else:
				target_focus_point = _get_player_troops_center(current_player_id)
		CameraView.TOP_DOWN:
			target_focus_point = Vector3.ZERO
		CameraView.CINEMATIC:
			if selected_troop and selected_troop.current_hex:
				target_focus_point = selected_troop.current_hex.global_position
			else:
				target_focus_point = Vector3.ZERO
	
	if smooth:
		is_camera_transitioning = true
	else:
		# Instant transition
		focus_point = target_focus_point
		camera_distance = target_distance
		camera_yaw = target_yaw
		camera_pitch = target_pitch
		_update_camera_transform()
	
	if game_ui:
		game_ui.show_info("Camera: %s" % VIEW_NAMES[view])
		# Hide info after 1.5 seconds
		get_tree().create_timer(1.5).timeout.connect(func():
			if game_ui and action_mode == "none":
				game_ui.hide_info()
		)
	
	print("Camera view: %s" % VIEW_NAMES[view])


## ==========================================================================
## COMBAT CAMERA
## ==========================================================================

## Transition camera to a front-quarter combat view, framing both combatants.
## Inspired by Mortal Kombat / fighting-game perspective.
func _enter_combat_camera(attacker: Node, defender: Node) -> void:
	if _in_combat_camera:
		return
	
	# Save current camera state so we can restore after combat
	_pre_combat_focus = focus_point
	_pre_combat_distance = camera_distance
	_pre_combat_yaw = camera_yaw
	_pre_combat_pitch = camera_pitch
	_pre_combat_view = current_view
	_in_combat_camera = true
	
	# Get world positions of both combatants
	var att_pos: Vector3 = attacker.global_position if attacker else Vector3.ZERO
	var def_pos: Vector3 = defender.global_position if defender else Vector3.ZERO
	
	# Focus point: midpoint between attacker and defender
	var midpoint = (att_pos + def_pos) * 0.5
	
	# Direction from attacker to defender (the combat axis)
	var combat_axis = (def_pos - att_pos)
	combat_axis.y = 0.0 # Project onto horizontal plane
	if combat_axis.length() < 0.001:
		combat_axis = Vector3.FORWARD
	combat_axis = combat_axis.normalized()
	
	# Camera goes to the SIDE of the combat axis (front-quarter angle)
	# Rotate the combat axis 55° to get a dramatic side view
	var side_offset = 55.0 # degrees from combat axis
	var yaw_rad = atan2(combat_axis.x, combat_axis.z) + deg_to_rad(side_offset)
	var combat_yaw = rad_to_deg(yaw_rad)
	
	# Calculate appropriate distance based on combatant separation
	var separation = att_pos.distance_to(def_pos)
	var combat_distance = clampf(separation * 0.9 + 4.0, 6.0, 14.0)
	
	# Set targets for smooth transition
	target_focus_point = midpoint + Vector3(0, 0.5, 0) # Slightly above ground
	target_distance = combat_distance
	target_yaw = combat_yaw
	target_pitch = 22.0 # Low angle for dramatic ground-level framing
	
	# Initiate smooth transition
	start_focus_point = focus_point
	start_distance = camera_distance
	start_yaw = camera_yaw
	start_pitch = camera_pitch
	transition_progress = 0.0
	is_camera_transitioning = true
	
	print("[CombatCamera] Entering combat view — att=%s, def=%s, yaw=%.1f, dist=%.1f" % [
		attacker.display_name, defender.display_name, combat_yaw, combat_distance])


## Restore camera to the view it had before combat started
func _exit_combat_camera() -> void:
	if not _in_combat_camera:
		return
	_in_combat_camera = false
	
	# Restore saved state via smooth transition
	target_focus_point = _pre_combat_focus
	target_distance = _pre_combat_distance
	target_yaw = _pre_combat_yaw
	target_pitch = _pre_combat_pitch
	current_view = _pre_combat_view
	
	start_focus_point = focus_point
	start_distance = camera_distance
	start_yaw = camera_yaw
	start_pitch = camera_pitch
	transition_progress = 0.0
	is_camera_transitioning = true
	
	print("[CombatCamera] Restoring pre-combat view")


## Smart camera positioning when selecting a troop
## Positions camera behind the troop, facing towards the enemy side
func _focus_on_troop_tactical(troop: Node) -> void:
	if not troop or not troop.current_hex:
		return
	
	var troop_player_id = troop.owner_player_id
	var troop_pos = troop.current_hex.global_position
	
	# Get enemy troops center to determine facing direction
	var enemy_center = _get_player_troops_center(1 - troop_player_id)
	if enemy_center == Vector3.ZERO:
		# Fallback: enemy is on opposite side of board
		enemy_center = Vector3(20.0 if troop_player_id == 0 else -20.0, 0, 0)
	
	# Direction from troop to enemy (this is where we want to LOOK)
	var to_enemy = (enemy_center - troop_pos).normalized()
	
	# Camera yaw: we want camera BEHIND troop, so opposite of to_enemy direction
	# atan2(x, z) gives angle where 0 = looking at +Z, 90 = looking at +X
	# We want camera at opposite side, so we use -to_enemy
	var camera_dir = - to_enemy
	target_yaw = rad_to_deg(atan2(camera_dir.x, camera_dir.z))
	
	# Set tactical view parameters
	target_focus_point = troop_pos
	target_distance = 15.0 # Close enough to see the troop and surrounding tiles
	target_pitch = 40.0 # Good angle to see movement/attack options
	
	is_camera_transitioning = true


## Update camera with smooth transitions
func _update_camera_smooth(delta: float) -> void:
	if not is_camera_transitioning:
		return
	
	# Use progress-based transition for smoother animation
	if is_player_switch_transition:
		_update_cinematic_transition(delta)
	else:
		_update_normal_transition(delta)


# Camera collision is now handled by CharacterBody3D.move_and_collide()
# inside _update_camera_transform(). No separate collision step needed.


## Smooth easing function (ease in-out cubic)
func _ease_in_out_cubic(t: float) -> float:
	if t < 0.5:
		return 4.0 * t * t * t
	else:
		return 1.0 - pow(-2.0 * t + 2.0, 3.0) / 2.0


## Smooth easing function (ease out cubic) - for quicker start, gentle end
func _ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)


## Cinematic player switch transition with arc movement
func _update_cinematic_transition(delta: float) -> void:
	transition_progress += delta / transition_duration
	transition_progress = clamp(transition_progress, 0.0, 1.0)
	
	# Use smooth easing curve
	var t = _ease_in_out_cubic(transition_progress)
	
	# Interpolate all camera values with eased progress
	focus_point = start_focus_point.lerp(target_focus_point, t)
	camera_distance = lerp(start_distance, target_distance, t)
	camera_pitch = lerp(start_pitch, target_pitch, t)
	
	# Add a cinematic arc - camera rises up in the middle of transition
	var arc_height = sin(t * PI) * 8.0 # Rise up to 8 units at midpoint
	focus_point.y += arc_height * 0.3 # Slight focus lift
	camera_distance += arc_height * 0.5 # Pull back slightly during arc
	
	# Handle yaw with proper wrapping
	var yaw_diff = target_yaw - start_yaw
	while yaw_diff > 180:
		yaw_diff -= 360
	while yaw_diff < -180:
		yaw_diff += 360
	camera_yaw = start_yaw + yaw_diff * t
	
	_update_camera_transform()
	
	# Check if complete
	if transition_progress >= 1.0:
		is_camera_transitioning = false
		is_player_switch_transition = false
		transition_progress = 0.0
		# Snap to exact final values
		focus_point = target_focus_point
		camera_distance = target_distance
		camera_pitch = target_pitch
		camera_yaw = target_yaw
		_update_camera_transform()


## Normal smooth transition (for troop selection, etc)
func _update_normal_transition(delta: float) -> void:
	var speed = CAMERA_TRANSITION_SPEED * delta
	var arrived = true
	
	# Use slightly eased interpolation
	var focus_speed = speed * 4.0
	var dist_speed = speed * 5.0
	var angle_speed = speed * 6.0
	
	# Smoothly interpolate all camera values
	focus_point = focus_point.lerp(target_focus_point, focus_speed)
	if focus_point.distance_to(target_focus_point) > 0.05:
		arrived = false
	
	camera_distance = lerp(camera_distance, target_distance, dist_speed)
	if abs(camera_distance - target_distance) > 0.05:
		arrived = false
	
	camera_pitch = lerp(camera_pitch, target_pitch, angle_speed)
	if abs(camera_pitch - target_pitch) > 0.3:
		arrived = false
	
	# Handle yaw wrapping for smooth rotation
	var yaw_diff = target_yaw - camera_yaw
	while yaw_diff > 180:
		yaw_diff -= 360
	while yaw_diff < -180:
		yaw_diff += 360
	camera_yaw += yaw_diff * angle_speed
	if abs(yaw_diff) > 0.5:
		arrived = false
	
	_update_camera_transform()
	
	if arrived:
		is_camera_transitioning = false
		# Snap to exact values
		focus_point = target_focus_point
		camera_distance = target_distance
		camera_pitch = target_pitch
		camera_yaw = target_yaw
		_update_camera_transform()


func _toggle_pause_menu() -> void:
	if pause_menu:
		_close_pause_menu()
	else:
		_open_pause_menu()


func _open_pause_menu() -> void:
	is_paused = true
	get_tree().paused = true
	
	# Explicitly pause logic systems
	if game_manager:
		game_manager.pause_game()

	pause_menu = CanvasLayer.new()
	pause_menu.layer = 100
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_menu)

	# Dark overlay
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = UITheme.C_OVERLAY_DIM
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.add_child(overlay)

	# Menu panel
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(380, 420)
	panel.position = Vector2(-190, -210)
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	panel.add_theme_stylebox_override("panel", UITheme.overlay_panel(UITheme.C_GOLD))
	pause_menu.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(title, 32, UITheme.C_GOLD, true)
	vbox.add_child(title)

	vbox.add_child(UITheme.make_separator())

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(spacer)

	# Resume Button
	var resume_btn = _create_pause_button("RESUME")
	resume_btn.add_theme_color_override("font_color", UITheme.C_GOLD_BRIGHT)
	resume_btn.pressed.connect(_close_pause_menu)
	vbox.add_child(resume_btn)

	# Settings Button
	var settings_btn = _create_pause_button("SETTINGS")
	settings_btn.pressed.connect(_open_settings_from_pause)
	vbox.add_child(settings_btn)

	# Main Menu Button
	var menu_btn = _create_pause_button("MAIN MENU")
	menu_btn.pressed.connect(_confirm_return_to_main_menu)
	vbox.add_child(menu_btn)

	# Quit Button
	var quit_btn = _create_pause_button("QUIT GAME")
	quit_btn.pressed.connect(_confirm_quit_game)
	vbox.add_child(quit_btn)

	print("Game paused")


func _create_pause_button(text: String) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(UITheme.BTN_W, UITheme.BTN_H)
	button.pivot_offset = Vector2(UITheme.BTN_W * 0.5, UITheme.BTN_H * 0.5)
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	UITheme.apply_menu_button(button, UITheme.BTN_FONT_SIZE)
	return button


func _close_pause_menu() -> void:
	if pause_menu:
		pause_menu.queue_free()
		pause_menu = null
	is_paused = false
	get_tree().paused = false
	
	# Explicitly resume logic systems
	if game_manager:
		game_manager.resume_game()
	
	print("Game resumed")


func _open_settings_from_pause() -> void:
	# Hide the pause menu while settings is open
	if pause_menu:
		pause_menu.visible = false
	
	var settings_menu = SettingsMenuScene.new()
	settings_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	# Add to scene root, not pause_menu, to avoid z-ordering issues
	add_child(settings_menu)
	
	# When settings closes, show pause menu again
	settings_menu.closed.connect(_on_settings_closed)


func _on_settings_closed() -> void:
	# Show pause menu again after settings is closed
	if pause_menu:
		pause_menu.visible = true


func _return_to_main_menu() -> void:
	_close_pause_menu()
	
	# Fade out tavern music quickly when returning to main menu
	if AudioManager and AudioManager.has_method("fade_out_music"):
		AudioManager.fade_out_music(0.8)
		
	# Use SceneManager for smooth transition
	if SceneManagerAutoload:
		SceneManagerAutoload.change_scene("start_menu")
	else:
		get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn")

func _confirm_return_to_main_menu() -> void:
	_show_confirmation_dialog("MAIN MENU", "Are you sure you want to return to the main menu? Any unsaved progress will be lost.", _return_to_main_menu)

func _confirm_quit_game() -> void:
	_show_confirmation_dialog("QUIT GAME", "Are you sure you want to exit Fantasy World? Any unsaved progress will be lost.", func(): get_tree().quit())

func _show_confirmation_dialog(title_text: String, message_text: String, on_confirm: Callable) -> void:
	var confirm_layer = CanvasLayer.new()
	confirm_layer.layer = 150
	confirm_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(confirm_layer)
	
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = UITheme.C_OVERLAY_DIM
	confirm_layer.add_child(bg)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	confirm_layer.add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 240)
	panel.add_theme_stylebox_override("panel", UITheme.overlay_panel(UITheme.C_GOLD))
	center.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(title, 24, UITheme.C_GOLD, true)
	vbox.add_child(title)
	
	var msg = Label.new()
	msg.text = message_text
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.style_label(msg, 16, UITheme.C_WARM_WHITE)
	vbox.add_child(msg)
	
	var btn_row = HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 24)
	vbox.add_child(btn_row)
	
	var yes_btn = Button.new()
	yes_btn.text = "YES"
	yes_btn.custom_minimum_size = Vector2(160, 50)
	yes_btn.pivot_offset = Vector2(80, 25)
	yes_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	UITheme.apply_menu_button(yes_btn, 18)
	yes_btn.pressed.connect(func():
		confirm_layer.queue_free()
		on_confirm.call()
	)
	btn_row.add_child(yes_btn)
	
	var no_btn = Button.new()
	no_btn.text = "NO"
	no_btn.custom_minimum_size = Vector2(160, 50)
	no_btn.pivot_offset = Vector2(80, 25)
	no_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	UITheme.apply_menu_button(no_btn, 18)
	no_btn.pressed.connect(func():
		confirm_layer.queue_free()
	)
	btn_row.add_child(no_btn)
	
	# Transition
	panel.modulate.a = 0.0
	var tw = confirm_layer.create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(panel, "modulate:a", 1.0, 0.35)


# =============================================================================
# TILE INTERACTION
# =============================================================================

func _on_tile_selected(tile: HexTile) -> void:
	# Block tile interaction during deck selection
	if is_selecting_decks:
		return
	
	# Block tile interaction during enhanced combat resolution
	if game_manager and game_manager.current_state == GameManager.GameState.ENHANCED_COMBAT:
		# During combat, only allow clicking on the combat UI - tile clicks are ignored
		return
	
	print("Tile selected: %s (Biome: %s)" % [
		tile.coordinates._to_string(),
		Biomes.get_biome_name(tile.biome_type)
	])
	
	# Handle action modes
	if action_mode == "move" and selected_troop:
		_try_move_to(tile)
		return
	elif action_mode == "attack" and selected_troop:
		_try_attack_at(tile)
		return
	elif action_mode == "mine" and selected_troop:
		_try_place_mine_at(tile)
		return
	
	# Check if there's a troop or mine on this tile
	var occupant = tile.get_occupant()
	if occupant and (occupant is Troop or ("card_id" in occupant and occupant.card_id.begins_with("mine_"))):
		# Check if it's the current player's entity
		var current_player_id = game_manager.turn_manager.get_active_player_id()
		if "owner_player_id" in occupant and occupant.owner_player_id == current_player_id:
			selected_troop = occupant
			var entity_name = occupant.display_name if "display_name" in occupant else "Gold Mine"
			print("Selected entity: %s" % entity_name)
			
			# When selecting an entity on the board, focus the 3D model
			_focus_on_troop_tactical(occupant)
		else:
			var entity_name = occupant.display_name if "display_name" in occupant else "Enemy Gold Mine"
			print("Enemy entity: %s" % entity_name)
	else:
		# Deselect if clicking empty tile
		if selected_troop:
			selected_troop = null
			hex_board.clear_all_highlights()
			# Reset camera if we were in the specialized troop zoom
			if current_view == CameraView.FRONT_QUARTER:
				_set_camera_view(CameraView.TACTICAL, true)
	
	hex_board.select_tile(tile)
	_update_ui()


func _on_tile_hovered(_tile: HexTile) -> void:
	# Could show tooltip or hover info
	pass


# =============================================================================
# ACTION HANDLERS
# =============================================================================

## Helper to check if player actions should be blocked
func _is_action_blocked() -> bool:
	# Block during deck selection
	if is_selecting_decks:
		return true
	
	# Block during enhanced combat resolution
	if game_manager and game_manager.current_state == GameManager.GameState.ENHANCED_COMBAT:
		game_ui.show_info("⚔️ Combat in progress!")
		return true
	
	return false


func _on_action_move() -> void:
	if _is_action_blocked():
		return
	
	if not selected_troop:
		game_ui.show_info("Select a troop first!")
		return
		
	if not selected_troop is Troop:
		game_ui.show_info("This entity cannot move!")
		return
	
	if selected_troop.has_moved_this_turn:
		game_ui.show_info("This troop has already moved!")
		return
	
	if selected_troop.has_attacked_this_turn:
		game_ui.show_info("This troop has already attacked! (One action per turn)")
		return
	
	if action_mode == "move":
		_cancel_action_mode()
		return
	
	action_mode = "move"
	game_ui.show_action_mode("move")
	
	# Highlight valid movement tiles
	hex_board.highlight_movement(selected_troop.current_hex.coordinates, selected_troop.current_speed)
	print("Move mode activated for %s (Speed: %d)" % [selected_troop.display_name, selected_troop.current_speed])


func _on_action_attack() -> void:
	if _is_action_blocked():
		return
	
	if not selected_troop:
		game_ui.show_info("Select a troop first!")
		return
		
	if not selected_troop is Troop:
		game_ui.show_info("This entity cannot attack!")
		return
	
	if selected_troop.has_attacked_this_turn:
		game_ui.show_info("This troop has already attacked!")
		return
	
	if selected_troop.has_moved_this_turn:
		game_ui.show_info("This troop has already moved! (One action per turn)")
		return
	
	if action_mode == "attack":
		_cancel_action_mode()
		return
	
	action_mode = "attack"
	game_ui.show_action_mode("attack")
	
	# Highlight attack range
	hex_board.highlight_attack(selected_troop.current_hex.coordinates, selected_troop.current_range)
	print("Attack mode activated for %s (Range: %d)" % [selected_troop.display_name, selected_troop.current_range])


func _on_action_place_mine() -> void:
	if _is_action_blocked():
		return
	
	if not selected_troop:
		game_ui.show_info("Select a troop first!")
		return
		
	if not selected_troop is Troop:
		game_ui.show_info("Only troops can place mines!")
		return
	
	var player = game_manager.player_manager.get_player(selected_troop.owner_player_id)
	if player.gold < 100:
		game_ui.show_info("Not enough gold! Need 100 gold.")
		return
	
	action_mode = "mine"
	game_ui.show_action_mode("mine")
	print("Mine placement mode activated")


func _on_action_upgrade() -> void:
	if _is_action_blocked():
		return
	
	if not selected_troop:
		game_ui.show_info("Select a troop or mine first!")
		return
		
	if selected_troop is Troop:
		var cost = selected_troop.get_upgrade_cost()
		if not cost["can_upgrade"]:
			game_ui.show_info("Troop is already max level!")
			return
		
		var player = game_manager.player_manager.get_player(selected_troop.owner_player_id)
		if player.gold < cost["gold"] or player.xp < cost["xp"]:
			game_ui.show_info("Not enough resources! Need %d gold and %d XP." % [cost["gold"], cost["xp"]])
			return
		
		# Perform upgrade
		var result = game_manager.action_upgrade_troop(selected_troop)
		if result["success"]:
			print("Upgraded %s to level %d!" % [selected_troop.display_name, result["new_level"]])
			_update_ui()
		else:
			game_ui.show_info(result.get("error", "Upgrade failed!"))
			
	elif "card_id" in selected_troop and selected_troop.card_id.begins_with("mine_"):
		if not selected_troop.can_upgrade():
			game_ui.show_info("Mine is already max level!")
			return
			
		var cost = selected_troop.get_upgrade_cost()
		var player = game_manager.player_manager.get_player(selected_troop.owner_player_id)
		
		if player.gold < cost:
			game_ui.show_info("Not enough gold! Need %d gold." % cost)
			return
			
		# Perform mine upgrade
		var result = game_manager.action_upgrade_mine(selected_troop)
		if result["success"]:
			print("Upgraded Gold Mine to level %d!" % result["new_level"])
			_update_ui()
		else:
			game_ui.show_info(result.get("error", "Upgrade failed!"))
			
	else:
		game_ui.show_info("This entity cannot be upgraded!")


func _on_action_end_turn() -> void:
	print("End turn pressed")
	
	# Block end turn during combat
	if game_manager and game_manager.current_state == GameManager.GameState.ENHANCED_COMBAT:
		game_ui.show_info("⚔️ Cannot end turn during combat!")
		return
	
	if game_manager and game_manager.turn_manager:
		game_manager.turn_manager.end_turn()
		selected_troop = null
		_cancel_action_mode()
		_update_ui()


func _cancel_action_mode() -> void:
	action_mode = "none"
	hex_board.clear_all_highlights()
	game_ui.hide_info()


func _try_move_to(tile: HexTile) -> void:
	if not selected_troop:
		return
	
	# Check if tile is highlighted (valid move)
	if tile in hex_board.highlighted_tiles:
		# Move the troop
		var old_hex = selected_troop.current_hex
		selected_troop.move_to_hex(tile)
		selected_troop.has_moved_this_turn = true
		
		print("%s moved from %s to %s" % [
			selected_troop.display_name,
			old_hex.coordinates._to_string() if old_hex else "spawn",
			tile.coordinates._to_string()
		])
		
		_cancel_action_mode()
		_update_ui()
	else:
		game_ui.show_info("Invalid move! Select a highlighted tile.")


func _try_attack_at(tile: HexTile) -> void:
	if not selected_troop:
		return
	
	var target = tile.get_occupant()
	if not target or not (target is Troop):
		game_ui.show_info("No valid target on this tile!")
		return
	
	if target.owner_player_id == selected_troop.owner_player_id:
		game_ui.show_info("Can't attack your own troops!")
		return
	
	# Check range
	var distance = selected_troop.current_hex.coordinates.distance_to(tile.coordinates)
	if distance > selected_troop.current_range:
		game_ui.show_info("Target out of range!")
		return
	
	# Store references for after dice animation
	var attacker = selected_troop
	var defender = target
	
	# Perform attack through GameManager
	var result = game_manager.action_attack(attacker, defender)
	if result["success"]:
		# Check if this is enhanced combat (combat will resolve via signals, not here)
		if game_manager.current_state == GameManager.GameState.ENHANCED_COMBAT:
			# Enhanced combat started - don't show anything yet
			# Results will be shown via _on_combat_resolved when combat completes
			print("Enhanced combat initiated, waiting for move/stance selection...")
			return
		
		# Legacy combat - show dice UI with combat results
		if dice_ui:
			var atk_roll = 0
			var def_roll = 0
			var atk_rolls = result.get("attacker_rolls", [])
			var def_rolls = result.get("defender_rolls", [])
			if not atk_rolls.is_empty():
				atk_roll = atk_rolls[-1] # Last roll
			if not def_rolls.is_empty():
				def_roll = def_rolls[-1] # Last roll
			
			dice_ui.display_combat_sequence(
				attacker.display_name,
				defender.display_name,
				attacker.current_atk,
				defender.current_def,
				atk_roll,
				def_roll,
				result.get("attack_succeeded", false),
				result.get("damage_dealt", 0),
				result.get("is_critical", false)
			)
		
		print("Combat: %s vs %s - Damage: %d, Killed: %s" % [
			attacker.display_name,
			defender.display_name,
			result.get("damage_dealt", 0),
			result.get("defender_killed", false)
		])
		
		if result.get("defender_killed", false):
			troops.erase(defender)
	else:
		game_ui.show_info(result.get("error", "Attack failed!"))
	
	_cancel_action_mode()
	_update_ui()


func _try_place_mine_at(tile: HexTile) -> void:
	if not selected_troop:
		return
	
	# Check if tile is adjacent to troop
	var distance = selected_troop.current_hex.coordinates.distance_to(tile.coordinates)
	if distance > 1:
		game_ui.show_info("Must place mine on adjacent tile!")
		return
	
	var result = game_manager.action_place_mine(selected_troop, tile)
	if result["success"]:
		print("Gold mine placed at %s" % tile.coordinates._to_string())
	else:
		game_ui.show_info(result.get("error", "Can't place mine here!"))
	
	_cancel_action_mode()
	_update_ui()


# =============================================================================
# GAME EVENTS
# =============================================================================

func _on_turn_started(player_id: int, turn_number: int) -> void:
	print("=== TURN %d: PLAYER %d's TURN ===" % [turn_number, player_id + 1])
	
	# Reset action flags for ALL troops at the start of each turn
	for troop in troops:
		if troop and troop.is_alive:
			troop.has_moved_this_turn = false
			troop.has_attacked_this_turn = false
	
	selected_troop = null
	_cancel_action_mode()
	
	# Switch camera view to be behind the new active player's troops
	_switch_camera_to_player(player_id)
	
	# Update troop cards to show current player's troops
	_update_troop_cards_for_player(player_id)
	
	_update_ui()


func _on_turn_ended(player_id: int, turn_number: int) -> void:
	print("Turn %d: Player %d's turn ended" % [turn_number, player_id + 1])


func _on_game_over(winner_id: int) -> void:
	print("=== GAME OVER ===")
	print("PLAYER %d WINS!" % (winner_id + 1))
	game_ui.show_info("PLAYER %d WINS!" % (winner_id + 1))


# =============================================================================
# ENHANCED COMBAT HANDLERS
# =============================================================================

## Called when enhanced combat starts - show the selection UI
func _on_combat_selection_started(attacker: Node, defender: Node) -> void:
	print("=== ENHANCED COMBAT STARTED ===")
	print("Attacker: %s vs Defender: %s" % [attacker.display_name, defender.display_name])
	
	# Transition camera to front-quarter combat view
	_enter_combat_camera(attacker, defender)
	
	if not combat_selection_ui:
		push_error("CombatSelectionUI not found!")
		return
	
	# Set combat mode on the UI (propagate from game settings)
	var combat_mode = game_manager.get_combat_mode()
	combat_selection_ui.set_combat_mode(combat_mode)
	
	# Determine which player is the local player (in local play, show attacker first)
	var current_player_id = game_manager.turn_manager.get_active_player_id()
	
	if attacker.owner_player_id == current_player_id:
		# Local player is attacking - show move selection
		combat_selection_ui.show_attacker_selection(attacker, defender)
		print("Showing move selection for attacker (Mode: %s)" % ("SIMPLE" if combat_mode == GameConfig.CombatMode.SIMPLE else "ENHANCED"))
	else:
		# Local player is defending - show stance selection
		# In Simple Mode, this will auto-select Brace and skip the UI
		combat_selection_ui.show_defender_selection(attacker, defender)
		print("Showing stance selection for defender (Mode: %s)" % ("SIMPLE" if combat_mode == GameConfig.CombatMode.SIMPLE else "ENHANCED"))


## Called when attacker selects a move
func _on_enhanced_move_selected(move: MoveData.Move) -> void:
	print("Move selected: %s" % move.move_name)
	
	# Check if combat is still active (could have been resolved by timeout)
	if game_manager.current_state != GameManager.GameState.ENHANCED_COMBAT:
		print("Combat already resolved, ignoring move selection")
		return
	
	# Pass to game manager
	game_manager.on_move_selected(move)
	
	# Check again - combat may have auto-resolved if defender was stunned or AI
	if game_manager.current_state != GameManager.GameState.ENHANCED_COMBAT:
		# Combat resolved immediately (e.g., defender couldn't respond)
		if combat_selection_ui:
			combat_selection_ui.hide_selection()
		return
	
	# In local multiplayer, now show defender's turn
	var attacker = game_manager.current_combat_attacker
	var defender = game_manager.current_combat_defender
	
	if defender and combat_selection_ui:
		# Give defender a chance to pick stance
		combat_selection_ui.show_defender_selection(attacker, defender)


## Called when defender selects a stance
func _on_enhanced_stance_selected(stance: int) -> void:
	var stance_name = DefensiveStances.get_stance_name(stance)
	print("Stance selected: %s" % stance_name)
	
	# Check if combat is still active (could have been resolved by timeout)
	if game_manager.current_state != GameManager.GameState.ENHANCED_COMBAT:
		print("Combat already resolved, ignoring stance selection")
		if combat_selection_ui:
			combat_selection_ui.hide_selection()
		return
	
	# Hide selection UI FIRST - before triggering resolution
	if combat_selection_ui:
		combat_selection_ui.hide_selection()
	
	# Pass to game manager - this will trigger combat resolution
	game_manager.on_stance_selected(stance)


## Called when the selection timer expires
func _on_enhanced_combat_timeout() -> void:
	print("Combat selection timed out - using defaults")
	
	# Check if combat is still active (may have already resolved)
	if game_manager.current_state != GameManager.GameState.ENHANCED_COMBAT:
		print("Combat already resolved, ignoring timeout")
		if combat_selection_ui:
			combat_selection_ui.hide_selection()
		return
	
	# Hide the UI FIRST - prevents further input
	if combat_selection_ui:
		combat_selection_ui.hide_selection()
	
	# Force combat to resolve with default selections
	if game_manager and game_manager.combat_manager:
		game_manager.combat_manager.handle_selection_timeout()


## Called when enhanced combat is resolved
func _on_combat_resolved(result: Dictionary) -> void:
	print("=== COMBAT RESOLVED ===")
	print("Result: %s" % str(result))
	
	# Restore camera to pre-combat view
	_exit_combat_camera()
	
	# Hide selection UI if still visible
	if combat_selection_ui:
		combat_selection_ui.hide_selection()
	
	# Show result with dice UI
	if dice_ui:
		var attacker = result.get("attacker")
		var defender = result.get("defender")
		var attacker_name = attacker.display_name if attacker else "Attacker"
		var defender_name = defender.display_name if defender else "Defender"
		
		dice_ui.display_combat_sequence(
			attacker_name,
			defender_name,
			result.get("attack_roll", 0),
			result.get("defense_dc", 0),
			result.get("attack_roll", 0),
			result.get("defense_dc", 0),
			result.get("hit", false),
			result.get("damage", 0),
			result.get("is_critical", false)
		)
	
	# Handle kill
	if result.get("defender_killed", false):
		var defender = result.get("defender")
		if defender:
			troops.erase(defender)
			print("%s was defeated!" % defender.display_name)
	
	# Cancel action mode and update UI
	_cancel_action_mode()
	_update_ui()


## Switch camera to view from behind the specified player's troops
func _switch_camera_to_player(player_id: int) -> void:
	# Store current camera state as starting point for smooth transition
	start_focus_point = focus_point
	start_distance = camera_distance
	start_yaw = camera_yaw
	start_pitch = camera_pitch
	transition_progress = 0.0
	
	# Calculate the center point of the new player's troops
	var player_center = _get_player_troops_center(player_id)
	var opponent_center = _get_player_troops_center(1 - player_id)
	
	print("Switching camera to Player %d's perspective" % (player_id + 1))
	
	if player_center != Vector3.ZERO and opponent_center != Vector3.ZERO:
		# Direction from player to opponent (where we want to LOOK)
		var to_opponent = (opponent_center - player_center).normalized()
		
		# Focus point: slightly ahead of player troops towards center
		target_focus_point = player_center.lerp(opponent_center, 0.25)
		
		# Camera yaw: we want camera BEHIND player, so opposite of to_opponent direction
		var camera_dir = - to_opponent
		target_yaw = rad_to_deg(atan2(camera_dir.x, camera_dir.z))
		
	elif player_center != Vector3.ZERO:
		# Only player troops exist, point towards center
		target_focus_point = player_center.lerp(Vector3.ZERO, 0.3)
		var to_center = (Vector3.ZERO - player_center).normalized()
		var camera_dir = - to_center
		target_yaw = rad_to_deg(atan2(camera_dir.x, camera_dir.z))
	else:
		# Fallback to default overview
		target_focus_point = Vector3.ZERO
		target_yaw = 0.0
	
	# Use a dramatic tactical view for turn start
	target_distance = 25.0
	target_pitch = 40.0
	
	# Enable cinematic transition mode for smooth player switch
	is_camera_transitioning = true
	is_player_switch_transition = true
	
	# Show turn change notification
	if game_ui:
		var _player_color = PLAYER1_COLOR if player_id == 0 else PLAYER2_COLOR
		game_ui.show_info("⚔️ PLAYER %d's TURN ⚔️" % (player_id + 1))
		get_tree().create_timer(2.0).timeout.connect(func():
			if game_ui and action_mode == "none":
				game_ui.hide_info()
		)


## Update the troop cards panel to display the current player's troops
func _update_troop_cards_for_player(player_id: int) -> void:
	if not game_ui or not game_manager:
		return
	
	var player = game_manager.player_manager.get_player(player_id)
	if player:
		# Update the troop cards for this player
		game_ui.update_troop_cards(player, selected_troop)
