## Character Model Loader
## Centralized manager for loading 3D character models and card art textures.
## Maps troop/NPC IDs to their respective asset files.
class_name CharacterModelLoader
extends RefCounted

# =============================================================================
# MODEL PATHS
# =============================================================================
## Maps troop_id -> GLB model file path
const MODEL_PATHS: Dictionary = {
	"medieval_knight": "res://assets/models/characters/medieval_knight_3d_model_still.glb",
	"stone_giant": "res://assets/models/characters/stone_giant_3d_model_still.glb",
	"four_headed_hydra": "res://assets/models/characters/four_headed_hydra_3d_model_still.glb",
	"dark_blood_dragon": "res://assets/models/characters/dark_dragon_3d_model_still.glb",
	"sky_serpent": "res://assets/models/characters/sky_serpent_3d_model_still.glb",
	"frost_valkyrie": "res://assets/models/characters/frost_valkery_3d_model_still.glb",
	"dark_magic_wizard": "res://assets/models/characters/dark_magic_wizard_3d_model_still.glb",
	"demon_of_darkness": "res://assets/models/characters/demon_of_darkness_3d_model_still.glb",
	"elven_archer": "res://assets/models/characters/elven_archer_3d_model_still.glb",
	"celestial_cleric": "res://assets/models/characters/celestial_cleric_3d_model_still.glb",
	"shadow_assassin": "res://assets/models/characters/shadow_assassin_3d_model_still.glb",
	"infernal_soul": "res://assets/models/characters/infernal_soul_3d_model_still.glb",
}

# =============================================================================
# CARD ART PATHS
# =============================================================================
## Maps troop_id -> card art texture file path
const CARD_ART_PATHS: Dictionary = {
	"medieval_knight": "res://assets/textures/cards/medieval_knight.png",
	"stone_giant": "res://assets/textures/cards/stone_giant.PNG",
	"four_headed_hydra": "res://assets/textures/cards/four_headed_hydra.png",
	"dark_blood_dragon": "res://assets/textures/cards/dark_dragon.PNG",
	"sky_serpent": "res://assets/textures/cards/sky_serpent.png",
	"frost_valkyrie": "res://assets/textures/cards/frost_valkery.png",
	"dark_magic_wizard": "res://assets/textures/cards/dark_magic_wizard.png",
	"demon_of_darkness": "res://assets/textures/cards/demon_of_darkness.png",
	"elven_archer": "res://assets/textures/cards/elven_archer.png",
	"celestial_cleric": "res://assets/textures/cards/celestial_cleric.png",
	"shadow_assassin": "res://assets/textures/cards/shadow_assassin.png",
	"infernal_soul": "res://assets/textures/cards/infernal_soul.png",
	# NPC cards
	"goblin": "res://assets/textures/cards/goblin.png",
	"orc": "res://assets/textures/cards/orc.png",
	"troll": "res://assets/textures/cards/troll.png",
}

# =============================================================================
# MODEL SCALE OVERRIDES
# =============================================================================
## All models are normalized to ~1.0 unit native height by the AI generation tool.
## Scale factor = desired world height in units.
## Reference: Medieval Knight = 1.8 units tall (baseline human, ~1 hex diameter).
## Creatures are scaled relative to the Knight for gameplay clarity on the board.
## NOTE: These are BOARD GAME scales, not realistic scales. A 5x dragon would
## dwarf the entire playing field, so we use more modest ratios that still
## convey a clear size hierarchy.
const MODEL_SCALES: Dictionary = {
	# --- Human-sized (1.0x Knight = 1.8 units) ---
	"medieval_knight": Vector3(0.54, 0.54, 0.54),
	"shadow_assassin": Vector3(0.51, 0.51, 0.51),
	"elven_archer": Vector3(0.54, 0.54, 0.54),
	
	# --- Large Humanoid (1.2-1.5x Knight) ---
	"dark_magic_wizard": Vector3(0.57, 0.57, 0.57),
	"frost_valkyrie": Vector3(0.66, 0.66, 0.66),
	"celestial_cleric": Vector3(0.6, 0.6, 0.6),
	"demon_of_darkness": Vector3(0.72, 0.72, 0.72),
	
	# --- Giant (2.0x Knight) ---
	"stone_giant": Vector3(1.62, 1.62, 1.62), # 1.5x of 1.08
	
	# --- Massive Creature (2.5-3.0x Knight) ---
	"dark_blood_dragon": Vector3(1.76, 1.76, 1.76), # ~1.3x of 1.35
	"four_headed_hydra": Vector3(1.8, 1.8, 1.8), # 1.5x of 1.2
	
	# --- Aerial/Serpent ---
	"sky_serpent": Vector3(1.37, 1.37, 1.37), # ~1.3x of 1.05
	
	# --- Small (Originally) ---
	"infernal_soul": Vector3(0.72, 0.72, 0.72), # 2x of 0.36
}

