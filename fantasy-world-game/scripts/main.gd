## Main Game Entry Point
## Sets up the game and coordinates all systems
## This is the playable test scene with GameManager integration
extends Node3D

# Preload dependencies
const SettingsMenuScene = preload("res://scripts/ui/settings_menu.gd")
const CardSelectionUIScene = preload("res://scripts/ui/card_selection_ui.gd")

# =============================================================================
# NODE REFERENCES
# =============================================================================
var hex_board: HexBoard
var camera: Camera3D
var camera_pivot: Node3D
var game_manager: GameManager
var game_ui: GameUI
var dice_ui: DiceUI
var card_selection_ui: Node # CardSelectionUI

# Deck selection state
var is_selecting_decks: bool = false
var current_selecting_player: int = 0
var player_decks: Array[Array] = [[], []] # Stores selected decks for both players

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

var camera_distance: float = 35.0 # Current zoom distance (start zoomed out)
var camera_yaw: float = 0.0 # Horizontal rotation (Y-axis)
var camera_pitch: float = 45.0 # Vertical rotation (X-axis), start at 45° down

var is_rotating: bool = false # Is right-click drag active?
var is_panning_mouse: bool = false # Is middle-click drag active?

# Focus point for camera orbit (where camera looks at)
var focus_point: Vector3 = Vector3.ZERO

# Camera view presets
enum CameraView {
	OVERVIEW, # Full board view from behind player's troops
	TACTICAL, # Closer tactical view centered on action
	TROOP_FOCUS, # Close-up on selected troop
	TOP_DOWN, # Bird's eye view
	CINEMATIC # Low angle dramatic view
}

var current_view: CameraView = CameraView.OVERVIEW
var target_focus_point: Vector3 = Vector3.ZERO
var target_distance: float = 35.0
var target_yaw: float = 0.0
var target_pitch: float = 45.0
var is_camera_transitioning: bool = false

# Smooth transition variables
var transition_progress: float = 0.0
var transition_duration: float = 1.5 # Duration in seconds for player switch
var start_focus_point: Vector3 = Vector3.ZERO
var start_distance: float = 35.0
var start_yaw: float = 0.0
var start_pitch: float = 45.0
var is_player_switch_transition: bool = false # Special cinematic transition

# View preset definitions: {distance, pitch, yaw_offset from base position}
# yaw_offset: 0 = directly behind player, positive = rotate right, negative = rotate left
const VIEW_PRESETS: Dictionary = {
	"OVERVIEW": {"distance": 35.0, "pitch": 45.0, "yaw_offset": 0.0},
	"TACTICAL": {"distance": 20.0, "pitch": 50.0, "yaw_offset": 0.0},
	"TROOP_FOCUS": {"distance": 10.0, "pitch": 35.0, "yaw_offset": 15.0},
	"TOP_DOWN": {"distance": 40.0, "pitch": 85.0, "yaw_offset": 0.0},
	"CINEMATIC": {"distance": 15.0, "pitch": 20.0, "yaw_offset": 25.0}
}

const VIEW_NAMES: Array[String] = ["Overview", "Tactical", "Troop Focus", "Top-Down", "Cinematic"]

# =============================================================================
# GAME STATE
# =============================================================================
var game_started: bool = false
var decks_confirmed: bool = false
var selected_troop: Troop = null
var troops: Array[Troop] = []

# Action mode: "none", "move", "attack", "mine"
var action_mode: String = "none"

# Pause state
var is_paused: bool = false
var pause_menu: CanvasLayer = null

# Team Colors
const PLAYER1_COLOR = Color(0.2, 0.5, 1.0) # Blue
const PLAYER2_COLOR = Color(1.0, 0.3, 0.2) # Red

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	print("Fantasy World Game - Starting...")
	print("Godot Version: %s" % Engine.get_version_info().string)
	
	# Find or create camera system
	_setup_camera_system()
	
	# Find hex board
	hex_board = get_node_or_null("HexBoard")
	if hex_board:
		_generate_board()
	else:
		push_error("HexBoard node not found!")
	
	# Create game UI
	_setup_game_ui()
	
	# Start test game
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
	# Create camera pivot (the point camera orbits around)
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	add_child(camera_pivot)
	
	# Create camera as child of pivot
	camera = Camera3D.new()
	camera.name = "MainCamera"
	camera.current = true
	camera.fov = 60.0
	camera_pivot.add_child(camera)
	
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
	
	# Apply initial transform
	_update_camera_transform()
	print("Camera system initialized")


