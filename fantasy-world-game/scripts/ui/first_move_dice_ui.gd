## First Move Dice UI — Cinematic 3D d20 roll
## Fully staged 3D die-roll sequence using the game camera & UITheme styling.
##
##  Phase 0 — P1 camera glide:      Bird's-eye view of P1's table side
##  Phase 1 — P1 roll prompt:       "PLAYER 1" header + countdown/ENTER
##  Phase 2 — P1 die launch:        d20 tumbles from corner to centre
##  Phase 3 — P1 die settle + zoom: Camera closes in; result pops up
##  Phase 4 — Handoff cut:          Brief fade, camera swings to P2
##  Phases 5-8 — same for P2
##  Phase 9 — Final verdict panel:  P1 vs P2 result; winner highlighted
##
## Call set_camera(camera, main_node) before show_roll().
class_name FirstMoveDiceUI
extends CanvasLayer

# =============================================================================
# SIGNALS
# =============================================================================
signal roll_complete(first_player_id: int)

# =============================================================================
# CONSTANTS
# =============================================================================
const COUNTDOWN_SECONDS: float = 10.0
const SETTLE_HOLD_SECONDS: float = 2.0
const VERDICT_HOLD_SECONDS: float = 3.5

## 3D Die scale — 3× the table-comfortable size.
const DIE_SCALE: float = 1.56

## Camera states. Yaw -60° = looking toward P2 from P1 side.
## Wait view matches the initial gameplay view for the respective player.
## Zoom view brings the camera down for a close-up on the settled die.
const CAM_P1_WAIT := {
	"pitch": 15.0,
	"yaw": - 60.0,
	"distance": 55.0,
	"focus": Vector3(-7.0, 0.0, 4.0)
}
const CAM_P1_ZOOM := {
	"pitch": 45.0,
	"yaw": - 60.0,
	"distance": 8.0,
	"focus": Vector3(-18.0, 0.0, 10.0)
}
const CAM_P2_WAIT := {
	"pitch": 15.0,
	"yaw": 120.0,
	"distance": 55.0,
	"focus": Vector3(7.0, 0.0, -4.0)
}
const CAM_P2_ZOOM := {
	"pitch": 45.0,
	"yaw": 120.0,
	"distance": 8.0,
	"focus": Vector3(18.0, 0.0, -10.0)
}
const CAM_GAMEPLAY := {
	"pitch": 80.0, # Centered bird's eye view
	"yaw": 30.0,
	"distance": 45.0,
	"focus": Vector3.ZERO
}

## Die spawn/settle positions. Lowered height and tightened distance.
const P1_SPAWN := Vector3(-35.0, 4.0, 24.0)
const P1_SETTLE := Vector3(-18.0, 1.3, 10.0)
const P2_SPAWN := Vector3(35.0, 4.0, -24.0)
const P2_SETTLE := Vector3(18.0, 1.3, -10.0)

# =============================================================================
# HUD NODE REFS
# =============================================================================
var _hud_root: Control
var _player_label: Label
var _prompt_label: Label
var _countdown_label: Label
var _result_label: Label
var _verdict_panel: Control

# =============================================================================
# 3-D ELEMENTS
# =============================================================================
var _die_p1: Node3D
var _die_p2: Node3D
var _die_tween: Tween
var _die_spin_tween: Tween

# =============================================================================
# EXTERNAL REFS (set via set_camera)
# =============================================================================
var _camera: Camera3D = null
var _main: Node3D = null

# =============================================================================
# STATE
# =============================================================================
var _p1_roll: int = 0
var _p2_roll: int = 0
var _first_player: int = 0
var _phase: int = 0
var _countdown_val: float = COUNTDOWN_SECONDS
var _countdown_active: bool = false
var _waiting_input: bool = false
var _cam_tween: Tween
var _countdown_timer: Timer = null
var _p1_die_visible_before_pause: bool = false
var _p2_die_visible_before_pause: bool = false
var _p1_actual_settle: Vector3
var _p2_actual_settle: Vector3

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	layer = 110
	visible = false
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_build_hud()