# =============================================================================
# MODEL Y OFFSET
# =============================================================================
## Vertical offset to position model correctly on the hex tile surface.
## Most models have minY=-0.5 (centered at origin), so they need to be lifted
## by (scale * 0.5) to sit on the ground. The offset here is ADDED to the
## model's local position AFTER scaling.
const MODEL_Y_OFFSETS: Dictionary = {
	# Centered models (minY≈-0.5): offset = scale * 0.5
	"medieval_knight": 0.27,
	"shadow_assassin": 0.255,
	"elven_archer": 0.27,
	"frost_valkyrie": 0.33,
	"celestial_cleric": 0.3,
	"demon_of_darkness": 0.36,
	"stone_giant": 0.81, # 1.62 * 0.5
	"four_headed_hydra": 0.9, # 1.8 * 0.5
	"sky_serpent": 0.68, # 1.37 * 0.5
	"infernal_soul": 0.36, # 0.72 * 0.5
	
	# Ground-based models (minY≈0): feet already at origin, no lift needed
	"dark_magic_wizard": 0.0,
	"dark_blood_dragon": 0.88, # 1.76 * 0.5
}

# =============================================================================
# MODEL ROTATION (degrees around Y axis)
# =============================================================================
## Rotation correction so models face -Z (Godot's default forward direction).
## This is the model's OWN facing correction (separate from player team rotation
## which is handled in main.gd's _create_troop).
##
## Determined by bounding box analysis:
## - "Z-deep" models (depth > width): likely face -Z by default -> 0° correction
## - "X-wide" models (width > depth): face sideways -> need 90° correction
## - Adjustments made based on visual inspection from screenshots
const MODEL_ROTATIONS: Dictionary = {
	# Z-axis facing models (depth > width) - face -Z by default
	"medieval_knight": 180.0, # Faces +Z natively, flip to -Z
	"shadow_assassin": 180.0,
	"dark_magic_wizard": 180.0,
	"demon_of_darkness": 180.0,
	"frost_valkyrie": 180.0,
	"infernal_soul": 180.0,
	"stone_giant": 180.0,
	"celestial_cleric": 180.0,
	"elven_archer": 180.0,
	
	# X-axis wide models - wingspan extends along X, face along Z
	"dark_blood_dragon": 180.0, # Wide along X, rotate to face -Z
	"sky_serpent": 270.0, # Wide along X, flipped to face correct direction
	
	# Square-ish models - native orientation already correct
	"four_headed_hydra": 0.0, # Faces correct direction natively (was 180° = backwards)
}

# =============================================================================
# CACHED RESOURCES
# =============================================================================
## Cache for loaded PackedScene/model resources to avoid reloading
static var _model_cache: Dictionary = {}
## Cache for loaded card art textures
static var _card_art_cache: Dictionary = {}


# =============================================================================
# PUBLIC METHODS - 3D MODELS
# =============================================================================

