## Card Selection UI
## Pre-game deck builder for selecting 4 cards.
## Supports two modes (see GameConfig.DeckSelectionMode):
##   ALTERNATING_DRAFT — one pick per turn, opponent's choice disables same-slot
##   SEQUENTIAL        — one player picks full deck, then the other
class_name CardSelectionUI
extends CanvasLayer

# =============================================================================
# SIGNALS
# =============================================================================
signal deck_confirmed(deck: Array[String])  ## SEQUENTIAL mode: full deck done
signal pick_made(player_id: int, slot_index: int, card_id: String) ## ALTERNATING mode: one pick
signal selection_canceled()

# =============================================================================
# CONSTANTS
# =============================================================================
const MAX_DECK_SIZE: int = 4
const SELECTION_TIME: float = 60.0 # 60 seconds to select

# Role slot indices
enum RoleSlot {GROUND_TANK = 0, AIR_HYBRID = 1, RANGED_MAGIC = 2, FLEX = 3}

# =============================================================================
# COLORS
# =============================================================================
static var COLOR_GROUND_TANK  = UITheme.C_ROLE_GROUND
static var COLOR_AIR_HYBRID   = UITheme.C_ROLE_AIR
static var COLOR_RANGED_MAGIC = UITheme.C_ROLE_MAGIC
static var COLOR_FLEX         = UITheme.C_ROLE_FLEX

static var COLOR_BG           = UITheme.C_PANEL_FILL
static var COLOR_SELECTED     = UITheme.C_GOLD
static var COLOR_VALID        = Color(0.4, 0.8, 0.4)
static var COLOR_INVALID      = Color(0.9, 0.3, 0.3)

# =============================================================================
# UI ELEMENTS
# =============================================================================
var root_control: Control
var overlay: ColorRect
var main_panel: PanelContainer
var title_label: Label
var timer_label: Label

# Card grid (4 columns for 4 roles)
var card_columns: Array[VBoxContainer] = []
var card_buttons: Dictionary = {} # card_id -> Button

# Selected deck display
var deck_slots: Array[PanelContainer] = []
var deck_slot_labels: Array[Label] = []

# Confirm button
var confirm_button: Button

# Timer
var selection_timer: Timer
var time_remaining: float = SELECTION_TIME
var _is_showing_confirm: bool = false


# State
var selected_deck: Array[String] = ["", "", "", ""] # One slot per role
var player_id: int = 0
var is_visible_ui: bool = false
var current_tween: Tween = null

## ALTERNATING DRAFT state ──────────────────────────────────────────────────
## Tracks which card each player picked per slot-index.
## Shape: { player_id: { slot_index: card_id } }
var opponent_picks: Dictionary = {}  # cross-player exclusion tracking
var _draft_mode: bool = false        # true when using ALTERNATING_DRAFT
var _draft_slot_restriction: int = -1 # -1 = free pick; >=0 = must pick this slot
## ────────────────────────────────────────────────────────────────────────────

# =============================================================================
# CHARACTER PREVIEW (right panel)
# =============================================================================
var _preview_viewport: SubViewport = null
var _preview_model_root: Node3D = null  # Currently shown model
var _preview_current_id: String = ""    # Card ID in the viewport
var _preview_name_lbl: Label = null
var _preview_role_lbl: Label = null
var _preview_hp_lbl:   Label = null
var _preview_atk_lbl:  Label = null
var _preview_def_lbl:  Label = null
var _preview_rng_lbl:  Label = null
var _preview_spd_lbl:  Label = null
var _preview_abi_lbl:  Label = null
var _preview_empty_lbl: Label = null

# =============================================================================
# CARD DATA (organized by role)
# =============================================================================
const GROUND_TANK_CARDS = ["medieval_knight", "stone_giant", "four_headed_hydra"]
const AIR_HYBRID_CARDS = ["dark_blood_dragon", "sky_serpent", "frost_valkyrie"]
const RANGED_MAGIC_CARDS = ["dark_magic_wizard", "demon_of_darkness", "elven_archer"]
const FLEX_CARDS = ["celestial_cleric", "shadow_assassin", "infernal_soul"]


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	layer = 100
	_create_ui()
	# Hide initially - directly set visibility without tween
	if root_control:
		root_control.visible = false
	print("CardSelectionUI ready, root_control created: %s" % (root_control != null))


func _create_ui() -> void:
	# Root control that fills the viewport
	root_control = Control.new()
	root_control.name = "RootControl"
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	
	# Dark overlay
	overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = UITheme.C_OVERLAY_DIM
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root_control.add_child(overlay)
	
	# Main panel
	main_panel = PanelContainer.new()
	main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.offset_left = 50
	main_panel.offset_right = -50
	main_panel.offset_top = 50
	main_panel.offset_bottom = -50
	root_control.add_child(main_panel)
	
	main_panel.add_theme_stylebox_override("panel", UITheme.overlay_panel(UITheme.C_GOLD))
	
	# Main layout
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	main_panel.add_child(margin)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 20)
	margin.add_child(main_vbox)
	
	_create_header(main_vbox)
	_create_card_and_preview_area(main_vbox)
	_create_deck_display(main_vbox)
	_create_footer(main_vbox)

	# Create timer
	selection_timer = Timer.new()
	selection_timer.one_shot = false
	selection_timer.timeout.connect(_on_timer_tick)
	add_child(selection_timer)


