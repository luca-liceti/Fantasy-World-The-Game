## Settings Manager (Autoload Singleton)
## Manages game settings persistence and provides access to settings from anywhere
## Access via: SettingsManager.get_setting("audio/master_volume")
extends Node

# =============================================================================
# SIGNALS
# =============================================================================
signal settings_changed(section: String, key: String, value: Variant)
signal settings_loaded
signal settings_saved

# =============================================================================
# SETTINGS FILE
# =============================================================================
const SETTINGS_FILE_PATH = "user://settings.cfg"

# =============================================================================
# DEFAULT SETTINGS
# =============================================================================
const DEFAULT_SETTINGS: Dictionary = {
	"audio": {
		"master_volume": 80,
		"music_volume": 70,
		"sfx_volume": 80,
		"voice_volume": 80,
		"mute_when_unfocused": false
	},
	"graphics": {
		"display_mode": 0, # 0=Windowed, 1=Borderless, 2=Fullscreen
		"resolution_index": 0, # Index into RESOLUTIONS array
		"vsync": true,
		"fps_limit": 0, # 0=Unlimited, 30, 60, 120, 144
		"msaa": 2, # 0=Off, 1=2x, 2=4x, 3=8x
		"shadow_quality": 2, # 0=Off, 1=Low, 2=Medium, 3=High
		"ambient_occlusion": true,
		"bloom": true,
		"camera_shake": true
	},
	"controls": {
		"camera_sensitivity": 50,
		"invert_camera_y": false,
		"edge_pan_enabled": true,
		"edge_pan_speed": 50,
		"show_tile_coordinates": false,
		"confirm_end_turn": true
	},
	"gameplay": {
		"turn_timer": 120, # seconds
		"auto_end_turn": false,
		"show_damage_numbers": true,
		"show_combat_animations": true,
		"combat_speed": 1.0, # 0.5x, 1.0x, 1.5x, 2.0x
		"show_biome_tooltips": true,
		"colorblind_mode": 0 # 0=Off, 1=Protanopia, 2=Deuteranopia, 3=Tritanopia
	},
	"accessibility": {
		"text_size": 1.0, # 0.8, 1.0, 1.2, 1.4
		"high_contrast": false,
		"reduce_motion": false,
		"screen_reader_hints": false
	}
}

# Available resolutions
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
	Vector2i(1600, 900),
	Vector2i(1366, 768),
	Vector2i(1280, 720)
]

const RESOLUTION_NAMES: Array[String] = [
	"1920 x 1080 (FHD)",
	"2560 x 1440 (QHD)",
	"3840 x 2160 (4K)",
	"1600 x 900",
	"1366 x 768",
	"1280 x 720 (HD)"
]

# =============================================================================
# CURRENT SETTINGS
# =============================================================================
var settings: Dictionary = {}
var config_file: ConfigFile


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	config_file = ConfigFile.new()
	_init_default_settings()
	load_settings()
	_apply_all_settings()
	print("SettingsManager initialized")


func _init_default_settings() -> void:
	# Deep copy default settings
	settings = DEFAULT_SETTINGS.duplicate(true)


# =============================================================================
# SETTINGS ACCESS
# =============================================================================

## Get a setting value using path notation: "audio/master_volume"
func get_setting(path: String) -> Variant:
	var parts = path.split("/")
	if parts.size() != 2:
		push_error("Invalid settings path: " + path)
		return null
	
	var section = parts[0]
	var key = parts[1]
	
	if settings.has(section) and settings[section].has(key):
		return settings[section][key]
	
	# Return default if not found
	if DEFAULT_SETTINGS.has(section) and DEFAULT_SETTINGS[section].has(key):
		return DEFAULT_SETTINGS[section][key]
	
	push_error("Setting not found: " + path)
	return null


## Set a setting value using path notation
func set_setting(path: String, value: Variant, auto_save: bool = true) -> void:
	var parts = path.split("/")
	if parts.size() != 2:
		push_error("Invalid settings path: " + path)
		return
	
	var section = parts[0]
	var key = parts[1]
	
	if not settings.has(section):
		settings[section] = {}
	
	var old_value = settings[section].get(key)
	settings[section][key] = value
	
	# Apply the setting immediately
	_apply_setting(section, key, value)
	
	# Emit signal
	settings_changed.emit(section, key, value)
	
	# Auto-save
	if auto_save:
		save_settings()


## Get all settings for a section
func get_section(section: String) -> Dictionary:
	if settings.has(section):
		return settings[section].duplicate()
	return {}