func set_camera(camera: Camera3D, main_node: Node3D) -> void:
	_camera = camera
	_main = main_node


func show_roll(p1_roll: int, p2_roll: int) -> void:
	_p1_roll = p1_roll
	_p2_roll = p2_roll
	_first_player = 0 if p1_roll >= p2_roll else 1
	_spawn_dice()
	visible = true
	_phase = 0
	# Lock all game controls for the duration of the cinematic
	if _main and "dice_roll_active" in _main:
		_main.dice_roll_active = true
	_run_phase()


# =============================================================================
# PHASE RUNNER
# =============================================================================

func _run_phase() -> void:
	match _phase:
		0: _phase_p1_cam()
		1: _phase_p1_prompt()
		2: _phase_p1_launch()
		3: _phase_p1_settle()
		4: _phase_handoff()
		5: _phase_p2_cam()
		6: _phase_p2_prompt()
		7: _phase_p2_launch()
		8: _phase_p2_settle()
		9: _phase_verdict()
		_: _finish()


func _next() -> void:
	_phase += 1
	_run_phase()


# ── Phase 0 ──────────────────────────────────────────────────────────────────
func _phase_p1_cam() -> void:
	_hide_all_hud()
	_fly_camera(CAM_P1_WAIT, 1.8, _next)


# ── Phase 1 ──────────────────────────────────────────────────────────────────
func _phase_p1_prompt() -> void:
	_show_player_header("PLAYER 1", Color(0.2, 0.5, 1.0))
	_show_roll_prompt()
	_start_countdown()


func _on_p1_roll_triggered() -> void:
	if _phase != 1: return
	_stop_countdown()
	_hide_prompt()
	_next()


# ── Phase 2 ──────────────────────────────────────────────────────────────────
func _phase_p1_launch() -> void:
	_die_p1.visible = true
	_die_p1.global_position = P1_SPAWN
	
	# Calculate exactly bounded random position on P1's side of the table
	var dir_to_p1 = Vector3(-35.0, 0.0, 24.0).normalized()
	var perp_p1 = Vector3(-dir_to_p1.z, 0.0, dir_to_p1.x)
	var rand_dist = randf_range(26.0, 32.0)
	var rand_width = randf_range(-12.0, 12.0)
	var new_pos = dir_to_p1 * rand_dist + perp_p1 * rand_width
	
	_p1_actual_settle = Vector3(new_pos.x, P1_SETTLE.y, new_pos.z)
	_launch_die(_die_p1, P1_SPAWN, _p1_actual_settle, _p1_roll, _next)


# ── Phase 3 ──────────────────────────────────────────────────────────────────
func _phase_p1_settle() -> void:
	var cam_target: Dictionary = CAM_P1_ZOOM.duplicate()
	cam_target["focus"] = _p1_actual_settle
	_fly_camera(cam_target, 1.2, func():
		_show_result_number(_p1_roll, Color(0.2, 0.5, 1.0))
		_delay(SETTLE_HOLD_SECONDS, _next)
	)


# ── Phase 4 ──────────────────────────────────────────────────────────────────
func _phase_handoff() -> void:
	_hide_result_number()
	_fade_hud_out(0.3, func():
		_delay(0.4, _next)
	)


# ── Phase 5 ──────────────────────────────────────────────────────────────────
func _phase_p2_cam() -> void:
	_fly_camera(CAM_P2_WAIT, 1.8, _next)


# ── Phase 6 ──────────────────────────────────────────────────────────────────
func _phase_p2_prompt() -> void:
	_show_player_header("PLAYER 2", Color(1.0, 0.3, 0.2))
	_show_roll_prompt()
	_start_countdown()


func _on_p2_roll_triggered() -> void:
	if _phase != 6: return
	_stop_countdown()
	_hide_prompt()
	_next()