func _create_header(parent: VBoxContainer) -> void:
	var header_box = MarginContainer.new()
	parent.add_child(header_box)
	
	# Title
	title_label = Label.new()
	title_label.text = "\u2694\ufe0f SELECT YOUR DECK \u2694\ufe0f"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.style_label(title_label, 32, UITheme.C_GOLD_BRIGHT, true)
	header_box.add_child(title_label)
	
	# Timer
	timer_label = Label.new()
	timer_label.text = "\u23f1 30s"
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.style_label(timer_label, 24, Color.YELLOW)
	header_box.add_child(timer_label)
	
	# Instructions
	var instructions = Label.new()
	instructions.text = "Pick 1 card from each role."
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(instructions, 16, UITheme.C_DIM)
	parent.add_child(instructions)
	
	# Info badges row (Removed content but keeping space as requested)
	var badges_row = Control.new()
	badges_row.custom_minimum_size = Vector2(0, 40) # Height of the original badges row
	parent.add_child(badges_row)


# Replaces old _create_card_grid — now places cards left + preview right
func _create_card_and_preview_area(parent: VBoxContainer) -> void:
	var h_split = HBoxContainer.new()
	h_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h_split.add_theme_constant_override("separation", 16)
	parent.add_child(h_split)

	# ── Left: scrollable card columns ──
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	h_split.add_child(scroll)

	var grid = HBoxContainer.new()
	grid.add_theme_constant_override("separation", 16)
	grid.alignment = BoxContainer.ALIGNMENT_CENTER
	scroll.add_child(grid)

	var role_data = [
		{"name": "GROUND TANK", "color": COLOR_GROUND_TANK, "cards": GROUND_TANK_CARDS, "icon": "🛡️"},
		{"name": "AIR/HYBRID",  "color": COLOR_AIR_HYBRID,  "cards": AIR_HYBRID_CARDS,  "icon": "🐲"},
		{"name": "RANGED/MAGIC","color": COLOR_RANGED_MAGIC,"cards": RANGED_MAGIC_CARDS,"icon": "✨"},
		{"name": "FLEX/SUPPORT","color": COLOR_FLEX,        "cards": FLEX_CARDS,        "icon": "⚡"}
	]

	for i in range(4):
		var column = _create_role_column(role_data[i], i)
		card_columns.append(column)
		grid.add_child(column)

	# ── Right: character preview ──
	_create_preview_panel(h_split)


