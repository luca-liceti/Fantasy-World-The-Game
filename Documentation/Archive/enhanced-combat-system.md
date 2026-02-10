# Combat System v2: D&D × Pokémon Hybrid

## Overview

This document outlines the combat system that combines the tactical depth of Dungeons & Dragons (Advantage/Disadvantage, d20 rolls, critical hits) with Pokémon's strategic elements (type effectiveness, move selection, stat stages). The system prioritizes **longer, more strategic battles** with **no direction-based mechanics**.

## Core Design Philosophy

| Principle | Implementation |
|-----------|----------------|
| **Hybrid D&D/Pokémon** | d20 with Advantage/Disadvantage + Type effectiveness multipliers |
| **No Direction Mechanics** | No backstab, no facing, no "attack from behind" bonuses |
| **Less Lethal** | 4-6 hit time-to-kill (extended battles) |
| **Attacker-Driven** | Attacker selects moves; defender has automatic reactions |
| **Predictable Damage** | Fixed damage formula (no damage dice) |
| **Strategic Depth** | Positioning, type matchups, and move selection matter |

---

## Combat Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    COMBAT INITIATION                            │
│  Attacker selects target in range                               │
└─────────────────────────┬───────────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│              PHASE 1: MOVE SELECTION                            │
│  • Attacker chooses 1 of 4 available moves                      │
│  • Cooldowns and PP checked                                     │
│  • No defender input required                                   │
└─────────────────────────┬───────────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│              PHASE 2: ROLL RESOLUTION                           │
│  • Check for Advantage/Disadvantage sources                     │
│  • Roll d20 (or 2d20 if Adv/Dis)                               │
│  • Add ATK modifier, compare vs DEF DC                          │
│  • Determine hit, miss, crit, or crit miss                      │
└─────────────────────────┬───────────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│              PHASE 3: DAMAGE CALCULATION                        │
│  • Calculate base damage (ATK × Move Power%)                    │
│  • Apply type effectiveness (×1.5 / ×1.0 / ×0.5)               │
│  • Apply defense reduction                                      │
│  • Apply critical hit multiplier if applicable (×1.5)           │
└─────────────────────────┬───────────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│              PHASE 4: CONDITIONAL REACTIONS                     │
│  • Check defender's reaction triggers                           │
│  • Apply automatic reactions (counter, damage reduction, etc.)  │
│  • Resolve final damage and effects                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## PHASE 1: Move Selection System

### Each Troop Has 4 Moves

Every troop has **4 unique moves** with different properties. Choosing the right move for the situation is a core skill expression.

### Move Categories

| Category | Description | Typical Properties |
|----------|-------------|-------------------|
| **Standard** | Reliable damage, no drawbacks | 100% power, +0 accuracy |
| **Power** | High damage, accuracy penalty | 130-150% power, -3 to -5 accuracy |
| **Precision** | Lower damage, accuracy bonus | 70-80% power, +4 to +6 accuracy |
| **Special** | Unique effect (status, buff, utility) | Varies by troop |

### Move Cooldowns

- Each non-Standard move has a cooldown (1-4 turns typically)
- Cooldowns tick down at the start of the troop's controller's turn
- Standard moves have no cooldown

---

## Complete Troop Movesets

### Ground Tanks

#### Medieval Knight
| Move | Type | Power | Accuracy | Effect | Cooldown |
|------|------|-------|----------|--------|----------|
| Sword Slash | Standard | 100% | +0 | — | — |
| Heavy Blow | Power | 140% | -4 | — | 2 turns |
| Precise Thrust | Precision | 75% | +5 | +15% crit chance | — |
| Shield Bash | Special (CC) | 50% | +0 | Target STUNNED (skips next action) | 3 turns |

**Conditional Reaction:** *Riposte* — On miss, counter-attack for 30% ATK damage.

#### Stone Giant
| Move | Type | Power | Accuracy | Effect | Cooldown |
|------|------|-------|----------|--------|----------|
| Boulder Smash | Standard | 100% | +0 | — | — |
| Ground Pound | Power + AoE | 120% | -4 | Hits all adjacent enemies | 3 turns |
| Stone Throw | Precision + Range | 65% | +4 | Range 2 hexes | — |
| Earthquake | CC | 0% | Auto | All enemies in 2 hexes: -2 Speed for 2 turns | 4 turns |

**Conditional Reaction:** *Thick Skin* — On critical hit received, reduce damage by 50%.

