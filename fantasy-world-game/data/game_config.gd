## Game Configuration
## Contains all game constants and configuration values
class_name GameConfig
extends RefCounted

# =============================================================================
# BOARD CONFIGURATION
# =============================================================================
const BOARD_SIZE: int = 12 # Hexagons per side (creates 397 total hexes)
const TOTAL_HEXES: int = 397 # 12-hex-per-side hexagonal board
const BOARD_LIFT: float = 1.0 # Height of hex tiles above table (matches border height)
const BORDER_HEIGHT: float = 1.0 # Fixed height of the board border rim (edge tiles connect here)
const TERRAIN_HEIGHT_MULTIPLIER: float = 1 # Global multiplier for terrain height exaggeration (2.0 = smooth slopes, 4.0+ = dramatic cliffs)

# =============================================================================
# GRAPHICS SETTINGS
# =============================================================================
## Grass quality levels: 0=Off, 1=Low, 2=Medium, 3=High
enum GrassQuality {
	OFF = 0,
	LOW = 1,
	MEDIUM = 2,
	HIGH = 3
}

## Default grass quality
const DEFAULT_GRASS_QUALITY: int = GrassQuality.MEDIUM

## Runtime grass settings (can be changed in-game)
static var grass_enabled: bool = true
static var grass_quality: int = DEFAULT_GRASS_QUALITY

## Apply grass settings to the GrassSystem
static func apply_grass_settings() -> void:
	if Engine.has_singleton("GrassSystem") or ClassDB.class_exists("GrassSystem"):
		GrassSystem.set_grass_enabled(grass_enabled)
		GrassSystem.set_grass_quality(grass_quality)

## Toggle grass on/off
static func set_grass_enabled(enabled: bool) -> void:
	grass_enabled = enabled
	GrassSystem.set_grass_enabled(enabled)

## Set grass quality level
static func set_grass_quality_level(quality: int) -> void:
	grass_quality = clampi(quality, 0, 3)
	GrassSystem.set_grass_quality(grass_quality)


# =============================================================================
# WORLD SCALE (1:1 REALISTIC)
# =============================================================================
# The game uses realistic scale for immersive troop-to-environment proportions.
# All assets should be created following these guidelines:
#
# UNIT SCALE:
#   - 1 Godot unit = 1 meter (real world)
#
# HEX TILE SCALE:
#   - hex_size = 1.0 (center to corner distance in units)
#   - Hex width = ~1.73 units (~1.73 meters)
#   - Each hex represents a tactical "space" for one combatant
#
# TROOP MODEL SCALE:
#   - Human-sized troops (knight, archer, cleric): 1.8 - 2.0 units tall
#   - Large troops (stone giant): 4.0 - 5.0 units tall
#   - Massive troops (hydra, dragon): 8.0 - 15.0 units tall
#   - Small creatures: 0.5 - 1.0 units tall
#
# TEXTURE SCALE:
#   - Biome textures use world-space UV at 0.03 scale
#   - This makes terrain features (rocks, leaves) visible at realistic size
#   - A rock in the texture appears ~0.5-2m in diameter

# =============================================================================
# PLAYER CONFIGURATION
# =============================================================================
const NUM_PLAYERS: int = 2 # 1v1 game
const STARTING_GOLD: int = 150
const STARTING_XP: int = 0
const CARDS_PER_PLAYER: int = 4
const SPAWN_HEXES_PER_PLAYER: int = 4

# =============================================================================
# TURN CONFIGURATION
# =============================================================================
const TURN_TIMER_OPTIONS: Array[int] = [60, 120] # 1 or 2 minutes
const DEFAULT_TURN_TIMER: int = 120 # 2 minutes default

# =============================================================================
# COMBAT CONFIGURATION
# =============================================================================
const DICE_TYPE: int = 20 # d20 dice (1-20 range)
const MAX_REROLLS: int = 3 # Maximum re-rolls on equal dice
const MIN_DAMAGE: int = 1 # Minimum damage dealt (even if DEF is high)

# =============================================================================
# COMBAT MODE (NEW PLAYER ACCESSIBILITY)
# =============================================================================
## Combat mode determines complexity level
enum CombatMode {
	SIMPLE, # Reduced complexity for new players
	ENHANCED # Full D&D × Pokémon hybrid system
}

## Default combat mode for new games
const DEFAULT_COMBAT_MODE: int = CombatMode.ENHANCED

## Simple Mode Configuration
const SIMPLE_MODE_CONFIG: Dictionary = {
	"moves_visible": 2, # Only show 2 moves (Standard + 1 Special)
	"auto_defender_stance": true, # Auto-select Brace for defender
	"timer_seconds": 15.0, # Extended timer (15 seconds)
	"show_damage_types": false, # Hide damage type complexity
	"show_advantage_disadvantage": false, # Hide adv/disadv
	"show_hit_chance": true, # Show simple hit %
	"show_positioning": false, # Hide positioning modifiers
	"hint_recommended_move": true, # Highlight best move
}

