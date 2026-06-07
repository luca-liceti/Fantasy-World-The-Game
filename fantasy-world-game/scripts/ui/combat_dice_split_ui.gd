## CombatDiceSplitUI — Split-screen 3D dice roll sequence
##
## Replaces the old DiceUI popup panel. When called, it:
##  1. Splits the viewport 50/50 with two SubViewports
##  2. Spawns one 3D d20 on each player's side of the table
##  3. Both dice tumble simultaneously
##  4. Each half shows the roll math once the die settles
##  5. A full-width result banner fades in at the bottom
##  6. Auto-advances after RESULT_HOLD_SECONDS (skip with any key/click)
##
## Public API:
##   show_combat_roll(...)     — start the sequence
##   signal roll_complete()    — emitted when sequence finishes
##
## Setup:
##   Call set_main(main_node) once after creating this node.
class_name CombatDiceSplitUI
extends CanvasLayer

# =============================================================================
# SIGNALS
# =============================================================================
signal roll_complete()

# =============================================================================
# CONSTANTS
# =============================================================================
const ROLL_DURATION       : float = 1.6   # seconds for dice to tumble and settle
const RESULT_HOLD_SECONDS : float = 2.5   # seconds to show result before auto-advancing
const OVERHEAD_PITCH      : float = 88.0  # near-top-down camera pitch
const OVERHEAD_DIST       : float = 5.5   # camera distance for top-down close-up
const DIE_SCALE           : float = 1.95

const D20_PATH := "res://assets/props/dice/d20_gold/d20_gold.glb"

## Die spawn corners (outer board edges)
const P1_SPAWN  := Vector3(-35.0,  4.0,  24.0)
const P2_SPAWN  := Vector3( 35.0,  4.0, -24.0)

## Die settle zones (mid-table, each player's side)
const P1_SETTLE := Vector3(-18.0,  1.3,  10.0)
const P2_SETTLE := Vector3( 18.0,  1.3, -10.0)

## Face map: game roll (1-20) → physical face index
const D20_FACE_MAP := {
	1: 19, 2: 1,  3: 13, 4: 8,  5: 12,
	6: 9,  7: 16, 8: 2,  9: 14, 10: 5,
	11: 15, 12: 4, 13: 17, 14: 3, 15: 10,
	16: 7, 17: 11, 18: 6, 19: 18, 20: 0
}

# =============================================================================
# COLOUR TOKENS
# =============================================================================
const C_HIT      := Color(0.25, 0.88, 0.30)
const C_MISS     := Color(0.88, 0.25, 0.25)
const C_CRIT     := Color(1.00, 0.88, 0.20)
const C_ENDURE   := Color(0.85, 0.20, 0.20)
const C_COUNTER  := Color(0.95, 0.55, 0.10)
const C_STATUS   := Color(0.75, 0.50, 0.95)
const C_DIVIDER  := Color(0.88, 0.76, 0.44, 0.45)
const C_PANEL_BG := Color(0.0,  0.0,  0.0,  0.78)

# =============================================================================
# EXTERNAL REF
# =============================================================================
var _main : Node3D = null

func set_main(main_node: Node3D) -> void:
	_main = main_node
	if _vp_p1:
		_vp_p1.world_3d = _main.get_world_3d()
	if _vp_p2:
		_vp_p2.world_3d = _main.get_world_3d()

# =============================================================================
# INTERNAL STATE
# =============================================================================
var _die_p1        : Node3D = null
var _die_p2        : Node3D = null
var _p1_settle_pos : Vector3
var _p2_settle_pos : Vector3

var _active_tweens : Array[Tween] = []
var _cam_tween     : Tween = null

var _cached_normals: Array[Vector3] = []

var _hold_timer    : float = 0.0
var _holding       : bool  = false
var _sequence_done : bool  = false

var _saved_cam     : Dictionary = {}

# =============================================================================
# UI NODES
# =============================================================================
var _root          : Control         # root node for fading the entire UI
var _vp_p1         : SubViewport
var _vp_p2         : SubViewport
var _cam_p1        : Camera3D
var _cam_p2        : Camera3D

var _label_p1      : Label           # "PLAYER 1" half label
var _label_p2      : Label           # "PLAYER 2" half label
var _roll_lbl_p1   : Label           # "🎲 17 + 8 = 25" per half
var _roll_lbl_p2   : Label

var _divider       : ColorRect       # vertical gold line in centre