#### Four-Headed Hydra
| Move | Type | Power | Accuracy | Effect | Cooldown |
|------|------|-------|----------|--------|----------|
| Quad Bite | Standard | 100% | +0 | Hits up to 2 adjacent targets | — |
| Venom Spray | DoT | 50% | +0 | Target takes 15 damage/turn for 3 turns | 2 turns |
| Regenerate | Self-Heal | — | — | Heal 50 HP, skip attack | 3 turns |
| Raging Fury | Power | 180% | -3 | Hydra takes 25 recoil damage | 3 turns |

**Conditional Reaction:** *Regrowth* — On taking damage, heal 5% of max HP.

---

### Air/Hybrid Units

#### Dark Blood Dragon
| Move | Type | Power | Accuracy | Effect | Cooldown |
|------|------|-------|----------|--------|----------|
| Claw Strike | Standard | 100% | +0 | — | — |
| Fire Breath | Power + AoE | 110% | -3 | Hits target + 1 adjacent hex | 2 turns |
| Aerial Dive | Precision | 85% | +4 | Ignores cover bonuses | — |
| Terrify | Debuff | 0% | Auto | Target: -25% ATK for 2 turns | 3 turns |

**Conditional Reaction:** *Dragon's Fury* — On taking Ice damage, gain +1 ATK stage.

#### Sky Serpent
| Move | Type | Power | Accuracy | Effect | Cooldown |
|------|------|-------|----------|--------|----------|
| Wind Slash | Standard | 100% | +0 | — | — |
| Lightning Strike | Power | 150% | -5 | — | 2 turns |
| Coil Bind | CC | 60% | +0 | Target ROOTED (cannot move) for 2 turns | 3 turns |
| Evasive Maneuver | Buff | — | — | +50% dodge chance for next 2 attacks | 4 turns |

**Conditional Reaction:** *Slither Away* — On miss, gain Stealth for 1 turn.

#### Frost Valkyrie
| Move | Type | Power | Accuracy | Effect | Cooldown |
|------|------|-------|----------|--------|----------|
| Frost Blade | Standard | 100% | +0 | — | — |
| Blizzard Strike | Power + Slow | 120% | -2 | Target: -1 Speed for 2 turns | 2 turns |
| Shield Maiden | Counter | — | — | Next attack reflects 50% damage back | 3 turns |
| Healing Aura | Support | — | — | Heal self or adjacent ally 30 HP | 2 turns |

**Conditional Reaction:** *Frozen Resilience* — On taking Fire damage, gain +1 DEF stage.

---

### Ranged/Magic Units

#### Dark Magic Wizard
| Move | Type | Power | Accuracy | Effect | Cooldown |
|------|------|-------|----------|--------|----------|
| Arcane Bolt | Standard | 100% | +0 | Ignores 20% of DEF (magic penetration) | — |
| Soul Drain | Lifesteal | 80% | +0 | Heal 50% of damage dealt | 2 turns |
| Curse | Debuff | 0% | Auto | Target takes +30% damage for 2 turns | 3 turns |
| Arcane Explosion | Power + AoE | 130% | -4 | Hits all enemies within 2 hexes | 4 turns |

**Conditional Reaction:** *Arcane Barrier* — First hit each round deals 20% less damage.

#### Demon of Darkness
| Move | Type | Power | Accuracy | Effect | Cooldown |
|------|------|-------|----------|--------|----------|
| Dark Claw | Standard | 100% | +0 | Ignores 20% of DEF (magic penetration) | — |
| Hellfire | Power | 140% | -3 | — | 2 turns |
| Shadow Step | Utility | — | — | Teleport up to 3 hexes, no attack | 3 turns |
| Doom Mark | Execute | 60% / 150% | +0 | 150% power if target <30% HP, else 60% | 4 turns |

**Conditional Reaction:** *Demonic Hide* — Incoming Physical damage reduced by 15%.

#### Elven Archer
| Move | Type | Power | Accuracy | Effect | Cooldown |
|------|------|-------|----------|--------|----------|
| Arrow Shot | Standard | 100% | +0 | Range 3 | — |
| Multi-Shot | Multi-target | 70% | +0 | Hits up to 3 targets in range | 2 turns |
| Aimed Shot | Precision | 110% | +6 | Must not have moved this turn | 2 turns |
| Crippling Shot | CC | 60% | +0 | Target ROOTED for 2 turns | 3 turns |

**Conditional Reaction:** *Quick Reflexes* — On miss, retaliate with 40% ATK damage.

---

### Flex/Support/Assassin Units

