## Combat Audio Manager
## Handles audio events for the enhanced combat system
## Placeholder system ready for audio asset integration
class_name CombatAudioManager
extends Node

# =============================================================================
# AUDIO BUS
# =============================================================================
const AUDIO_BUS_COMBAT = "Combat"
const AUDIO_BUS_UI = "UI"

# =============================================================================
# AUDIO EVENTS
# =============================================================================
## Define all combat audio events here
## Format: event_name -> { "path": resource_path, "volume": db, "pitch_variance": float }

const AUDIO_EVENTS = {
	# UI/Selection sounds
	"move_hover": {
		"path": "res://assets/audio/sfx/combat/move_hover.ogg",
		"volume": -10.0,
		"pitch_variance": 0.05,
		"bus": "UI"
	},
	"move_select": {
		"path": "res://assets/audio/sfx/combat/move_select.ogg",
		"volume": -5.0,
		"pitch_variance": 0.0,
		"bus": "UI"
	},
	"stance_select": {
		"path": "res://assets/audio/sfx/combat/stance_select.ogg",
		"volume": -5.0,
		"pitch_variance": 0.0,
		"bus": "UI"
	},
	"ready_confirm": {
		"path": "res://assets/audio/sfx/combat/ready_confirm.ogg",
		"volume": -3.0,
		"pitch_variance": 0.0,
		"bus": "UI"
	},
	"timer_tick": {
		"path": "res://assets/audio/sfx/combat/timer_tick.ogg",
		"volume": -8.0,
		"pitch_variance": 0.0,
		"bus": "UI"
	},
	"timer_warning": {
		"path": "res://assets/audio/sfx/combat/timer_warning.ogg",
		"volume": -5.0,
		"pitch_variance": 0.0,
		"bus": "UI"
	},
	
	# Dice sounds
	"dice_roll": {
		"path": "res://assets/audio/sfx/combat/dice_roll.ogg",
		"volume": -5.0,
		"pitch_variance": 0.1,
		"bus": "Combat"
	},
	"dice_result": {
		"path": "res://assets/audio/sfx/combat/dice_result.ogg",
		"volume": -3.0,
		"pitch_variance": 0.05,
		"bus": "Combat"
	},
	
	# Combat result sounds
	"hit_normal": {
		"path": "res://assets/audio/sfx/combat/hit_normal.ogg",
		"volume": -5.0,
		"pitch_variance": 0.1,
		"bus": "Combat"
	},
	"hit_critical": {
		"path": "res://assets/audio/sfx/combat/hit_critical.ogg",
		"volume": 0.0,
		"pitch_variance": 0.05,
		"bus": "Combat"
	},
	"miss": {
		"path": "res://assets/audio/sfx/combat/miss.ogg",
		"volume": -8.0,
		"pitch_variance": 0.1,
		"bus": "Combat"
	},
	"dodge": {
		"path": "res://assets/audio/sfx/combat/dodge.ogg",
		"volume": -5.0,
		"pitch_variance": 0.05,
		"bus": "Combat"
	},
	"block": {
		"path": "res://assets/audio/sfx/combat/block.ogg",
		"volume": -5.0,
		"pitch_variance": 0.05,
		"bus": "Combat"
	},
	"counter": {
		"path": "res://assets/audio/sfx/combat/counter.ogg",
		"volume": -3.0,
		"pitch_variance": 0.0,
		"bus": "Combat"
	},
	"endure": {
		"path": "res://assets/audio/sfx/combat/endure.ogg",
		"volume": -3.0,
		"pitch_variance": 0.0,
		"bus": "Combat"
	},
	
	# Damage type sounds
	"damage_physical": {
		"path": "res://assets/audio/sfx/combat/damage_physical.ogg",
		"volume": -5.0,
		"pitch_variance": 0.15,
		"bus": "Combat"
	},
	"damage_fire": {
		"path": "res://assets/audio/sfx/combat/damage_fire.ogg",
		"volume": -5.0,
		"pitch_variance": 0.1,
		"bus": "Combat"
	},
	"damage_ice": {
		"path": "res://assets/audio/sfx/combat/damage_ice.ogg",
		"volume": -5.0,
		"pitch_variance": 0.1,
		"bus": "Combat"
	},
	"damage_dark": {
		"path": "res://assets/audio/sfx/combat/damage_dark.ogg",
		"volume": -5.0,
		"pitch_variance": 0.1,
		"bus": "Combat"
	},
	"damage_holy": {
		"path": "res://assets/audio/sfx/combat/damage_holy.ogg",
		"volume": -5.0,
		"pitch_variance": 0.1,
		"bus": "Combat"
	},
	"damage_nature": {
		"path": "res://assets/audio/sfx/combat/damage_nature.ogg",
		"volume": -5.0,
		"pitch_variance": 0.1,
		"bus": "Combat"
	},
	
	# Status effect sounds
	"status_apply": {
		"path": "res://assets/audio/sfx/combat/status_apply.ogg",
		"volume": -5.0,
		"pitch_variance": 0.05,
		"bus": "Combat"
	},
	"status_stunned": {
		"path": "res://assets/audio/sfx/combat/status_stunned.ogg",
		"volume": -5.0,
		"pitch_variance": 0.0,
		"bus": "Combat"
	},
	"status_burned": {
		"path": "res://assets/audio/sfx/combat/status_burned.ogg",
		"volume": -5.0,
		"pitch_variance": 0.0,
		"bus": "Combat"
	},
	"status_poisoned": {
		"path": "res://assets/audio/sfx/combat/status_poisoned.ogg",
		"volume": -5.0,
		"pitch_variance": 0.0,
		"bus": "Combat"
	},
	"status_tick": {
		"path": "res://assets/audio/sfx/combat/status_tick.ogg",
		"volume": -8.0,
		"pitch_variance": 0.1,
		"bus": "Combat"
	},
	
	# Type effectiveness
	"super_effective": {
		"path": "res://assets/audio/sfx/combat/super_effective.ogg",
		"volume": -3.0,
		"pitch_variance": 0.0,
		"bus": "Combat"
	},
	"not_effective": {
		"path": "res://assets/audio/sfx/combat/not_effective.ogg",
		"volume": -5.0,
		"pitch_variance": 0.0,
		"bus": "Combat"
	},
	"immune": {
		"path": "res://assets/audio/sfx/combat/immune.ogg",
		"volume": -5.0,
		"pitch_variance": 0.0,
		"bus": "Combat"
	},
	
	# Death/kill sounds
	"troop_death": {
		"path": "res://assets/audio/sfx/combat/troop_death.ogg",
		"volume": -3.0,
		"pitch_variance": 0.1,
		"bus": "Combat"
	},
	"death_burst": {
		"path": "res://assets/audio/sfx/combat/death_burst.ogg",
		"volume": 0.0,
		"pitch_variance": 0.0,
		"bus": "Combat"
	}
}

