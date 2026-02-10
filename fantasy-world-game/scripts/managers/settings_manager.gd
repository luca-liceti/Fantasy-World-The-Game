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
		"shadow_quality": 2, # 0=Off, 1=Low, 2=Medium, 3=High, 4=Ultra
		"ambient_occlusion": true,
		"bloom": true,
		"bloom_intensity": 0.8, # 0.0 - 1.0
		"camera_shake": true,
		"grass_quality": 2, # 0=Off, 1=Low, 2=Medium, 3=High (Witcher 3 style grass)
		"groove_textures": true, # Carved groove effects on table, stone border, biome tiles
		# Quality Settings System (for asset integration)
		"quality_preset": -1, # -1=Auto, 0=Low, 1=Medium, 2=High, 3=Ultra
		"texture_quality": 2, # 0=Low (512), 1=Medium (1024), 2=High (2048), 3=Ultra (4096)
		"model_quality": 2, # 0=Low (LOD2), 1=Medium (LOD1), 2=High (LOD0), 3=Ultra (LOD0+)
		"particle_quality": 2, # 0=Low (25%), 1=Medium (50%), 2=High (100%), 3=Ultra (100%+extras)
		"terrain_height_variation": true, # Toggle hex height variation
		"spell_effect_intensity": 1.0, # 0.0 - 1.0
		"antialiasing_mode": 2, # 0=Off, 1=FXAA, 2=TAA, 3=MSAA 2x, 4=MSAA 4x, 5=MSAA 8x
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
# QUALITY PRESET CONFIGURATIONS
# =============================================================================
# Based on asset_integration_master_plan.md specifications

## Quality preset names for UI display
const QUALITY_PRESET_NAMES: Array[String] = ["Low", "Medium", "High", "Ultra"]

## Texture size limits per quality level
const TEXTURE_SIZE_LIMITS: Array[int] = [512, 1024, 2048, 4096]

## Shadow atlas resolution per quality level (0 = disabled)
const SHADOW_ATLAS_SIZES: Array[int] = [0, 512, 2048, 4096]

## Particle count multipliers per quality level
const PARTICLE_MULTIPLIERS: Array[float] = [0.25, 0.5, 1.0, 1.0]

## LOD bias per quality level (higher = more aggressive LOD switching)
const LOD_BIASES: Array[float] = [2.0, 1.0, 0.5, 0.0]