var _result_panel  : PanelContainer  # full-width bottom banner
var _result_label  : Label
var _sub_label     : Label           # secondary line (status, counter, endure)


# =============================================================================
# READY
# =============================================================================

func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()


func _build_ui() -> void:
	# ── Root control ──────────────────────────────────────────────────────────
	var root = Control.new()
	_root = root
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# ── Left SubViewport (Player 1) ───────────────────────────────────────────
	var container_p1 = SubViewportContainer.new()
	container_p1.anchor_left   = 0.0
	container_p1.anchor_top    = 0.0
	container_p1.anchor_right  = 0.5
	container_p1.anchor_bottom = 1.0
	container_p1.stretch = true
	container_p1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(container_p1)

	_vp_p1 = SubViewport.new()
	_vp_p1.transparent_bg = true
	container_p1.add_child(_vp_p1)

	_cam_p1 = Camera3D.new()
	_vp_p1.add_child(_cam_p1)

	# ── Right SubViewport (Player 2) ──────────────────────────────────────────
	var container_p2 = SubViewportContainer.new()
	container_p2.anchor_left   = 0.5
	container_p2.anchor_top    = 0.0
	container_p2.anchor_right  = 1.0
	container_p2.anchor_bottom = 1.0
	container_p2.stretch = true
	container_p2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(container_p2)

	_vp_p2 = SubViewport.new()
	_vp_p2.transparent_bg = true
	container_p2.add_child(_vp_p2)

	_cam_p2 = Camera3D.new()
	_vp_p2.add_child(_cam_p2)

	# ── Gold vertical divider ─────────────────────────────────────────────────
	_divider = ColorRect.new()
	_divider.anchor_left   = 0.5
	_divider.anchor_top    = 0.0
	_divider.anchor_right  = 0.5
	_divider.anchor_bottom = 1.0
	_divider.offset_left   = -1
	_divider.offset_right  =  1
	_divider.color         = C_DIVIDER
	_divider.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	root.add_child(_divider)

	# ── Player labels (top of each half) ─────────────────────────────────────
	_label_p1 = _make_half_label("PLAYER 1", Color(0.25, 0.55, 1.0), false)
	root.add_child(_label_p1)

	_label_p2 = _make_half_label("PLAYER 2", Color(1.00, 0.32, 0.22), true)
	root.add_child(_label_p2)

	# ── Roll math labels (bottom centre of each half) ─────────────────────────
	_roll_lbl_p1 = _make_roll_label(false)
	root.add_child(_roll_lbl_p1)

	_roll_lbl_p2 = _make_roll_label(true)
	root.add_child(_roll_lbl_p2)

	# ── Result banner (full width, lower third) ───────────────────────────────
	_result_panel = PanelContainer.new()
	_result_panel.anchor_left   = 0.1
	_result_panel.anchor_right  = 0.9
	_result_panel.anchor_top    = 0.72
	_result_panel.anchor_bottom = 0.92
	_result_panel.mouse_filter  = Control.MOUSE_FILTER_IGNORE

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = C_PANEL_BG
	panel_style.border_color = Color(0.88, 0.76, 0.44, 0.6)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(14)
	_result_panel.add_theme_stylebox_override("panel", panel_style)
	root.add_child(_result_panel)

	var result_vbox = VBoxContainer.new()
	result_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	result_vbox.add_theme_constant_override("separation", 8)
	_result_panel.add_child(result_vbox)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",  24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top",   16)
	margin.add_theme_constant_override("margin_bottom",16)
	result_vbox.add_child(margin)

	var inner = VBoxContainer.new()
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 6)
	margin.add_child(inner)

	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(_result_label, 34, UITheme.C_WARM_WHITE, true)
	inner.add_child(_result_label)

	_sub_label = Label.new()
	_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_label.visible = false
	UITheme.style_label(_sub_label, 18, UITheme.C_WARM_WHITE)
	inner.add_child(_sub_label)


func _make_half_label(text: String, color: Color, right_half: bool) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.anchor_top    = 0.04
	lbl.anchor_bottom = 0.12
	if right_half:
		lbl.anchor_left  = 0.5
		lbl.anchor_right = 1.0
	else:
		lbl.anchor_left  = 0.0
		lbl.anchor_right = 0.5
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.style_label(lbl, 18, color, true)
	return lbl


