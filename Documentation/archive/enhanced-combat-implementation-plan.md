# Enhanced Combat System Implementation Plan

## Overview

This step-by-step implementation plan converts the Combat System v2 (D&D × Pokémon Hybrid) design document into actionable tasks with checkboxes for tracking progress.

---

## Phase 1: Core Foundation

### 1.1 Design Philosophy Setup
- [x] 1.1.1 Remove all direction-based mechanics (backstab, facing, attack from behind bonuses)
- [x] 1.1.2 Implement attacker-driven combat flow (no defender input during attacks)
- [x] 1.1.3 Set up fixed damage formula (no damage dice)
- [x] 1.1.4 Configure 4-6 hit time-to-kill lethality adjustments

### 1.2 Combat Flow Architecture
- [x] 1.2.1 Create combat initiation system (attacker selects target in range)
- [x] 1.2.2 Implement Phase 1: Move Selection
- [x] 1.2.3 Implement Phase 2: Roll Resolution
- [x] 1.2.4 Implement Phase 3: Damage Calculation
- [x] 1.2.5 Implement Phase 4: Conditional Reactions

---

## Phase 2: Move System

### 2.1 Move Categories
- [x] 2.1.1 Implement **Standard** moves (100% power, +0 accuracy, no drawbacks)
- [x] 2.1.2 Implement **Power** moves (130-150% power, -3 to -5 accuracy penalty)
- [x] 2.1.3 Implement **Precision** moves (70-80% power, +4 to +6 accuracy bonus)
- [x] 2.1.4 Implement **Special** moves (status, buff, utility effects)

### 2.2 Cooldown System
- [x] 2.2.1 Track cooldowns per move (1-4 turns typically)
- [x] 2.2.2 Tick down cooldowns at start of troop's controller's turn
- [x] 2.2.3 Standard moves have no cooldown (always available)

### 2.3 Each Troop Gets 4 Moves
- [x] 2.3.1 Set up move slot structure (4 unique moves per troop)

---

## Phase 3: Troop Moveset Implementation

### 3.1 Ground Tanks

#### 3.1.1 Medieval Knight
- [x] Sword Slash (Standard, 100% power, +0 acc)
- [x] Heavy Blow (Power, 140% power, -4 acc, 2 turn CD)
- [x] Precise Thrust (Precision, 75% power, +5 acc, +15% crit chance)
- [x] Shield Bash (Special CC, 50% power, +0 acc, STUN target, 3 turn CD)
- [x] Conditional Reaction: *Riposte* — On miss, counter-attack for 30% ATK damage

#### 3.1.2 Stone Giant
- [x] Boulder Smash (Standard, 100% power, +0 acc)
- [x] Ground Pound (Power + AoE, 120% power, -4 acc, hits all adjacent, 3 turn CD)
- [x] Stone Throw (Precision + Range, 65% power, +4 acc, Range 2 hexes)
- [x] Earthquake (CC, 0% power, Auto, all enemies in 2 hexes: -2 Speed for 2 turns, 4 turn CD)
- [x] Conditional Reaction: *Thick Skin* — On critical hit received, reduce damage by 50%

#### 3.1.3 Four-Headed Hydra
- [x] Quad Bite (Standard, 100% power, +0 acc, hits up to 2 adjacent targets)
- [x] Venom Spray (DoT, 50% power, +0 acc, 15 dmg/turn for 3 turns, 2 turn CD)
- [x] Regenerate (Self-Heal, heal 50 HP, skip attack, 3 turn CD)
- [x] Raging Fury (Power, 180% power, -3 acc, 25 recoil damage, 3 turn CD)
- [x] Conditional Reaction: *Regrowth* — On taking damage, heal 5% of max HP

### 3.2 Air/Hybrid Units

#### 3.2.1 Dark Blood Dragon
- [x] Claw Strike (Standard, 100% power, +0 acc)
- [x] Fire Breath (Power + AoE, 110% power, -3 acc, hits target + 1 adjacent hex, 2 turn CD)
- [x] Aerial Dive (Precision, 85% power, +4 acc, ignores cover bonuses)
- [x] Terrify (Debuff, 0% power, Auto, -25% ATK for 2 turns, 3 turn CD)
- [x] Conditional Reaction: *Dragon's Fury* — On taking Ice damage, gain +1 ATK stage

