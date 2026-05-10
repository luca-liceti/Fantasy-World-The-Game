# Fantasy World — Combat Reference

> **Single source of truth for all combat rules.**
> Last updated: 2026-05-09. Supersedes all prior versions.

---

## Table of Contents

1. [Draft Phase](#1-draft-phase)
2. [Combat Flow](#2-combat-flow)
3. [Move Category Taxonomy](#3-move-category-taxonomy)
4. [Moves](#4-moves)
5. [Defensive Stances](#5-defensive-stances)
6. [Dice System](#6-dice-system)
7. [Damage Formula](#7-damage-formula)
8. [Damage Types & Type Effectiveness](#8-damage-types--type-effectiveness)
9. [Positioning Bonuses](#9-positioning-bonuses)
10. [Biome Modifiers](#10-biome-modifiers)
11. [Status Effects](#11-status-effects)
12. [Range & Line of Sight](#12-range--line-of-sight)
13. [Troop Roster & Moves](#13-troop-roster--moves)
14. [Signature Specials](#14-signature-specials)
15. [General Rules](#15-general-rules)
16. [Simplified Combat Mode](#16-simplified-combat-mode)

---

## 1. Draft Phase

- First pick is determined by a **d20 dice roll** — higher roll picks first.
- **Snake draft**: P1 picks → P2 picks → P2 picks → P1 picks.
- **Role slots must be filled**: 1 Ground Tank · 1 Air/Hybrid · 1 Ranged/Magic · 1 Flex.
- Picks are **visible** — counter-picking is a deliberate strategy.
- **20 seconds** per pick. Timer expiry auto-selects first valid option.
- **Duplicates allowed** — denying a troop from your opponent is valid.
- No mana or resource system — any combination within role slots is valid.

---

## 2. Combat Flow

1. **Attacker** selects a target within range.
2. **Simultaneous Selection Phase (10 seconds)** — attacker picks a Move, defender picks a Stance. Neither is revealed yet.
3. **Reaction Window (2 seconds)** — defender sees the attacker's **move category** (not the exact move) and may swap their stance once, only if they have at least one move off cooldown.
4. Selections are **revealed simultaneously**.
5. Dice are rolled, modifiers applied, damage calculated.
6. Post-combat effects resolve (status effects applied, death checks, etc.).

> **On selection timeout:** attacker defaults to their first available Standard move. Defender defaults to Brace. Stunned defenders always auto-Brace.

---

## 3. Move Category Taxonomy

Used during the Reaction Window. The defender sees a category label — not the exact move name.

| Move | Category Label | Meaning |
|------|---------------|---------|
| Standard | ⚖️ **Measured** | Balanced attack, no special risk |
| Precision | 🎯 **Careful** | Lower damage, accuracy-focused |
| Power | 💥 **Aggressive** | High damage, lower accuracy |
| Special | ✨ **Special** | Unique ability — expect an effect |

> Special is shown as its own category because the defender can already see the attacker's cooldown state on the board UI. Revealing "Special" gives fair warning without spoiling the exact ability.

---

## 4. Moves

Each troop has exactly **4 moves**: Standard, Power, Precision, and Special. The Special is unique per troop (see [Section 14](#14-signature-specials)).

| Move | Power | Accuracy Modifier | Cooldown |
|------|-------|-------------------|----------|
| **Standard** | 100% ATK | ±0 | None |
| **Power** | 150% ATK | −3 | 3 turns |
| **Precision** | 80% ATK | +5 | 2 turns |
| **Special** | Unique | Unique | 4 turns (unless noted) |

---

## 5. Defensive Stances

| Stance | Effect |
|--------|--------|
| 🛡️ **Brace** | +3 DEF modifier to DC. −20% incoming damage. Negates knockback. |
| ⚡ **Dodge** | +5 Evasion added to Defense DC. |
| ↩️ **Counter** | On attacker miss: deal 50% of defender's ATK back to the attacker (no roll required). |
| 💪 **Endure** | Survive a killing blow at 1 HP + immediately restore 20 HP. **Once per match.** Cannot be negated by Desperation moves. |

> Critical hits bypass Brace, Dodge, and Counter. Endure is the only stance that is **never bypassed** by crits.

---

## 6. Dice System

- **Dice type**: d20 (1–20)
- **Attack Roll** = d20 + (ATK ÷ 10) + Move Accuracy Modifier + Position Bonuses
- **Defense DC** = 10 + (DEF ÷ 10) + Stance Bonus + Position Bonuses
- **Attack succeeds** if Attack Roll > Defense DC
- **Tie** → re-roll (maximum 3×). After 3 draws, **defender wins**.

### Crits & Misses

| Natural Roll | Result |
|--------------|--------|
| 18, 19, or 20 | **Critical Hit** — 2× damage (applied before DEF reduction) |
| 1 | **Critical Miss** — automatic miss, no damage |

### Stealth Attacks

If the attacker is currently **Stealthed**, the attack is a **guaranteed critical hit** regardless of roll. Stealth is removed immediately upon attacking.

---

## 7. Damage Formula

```
If attack roll > defense DC:

  Raw Damage = ATK × Power% × Type Effectiveness × Biome Modifier

  If Critical Hit:
    Raw Damage × 2   ← applied BEFORE DEF reduction

  DEF Reduction = DEF ÷ 2
  If Magic attack: DEF Reduction = max(0, DEF/2 − 20)

  Final Damage = max(1,  Raw Damage − DEF Reduction)

If attack roll ≤ defense DC:
  No damage. Check for Counter stance trigger.
```

**Key rules:**
- Minimum damage is always **1** (can never deal 0 on a hit).
- **Magic** attacks (Dark, Holy, Nature types from a magic-capable troop) reduce the defender's DEF/2 term by a flat **20**, minimum 0. This is NOT a percentage — it is a flat subtraction.
- Type Effectiveness and Biome Modifier are **multiplicative**.

**Example:** Frost Valkyrie (ATK 95, Ice type) uses Precision move (80% power) against a BEAST-type troop (1.5× Ice type) in Peaks biome (+15%), the troop has DEF 80.
```
Raw Damage = 95 × 0.80 × 1.5 × 1.15 = 131.1
DEF Reduction = 80 / 2 = 40
Final Damage = max(1, 131 − 40) = 91
```

---

## 8. Damage Types & Type Effectiveness

### Effectiveness Multipliers

| Result | Multiplier |
|--------|-----------|
| Super Effective | 1.5× |
| Normal | 1.0× |
| Not Very Effective | 0.5× |
| Immune | 0× |

### Type Chart

| Damage Type | Super Effective vs. | Not Very Effective vs. | Immune |
|-------------|---------------------|------------------------|--------|
| ⚔️ Physical | — (varies by troop) | CONSTRUCT | — |
| 🔥 Fire | UNDEAD, NATURE | ELEMENTAL | — |
| ❄️ Ice | BEAST, NATURE | ELEMENTAL | — |
| 🌑 Dark | SPIRIT | HOLY | — |
| ✨ Holy | UNDEAD, DARK types | — | — |
| 🌿 Nature | BEAST | UNDEAD | — |

> **Magic types** (Dark, Holy, Nature) deal reduced DEF when used by a magic-capable troop (see Section 7).

---

## 9. Positioning Bonuses

| Bonus | Effect | Condition |
|-------|--------|-----------|
| **Flanking** | +3 to Attack Roll | At least 1 friendly troop is adjacent to the defender |
| **Cover** | +3 to Defense DC | Defender is standing on a Forest or Ruins hex |
| **Surrounded** | −2 to Defense DC | 3 or more enemies are adjacent to the defender |

All positioning bonuses stack with each other.

---

## 10. Biome Modifiers

Every troop has exactly **one strong biome** (+S, +15% damage dealt) and **one weak biome** (−S, −25% damage dealt). All other biomes are neutral. There are exactly 6 biomes, always present on the board in approximately equal hex counts.

| Troop | Forest 🌲 | Peaks ❄️ | Wastes 🏜️ | Plains 🌾 | Ashlands 🌋 | Swamp 🌿 |
|-------|-----------|----------|------------|-----------|-------------|----------|
| Medieval Knight | — | — | — | **+S** | — | −S |
| Stone Giant | — | — | **+S** | — | — | −S |
| Four-Headed Hydra | −S | — | — | — | — | **+S** |
| Dark Blood Dragon | — | — | **+S** | — | — | −S |
| Sky Serpent | — | **+S** | — | — | −S | — |
| Frost Valkyrie | — | **+S** | −S | — | — | — |
| Dark Magic Wizard | **+S** | — | — | −S | — | — |
| Demon of Darkness | — | — | — | −S | **+S** | — |
| Elven Archer | **+S** | — | −S | — | — | — |
| Celestial Cleric | — | — | — | **+S** | −S | — |
| Shadow Assassin | — | −S | — | — | — | **+S** |
| Infernal Soul | — | −S | — | — | **+S** | — |

### Biome Symmetry (each biome boosts 2, weakens 2)

| Biome | Boosted Troops | Weakened Troops |
|-------|----------------|-----------------|
| Forest 🌲 | Elven Archer, Dark Magic Wizard | Stone Giant, Four-Headed Hydra |
| Peaks ❄️ | Frost Valkyrie, Sky Serpent | Shadow Assassin, Infernal Soul |
| Wastes 🏜️ | Stone Giant, Dark Blood Dragon | Frost Valkyrie, Elven Archer |
| Plains 🌾 | Medieval Knight, Celestial Cleric | Dark Magic Wizard, Demon of Darkness |
| Ashlands 🌋 | Infernal Soul, Demon of Darkness | Sky Serpent, Celestial Cleric |
| Swamp 🌿 | Four-Headed Hydra, Shadow Assassin | Medieval Knight, Dark Blood Dragon |

---

## 11. Status Effects

### Effect Table

| Effect | Duration | Effect |
|--------|----------|--------|
| ⚡ **Stunned** | 1 turn | Cannot act. Auto-Brace if attacked while stunned. |
| 🔥 **Burned** | 3 turns | 10 damage at the start of each of the afflicted troop's turns. |
| ☠️ **Poisoned** | 4 turns | 8 damage at the start of each of the afflicted troop's turns. |
| 🐢 **Slowed** | 2 turns | −2 Speed (flat reduction, not percentage). |
| 💀 **Cursed** | 3 turns | −25% ATK. |
| 😱 **Terrified** | 2 turns | −25% DEF. |
| 🌿 **Rooted** | 2 turns | Cannot move. Can still attack. |
| 👻 **Stealth** | 3 turns | Next attack is a guaranteed critical hit. Stealth ends immediately when the troop attacks. |

> Some moves apply Rooted for a duration different from the default (e.g., Elven Archer's Pinning Shot applies Rooted for **3 turns**, Frost Valkyrie's Ice Lance applies Rooted for **2 turns**).

### Status Immunities

| Troop | Immune To |
|-------|-----------|
| Infernal Soul | Burned |
| Frost Valkyrie | Slowed |
| Celestial Cleric | Cursed |

> **Shadow Assassin** is not immune to any status effect, but **begins every match with Stealth active** (the 3-turn starting Stealth is applied at spawn).

### Application Rules

- A troop can only have **one instance** of each status effect at a time. Re-applying refreshes the duration.
- Status effects applied by a move are checked against the defender's immunities before being applied.
- DoT damage (Burned, Poisoned) is dealt at the **start of the afflicted troop's turn** before they act.
- A troop reduced to 0 HP by DoT damage dies immediately at the start of their turn.

---

## 12. Range & Line of Sight

| Range Value | Reach |
|-------------|-------|
| 1 | Adjacent hex only (melee) |
| 2 | Up to 2 hexes |
| 3 | Up to 3 hexes |

- **No terrain-based LOS blocking** — all terrain is transparent.
- **Units do not block LOS** — you can shoot through allied or enemy troops.
- **Air units** (Dark Blood Dragon, Sky Serpent) can attack all ground units.
- **Only Ranged and Magic ground units** can attack air units. (Exception: Frost Valkyrie.)
- **Frost Valkyrie** (Hybrid) is treated as a **ground unit** for targeting purposes — she can attack and be attacked by any unit.
- Range is always counted from the attacking troop's hex.

---

## 13. Troop Roster & Moves

All 12 player-selectable troops. NPCs (Goblin, Orc, Troll) have separate stats in `card_data.gd`.

---

### Ground Tank Role (pick 1)

#### Medieval Knight
HP: 150 | ATK: 80 | DEF: 130 | Range: 1 (Melee) | Speed: 2
Damage type: Physical | Strong: Plains | Weak: Swamp

| Move | Type | Power | Accuracy | Cooldown | Effect |
|------|------|-------|----------|----------|--------|
| Sword Slash | Standard | 100% | ±0 | — | — |
| Heavy Strike | Power | 150% | −3 | 3t | — |
| Shield Bash | Precision | 80% | +5 | 2t | 50% Stun |
| **Shield Wall** | **Special** | — | — | **4t** | *See Section 14* |

---

#### Stone Giant
HP: 220 | ATK: 90 | DEF: 150 | Range: 1 (Melee) | Speed: 1
Damage type: Physical | Strong: Wastes | Weak: Swamp
Knockback immune.

| Move | Type | Power | Accuracy | Cooldown | Effect |
|------|------|-------|----------|----------|--------|
| Fist Strike | Standard | 100% | ±0 | — | — |
| Boulder Hurl | Power | 150% | −3 | 3t | — |
| Tremor | Precision | 80% | +5 | 2t | 60% Root |
| **Ground Slam** | **Special** | 90% | ±0 | **4t** | *See Section 14* |

---

#### Four-Headed Hydra
HP: 200 | ATK: 120 | DEF: 120 | Range: 1 (Melee) | Speed: 1
Damage type: Nature | Strong: Swamp | Weak: Forest
Knockback immune.

| Move | Type | Power | Accuracy | Cooldown | Effect |
|------|------|-------|----------|----------|--------|
| Venomous Bite | Standard | 100% | ±0 | — | 30% Poison |
| Acid Spray | Power | 150% | −3 | 3t | 80% Poison |
| Regenerate | Precision (Self) | — | — | 2t | Heal 25% max HP |
| **Frenzy Strike** | **Special** | 45%×4 | ±0 | **4t** | *See Section 14* |

---

### Air / Hybrid Role (pick 1)

#### Dark Blood Dragon
HP: 140 | ATK: 110 | DEF: 70 | Range: 2 (Air) | Speed: 4
Damage type: Fire | Strong: Wastes | Weak: Swamp
Air unit. Knockback immune.

| Move | Type | Power | Accuracy | Cooldown | Effect |
|------|------|-------|----------|----------|--------|
| Dragon Claw | Standard | 100% | ±0 | — | — |
| Fire Breath | Power | 150% (AoE) | −1 | 3t | 60% Burn |
| Dark Pulse | Precision | 80% | +5 | 2t | 40% Terrify |
| **Inferno** | **Special** | 70% (AoE) | ±0 | **4t** | *See Section 14* |

---

#### Sky Serpent
HP: 100 | ATK: 85 | DEF: 60 | Range: 2 (Air) | Speed: 5
Damage type: Physical | Strong: Peaks | Weak: Ashlands
Air unit.

| Move | Type | Power | Accuracy | Cooldown | Effect |
|------|------|-------|----------|----------|--------|
| Serpent Strike | Standard | 100% | ±0 | — | — |
| Gale Slash | Power | 150% | −3 | 3t | 40% Slow |
| Storm Sense | Precision | 80% | +5 | 2t | — |
| **Storm Dive** | **Special** | 100% | +4 | **4t** | *See Section 14* |

---

#### Frost Valkyrie
HP: 120 | ATK: 95 | DEF: 85 | Range: 2 (Hybrid) | Speed: 4
Damage type: Ice | Strong: Peaks | Weak: Wastes
Hybrid — treated as ground unit for targeting. Immune: Slowed. Anti-Air capable.

| Move | Type | Power | Accuracy | Cooldown | Effect |
|------|------|-------|----------|----------|--------|
| Valkyrie Blade | Standard | 100% | ±0 | — | — |
| Charging Strike | Power | 150% | −3 | 3t | 30% Stun |
| Frost Bolt | Precision | 80% | +5 | 2t | 70% Slow |
| **Ice Lance** | **Special** | 85% (Line) | ±0 | **4t** | *See Section 14* |

---

### Ranged / Magic Role (pick 1)

#### Dark Magic Wizard
HP: 75 | ATK: 100 | DEF: 50 | Range: 3 (Magic) | Speed: 2
Damage type: Dark | Strong: Forest | Weak: Plains
Magic: DEF−20 reduction (flat). Can attack air units.

| Move | Type | Power | Accuracy | Cooldown | Effect |
|------|------|-------|----------|----------|--------|
| Dark Bolt | Standard | 100% | ±0 | — | — |
| Shadow Blast | Power | 150% | −3 | 3t | — |
| Life Drain | Precision | 80% | +5 | 2t | Heals caster 50% dmg |
| **Soul Rip** | **Special** | 90% | ±0 | **4t** | *See Section 14* |

---

#### Demon of Darkness
HP: 110 | ATK: 120 | DEF: 90 | Range: 2 (Magic) | Speed: 2
Damage type: Dark | Strong: Ashlands | Weak: Plains
Magic: DEF−20 reduction (flat). Can attack air units.

| Move | Type | Power | Accuracy | Cooldown | Effect |
|------|------|-------|----------|----------|--------|
| Demon Strike | Standard | 100% | ±0 | — | — |
| Hellfire | Power | 150% (AoE) | −3 | 3t | 30% Burn splash |
| Terrify | Precision | 80% | +5 | 2t | 100% Terrify |
| **Hellfire Surge** | **Special** | 100% + 60% AoE | ±0 | **4t** | *See Section 14* |

---

#### Elven Archer
HP: 80 | ATK: 90 | DEF: 55 | Range: 3 (Ranged) | Speed: 3
Damage type: Physical | Strong: Forest | Weak: Wastes
Anti-Air 2×: deals double damage to air units. Can attack air units.

| Move | Type | Power | Accuracy | Cooldown | Effect |
|------|------|-------|----------|----------|--------|
| Arrow Shot | Standard | 100% | ±0 | — | — |
| Arrow Volley | Power | 150% | −3 | 3t | — |
| Poison Arrow | Precision | 80% | +5 | 2t | 60% Poison |
| **Pinning Shot** | **Special** | 70% | +3 | **4t** | *See Section 14* |

---

### Flex / Support / Assassin Role (pick 1)

#### Celestial Cleric
HP: 110 | ATK: 55 | DEF: 100 | Range: 2 (Support) | Speed: 2
Damage type: Holy | Strong: Plains | Weak: Ashlands
Magic: DEF−20 reduction (flat). Immune: Cursed.

| Move | Type | Power | Accuracy | Cooldown | Effect |
|------|------|-------|----------|----------|--------|
| Holy Smite | Standard | 100% | ±0 | — | — |
| Heal Ally | Special (Self) | — | — | 2t | Restore 35 HP to ally in range |
| Purifying Light | Precision | 80% | +5 | 2t | Cleanses all debuffs on target |
| **Divine Surge** | **Special** | — | — | **6t** | *See Section 14* |

---

#### Shadow Assassin
HP: 70 | ATK: 115 | DEF: 45 | Range: 1 (Melee) | Speed: 5
Damage type: Physical | Strong: Swamp | Weak: Peaks
Starts every match with **Stealth** active (3 turns).

| Move | Type | Power | Accuracy | Cooldown | Effect |
|------|------|-------|----------|----------|--------|
| Stab | Standard | 100% | ±0 | — | — |
| **Backstab** | **Special** | *See Section 14* | — | **4t** | *See Section 14* |
| Vanish | Precision (Self) | — | — | 2t | Gain Stealth for 3 turns |
| Poison Blade | Power | 150% | −3 | 3t | 70% Poison |

---

#### Infernal Soul
HP: 60 | ATK: 85 | DEF: 40 | Range: 1 (Melee) | Speed: 5
Damage type: Fire | Strong: Ashlands | Weak: Peaks
Immune: Burned. **Death Burst passive**: deals 30 damage to all adjacent units on death.

| Move | Type | Power | Accuracy | Cooldown | Effect |
|------|------|-------|----------|----------|--------|
| Infernal Slash | Standard | 100% | ±0 | — | — |
| Immolate | Power | 150% | −3 | 3t | 80% Burn |
| Dark Pact | Precision | 80% | +5 | 2t | 50% Curse |
| **Soul Leech** | **Special** | 80% | ±0 | **4t** | *See Section 14* |

---

## 14. Signature Specials

All Specials share a **4-turn cooldown** unless noted otherwise. Each is unique — no two troops share a Special.

---

### Ground Tank

#### Medieval Knight — Shield Wall
The Knight plants their shield and creates a fortified zone until their next turn. **All adjacent friendly troops gain +25 DEF** (added to their DC for any incoming attack). Any enemy that attacks an adjacent protected ally while Shield Wall is active **triggers a free Knight counter-attack at 50% ATK** — no roll required, but the Knight must be alive and unaffected by Stun. Does not cost the Knight's movement. Targets self (no attack roll).

#### Stone Giant — Ground Slam
The Giant slams the earth. Deals **90% ATK Physical damage** to every unit on all **6 adjacent hexes simultaneously**, friendly or enemy. Each target makes a **separate defense roll**. Every target that takes damage is **knocked back 1 hex** directly away from the Giant. Giant, Hydra, and Dragon are immune to this knockback but still take damage. If a knockback destination is occupied or out of bounds, knockback is blocked (no fall damage from Ground Slam).

#### Four-Headed Hydra — Frenzy Strike
All four heads attack simultaneously. Makes **4 separate attack rolls** against a single target, each dealing **45% ATK** independently. Each roll can crit or miss on its own. On **3 or more hits**, the target is **Stunned for 1 turn**.

---

### Air / Hybrid

#### Dark Blood Dragon — Inferno
Breathes a massive fire cone. Deals **70% ATK Fire damage** to the **target hex and all 6 adjacent hexes**. Each unit in the radius makes a **separate defense roll**. **40% chance to Burn** each target hit. Friendly troops in radius take **half damage** (35% ATK). The Dragon never discriminates.

#### Sky Serpent — Storm Dive
Vanishes into storm clouds and **teleports to any empty hex within 5 hexes**, then immediately strikes the selected target. The teleport cannot be interrupted or countered. The attack receives **+4 to the roll**. On a critical hit, the target is **Slowed for 2 turns**.

#### Frost Valkyrie — Ice Lance
Hurls an ice lance that **pierces in a straight line up to 4 hexes**, chosen by the Valkyrie after selecting the move. Hits every unit in its path (friendly fire included). Each target takes **85% ATK Ice damage** and is **Rooted for 2 turns**. Each target makes a separate defense roll.

---

### Ranged / Magic

#### Dark Magic Wizard — Soul Rip
Deals **90% ATK Dark damage**. Ignores an additional **50% DEF** on top of the standard magic DEF reduction (i.e., the DEF/2 term is reduced by 50 instead of 20, minimum 0). **Heals the Wizard for 100% of damage dealt**. On kill, the Wizard gains **Stealth for 1 turn** immediately.

#### Demon of Darkness — Hellfire Surge
Deals **100% ATK Dark magic** to the primary target and applies **Terrified (−25% DEF, 2 turns)**. Every unit adjacent to the primary target takes **60% ATK Dark damage** with a **30% chance to Burn**. Friendly fire included on splash. Primary target and adjacents each make separate defense rolls.

#### Elven Archer — Pinning Shot
A precision shot dealing **70% ATK Physical damage** with **+3 accuracy**. On any hit (crit or not), applies **Rooted for 3 turns** — the longest root in the game. Can target **air units at full effectiveness**. Works at full Range 3.

---

### Flex / Support / Assassin

#### Celestial Cleric — Divine Surge *(6-turn cooldown)*
Simultaneously heals **every friendly troop within Range 2** (including self) for **25 HP** and **cleanses all status effects** from each healed troop. Healing and cleansing trigger even if the Cleric has 0 available attacks. Does not require an attack roll.

#### Shadow Assassin — Backstab
- **If in Stealth:** Deals **3× ATK Physical damage**. Attack is an **automatic critical hit** and **cannot miss**. Also applies **Cursed (−25% ATK, 3 turns)**. Stealth ends after use.
- **If not in Stealth:** Functions as a Power move — **150% ATK**, −3 accuracy, no guaranteed crit.

> The Assassin's starting Stealth is specifically designed to enable a turn-one Backstab. High risk, high reward — the Assassin has 70 HP and DEF 45. A failed approach or counter means death.

#### Infernal Soul — Soul Leech
Deals **80% ATK Fire damage** to the target. **Heals the Infernal Soul for 100% of damage dealt.** Given the Soul's 60 base HP, a full-power Soul Leech against a mid-DEF target can nearly double its remaining health pool.

> **Death Burst** (Passive, always active): When the Infernal Soul dies by any means — combat, status DoT, friendly fire — it deals **30 damage** to every unit on all adjacent hexes. No roll. Friendly fire included.

---

## 15. General Rules

- Each troop gets **one action per turn — Move OR Attack, not both**.
- Movement is always free of resource cost (no gold or XP to move).
- Air units can attack all ground units; only Ranged, Magic, and the Frost Valkyrie can attack air units.
- Frost Valkyrie is treated as a ground unit for all targeting purposes.
- No terrain blocks LOS; units do not block LOS.
- Range is counted from the attacking troop's hex.
- A troop cannot attack a target that has already died this turn (resolve in order if multiple things happen simultaneously).
- NPCs (Goblin, Orc, Troll) fight using simplified AI and do not use the stance/move selection system.

---

## 16. Simplified Combat Mode

For new players. Enabled per-match in Custom Match settings.

| Setting | Normal | Simplified |
|---------|--------|------------|
| Move options | 4 | 2 (Standard + Special) |
| Damage types | 6 | 3 (Physical, Magic, Elemental) |
| Defender stance | Player choice | Auto-Brace |
| Selection timer | 10 seconds | 15 seconds |
| Crit/Miss display | Roll numbers | Emoji feedback only |
| Type labels | None shown | STRONG / WEAK / NEUTRAL |
| Biome labels | None shown | BOOSTED / WEAKENED |

---

*End of document.*
