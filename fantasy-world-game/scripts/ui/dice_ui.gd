## Dice UI — 3D d20 combat roll display
## Replaces the flat number-based combat dice overlay with a 3D d20 sequence.
##
## Flow:
##   show_combat()      → reveals the overlay panel (attacker vs defender)
##   start_roll()       → spawns & launches the 3D die on the table near the combatants
##   show_result()      → stops die, zooms in, displays result; emits roll_animation_complete
##   Player can dismiss → hide_dice() emits dice_dismissed
##
## External setup:
##   Call set_camera(camera, main_node) once after creating this node.
class_name DiceUI
extends CanvasLayer

# =============================================================================
# SIGNALS
# =============================================================================
signal roll_animation_complete()
signal dice_dismissed()

# =============================================================================
# CONSTANTS
# =============================================================================
const ROLL_DURATION   : float = 1.5
const CRITICAL_THRESHOLD : int = 18

## 3D die scale (same as first-move sequence)
const DIE_SCALE : float = 1.95

## Combat die spawns on the near-right corner and settles near the attacker
const COMBAT_DIE_SPAWN  := Vector3(16.0, 4.0, 16.0)
const COMBAT_DIE_SETTLE := Vector3( 4.0, 1.3,  4.0)

## Camera zoom in for combat result
const CAM_COMBAT_ZOOM := {
	"pitch"   : 65.0,
	"yaw"     : 60.0,
	"distance":  8.0,
	"focus"   : Vector3(4.0, 0.0, 4.0)
}

# =============================================================================
# UI ELEMENTS
# =============================================================================
var main_panel       : PanelContainer
var content_container: VBoxContainer

# Header
var title_label   : Label
var subtitle_label: Label

# Dice display panels
var dice_container      : HBoxContainer
var attacker_dice_panel : PanelContainer
var defender_dice_panel : PanelContainer
var attacker_value_label: Label
var defender_value_label: Label
var attacker_stat_label : Label
var defender_stat_label : Label
var attacker_total_label: Label
var defender_total_label: Label

# Result
var result_label : Label
var damage_label : Label
var vs_label     : Label
var reroll_label : Label

# =============================================================================
# EXTERNAL REFS
# =============================================================================
var _camera : Camera3D = null
var _main   : Node3D   = null

# =============================================================================
# INTERNAL STATE
# =============================================================================
var tween              : Tween
var roll_timer         : Timer
var is_rolling         : bool  = false
var current_attacker_display : int = 1
var current_defender_display : int = 1
var final_attacker_roll      : int = 0
var final_defender_roll      : int = 0
var attacker_stat : int = 0
var defender_stat : int = 0

var _combat_die    : Node3D = null
var _die_tween     : Tween
var _die_spin_tween: Tween
var _cam_tween     : Tween
var _saved_cam     : Dictionary = {}   # snapshot for restore

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_create_ui()
	hide_immediate()


func set_camera(camera: Camera3D, main_node: Node3D) -> void:
	_camera = camera
	_main   = main_node


func _create_ui() -> void:
	# Darkened overlay
	var overlay = UITheme.make_overlay_bg()
	overlay.color = Color(0, 0, 0, 0.65)
	add_child(overlay)

	# Main centred panel
	main_panel = PanelContainer.new()
	main_panel.anchor_left   = 0.5
	main_panel.anchor_top    = 0.5
	main_panel.anchor_right  = 0.5
	main_panel.anchor_bottom = 0.5
	main_panel.offset_left   = -280
	main_panel.offset_top    = -230
	main_panel.offset_right  =  280
	main_panel.offset_bottom =  230
	main_panel.custom_minimum_size = Vector2(560, 460)
	main_panel.pivot_offset  = Vector2(280, 230)
	add_child(main_panel)

	main_panel.add_theme_stylebox_override("panel", UITheme.overlay_panel(UITheme.C_GOLD))

	# Content
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   UITheme.PAD)
	margin.add_theme_constant_override("margin_right",  UITheme.PAD)
	margin.add_theme_constant_override("margin_top",    UITheme.PAD_SM)
	margin.add_theme_constant_override("margin_bottom", UITheme.PAD_SM)
	main_panel.add_child(margin)

	content_container = VBoxContainer.new()
	content_container.add_theme_constant_override("separation", 14)
	content_container.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(content_container)

	_create_header()
	_create_dice_display()
	_create_result_display()

	roll_timer = Timer.new()
	roll_timer.one_shot = false
	roll_timer.timeout.connect(_on_roll_timer_tick)
	add_child(roll_timer)