func _create_preview_panel(parent: HBoxContainer) -> void:
	var outer = VBoxContainer.new()
	outer.custom_minimum_size = Vector2(280, 0)
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 10)
	parent.add_child(outer)

	# ── 3D Viewport ──
	var vp_container = SubViewportContainer.new()
	vp_container.custom_minimum_size = Vector2(280, 300)
	vp_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vp_container.stretch = true
	# Panel border around the viewport
	var vp_style = StyleBoxFlat.new()
	vp_style.bg_color      = Color(0.0, 0.0, 0.0, 0.0)  # Fully transparent
	vp_style.border_color  = UITheme.C_GOLD.darkened(0.4)
	vp_style.set_border_width_all(0)
	vp_style.set_corner_radius_all(10)
	vp_container.add_theme_stylebox_override("panel", vp_style)
	outer.add_child(vp_container)

	_preview_viewport = SubViewport.new()
	_preview_viewport.size = Vector2i(280, 300)
	_preview_viewport.transparent_bg = true
	_preview_viewport.own_world_3d = true
	_preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp_container.add_child(_preview_viewport)

	# Camera — framed to fit a 3.5-unit tall character perfectly
	var camera = Camera3D.new()
	camera.name = "PreviewCamera"
	camera.position = Vector3(0.0, 1.75, 6.5)   # exactly half of target height, pulled back to fit FOV
	camera.rotation_degrees = Vector3(0.0, 0.0, 0.0)  # straight on
	camera.fov = 40.0
	_preview_viewport.add_child(camera)

	# Key light (bright, front-left)
	var key_light = DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-30.0, 45.0, 0.0)
	key_light.light_energy = 1.2
	key_light.light_color = Color(1.0, 0.95, 0.85)
	_preview_viewport.add_child(key_light)

	# Rim light (blueish, back-right)
	var rim_light = DirectionalLight3D.new()
	rim_light.rotation_degrees = Vector3(-45.0, -135.0, 0.0)
	rim_light.light_energy = 0.8
	rim_light.light_color = Color(0.5, 0.65, 1.0)
	_preview_viewport.add_child(rim_light)

	# WorldEnvironment so the background is transparent dark
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.0, 0.0, 0.0, 0.0)  # Fully transparent
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.8, 0.8)
	env.ambient_light_energy = 0.5
	world_env.environment = env
	_preview_viewport.add_child(world_env)

	# ── "Hover a card" placeholder label ──
	_preview_empty_lbl = Label.new()
	_preview_empty_lbl.text = "Select a card\nto preview"
	_preview_empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_empty_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_preview_empty_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preview_empty_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.style_label(_preview_empty_lbl, 15, UITheme.C_DIM)
	vp_container.add_child(_preview_empty_lbl)

	# ── Stats panel (below viewport) ──
	var stats_panel = PanelContainer.new()
	var stats_style = StyleBoxFlat.new()
	stats_style.bg_color     = Color(0, 0, 0, 0)
	stats_style.border_color = UITheme.C_GOLD.darkened(0.4)
	stats_style.set_border_width_all(0)
	stats_style.set_corner_radius_all(10)
	stats_style.content_margin_left   = 14
	stats_style.content_margin_right  = 14
	stats_style.content_margin_top    = 10
	stats_style.content_margin_bottom = 10
	stats_panel.add_theme_stylebox_override("panel", stats_style)
	outer.add_child(stats_panel)

	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 5)
	stats_panel.add_child(stats_vbox)

	# Name row
	var name_row = HBoxContainer.new()
	stats_vbox.add_child(name_row)

	_preview_name_lbl = Label.new()
	_preview_name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.style_label(_preview_name_lbl, 16, UITheme.C_GOLD_BRIGHT, true)
	name_row.add_child(_preview_name_lbl)

	_preview_role_lbl = Label.new()
	UITheme.style_label(_preview_role_lbl, 12, UITheme.C_DIM)
	stats_vbox.add_child(_preview_role_lbl)

	stats_vbox.add_child(UITheme.make_separator())

	stats_vbox.add_child(UITheme.make_separator())

	# Stat horizontal layout (Row 1: HP, ATK, DEF)
	var stat_hbox1 = HBoxContainer.new()
	stat_hbox1.alignment = BoxContainer.ALIGNMENT_CENTER
	stat_hbox1.add_theme_constant_override("separation", 24)
	stats_vbox.add_child(stat_hbox1)

	_preview_hp_lbl  = _make_stat_row(stat_hbox1, "❤️")
	_preview_atk_lbl = _make_stat_row(stat_hbox1, "⚔️")
	_preview_def_lbl = _make_stat_row(stat_hbox1, "🛡️")

	# Stat horizontal layout (Row 2: Range, Speed)
	var stat_hbox2 = HBoxContainer.new()
	stat_hbox2.alignment = BoxContainer.ALIGNMENT_CENTER
	stat_hbox2.add_theme_constant_override("separation", 24)
	stats_vbox.add_child(stat_hbox2)

	_preview_rng_lbl = _make_stat_row(stat_hbox2, "📍 Range")
	_preview_spd_lbl = _make_stat_row(stat_hbox2, "🏃 Speed")

	stats_vbox.add_child(UITheme.make_separator())

	_preview_abi_lbl = Label.new()
	_preview_abi_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_abi_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(_preview_abi_lbl, 11, Color(1.0, 0.9, 0.5))
	stats_vbox.add_child(_preview_abi_lbl)

	# Start hidden until a card is selected
	stats_panel.visible = false
	# Store reference so we can toggle it
	_preview_viewport.set_meta("stats_panel", stats_panel)


## Creates an icon + value horizontal container. Returns the value label.
func _make_stat_row(parent: Control, icon: String) -> Label:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	parent.add_child(hbox)

	var icon_lbl = Label.new()
	icon_lbl.text = icon
	UITheme.style_label(icon_lbl, 13, UITheme.C_DIM)
	hbox.add_child(icon_lbl)

	var val_lbl = Label.new()
	UITheme.style_label(val_lbl, 14, UITheme.C_WARM_WHITE, true)
	hbox.add_child(val_lbl)
	return val_lbl


