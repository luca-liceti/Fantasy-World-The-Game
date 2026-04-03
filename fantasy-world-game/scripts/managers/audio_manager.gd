## Audio Manager (Autoload Singleton)
## Handles global audio events, background music, and ambient sounds.
extends Node

# =============================================================================
# CONSTANTS
# =============================================================================
const BGM_PATH = "res://assets/music/tavern_background_music_with_ambience.mp3"
const SFX_HOVER = "res://assets/sfx/button_hover.mp3"
const SFX_CARD_PICK = "res://assets/sfx/card_pick.mp3"
const FADE_IN_DURATION = 1 # Fades in music over 1.5 seconds
const AUDIO_BUS_MUSIC = "Music"
const AUDIO_BUS_SFX = "SFX"

# =============================================================================
# STATE
# =============================================================================
var bgm_player: AudioStreamPlayer = null
var bgm_stream: AudioStream = null
var _is_initialized: bool = false

# =============================================================================
# INITIALIZATION
# =============================================================================

func _ready() -> void:
	# Initialize the player and start background loading for the BGM
	_initialize_player()
	_prepare_stream()


func _initialize_player() -> void:
	if _is_initialized:
		return
		
	# Create the background music player
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BackgroundMusicPlayer"
	
	# Verify if the Music bus exists, if not use Master
	if AudioServer.get_bus_index(AUDIO_BUS_MUSIC) != -1:
		bgm_player.bus = AUDIO_BUS_MUSIC
	else:
		bgm_player.bus = "Master"
		print("[AudioManager] Warning: 'Music' bus not found, using 'Master'")
	
	add_child(bgm_player)
	_is_initialized = true


func _prepare_stream() -> void:
	# Request async loading of the track so it's ready when triggered
	if ResourceLoader.exists(BGM_PATH):
		ResourceLoader.load_threaded_request(BGM_PATH)
		print("[AudioManager] Background loading BGM: %s" % BGM_PATH)


# =============================================================================
# PUBLIC API
# =============================================================================

## Starts the tavern background music with a random offset and fade-in
func start_tavern_music() -> void:
	_initialize_player()
	
	if bgm_player.playing:
		return # Already playing
		
	# Retrieve the stream from the threaded loader or load it if not ready
	if not bgm_stream:
		if ResourceLoader.load_threaded_get_status(BGM_PATH) == ResourceLoader.THREAD_LOAD_LOADED:
			bgm_stream = ResourceLoader.load_threaded_get(BGM_PATH)
		else:
			# Fallback to sync load if not ready yet
			bgm_stream = load(BGM_PATH)
	
	if not bgm_stream:
		push_error("[AudioManager] Failed to load BGM: %s" % BGM_PATH)
		return
	
	# Enable infinite looping
	if bgm_stream is AudioStreamMP3:
		bgm_stream.loop = true
	elif bgm_stream is AudioStreamOggVorbis:
		bgm_stream.loop = true
	
	bgm_player.stream = bgm_stream
	
	# Calculate random start point
	var stream_length = bgm_stream.get_length()
	var random_start_time = randf_range(0.0, max(0.0, stream_length - 1.0))
	
	# Start with zero volume for fade-in
	bgm_player.volume_db = -80.0
	
	print("[AudioManager] Fading in tavern music from: %.2f seconds" % random_start_time)
	
	# Play from random offset
	bgm_player.play(random_start_time)
	
	# Fade in - synchronized with UI appearance
	var tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", 0.0, FADE_IN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


## Stop background music
func stop_music() -> void:
	if bgm_player and bgm_player.playing:
		bgm_player.stop()


## Resume background music
func resume_music() -> void:
	if bgm_player and not bgm_player.playing:
		# If we resume, we might want to fade in again
		bgm_player.volume_db = -80.0
		bgm_player.play()
		var tween = create_tween()
		tween.tween_property(bgm_player, "volume_db", 0.0, 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)


## Fade out and stop background music
func fade_out_music(duration: float = 2.0) -> void:
	if bgm_player and bgm_player.playing:
		var tween = create_tween()
		tween.tween_property(bgm_player, "volume_db", -80.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await tween.finished
		bgm_player.stop()


## Play a one-shot sound effect
func play_sfx(path: String, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if not ResourceLoader.exists(path):
		push_error("[AudioManager] SFX not found: %s" % path)
		return
		
	var stream = load(path)
	if not stream:
		return
		
	var sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = stream
	sfx_player.pitch_scale = pitch_scale
	sfx_player.volume_db = volume_db
	
	# Verify SFX bus
	if AudioServer.get_bus_index(AUDIO_BUS_SFX) != -1:
		sfx_player.bus = AUDIO_BUS_SFX
	else:
		sfx_player.bus = "Master"
		
	add_child(sfx_player)
	sfx_player.play()
	
	# Clean up after playing
	sfx_player.finished.connect(sfx_player.queue_free)


## Play the UI button hover sound
func play_ui_hover() -> void:
	# Subtle random pitch variation for better feel
	play_sfx(SFX_HOVER, randf_range(0.95, 1.05), -5.0)


## Play the card pick sound
func play_card_pick() -> void:
	play_sfx(SFX_CARD_PICK, 1.0, 0.0)