func _create_header() -> void:
	title_label = Label.new()
	title_label.text = "⚔️  COMBAT  ⚔️"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(title_label, 28, UITheme.C_GOLD_BRIGHT, true)
	content_container.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.text = "Attacker vs Defender"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(subtitle_label, 16, UITheme.C_WARM_WHITE)
	content_container.add_child(subtitle_label)

	content_container.add_child(UITheme.make_separator())


func _create_dice_display() -> void:
	dice_container = HBoxContainer.new()
	dice_container.alignment = BoxContainer.ALIGNMENT_CENTER
	dice_container.add_theme_constant_override("separation", 36)
	content_container.add_child(dice_container)

	attacker_dice_panel = _create_dice_panel("ATTACKER", Color(0.9, 0.35, 0.2))
	dice_container.add_child(attacker_dice_panel)

	vs_label = Label.new()
	vs_label.text = "VS"
	vs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(vs_label, 26, UITheme.C_GOLD)
	dice_container.add_child(vs_label)

	defender_dice_panel = _create_dice_panel("DEFENDER", Color(0.2, 0.55, 1.0))
	dice_container.add_child(defender_dice_panel)

	reroll_label = Label.new()
	reroll_label.text = ""
	reroll_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(reroll_label, 18, Color(1.0, 0.6, 0.2))
	reroll_label.visible = false
	content_container.add_child(reroll_label)


func _create_dice_panel(label_text: String, color: Color) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(165, 190)
	panel.add_theme_stylebox_override("panel", UITheme.section_panel(color))

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)

	var inner = MarginContainer.new()
	inner.add_theme_constant_override("margin_left",   14)
	inner.add_theme_constant_override("margin_right",  14)
	inner.add_theme_constant_override("margin_top",    12)
	inner.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(inner)
	inner.add_child(vbox)

	var role_lbl = Label.new()
	role_lbl.text = label_text
	role_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(role_lbl, 14, color, true)
	vbox.add_child(role_lbl)

	var value_lbl = Label.new()
	value_lbl.text = "?"
	value_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_lbl.custom_minimum_size = Vector2(80, 60)
	UITheme.style_label(value_lbl, 52, UITheme.C_WARM_WHITE, true)
	vbox.add_child(value_lbl)

	var stat_lbl = Label.new()
	stat_lbl.text = "+ ATK 0"
	stat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(stat_lbl, 13, UITheme.C_DIM)
	vbox.add_child(stat_lbl)

	var total_lbl = Label.new()
	total_lbl.text = "= 0"
	total_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(total_lbl, 22, color, true)
	vbox.add_child(total_lbl)

	if label_text == "ATTACKER":
		attacker_value_label = value_lbl
		attacker_stat_label  = stat_lbl
		attacker_total_label = total_lbl
	else:
		defender_value_label = value_lbl
		defender_stat_label  = stat_lbl
		defender_total_label = total_lbl

	return panel


func _create_result_display() -> void:
	content_container.add_child(UITheme.make_separator())

	result_label = Label.new()
	result_label.text = "Rolling..."
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(result_label, 28, UITheme.C_WARM_WHITE, true)
	content_container.add_child(result_label)

	damage_label = Label.new()
	damage_label.text = ""
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(damage_label, 18, UITheme.C_WARM_WHITE)
	content_container.add_child(damage_label)


# =============================================================================
# PUBLIC API
# =============================================================================