# ── Phase 7 ──────────────────────────────────────────────────────────────────
func _phase_p2_launch() -> void:
	_die_p2.visible = true
	_die_p2.global_position = P2_SPAWN
	
	# Calculate exactly bounded random position on P2's side of the table
	var dir_to_p2 = Vector3(35.0, 0.0, -24.0).normalized()
	var perp_p2 = Vector3(-dir_to_p2.z, 0.0, dir_to_p2.x)
	var rand_dist = randf_range(26.0, 32.0)
	var rand_width = randf_range(-12.0, 12.0)
	var new_pos = dir_to_p2 * rand_dist + perp_p2 * rand_width
	
	_p2_actual_settle = Vector3(new_pos.x, P2_SETTLE.y, new_pos.z)
	_launch_die(_die_p2, P2_SPAWN, _p2_actual_settle, _p2_roll, _next)


# ── Phase 8 ──────────────────────────────────────────────────────────────────
func _phase_p2_settle() -> void:
	var cam_target: Dictionary = CAM_P2_ZOOM.duplicate()
	cam_target["focus"] = _p2_actual_settle
	_fly_camera(cam_target, 1.2, func():
		_show_result_number(_p2_roll, Color(1.0, 0.3, 0.2))
		_delay(SETTLE_HOLD_SECONDS, _next)
	)


# ── Phase 9 ──────────────────────────────────────────────────────────────────
func _phase_verdict() -> void:
	_hide_result_number()
	_player_label.visible = false
	_fly_camera(CAM_GAMEPLAY, 1.5, func():
		_show_verdict_panel()
		_delay(VERDICT_HOLD_SECONDS, _finish)
	)


func _finish() -> void:
	_hide_all_hud()
	# Release input lock before signalling game to begin
	if _main and "dice_roll_active" in _main:
		_main.dice_roll_active = false
	_fade_hud_out(0.4, func():
		_cleanup_dice()
		if _main:
			_main.ignore_camera_process = false # Return camera control to player loop
		visible = false
		roll_complete.emit(_first_player)
	)


# =============================================================================
# CAMERA HELPER
# =============================================================================

func _fly_camera(target: Dictionary, duration: float, on_done: Callable) -> void:
	if not _main:
		on_done.call()
		return

	if _cam_tween and _cam_tween.is_running():
		_cam_tween.kill()

	var s_focus: Vector3 = _main.focus_point
	var s_distance: float = _main.camera_distance
	var s_yaw: float = _main.camera_yaw
	var s_pitch: float = _main.camera_pitch

	var t_focus: Vector3 = target.get("focus", Vector3.ZERO)
	var t_distance: float = target.get("distance", 25.0)
	var t_yaw: float = target.get("yaw", 0.0)
	var t_pitch: float = target.get("pitch", 40.0)

	_main.ignore_camera_process = true

	_cam_tween = create_tween()
	_cam_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	_cam_tween.set_parallel(true)
	_cam_tween.tween_method(func(v: Vector3): _main.focus_point = v, s_focus, t_focus, duration)
	_cam_tween.tween_method(func(v: float): _main.camera_distance = v, s_distance, t_distance, duration)
	_cam_tween.tween_method(func(v: float): _main.camera_yaw = v, s_yaw, t_yaw, duration)
	_cam_tween.tween_method(func(v: float): _main.camera_pitch = v, s_pitch, t_pitch, duration)

	_cam_tween.chain().tween_callback(func():
		_main._update_camera_transform()
		on_done.call()
	)


# =============================================================================
# 3-D DIE HELPERS
# =============================================================================

const D20_PATH := "res://assets/models/d20-gold.glb"


func _spawn_dice() -> void:
	_die_p1 = _make_die()
	_die_p1.visible = false
	_main.add_child(_die_p1)

	_die_p2 = _make_die()
	_die_p2.visible = false
	_main.add_child(_die_p2)


func _make_die() -> Node3D:
	var res = load(D20_PATH)
	var die: Node3D = res.instantiate() if res else Node3D.new()
	die.scale = Vector3.ONE * DIE_SCALE
	_reduce_shininess(die, 0.5)
	return die