## Quality preset definitions
## Each preset is a dictionary of graphics settings to apply
const QUALITY_PRESETS: Dictionary = {
	# LOW PRESET (Work Laptops, Integrated Graphics)
	# Target: 30 FPS minimum
	0: {
		"texture_quality": 0,      # 512x512 textures
		"model_quality": 0,        # LOD2 (30% polygons)
		"shadow_quality": 0,       # Off
		"particle_quality": 0,     # 25% particles
		"grass_quality": 0,        # Off (performance)
		"groove_textures": false,  # Off (performance)
		"terrain_height_variation": false,
		"spell_effect_intensity": 0.5,
		"antialiasing_mode": 0,    # Off
		"ambient_occlusion": false,
		"bloom": false,
		"bloom_intensity": 0.0,
		"vsync": true
	},
	# MEDIUM PRESET (Mid-Range Laptops, GTX 1050-1650)
	# Target: 60 FPS
	1: {
		"texture_quality": 1,      # 1024x1024 textures
		"model_quality": 1,        # LOD1 (60% polygons)
		"shadow_quality": 1,       # Low (512x512)
		"particle_quality": 1,     # 50% particles
		"grass_quality": 1,        # Low density
		"groove_textures": true,   # Enabled (minimal performance cost)
		"terrain_height_variation": false,
		"spell_effect_intensity": 0.75,
		"antialiasing_mode": 1,    # FXAA
		"ambient_occlusion": false,
		"bloom": true,
		"bloom_intensity": 0.5,
		"vsync": true
	},
	# HIGH PRESET (Gaming Laptops, RTX 2060-3060)
	# Target: 60 FPS stable
	2: {
		"texture_quality": 2,      # 2048x2048 textures
		"model_quality": 2,        # LOD0 (100% polygons)
		"shadow_quality": 2,       # Medium (2048x2048, soft)
		"particle_quality": 2,     # 100% particles
		"grass_quality": 2,        # Medium density
		"groove_textures": true,   # Enabled
		"terrain_height_variation": true,
		"spell_effect_intensity": 1.0,
		"antialiasing_mode": 2,    # TAA
		"ambient_occlusion": true,
		"bloom": true,
		"bloom_intensity": 0.8,
		"vsync": true
	},
	# ULTRA PRESET (Gaming Desktops, RTX 3070+)
	# Target: 120+ FPS
	3: {
		"texture_quality": 3,      # 4096x4096 textures
		"model_quality": 3,        # LOD0 (100% + best textures)
		"shadow_quality": 3,       # High (4096x4096, PCF)
		"particle_quality": 3,     # 100% + extra detail
		"grass_quality": 3,        # High density (Witcher 3 style)
		"groove_textures": true,   # Enabled
		"terrain_height_variation": true,
		"spell_effect_intensity": 1.0,
		"antialiasing_mode": 4,    # MSAA 4x
		"ambient_occlusion": true,
		"bloom": true,
		"bloom_intensity": 1.0,
		"vsync": false             # Allow unlocked FPS
	}
}

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
		"grass_quality":
			# Apply grass quality to the GrassSystem
			var quality = clampi(value, 0, 3)
			if quality == 0:
				GrassSystem.set_grass_enabled(false)
			else:
				GrassSystem.set_grass_enabled(true)
				GrassSystem.set_grass_quality(quality)
			print("[SettingsManager] Grass quality set to: %d" % quality)
		"groove_textures":
			# Groove textures setting is read by BiomeMaterialManager and BoardEnvironment
			# Changes require scene reload to take full effect
			print("[SettingsManager] Groove textures: %s" % ("Enabled" if value else "Disabled"))


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


# =============================================================================
# QUALITY SETTINGS SYSTEM
# =============================================================================

## Detect hardware capabilities and return recommended preset level
## Returns: 0=Low, 1=Medium, 2=High, 3=Ultra
func detect_hardware_preset() -> int:
	# Get GPU information
	var adapter_name = RenderingServer.get_video_adapter_name().to_lower()
	
	# Try to estimate VRAM (Godot 4 doesn't have direct VRAM access)
	# We use heuristics based on GPU name
	var estimated_vram_mb = _estimate_vram_from_gpu(adapter_name)
	
	print("Detected GPU: %s (estimated VRAM: %d MB)" % [adapter_name, estimated_vram_mb])
	
	# Determine preset based on estimated VRAM
	if estimated_vram_mb < 2000:  # Less than 2GB VRAM
		return 0  # Low preset
	elif estimated_vram_mb < 4000:  # 2-4GB VRAM
		return 1  # Medium preset
	elif estimated_vram_mb < 8000:  # 4-8GB VRAM
		return 2  # High preset
	else:  # 8GB+ VRAM
		return 3  # Ultra preset


## Estimate VRAM based on GPU name patterns
func _estimate_vram_from_gpu(gpu_name: String) -> int:
	# Check for integrated graphics (typically low VRAM)
	if "intel" in gpu_name and ("hd" in gpu_name or "uhd" in gpu_name or "iris" in gpu_name):
		return 1024  # Integrated Intel
	if "amd" in gpu_name and ("vega" in gpu_name or "radeon graphics" in gpu_name):
		return 1024  # Integrated AMD
	
	# NVIDIA cards
	if "rtx 4090" in gpu_name or "rtx 4080" in gpu_name:
		return 16000
	if "rtx 4070" in gpu_name or "rtx 3090" in gpu_name or "rtx 3080" in gpu_name:
		return 12000
	if "rtx 3070" in gpu_name or "rtx 4060" in gpu_name:
		return 8000
	if "rtx 3060" in gpu_name or "rtx 2080" in gpu_name:
		return 8000
	if "rtx 2070" in gpu_name or "rtx 2060" in gpu_name:
		return 6000
	if "gtx 1080" in gpu_name or "gtx 1070" in gpu_name:
		return 8000
	if "gtx 1660" in gpu_name or "gtx 1650" in gpu_name:
		return 4000
	if "gtx 1050" in gpu_name or "gtx 1060" in gpu_name:
		return 4000
	if "gtx 960" in gpu_name or "gtx 970" in gpu_name or "gtx 980" in gpu_name:
		return 4000
	
	# AMD cards  
	if "rx 7900" in gpu_name or "rx 6900" in gpu_name:
		return 16000
	if "rx 7800" in gpu_name or "rx 6800" in gpu_name:
		return 16000
	if "rx 7700" in gpu_name or "rx 6700" in gpu_name:
		return 12000
	if "rx 7600" in gpu_name or "rx 6600" in gpu_name:
		return 8000
	if "rx 580" in gpu_name or "rx 590" in gpu_name:
		return 8000
	if "rx 570" in gpu_name or "rx 560" in gpu_name:
		return 4000
	
	# Default assumption for unknown GPUs
	return 4000