func _make_roll_label(right_half: bool) -> Label:
	var lbl = Label.new()
	lbl.text = ""
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.anchor_top    = 0.60
	lbl.anchor_bottom = 0.70
	if right_half:
		lbl.anchor_left  = 0.5
		lbl.anchor_right = 1.0
	else:
		lbl.anchor_left  = 0.0
		lbl.anchor_right = 0.5
	lbl.visible = false
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.style_label(lbl, 20, UITheme.C_GOLD, true)
	return lbl


# =============================================================================
# PUBLIC ENTRY POINT
# =============================================================================

## Start the full split-screen dice roll sequence.
## atk_natural  : the raw d20 roll for the attacker
## atk_stat     : attacker's ATK modifier added to the roll
## atk_total    : atk_natural + atk_stat
## def_dc       : the defence difficulty class (10 + DEF)
## def_roll     : the defender's natural d20 roll (for display)
func show_combat_roll(
		attacker_name   : String,
		defender_name   : String,
		atk_natural     : int,
		atk_stat        : int,
		atk_total       : int,
		def_dc          : int,
		def_roll        : int,
		attack_succeeded: bool,
		damage          : int,
		is_critical     : bool,
		result          : Dictionary = {}
) -> void:
	if visible:
		return   # already running

	_sequence_done = false
	_holding       = false
	_hold_timer    = 0.0

	_reset_labels()

	# Save camera state
	if _main:
		_saved_cam = {
			"focus"   : _main.focus_point,
			"distance": _main.camera_distance,
			"yaw"     : _main.camera_yaw,
			"pitch"   : _main.camera_pitch
		}

	# Show UI
	visible = true

	# Spawn dice
	_spawn_dice()

	# Calculate random settle positions within each player's zone
	_p1_settle_pos = _random_settle(P1_SETTLE, Vector3(-35, 0, 24).normalized())
	_p2_settle_pos = _random_settle(P2_SETTLE, Vector3( 35, 0,-24).normalized())

	# Position overhead cameras
	_aim_camera(_cam_p1, _p1_settle_pos)
	_aim_camera(_cam_p2, _p2_settle_pos)

	# Add dice to main scene FIRST before setting position
	if _main:
		_main.add_child(_die_p1)
		_main.add_child(_die_p2)

	_die_p1.global_position = P1_SPAWN
	_die_p2.global_position = P2_SPAWN

	# Launch both dice simultaneously
	_launch_die(_die_p1, P1_SPAWN, _p1_settle_pos, atk_natural)
	_launch_die(_die_p2, P2_SPAWN, _p2_settle_pos, def_roll)

	# After dice settle → show roll math → show result banner
	await get_tree().create_timer(ROLL_DURATION + 0.1).timeout
	if _sequence_done: return

	# Roll math labels
	_roll_lbl_p1.text = "🎲  %d + %d  =  %d" % [atk_natural, atk_stat, atk_total]
	_roll_lbl_p2.text = "🛡️  DC  %d" % def_dc
	_roll_lbl_p1.visible = true
	_roll_lbl_p2.visible = true
	_fade_in_node(_roll_lbl_p1, 0.3)
	_fade_in_node(_roll_lbl_p2, 0.3)

	await get_tree().create_timer(0.5).timeout
	if _sequence_done: return

	# Build result text
	_populate_result(attack_succeeded, damage, is_critical, result)
	_result_panel.modulate.a = 0.0
	_result_panel.visible    = true
	_fade_in_node(_result_panel, 0.45)

	# Hold then auto-advance
	_holding    = true
	_hold_timer = RESULT_HOLD_SECONDS


# =============================================================================
# PROCESS — hold countdown + skip input
# =============================================================================

func _process(delta: float) -> void:
	if not _holding:
		return

	_hold_timer -= delta
	if _hold_timer <= 0.0:
		_finish()


func _input(event: InputEvent) -> void:
	if not visible or _sequence_done:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode != KEY_ESCAPE:
			_finish()
	elif event is InputEventMouseButton and event.pressed:
		_finish()


# =============================================================================
# RESULT TEXT
# =============================================================================

