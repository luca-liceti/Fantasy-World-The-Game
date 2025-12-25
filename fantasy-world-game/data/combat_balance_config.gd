## Combat Balance Config
## Centralized configuration for all combat balance values
## Easy to tweak during playtesting
class_name CombatBalanceConfig
extends RefCounted

# =============================================================================
# DICE & ROLL CONFIGURATION
# =============================================================================

## Base dice type (d20)
const DICE_TYPE: int = 20

## Natural roll needed for critical hit (18-20)
const CRITICAL_HIT_MIN: int = 18

## Natural roll that always misses
const CRITICAL_MISS_MAX: int = 1

## Base Defense Class (DC) for attacks
const BASE_DEFENSE_DC: int = 10


# =============================================================================
# DAMAGE CALCULATION
# =============================================================================

## Minimum damage dealt (even on perfect defense)
const MIN_DAMAGE: int = 1

## DEF reduction divisor (damage -= DEF / this value)
const DEF_DIVISOR: float = 2.0

## Critical hit damage multiplier
const CRIT_DAMAGE_MULT: float = 2.0

## Magic damage DEF ignore percentage (ignores 25% of DEF)
const MAGIC_DEF_IGNORE: float = 0.25


# =============================================================================
# TYPE EFFECTIVENESS
# =============================================================================

## Super effective multiplier
const SUPER_EFFECTIVE_MULT: float = 1.5

## Not very effective multiplier
const NOT_EFFECTIVE_MULT: float = 0.5

## Immune (no damage)
const IMMUNE_MULT: float = 0.0


# =============================================================================
# STAT STAGE SYSTEM (Pokémon-style -6 to +6)
# =============================================================================

## Maximum stat stage
const MAX_STAT_STAGE: int = 6

## Minimum stat stage
const MIN_STAT_STAGE: int = -6

## Stat stage multipliers
## Stage 0 = 1.0x, +1 = 1.5x, +2 = 2.0x, etc.
## -1 = 0.67x, -2 = 0.5x, etc.
static func get_stat_multiplier(stage: int) -> float:
	stage = clamp(stage, MIN_STAT_STAGE, MAX_STAT_STAGE)
	if stage >= 0:
		return (2.0 + float(stage)) / 2.0
	else:
		return 2.0 / (2.0 - float(stage))


# =============================================================================
# MOVE TYPE DEFAULTS
# =============================================================================

## Default power percentage by move type
const MOVE_TYPE_POWER = {
	"STANDARD": 1.0,    # 100% ATK
	"POWER": 1.5,       # 150% ATK
	"PRECISION": 0.8,   # 80% ATK
	"SPECIAL": 1.2      # 120% ATK (with effect)
}

## Default accuracy modifier by move type
const MOVE_TYPE_ACCURACY = {
	"STANDARD": 0,      # No modifier
	"POWER": -3,        # Harder to hit
	"PRECISION": 5,     # Easier to hit
	"SPECIAL": 0        # No modifier
}

## Default cooldown by move type
const MOVE_TYPE_COOLDOWN = {
	"STANDARD": 0,      # No cooldown
	"POWER": 3,         # 3 turn cooldown
	"PRECISION": 2,     # 2 turn cooldown
	"SPECIAL": 4        # 4 turn cooldown
}


# =============================================================================
# DEFENSIVE STANCES
# =============================================================================

## Brace: +DEF, reduced damage
const BRACE_DEF_BONUS: int = 3
const BRACE_DAMAGE_REDUCTION: float = 0.8  # Take 80% damage

## Dodge: +Evasion (adds to DC)
const DODGE_EVASION_BONUS: int = 5

## Counter: Deal damage back on miss
const COUNTER_DAMAGE_PERCENT: float = 0.5  # 50% of DEF'er ATK

## Endure: Survive at 1 HP (once per combat)
const ENDURE_USES_PER_COMBAT: int = 1


# =============================================================================
# POSITIONING BONUSES
# =============================================================================

## Flanking: Ally adjacent to defender
const FLANKING_HIT_BONUS: int = 3
const FLANKING_DAMAGE_BONUS: float = 0.0  # No damage bonus, just accuracy