#### 3.2.2 Sky Serpent
- [x] Wind Slash (Standard, 100% power, +0 acc)
- [x] Lightning Strike (Power, 150% power, -5 acc, 2 turn CD)
- [x] Coil Bind (CC, 60% power, +0 acc, ROOT target for 2 turns, 3 turn CD)
- [x] Evasive Maneuver (Buff, +50% dodge chance for next 2 attacks, 4 turn CD)
- [x] Conditional Reaction: *Slither Away* — On miss, gain Stealth for 1 turn

#### 3.2.3 Frost Valkyrie
- [x] Frost Blade (Standard, 100% power, +0 acc)
- [x] Blizzard Strike (Power + Slow, 120% power, -2 acc, -1 Speed for 2 turns, 2 turn CD)
- [x] Shield Maiden (Counter, next attack reflects 50% damage back, 3 turn CD)
- [x] Healing Aura (Support, heal self or adjacent ally 30 HP, 2 turn CD)
- [x] Conditional Reaction: *Frozen Resilience* — On taking Fire damage, gain +1 DEF stage

### 3.3 Ranged/Magic Units

#### 3.3.1 Dark Magic Wizard
- [x] Arcane Bolt (Standard, 100% power, +0 acc, ignores 20% of DEF)
- [x] Soul Drain (Lifesteal, 80% power, +0 acc, heal 50% of damage dealt, 2 turn CD)
- [x] Curse (Debuff, 0% power, Auto, target takes +30% damage for 2 turns, 3 turn CD)
- [x] Arcane Explosion (Power + AoE, 130% power, -4 acc, hits all enemies within 2 hexes, 4 turn CD)
- [x] Conditional Reaction: *Arcane Barrier* — First hit each round deals 20% less damage

#### 3.3.2 Demon of Darkness
- [x] Dark Claw (Standard, 100% power, +0 acc, ignores 20% of DEF)
- [x] Hellfire (Power, 140% power, -3 acc, 2 turn CD)
- [x] Shadow Step (Utility, teleport up to 3 hexes, no attack, 3 turn CD)
- [x] Doom Mark (Execute, 60%/150% power, +0 acc, 150% if target <30% HP, 4 turn CD)
- [x] Conditional Reaction: *Demonic Hide* — Incoming Physical damage reduced by 15%

#### 3.3.3 Elven Archer
- [x] Arrow Shot (Standard, 100% power, +0 acc, Range 3)
- [x] Multi-Shot (Multi-target, 70% power, +0 acc, hits up to 3 targets, 2 turn CD)
- [x] Aimed Shot (Precision, 110% power, +6 acc, must not have moved this turn, 2 turn CD)
- [x] Crippling Shot (CC, 60% power, +0 acc, ROOT target for 2 turns, 3 turn CD)
- [x] Conditional Reaction: *Quick Reflexes* — On miss, retaliate with 40% ATK damage

### 3.4 Flex/Support/Assassin Units

#### 3.4.1 Celestial Cleric
- [x] Holy Strike (Standard, 100% power, +0 acc)
- [x] Divine Heal (Heal, heal ally for 60 HP, Range 2, 1 turn CD)
- [x] Purify (Cleanse, remove all debuffs from self or ally, 2 turn CD)
- [x] Resurrection (Ultimate, revive dead ally at 50% HP, once per game)
- [x] Conditional Reaction: *Divine Protection* — On status effect applied, cleanse it and heal 25 HP

#### 3.4.2 Shadow Assassin
- [x] Dagger Slash (Standard, 100% power, +0 acc)
- [x] Ambush (Conditional, 100%/180% power, +0 acc, 180% if attacker has Stealth, 2 turn CD)
- [x] Vanish (Stealth, become untargetable for 1 turn, 4 turn CD)
- [x] Execute (Finisher, 60%/250% power, +0 acc, 250% if target <25% HP, 3 turn CD)
- [x] Conditional Reaction: *Slippery* — On miss, gain Stealth for 1 turn

#### 3.4.3 Infernal Soul
- [x] Flame Touch (Standard, 100% power, +0 acc)
- [x] Self-Destruct (Sacrifice, 220% power, Auto, hits all adjacent, Infernal Soul dies)
- [x] Burn (DoT, 40% power, +0 acc, 20 dmg/turn for 3 turns, 2 turn CD)
- [x] Inferno Burst (Power + AoE, 130% power, -3 acc, hits all adjacent, self takes 15 dmg, 3 turn CD)
- [x] Conditional Reaction: *Burning Aura* — On melee attack received, attacker takes 20 damage
- [x] Passive: *Death Burst* — On death, deal 40 damage to all adjacent units