#### Celestial Cleric
| Move | Type | Power | Accuracy | Effect | Cooldown |
|------|------|-------|----------|--------|----------|
| Holy Strike | Standard | 100% | +0 | — | — |
| Divine Heal | Heal | — | — | Heal ally for 60 HP, Range 2 | 1 turn |
| Purify | Cleanse | — | — | Remove all debuffs from self or ally | 2 turns |
| Resurrection | Ultimate | — | — | Revive dead ally at 50% HP | Once per game |

**Conditional Reaction:** *Divine Protection* — On status effect applied, cleanse it and heal 25 HP.

#### Shadow Assassin
| Move | Type | Power | Accuracy | Effect | Cooldown |
|------|------|-------|----------|--------|----------|
| Dagger Slash | Standard | 100% | +0 | — | — |
| Ambush | Conditional | 100% / 180% | +0 | 180% power if attacker has Stealth | 2 turns |
| Vanish | Stealth | — | — | Become untargetable for 1 turn | 4 turns |
| Execute | Finisher | 60% / 250% | +0 | 250% power if target <25% HP, else 60% | 3 turns |

**Conditional Reaction:** *Slippery* — On miss, gain Stealth for 1 turn.

#### Infernal Soul
| Move | Type | Power | Accuracy | Effect | Cooldown |
|------|------|-------|----------|--------|----------|
| Flame Touch | Standard | 100% | +0 | — | — |
| Self-Destruct | Sacrifice | 220% | Auto | Hits all adjacent enemies, Infernal Soul dies | N/A |
| Burn | DoT | 40% | +0 | Target burns for 20 damage/turn for 3 turns | 2 turns |
| Inferno Burst | Power + AoE | 130% | -3 | Hits all adjacent, self takes 15 damage | 3 turns |

**Conditional Reaction:** *Burning Aura* — On melee attack received, attacker takes 20 damage.
**Passive:** *Death Burst* — On death, deal 40 damage to all adjacent units.

---

## PHASE 2: Roll Resolution (D&D-style)

### Attack Roll Formula

```
ATTACK ROLL = d20 + (ATK ÷ 10) + Move Accuracy Modifier

TARGET DC = 10 + (DEF ÷ 10) + Cover Modifier

HIT CONDITION: ATTACK ROLL ≥ TARGET DC
```

### Advantage & Disadvantage

| Roll Type | Method |
|-----------|--------|
| **Normal** | Roll 1d20 |
| **Advantage** | Roll 2d20, take the **higher** result |
| **Disadvantage** | Roll 2d20, take the **lower** result |

**Rule:** Advantage and Disadvantage cancel each other out. If you have both, roll normally.

### Advantage Sources

| Source | Condition |
|--------|-----------|
| **Flanking** | Allied troop adjacent to target |
| **High Ground** | Attacker on Hills/Peaks biome |
| **Stealth** | Attacker is invisible/hidden |
| **Target Stunned** | Target has Stunned status |
| **Target Surrounded** | 3+ enemies adjacent to target |

### Disadvantage Sources

| Source | Condition |
|--------|-----------|
| **Cover** | Target on Forest/Ruins hex |
| **Attacker Slowed** | Attacker has Slowed status |
| **Attacker Cursed** | Attacker has Cursed status |
| **Long Range** | Ranged attack at maximum range |
| **Target Evasion** | Target has active evasion buff |

### Critical Hit System

| d20 Roll | Result |
|----------|--------|
| **Natural 1** | **Critical Miss** — Attack automatically fails. Attacker loses next reaction. |
| 2-19 | Normal roll — Apply modifiers and compare to DC |
| **Natural 20** | **Critical Hit** — Auto-hit regardless of DC. ×1.5 damage. Bypass reactions. |

---

## PHASE 3: Damage Calculation

### Damage Formula

```
BASE DAMAGE = ATK × Move Power%

TYPE DAMAGE = BASE DAMAGE × Type Effectiveness Multiplier

DEFENSE REDUCTION = TYPE DAMAGE ÷ (1 + DEF / 80)

FINAL DAMAGE = max(DEFENSE REDUCTION, 1)

CRITICAL DAMAGE = FINAL DAMAGE × 1.5
```

### Example Calculation

```
SITUATION:
- Shadow Assassin (ATK: 110) uses Execute on Medieval Knight (DEF: 120)
- Knight is below 25% HP, so Execute deals 250% power
- Assassin has Physical damage type, Knight resists Physical (×0.5)

CALCULATION:
├── Base Damage: 110 × 2.5 = 275
├── Type Effectiveness: 275 × 0.5 = 137.5 (not effective)
├── Defense Reduction: 137.5 ÷ (1 + 120/80) = 137.5 ÷ 2.5 = 55
└── Final Damage: 55

Result: Knight takes 55 damage (reduced due to type resistance + high DEF)
```