## Reduce shininess by factor (0.5 = 50% less) across all surfaces.
func _reduce_shininess(node: Node, factor: float) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		for surf in range(mi.get_surface_override_material_count()):
			var orig_mat = mi.mesh.surface_get_material(surf) if mi.mesh else null
			var mat = mi.get_surface_override_material(surf)
			if not mat and orig_mat:
				mat = orig_mat.duplicate()
				mi.set_surface_override_material(surf, mat)
			if mat is StandardMaterial3D:
				var m := mat as StandardMaterial3D
				m.metallic = clamp(m.metallic * (1.0 - factor), 0.0, 1.0)
				m.roughness = clamp(m.roughness + (1.0 - m.roughness) * factor, 0.0, 1.0)
	for child in node.get_children():
		_reduce_shininess(child, factor)


func _launch_die(die: Node3D, from: Vector3, to: Vector3,
		final_roll: int, on_settled: Callable) -> void:
	if _die_tween and _die_tween.is_running():
		_die_tween.kill()
	if _die_spin_tween and _die_spin_tween.is_running():
		_die_spin_tween.kill()

	die.visible = true
	die.global_position = from

	const TRAVEL: float = 1.6
	const BOUNCE_H: float = 3.5

	_die_tween = create_tween()
	_die_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_die_tween.tween_method(func(t: float):
		var base_pos = from.lerp(to, t)
		var drop_height = max(0.0, (from.y - to.y) * (1.0 - t))
		var bounce_arc = abs(sin(t * PI * 2.5)) * (1.0 - t) * BOUNCE_H
		die.global_position = Vector3(base_pos.x, to.y + drop_height + bounce_arc, base_pos.z)
	, 0.0, 1.0, TRAVEL)

	# Calculate exactly how we want to land
	var final_rotation = _face_rotation_for(die, final_roll)
	# Add multiple 360-degree rotations on all axes to simulate a tumble
	# Using random complete spins prevents unnatural linear interpolation
	var spin_rot = final_rotation + Vector3(
		360.0 * randi_range(2, 4), 
		360.0 * randi_range(3, 5), 
		360.0 * randi_range(2, 4)
	)
	
	# Reset starting rotation so the tween actually travels the full distance
	die.rotation_degrees = Vector3.ZERO

	# Tumble spin matching the bounce speed, ending perfectly on the exact target angle minus the full 360s
	_die_spin_tween = create_tween()
	_die_spin_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	_die_spin_tween.tween_property(die, "rotation_degrees", spin_rot, TRAVEL)

	# Resolve
	_die_tween.chain().tween_callback(func():
		_die_spin_tween.kill()
		die.rotation_degrees = final_rotation # mathematically snap to exact floating point (imperceptible)
		on_settled.call()
	)


# Map game roll (1-20) to physical face index (0-19)
# Thanks to the rigorous manual testing, this is now 100% accurate 
# to the paint job wrapped around your specific d20-gold.glb!
var D20_FACE_MAP = {
	1: 19, 2: 1, 3: 13, 4: 8, 5: 12,
	6: 9, 7: 16, 8: 2, 9: 14, 10: 5,
	11: 15, 12: 4, 13: 17, 14: 3, 15: 10,
	16: 7, 17: 11, 18: 6, 19: 18, 20: 0
}

var _cached_normals: Array[Vector3] = []

