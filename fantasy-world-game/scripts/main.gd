## Main Game Entry Point
## Sets up the game and coordinates all systems
## This is the playable test scene with GameManager integration
extends Node3D

# =============================================================================
# NODE REFERENCES
# =============================================================================
var hex_board: HexBoard
var camera: Camera3D
var camera_pivot: Node3D
var game_manager: GameManager
var game_ui: GameUI

# =============================================================================
# CAMERA SETTINGS
# =============================================================================
const ZOOM_MIN: float = 3.0 # Closest zoom (to see characters up close)
const ZOOM_MAX: float = 40.0 # Farthest zoom (see whole board)
const ZOOM_SPEED: float = 0.15 # Zoom sensitivity
const PAN_SPEED: float = 15.0 # WASD pan speed
const ROTATE_SPEED: float = 0.3 # Mouse rotation sensitivity (degrees per pixel)
const PAN_SPEED_SHIFT: float = 30.0 # Faster pan when holding Shift

var camera_distance: float = 20.0 # Current zoom distance
var camera_yaw: float = 0.0 # Horizontal rotation (Y-axis)
var camera_pitch: float = 45.0 # Vertical rotation (X-axis), start at 45° down

var is_rotating: bool = false # Is right-click drag active?
var is_panning_mouse: bool = false # Is middle-click drag active?

# Focus point for camera orbit (where camera looks at)
var focus_point: Vector3 = Vector3.ZERO

# =============================================================================
# GAME STATE
# =============================================================================
var game_started: bool = false
var selected_troop: Troop = null
var troops: Array[Troop] = []

# Action mode: "none", "move", "attack", "mine"
var action_mode: String = "none"

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
	print("F: Focus on selected tile")
	print("Home: Reset camera")
	print("")
	print("=== GAMEPLAY ===")
	print("Left-Click tile: Select")
	print("1-4: Select troop by slot")
	print("Space: End turn")
	print("M: Toggle move mode")
	print("A: Toggle attack mode")
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
	
	# Set test decks for both players
	# Player 1: Knight, Dragon, Wizard, Cleric
	var player1_deck: Array[String] = ["medieval_knight", "dark_blood_dragon", "dark_magic_wizard", "celestial_cleric"]
	game_manager.set_player_deck(0, player1_deck)
	
	# Player 2: Giant, Sky Serpent, Elven Archer, Shadow Assassin
	var player2_deck: Array[String] = ["stone_giant", "sky_serpent", "elven_archer", "shadow_assassin"]
	game_manager.set_player_deck(1, player2_deck)
	
	# Spawn troops manually for testing
	_spawn_test_troops()
	
	# Properly start the game (set phase to PLAYING and begin first turn)
	game_manager.current_state = GameManager.GameState.PLAYING
	game_manager.turn_manager.current_phase = TurnManager.Phase.PLAYER_TURN
	game_manager.turn_manager._begin_new_turn()
	
	game_started = true
	_update_ui()
	
	print("Test game started!")
	print("Player 1 (Blue): Knight, Dragon, Wizard, Cleric")
	print("Player 2 (Red): Giant, Serpent, Archer, Assassin")


func _spawn_test_troops() -> void:
	# Get spawn positions
	var p1_spawns = hex_board.get_player_spawn_positions(0)
	var p2_spawns = hex_board.get_player_spawn_positions(1)
	
	print("Player 1 spawn positions: %d" % p1_spawns.size())
	print("Player 2 spawn positions: %d" % p2_spawns.size())
	
	# Player 1 troops (Blue)
	var p1_deck = ["medieval_knight", "dark_blood_dragon", "dark_magic_wizard", "celestial_cleric"]
	for i in range(min(p1_deck.size(), p1_spawns.size())):
		var troop = _create_troop(p1_deck[i], 0, p1_spawns[i])
		if troop:
			troops.append(troop)
	
	# Player 2 troops (Red)
	var p2_deck = ["stone_giant", "sky_serpent", "elven_archer", "shadow_assassin"]
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
	match event.keycode:
		KEY_ESCAPE:
			# Release mouse if captured, otherwise cancel action mode
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				is_rotating = false
				is_panning_mouse = false
			elif action_mode != "none":
				_cancel_action_mode()
			else:
				_toggle_pause_menu()
		
		KEY_F:
			# Focus on selected tile
			_focus_on_selection()
		
		KEY_HOME:
			# Reset camera to default
			_reset_camera()
		
		KEY_1:
			_select_troop_by_slot(0)
		KEY_2:
			_select_troop_by_slot(1)
		KEY_3:
			_select_troop_by_slot(2)
		KEY_4:
			_select_troop_by_slot(3)
		
		KEY_SPACE:
			_on_action_end_turn()
		
		KEY_M:
			_on_action_move()
		
		KEY_T:
			_on_action_attack()


func _select_troop_by_slot(slot: int) -> void:
	if not game_manager or not game_manager.turn_manager:
		return
	
	var current_player_id = game_manager.turn_manager.get_active_player_id()
	var player = game_manager.player_manager.get_player(current_player_id)
	
	if player and slot < player.troops.size():
		# Cancel any active action mode when selecting a new troop
		_cancel_action_mode()
		
		selected_troop = player.troops[slot]
		print("Selected %s (Slot %d)" % [selected_troop.display_name, slot + 1])
		
		# Focus camera on troop
		if selected_troop.current_hex:
			focus_point = selected_troop.current_hex.position
			_update_camera_transform()
		
		_update_ui()


func _focus_on_selection() -> void:
	if selected_troop and selected_troop.current_hex:
		focus_point = selected_troop.current_hex.global_position
		_update_camera_transform()
		print("Camera focused on %s" % selected_troop.display_name)
	elif hex_board and hex_board.selected_tile:
		focus_point = hex_board.selected_tile.global_position
		_update_camera_transform()
		print("Camera focused on selected tile")
	else:
		print("No tile or troop selected - click a tile first, then press F")


func _reset_camera() -> void:
	focus_point = Vector3.ZERO
	camera_distance = 20.0
	camera_yaw = 0.0
	camera_pitch = 45.0
	_update_camera_transform()
	print("Camera reset to default")


func _toggle_pause_menu() -> void:
	print("Pause menu (ESC pressed)")
	# TODO: Implement pause menu


# =============================================================================
# TILE INTERACTION
# =============================================================================

func _on_tile_selected(tile: HexTile) -> void:
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
	
	# Perform attack through GameManager
	var result = game_manager.action_attack(selected_troop, target)
	if result["success"]:
		var combat_result = result.get("combat_result", {})
		print("Combat: %s vs %s - Damage: %d, Killed: %s" % [
			selected_troop.display_name,
			target.display_name,
			combat_result.get("damage", 0),
			combat_result.get("target_killed", false)
		])
		
		if combat_result.get("target_killed", false):
			troops.erase(target)
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
	_update_ui()


func _on_turn_ended(player_id: int, turn_number: int) -> void:
	print("Turn %d: Player %d's turn ended" % [turn_number, player_id + 1])


func _on_game_over(winner_id: int) -> void:
	print("=== GAME OVER ===")
	print("PLAYER %d WINS!" % (winner_id + 1))
	game_ui.show_info("PLAYER %d WINS!" % (winner_id + 1))
