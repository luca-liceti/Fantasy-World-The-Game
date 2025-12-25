## Conditional Reactions System
## Each troop has one passive reaction that triggers on specific conditions
## Reactions are automatic (no player input required)
## Critical Hits bypass reactions
class_name ConditionalReactions
extends RefCounted

# =============================================================================
# ENUMS
# =============================================================================

## Trigger conditions for reactions
enum ReactionTrigger {
	ON_MISS,            # Triggers when the troop is missed by an attack
	ON_CRIT_RECEIVED,   # Triggers when receiving a critical hit
	ON_DAMAGE_TAKEN,    # Triggers when taking any damage
	ON_ICE_DAMAGE,      # Triggers when taking Ice damage
	ON_FIRE_DAMAGE,     # Triggers when taking Fire damage
	ON_PHYSICAL_DAMAGE, # Triggers when taking Physical damage
	ON_STATUS_APPLIED,  # Triggers when a status effect is applied
	ON_MELEE_RECEIVED,  # Triggers when hit by a melee attack
	ON_FIRST_HIT,       # Triggers on the first hit per round
	ON_DEATH            # Triggers when the troop dies
}

## Effect types for reactions
enum ReactionEffect {
	COUNTER_ATTACK,     # Deal damage back to attacker
	REDUCE_DAMAGE,      # Reduce incoming damage
	HEAL_PERCENT,       # Heal a percentage of max HP
	GAIN_STAT_STAGE,    # Gain a stat stage bonus
	GAIN_STEALTH,       # Become stealthed
	CLEANSE_AND_HEAL,   # Remove debuffs and heal
	DEAL_FLAT_DAMAGE,   # Deal flat damage to attacker
	DEAL_AOE_DAMAGE     # Deal damage to all adjacent enemies (on death)
}

# =============================================================================
# REACTION DATA CLASS
# =============================================================================

class Reaction:
	var reaction_id: String
	var reaction_name: String
	var trigger: ReactionTrigger
	var effect: ReactionEffect
	var effect_value: float          # Values vary: damage%, reduction%, heal%, stages
	var stat_affected: String        # For GAIN_STAT_STAGE: "atk", "def", "spd"
	var duration_turns: int          # For buffs/debuffs
	var description: String
	var bypassed_by_crit: bool       # True if critical hits bypass this reaction
	
	func _init(data: Dictionary = {}) -> void:
		reaction_id = data.get("reaction_id", "")
		reaction_name = data.get("reaction_name", "Unknown")
		trigger = data.get("trigger", ReactionTrigger.ON_DAMAGE_TAKEN)
		effect = data.get("effect", ReactionEffect.COUNTER_ATTACK)
		effect_value = data.get("effect_value", 0.0)
		stat_affected = data.get("stat_affected", "")
		duration_turns = data.get("duration_turns", 0)
		description = data.get("description", "")
		bypassed_by_crit = data.get("bypassed_by_crit", true)
	
	func get_display_text() -> String:
		return "%s\n%s" % [reaction_name, description]

# =============================================================================
# REACTION DEFINITIONS
# =============================================================================

