## Move Data
## Contains all move definitions for the D&D × Pokémon hybrid combat system
## Each troop has 4 unique moves with different effects
class_name MoveData
extends RefCounted

# =============================================================================
# ENUMS
# =============================================================================

## Move type categories affect base stats
enum MoveType {
	STANDARD,   # Basic attack, no modifiers, no cooldown
	POWER,      # High damage, low accuracy, cooldown
	PRECISION,  # Lower damage, high accuracy, cooldown
	SPECIAL     # Unique effects, variable cooldowns
}

## Damage types for type effectiveness calculation
enum DamageType {
	PHYSICAL,   # Standard physical damage
	FIRE,       # Fire elemental
	ICE,        # Ice/Cold elemental
	DARK,       # Dark/Shadow elemental
	HOLY,       # Light/Holy elemental
	NATURE      # Nature/Poison elemental
}

# =============================================================================
# MOVE CLASS
# =============================================================================

## Represents a single move that a troop can use
class Move:
	var move_id: String
	var move_name: String
	var move_type: MoveType
	var damage_type: DamageType
	var power_percent: float        # 0.0 - 3.0 (multiplier to ATK)
	var accuracy_modifier: int      # -5 to +8 (added to hit roll)
	var cooldown_turns: int         # 0-8 (turns until usable again)
	var effect_id: String           # Status effect to apply (or "" for none)
	var effect_chance: float        # 0.0 - 1.0 (probability to apply effect)
	var description: String
	var is_aoe: bool                # True if hits multiple hexes
	var aoe_pattern: Array          # Hex offsets for AoE (e.g., [[0,1], [1,0]])
	var targets_self: bool          # True for self-buffs/heals
	
	func _init(data: Dictionary = {}) -> void:
		move_id = data.get("move_id", "")
		move_name = data.get("move_name", "Unknown")
		move_type = data.get("move_type", MoveType.STANDARD)
		damage_type = data.get("damage_type", DamageType.PHYSICAL)
		power_percent = data.get("power_percent", 1.0)
		accuracy_modifier = data.get("accuracy_modifier", 0)
		cooldown_turns = data.get("cooldown_turns", 0)
		effect_id = data.get("effect_id", "")
		effect_chance = data.get("effect_chance", 0.0)
		description = data.get("description", "")
		is_aoe = data.get("is_aoe", false)
		aoe_pattern = data.get("aoe_pattern", [])
		targets_self = data.get("targets_self", false)
	
	## Get a formatted string for display
	func get_display_text() -> String:
		var type_str = ["Standard", "Power", "Precision", "Special"][move_type]
		var dmg_str = ["Physical", "Fire", "Ice", "Dark", "Holy", "Nature"][damage_type]
		var power_str = str(int(power_percent * 100)) + "%"
		var acc_str = ("+" if accuracy_modifier >= 0 else "") + str(accuracy_modifier)
		
		return "%s\nType: %s | %s\nPower: %s | Accuracy: %s\n%s" % [
			move_name, type_str, dmg_str, power_str, acc_str, description
		]


# =============================================================================
# MOVE DEFINITIONS - ALL 48 MOVES (4 per troop × 12 troops)
# =============================================================================