func _generate_board() -> void:
	hex_board.generate_board()
	hex_board.print_board_stats()
	
	# Connect board signals
	hex_board.tile_selected.connect(_on_tile_selected)
	hex_board.tile_hovered.connect(_on_tile_hovered)
	
	print("Board generated successfully!")


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
		
		# Create Dice UI for combat visualization
		dice_ui = DiceUI.new()
		add_child(dice_ui)
		
		# Create Card Selection UI
		card_selection_ui = CardSelectionUIScene.new()
		add_child(card_selection_ui)
		card_selection_ui.deck_confirmed.connect(_on_deck_confirmed)
		card_selection_ui.selection_canceled.connect(_on_deck_selection_canceled)
	else:
		push_error("GameUI CanvasLayer not found!")


# =============================================================================
# TEST GAME SETUP
# =============================================================================

func _start_test_game() -> void:
	print("Starting test game...")
	
	# Create GameManager
	game_manager = GameManager.new()
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
	
	# Hide game UI during deck selection
	if game_ui and game_ui.main_container:
		game_ui.main_container.visible = false
	
	# Start deck selection for Player 1
	_start_deck_selection(0)


## Start deck selection phase for a player
func _start_deck_selection(player_id: int) -> void:
	is_selecting_decks = true
	current_selecting_player = player_id
	game_manager.current_state = GameManager.GameState.DECK_SELECTION
	
	print("=== DECK SELECTION ===")
	print("Player %d - Select your deck!" % (player_id + 1))
	print("card_selection_ui exists: %s" % (card_selection_ui != null))
	
	# Show card selection UI
	if card_selection_ui:
		print("Calling show_selection...")
		card_selection_ui.show_selection(player_id, true)
		print("show_selection called!")
	else:
		push_error("ERROR: card_selection_ui is NULL!")


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
	# Return to main menu or handle cancellation
	if card_selection_ui:
		card_selection_ui.hide_selection()
	get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn")


## Finalize game start after both players selected decks
func _finalize_game_start() -> void:
	is_selecting_decks = false
	decks_confirmed = true
	
	# Show game UI
	if game_ui and game_ui.main_container:
		game_ui.main_container.visible = true
	
	# Spawn troops based on selected decks
	_spawn_troops_from_decks()
	
	# Properly start the game (set phase to PLAYING and begin first turn)
	game_manager.current_state = GameManager.GameState.PLAYING
	game_manager.turn_manager.current_phase = TurnManager.Phase.PLAYER_TURN
	game_manager.turn_manager._begin_new_turn()
	
	game_started = true
	_update_ui()
	
	# Set up initial camera view - behind player 1's troops looking at the board
	# Defer this to ensure all node transforms are updated
	call_deferred("_setup_initial_camera_view")
	
	print("Game started!")
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
		var can_move = not selected_troop.has_moved_this_turn
		var can_attack = not selected_troop.has_attacked_this_turn
		var can_mine = game_manager.player_manager.get_player(selected_troop.owner_player_id).gold >= 100
		var can_upgrade = selected_troop.level < 5
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
	if not camera or not camera_pivot:
		return
	
	# Clamp pitch
	camera_pitch = clamp(camera_pitch, 10.0, 89.0)
	
	# Position pivot at focus point
	camera_pivot.global_position = focus_point
	
	# Calculate camera position based on spherical coordinates
	var pitch_rad = deg_to_rad(camera_pitch)
	var yaw_rad = deg_to_rad(camera_yaw)
	
	# Spherical to Cartesian
	var offset = Vector3(
		camera_distance * cos(pitch_rad) * sin(yaw_rad),
		camera_distance * sin(pitch_rad),
		camera_distance * cos(pitch_rad) * cos(yaw_rad)
	)
	
	camera.global_position = focus_point + offset
	camera.look_at(focus_point, Vector3.UP)