func _face_rotation_for(die: Node3D, value: int) -> Vector3:
	if _cached_normals.is_empty():
		var mi = die.find_child("*Material*", true, false) as MeshInstance3D
		if not mi: mi = die.find_child("*", true, false) as MeshInstance3D
		
		# Get transform relative to the die root
		var rel_transform = Transform3D.IDENTITY
		var curr = mi
		while curr and curr != die:
			rel_transform = curr.transform * rel_transform
			curr = curr.get_parent()
			
		var faces = mi.mesh.get_faces()
		var normal_areas = {}
		
		# Tally surface area for each unique normal to bypass edge bevels
		for i in range(0, faces.size(), 3):
			var v1 = rel_transform * faces[i]
			var v2 = rel_transform * faces[i+1]
			var v3 = rel_transform * faces[i+2]
			var cross = (v2 - v1).cross(v3 - v1)
			var area = cross.length() / 2.0
			if area < 0.0001: continue
			
			var n = cross.normalized()
			var center = (v1 + v2 + v3) / 3.0
			if n.dot(center) < 0: n = -n
			
			var matched_key = ""
			for k in normal_areas:
				if normal_areas[k].normal.angle_to(n) < 0.1:
					matched_key = k
					break
					
			if matched_key != "":
				normal_areas[matched_key].area += area
			else:
				normal_areas[str(n)] = { "normal": n, "area": area }
				
		var area_list = normal_areas.values()
		area_list.sort_custom(func(a, b): return a.area > b.area)
		
		# The 20 faces with the largest flat area are the true 20 faces
		for i in range(min(20, area_list.size())):
			_cached_normals.append(area_list[i].normal)
			
		# Sort deterministically
		_cached_normals.sort_custom(func(a, b):
			if abs(a.y - b.y) > 0.01: return a.y > b.y
			if abs(a.x - b.x) > 0.01: return a.x > b.x
			return a.z > b.z
		)

	var idx = D20_FACE_MAP.get(value, 0) % max(1, _cached_normals.size())
	print("[DICE] Rolled %s -> Pointing Face Index %d UP" % [value, idx])
	
	var up = _cached_normals[idx]
	var right = Vector3.UP.cross(up).normalized()
	if right.length() < 0.1: right = Vector3.RIGHT
	var fwd = right.cross(up).normalized()
	
	var target_basis = Basis(right, up, fwd).inverse()
	# The normals were extracted using the full relative transform tree, 
	# meaning internal GLTF model quirks are already accounted for mathematically!
	return target_basis.get_euler() * (180.0 / PI)


func _cleanup_dice() -> void:
	if _die_p1: _die_p1.queue_free(); _die_p1 = null
	if _die_p2: _die_p2.queue_free(); _die_p2 = null


# =============================================================================
# HUD — built entirely with UITheme
# =============================================================================

func _build_hud() -> void:
	_hud_root = Control.new()
	_hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hud_root)

	# ── PLAYER 1 / PLAYER 2 header (top-centre) ───────────────────────────
	_player_label = Label.new()
	_player_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_player_label.offset_top = 36
	_player_label.offset_bottom = 112
	_player_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_player_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.style_label(_player_label, 54, UITheme.C_GOLD_BRIGHT, true)
	_hud_root.add_child(_player_label)

	# ── "Press ENTER to roll" prompt (bottom-centre) ───────────────────────
	_prompt_label = Label.new()
	_prompt_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_prompt_label.offset_top = -118
	_prompt_label.offset_bottom = -68
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.style_label(_prompt_label, 24, UITheme.C_WARM_WHITE, false)
	_prompt_label.text = "Press ENTER to roll"
	_hud_root.add_child(_prompt_label)

	# ── Countdown number ───────────────────────────────────────────────────
	_countdown_label = Label.new()
	_countdown_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_countdown_label.offset_top = -66
	_countdown_label.offset_bottom = -10
	_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.style_label(_countdown_label, 38, UITheme.C_GOLD, true)
	_hud_root.add_child(_countdown_label)

	# ── Result roll number (large, bottom) ────────────────────────────────
	_result_label = Label.new()
	_result_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_result_label.offset_top = -190
	_result_label.offset_bottom = -20
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.style_label(_result_label, 100, UITheme.C_GOLD_BRIGHT, true)
	_hud_root.add_child(_result_label)

	# ── Verdict panel (centred overlay) ───────────────────────────────────
	_verdict_panel = _build_verdict_panel()
	_hud_root.add_child(_verdict_panel)

	_hide_all_hud()