const MOVES: Dictionary = {
	# =========================================================================
	# MEDIEVAL KNIGHT (Ground Tank)
	# =========================================================================
	"knight_slash": {
		"move_id": "knight_slash",
		"move_name": "Sword Slash",
		"move_type": MoveType.STANDARD,
		"damage_type": DamageType.PHYSICAL,
		"power_percent": 1.0,
		"accuracy_modifier": 0,
		"cooldown_turns": 0,
		"effect_id": "",
		"effect_chance": 0.0,
		"description": "A standard sword attack."
	},
	"knight_shield_bash": {
		"move_id": "knight_shield_bash",
		"move_name": "Shield Bash",
		"move_type": MoveType.PRECISION,
		"damage_type": DamageType.PHYSICAL,
		"power_percent": 0.6,
		"accuracy_modifier": 4,
		"cooldown_turns": 2,
		"effect_id": "stunned",
		"effect_chance": 0.5,
		"description": "Bash with shield. 50% chance to stun."
	},
	"knight_heavy_strike": {
		"move_id": "knight_heavy_strike",
		"move_name": "Heavy Strike",
		"move_type": MoveType.POWER,
		"damage_type": DamageType.PHYSICAL,
		"power_percent": 1.8,
		"accuracy_modifier": -3,
		"cooldown_turns": 3,
		"effect_id": "",
		"effect_chance": 0.0,
		"description": "Massive overhead swing. High damage, low accuracy."
	},
	"knight_rally": {
		"move_id": "knight_rally",
		"move_name": "Rally Cry",
		"move_type": MoveType.SPECIAL,
		"damage_type": DamageType.PHYSICAL,
		"power_percent": 0.0,
		"accuracy_modifier": 0,
		"cooldown_turns": 5,
		"effect_id": "",
		"effect_chance": 1.0,
		"description": "Boost own DEF by +3 stages for 3 turns.",
		"targets_self": true
	},
	
	# =========================================================================
	# FOUR HEADED HYDRA (Ground Tank)
	# =========================================================================
	"hydra_bite": {
		"move_id": "hydra_bite",
		"move_name": "Venomous Bite",
		"move_type": MoveType.STANDARD,
		"damage_type": DamageType.NATURE,
		"power_percent": 1.0,
		"accuracy_modifier": 0,
		"cooldown_turns": 0,
		"effect_id": "poisoned",
		"effect_chance": 0.3,
		"description": "Bite attack. 30% chance to poison."
	},
	"hydra_multi_strike": {
		"move_id": "hydra_multi_strike",
		"move_name": "Multi-Head Strike",
		"move_type": MoveType.SPECIAL,
		"damage_type": DamageType.PHYSICAL,
		"power_percent": 0.6,
		"accuracy_modifier": 0,
		"cooldown_turns": 3,
		"effect_id": "",
		"effect_chance": 0.0,
		"description": "Attack up to 2 adjacent enemies.",
		"is_aoe": true,
		"aoe_pattern": [[1, 0], [-1, 0], [0, 1], [0, -1]]
	},
	"hydra_regenerate": {
		"move_id": "hydra_regenerate",
		"move_name": "Regenerate",
		"move_type": MoveType.SPECIAL,
		"damage_type": DamageType.NATURE,
		"power_percent": 0.0,
		"accuracy_modifier": 0,
		"cooldown_turns": 4,
		"effect_id": "",
		"effect_chance": 0.0,
		"description": "Heal 25% of max HP.",
		"targets_self": true
	},
	"hydra_acid_spray": {
		"move_id": "hydra_acid_spray",
		"move_name": "Acid Spray",
		"move_type": MoveType.POWER,
		"damage_type": DamageType.NATURE,
		"power_percent": 1.5,
		"accuracy_modifier": -2,
		"cooldown_turns": 4,
		"effect_id": "poisoned",
		"effect_chance": 0.8,
		"description": "Spray acid. 80% chance to poison."
	},
	
	# =========================================================================
	# DARK BLOOD DRAGON (Air/Hybrid)
	# =========================================================================
	"dragon_claw": {
		"move_id": "dragon_claw",
		"move_name": "Dragon Claw",
		"move_type": MoveType.STANDARD,
		"damage_type": DamageType.PHYSICAL,
		"power_percent": 1.0,
		"accuracy_modifier": 0,
		"cooldown_turns": 0,
		"effect_id": "",
		"effect_chance": 0.0,
		"description": "Slash with razor-sharp claws."
	},
	"dragon_fire_breath": {
		"move_id": "dragon_fire_breath",
		"move_name": "Fire Breath",
		"move_type": MoveType.POWER,
		"damage_type": DamageType.FIRE,
		"power_percent": 1.6,
		"accuracy_modifier": -1,
		"cooldown_turns": 3,
		"effect_id": "burned",
		"effect_chance": 0.6,
		"description": "Breathe fire. 60% chance to burn.",
		"is_aoe": true,
		"aoe_pattern": [[1, 0], [2, 0]]
	},
	"dragon_dark_pulse": {
		"move_id": "dragon_dark_pulse",
		"move_name": "Dark Pulse",
		"move_type": MoveType.PRECISION,
		"damage_type": DamageType.DARK,
		"power_percent": 0.8,
		"accuracy_modifier": 5,
		"cooldown_turns": 2,
		"effect_id": "terrified",
		"effect_chance": 0.4,
		"description": "Wave of darkness. 40% chance to terrify."
	},
	"dragon_wing_buffet": {
		"move_id": "dragon_wing_buffet",
		"move_name": "Wing Buffet",
		"move_type": MoveType.SPECIAL,
		"damage_type": DamageType.PHYSICAL,
		"power_percent": 0.5,
		"accuracy_modifier": 8,
		"cooldown_turns": 3,
		"effect_id": "slowed",
		"effect_chance": 1.0,
		"description": "Buffet with wings. Always slows target."
	},
	
	# =========================================================================
	# GRIFFIN (Air/Hybrid)
	# =========================================================================
	"griffin_talon": {
		"move_id": "griffin_talon",
		"move_name": "Talon Strike",
		"move_type": MoveType.STANDARD,
		"damage_type": DamageType.PHYSICAL,
		"power_percent": 1.0,
		"accuracy_modifier": 0,
		"cooldown_turns": 0,
		"effect_id": "",
		"effect_chance": 0.0,
		"description": "Strike with sharp talons."
	},
	"griffin_dive_bomb": {
		"move_id": "griffin_dive_bomb",
		"move_name": "Dive Bomb",
		"move_type": MoveType.POWER,
		"damage_type": DamageType.PHYSICAL,
		"power_percent": 2.0,
		"accuracy_modifier": -4,
		"cooldown_turns": 4,
		"effect_id": "stunned",
		"effect_chance": 0.3,
		"description": "Dive from above. 30% stun on hit."
	},
	"griffin_screech": {
		"move_id": "griffin_screech",
		"move_name": "Piercing Screech",
		"move_type": MoveType.SPECIAL,
		"damage_type": DamageType.PHYSICAL,
		"power_percent": 0.3,
		"accuracy_modifier": 8,
		"cooldown_turns": 3,
		"effect_id": "terrified",
		"effect_chance": 0.7,
		"description": "Terrifying screech. 70% to terrify."
	},
	"griffin_gust": {
		"move_id": "griffin_gust",
		"move_name": "Gust Wings",
		"move_type": MoveType.PRECISION,
		"damage_type": DamageType.PHYSICAL,
		"power_percent": 0.7,
		"accuracy_modifier": 4,
		"cooldown_turns": 2,
		"effect_id": "slowed",
		"effect_chance": 0.5,
		"description": "Gusty wind. 50% chance to slow."
	},
	
	# =========================================================================
	# DARK MAGIC WIZARD (Ranged/Magic)
	# =========================================================================
	"wizard_dark_bolt": {
		"move_id": "wizard_dark_bolt",
		"move_name": "Dark Bolt",
		"move_type": MoveType.STANDARD,
		"damage_type": DamageType.DARK,
		"power_percent": 1.0,
		"accuracy_modifier": 0,
		"cooldown_turns": 0,
		"effect_id": "",
		"effect_chance": 0.0,
		"description": "Fire a bolt of dark energy."
	},
	"wizard_shadow_blast": {
		"move_id": "wizard_shadow_blast",
		"move_name": "Shadow Blast",
		"move_type": MoveType.POWER,
		"damage_type": DamageType.DARK,
		"power_percent": 1.8,
		"accuracy_modifier": -3,
		"cooldown_turns": 4,
		"effect_id": "cursed",
		"effect_chance": 0.5,
		"description": "Massive dark blast. 50% curse."
	},
	"wizard_life_drain": {
		"move_id": "wizard_life_drain",
		"move_name": "Life Drain",
		"move_type": MoveType.SPECIAL,
		"damage_type": DamageType.DARK,
		"power_percent": 0.8,
		"accuracy_modifier": 2,
		"cooldown_turns": 4,
		"effect_id": "",
		"effect_chance": 0.0,
		"description": "Drain HP. Heal for 50% of damage dealt."
	},
	"wizard_curse": {
		"move_id": "wizard_curse",
		"move_name": "Hex Curse",
		"move_type": MoveType.PRECISION,
		"damage_type": DamageType.DARK,
		"power_percent": 0.5,
		"accuracy_modifier": 6,
		"cooldown_turns": 3,
		"effect_id": "cursed",
		"effect_chance": 1.0,
		"description": "Weak attack. Always curses target."
	},
	
	# =========================================================================
	# ELVEN ARCHER (Ranged/Magic)
	# =========================================================================
	"archer_arrow": {
		"move_id": "archer_arrow",
		"move_name": "Arrow Shot",
		"move_type": MoveType.STANDARD,
		"damage_type": DamageType.PHYSICAL,
		"power_percent": 1.0,
		"accuracy_modifier": 0,
		"cooldown_turns": 0,
		"effect_id": "",
		"effect_chance": 0.0,
		"description": "Fire an arrow."
	},
	"archer_volley": {
		"move_id": "archer_volley",
		"move_name": "Arrow Volley",
		"move_type": MoveType.POWER,
		"damage_type": DamageType.PHYSICAL,
		"power_percent": 0.8,
		"accuracy_modifier": 0,
		"cooldown_turns": 3,
		"effect_id": "",
		"effect_chance": 0.0,
		"description": "Rain of arrows on target area.",
		"is_aoe": true,
		"aoe_pattern": [[0, 0], [1, 0], [-1, 0], [0, 1]]
	},
	"archer_poison_arrow": {
		"move_id": "archer_poison_arrow",
		"move_name": "Poison Arrow",
		"move_type": MoveType.PRECISION,
		"damage_type": DamageType.NATURE,
		"power_percent": 0.7,
		"accuracy_modifier": 4,
		"cooldown_turns": 2,
		"effect_id": "poisoned",
		"effect_chance": 0.8,
		"description": "Poisoned tip. 80% chance to poison."
	},
	"archer_aimed_shot": {
		"move_id": "archer_aimed_shot",
		"move_name": "Aimed Shot",
		"move_type": MoveType.PRECISION,
		"damage_type": DamageType.PHYSICAL,
		"power_percent": 1.2,
		"accuracy_modifier": 5,
		"cooldown_turns": 3,
		"effect_id": "",
		"effect_chance": 0.0,
		"description": "Carefully aimed shot. High accuracy."
	},
	
	# =========================================================================
	# CELESTIAL CLERIC (Flex/Support)
	# =========================================================================
	"cleric_smite": {
		"move_id": "cleric_smite",
		"move_name": "Holy Smite",
		"move_type": MoveType.STANDARD,
		"damage_type": DamageType.HOLY,
		"power_percent": 1.0,
		"accuracy_modifier": 0,
		"cooldown_turns": 0,
		"effect_id": "",
		"effect_chance": 0.0,
		"description": "Strike with holy power."
	},
	"cleric_heal": {
		"move_id": "cleric_heal",
		"move_name": "Divine Heal",
		"move_type": MoveType.SPECIAL,
		"damage_type": DamageType.HOLY,
		"power_percent": 0.0,
		"accuracy_modifier": 0,
		"cooldown_turns": 2,
		"effect_id": "",
		"effect_chance": 0.0,
		"description": "Heal an ally for 25-40 HP.",
		"targets_self": false
	},
	"cleric_purify": {
		"move_id": "cleric_purify",
		"move_name": "Purify",
		"move_type": MoveType.SPECIAL,
		"damage_type": DamageType.HOLY,
		"power_percent": 0.0,
		"accuracy_modifier": 0,
		"cooldown_turns": 3,
		"effect_id": "",
		"effect_chance": 0.0,
		"description": "Remove all negative status effects from self.",
		"targets_self": true
	},
	"cleric_resurrection": {
		"move_id": "cleric_resurrection",
		"move_name": "Resurrection",
		"move_type": MoveType.SPECIAL,
		"damage_type": DamageType.HOLY,
		"power_percent": 0.0,
		"accuracy_modifier": 0,
		"cooldown_turns": 8,
		"effect_id": "",
		"effect_chance": 0.0,
		"description": "Ultimate: Revive a fallen ally at 50% HP."
	},
	
	# =========================================================================
	# INFERNAL SOUL (Flex/Support - Assassin variant)
	# =========================================================================
	"infernal_slash": {
		"move_id": "infernal_slash",
		"move_name": "Hell Slash",
		"move_type": MoveType.STANDARD,
		"damage_type": DamageType.FIRE,
		"power_percent": 1.0,
		"accuracy_modifier": 0,
		"cooldown_turns": 0,
		"effect_id": "burned",
		"effect_chance": 0.2,
		"description": "Fiery slash. 20% burn chance."
	},
	"infernal_immolate": {
		"move_id": "infernal_immolate",
		"move_name": "Immolate",
		"move_type": MoveType.POWER,
		"damage_type": DamageType.FIRE,
		"power_percent": 1.7,
		"accuracy_modifier": -2,
		"cooldown_turns": 3,
		"effect_id": "burned",
		"effect_chance": 0.9,
		"description": "Engulf in flames. 90% burn chance."
	},
	"infernal_dark_pact": {
		"move_id": "infernal_dark_pact",
		"move_name": "Dark Pact",
		"move_type": MoveType.SPECIAL,
		"damage_type": DamageType.DARK,
		"power_percent": 0.0,
		"accuracy_modifier": 0,
		"cooldown_turns": 4,
		"effect_id": "",
		"effect_chance": 0.0,
		"description": "Sacrifice 20% HP to gain +4 ATK stages.",
		"targets_self": true
	},
	"infernal_self_destruct": {
		"move_id": "infernal_self_destruct",
		"move_name": "Self-Destruct",
		"move_type": MoveType.SPECIAL,
		"damage_type": DamageType.FIRE,
		"power_percent": 3.0,
		"accuracy_modifier": 10,
		"cooldown_turns": 0,
		"effect_id": "burned",
		"effect_chance": 1.0,
		"description": "Ultimate: Sacrifice self to deal massive AoE damage.",
		"is_aoe": true,
		"aoe_pattern": [[1, 0], [-1, 0], [0, 1], [0, -1], [1, 1], [-1, -1]]
	},
	
	# =========================================================================
	# SHADOW ASSASSIN (Flex/Assassin)
	# =========================================================================
	"assassin_stab": {
		"move_id": "assassin_stab",
		"move_name": "Quick Stab",
		"move_type": MoveType.STANDARD,
		"damage_type": DamageType.PHYSICAL,
		"power_percent": 1.0,
		"accuracy_modifier": 0,
		"cooldown_turns": 0,
		"effect_id": "",
		"effect_chance": 0.0,
		"description": "A quick dagger stab."
	},
	"assassin_backstab": {
		"move_id": "assassin_backstab",
		"move_name": "Backstab",
		"move_type": MoveType.POWER,
		"damage_type": DamageType.PHYSICAL,
		"power_percent": 2.5,
		"accuracy_modifier": -2,
		"cooldown_turns": 4,
		"effect_id": "",
		"effect_chance": 0.0,
		"description": "Devastating strike. Best used after Vanish for guaranteed crit."
	},
	"assassin_vanish": {
		"move_id": "assassin_vanish",
		"move_name": "Vanish",
		"move_type": MoveType.SPECIAL,
		"damage_type": DamageType.DARK,
		"power_percent": 0.0,
		"accuracy_modifier": 0,
		"cooldown_turns": 4,
		"effect_id": "stealth",
		"effect_chance": 1.0,
		"description": "Become invisible. Next attack is guaranteed crit.",
		"targets_self": true
	},
	"assassin_poison_blade": {
		"move_id": "assassin_poison_blade",
		"move_name": "Poison Blade",
		"move_type": MoveType.PRECISION,
		"damage_type": DamageType.NATURE,
		"power_percent": 0.8,
		"accuracy_modifier": 4,
		"cooldown_turns": 2,
		"effect_id": "poisoned",
		"effect_chance": 1.0,
		"description": "Venomous strike. Always poisons."
	},
	
	# =========================================================================
	# NECROMANCER (Flex/Magic)
	# =========================================================================
	"necro_touch": {
		"move_id": "necro_touch",
		"move_name": "Death Touch",
		"move_type": MoveType.STANDARD,
		"damage_type": DamageType.DARK,
		"power_percent": 1.0,
		"accuracy_modifier": 0,
		"cooldown_turns": 0,
		"effect_id": "",
		"effect_chance": 0.0,
		"description": "Touch of death."
	},
	"necro_soul_rip": {
		"move_id": "necro_soul_rip",
		"move_name": "Soul Rip",
		"move_type": MoveType.POWER,
		"damage_type": DamageType.DARK,
		"power_percent": 1.6,
		"accuracy_modifier": -2,
		"cooldown_turns": 3,
		"effect_id": "cursed",
		"effect_chance": 0.7,
		"description": "Tear at the soul. 70% curse chance."
	},
	"necro_fear": {
		"move_id": "necro_fear",
		"move_name": "Aura of Fear",
		"move_type": MoveType.SPECIAL,
		"damage_type": DamageType.DARK,
		"power_percent": 0.0,
		"accuracy_modifier": 0,
		"cooldown_turns": 4,
		"effect_id": "terrified",
		"effect_chance": 1.0,
		"description": "Terrify all adjacent enemies.",
		"is_aoe": true,
		"aoe_pattern": [[1, 0], [-1, 0], [0, 1], [0, -1], [1, 1], [-1, -1]]
	},
	"necro_summon": {
		"move_id": "necro_summon",
		"move_name": "Summon Skeleton",
		"move_type": MoveType.SPECIAL,
		"damage_type": DamageType.DARK,
		"power_percent": 0.0,
		"accuracy_modifier": 0,
		"cooldown_turns": 6,
		"effect_id": "",
		"effect_chance": 0.0,
		"description": "Summon a skeleton warrior (50 HP, 30 ATK)."
	},
	
	# =========================================================================
	# FROST GIANT (Ground/Special)
	# =========================================================================
	"giant_smash": {
		"move_id": "giant_smash",
		"move_name": "Ice Fist",
		"move_type": MoveType.STANDARD,
		"damage_type": DamageType.ICE,
		"power_percent": 1.0,
		"accuracy_modifier": 0,
		"cooldown_turns": 0,
		"effect_id": "",
		"effect_chance": 0.0,
		"description": "Smash with frozen fist."
	},
	"giant_glacier": {
		"move_id": "giant_glacier",
		"move_name": "Glacier Slam",
		"move_type": MoveType.POWER,
		"damage_type": DamageType.ICE,
		"power_percent": 2.0,
		"accuracy_modifier": -4,
		"cooldown_turns": 4,
		"effect_id": "slowed",
		"effect_chance": 0.8,
		"description": "Ground-shaking slam. 80% slow."
	},
	"giant_freeze": {
		"move_id": "giant_freeze",
		"move_name": "Freeze Aura",
		"move_type": MoveType.SPECIAL,
		"damage_type": DamageType.ICE,
		"power_percent": 0.4,
		"accuracy_modifier": 6,
		"cooldown_turns": 3,
		"effect_id": "slowed",
		"effect_chance": 1.0,
		"description": "Freeze nearby enemies.",
		"is_aoe": true,
		"aoe_pattern": [[1, 0], [-1, 0], [0, 1], [0, -1]]
	},
	"giant_stomp": {
		"move_id": "giant_stomp",
		"move_name": "Thunderous Stomp",
		"move_type": MoveType.PRECISION,
		"damage_type": DamageType.PHYSICAL,
		"power_percent": 0.7,
		"accuracy_modifier": 4,
		"cooldown_turns": 2,
		"effect_id": "stunned",
		"effect_chance": 0.4,
		"description": "Stomp the ground. 40% stun."
	},
	
	# =========================================================================
	# PHOENIX (Air/Special)
	# =========================================================================
	"phoenix_peck": {
		"move_id": "phoenix_peck",
		"move_name": "Fire Peck",
		"move_type": MoveType.STANDARD,
		"damage_type": DamageType.FIRE,
		"power_percent": 1.0,
		"accuracy_modifier": 0,
		"cooldown_turns": 0,
		"effect_id": "",
		"effect_chance": 0.0,
		"description": "Peck with fiery beak."
	},
	"phoenix_inferno": {
		"move_id": "phoenix_inferno",
		"move_name": "Inferno Wings",
		"move_type": MoveType.POWER,
		"damage_type": DamageType.FIRE,
		"power_percent": 1.5,
		"accuracy_modifier": -1,
		"cooldown_turns": 3,
		"effect_id": "burned",
		"effect_chance": 0.7,
		"description": "Engulf in flames. 70% burn.",
		"is_aoe": true,
		"aoe_pattern": [[1, 0], [-1, 0]]
	},
	"phoenix_rebirth": {
		"move_id": "phoenix_rebirth",
		"move_name": "Rebirth",
		"move_type": MoveType.SPECIAL,
		"damage_type": DamageType.HOLY,
		"power_percent": 0.0,
		"accuracy_modifier": 0,
		"cooldown_turns": 0,
		"effect_id": "",
		"effect_chance": 0.0,
		"description": "Passive: Revive once at 25% HP on death."
	},
	"phoenix_cleanse": {
		"move_id": "phoenix_cleanse",
		"move_name": "Purifying Flames",
		"move_type": MoveType.SPECIAL,
		"damage_type": DamageType.HOLY,
		"power_percent": 0.0,
		"accuracy_modifier": 0,
		"cooldown_turns": 4,
		"effect_id": "",
		"effect_chance": 0.0,
		"description": "Remove all debuffs from self and nearby allies.",
		"targets_self": true,
		"is_aoe": true,
		"aoe_pattern": [[1, 0], [-1, 0], [0, 1], [0, -1]]
	},
	
	# =========================================================================
	# DEMON LORD (Boss/Tank)
	# =========================================================================
	"demon_strike": {
		"move_id": "demon_strike",
		"move_name": "Infernal Strike",
		"move_type": MoveType.STANDARD,
		"damage_type": DamageType.FIRE,
		"power_percent": 1.0,
		"accuracy_modifier": 0,
		"cooldown_turns": 0,
		"effect_id": "",
		"effect_chance": 0.0,
		"description": "Strike with hellfire."
	},
	"demon_hellfire": {
		"move_id": "demon_hellfire",
		"move_name": "Hellfire",
		"move_type": MoveType.POWER,
		"damage_type": DamageType.FIRE,
		"power_percent": 1.8,
		"accuracy_modifier": -2,
		"cooldown_turns": 4,
		"effect_id": "burned",
		"effect_chance": 0.8,
		"description": "Rain hellfire. 80% burn.",
		"is_aoe": true,
		"aoe_pattern": [[0, 0], [1, 0], [-1, 0], [0, 1]]
	},
	"demon_terrify": {
		"move_id": "demon_terrify",
		"move_name": "Demonic Presence",
		"move_type": MoveType.SPECIAL,
		"damage_type": DamageType.DARK,
		"power_percent": 0.0,
		"accuracy_modifier": 0,
		"cooldown_turns": 5,
		"effect_id": "terrified",
		"effect_chance": 1.0,
		"description": "Terrify all enemies in range 2.",
		"is_aoe": true,
		"aoe_pattern": [[1, 0], [2, 0], [-1, 0], [-2, 0], [0, 1], [0, 2]]
	},
	"demon_dark_slash": {
		"move_id": "demon_dark_slash",
		"move_name": "Shadow Cleave",
		"move_type": MoveType.PRECISION,
		"damage_type": DamageType.DARK,
		"power_percent": 0.9,
		"accuracy_modifier": 3,
		"cooldown_turns": 2,
		"effect_id": "cursed",
		"effect_chance": 0.5,
		"description": "Dark slash. 50% curse."
	}
}