## Load / swap the 3D model in the SubViewport and fill the stats panel.
func _show_character_preview(card_id: String, role_color: Color) -> void:
	if _preview_viewport == null:
		return

	# Avoid reloading the same model
	if _preview_current_id == card_id:
		return
	_preview_current_id = card_id

	# Remove old model
	if _preview_model_root and is_instance_valid(_preview_model_root):
		_preview_model_root.queue_free()
		_preview_model_root = null

	# Load + add new model
	var model = CharacterModelLoader.load_character_model(card_id)
	if model:
		# Use the actual model scale (no normalization here to reflect true size hirearchy)
		# But we still need to position it correctly (grounded at Y=0)
		model.position = Vector3(0.0, 0.0, 0.0) 
		# MODEL_Y_OFFSETS is already handled inside load_character_model which returns 
		# a node containing the scaled and offset model.
		
		# Front-left facing: base rotation + 60 degree anticlockwise turn
		var base_rot = CharacterModelLoader.MODEL_ROTATIONS.get(card_id, 0.0)
		model.rotation_degrees.y = base_rot + 60.0 # Quarter view
		_preview_viewport.add_child(model)
		_preview_model_root = model
		_preview_empty_lbl.visible = false
		
		# DYNAMIC CAMERA CALIBRATION
		var camera = _preview_viewport.get_node("PreviewCamera")
		if camera:
			var raw_scale = CharacterModelLoader.MODEL_SCALES.get(card_id, Vector3.ONE)
			var h = raw_scale.y
			
			# Amount of "zooming" based on height
			# Larger characters get a more pulled-back view but still fill most of the frame
			# Smaller characters get a tighter zoom to show detail
			# FOV is 40.0. To fit height 'h' in FOV, distance 'd' = (h/2) / tan(20°) ≈ h / 0.728
			# We'll add some padding (multiplier 2.5 was chosen back when h was ~2.0)
			var dist_mult = 1.3 # Tight framing
			if h > 1.2: dist_mult = 1.8 # Pull back for larger units
			
			camera.position.z = max(1.2, h * dist_mult + 1.0)
			camera.position.y = h * 0.5 # Center at waist/chest
			camera.look_at(Vector3(0, h * 0.45, 0), Vector3.UP)
	else:
		_preview_empty_lbl.visible = true

	# Fill stats
	var card_data    = CardData.get_troop(card_id)
	var display_name = card_data.get("name", card_id.replace("_", " ").capitalize())
	var hp           = card_data.get("hp", 0)
	var atk          = card_data.get("atk", 0)
	var def_val      = card_data.get("def", 0)
	var rng          = card_data.get("range", 1)
	var spd          = card_data.get("speed", 2)
	var ability      = card_data.get("ability_description", "")
	var role_enum    = card_data.get("role", -1)

	# Convert Role enum to readable string
	var role_text = ""
	match role_enum:
		CardData.Role.GROUND_TANK:  role_text = "Ground Tank"
		CardData.Role.AIR_HYBRID:   role_text = "Air / Hybrid"
		CardData.Role.RANGED_MAGIC: role_text = "Ranged / Magic"
		CardData.Role.FLEX_SUPPORT: role_text = "Flex / Support"

	_preview_name_lbl.text = display_name
	_preview_name_lbl.add_theme_color_override("font_color", role_color)
	_preview_role_lbl.text  = role_text
	_preview_hp_lbl.text    = str(hp)
	_preview_atk_lbl.text   = str(atk)
	_preview_def_lbl.text   = str(def_val)
	_preview_rng_lbl.text   = str(rng)
	_preview_spd_lbl.text   = str(spd)
	_preview_abi_lbl.text   = ability if ability != "" else "—"

	# Show stats panel
	var stats_panel = _preview_viewport.get_meta("stats_panel", null) as PanelContainer
	if stats_panel:
		stats_panel.visible = true


## Clear the 3D preview (called when a card is deselected)
func _clear_preview() -> void:
	if _preview_model_root and is_instance_valid(_preview_model_root):
		_preview_model_root.queue_free()
		_preview_model_root = null
	_preview_current_id = ""
	if _preview_empty_lbl:
		_preview_empty_lbl.visible = true
	var stats_panel = _preview_viewport.get_meta("stats_panel", null) as PanelContainer if _preview_viewport else null
	if stats_panel:
		stats_panel.visible = false


func _create_role_column(role_info: Dictionary, slot_index: int) -> VBoxContainer:
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.custom_minimum_size = Vector2(250, 0)
	
	# Role header
	var header_panel = PanelContainer.new()
	header_panel.add_theme_stylebox_override("panel", UITheme.btn_normal())
	column.add_child(header_panel)
	
	var header_label = Label.new()
	header_label.text = "%s %s" % [role_info["icon"], role_info["name"]]
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(header_label, 18, role_info["color"], true)
	var header_margin = MarginContainer.new()
	header_margin.add_theme_constant_override("margin_top", 4)
	header_margin.add_theme_constant_override("margin_bottom", 4)
	header_margin.add_child(header_label)
	header_panel.add_child(header_margin)
	
	# Cards in this role
	for card_id in role_info["cards"]:
		var card_button = _create_card_button(card_id, role_info["color"], slot_index)
		column.add_child(card_button)
		card_buttons[card_id] = card_button
	
	return column