---

## Type Effectiveness System

### The 6 Damage Types

| Type | Strong Against (×1.5) | Weak Against (×0.5) |
|------|----------------------|---------------------|
| **Physical** | Mage, Archer | Tank, Giant |
| **Fire** | Ice, Nature | Dragon, Demon |
| **Ice** | Dragon, Serpent | Fire, Giant |
| **Dark** | Cleric, Valkyrie | Assassin, Soul |
| **Holy** | Demon, Soul, Assassin | — (no weakness) |
| **Nature** | Giant, Knight | Fire, Dragon |

### Troop Type Assignments

| Troop | Damage Type | Resistant To (×0.5 damage taken) | Weak To (×1.5 damage taken) |
|-------|-------------|----------------------------------|----------------------------|
| Medieval Knight | Physical | Physical | Fire, Dark |
| Stone Giant | Physical | Physical, Ice | Nature |
| Four-Headed Hydra | Nature | Nature | Ice, Fire |
| Dark Blood Dragon | Fire | Fire | Ice |
| Sky Serpent | Ice | Ice, Nature | Fire |
| Frost Valkyrie | Ice | Ice | Fire, Dark |
| Dark Magic Wizard | Dark | Dark | Holy |
| Demon of Darkness | Dark/Fire | Dark, Fire | Holy |
| Elven Archer | Physical/Nature | Nature | Dark, Fire |
| Celestial Cleric | Holy | Holy, Dark | — |
| Shadow Assassin | Dark | Dark | Holy |
| Infernal Soul | Fire | Fire | Ice, Holy |

---

## PHASE 4: Conditional Reactions

### How Reactions Work

1. Reactions are **automatic** — no player input required
2. Each troop has **one primary reaction** (some have a passive too)
3. Reactions trigger **after damage is calculated but before it's applied** (unless otherwise stated)
4. Reactions can be bypassed by **Critical Hits**

### Complete Reaction List

| Troop | Reaction Name | Trigger | Effect |
|-------|---------------|---------|--------|
| Medieval Knight | Riposte | On Miss | Counter-attack for 30% ATK |
| Stone Giant | Thick Skin | On Crit Received | Reduce damage by 50% |
| Four-Headed Hydra | Regrowth | On Damage Taken | Heal 5% max HP |
| Dark Blood Dragon | Dragon's Fury | On Ice Damage | Gain +1 ATK stage |
| Sky Serpent | Slither Away | On Miss | Gain Stealth for 1 turn |
| Frost Valkyrie | Frozen Resilience | On Fire Damage | Gain +1 DEF stage |
| Dark Magic Wizard | Arcane Barrier | First Hit Per Round | 20% damage reduction |
| Demon of Darkness | Demonic Hide | On Physical Damage | 15% damage reduction |
| Elven Archer | Quick Reflexes | On Miss | Retaliate for 40% ATK |
| Celestial Cleric | Divine Protection | On Status Applied | Cleanse + heal 25 HP |
| Shadow Assassin | Slippery | On Miss | Gain Stealth for 1 turn |
| Infernal Soul | Burning Aura | On Melee Attack | Attacker takes 20 damage |

---

## Status Conditions

### Condition Types

| Condition | Effect | Duration | Cure |
|-----------|--------|----------|------|
| **Stunned** | Skip next action | 1 turn | Automatic |
| **Burned** | Take 20 damage at turn start, -10% ATK | 3 turns | Purify |
| **Poisoned** | Take 15 damage at turn start | 3 turns | Purify |
| **Slowed** | -1 to -2 Speed, Disadvantage on attacks | 2 turns | Purify |
| **Cursed** | Take +30% damage from all sources | 2 turns | Purify |
| **Terrified** | -25% ATK | 2 turns | Purify |
| **Rooted** | Cannot move (can still attack) | 1-2 turns | Purify |
| **Stealth** | Cannot be targeted by enemies | 1 turn | Attacking/moving ends it |

### Condition Immunity

| Troop Category | Immune To |
|----------------|-----------|
| **Tanks** (Knight, Giant, Hydra) | Terrified |
| **Undead/Demon** (Demon, Soul) | Poisoned |
| **Air Units** (Dragon, Serpent, Valkyrie) | Rooted |

---

## Stat Stages (Pokémon-style Buffs/Debuffs)

Buffs and debuffs stack in **stages** from -6 to +6.

### Stage Multipliers