func _populate_result(attack_succeeded: bool, damage: int, is_critical: bool,
		result: Dictionary) -> void:

	var sub_parts: Array[String] = []

	if not attack_succeeded:
		_result_label.text = "✗  Missed"
		_result_label.add_theme_color_override("font_color", C_MISS)
	elif is_critical:
		_result_label.text = "⚡  Critical Hit!  — %d damage" % damage
		_result_label.add_theme_color_override("font_color", C_CRIT)
	else:
		_result_label.text = "✓  Hit  — %d damage" % damage
		_result_label.add_theme_color_override("font_color", C_HIT)

	# Effectiveness
	var eff = result.get("type_effectiveness", 1.0)
	if eff >= 1.5:
		sub_parts.append("✨ Super Effective!")
	elif eff == 0.0:
		sub_parts.append("🛡️ Immune")
	elif eff <= 0.5:
		sub_parts.append("↓ Resisted")

	# Status applied
	var status = result.get("status_applied", "")
	if status != "":
		var eff_data = StatusEffects.get_effect_data(status)
		var name_str = eff_data.get("effect_name", status)
		sub_parts.append("💫 %s applied!" % name_str)

	# Endure
	if result.get("survived_lethal", false):
		sub_parts.append("💪 Endured at 1 HP!")

	# Counter
	var counter_dmg = result.get("counter_damage", 0)
	if counter_dmg > 0:
		sub_parts.append("↩️ Counter! %d damage back" % counter_dmg)

	# Defender killed
	if result.get("defender_killed", false):
		sub_parts.append("💀 Defeated!")

	if not sub_parts.is_empty():
		_sub_label.text    = "  ·  ".join(sub_parts)
		_sub_label.visible = true
	else:
		_sub_label.visible = false


# =============================================================================
# CLEANUP + FINISH
# =============================================================================

func _finish() -> void:
	if _sequence_done:
		return
	_sequence_done = true
	_holding       = false

	# Fade out the whole layer
	var tw = create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, 0.35)
	tw.tween_callback(_cleanup)


func _cleanup() -> void:
	visible = false
	if _root:
		_root.modulate.a = 1.0

	for tw in _active_tweens:
		if tw and tw.is_valid():
			tw.kill()
	_active_tweens.clear()

	# Free dice from scene
	if _die_p1 and is_instance_valid(_die_p1):
		_die_p1.queue_free()
		_die_p1 = null
	if _die_p2 and is_instance_valid(_die_p2):
		_die_p2.queue_free()
		_die_p2 = null

	# Cameras stay in their SubViewports, no need to free them.

	_restore_camera()
	_reset_labels()
	_cached_normals.clear()

	roll_complete.emit()


func _reset_labels() -> void:
	_roll_lbl_p1.visible = false
	_roll_lbl_p2.visible = false
	_roll_lbl_p1.text    = ""
	_roll_lbl_p2.text    = ""
	_result_panel.visible = false
	_sub_label.visible   = false


# =============================================================================
# 3D DIE HELPERS
# =============================================================================

func _spawn_dice() -> void:
	var res = load(D20_PATH)
	_die_p1 = res.instantiate() if res else Node3D.new()
	_die_p1.scale = Vector3.ONE * DIE_SCALE
	_reduce_shininess(_die_p1, 0.5)

	_die_p2 = res.instantiate() if res else Node3D.new()
	_die_p2.scale = Vector3.ONE * DIE_SCALE
	_reduce_shininess(_die_p2, 0.5)


func _random_settle(base: Vector3, dir: Vector3) -> Vector3:
	var perp = Vector3(-dir.z, 0, dir.x)
	var dist = randf_range(26.0, 32.0)
	var width = randf_range(-10.0, 10.0)
	var pos = dir * dist + perp * width
	return Vector3(pos.x, base.y, pos.z)


func _launch_die(die: Node3D, from: Vector3, to: Vector3, roll_value: int) -> void:
	const TRAVEL : float = ROLL_DURATION
	const ARC_H  : float = 3.0

	var pos_tween = create_tween()
	pos_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	pos_tween.tween_method(func(t: float):
		if not is_instance_valid(die): return
		var base = from.lerp(to, t)
		var drop = max(0.0, (from.y - to.y) * (1.0 - t))
		var arc  = abs(sin(t * PI * 2.5)) * (1.0 - t) * ARC_H
		die.global_position = Vector3(base.x, to.y + drop + arc, base.z)
	, 0.0, 1.0, TRAVEL)

	var final_rot = _face_rotation_for(die, roll_value)
	var spin_rot  = final_rot + Vector3(
		360.0 * randi_range(2, 4),
		360.0 * randi_range(3, 5),
		360.0 * randi_range(2, 4)
	)
	die.rotation_degrees = Vector3.ZERO

	var s_tween = create_tween()
	s_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	s_tween.tween_property(die, "rotation_degrees", spin_rot, TRAVEL)
	s_tween.tween_callback(func():
		if is_instance_valid(die):
			die.rotation_degrees = final_rot
	)

	_active_tweens.append(pos_tween)
	_active_tweens.append(s_tween)