# =============================================================================
# TROOP TO MOVES MAPPING
# =============================================================================

const TROOP_MOVES: Dictionary = {
	"medieval_knight": ["knight_slash", "knight_shield_bash", "knight_heavy_strike", "knight_rally"],
	"four_headed_hydra": ["hydra_bite", "hydra_multi_strike", "hydra_regenerate", "hydra_acid_spray"],
	"dark_blood_dragon": ["dragon_claw", "dragon_fire_breath", "dragon_dark_pulse", "dragon_wing_buffet"],
	"griffin": ["griffin_talon", "griffin_dive_bomb", "griffin_screech", "griffin_gust"],
	"dark_magic_wizard": ["wizard_dark_bolt", "wizard_shadow_blast", "wizard_life_drain", "wizard_curse"],
	"elven_archer": ["archer_arrow", "archer_volley", "archer_poison_arrow", "archer_aimed_shot"],
	"celestial_cleric": ["cleric_smite", "cleric_heal", "cleric_purify", "cleric_resurrection"],
	"infernal_soul": ["infernal_slash", "infernal_immolate", "infernal_dark_pact", "infernal_self_destruct"],
	"shadow_assassin": ["assassin_stab", "assassin_backstab", "assassin_vanish", "assassin_poison_blade"],
	"necromancer": ["necro_touch", "necro_soul_rip", "necro_fear", "necro_summon"],
	"frost_giant": ["giant_smash", "giant_glacier", "giant_freeze", "giant_stomp"],
	"phoenix": ["phoenix_peck", "phoenix_inferno", "phoenix_rebirth", "phoenix_cleanse"],
	# Additional troops using thematically appropriate moves
	"sky_serpent": ["griffin_talon", "griffin_gust", "griffin_dive_bomb", "dragon_wing_buffet"],
	"frost_valkyrie": ["giant_smash", "giant_freeze", "knight_slash", "giant_stomp"],
	"demon_of_darkness": ["demon_strike", "demon_hellfire", "demon_terrify", "demon_dark_slash"],
	"thunder_behemoth": ["giant_smash", "giant_stomp", "knight_heavy_strike", "giant_glacier"],
	"frost_revenant": ["giant_smash", "giant_glacier", "giant_freeze", "necro_touch"],
	"ironclad_golem": ["knight_slash", "knight_shield_bash", "knight_heavy_strike", "knight_rally"]
}


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