func _create_card_button(card_id: String, role_color: Color, slot_index: int) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(240, 140)
	button.clip_text = false
	
	# Get card data
	var card_data = CardData.get_troop(card_id)
	var display_name = card_data.get("display_name", card_id.replace("_", " ").capitalize())
	var hp = card_data.get("hp", 100)
	var atk = card_data.get("atk", 50)
	var def = card_data.get("def", 50)
	var range_val = card_data.get("range", 1)
	var speed = card_data.get("speed", 2)
	var ability_text = card_data.get("ability_description", "")
	
	# Use a MarginContainer to ensure the content doesn't overlap the border
	var margin_container = MarginContainer.new()
	margin_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin_container.add_theme_constant_override("margin_left", 8)
	margin_container.add_theme_constant_override("margin_right", 8)
	margin_container.add_theme_constant_override("margin_top", 8)
	margin_container.add_theme_constant_override("margin_bottom", 8)
	margin_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(margin_container)
	
	# Use an HBoxContainer layout: [Card Art | Stats Text]
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin_container.add_child(hbox)
	
	# Card art thumbnail
	var card_art = CharacterModelLoader.load_card_art(card_id)
	if card_art:
		var tex_rect = TextureRect.new()
		tex_rect.texture = card_art
		tex_rect.custom_minimum_size = Vector2(80, 120)
		tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(tex_rect)
	else:
		# Placeholder colored rectangle if no art available
		var placeholder = ColorRect.new()
		placeholder.custom_minimum_size = Vector2(80, 120)
		placeholder.color = role_color.darkened(0.4)
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(placeholder)
	
	# Stats text in a VBoxContainer
	var stats_vbox = VBoxContainer.new()
	stats_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_vbox.add_theme_constant_override("separation", 2)
	stats_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(stats_vbox)
	
	# Name label
	var name_label = Label.new()
	name_label.text = display_name
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.style_label(name_label, 14, role_color, true)
	stats_vbox.add_child(name_label)
	
	# Stats line
	var stats_label = Label.new()
	stats_label.text = "❤️%d ⚔️%d 🛡️%d 📍%d 🏃%d" % [hp, atk, def, range_val, speed]
	stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.style_label(stats_label, 10, Color(0.8, 0.8, 0.8))
	stats_vbox.add_child(stats_label)
	
	# Ability text (if any)
	if ability_text != "":
		var ability_label = Label.new()
		ability_label.text = "✨ %s" % ability_text
		ability_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ability_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UITheme.style_label(ability_label, 9, Color(1.0, 0.9, 0.5))
		stats_vbox.add_child(ability_label)
	
	# Style
	UITheme.apply_hud_button(button, role_color, 14)
	
	# Connect signals
	button.pressed.connect(_on_card_selected.bind(card_id, slot_index))
	
	return button


func _create_deck_display(parent: VBoxContainer) -> void:
	var deck_container = HBoxContainer.new()
	deck_container.alignment = BoxContainer.ALIGNMENT_CENTER
	deck_container.add_theme_constant_override("separation", 20)
	parent.add_child(deck_container)
	
	var deck_label = Label.new()
	deck_label.text = "YOUR DECK: "
	UITheme.style_label(deck_label, 18, UITheme.C_WARM_WHITE, true)
	deck_container.add_child(deck_label)
	
	var role_colors = [COLOR_GROUND_TANK, COLOR_AIR_HYBRID, COLOR_RANGED_MAGIC, COLOR_FLEX]
	
	for i in range(4):
		var slot = PanelContainer.new()
		slot.custom_minimum_size = Vector2(150, 50)
		slot.add_theme_stylebox_override("panel", UITheme.section_panel(role_colors[i]))
		
		var slot_label = Label.new()
		slot_label.text = "Empty"
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UITheme.style_label(slot_label, 14, UITheme.C_DIM)
		
		var slot_margin = MarginContainer.new()
		slot_margin.add_theme_constant_override("margin_left", 10)
		slot_margin.add_theme_constant_override("margin_right", 10)
		slot_margin.add_child(slot_label)
		slot.add_child(slot_margin)
		
		deck_container.add_child(slot)
		deck_slots.append(slot)
		deck_slot_labels.append(slot_label)
	
func _create_footer(parent: VBoxContainer) -> void:
	var footer = HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 30)
	parent.add_child(footer)
	
	# Cancel button
	var cancel_button = Button.new()
	cancel_button.text = "CANCEL"
	cancel_button.custom_minimum_size = Vector2(144, 50)
	UITheme.apply_menu_button(cancel_button, 18)
	cancel_button.pressed.connect(_on_cancel_pressed)
	footer.add_child(cancel_button)
	
	# Confirm button
	confirm_button = Button.new()
	confirm_button.text = "CONFIRM DECK"
	confirm_button.custom_minimum_size = Vector2(192, 50)
	confirm_button.disabled = true
	UITheme.apply_menu_button(confirm_button, 18)
	
	confirm_button.pressed.connect(_on_confirm_pressed)
	footer.add_child(confirm_button)


func _create_info_badge(text: String, color: Color) -> PanelContainer:
	var badge = PanelContainer.new()
	badge.add_theme_stylebox_override("panel", UITheme.section_panel(color))
	
	var label = Label.new()
	label.text = text
	UITheme.style_label(label, 12, color)
	badge.add_child(label)
	
	return badge


# =============================================================================
# PUBLIC METHODS
# =============================================================================