## Load and instantiate a 3D model for a given troop ID.
## Returns the instantiated Node3D with correct scale and rotation applied,
## or null if the model cannot be loaded.
static func load_character_model(troop_id: String) -> Node3D:
	var model_path = MODEL_PATHS.get(troop_id, "")
	if model_path.is_empty():
		push_warning("CharacterModelLoader: No model path for troop '%s'" % troop_id)
		return null
	
	# Check if we already know this model fails to load
	if _model_cache.has(troop_id) and _model_cache[troop_id] == null:
		return null # Previously failed, don't retry
	
	# Check cache first
	if not _model_cache.has(troop_id):
		if not ResourceLoader.exists(model_path):
			push_warning("CharacterModelLoader: Model not found (may need reimport in Godot Editor): %s" % model_path)
			_model_cache[troop_id] = null # Mark as failed
			return null
		
		var resource = load(model_path)
		if resource == null:
			push_warning("CharacterModelLoader: Failed to load model (import may have failed - try reopening Godot Editor): %s" % model_path)
			_model_cache[troop_id] = null # Mark as failed
			return null
		
		if not (resource is PackedScene):
			push_warning("CharacterModelLoader: Resource is not a PackedScene (unexpected type: %s): %s" % [resource.get_class(), model_path])
			_model_cache[troop_id] = null # Mark as failed
			return null
		
		_model_cache[troop_id] = resource
		print("CharacterModelLoader: Successfully loaded model for '%s'" % troop_id)
	
	# Instantiate the cached scene
	var packed_scene: PackedScene = _model_cache[troop_id] as PackedScene
	if packed_scene == null:
		return null
	
	var instance = packed_scene.instantiate() as Node3D
	if instance == null:
		push_error("CharacterModelLoader: Failed to instantiate model for '%s'" % troop_id)
		return null
	
	# Apply scale
	var model_scale = MODEL_SCALES.get(troop_id, Vector3.ONE)
	instance.scale = model_scale
	
	# Apply Y offset
	var y_offset = MODEL_Y_OFFSETS.get(troop_id, 0.0)
	instance.position.y = y_offset
	
	# Apply rotation (model-specific correction, separate from player-facing rotation)
	var rotation_deg = MODEL_ROTATIONS.get(troop_id, 0.0)
	if rotation_deg != 0.0:
		instance.rotation_degrees.y = rotation_deg
	
	instance.name = "CharacterModel"
	return instance


## Check if a model exists for the given troop ID.
## Note: Returns true if the path is mapped AND the resource exists in the project.
## Models with valid=false in their .import file will return false here.
static func has_model(troop_id: String) -> bool:
	# If we already know this model fails, return false immediately
	if _model_cache.has(troop_id) and _model_cache[troop_id] == null:
		return false
	# If we have it cached successfully, it definitely exists
	if _model_cache.has(troop_id) and _model_cache[troop_id] != null:
		return true
	
	var model_path = MODEL_PATHS.get(troop_id, "")
	if model_path.is_empty():
		return false
	return ResourceLoader.exists(model_path)


# =============================================================================
# PUBLIC METHODS - CARD ART
# =============================================================================

## Load the framed card art texture for a given troop/NPC ID.
static func load_framed_card_art(troop_id: String) -> Texture2D:
	var art_path = CARD_ART_PATHS.get(troop_id, "")
	if art_path.is_empty():
		return null
		
	var ext = art_path.get_extension()
	var base = art_path.trim_suffix("." + ext)
	var framed_path = base + "_framed." + ext
	
	if ResourceLoader.exists(framed_path):
		var framed_id = troop_id + "_framed"
		if _card_art_cache.has(framed_id):
			return _card_art_cache[framed_id]
			
		var texture = load(framed_path) as Texture2D
		if texture:
			_card_art_cache[framed_id] = texture
			return texture
			
	return load_card_art(troop_id)


## Load the card art texture for a given troop/NPC ID.
## Returns the Texture2D or null if not found.
static func load_card_art(troop_id: String) -> Texture2D:
	# Check cache first
	if _card_art_cache.has(troop_id):
		return _card_art_cache[troop_id]
	
	var art_path = CARD_ART_PATHS.get(troop_id, "")
	if art_path.is_empty():
		push_warning("CharacterModelLoader: No card art path for '%s'" % troop_id)
		return null
	
	if not ResourceLoader.exists(art_path):
		push_warning("CharacterModelLoader: Card art file not found: %s" % art_path)
		return null
	
	var texture = load(art_path) as Texture2D
	if texture:
		_card_art_cache[troop_id] = texture
	
	return texture


## Check if card art exists for the given troop/NPC ID
static func has_card_art(troop_id: String) -> bool:
	var art_path = CARD_ART_PATHS.get(troop_id, "")
	if art_path.is_empty():
		return false
	return ResourceLoader.exists(art_path)


# =============================================================================
# UTILITY
# =============================================================================

## Clear all cached resources (useful for memory management)
static func clear_cache() -> void:
	_model_cache.clear()
	_card_art_cache.clear()


## Get the model path for a troop ID (for debugging/logging)
static func get_model_path(troop_id: String) -> String:
	return MODEL_PATHS.get(troop_id, "")


## Get the card art path for a troop ID (for debugging/logging)
static func get_card_art_path(troop_id: String) -> String:
	return CARD_ART_PATHS.get(troop_id, "")