const REACTIONS: Dictionary = {
	# =========================================================================
	# GROUND TANKS
	# =========================================================================
	
	## Medieval Knight - Riposte
	"knight_riposte": {
		"reaction_id": "knight_riposte",
		"reaction_name": "Riposte",
		"trigger": ReactionTrigger.ON_MISS,
		"effect": ReactionEffect.COUNTER_ATTACK,
		"effect_value": 0.30,  # 30% ATK damage
		"description": "On miss, counter-attack for 30% ATK damage.",
		"bypassed_by_crit": true
	},
	
	## Stone Giant - Thick Skin
	"giant_thick_skin": {
		"reaction_id": "giant_thick_skin",
		"reaction_name": "Thick Skin",
		"trigger": ReactionTrigger.ON_CRIT_RECEIVED,
		"effect": ReactionEffect.REDUCE_DAMAGE,
		"effect_value": 0.50,  # 50% damage reduction
		"description": "On critical hit received, reduce damage by 50%.",
		"bypassed_by_crit": false  # Specifically triggers on crits, doesn't bypass
	},
	
	## Four-Headed Hydra - Regrowth
	"hydra_regrowth": {
		"reaction_id": "hydra_regrowth",
		"reaction_name": "Regrowth",
		"trigger": ReactionTrigger.ON_DAMAGE_TAKEN,
		"effect": ReactionEffect.HEAL_PERCENT,
		"effect_value": 0.05,  # 5% max HP
		"description": "On taking damage, heal 5% of max HP.",
		"bypassed_by_crit": true
	},
	
	# =========================================================================
	# AIR/HYBRID UNITS
	# =========================================================================
	
	## Dark Blood Dragon - Dragon's Fury
	"dragon_fury": {
		"reaction_id": "dragon_fury",
		"reaction_name": "Dragon's Fury",
		"trigger": ReactionTrigger.ON_ICE_DAMAGE,
		"effect": ReactionEffect.GAIN_STAT_STAGE,
		"effect_value": 1.0,  # +1 stage
		"stat_affected": "atk",
		"description": "On taking Ice damage, gain +1 ATK stage.",
		"bypassed_by_crit": true
	},
	
	## Sky Serpent - Slither Away
	"serpent_slither": {
		"reaction_id": "serpent_slither",
		"reaction_name": "Slither Away",
		"trigger": ReactionTrigger.ON_MISS,
		"effect": ReactionEffect.GAIN_STEALTH,
		"effect_value": 1.0,  # 1 turn stealth
		"duration_turns": 1,
		"description": "On miss, gain Stealth for 1 turn.",
		"bypassed_by_crit": true
	},
	
	## Frost Valkyrie - Frozen Resilience
	"valkyrie_resilience": {
		"reaction_id": "valkyrie_resilience",
		"reaction_name": "Frozen Resilience",
		"trigger": ReactionTrigger.ON_FIRE_DAMAGE,
		"effect": ReactionEffect.GAIN_STAT_STAGE,
		"effect_value": 1.0,  # +1 stage
		"stat_affected": "def",
		"description": "On taking Fire damage, gain +1 DEF stage.",
		"bypassed_by_crit": true
	},
	
	# =========================================================================
	# RANGED/MAGIC UNITS
	# =========================================================================
	
	## Dark Magic Wizard - Arcane Barrier
	"wizard_barrier": {
		"reaction_id": "wizard_barrier",
		"reaction_name": "Arcane Barrier",
		"trigger": ReactionTrigger.ON_FIRST_HIT,
		"effect": ReactionEffect.REDUCE_DAMAGE,
		"effect_value": 0.20,  # 20% damage reduction
		"description": "First hit each round deals 20% less damage.",
		"bypassed_by_crit": true
	},
	
	## Demon of Darkness - Demonic Hide
	"demon_hide": {
		"reaction_id": "demon_hide",
		"reaction_name": "Demonic Hide",
		"trigger": ReactionTrigger.ON_PHYSICAL_DAMAGE,
		"effect": ReactionEffect.REDUCE_DAMAGE,
		"effect_value": 0.15,  # 15% damage reduction
		"description": "Incoming Physical damage reduced by 15%.",
		"bypassed_by_crit": true
	},
	
	## Elven Archer - Quick Reflexes
	"archer_reflexes": {
		"reaction_id": "archer_reflexes",
		"reaction_name": "Quick Reflexes",
		"trigger": ReactionTrigger.ON_MISS,
		"effect": ReactionEffect.COUNTER_ATTACK,
		"effect_value": 0.40,  # 40% ATK damage
		"description": "On miss, retaliate with 40% ATK damage.",
		"bypassed_by_crit": true
	},
	
	# =========================================================================
	# FLEX/SUPPORT/ASSASSIN UNITS
	# =========================================================================
	
	## Celestial Cleric - Divine Protection
	"cleric_protection": {
		"reaction_id": "cleric_protection",
		"reaction_name": "Divine Protection",
		"trigger": ReactionTrigger.ON_STATUS_APPLIED,
		"effect": ReactionEffect.CLEANSE_AND_HEAL,
		"effect_value": 25.0,  # 25 HP heal
		"description": "On status effect applied, cleanse it and heal 25 HP.",
		"bypassed_by_crit": true
	},
	
	## Shadow Assassin - Slippery
	"assassin_slippery": {
		"reaction_id": "assassin_slippery",
		"reaction_name": "Slippery",
		"trigger": ReactionTrigger.ON_MISS,
		"effect": ReactionEffect.GAIN_STEALTH,
		"effect_value": 1.0,  # 1 turn stealth
		"duration_turns": 1,
		"description": "On miss, gain Stealth for 1 turn.",
		"bypassed_by_crit": true
	},
	
	## Infernal Soul - Burning Aura
	"infernal_aura": {
		"reaction_id": "infernal_aura",
		"reaction_name": "Burning Aura",
		"trigger": ReactionTrigger.ON_MELEE_RECEIVED,
		"effect": ReactionEffect.DEAL_FLAT_DAMAGE,
		"effect_value": 20.0,  # 20 damage
		"description": "On melee attack received, attacker takes 20 damage.",
		"bypassed_by_crit": true
	},
	
	## Infernal Soul - Death Burst (Passive on death)
	"infernal_death_burst": {
		"reaction_id": "infernal_death_burst",
		"reaction_name": "Death Burst",
		"trigger": ReactionTrigger.ON_DEATH,
		"effect": ReactionEffect.DEAL_AOE_DAMAGE,
		"effect_value": 40.0,  # 40 damage
		"description": "On death, deal 40 damage to all adjacent units.",
		"bypassed_by_crit": false  # Death burst always triggers
	},
	
	# =========================================================================
	# ADDITIONAL TROOPS (using existing patterns)
	# =========================================================================
	
	## Necromancer - Soul Harvest
	"necro_harvest": {
		"reaction_id": "necro_harvest",
		"reaction_name": "Soul Harvest",
		"trigger": ReactionTrigger.ON_DAMAGE_TAKEN,
		"effect": ReactionEffect.HEAL_PERCENT,
		"effect_value": 0.03,  # 3% max HP
		"description": "On taking damage, heal 3% of max HP from dark energy.",
		"bypassed_by_crit": true
	},
	
	## Phoenix - Flame Shield
	"phoenix_shield": {
		"reaction_id": "phoenix_shield",
		"reaction_name": "Flame Shield",
		"trigger": ReactionTrigger.ON_MELEE_RECEIVED,
		"effect": ReactionEffect.DEAL_FLAT_DAMAGE,
		"effect_value": 15.0,  # 15 damage
		"description": "On melee attack received, attacker takes 15 fire damage.",
		"bypassed_by_crit": true
	},
	
	## Griffin - Aerial Evasion
	"griffin_evasion": {
		"reaction_id": "griffin_evasion",
		"reaction_name": "Aerial Evasion",
		"trigger": ReactionTrigger.ON_MISS,
		"effect": ReactionEffect.GAIN_STAT_STAGE,
		"effect_value": 1.0,  # +1 stage
		"stat_affected": "spd",
		"duration_turns": 2,
		"description": "On miss, gain +1 Speed stage for 2 turns.",
		"bypassed_by_crit": true
	},
	
	## Frost Giant - Frozen Counter
	"frost_giant_counter": {
		"reaction_id": "frost_giant_counter",
		"reaction_name": "Frozen Counter",
		"trigger": ReactionTrigger.ON_DAMAGE_TAKEN,
		"effect": ReactionEffect.COUNTER_ATTACK,
		"effect_value": 0.15,  # 15% ATK damage as ice
		"description": "On taking damage, counter for 15% ATK as Ice damage.",
		"bypassed_by_crit": true
	}
}