---

## Phase 4: Roll Resolution System (D&D-style)

### 4.1 Attack Roll Formula
- [x] 4.1.1 Implement: `ATTACK ROLL = d20 + (ATK ÷ 10) + Move Accuracy Modifier`
- [x] 4.1.2 Implement: `TARGET DC = 10 + (DEF ÷ 10) + Cover Modifier`
- [x] 4.1.3 Implement: `HIT CONDITION: ATTACK ROLL ≥ TARGET DC`

### 4.2 Advantage & Disadvantage System
- [x] 4.2.1 Normal roll: Roll 1d20
- [x] 4.2.2 Advantage: Roll 2d20, take the **higher** result
- [x] 4.2.3 Disadvantage: Roll 2d20, take the **lower** result
- [x] 4.2.4 Rule: Advantage and Disadvantage cancel each other out

### 4.3 Advantage Sources
- [x] 4.3.1 **Flanking**: Allied troop adjacent to target
- [x] 4.3.2 **High Ground**: Attacker on Hills/Peaks biome
- [x] 4.3.3 **Stealth**: Attacker is invisible/hidden
- [x] 4.3.4 **Target Stunned**: Target has Stunned status
- [x] 4.3.5 **Target Surrounded**: 3+ enemies adjacent to target

### 4.4 Disadvantage Sources
- [x] 4.4.1 **Cover**: Target on Forest/Ruins hex
- [x] 4.4.2 **Attacker Slowed**: Attacker has Slowed status
- [x] 4.4.3 **Attacker Cursed**: Attacker has Cursed status
- [x] 4.4.4 **Long Range**: Ranged attack at maximum range
- [x] 4.4.5 **Target Evasion**: Target has active evasion buff

### 4.5 Critical Hit System
- [x] 4.5.1 **Natural 1** (Critical Miss): Attack automatically fails, attacker loses next reaction
- [x] 4.5.2 **2-19**: Normal roll — Apply modifiers and compare to DC
- [x] 4.5.3 **Natural 20** (Critical Hit): Auto-hit, ×1.5 damage, bypass reactions

---

## Phase 5: Damage Calculation System

### 5.1 Damage Formula Implementation
- [x] 5.1.1 Implement: `BASE DAMAGE = ATK × Move Power%`
- [x] 5.1.2 Implement: `TYPE DAMAGE = BASE DAMAGE × Type Effectiveness Multiplier`
- [x] 5.1.3 Implement: `DEFENSE REDUCTION = TYPE DAMAGE ÷ (1 + DEF / 80)`
- [x] 5.1.4 Implement: `FINAL DAMAGE = max(DEFENSE REDUCTION, 1)`
- [x] 5.1.5 Implement: `CRITICAL DAMAGE = FINAL DAMAGE × 1.5`

---

## Phase 6: Type Effectiveness System

### 6.1 The 6 Damage Types
- [x] 6.1.1 **Physical**: Strong vs Mage, Archer | Weak vs Tank, Giant
- [x] 6.1.2 **Fire**: Strong vs Ice, Nature | Weak vs Dragon, Demon
- [x] 6.1.3 **Ice**: Strong vs Dragon, Serpent | Weak vs Fire, Giant
- [x] 6.1.4 **Dark**: Strong vs Cleric, Valkyrie | Weak vs Assassin, Soul
- [x] 6.1.5 **Holy**: Strong vs Demon, Soul, Assassin | No weakness
- [x] 6.1.6 **Nature**: Strong vs Giant, Knight | Weak vs Fire, Dragon