func _aim_camera(cam: Camera3D, target: Vector3) -> void:
	# Position camera directly above the die, looking straight down
	var cam_pos = target + Vector3(0, OVERHEAD_DIST, 0)
	cam.global_position = cam_pos
	cam.look_at(target, Vector3(0, 0, -1))


func _face_rotation_for(die: Node3D, value: int) -> Vector3:
	if _cached_normals.is_empty():
		var mi = die.find_child("*Material*", true, false) as MeshInstance3D
		if not mi:
			mi = die.find_child("*", true, false) as MeshInstance3D
		if not mi:
			return Vector3.ZERO

		var rel = Transform3D.IDENTITY
		var curr = mi
		while curr and curr != die:
			rel = curr.transform * rel
			curr = curr.get_parent()

		var faces = mi.mesh.get_faces()
		var normal_areas : Dictionary = {}

		for i in range(0, faces.size(), 3):
			var v1 = rel * faces[i]
			var v2 = rel * faces[i + 1]
			var v3 = rel * faces[i + 2]
			var cross = (v2 - v1).cross(v3 - v1)
			var area  = cross.length() / 2.0
			if area < 0.0001:
				continue
			var n = cross.normalized()
			var center = (v1 + v2 + v3) / 3.0
			if n.dot(center) < 0:
				n = -n
			var matched = ""
			for k in normal_areas:
				if normal_areas[k].normal.angle_to(n) < 0.1:
					matched = k
					break
			if matched != "":
				normal_areas[matched].area += area
			else:
				normal_areas[str(n)] = {"normal": n, "area": area}

		var area_list = normal_areas.values()
		area_list.sort_custom(func(a, b): return a.area > b.area)
		for i in range(min(20, area_list.size())):
			_cached_normals.append(area_list[i].normal)
		_cached_normals.sort_custom(func(a, b):
			if abs(a.y - b.y) > 0.01: return a.y > b.y
			if abs(a.x - b.x) > 0.01: return a.x > b.x
			return a.z > b.z
		)

	var idx = D20_FACE_MAP.get(value, 0) % max(1, _cached_normals.size())
	var up    = _cached_normals[idx]
	var right = Vector3.UP.cross(up).normalized()
	if right.length() < 0.1:
		right = Vector3.RIGHT
	var fwd = right.cross(up).normalized()
	var basis = Basis(right, up, fwd).inverse()
	return basis.get_euler() * (180.0 / PI)


func _reduce_shininess(node: Node, factor: float) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		for surf in range(mi.get_surface_override_material_count()):
			var orig = mi.mesh.surface_get_material(surf) if mi.mesh else null
			var mat  = mi.get_surface_override_material(surf)
			if not mat and orig:
				mat = orig.duplicate()
				mi.set_surface_override_material(surf, mat)
			if mat is StandardMaterial3D:
				var m := mat as StandardMaterial3D
				m.metallic  = clamp(m.metallic  * (1.0 - factor), 0.0, 1.0)
				m.roughness = clamp(m.roughness + (1.0 - m.roughness) * factor, 0.0, 1.0)
	for child in node.get_children():
		_reduce_shininess(child, factor)


# =============================================================================
# CAMERA RESTORE
# =============================================================================

func _restore_camera() -> void:
	if not _main or _saved_cam.is_empty():
		return

	var s := _saved_cam
	_main.ignore_camera_process = true
	var tw = create_tween()
	tw.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.set_parallel(true)
	tw.tween_method(func(v: Vector3): _main.focus_point     = v,
		_main.focus_point,    s.get("focus",    Vector3.ZERO), 0.6)
	tw.tween_method(func(v: float):   _main.camera_distance = v,
		_main.camera_distance, s.get("distance", 25.0),         0.6)
	tw.tween_method(func(v: float):   _main.camera_yaw      = v,
		_main.camera_yaw,     s.get("yaw",      0.0),           0.6)
	tw.tween_method(func(v: float):   _main.camera_pitch    = v,
		_main.camera_pitch,   s.get("pitch",    35.0),          0.6)
	tw.chain().tween_callback(func():
		_main._update_camera_transform()
		_main.ignore_camera_process = false
	)


# =============================================================================
# ANIMATION HELPERS
# =============================================================================

func _fade_in_node(node: CanvasItem, duration: float) -> void:
	node.modulate.a = 0.0
	create_tween().tween_property(node, "modulate:a", 1.0, duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
