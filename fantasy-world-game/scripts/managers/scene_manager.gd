## Scene Manager (Autoload Singleton)
## Eliminates gray screen during scene transitions by using parent-child scene management.
## Loads and initializes new scenes before removing old ones for seamless transitions.
extends Node

# =============================================================================
# SIGNALS
# =============================================================================
signal scene_change_started(from_scene: String, to_scene: String)
signal scene_change_completed(new_scene: String)

# =============================================================================
# CONSTANTS
# =============================================================================
const TRANSITION_DURATION: float = 0.4

# Scene paths
const SCENES = {
	"start_menu": "res://scenes/ui/start_menu.tscn",
	"main": "res://scenes/main.tscn"
}

# =============================================================================
# STATE
# =============================================================================
var current_scene: Node = null
var current_scene_name: String = ""
var is_transitioning: bool = false

# Fade overlay for smooth transitions
var fade_overlay: ColorRect = null
var fade_canvas: CanvasLayer = null

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	# Create fade overlay for transitions
	_create_fade_overlay()
	print("[SceneManager] Initialized")
	
	# Auto-load the initial scene (start menu)
	call_deferred("_load_start_scene")


func _create_fade_overlay() -> void:
	# Create a CanvasLayer at top layer for fade effect
	fade_canvas = CanvasLayer.new()
	fade_canvas.name = "FadeCanvas"
	fade_canvas.layer = 100 # Above everything
	add_child(fade_canvas)
	
	# Create fade overlay ColorRect
	fade_overlay = ColorRect.new()
	fade_overlay.name = "FadeOverlay"
	fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_overlay.color = Color(0.05, 0.08, 0.15, 0.0) # Match UI background, start transparent
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_canvas.add_child(fade_overlay)


# =============================================================================
# SCENE MANAGEMENT
# =============================================================================

## Change to a new scene by name (e.g., "start_menu", "main")
func change_scene(scene_name: String, use_transition: bool = true) -> void:
	if is_transitioning:
		push_warning("[SceneManager] Already transitioning, ignoring scene change request")
		return
	
	var scene_path = SCENES.get(scene_name, scene_name)
	if scene_path == scene_name and not ResourceLoader.exists(scene_path):
		push_error("[SceneManager] Unknown scene: %s" % scene_name)
		return
	
	await _change_scene_internal(scene_path, scene_name, use_transition)


## Change to a scene by file path
func change_scene_to_file(scene_path: String, use_transition: bool = true) -> void:
	if is_transitioning:
		push_warning("[SceneManager] Already transitioning, ignoring scene change request")
		return
	
	if not ResourceLoader.exists(scene_path):
		push_error("[SceneManager] Scene file not found: %s" % scene_path)
		return
	
	# Extract scene name from path
	var scene_name = scene_path.get_file().get_basename()
	await _change_scene_internal(scene_path, scene_name, use_transition)


## Internal scene change with proper parent-child management
func _change_scene_internal(scene_path: String, scene_name: String, use_transition: bool) -> void:
	is_transitioning = true
	var old_scene_name = current_scene_name
	
	print("[SceneManager] Changing scene: %s -> %s" % [old_scene_name, scene_name])
	scene_change_started.emit(old_scene_name, scene_name)
	
	# Step 1: Fade out (if using transition)
	if use_transition:
		await _fade_out()
	
	# Step 2: Load and instantiate the new scene BEFORE removing old one
	var new_scene_packed = load(scene_path) as PackedScene
	if not new_scene_packed:
		push_error("[SceneManager] Failed to load scene: %s" % scene_path)
		is_transitioning = false
		return
	
	var new_scene = new_scene_packed.instantiate()
	if not new_scene:
		push_error("[SceneManager] Failed to instantiate scene: %s" % scene_path)
		is_transitioning = false
		return
	
	# Step 3: Add new scene as child (hidden initially)
	new_scene.visible = false
	add_child(new_scene)
	
	# Step 4: Wait for scene to be fully initialized
	# This is CRITICAL - ensures all _ready() functions complete and nodes are in tree
	await get_tree().process_frame
	await get_tree().process_frame # Double-frame wait for complex scenes
	
	# Step 5: Make new scene visible
	new_scene.visible = true
	
	# Step 6: Remove old scene safely
	if current_scene and is_instance_valid(current_scene):
		current_scene.queue_free()
	
	# Step 7: Update state
	current_scene = new_scene
	current_scene_name = scene_name
	
	# Step 8: Fade in (if using transition)
	if use_transition:
		await _fade_in()
	
	is_transitioning = false
	print("[SceneManager] Scene change complete: %s" % scene_name)
	scene_change_completed.emit(scene_name)


# =============================================================================
# FADE TRANSITIONS
# =============================================================================

func _fade_out() -> void:
	if not fade_overlay:
		return
	
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP # Block input during fade
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(fade_overlay, "color:a", 1.0, TRANSITION_DURATION)
	await tween.finished


func _fade_in() -> void:
	if not fade_overlay:
		return
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(fade_overlay, "color:a", 0.0, TRANSITION_DURATION)
	await tween.finished
	
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE # Re-enable input


# =============================================================================
# INSTANT SCENE LOADING (for initial load)
# =============================================================================

## Load initial scene without transition (called on game start)
func load_initial_scene(scene_path: String) -> void:
	var scene_name = scene_path.get_file().get_basename()
	
	print("[SceneManager] Loading initial scene: %s" % scene_name)
	
	var packed_scene = load(scene_path) as PackedScene
	if not packed_scene:
		push_error("[SceneManager] Failed to load initial scene: %s" % scene_path)
		return
	
	current_scene = packed_scene.instantiate()
	if not current_scene:
		push_error("[SceneManager] Failed to instantiate initial scene: %s" % scene_path)
		return
	
	add_child(current_scene)
	current_scene_name = scene_name
	
	# Wait for scene to be ready
	await get_tree().process_frame
	
	print("[SceneManager] Initial scene loaded: %s" % scene_name)


# =============================================================================
# UTILITY
# =============================================================================

## Get the current active scene node
func get_current_scene() -> Node:
	return current_scene


## Check if a transition is in progress
func is_scene_transitioning() -> bool:
	return is_transitioning


## Load the start scene (called on initialization)
func _load_start_scene() -> void:
	await load_initial_scene(SCENES["start_menu"])