### 6.2 Troop Type Assignments
- [x] 6.2.1 Medieval Knight: Physical damage, resists Physical, weak to Fire/Dark
- [x] 6.2.2 Stone Giant: Physical damage, resists Physical/Ice, weak to Nature
- [x] 6.2.3 Four-Headed Hydra: Nature damage, resists Nature, weak to Ice/Fire
- [x] 6.2.4 Dark Blood Dragon: Fire damage, resists Fire, weak to Ice
- [x] 6.2.5 Sky Serpent: Ice damage, resists Ice/Nature, weak to Fire
- [x] 6.2.6 Frost Valkyrie: Ice damage, resists Ice, weak to Fire/Dark
- [x] 6.2.7 Dark Magic Wizard: Dark damage, resists Dark, weak to Holy
- [x] 6.2.8 Demon of Darkness: Dark/Fire damage, resists Dark/Fire, weak to Holy
- [x] 6.2.9 Elven Archer: Physical/Nature damage, resists Nature, weak to Dark/Fire
- [x] 6.2.10 Celestial Cleric: Holy damage, resists Holy/Dark, no weakness
- [x] 6.2.11 Shadow Assassin: Dark damage, resists Dark, weak to Holy
- [x] 6.2.12 Infernal Soul: Fire damage, resists Fire, weak to Ice/Holy

---

## Phase 7: Conditional Reactions System

### 7.1 Reaction Mechanics
- [x] 7.1.1 Reactions are automatic (no player input required)
- [x] 7.1.2 Each troop has one primary reaction
- [x] 7.1.3 Reactions trigger after damage calculated, before applied
- [x] 7.1.4 Critical Hits bypass reactions

### 7.2 Implement All Reactions
- [x] 7.2.1 Medieval Knight: *Riposte* — On Miss → Counter-attack for 30% ATK
- [x] 7.2.2 Stone Giant: *Thick Skin* — On Crit Received → Reduce damage by 50%
- [x] 7.2.3 Four-Headed Hydra: *Regrowth* — On Damage Taken → Heal 5% max HP
- [x] 7.2.4 Dark Blood Dragon: *Dragon's Fury* — On Ice Damage → Gain +1 ATK stage
- [x] 7.2.5 Sky Serpent: *Slither Away* — On Miss → Gain Stealth for 1 turn
- [x] 7.2.6 Frost Valkyrie: *Frozen Resilience* — On Fire Damage → Gain +1 DEF stage
- [x] 7.2.7 Dark Magic Wizard: *Arcane Barrier* — First Hit Per Round → 20% damage reduction
- [x] 7.2.8 Demon of Darkness: *Demonic Hide* — On Physical Damage → 15% damage reduction
- [x] 7.2.9 Elven Archer: *Quick Reflexes* — On Miss → Retaliate for 40% ATK
- [x] 7.2.10 Celestial Cleric: *Divine Protection* — On Status Applied → Cleanse + heal 25 HP
- [x] 7.2.11 Shadow Assassin: *Slippery* — On Miss → Gain Stealth for 1 turn
- [x] 7.2.12 Infernal Soul: *Burning Aura* — On Melee Attack → Attacker takes 20 damage

---

## Phase 8: Status Conditions System

### 8.1 Condition Types
- [x] 8.1.1 **Stunned**: Skip next action, 1 turn, auto-cure
- [x] 8.1.2 **Burned**: 20 damage at turn start, -10% ATK, 3 turns, Purify cures
- [x] 8.1.3 **Poisoned**: 15 damage at turn start, 3 turns, Purify cures
- [x] 8.1.4 **Slowed**: -1 to -2 Speed, Disadvantage on attacks, 2 turns, Purify cures
- [x] 8.1.5 **Cursed**: Take +30% damage from all sources, 2 turns, Purify cures
- [x] 8.1.6 **Terrified**: -25% ATK, 2 turns, Purify cures
- [x] 8.1.7 **Rooted**: Cannot move (can still attack), 1-2 turns, Purify cures
- [x] 8.1.8 **Stealth**: Cannot be targeted by enemies, 1 turn, attacking/moving ends it

### 8.2 Condition Immunities
- [x] 8.2.1 **Tanks** (Knight, Giant, Hydra): Immune to Terrified
- [x] 8.2.2 **Undead/Demon** (Demon, Soul): Immune to Poisoned
- [x] 8.2.3 **Air Units** (Dragon, Serpent, Valkyrie): Immune to Rooted

---

## Phase 9: Stat Stages System (Pokémon-style)