## Apply a quality preset by level (0=Low, 1=Medium, 2=High, 3=Ultra)
func apply_quality_preset(level: int, auto_save: bool = true) -> void:
	if level < 0 or level > 3:
		push_warning("Invalid quality preset level: %d, using Medium" % level)
		level = 1
	
	var preset = QUALITY_PRESETS[level]
	
	print("Applying %s quality preset..." % QUALITY_PRESET_NAMES[level])
	
	# Apply all settings from preset
	for key in preset.keys():
		var path = "graphics/" + key
		set_setting(path, preset[key], false)  # Don't auto-save each one
	
	# Update the preset setting itself
	settings["graphics"]["quality_preset"] = level
	
	# Apply all graphics settings
	for key in settings["graphics"].keys():
		_apply_graphics_setting(key, settings["graphics"][key])
	
	if auto_save:
		save_settings()
	
	settings_changed.emit("graphics", "quality_preset", level)
	print("Quality preset applied: %s" % QUALITY_PRESET_NAMES[level])


## Set texture quality (0=Low/512, 1=Medium/1024, 2=High/2048, 3=Ultra/4096)
func set_texture_quality(level: int) -> void:
	level = clampi(level, 0, 3)
	var size_limit = TEXTURE_SIZE_LIMITS[level]
	
	# Update rendering settings for texture quality
	var viewport = get_viewport()
	if viewport:
		# Note: Texture size limiting is typically done at import time
		# Runtime changes affect how textures are sampled
		match level:
			0:  # Low - use nearest filtering, reduce anisotropy
				ProjectSettings.set_setting("rendering/textures/default_filters/anisotropic_filtering_level", 2)
			1:  # Medium
				ProjectSettings.set_setting("rendering/textures/default_filters/anisotropic_filtering_level", 4)
			2:  # High
				ProjectSettings.set_setting("rendering/textures/default_filters/anisotropic_filtering_level", 8)
			3:  # Ultra
				ProjectSettings.set_setting("rendering/textures/default_filters/anisotropic_filtering_level", 16)
	
	set_setting("graphics/texture_quality", level)
	print("Texture quality set to: %s (%dx%d max)" % [QUALITY_PRESET_NAMES[level], size_limit, size_limit])


## Set model quality (LOD bias) (0=Low/LOD2, 1=Medium/LOD1, 2=High/LOD0, 3=Ultra/LOD0+)
func set_model_quality(level: int) -> void:
	level = clampi(level, 0, 3)
	var lod_bias = LOD_BIASES[level]
	
	# Apply LOD bias to all mesh instances in scene
	var viewport = get_viewport()
	if viewport:
		viewport.mesh_lod_threshold = lod_bias * 2.0  # Scale for Godot's threshold system
	
	set_setting("graphics/model_quality", level)
	print("Model quality set to: %s (LOD bias: %.1f)" % [QUALITY_PRESET_NAMES[level], lod_bias])