## Enhanced Mode Configuration (full complexity)
const ENHANCED_MODE_CONFIG: Dictionary = {
	"moves_visible": 4, # Show all 4 moves
	"auto_defender_stance": false, # Player chooses stance
	"timer_seconds": 10.0, # Standard timer
	"show_damage_types": true, # Show all damage types
	"show_advantage_disadvantage": true,
	"show_hit_chance": true,
	"show_positioning": true,
	"hint_recommended_move": false, # No hand-holding
}

## Get combat config for a given mode
static func get_combat_mode_config(mode: int) -> Dictionary:
	match mode:
		CombatMode.SIMPLE:
			return SIMPLE_MODE_CONFIG.duplicate()
		CombatMode.ENHANCED:
			return ENHANCED_MODE_CONFIG.duplicate()
		_:
			return ENHANCED_MODE_CONFIG.duplicate()

# =============================================================================
# GOLD MINE CONFIGURATION
# =============================================================================
const MAX_MINES_PER_PLAYER: int = 5
const MINE_PLACEMENT_COST: int = 100
const MIN_DISTANCE_BETWEEN_MINES: int = 3 # Minimum hexes between mines

# Gold mine upgrade costs
const MINE_UPGRADE_COSTS: Dictionary = {
	1: 100, # Initial placement
	2: 200, # Level 1 -> 2
	3: 400, # Level 2 -> 3
	4: 800, # Level 3 -> 4
	5: 1600 # Level 4 -> 5
}

# Gold generation per turn by level
const MINE_GENERATION_RATES: Dictionary = {
	1: 10,
	2: 25,
	3: 50,
	4: 100,
	5: 200
}

# =============================================================================
# TROOP UPGRADE CONFIGURATION
# =============================================================================
# Upgrade costs: {level: {gold: X, xp: Y}}
const TROOP_UPGRADE_COSTS: Dictionary = {
	2: {"gold": 50, "xp": 25},
	3: {"gold": 100, "xp": 50},
	4: {"gold": 200, "xp": 100},
	5: {"gold": 400, "xp": 200}
}

const MAX_TROOP_LEVEL: int = 5
const HP_INCREASE_PERCENT: float = 0.10 # +10% HP per level
const ATK_INCREASE_FLAT: int = 5 # +5 ATK per level
const DEF_INCREASE_FLAT: int = 3 # +3 DEF per level

# =============================================================================
# NPC CONFIGURATION
# =============================================================================
const NPC_SPAWN_CHANCE: float = 0.05 # 5% chance when troop moves

# =============================================================================
# BIOME MODIFIERS
# =============================================================================
const ADVANTAGE_MODIFIER: float = 0.25 # +A: +25% damage dealt
const STRENGTH_MODIFIER: float = 0.15 # +S: +15% damage dealt
const DEFENSE_MODIFIER: float = 0.15 # +D: -15% incoming damage
const WEAKNESS_MODIFIER: float = -0.25 # -S: -25% damage dealt

# =============================================================================
# PLAYER INVENTORY
# =============================================================================
const MAX_INVENTORY_SLOTS: int = 3
const MAX_PHOENIX_FEATHERS: int = 1

# =============================================================================
# AGGRESSION BOUNTY SYSTEM
# =============================================================================
const FIRST_BLOOD_GOLD: int = 50
const KILL_STREAK_XP_BONUSES: Dictionary = {
	2: 0.25, # 2nd kill: +25% XP
	3: 0.50, # 3rd kill: +50% XP
	4: 1.00 # 4th+ kill: +100% XP
}
const REVENGE_KILL_GOLD_BONUS: float = 0.25 # +25% gold
const MINE_RAIDER_GOLD: int = 20

# =============================================================================
# DISCONNECTION HANDLING (Future Online Mode)
# =============================================================================
const RECONNECT_TIMEOUT_SECONDS: int = 180 # 3 minutes
const MAX_DISCONNECTIONS: int = 3

# =============================================================================
# SUPPORT/HEALING
# =============================================================================
const CLERIC_HEAL_AMOUNT: int = 35
const CLERIC_HEAL_RANGE: int = 2

# =============================================================================
# ITEM EFFECTS
# =============================================================================
const SPEED_POTION_BONUS: int = 1
const SPEED_POTION_DURATION: int = 3 # turns
const WHETSTONE_ATK_BONUS: int = 10
const PHOENIX_FEATHER_DROP_CHANCE: float = 0.20 # 20%

# =============================================================================
# DECK SELECTION
# =============================================================================
const DECK_SELECTION_TIMER: int = 30 # seconds