| Stage | Multiplier |
|-------|------------|
| -6 | 0.25× |
| -5 | 0.29× |
| -4 | 0.33× |
| -3 | 0.40× |
| -2 | 0.50× |
| -1 | 0.67× |
| 0 | 1.00× |
| +1 | 1.50× |
| +2 | 2.00× |
| +3 | 2.50× |
| +4 | 3.00× |
| +5 | 3.50× |
| +6 | 4.00× |

### Stacking Rules

- Multiple sources stack (e.g., two -1 ATK = -2 ATK stage)
- Stages cap at +6 and -6
- Stages reset when troop dies and is revived

---

## Positioning Bonuses

**Note:** Direction-based bonuses (backstab) have been removed.

| Condition | Bonus | How to Achieve |
|-----------|-------|----------------|
| **Flanking** | Advantage on attack | Allied troop adjacent to defender |
| **High Ground** | Advantage + 10% damage | Attacking from Hills/Peaks biome |
| **Surrounded** | Advantage on all attacks | 3+ enemies adjacent to defender |
| **Cover** | Disadvantage for attacker | Defender on Forest/Ruins hex |

---

## Lethality Adjustments

To ensure longer, more strategic battles:

| Adjustment | Value |
|------------|-------|
| **HP Scaling** | All troop HP increased by 30% |
| **Move Power** | All move power reduced by 15% |
| **Critical Multiplier** | 1.5× (reduced from 2×) |
| **Execute Threshold** | Bonus damage, not instant kill |
| **Defense Formula** | Divisor-based (never reduces to 0) |

### Target Time-to-Kill

| Scenario | Hits to Kill |
|----------|--------------|
| Glass cannon vs Glass cannon | 3-4 hits |
| Balanced vs Balanced | 4-5 hits |
| Tank vs Tank | 6-8 hits |
| Glass cannon vs Tank | 5-6 hits |
| With healing/support | 8+ hits |

---

## UI Requirements

### Move Selection Interface

```
┌──────────────────────────────────────────────────────────────────┐
│                    ⚔️ SELECT YOUR MOVE                           │
│                                                                  │
│   ATTACKER: Shadow Assassin          TARGET: Medieval Knight    │
│   ATK: 110 | HP: 180/180             DEF: 120 | HP: 260/260    │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │ [1] Dagger Slash      │ 100% PWR │ +0 ACC │ READY      │   │
│   │ [2] Ambush            │ 180% PWR │ +0 ACC │ READY      │   │
│   │ [3] Vanish            │ UTILITY  │ AUTO   │ 2 TURNS    │   │
│   │ [4] Execute           │ 60/250%  │ +0 ACC │ READY      │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
│   Type Matchup: Physical → Knight (RESISTED ×0.5)               │
│   Positioning: Flanking (ADVANTAGE)                              │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### Combat Resolution Display

```
┌──────────────────────────────────────────────────────────────────┐
│                         ⚔️ COMBAT RESULT                         │
│                                                                  │
│   Shadow Assassin uses EXECUTE on Medieval Knight!              │
│                                                                  │
│   Roll: [18] + 11 (ATK) = 29                                    │
│   vs DC: 10 + 12 (DEF) = 22                                     │
│                                                                  │
│   ✓ HIT!                                                         │
│                                                                  │
│   Damage: 110 × 60% = 66 base                                   │
│   × 0.5 (Not Effective) = 33                                    │
│   ÷ 2.5 (Defense) = 13                                          │
│                                                                  │
│   Medieval Knight takes 13 damage!                               │
│   ► Reaction: Riposte did not trigger (attack hit)              │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Skill Expression Summary

| Element | Skill Expression |
|---------|------------------|
| **Pre-Combat Positioning** | Place troops for flanking, high ground, cover |
| **Move Selection** | Choose the optimal move for the situation |
| **Type Matchups** | Know which troops counter which |
| **Cooldown Management** | Save powerful moves for key moments |
| **Buff/Debuff Setup** | Apply Curse/Terrify before ally attacks |
| **Resource Management** | Balance aggression with self-preservation |

**Skill vs Luck Balance:** ~75% Skill, ~25% Luck

---

## Balance Philosophy

- Power moves require commitment (cooldowns, positioning)
- Type effectiveness encourages diverse team composition
- Reactions add counterplay without requiring defender input
- The d20 creates memorable moments without deciding matches alone
- Advantage/Disadvantage is elegant and doesn't require complex math
- Less lethality means comebacks are possible

---

*Document Version: 2.0*
*Last Updated: 2025-12-23*
*Replaces: enhanced-combat-system.md v1.0*