func _zoom_camera(direction: float) -> void:
	camera_distance += direction * camera_distance * ZOOM_SPEED
	camera_distance = clamp(camera_distance, ZOOM_MIN, ZOOM_MAX)
	_update_camera_transform()


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
	forward = forward.normalized()
	
	# Calculate movement relative to camera facing
	var movement = Vector3.ZERO
	movement += forward * direction.z # W/S
	movement += right * direction.x # A/D
	movement.y = direction.y # Q/E
	
	# Apply speed modifier if Shift is held
	var speed = PAN_SPEED_SHIFT if Input.is_key_pressed(KEY_SHIFT) else PAN_SPEED
	focus_point += movement * speed * delta
	
	_update_camera_transform()


# =============================================================================
# INPUT HANDLING
# =============================================================================

func _process(delta: float) -> void:
	_handle_keyboard_movement(delta)
	_update_camera_smooth(delta)
	
	# Update timer display
	if game_ui and game_manager and game_manager.turn_manager:
		game_ui.update_timer(game_manager.turn_manager.turn_timer_remaining)


func _handle_keyboard_movement(delta: float) -> void:
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


func _input(event: InputEvent) -> void:
	# Mouse button events
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	
	# Mouse motion events
	if event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	
	# Keyboard events
	if event is InputEventKey and event.pressed:
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
		# Rotate camera with right-click drag
		_rotate_camera_view(-event.relative.x, -event.relative.y)
	
	elif is_panning_mouse:
		# Pan with middle-click drag
		var pan_sensitivity = 0.02 * (camera_distance / 10.0)
		var right = camera.global_transform.basis.x
		var up = camera.global_transform.basis.y
		
		focus_point -= right * event.relative.x * pan_sensitivity
		focus_point += up * event.relative.y * pan_sensitivity
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


## Selects troop based on slot number (1-4 keys select troops 1-4)
func _select_troop_by_slot_for_current_player(slot: int) -> void:
	if not game_manager or not game_manager.turn_manager:
		return
	
	# Simply select the troop at the given slot (no inversion)
	_select_troop_by_slot(slot)


func _select_troop_by_slot(slot: int) -> void:
	if not game_manager or not game_manager.turn_manager:
		return
	
	var current_player_id = game_manager.turn_manager.get_active_player_id()
	var player = game_manager.player_manager.get_player(current_player_id)
	
	if not player:
		return
	
	# Find troop by deck slot (same as UI card order)
	if slot < player.deck.size():
		var troop_id = player.deck[slot]
		var troop = _find_troop_by_id_for_player(player, troop_id)
		
		if troop and troop.is_alive:
			# Cancel any active action mode when selecting a new troop
			_cancel_action_mode()
			
			selected_troop = troop
			print("Selected %s (Slot %d)" % [selected_troop.display_name, slot + 1])
			
			# Smart camera focus on troop for tactical view
			_focus_on_troop_tactical(selected_troop)
			
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
		print("Camera focused on %s (tactical view)" % selected_troop.display_name)
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
	
	camera_pitch = 10.0 # Very low angle for dramatic ground-level view
	camera_distance = 20.0 # Zoomed in closer
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
	
	# Calculate target values
	target_distance = preset["distance"]
	target_pitch = preset["pitch"]
	
	# Yaw: position camera behind current player's side
	# Player 0 at -X needs yaw = -90, Player 1 at +X needs yaw = 90
	var base_yaw = -90.0 if current_player_id == 0 else 90.0
	target_yaw = base_yaw + preset["yaw_offset"]
	
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