## Get a Move object by ID
static func get_move(move_id: String) -> Move:
	var data = MOVES.get(move_id, {})
	if data.is_empty():
		push_error("MoveData: Unknown move ID: " + move_id)
		return null
	return Move.new(data)


## Get all moves for a specific troop
static func get_moves_for_troop(troop_id: String) -> Array:
	var move_ids = TROOP_MOVES.get(troop_id, [])
	var moves: Array = []
	
	for move_id in move_ids:
		var move = get_move(move_id)
		if move:
			moves.append(move)
	
	return moves


## Get move IDs for a specific troop
static func get_move_ids_for_troop(troop_id: String) -> Array:
	return TROOP_MOVES.get(troop_id, [])


## Get all moves as Move objects
static func get_all_moves() -> Array:
	var result: Array = []
	for move_id in MOVES:
		var move = get_move(move_id)
		if move:
			result.append(move)
	return result


## Get all moves of a specific type
static func get_moves_by_type(move_type: MoveType) -> Array:
	var result: Array = []
	for move_id in MOVES:
		if MOVES[move_id]["move_type"] == move_type:
			result.append(get_move(move_id))
	return result


## Get all moves that can apply a specific status effect
static func get_moves_with_effect(effect_id: String) -> Array:
	var result: Array = []
	for move_id in MOVES:
		if MOVES[move_id].get("effect_id", "") == effect_id:
			result.append(get_move(move_id))
	return result