# =============================================================================
# PERSISTENCE
# =============================================================================

func load_settings() -> void:
	var error = config_file.load(SETTINGS_FILE_PATH)
	
	if error == OK:
		# Load each section
		for section in settings.keys():
			for key in settings[section].keys():
				if config_file.has_section_key(section, key):
					settings[section][key] = config_file.get_value(section, key)
		print("Settings loaded from: " + SETTINGS_FILE_PATH)
	else:
		print("No settings file found, using defaults")
	
	settings_loaded.emit()


func save_settings() -> void:
	# Save each section
	for section in settings.keys():
		for key in settings[section].keys():
			config_file.set_value(section, key, settings[section][key])
	
	var error = config_file.save(SETTINGS_FILE_PATH)
	if error == OK:
		print("Settings saved to: " + SETTINGS_FILE_PATH)
		settings_saved.emit()
	else:
		push_error("Failed to save settings: " + str(error))


func reset_to_defaults() -> void:
	settings = DEFAULT_SETTINGS.duplicate(true)
	_apply_all_settings()
	save_settings()
	print("Settings reset to defaults")


func reset_section(section: String) -> void:
	if DEFAULT_SETTINGS.has(section):
		settings[section] = DEFAULT_SETTINGS[section].duplicate(true)
		for key in settings[section].keys():
			_apply_setting(section, key, settings[section][key])
		save_settings()


# =============================================================================
# APPLY SETTINGS
# =============================================================================

func _apply_all_settings() -> void:
	for section in settings.keys():
		for key in settings[section].keys():
			_apply_setting(section, key, settings[section][key])


func _apply_setting(section: String, key: String, value: Variant) -> void:
	match section:
		"audio":
			_apply_audio_setting(key, value)
		"graphics":
			_apply_graphics_setting(key, value)
		"controls":
			_apply_controls_setting(key, value)
		"gameplay":
			_apply_gameplay_setting(key, value)
		"accessibility":
			_apply_accessibility_setting(key, value)


func _apply_audio_setting(key: String, value: Variant) -> void:
	match key:
		"master_volume":
			var bus_idx = AudioServer.get_bus_index("Master")
			if bus_idx >= 0:
				AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value / 100.0))
		"music_volume":
			var bus_idx = AudioServer.get_bus_index("Music")
			if bus_idx >= 0:
				AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value / 100.0))
		"sfx_volume":
			var bus_idx = AudioServer.get_bus_index("SFX")
			if bus_idx >= 0:
				AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value / 100.0))
		"voice_volume":
			var bus_idx = AudioServer.get_bus_index("Voice")
			if bus_idx >= 0:
				AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value / 100.0))


func _apply_graphics_setting(key: String, value: Variant) -> void:
	match key:
		"display_mode":
			match value:
				0: # Windowed
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
					DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
				1: # Borderless
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
					DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
					var screen_size = DisplayServer.screen_get_size()
					DisplayServer.window_set_size(screen_size)
					DisplayServer.window_set_position(Vector2i.ZERO)
				2: # Fullscreen
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"resolution_index":
			if value >= 0 and value < RESOLUTIONS.size():
				var res = RESOLUTIONS[value]
				DisplayServer.window_set_size(res)
				# Center window
				var screen_size = DisplayServer.screen_get_size()
				var pos = (screen_size - res) / 2
				DisplayServer.window_set_position(pos)
		"vsync":
			if value:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			else:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		"fps_limit":
			Engine.max_fps = value
		"msaa":
			var viewport = get_viewport()
			if viewport:
				match value:
					0: viewport.msaa_3d = Viewport.MSAA_DISABLED
					1: viewport.msaa_3d = Viewport.MSAA_2X
					2: viewport.msaa_3d = Viewport.MSAA_4X
					3: viewport.msaa_3d = Viewport.MSAA_8X


func _apply_controls_setting(key: String, _value: Variant) -> void:
	# Controls are applied when checking input
	pass


func _apply_gameplay_setting(key: String, _value: Variant) -> void:
	# Gameplay settings are read when needed
	pass


func _apply_accessibility_setting(key: String, _value: Variant) -> void:
	# Accessibility settings are applied by UI components
	pass


# =============================================================================
# UTILITY
# =============================================================================

func get_resolution_names() -> Array[String]:
	return RESOLUTION_NAMES.duplicate()


func get_current_resolution() -> Vector2i:
	var idx = settings["graphics"]["resolution_index"]
	if idx >= 0 and idx < RESOLUTIONS.size():
		return RESOLUTIONS[idx]
	return RESOLUTIONS[0]