func _build_verdict_panel() -> Control:
	# Outer wrapper — full rect so we can centre the inner panel
	var wrapper = Control.new()
	wrapper.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel = PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -340
	panel.offset_right = 340
	panel.offset_top = -145
	panel.offset_bottom = 145
	# Use UITheme overlay panel (gold border, dark bg)
	panel.add_theme_stylebox_override("panel", UITheme.overlay_panel(UITheme.C_GOLD))
	wrapper.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", UITheme.PAD)
	margin.add_theme_constant_override("margin_right", UITheme.PAD)
	margin.add_theme_constant_override("margin_top", UITheme.PAD_SM)
	margin.add_theme_constant_override("margin_bottom", UITheme.PAD_SM)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	# Score row: P1   17   VS   9   P2
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	vbox.add_child(row)

	var p1_tag = Label.new()
	UITheme.style_label(p1_tag, 30, Color(0.2, 0.5, 1.0), true)
	p1_tag.text = "P1"
	row.add_child(p1_tag)

	var p1_val = Label.new()
	p1_val.name = "P1Value"
	p1_val.custom_minimum_size = Vector2(88, 0)
	p1_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(p1_val, 68, Color(0.2, 0.5, 1.0), true)
	row.add_child(p1_val)

	var vs_lbl = Label.new()
	UITheme.style_label(vs_lbl, 24, UITheme.C_WARM_WHITE, false)
	vs_lbl.text = "VS"
	row.add_child(vs_lbl)

	var p2_val = Label.new()
	p2_val.name = "P2Value"
	p2_val.custom_minimum_size = Vector2(88, 0)
	p2_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(p2_val, 68, Color(1.0, 0.3, 0.2), true)
	row.add_child(p2_val)

	var p2_tag = Label.new()
	UITheme.style_label(p2_tag, 30, Color(1.0, 0.3, 0.2), true)
	p2_tag.text = "P2"
	row.add_child(p2_tag)

	var sep = UITheme.make_separator()
	var sep_style = StyleBoxFlat.new()
	sep_style.bg_color = UITheme.C_GOLD
	sep_style.set_content_margin_all(1)
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	# Winner label
	var winner_lbl = Label.new()
	winner_lbl.name = "WinnerLabel"
	winner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(winner_lbl, 30, UITheme.C_GOLD_BRIGHT, true)
	vbox.add_child(winner_lbl)

	wrapper.visible = false
	return wrapper


# =============================================================================
# HUD HELPERS
# =============================================================================

func _hide_all_hud() -> void:
	for n in [_player_label, _prompt_label, _countdown_label, _result_label, _verdict_panel]:
		if n: n.visible = false


func _show_player_header(text: String, color: Color) -> void:
	_player_label.text = text
	_player_label.add_theme_color_override("font_color", color)
	_player_label.modulate.a = 0.0
	_player_label.visible = true
	_fade_in(_player_label, 0.35)


func _show_roll_prompt() -> void:
	_prompt_label.modulate.a = 0.0
	_prompt_label.visible = true
	_fade_in(_prompt_label, 0.30)
	_waiting_input = true


func _hide_prompt() -> void:
	_waiting_input = false
	_prompt_label.visible = false
	_countdown_label.visible = false


func _show_result_number(value: int, color: Color) -> void:
	_result_label.text = str(value)
	_result_label.add_theme_color_override("font_color", color)
	_result_label.modulate = Color(1, 1, 1, 0)
	_result_label.scale = Vector2(0.55, 0.55)
	_result_label.visible = true
	var t = create_tween().set_parallel(true)
	t.tween_property(_result_label, "modulate:a", 1.0, 0.22)
	t.tween_property(_result_label, "scale", Vector2(1, 1), 0.35) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _hide_result_number() -> void:
	_result_label.visible = false


func _show_verdict_panel() -> void:
	var p1v = _verdict_panel.find_child("P1Value", true, false) as Label
	var p2v = _verdict_panel.find_child("P2Value", true, false) as Label
	var wlb = _verdict_panel.find_child("WinnerLabel", true, false) as Label

	if p1v:
		p1v.text = str(_p1_roll)
		p1v.add_theme_color_override("font_color", Color(0.2, 0.5, 1.0))
	if p2v:
		p2v.text = str(_p2_roll)
		p2v.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
	if wlb:
		var wname = "PLAYER 1" if _first_player == 0 else "PLAYER 2"
		wlb.text = "%s GOES FIRST" % wname
		wlb.add_theme_color_override("font_color", UITheme.C_GOLD_BRIGHT)

	_verdict_panel.modulate.a = 0.0
	_verdict_panel.visible = true
	_fade_in(_verdict_panel, 0.45)