## Set shadow quality (0=Off, 1=Low/512, 2=Medium/2048, 3=High/4096)
func set_shadow_quality(level: int) -> void:
	level = clampi(level, 0, 3)
	var atlas_size = SHADOW_ATLAS_SIZES[level]
	
	# Set directional shadow atlas size
	if atlas_size == 0:
		RenderingServer.directional_shadow_atlas_set_size(256, false)
	else:
		RenderingServer.directional_shadow_atlas_set_size(atlas_size, level >= 2)
	
	# Configure shadow settings
	match level:
		0:  # Off
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_HARD)
		1:  # Low
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW)
		2:  # Medium
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM)
		3:  # High
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
	
	set_setting("graphics/shadow_quality", level)
	print("Shadow quality set to: %s (%dx%d atlas)" % [QUALITY_PRESET_NAMES[level] if level > 0 else "Off", atlas_size, atlas_size])


## Set particle quality (0=Low/25%, 1=Medium/50%, 2=High/100%, 3=Ultra/100%+)
func set_particle_quality(level: int) -> void:
	level = clampi(level, 0, 3)
	var multiplier = PARTICLE_MULTIPLIERS[level]
	
	# Store for use by particle systems
	set_setting("graphics/particle_quality", level)
	
	# Particle systems should query this setting and adjust their amount property
	print("Particle quality set to: %s (%.0f%% particles)" % [QUALITY_PRESET_NAMES[level], multiplier * 100])


## Get current particle multiplier (for use by particle systems)
func get_particle_multiplier() -> float:
	var level = get_setting("graphics/particle_quality")
	if level >= 0 and level < PARTICLE_MULTIPLIERS.size():
		return PARTICLE_MULTIPLIERS[level]
	return 1.0


## Set anti-aliasing mode (0=Off, 1=FXAA, 2=TAA, 3=MSAA 2x, 4=MSAA 4x, 5=MSAA 8x)
func set_antialiasing_mode(mode: int) -> void:
	mode = clampi(mode, 0, 5)
	var viewport = get_viewport()
	
	if viewport:
		# Reset all AA first
		viewport.msaa_3d = Viewport.MSAA_DISABLED
		viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		viewport.use_taa = false
		
		match mode:
			0:  # Off
				pass
			1:  # FXAA
				viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
			2:  # TAA
				viewport.use_taa = true
			3:  # MSAA 2x
				viewport.msaa_3d = Viewport.MSAA_2X
			4:  # MSAA 4x
				viewport.msaa_3d = Viewport.MSAA_4X
			5:  # MSAA 8x
				viewport.msaa_3d = Viewport.MSAA_8X
	
	set_setting("graphics/antialiasing_mode", mode)
	var mode_names = ["Off", "FXAA", "TAA", "MSAA 2x", "MSAA 4x", "MSAA 8x"]
	print("Anti-aliasing set to: %s" % mode_names[mode])


## Set ambient occlusion enabled
func set_ambient_occlusion(enabled: bool) -> void:
	# This needs to be applied to the WorldEnvironment
	# Stored in settings, applied when environment is loaded
	set_setting("graphics/ambient_occlusion", enabled)
	print("Ambient Occlusion: %s" % ("Enabled" if enabled else "Disabled"))


## Set bloom enabled with optional intensity
func set_bloom(enabled: bool, intensity: float = 0.8) -> void:
	set_setting("graphics/bloom", enabled, false)
	set_setting("graphics/bloom_intensity", intensity, true)
	print("Bloom: %s (intensity: %.1f)" % ["Enabled" if enabled else "Disabled", intensity])


## Auto-detect and apply appropriate quality preset on first run
func auto_detect_and_apply_quality() -> void:
	var current_preset = get_setting("graphics/quality_preset")
	
	if current_preset == -1:  # -1 means auto-detect
		var detected_level = detect_hardware_preset()
		print("Auto-detected hardware capability: %s preset recommended" % QUALITY_PRESET_NAMES[detected_level])
		apply_quality_preset(detected_level)
	else:
		print("Using saved quality preset: %s" % QUALITY_PRESET_NAMES[current_preset])


## Get quality preset names for UI display
func get_quality_preset_names() -> Array[String]:
	return QUALITY_PRESET_NAMES.duplicate()


## Get current quality preset level
func get_current_quality_preset() -> int:
	return get_setting("graphics/quality_preset")