## High Ground: Attacker on Hills/Peaks
const HIGH_GROUND_HIT_BONUS: int = 2
const HIGH_GROUND_DAMAGE_BONUS: float = 0.1  # +10% damage

## Cover: Defender on Forest/Ruins
const COVER_DEF_BONUS: int = 3

## Surrounded: 3+ enemies adjacent to defender
const SURROUNDED_DEF_PENALTY: int = 2
const SURROUNDED_MIN_ENEMIES: int = 3


# =============================================================================
# STATUS EFFECTS
# =============================================================================

## Stunned: Skip turn
const STUNNED_DURATION: int = 1

## Burned: Take damage each turn
const BURNED_DURATION: int = 3
const BURNED_DAMAGE: int = 10

## Poisoned: Take damage each turn (stacking)
const POISONED_DURATION: int = 4
const POISONED_DAMAGE: int = 8

## Slowed: -2 Speed
const SLOWED_DURATION: int = 2
const SLOWED_SPEED_PENALTY: int = -2

## Cursed: -25% ATK
const CURSED_DURATION: int = 3
const CURSED_ATK_PENALTY: float = -0.25  # Represented as stat stage

## Terrified: -25% DEF
const TERRIFIED_DURATION: int = 2
const TERRIFIED_DEF_PENALTY: float = -0.25

## Rooted: Cannot move
const ROOTED_DURATION: int = 2

## Stealth: Guaranteed crit, removed after attacking
const STEALTH_DURATION: int = 3


# =============================================================================
# COMBAT TIMER
# =============================================================================

## Selection time limit (seconds) - Enhanced Mode
const SELECTION_TIME_LIMIT: float = 10.0

## Simple Mode timer (longer for new players)
const SIMPLE_MODE_TIME_LIMIT: float = 15.0

## Warning at this many seconds remaining
const SELECTION_WARNING_TIME: float = 5.0

## Tick sound interval in final seconds
const SELECTION_TICK_INTERVAL: float = 1.0


# =============================================================================
# SIMPLE MODE CONFIGURATION
# =============================================================================

## Simplified damage types for Simple Mode (3 instead of 6)
## Maps full damage types to simplified categories
enum SimpleDamageType {
	PHYSICAL,  # Physical only
	MAGIC,     # Dark, Holy
	ELEMENTAL  # Fire, Ice, Nature
}

## Mapping from full damage types to simple types
const DAMAGE_TYPE_SIMPLIFICATION: Dictionary = {
	0: SimpleDamageType.PHYSICAL,  # PHYSICAL -> PHYSICAL
	1: SimpleDamageType.ELEMENTAL, # FIRE -> ELEMENTAL
	2: SimpleDamageType.ELEMENTAL, # ICE -> ELEMENTAL
	3: SimpleDamageType.MAGIC,     # DARK -> MAGIC
	4: SimpleDamageType.MAGIC,     # HOLY -> MAGIC
	5: SimpleDamageType.ELEMENTAL  # NATURE -> ELEMENTAL
}

## Simple Mode effectiveness (Strong/Weak/Neutral)
## Format: {SimpleDamageType: {troop_category: effectiveness}}
const SIMPLE_EFFECTIVENESS: Dictionary = {
	SimpleDamageType.PHYSICAL: {
		"tank": 0.5,     # Weak vs tanks
		"ranged": 1.5,   # Strong vs ranged
		"support": 1.0   # Neutral
	},
	SimpleDamageType.MAGIC: {
		"tank": 1.0,     # Neutral
		"ranged": 1.5,   # Strong vs ranged
		"support": 0.5   # Weak vs support (clerics resist)
	},
	SimpleDamageType.ELEMENTAL: {
		"tank": 1.0,     # Neutral
		"ranged": 1.0,   # Neutral
		"support": 1.5   # Strong vs support
	}
}

## Troop category mapping for Simple Mode
const TROOP_SIMPLE_CATEGORIES: Dictionary = {
	"medieval_knight": "tank",
	"stone_giant": "tank",
	"hydra": "tank",
	"dark_blood_dragon": "ranged",
	"sky_serpent": "ranged",
	"frost_valkyrie": "ranged",
	"dark_magic_wizard": "ranged",
	"demon_of_darkness": "ranged",
	"elven_archer": "ranged",
	"celestial_cleric": "support",
	"shadow_assassin": "support",
	"infernal_soul": "support"
}