func _fade_in(node: CanvasItem, dur: float) -> void:
	create_tween().tween_property(node, "modulate:a", 1.0, dur) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _fade_hud_out(dur: float, on_done: Callable) -> void:
	var t = create_tween()
	t.tween_property(_hud_root, "modulate:a", 0.0, dur)
	t.tween_callback(func():
		_hud_root.modulate.a = 1.0
		_hide_all_hud()
		on_done.call()
	)


# =============================================================================
# COUNTDOWN
# =============================================================================

func _start_countdown() -> void:
	_countdown_val = COUNTDOWN_SECONDS
	_countdown_label.text = str(int(ceil(_countdown_val)))
	_countdown_label.modulate.a = 0.0
	_countdown_label.visible = true
	_fade_in(_countdown_label, 0.2)
	_countdown_active = true

	if _countdown_timer:
		_countdown_timer.queue_free()
	_countdown_timer = Timer.new()
	_countdown_timer.wait_time = 0.1
	_countdown_timer.one_shot = false
	_countdown_timer.timeout.connect(_on_countdown_tick)
	add_child(_countdown_timer)
	_countdown_timer.start()


func _on_countdown_tick() -> void:
	if not _countdown_active: return
	_countdown_val -= 0.1
	_countdown_label.text = str(max(0, int(ceil(_countdown_val))))
	if _countdown_val <= 0.0:
		_stop_countdown()
		if _phase == 1: _on_p1_roll_triggered()
		elif _phase == 6: _on_p2_roll_triggered()


func _stop_countdown() -> void:
	_countdown_active = false
	if _countdown_timer:
		_countdown_timer.stop()
		_countdown_timer.queue_free()
		_countdown_timer = null


# =============================================================================
# UTILITY
# =============================================================================

func _delay(seconds: float, on_done: Callable) -> void:
	get_tree().create_timer(seconds).timeout.connect(on_done, CONNECT_ONE_SHOT)


# =============================================================================
# INPUT — block everything except ESC and ENTER during the sequence
# =============================================================================

func _input(event: InputEvent) -> void:
	if not visible: return

	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			# Always let ESC through (pause menu)
			return
		# ENTER triggers roll during prompt phases
		if event.pressed and not event.echo:
			if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
				get_viewport().set_input_as_handled()
				if _waiting_input:
					if _phase == 1: _on_p1_roll_triggered()
					elif _phase == 6: _on_p2_roll_triggered()
				return
		# Consume every other key (WASD, Space, V, F, number keys, etc.)
		get_viewport().set_input_as_handled()
		return

	# Block all mouse clicks and scroll during the cinematic
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()


# =============================================================================
# PAUSE HANDLING
# =============================================================================

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PAUSED:
			_on_game_paused()
		NOTIFICATION_UNPAUSED:
			_on_game_unpaused()


func _on_game_paused() -> void:
	if not visible: return
	
	# Cache die visibility to restore later
	_p1_die_visible_before_pause = _die_p1.visible if _die_p1 else false
	_p2_die_visible_before_pause = _die_p2.visible if _die_p2 else false
	
	# Hide everything
	_hud_root.visible = false
	if _die_p1: _die_p1.visible = false
	if _die_p2: _die_p2.visible = false
	
	print("[FirstMoveDiceUI] Paused cinematic")


func _on_game_unpaused() -> void:
	if not visible: return
	
	# Restore HUD visibility
	_hud_root.visible = true
	
	# Restore dice visibility based on which one was active
	if _die_p1: _die_p1.visible = _p1_die_visible_before_pause
	if _die_p2: _die_p2.visible = _p2_die_visible_before_pause
	
	print("[FirstMoveDiceUI] Resumed cinematic")