### 9.1 Stage Multipliers
- [x] 9.1.1 Implement stage range: -6 to +6
- [x] 9.1.2 Stage -6: 0.25×
- [x] 9.1.3 Stage -5: 0.29×
- [x] 9.1.4 Stage -4: 0.33×
- [x] 9.1.5 Stage -3: 0.40×
- [x] 9.1.6 Stage -2: 0.50×
- [x] 9.1.7 Stage -1: 0.67×
- [x] 9.1.8 Stage 0: 1.00×
- [x] 9.1.9 Stage +1: 1.50×
- [x] 9.1.10 Stage +2: 2.00×
- [x] 9.1.11 Stage +3: 2.50×
- [x] 9.1.12 Stage +4: 3.00×
- [x] 9.1.13 Stage +5: 3.50×
- [x] 9.1.14 Stage +6: 4.00×

### 9.2 Stacking Rules
- [x] 9.2.1 Multiple sources stack (e.g., two -1 ATK = -2 ATK stage)
- [x] 9.2.2 Stages cap at +6 and -6
- [x] 9.2.3 Stages reset when troop dies and is revived

---

## Phase 10: Positioning Bonuses

### 10.1 Position-Based Bonuses (No Direction Mechanics)
- [x] 10.1.1 **Flanking**: Advantage on attack — Allied troop adjacent to defender
- [x] 10.1.2 **High Ground**: Advantage + 10% damage — Attacking from Hills/Peaks biome
- [x] 10.1.3 **Surrounded**: Advantage on all attacks — 3+ enemies adjacent to defender
- [x] 10.1.4 **Cover**: Disadvantage for attacker — Defender on Forest/Ruins hex

---

## Phase 11: Lethality Adjustments

### 11.1 Balance Adjustments
- [x] 11.1.1 **HP Scaling**: All troop HP increased by 30%
- [x] 11.1.2 **Move Power**: All move power reduced by 15%
- [x] 11.1.3 **Critical Multiplier**: 1.5× (reduced from 2×)
- [x] 11.1.4 **Execute Threshold**: Bonus damage, not instant kill
- [x] 11.1.5 **Defense Formula**: Divisor-based (never reduces to 0)

### 11.2 Target Time-to-Kill Validation
- [x] 11.2.1 Glass cannon vs Glass cannon: 3-4 hits ✓
- [x] 11.2.2 Balanced vs Balanced: 4-5 hits ✓
- [x] 11.2.3 Tank vs Tank: 6-8 hits ✓
- [x] 11.2.4 Glass cannon vs Tank: 5-6 hits ✓
- [x] 11.2.5 With healing/support: 8+ hits ✓

---

## Phase 12: UI Implementation

### 12.1 Move Selection Interface
- [x] 12.1.1 Display attacker and target info (name, ATK, HP, DEF)
- [x] 12.1.2 Show 4 move buttons with: Name, Power %, Accuracy, Cooldown status
- [x] 12.1.3 Display Type Matchup preview (effective/resisted/neutral)
- [x] 12.1.4 Show Positioning info (flanking, high ground, cover)
- [x] 12.1.5 Disable moves on cooldown (show remaining turns)

### 12.2 Combat Resolution Display
- [x] 12.2.1 Show attacking troop's move and target
- [x] 12.2.2 Display d20 roll result + modifiers
- [x] 12.2.3 Show DC calculation (10 + DEF modifier)
- [x] 12.2.4 Display HIT/MISS/CRIT/CRIT MISS result
- [x] 12.2.5 Show damage calculation breakdown (base → type → defense → final)
- [x] 12.2.6 Display reaction trigger results

---

## Progress Tracker

| Phase | Description | Tasks | Completed |
|-------|-------------|-------|-----------|
| 1 | Core Foundation | 9 | 9 ✓ |
| 2 | Move System | 7 | 7 ✓ |
| 3 | Troop Movesets | 66 | 66 ✓ |
| 4 | Roll Resolution | 17 | 17 ✓ |
| 5 | Damage Calculation | 5 | 5 ✓ |
| 6 | Type Effectiveness | 18 | 18 ✓ |
| 7 | Conditional Reactions | 16 | 16 ✓ |
| 8 | Status Conditions | 11 | 11 ✓ |
| 9 | Stat Stages | 17 | 17 ✓ |
| 10 | Positioning Bonuses | 4 | 4 ✓ |
| 11 | Lethality Adjustments | 10 | 10 ✓ |
| 12 | UI Implementation | 11 | 11 ✓ |
| **TOTAL** | | **191** | **191** ✓ |

---

*Document Version: 1.0*
*Created: 2025-12-23*
*Based on: enhanced-combat-system.md v2.0*