func show_combat(attacker_name: String, defender_name: String,
		atk_stat: int, def_stat: int) -> void:
	subtitle_label.text = "%s  vs  %s" % [attacker_name, defender_name]
	attacker_stat = atk_stat
	defender_stat = def_stat

	attacker_value_label.text = "?"
	defender_value_label.text = "?"
	attacker_stat_label.text  = "+ ATK %d" % atk_stat
	defender_stat_label.text  = "+ DEF %d" % def_stat
	attacker_total_label.text = "= ?"
	defender_total_label.text = "= ?"
	UITheme.style_label(result_label, 28, UITheme.C_WARM_WHITE, true)
	result_label.text  = "Rolling..."
	damage_label.text  = ""
	reroll_label.visible = false

	visible = true
	main_panel.scale     = Vector2(0.85, 0.85)
	main_panel.modulate.a = 0.0
	tween = create_tween().set_parallel(true)
	tween.tween_property(main_panel, "modulate:a", 1.0, 0.35)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(main_panel, "scale", Vector2(1, 1), 0.35)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Snapshot camera state for restore
	if _main:
		_saved_cam = {
			"focus"   : _main.focus_point,
			"distance": _main.camera_distance,
			"yaw"     : _main.camera_yaw,
			"pitch"   : _main.camera_pitch
		}


func start_roll(atk_roll: int) -> void:
	is_rolling = true
	roll_timer.start(0.08)

	# Spawn the 3D die and launch it
	_spawn_combat_die()
	_launch_combat_die(atk_roll)


func show_result(atk_roll: int, def_roll: int, atk_total: int, def_total: int,
		attack_succeeded: bool, damage: int, is_critical: bool) -> void:
	is_rolling = false
	roll_timer.stop()
	final_attacker_roll = atk_roll
	final_defender_roll = def_roll

	attacker_value_label.text = str(atk_roll)
	defender_value_label.text = str(def_roll)
	attacker_total_label.text = "= %d" % atk_total
	defender_total_label.text = "= %d" % def_total

	if atk_roll >= CRITICAL_THRESHOLD:
		attacker_value_label.add_theme_color_override("font_color", UITheme.C_GOLD_BRIGHT)
		_pulse_label(attacker_value_label)
	else:
		UITheme.style_label(attacker_value_label, 52, UITheme.C_WARM_WHITE, true)

	if def_roll >= CRITICAL_THRESHOLD:
		defender_value_label.add_theme_color_override("font_color", UITheme.C_GOLD_BRIGHT)
	else:
		UITheme.style_label(defender_value_label, 52, UITheme.C_WARM_WHITE, true)

	if attack_succeeded:
		if is_critical:
			result_label.text = "💥 CRITICAL HIT! 💥"
			result_label.add_theme_color_override("font_color", UITheme.C_GOLD_BRIGHT)
			damage_label.text = "%d DAMAGE!" % damage
			damage_label.add_theme_color_override("font_color", UITheme.C_GOLD_BRIGHT)
		else:
			result_label.text = "✓  HIT!"
			result_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
			damage_label.text = "%d damage dealt" % damage
			UITheme.style_label(damage_label, 18, UITheme.C_WARM_WHITE)
	else:
		result_label.text = "✗  BLOCKED!"
		result_label.add_theme_color_override("font_color", UITheme.C_DIM)
		damage_label.text = "Attack deflected"
		UITheme.style_label(damage_label, 18, UITheme.C_DIM)

	_pulse_label(result_label)

	# Zoom camera onto die
	_zoom_combat_camera()

	roll_animation_complete.emit()


func show_reroll(roll_number: int, reason: String) -> void:
	reroll_label.text = "🎲 Reroll #%d — %s" % [roll_number, reason]
	reroll_label.visible = true
	attacker_value_label.text = "?"
	defender_value_label.text = "?"
	attacker_total_label.text = "= ?"
	defender_total_label.text = "= ?"