# =============================================================================
# AUDIO PLAYERS
# =============================================================================
var audio_pool: Array[AudioStreamPlayer] = []
var audio_3d_pool: Array[AudioStreamPlayer3D] = []
const POOL_SIZE = 8

# Cached audio streams
var loaded_streams: Dictionary = {}


# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	_create_audio_pools()
	_preload_common_sounds()


func _create_audio_pools() -> void:
	# 2D audio pool
	for i in range(POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = AUDIO_BUS_COMBAT
		add_child(player)
		audio_pool.append(player)
	
	# 3D audio pool
	for i in range(POOL_SIZE):
		var player = AudioStreamPlayer3D.new()
		player.bus = AUDIO_BUS_COMBAT
		add_child(player)
		audio_3d_pool.append(player)


func _preload_common_sounds() -> void:
	# Preload commonly used sounds
	var common_events = ["hit_normal", "hit_critical", "miss", "dice_roll"]
	for event_name in common_events:
		_get_audio_stream(event_name)


func _get_audio_stream(event_name: String) -> AudioStream:
	if event_name in loaded_streams:
		return loaded_streams[event_name]
	
	if event_name not in AUDIO_EVENTS:
		return null
	
	var path = AUDIO_EVENTS[event_name]["path"]
	
	# Check if file exists (for placeholder system)
	if not ResourceLoader.exists(path):
		# Use placeholder or return null
		return null
	
	var stream = load(path) as AudioStream
	loaded_streams[event_name] = stream
	return stream


# =============================================================================
# PUBLIC API
# =============================================================================

## Play a 2D audio event
func play(event_name: String) -> void:
	var stream = _get_audio_stream(event_name)
	if stream == null:
		# Placeholder: just print when audio would play
		print("[Audio] Would play: %s" % event_name)
		return
	
	var player = _get_available_player()
	if player == null:
		return
	
	var event_data = AUDIO_EVENTS.get(event_name, {})
	
	player.stream = stream
	player.volume_db = event_data.get("volume", 0.0)
	player.bus = event_data.get("bus", AUDIO_BUS_COMBAT)
	
	# Apply pitch variance
	var pitch_variance = event_data.get("pitch_variance", 0.0)
	if pitch_variance > 0:
		player.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
	else:
		player.pitch_scale = 1.0
	
	player.play()


## Play a 3D positional audio event
func play_at_position(event_name: String, position: Vector3) -> void:
	var stream = _get_audio_stream(event_name)
	if stream == null:
		print("[Audio 3D] Would play: %s at %s" % [event_name, position])
		return
	
	var player = _get_available_3d_player()
	if player == null:
		return
	
	var event_data = AUDIO_EVENTS.get(event_name, {})
	
	player.stream = stream
	player.volume_db = event_data.get("volume", 0.0)
	player.bus = event_data.get("bus", AUDIO_BUS_COMBAT)
	player.global_position = position
	
	# Apply pitch variance
	var pitch_variance = event_data.get("pitch_variance", 0.0)
	if pitch_variance > 0:
		player.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
	else:
		player.pitch_scale = 1.0
	
	player.play()


func _get_available_player() -> AudioStreamPlayer:
	for player in audio_pool:
		if not player.playing:
			return player
	# All players busy, return the first one (oldest sound)
	return audio_pool[0]


func _get_available_3d_player() -> AudioStreamPlayer3D:
	for player in audio_3d_pool:
		if not player.playing:
			return player
	return audio_3d_pool[0]


# =============================================================================
# CONVENIENCE METHODS
# =============================================================================

## Play appropriate sound for combat hit
func play_hit_sound(is_critical: bool, damage_type: String) -> void:
	if is_critical:
		play("hit_critical")
	else:
		play("hit_normal")
	
	# Also play damage type sound
	var damage_event = "damage_" + damage_type.to_lower()
	if damage_event in AUDIO_EVENTS:
		play(damage_event)


## Play miss sound
func play_miss_sound() -> void:
	play("miss")


## Play stance-specific sound
func play_stance_sound(stance_name: String) -> void:
	var event_name = stance_name.to_lower()
	if event_name in AUDIO_EVENTS:
		play(event_name)


## Play status effect sound
func play_status_effect_sound(effect_id: String) -> void:
	var event_name = "status_" + effect_id.to_lower()
	if event_name in AUDIO_EVENTS:
		play(event_name)
	else:
		play("status_apply")


## Play type effectiveness feedback
func play_effectiveness_sound(effectiveness: float) -> void:
	if effectiveness > 1.0:
		play("super_effective")
	elif effectiveness < 1.0 and effectiveness > 0.0:
		play("not_effective")
	elif effectiveness == 0.0:
		play("immune")


## Play timer warning (last 5 seconds)
func play_timer_tick(seconds_remaining: float) -> void:
	if seconds_remaining <= 5.0 and seconds_remaining > 0:
		play("timer_tick")
	if seconds_remaining <= 3.0 and seconds_remaining > 0:
		play("timer_warning")