## Smart camera positioning when selecting a troop
## Positions camera behind the troop, facing towards the enemy side
func _focus_on_troop_tactical(troop: Troop) -> void:
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
	
	pause_menu = CanvasLayer.new()
	pause_menu.layer = 100
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_menu)
	
	# Dark overlay
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.add_child(overlay)
	
	# Menu panel
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(350, 400)
	panel.position = Vector2(-175, -200)
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.add_child(panel)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.12, 0.98)
	panel_style.set_corner_radius_all(16)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.4, 0.6, 1.0, 0.5)
	panel.add_theme_stylebox_override("panel", panel_style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "⏸️ PAUSED"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)
	
	# Resume Button
	var resume_btn = _create_pause_button("▶️  RESUME", Color(0.4, 0.7, 0.4))
	resume_btn.pressed.connect(_close_pause_menu)
	vbox.add_child(resume_btn)
	
	# Settings Button
	var settings_btn = _create_pause_button("⚙️  SETTINGS", Color(0.6, 0.6, 0.8))
	settings_btn.pressed.connect(_open_settings_from_pause)
	vbox.add_child(settings_btn)
	
	# Main Menu Button
	var menu_btn = _create_pause_button("🏠  MAIN MENU", Color(0.7, 0.6, 0.4))
	menu_btn.pressed.connect(_return_to_main_menu)
	vbox.add_child(menu_btn)
	
	# Quit Button
	var quit_btn = _create_pause_button("🚪  QUIT GAME", Color(0.7, 0.4, 0.4))
	quit_btn.pressed.connect(func(): get_tree().quit())
	vbox.add_child(quit_btn)
	
	print("Game paused")


func _create_pause_button(text: String, color: Color) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(280, 50)
	button.add_theme_font_size_override("font_size", 18)
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = color.darkened(0.5)
	normal_style.set_corner_radius_all(10)
	normal_style.set_border_width_all(2)
	normal_style.border_color = color.darkened(0.3)
	button.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = color.darkened(0.3)
	hover_style.set_corner_radius_all(10)
	hover_style.set_border_width_all(2)
	hover_style.border_color = color
	button.add_theme_stylebox_override("hover", hover_style)
	
	return button


func _close_pause_menu() -> void:
	if pause_menu:
		pause_menu.queue_free()
		pause_menu = null
	is_paused = false
	get_tree().paused = false
	print("Game resumed")


func _open_settings_from_pause() -> void:
	var settings_menu = SettingsMenuScene.new()
	settings_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.add_child(settings_menu)


func _return_to_main_menu() -> void:
	_close_pause_menu()
	get_tree().change_scene_to_file("res://scenes/ui/start_menu.tscn")


# =============================================================================
# TILE INTERACTION
# =============================================================================

func _on_tile_selected(tile: HexTile) -> void:
	# Block tile interaction during deck selection
	if is_selecting_decks:
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
	
	# Check if there's a troop on this tile
	var occupant = tile.get_occupant()
	if occupant is Troop:
		# Check if it's the current player's troop
		var current_player_id = game_manager.turn_manager.get_active_player_id()
		if occupant.owner_player_id == current_player_id:
			selected_troop = occupant
			print("Selected troop: %s" % occupant.display_name)
		else:
			print("Enemy troop: %s" % occupant.display_name)
	else:
		# Deselect if clicking empty tile
		if selected_troop:
			selected_troop = null
			hex_board.clear_all_highlights()
	
	hex_board.select_tile(tile)
	_update_ui()


func _on_tile_hovered(tile: HexTile) -> void:
	# Could show tooltip or hover info
	pass


# =============================================================================
# ACTION HANDLERS
# =============================================================================

func _on_action_move() -> void:
	if not selected_troop:
		game_ui.show_info("Select a troop first!")
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
	if not selected_troop:
		game_ui.show_info("Select a troop first!")
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
	if not selected_troop:
		game_ui.show_info("Select a troop first!")
		return
	
	var player = game_manager.player_manager.get_player(selected_troop.owner_player_id)
	if player.gold < 100:
		game_ui.show_info("Not enough gold! Need 100 gold.")
		return
	
	action_mode = "mine"
	game_ui.show_action_mode("mine")
	print("Mine placement mode activated")


func _on_action_upgrade() -> void:
	if not selected_troop:
		game_ui.show_info("Select a troop first!")
		return
	
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


func _on_action_end_turn() -> void:
	print("End turn pressed")
	
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
		# Show dice UI with combat results
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
		var player_color = PLAYER1_COLOR if player_id == 0 else PLAYER2_COLOR
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