## Get simple effectiveness multiplier
static func get_simple_effectiveness(damage_type: int, target_troop_id: String) -> float:
	var simple_type = DAMAGE_TYPE_SIMPLIFICATION.get(damage_type, SimpleDamageType.PHYSICAL)
	var troop_category = TROOP_SIMPLE_CATEGORIES.get(target_troop_id, "tank")
	
	if SIMPLE_EFFECTIVENESS.has(simple_type):
		return SIMPLE_EFFECTIVENESS[simple_type].get(troop_category, 1.0)
	return 1.0

## Get simple effectiveness text
static func get_simple_effectiveness_text(damage_type: int, target_troop_id: String) -> String:
	var mult = get_simple_effectiveness(damage_type, target_troop_id)
	if mult >= 1.5:
		return "STRONG"
	elif mult <= 0.5:
		return "WEAK"
	else:
		return "NEUTRAL"


# =============================================================================
# AI DIFFICULTY SETTINGS
# =============================================================================

enum AIDifficulty {
	EASY,    # Uses random/suboptimal moves
	NORMAL,  # Uses type-effective moves when obvious
	HARD     # Optimal play with positioning consideration
}

## AI move selection weights by difficulty
## Higher weight = more likely to choose that move
const AI_MOVE_WEIGHTS: Dictionary = {
	AIDifficulty.EASY: {
		"standard_weight": 3.0,      # Strongly prefers Standard (safe) moves
		"power_weight": 0.5,         # Rarely uses Power moves
		"precision_weight": 1.0,     # Sometimes uses Precision
		"special_weight": 0.5,       # Rarely uses Special
		"effectiveness_bonus": 0.0   # Doesn't consider type matchups
	},
	AIDifficulty.NORMAL: {
		"standard_weight": 1.5,
		"power_weight": 1.0,
		"precision_weight": 1.0,
		"special_weight": 1.0,
		"effectiveness_bonus": 0.5   # 50% bonus for super effective
	},
	AIDifficulty.HARD: {
		"standard_weight": 1.0,
		"power_weight": 1.2,
		"precision_weight": 1.0,
		"special_weight": 1.5,
		"effectiveness_bonus": 1.0   # Full bonus for super effective
	}
}


# =============================================================================
# XP & REWARDS
# =============================================================================

## XP for killing enemy troop
const KILL_XP_BASE: int = 25

## XP bonus for killing higher level troop
const KILL_XP_PER_LEVEL_DIFF: int = 10

## XP for dealing damage (per 10 damage)
const DAMAGE_XP_PER_10: int = 2

## XP for applying status effect
const STATUS_EFFECT_XP: int = 5


# =============================================================================
# VALIDATION HELPERS
# =============================================================================

## Validate a move configuration
static func validate_move(move_data: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	
	# Check power is reasonable
	var power = move_data.get("power_percent", 1.0)
	if power < 0.5 or power > 3.0:
		errors.append("Power percent %.1f seems extreme (expected 0.5-3.0)" % power)
	
	# Check accuracy modifier
	var accuracy = move_data.get("accuracy_modifier", 0)
	if accuracy < -10 or accuracy > 10:
		errors.append("Accuracy modifier %d seems extreme (expected -10 to +10)" % accuracy)
	
	# Check cooldown
	var cooldown = move_data.get("cooldown_turns", 0)
	if cooldown < 0 or cooldown > 10:
		errors.append("Cooldown %d seems extreme (expected 0-10)" % cooldown)
	
	# Check effect chance
	var effect_chance = move_data.get("effect_chance", 0.0)
	if effect_chance < 0.0 or effect_chance > 1.0:
		errors.append("Effect chance %.2f must be 0.0-1.0" % effect_chance)
	
	return {
		"valid": errors.is_empty(),
		"errors": errors
	}


## Get recommended cooldown for a move's power level
static func recommend_cooldown(power_percent: float, has_effect: bool) -> int:
	var base = 0
	
	if power_percent >= 1.5:
		base = 3
	elif power_percent >= 1.25:
		base = 2
	elif power_percent >= 1.0:
		base = 1
	
	if has_effect:
		base += 1
	
	return base