func hide_dice() -> void:
	_cleanup_combat_die()
	_restore_camera()

	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.tween_property(main_panel, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): visible = false)
	tween.tween_callback(func(): dice_dismissed.emit())


func hide_immediate() -> void:
	visible = false
	_cleanup_combat_die()


func display_combat_sequence(attacker_name: String, defender_name: String,
		atk_stat: int, def_stat: int, atk_roll: int, def_roll: int,
		attack_succeeded: bool, damage: int, is_critical: bool) -> void:
	show_combat(attacker_name, defender_name, atk_stat, def_stat)
	start_roll(atk_roll)
	var result_timer = get_tree().create_timer(ROLL_DURATION)
	result_timer.timeout.connect(func():
		var atk_total = atk_roll + atk_stat
		var def_total = def_roll + def_stat
		show_result(atk_roll, def_roll, atk_total, def_total,
			attack_succeeded, damage, is_critical)
	)


# =============================================================================
# 3-D DIE — COMBAT
# =============================================================================

const D20_PATH := "res://assets/models/d20-gold.glb"


func _spawn_combat_die() -> void:
	_cleanup_combat_die()
	var res = load(D20_PATH)
	_combat_die = res.instantiate() if res else Node3D.new()
	_combat_die.scale = Vector3.ONE * DIE_SCALE
	_reduce_shininess(_combat_die, 0.5)
	_combat_die.global_position = COMBAT_DIE_SPAWN
	if _main:
		_main.add_child(_combat_die)


func _launch_combat_die(atk_roll: int) -> void:
	if not _combat_die: return

	if _die_tween and _die_tween.is_running(): _die_tween.kill()
	if _die_spin_tween and _die_spin_tween.is_running(): _die_spin_tween.kill()

	var from := COMBAT_DIE_SPAWN
	var to   := COMBAT_DIE_SETTLE
	const TRAVEL := 1.2
	const ARC_H  := 2.5

	_die_tween = create_tween()
	_die_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	_die_tween.tween_method(func(t: float):
		var base = from.lerp(to, t)
		var arc_y = ARC_H * 4.0 * t * (1.0 - t)
		_combat_die.global_position = Vector3(base.x, base.y + arc_y, base.z)
	, 0.0, 1.0, TRAVEL)

	# Calculate exactly how we want to land
	var final_rotation = _face_rotation_for(_combat_die, atk_roll)
	# Add multiple 360-degree rotations on all axes to simulate a tumble
	var spin_rot = final_rotation + Vector3(
		360.0 * randi_range(2, 4), 
		360.0 * randi_range(3, 5), 
		360.0 * randi_range(2, 4)
	)
	
	_combat_die.rotation_degrees = Vector3.ZERO

	_die_spin_tween = create_tween()
	_die_spin_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	_die_spin_tween.tween_property(_combat_die, "rotation_degrees", spin_rot, TRAVEL)
	_die_spin_tween.tween_callback(func():
		_combat_die.rotation_degrees = final_rotation
	)


func _zoom_combat_camera() -> void:
	if not _main: return
	if _cam_tween and _cam_tween.is_running(): _cam_tween.kill()

	var s_focus    : Vector3 = _main.focus_point
	var s_distance : float   = _main.camera_distance
	var s_yaw      : float   = _main.camera_yaw
	var s_pitch    : float   = _main.camera_pitch

	var t := CAM_COMBAT_ZOOM
	var t_focus    := t.get("focus",    COMBAT_DIE_SETTLE) as Vector3
	var t_distance := t.get("distance", 8.0)              as float
	var t_yaw      := t.get("yaw",      60.0)             as float
	var t_pitch    := t.get("pitch",    65.0)             as float

	_main.ignore_camera_process = true
	_cam_tween = create_tween()
	_cam_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	_cam_tween.set_parallel(true)
	_cam_tween.tween_method(func(v: Vector3): _main.focus_point     = v, s_focus,    t_focus,    0.8)
	_cam_tween.tween_method(func(v: float):   _main.camera_distance = v, s_distance, t_distance, 0.8)
	_cam_tween.tween_method(func(v: float):   _main.camera_yaw      = v, s_yaw,      t_yaw,      0.8)
	_cam_tween.tween_method(func(v: float):   _main.camera_pitch    = v, s_pitch,    t_pitch,    0.8)
	_cam_tween.chain().tween_callback(func():
		_main._update_camera_transform()
	)