# =============================================================================
# TROOP TO REACTION MAPPING
# =============================================================================

const TROOP_REACTIONS: Dictionary = {
	"medieval_knight": "knight_riposte",
	"stone_giant": "giant_thick_skin",
	"four_headed_hydra": "hydra_regrowth",
	"dark_blood_dragon": "dragon_fury",
	"sky_serpent": "serpent_slither",
	"frost_valkyrie": "valkyrie_resilience",
	"dark_magic_wizard": "wizard_barrier",
	"demon_of_darkness": "demon_hide",
	"elven_archer": "archer_reflexes",
	"celestial_cleric": "cleric_protection",
	"shadow_assassin": "assassin_slippery",
	"infernal_soul": "infernal_aura",  # Primary reaction
	"necromancer": "necro_harvest",
	"phoenix": "phoenix_shield",
	"griffin": "griffin_evasion",
	"frost_giant": "frost_giant_counter"
}

## Infernal Soul has a special on-death passive
const TROOP_DEATH_REACTIONS: Dictionary = {
	"infernal_soul": "infernal_death_burst"
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

## Get a Reaction object by ID
static func get_reaction(reaction_id: String) -> Reaction:
	var data = REACTIONS.get(reaction_id, {})
	if data.is_empty():
		push_error("ConditionalReactions: Unknown reaction ID: " + reaction_id)
		return null
	return Reaction.new(data)


## Get the primary reaction for a troop
static func get_troop_reaction(troop_id: String) -> Reaction:
	var reaction_id = TROOP_REACTIONS.get(troop_id, "")
	if reaction_id.is_empty():
		return null
	return get_reaction(reaction_id)


## Get the reaction ID for a troop (for lookups)
static func get_troop_reaction_id(troop_id: String) -> String:
	return TROOP_REACTIONS.get(troop_id, "")


## Get the death reaction for a troop (if any)
static func get_death_reaction(troop_id: String) -> Reaction:
	var reaction_id = TROOP_DEATH_REACTIONS.get(troop_id, "")
	if reaction_id.is_empty():
		return null
	return get_reaction(reaction_id)


## Check if a troop has a death reaction
static func has_death_reaction(troop_id: String) -> bool:
	return TROOP_DEATH_REACTIONS.has(troop_id)


## Check if a reaction is bypassed by critical hits
static func is_bypassed_by_crit(reaction_id: String) -> bool:
	var reaction = get_reaction(reaction_id)
	if reaction == null:
		return true  # Default: assume bypassed
	return reaction.bypassed_by_crit


## Get all reactions as Reaction objects
static func get_all_reactions() -> Array:
	var result: Array = []
	for reaction_id in REACTIONS:
		var reaction = get_reaction(reaction_id)
		if reaction:
			result.append(reaction)
	return result


## Check if a reaction should trigger based on condition
static func should_trigger(reaction_id: String, trigger_condition: ReactionTrigger, is_crit: bool = false) -> bool:
	var reaction = get_reaction(reaction_id)
	if reaction == null:
		return false
	
	# Check if bypassed by crit
	if is_crit and reaction.bypassed_by_crit:
		return false
	
	# Check trigger match
	return reaction.trigger == trigger_condition


## Calculate reaction effect value (damage, heal, etc.)
static func calculate_effect_value(reaction_id: String, base_stat: float = 0.0, max_hp: float = 0.0) -> float:
	var reaction = get_reaction(reaction_id)
	if reaction == null:
		return 0.0
	
	match reaction.effect:
		ReactionEffect.COUNTER_ATTACK:
			return base_stat * reaction.effect_value  # base_stat = ATK
		ReactionEffect.REDUCE_DAMAGE:
			return reaction.effect_value  # Return percentage as multiplier
		ReactionEffect.HEAL_PERCENT:
			return max_hp * reaction.effect_value  # Max HP * percentage
		ReactionEffect.DEAL_FLAT_DAMAGE:
			return reaction.effect_value  # Flat damage
		ReactionEffect.DEAL_AOE_DAMAGE:
			return reaction.effect_value  # Flat AoE damage
		ReactionEffect.CLEANSE_AND_HEAL:
			return reaction.effect_value  # Flat HP heal
		_:
			return reaction.effect_value  # Default: return raw value
