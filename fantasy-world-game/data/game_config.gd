## Game Configuration
## Contains all game constants and configuration values
class_name GameConfig
extends RefCounted

# =============================================================================
# BOARD CONFIGURATION
# =============================================================================
const BOARD_SIZE: int = 12 # Hexagons per side (creates 397 total hexes)
const TOTAL_HEXES: int = 397 # 12-hex-per-side hexagonal board

# =============================================================================
# PLAYER CONFIGURATION
# =============================================================================
const NUM_PLAYERS: int = 2 # 1v1 game
const STARTING_GOLD: int = 150
const STARTING_XP: int = 0
const CARDS_PER_PLAYER: int = 4
const MAX_DECK_MANA: int = 22 # Maximum total mana cost for deck
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