func _restore_camera() -> void:
	if not _main or _saved_cam.is_empty(): return
	if _cam_tween and _cam_tween.is_running(): _cam_tween.kill()

	var s := _saved_cam
	_main.ignore_camera_process = true
	_cam_tween = create_tween()
	_cam_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	_cam_tween.set_parallel(true)
	_cam_tween.tween_method(func(v: Vector3): _main.focus_point     = v,
		_main.focus_point, s.get("focus",    Vector3.ZERO), 0.6)
	_cam_tween.tween_method(func(v: float):   _main.camera_distance = v,
		_main.camera_distance, s.get("distance", 25.0), 0.6)
	_cam_tween.tween_method(func(v: float):   _main.camera_yaw      = v,
		_main.camera_yaw, s.get("yaw", 0.0), 0.6)
	_cam_tween.tween_method(func(v: float):   _main.camera_pitch    = v,
		_main.camera_pitch, s.get("pitch", 35.0), 0.6)
	_cam_tween.chain().tween_callback(func():
		_main._update_camera_transform()
		_main.ignore_camera_process = false
	)


func _cleanup_combat_die() -> void:
	if _die_tween and _die_tween.is_running(): _die_tween.kill()
	if _die_spin_tween and _die_spin_tween.is_running(): _die_spin_tween.kill()
	if _combat_die:
		_combat_die.queue_free()
		_combat_die = null


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
				m.metallic  = clamp(m.metallic  * (1.0 - factor), 0.0, 1.0)
				m.roughness = clamp(m.roughness + (1.0 - m.roughness) * factor, 0.0, 1.0)
	for child in node.get_children():
		_reduce_shininess(child, factor)


# =============================================================================
# ANIMATION HELPERS
# =============================================================================

func _on_roll_timer_tick() -> void:
	if not is_rolling: return
	current_attacker_display = randi_range(1, 20)
	current_defender_display = randi_range(1, 20)
	attacker_value_label.text = str(current_attacker_display)
	defender_value_label.text = str(current_defender_display)
	attacker_total_label.text = "= %d" % (current_attacker_display + attacker_stat)
	defender_total_label.text = "= %d" % (current_defender_display + defender_stat)


func _pulse_label(label: Label) -> void:
	var pulse = create_tween()
	pulse.tween_property(label, "scale", Vector2(1.2, 1.2), 0.10)
	pulse.tween_property(label, "scale", Vector2(1.0, 1.0), 0.10)


# =============================================================================
# INPUT
# =============================================================================

func _input(event: InputEvent) -> void:
	if not visible: return
	if not is_rolling:
		if event is InputEventMouseButton and event.pressed:
			hide_dice()
		elif event is InputEventKey and event.pressed:
			hide_dice()


# =============================================================================
# PAUSE HANDLING
# =============================================================================

var _die_visible_before_pause : bool = false

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PAUSED:
			_on_game_paused()
		NOTIFICATION_UNPAUSED:
			_on_game_unpaused()


func _on_game_paused() -> void:
	if not visible: return
	
	_die_visible_before_pause = _combat_die.visible if _combat_die else false
	
	# Hide UI and 3D mesh
	main_panel.visible = false
	if _combat_die: _combat_die.visible = false
	
	print("[DiceUI] Paused combat roll")


func _on_game_unpaused() -> void:
	if not visible: return
	
	# Restore UI and 3D mesh
	main_panel.visible = true
	if _combat_die: _combat_die.visible = _die_visible_before_pause
	
	print("[DiceUI] Resumed combat roll")
