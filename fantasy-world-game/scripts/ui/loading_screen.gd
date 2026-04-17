extends Control

@export var next_scene_path: String = "res://scenes/game_root.tscn"

@onready var progress_bar = $VBoxContainer/ProgressBar
@onready var status_label = $VBoxContainer/StatusLabel
@onready var fade_rect = $FadeRect

var _loading_status = 0
var _progress = []

func _ready():
	_progress.resize(1)
	_progress[0] = 0.0
	progress_bar.visible = false
	
	# Start loading in background after a brief visual delay to show UI immediately
	await get_tree().create_timer(0.2).timeout
	ResourceLoader.load_threaded_request(next_scene_path)
	set_process(true)

func _process(_delta):
	_loading_status = ResourceLoader.load_threaded_get_status(next_scene_path, _progress)
	
	if _loading_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		status_label.text = "Loading environment..."
	elif _loading_status == ResourceLoader.THREAD_LOAD_LOADED:
		set_process(false)
		status_label.text = "Loading Complete!"
		call_deferred("_transition_to_next_scene")
	elif _loading_status == ResourceLoader.THREAD_LOAD_FAILED:
		set_process(false)
		status_label.text = "Loading Failed!"

func _transition_to_next_scene():
	# Simple fade to black before switching scene
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.5)
	await tween.finished
	var packed_scene = ResourceLoader.load_threaded_get(next_scene_path)
	get_tree().change_scene_to_packed(packed_scene)