## Show the card selection UI
## In ALTERNATING_DRAFT mode, pass opponent_picks_dict to grey-out opponent choices.
func show_selection(for_player_id: int = 0, timer_enabled: bool = true,
		opponent_picks_dict: Dictionary = {},
		draft_slot_restriction: int = -1,
		draft_mode: bool = false) -> void:
	print("CardSelectionUI.show_selection called for player %d" % for_player_id)
	print("  root_control exists: %s" % (root_control != null))
	print("  main_panel exists: %s" % (main_panel != null))
	
	# Kill any existing tween to prevent conflicts
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		current_tween = null
	
	player_id = for_player_id
	selected_deck = ["", "", "", ""]
	is_visible_ui = true
	opponent_picks = opponent_picks_dict.duplicate(true)  # deep copy
	_draft_mode = draft_mode
	_draft_slot_restriction = draft_slot_restriction

	# Clear any previous card preview from the last player's selection
	_clear_preview()
	
	# Update title to show which player is selecting
	var player_color = Color(0.2, 0.5, 1.0) if player_id == 0 else Color(1.0, 0.3, 0.2)
	var player_name = "PLAYER 1" if player_id == 0 else "PLAYER 2"
	if draft_mode:
		title_label.text = "\u2694\ufe0f %s — CHOOSE YOUR PICK \u2694\ufe0f" % player_name
	else:
		title_label.text = "\u2694\ufe0f %s - SELECT YOUR DECK \u2694\ufe0f" % player_name
	title_label.add_theme_color_override("font_color", player_color)
	
	# Reset UI state
	_update_deck_display()
	_update_card_highlights()
	
	if timer_enabled:
		time_remaining = SELECTION_TIME
		timer_label.text = "\u23f1 %ds" % int(time_remaining)
		timer_label.visible = true
		timer_label.add_theme_color_override("font_color", Color.YELLOW) # Reset timer color
		selection_timer.start(1.0)
	else:
		timer_label.visible = false
	
	# Trigger background music if not already playing
	if AudioManager and AudioManager.has_method("start_tavern_music"):
		AudioManager.start_tavern_music()

	# Show the root control (which contains overlay and main panel)
	if root_control:
		root_control.visible = true
	
	# Reset panel state before animation
	main_panel.modulate.a = 0
	
	# Animate entrance
	current_tween = create_tween()
	current_tween.tween_property(main_panel, "modulate:a", 1.0, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


## Hide the card selection UI
func hide_selection() -> void:
	is_visible_ui = false
	_clear_preview()  # Free the 3D model from the SubViewport
	
	if selection_timer:
		selection_timer.stop()
	
	# Kill any existing tween first
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	
	# Simply hide the root control
	if root_control:
		if is_inside_tree() and main_panel:
			current_tween = create_tween()
			current_tween.tween_property(main_panel, "modulate:a", 0.0, 0.2)
			current_tween.tween_callback(func():
				root_control.visible = false
			)
		else:
			root_control.visible = false


## Hide the card selection UI immediately without animation
func hide_immediate() -> void:
	is_visible_ui = false
	
	if selection_timer:
		selection_timer.stop()
	
	# Kill any existing tween first
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		current_tween = null
	
	# Immediately hide both the root control AND the CanvasLayer itself
	if root_control:
		root_control.visible = false
	visible = false # CRITICAL: Hide the CanvasLayer itself!


## Get the currently selected deck
func get_selected_deck() -> Array[String]:
	var deck: Array[String] = []
	for card_id in selected_deck:
		if card_id != "":
			deck.append(card_id)
	return deck


## Check if deck is valid and complete
func is_deck_valid() -> bool:
	# Check if all 4 slots are filled
	for card_id in selected_deck:
		if card_id == "":
			return false
	return true


# =============================================================================
# INTERNAL METHODS
# =============================================================================

func _on_card_selected(card_id: String, slot_index: int) -> void:
	# In draft mode, only allow one pick and only from allowed slots
	if _draft_mode:
		# If a slot restriction is active, only allow that slot
		if _draft_slot_restriction >= 0 and slot_index != _draft_slot_restriction:
			return
		# Current player can't re-pick a slot they already own
		if _is_own_slot_taken(slot_index):
			return
		# Can't pick a card already chosen by the opponent
		if _is_card_taken_by_opponent(card_id, slot_index):
			return
		# Allow deselect of the currently staged pick
		if selected_deck[slot_index] == card_id:
			selected_deck[slot_index] = ""
			_clear_preview()
			_update_deck_display()
			_update_card_highlights()
			return
		# Stage this pick (clears any other pending pick this turn)
		selected_deck = ["", "", "", ""]
		selected_deck[slot_index] = card_id
		if AudioManager and AudioManager.has_method("play_card_pick"):
			AudioManager.play_card_pick()
		var role_colors = [COLOR_GROUND_TANK, COLOR_AIR_HYBRID, COLOR_RANGED_MAGIC, COLOR_FLEX]
		_show_character_preview(card_id, role_colors[slot_index])
		_update_deck_display()
		_update_card_highlights()
		print("Draft pick staged: Player %d → slot %d → %s" % [player_id, slot_index, card_id])
		return

	# ── SEQUENTIAL mode (original logic) ──
	# Toggle selection
	if selected_deck[slot_index] == card_id:
		# Deselect
		selected_deck[slot_index] = ""
		_clear_preview()
	else:
		# Audio feedback
		if AudioManager and AudioManager.has_method("play_card_pick"):
			AudioManager.play_card_pick()
			
		# Select (replacing any previous selection in this slot)
		selected_deck[slot_index] = card_id
		# Show 3D preview for this card
		var role_colors = [COLOR_GROUND_TANK, COLOR_AIR_HYBRID, COLOR_RANGED_MAGIC, COLOR_FLEX]
		_show_character_preview(card_id, role_colors[slot_index])
	
	_update_deck_display()
	_update_card_highlights()
	
	print("Deck: %s" % str(selected_deck))


func _update_deck_display() -> void:
	var role_colors = [COLOR_GROUND_TANK, COLOR_AIR_HYBRID, COLOR_RANGED_MAGIC, COLOR_FLEX]
	
	for i in range(4):
		# In draft mode, merge committed picks with the current staged pick
		var card_id = selected_deck[i]
		if _draft_mode and card_id == "":
			# Check if committed in earlier draft turn
			var own_picks: Dictionary = opponent_picks.get(player_id, {})
			card_id = own_picks.get(i, "")
		
		if card_id != "":
			var card_data = CardData.get_troop(card_id)
			var display_name = card_data.get("display_name", card_id.replace("_", " ").capitalize())
			deck_slot_labels[i].text = display_name
			deck_slot_labels[i].add_theme_color_override("font_color", role_colors[i])
			# Committed picks get a green-tinted "done" border; staged pick gets gold
			var is_committed = _is_own_slot_taken(i)
			if is_committed:
				var done_style = UITheme.section_panel(Color(0.2, 0.7, 0.3))
				done_style.border_color = Color(0.3, 0.9, 0.4)
				deck_slots[i].add_theme_stylebox_override("panel", done_style)
			else:
				deck_slots[i].add_theme_stylebox_override("panel", UITheme.section_panel(COLOR_SELECTED))
		else:
			deck_slot_labels[i].text = "Empty"
			deck_slot_labels[i].add_theme_color_override("font_color", UITheme.C_DIM)
			deck_slots[i].add_theme_stylebox_override("panel", UITheme.section_panel(role_colors[i]))
	
	# Update confirm button
	if _draft_mode:
		# In draft mode the confirm button is active as soon as one card is pending
		var has_pick = false
		for cid in selected_deck:
			if cid != "":
				has_pick = true
				break
		confirm_button.disabled = not has_pick
		confirm_button.text = "CONFIRM PICK"
	else:
		confirm_button.disabled = not is_deck_valid()
		confirm_button.text = "CONFIRM DECK"


## Returns true if the opponent has already claimed this specific card in this slot.
func _is_card_taken_by_opponent(card_id: String, slot_index: int) -> bool:
	if not _draft_mode:
		return false
	for p_id in opponent_picks:
		if p_id == player_id:
			continue  # Only check opponent
		var picks: Dictionary = opponent_picks[p_id]
		if picks.get(slot_index, "") == card_id:
			return true
	return false

## Returns true if the current player already filled this slot in a previous draft turn.
func _is_own_slot_taken(slot_index: int) -> bool:
	if not _draft_mode:
		return false
	var own_picks: Dictionary = opponent_picks.get(player_id, {})
	return own_picks.has(slot_index)



func _update_card_highlights() -> void:
	var role_cards = [GROUND_TANK_CARDS, AIR_HYBRID_CARDS, RANGED_MAGIC_CARDS, FLEX_CARDS]
	var role_colors = [COLOR_GROUND_TANK, COLOR_AIR_HYBRID, COLOR_RANGED_MAGIC, COLOR_FLEX]
	
	for slot_index in range(4):
		var selected_id = selected_deck[slot_index]
		
		for card_id in role_cards[slot_index]:
			var button = card_buttons.get(card_id)
			if button == null:
				continue
			
			# Check if this card is taken by the opponent (draft mode)
			var opp_took = _is_card_taken_by_opponent(card_id, slot_index)
			# Current player already filled this slot in an earlier draft turn
			var own_slot_taken = _is_own_slot_taken(slot_index)
			# In draft mode, also grey out slots that aren't allowed this pick
			var slot_locked = _draft_mode and _draft_slot_restriction >= 0 and slot_index != _draft_slot_restriction
			
			if card_id == selected_id:
				# Selected — highlighted border and dark background
				var style = UITheme.section_panel(role_colors[slot_index])
				style.border_color = COLOR_SELECTED
				style.set_border_width_all(3)
				style.bg_color = role_colors[slot_index].darkened(0.7)
				button.add_theme_stylebox_override("normal", style)
				button.add_theme_color_override("font_color", COLOR_SELECTED)
				button.disabled = false
			elif own_slot_taken:
				# This player already picked from this category — lock entire column
				var style = UITheme.section_panel(role_colors[slot_index].darkened(0.55))
				style.bg_color = role_colors[slot_index].darkened(0.80)
				button.add_theme_stylebox_override("normal", style)
				button.add_theme_color_override("font_color", Color(0.45, 0.7, 0.45, 0.9))  # greenish "done" tint
				button.disabled = true
			elif opp_took:
				# Opponent already picked this card — grey it out
				var style = UITheme.section_panel(Color(0.3, 0.3, 0.3))
				style.bg_color = Color(0.15, 0.15, 0.15, 0.7)
				button.add_theme_stylebox_override("normal", style)
				button.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
				button.disabled = true
			elif slot_locked:
				# Slot not available this pick (draft slot restriction) — dim it
				var style = UITheme.section_panel(role_colors[slot_index].darkened(0.6))
				style.bg_color = role_colors[slot_index].darkened(0.85)
				button.add_theme_stylebox_override("normal", style)
				button.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
				button.disabled = true
			else:
				# Normal — default hud button style
				UITheme.apply_hud_button(button, role_colors[slot_index], 14)
				button.remove_theme_color_override("font_color")
				button.disabled = false


func _on_timer_tick() -> void:
	time_remaining -= 1.0
	timer_label.text = "\u23f1 %ds" % int(time_remaining)
	
	if time_remaining <= 10:
		timer_label.add_theme_color_override("font_color", COLOR_INVALID)
	
	if time_remaining <= 0:
		selection_timer.stop()
		if _draft_mode:
			# Draft mode: auto-pick a random available card for this turn
			_auto_draft_pick()
			_on_confirm_pressed()
		else:
			# Sequential mode: auto-fill remaining slots then confirm
			if is_deck_valid():
				_on_confirm_pressed()
			else:
				_auto_select_remaining()
				_on_confirm_pressed()


## Auto-pick one random valid card for draft mode when timer expires.
func _auto_draft_pick() -> void:
	var role_cards = [GROUND_TANK_CARDS, AIR_HYBRID_CARDS, RANGED_MAGIC_CARDS, FLEX_CARDS]
	# Determine which slots are eligible
	var eligible_slots: Array[int] = []
	for i in range(4):
		if _draft_slot_restriction >= 0 and i != _draft_slot_restriction:
			continue
		# Find available cards in this slot
		var available: Array[String] = []
		for card_id in role_cards[i]:
			if not _is_card_taken_by_opponent(card_id, i):
				available.append(card_id)
		if available.size() > 0:
			eligible_slots.append(i)
	if eligible_slots.is_empty():
		return
	var slot = eligible_slots[randi() % eligible_slots.size()]
	var available_in_slot: Array[String] = []
	for card_id in role_cards[slot]:
		if not _is_card_taken_by_opponent(card_id, slot):
			available_in_slot.append(card_id)
	if available_in_slot.is_empty():
		return
	selected_deck = ["", "", "", ""]
	selected_deck[slot] = available_in_slot[randi() % available_in_slot.size()]
	_update_deck_display()



func _auto_select_remaining() -> void:
	# Fill any empty slots with random cards from their role
	var role_cards = [GROUND_TANK_CARDS, AIR_HYBRID_CARDS, RANGED_MAGIC_CARDS, FLEX_CARDS]
	
	for i in range(4):
		if selected_deck[i] == "":
			# Pick random card from this role
			var cards = role_cards[i]
			selected_deck[i] = cards[randi() % cards.size()]
	
	_update_deck_display()


func _on_confirm_pressed() -> void:
	if _draft_mode:
		# Draft mode: emit pick_made for the single selected card
		var pick_slot: int = -1
		var pick_card: String = ""
		for i in range(4):
			if selected_deck[i] != "":
				pick_slot = i
				pick_card = selected_deck[i]
				break
		if pick_slot < 0:
			return # Nothing selected yet
		selection_timer.stop()
		# Keep panel visible (main.gd will show_selection again for next pick)
		pick_made.emit(player_id, pick_slot, pick_card)
		return

	# Sequential mode: full deck confirm
	if not is_deck_valid():
		return
	
	var final_deck: Array[String] = []
	for card_id in selected_deck:
		final_deck.append(card_id)
	
	hide_selection()
	deck_confirmed.emit(final_deck)


func _on_cancel_pressed() -> void:
	_show_cancel_confirm()

func _show_cancel_confirm() -> void:
	var confirm_layer = CanvasLayer.new()
	confirm_layer.layer = 150
	
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
	title.text = "CANCEL DECK SELECTION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UITheme.style_label(title, 24, UITheme.C_GOLD, true)
	vbox.add_child(title)
	
	var msg = Label.new()
	msg.text = "Are you sure you want to cancel deck selection? You will return to the main menu."
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
		_is_showing_confirm = false
		confirm_layer.queue_free()
		hide_selection()
		selection_canceled.emit()
	)
	btn_row.add_child(yes_btn)
	
	var no_btn = Button.new()
	no_btn.text = "NO"
	no_btn.custom_minimum_size = Vector2(160, 50)
	no_btn.pivot_offset = Vector2(80, 25)
	no_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	UITheme.apply_menu_button(no_btn, 18)
	no_btn.pressed.connect(func():
		_is_showing_confirm = false
		confirm_layer.queue_free()
	)
	btn_row.add_child(no_btn)
	
	_is_showing_confirm = true
	add_child(confirm_layer)


# =============================================================================
# INPUT
# =============================================================================

func _input(event: InputEvent) -> void:
	if not is_visible_ui or _is_showing_confirm:
		return
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_cancel_pressed()
		elif event.keycode == KEY_ENTER:
			if is_deck_valid():
				_on_confirm_pressed()
