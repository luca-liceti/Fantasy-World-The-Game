# 🎮 Fantasy World - Complete Master Development Plan

> **Last Updated:** January 29, 2026  
> **Project Status:** Combat System Complete ✅ | Full Game Pending 🔴 | Assets Partial 🟡

---

## 📚 Table of Contents

### Part 1: Project Overview
1. [Executive Summary](#executive-summary)
2. [Current Status Dashboard](#current-status-dashboard)
3. [Project Structure](#project-structure)

### Part 2: Core Game Systems (17 Phases)
4. [Phase 1-5: Foundation Systems](#phase-1-5-foundation-systems)
5. [Phase 6: Combat System](#phase-6-combat-system)
6. [Phase 7-13: Economy & Gameplay](#phase-7-13-economy--gameplay)
7. [Phase 14-17: Polish & Network](#phase-14-17-polish--network)

### Part 3: Visual Assets & Art Pipeline
8. [Asset Integration Overview](#asset-integration-overview)
9. [Biome Textures (Phase 1 NOW)](#biome-textures-phase-1-now)
10. [Character Models & Animations](#character-models--animations)
11. [UI Assets & Effects](#ui-assets--effects)
12. [Quality Settings System](#quality-settings-system)

### Part 4: Combat UX & Accessibility
13. [Combat New Player Experience](#combat-new-player-experience)
14. [Tutorial System](#tutorial-system)
15. [Simple Combat Mode](#simple-combat-mode)
16. [UI/UX Improvements](#uiux-improvements)

### Part 5: Reference Documentation
17. [Combat Guide (Player-Facing)](#combat-guide-player-facing)
18. [Troop Balance Reference](#troop-balance-reference)
19. [Complete Game Rules](#complete-game-rules)

### Part 6: Implementation Checklists
20. [Master TODO List](#master-todo-list)
21. [Asset Acquisition Checklist](#asset-acquisition-checklist)
22. [Progress Tracking](#progress-tracking)

---

# Part 1: Project Overview

## Executive Summary

**Fantasy World** is a 1v1 networked turn-based strategy board game built in Godot 4.5 featuring:

- **397-hex procedural board** with 7 biomes
- **12 unique troops** with D&D × Pokémon hybrid combat
- **Resource economy** (gold mines, XP, upgrades)
- **3D presentation** with realistic fantasy aesthetic (Manor Lords inspired)
- **Networked multiplayer** via ENet
- **Accessibility features** (Simple Mode, tutorials)

**Core Gameplay Loop:**
1. Select 4-card deck (1 Tank, 1 Air, 1 Ranged, 1 Flex)
2. Deploy troops on hex board
3. Move, attack, place mines, upgrade troops
4. Defeat all enemy troops to win

---

## Current Status Dashboard

### Development Progress

| System | Status | Progress | Notes |
|--------|--------|----------|-------|
| **Combat Core** | ✅ Complete | 191/191 tasks | D&D × Pokémon hybrid implemented |
| **Combat UX** | 🟡 Partial | Phase 2/7 | Simple Mode done, tutorials pending |
| **Board System** | ✅ Complete | 100% | 397 hexes, procedural biomes |
| **Turn System** | ✅ Complete | 100% | Multi-action, timer, network sync |
| **Gold/XP Economy** | ✅ Complete | 100% | Mines, upgrades, inventory |
| **NPC System** | ✅ Complete | 100% | Spawning, loot, combat |
| **Networking** | ✅ Complete | 100% | ENet multiplayer, RPC sync |
| **Visual Assets** | 🟡 Partial | 20/328 tasks | Partial 🟡, Models needed 🔴 |
| **UI Polish** | 🔴 Pending | 0% | Animations, effects, feedback |
| **Audio** | 🔴 Not Started | 0% | End of MVP |

### Asset Status

| Asset Category | Status | Details |
|----------------|--------|---------|
| **Terrain Textures** | 🔴 Needed | ~8.6GB downloaded (Poly Haven + AmbientCG) |
| **Board Textures** | 🔴 Needed | Wood, stone, metal for frame/table |
| **HDRI Lighting** | 🔴 Needed | `evening_road_01_4k.exr` |
| **Troop 3D Models** | 🔴 Needed | 12 troops (AI generation prompts ready) |
| **Card Illustrations** | 🔴 Needed | 12 card arts (AI prompts ready) |
| **Particle Effects** | 🔴 Needed | Fire, magic, impacts |
| **Animations** | 🔴 Needed | Attack, damage, death (per troop) |
| **Audio** | 🔴 Not Started | SFX, music (end of MVP) |

---

## Project Structure

```
fantasy-world-game/
├── scenes/
│   ├── main.tscn (main game scene)
│   ├── board/
│   │   ├── hex_board.tscn
│   │   ├── hex_tile.tscn
│   │   └── biome_manager.tscn
│   ├── gameplay/
│   │   ├── game_manager.tscn
│   │   ├── turn_manager.tscn
│   │   ├── player_manager.tscn
│   │   └── combat_manager.tscn
│   ├── ui/
│   │   ├── game_ui.tscn
│   │   ├── card_ui.tscn
│   │   ├── dice_ui.tscn
│   │   ├── combat_selection_ui.tscn
│   │   ├── combat_resolution_ui.tscn
│   │   └── gold_ui.tscn
│   └── entities/
│       ├── troop.tscn
│       ├── gold_mine.tscn
│       ├── npc.tscn
│       └── card.tscn
├── scripts/
│   ├── board/
│   │   ├── hex_board.gd
│   │   ├── hex_tile.gd
│   │   ├── hex_coordinates.gd
│   │   ├── biome_manager.gd
│   │   └── biome_generator.gd
│   ├── gameplay/
│   │   ├── game_manager.gd
│   │   ├── turn_manager.gd
│   │   ├── player.gd
│   │   ├── player_manager.gd
│   │   └── combat_manager.gd
│   ├── ui/
│   │   ├── game_ui.gd
│   │   ├── card_ui.gd
│   │   ├── dice_ui.gd
│   │   ├── combat_selection_ui.gd
│   │   ├── combat_resolution_ui.gd
│   │   └── gold_ui.gd
│   ├── entities/
│   │   ├── troop.gd
│   │   ├── gold_mine.gd
│   │   ├── npc.gd
│   │   └── card.gd
│   └── network/
│       ├── network_manager.gd
│       └── lobby_manager.gd
├── data/
│   ├── biomes.gd
│   ├── card_data.gd
│   ├── game_config.gd
│   ├── combat_balance_config.gd
│   └── move_definitions.gd
└── assets/
    ├── models/
    │   ├── troops/ (12 troop models needed)
    │   ├── buildings/ (gold mines)
    │   └── board/ (hex_base.glb)
    ├── textures/
    │   ├── biomes/ ✅ (all 7 biomes downloaded)
    │   ├── board/ ✅ (table, frame)
    │   └── ui/ ✅ (wood, stone, metal)
    ├── hdri/ ✅
    │   └── evening_road_01_4k.exr
    ├── shaders/
    │   └── team_color_shader.gdshader ✅
    ├── particles/ (fire, magic, impacts - needed)
    ├── animations/ (per troop - needed)
    └── audio/ (SFX, music - end of MVP)
```

---

# Part 2: Core Game Systems

## Phase 1-5: Foundation Systems

### Phase 1: Hexagonal Board (✅ COMPLETE)

**Hex Board System (`scripts/board/hex_board.gd`)**
- [x] Generate 397 hexagons in hexagonal pattern (12 hexagons per side)
- [x] Implement axial/cube coordinate system for hex math
- [x] Calculate neighbor relationships between hexes
- [x] Handle hex selection and highlighting
- [x] Store hex data (coordinates, biome, occupants)

**Hex Tile (`scenes/board/hex_tile.tscn` + `scripts/board/hex_tile.gd`)**
- [x] Visual representation of a single hex
- [x] Display biome visuals
- [x] Handle mouse input for selection
- [x] Show/hide highlights for movement/attack ranges

**Hex Coordinates (`scripts/board/hex_coordinates.gd`)**
- [x] Utility class for hex coordinate math (axial/cube)
- [x] Distance calculation between hexes
- [x] Pathfinding algorithms (A* for hex grids)
- [x] Coordinate conversion (pixel to hex, hex to pixel)

---

### Phase 2: Biome System (✅ COMPLETE)

**7 Biome Types:**
1. **Enchanted Forest** - Deep greens, magical atmosphere
2. **Frozen Peaks** - Snowy mountains, icy terrain
3. **Desolate Wastes** - Barren desert, dry cracked earth
4. **Golden Plains** - Grassy fields, golden wheat
5. **Ashlands** - Volcanic ash, charred ground
6. **Highlands (Rolling Hills)** - Green hills, rocky outcrops
7. **Swamplands** - Murky swamps, mossy ground

**Biome Manager (`scripts/board/biome_manager.gd`)**
- [x] Define 7 biome types with unique properties
- [x] Procedural board generation (new layout each game)
- [x] Biome placement algorithm (ensure all 7 biomes present)
- [x] Harmonious biome flow (natural transitions and clustering)
- [x] Biome strength/weakness system (troops gain bonuses/penalties)

**Biome Distribution:**
- 20% Plains
- 15% Forest
- 15% Hills
- 12% Swamp
- 12% Ashlands
- 10% Peaks
- 10% Wastes
- 6% special biomes

**Biome Modifiers:**
- **+A (Advantage)**: +25% damage dealt
- **+S (Strength)**: +15% damage dealt
- **+D (Defense)**: -15% incoming damage
- **-S (Weakness)**: -25% damage dealt

---

### Phase 3: Player & Turn System (✅ COMPLETE)

**Player (`scripts/gameplay/player.gd`)**
- [x] Player data (ID, name, team color)
- [x] Gold amount (starting: 150)
- [x] XP amount (starting: 0)
- [x] Selected cards (4 cards per player)
- [x] Mana cost tracking (deck total ≤ 22 mana)
- [x] Troops on board
- [x] Gold mines owned

**Turn Manager (`scripts/gameplay/turn_manager.gd`)**
- [x] Track current turn and phase
- [x] Handle turn order (initial dice roll)
- [x] Multiple actions per turn (one action per troop)
- [x] 60-120 second turn timer (configurable)
- [x] Action queue (move, attack, place mine, upgrade)
- [x] End turn functionality

**Turn Structure:**
- Each troop can perform ONE action per turn (Move OR Attack OR Place Mine OR Upgrade)
- Turn passes when player ends turn manually or timer expires
- Timer pauses during combat animations and UI interactions

---

### Phase 4: Card & Troop System (✅ COMPLETE)

**12 Troop Types with Deck-Building Restrictions:**

**Ground Tank (pick 1):**
1. **Medieval Knight** - 150 HP, 80 ATK, 130 DEF, Range 1, Speed 2, Mana 5
2. **Stone Giant** - 220 HP, 90 ATK, 150 DEF, Range 1, Speed 1, Mana 8
3. **Four-Headed Hydra** - 200 HP, 120 ATK, 120 DEF, Range 1, Speed 1, Mana 9 (Multi-Strike)

**Air/Hybrid (pick 1):**
4. **Dark Blood Dragon** - 140 HP, 110 ATK, 70 DEF, Range 2 Air, Speed 4, Mana 8
5. **Sky Serpent** - 100 HP, 85 ATK, 60 DEF, Range 2 Air, Speed 5, Mana 5
6. **Frost Valkyrie** - 120 HP, 95 ATK, 85 DEF, Range 2 Hybrid, Speed 4, Mana 6 (Anti-Air)

**Ranged/Magic (pick 1):**
7. **Dark Magic Wizard** - 75 HP, 100 ATK, 50 DEF, Range 3 Magic, Speed 2, Mana 4 (Ignores 25% DEF)
8. **Demon of Darkness** - 130 HP, 120 ATK, 90 DEF, Range 2 Magic, Speed 2, Mana 7 (Ignores 25% DEF)
9. **Elven Archer** - 80 HP, 90 ATK, 55 DEF, Range 3 Ranged, Speed 3, Mana 4 (Anti-Air 2x)

**Flex - Support/Assassin (pick 1):**
10. **Celestial Cleric** - 110 HP, 55 ATK, 100 DEF, Range 2 Support, Speed 2, Mana 5 (Heal 35 HP)
11. **Shadow Assassin** - 70 HP, 115 ATK, 45 DEF, Range 1, Speed 5, Mana 4 (Glass cannon)
12. **Infernal Soul** - 60 HP, 85 ATK, 40 DEF, Range 1, Speed 5, Mana 3 (Death Burst 30 dmg)

**Deck Selection Rules:**
- 1 Ground Tank + 1 Air/Hybrid + 1 Ranged/Magic + 1 Flex
- Total mana ≤ 22
- Simultaneous selection (30-second timer)
- Duplicates allowed (both players can pick same card)

---

### Phase 5: Movement System (✅ COMPLETE)

**Movement (`scripts/board/hex_board.gd` + `game_manager.gd`)**
- [x] Calculate valid movement hexes (based on troop Speed stat)
- [x] Pathfinding between hexes (hex-based A*)
- [x] Move troop action
- [x] Validate movement (occupied hex check, range check)
- [x] No biome movement modifiers (all terrain = same speed)
- [x] Animate troop movement

**Range Calculation:**
- Range counts hex distance (hexagonal distance)
- Range 1 = adjacent hex only
- Range 2 = up to 2 hexes away
- Range 3 = up to 3 hexes away

**Line of Sight:**
- Bresenham line algorithm from attacker to target
- **No biome LOS blocking** - all terrain transparent
- Units do NOT block LOS
- Simplified rules, focus on positioning

---

## Phase 6: Combat System

### 🆕 Enhanced Combat System (D&D × Pokémon Hybrid) - ✅ COMPLETE

**Design Philosophy:**
- D&D-style advantage/disadvantage + Pokémon type effectiveness
- Simultaneous move/stance selection
- 4-6 hit time-to-kill (extended battles)
- No direction-based mechanics (no backstab, no facing)
- Predictable damage (fixed formula, no damage dice)

**Combat Flow:**

```
┌─────────────────────────────────────────────────┐
│         COMBAT INITIATION                       │
│  Attacker selects target in range               │
└─────────────────┬───────────────────────────────┘
                  ▼
┌─────────────────────────────────────────────────┐
│  PHASE 1: SIMULTANEOUS SELECTION (10 seconds)   │
│  • Attacker: Choose 1 of 4 Moves                │
│  • Defender: Choose Defensive Stance            │
└─────────────────┬───────────────────────────────┘
                  ▼
┌─────────────────────────────────────────────────┐
│         PHASE 2: ROLL RESOLUTION                │
│  • Check Advantage/Disadvantage sources         │
│  • Roll d20 (or 2d20 if Adv/Dis)               │
│  • Add modifiers, compare vs DC                 │
│  • Determine: Hit / Miss / Crit / Crit Miss     │
└─────────────────┬───────────────────────────────┘
                  ▼
┌─────────────────────────────────────────────────┐
│       PHASE 3: DAMAGE CALCULATION               │
│  • Base Damage = ATK × Move Power%              │
│  • Apply type effectiveness (×1.5/×1.0/×0.5)   │
│  • Apply defense reduction                      │
│  • Apply critical multiplier if crit (×1.5)     │
└─────────────────┬───────────────────────────────┘
                  ▼
┌─────────────────────────────────────────────────┐
│       PHASE 4: CONDITIONAL REACTIONS            │
│  • Check defender's reaction triggers           │
│  • Apply automatic reactions                    │
│  • Resolve final damage and effects             │
└─────────────────────────────────────────────────┘
```

---

### Move System (4 Moves Per Troop)

**Move Categories:**

| Type | Power | Accuracy | Cooldown | Best For |
|------|-------|----------|----------|----------|
| **Standard** | 100% | +0 | None | Reliable damage every turn |
| **Power** | 150% | -3 | 3 turns | Big damage, risky accuracy |
| **Precision** | 80% | +5 | 2 turns | Guaranteed hits on tough targets |
| **Special** | 120% | +0 | 4 turns | Effects + good damage |

**Move Cooldowns:**
- Track cooldowns per move (1-4 turns typically)
- Cooldowns tick down at start of troop's controller's turn
- Standard moves have no cooldown (always available)

---

### Dice Rolling System (D&D-Style)

**Attack Roll Formula:**
```
ATTACK ROLL = d20 + (ATK ÷ 10) + Move Accuracy Modifier + Position Bonuses
TARGET DC = 10 + (DEF ÷ 10) + Stance Bonus + Position Bonuses
HIT CONDITION: ATTACK ROLL ≥ TARGET DC
```

**Advantage & Disadvantage:**
- **Normal**: Roll 1d20
- **Advantage**: Roll 2d20, take higher
- **Disadvantage**: Roll 2d20, take lower
- Rule: Advantage and Disadvantage cancel each other

**Advantage Sources (+5 each):**
1. **Flanking**: Allied troop adjacent to target
2. **High Ground**: Attacker on Hills/Peaks biome
3. **Stealth**: Attacker is invisible/hidden
4. **Target Stunned**: Target has Stunned status
5. **Target Surrounded**: 3+ enemies adjacent to target

**Disadvantage Sources (-5 each):**
1. **Cover**: Target on Forest/Ruins hex
2. **Attacker Slowed**: Attacker has Slowed status
3. **Attacker Cursed**: Attacker has Cursed status
4. **Long Range**: Ranged attack at maximum range
5. **Target Evasion**: Target has active evasion buff

**Critical Hits/Misses:**
- **Natural 1** (Critical Miss): Attack automatically fails, attacker loses next reaction
- **Natural 2-17**: Normal roll - apply modifiers and compare to DC
- **Natural 18-20** (Critical Hit): Auto-hit, ×1.5 damage, bypass reactions

---

### Damage Calculation

**Damage Formula:**
```
BASE DAMAGE = ATK × Move Power%
TYPE DAMAGE = BASE DAMAGE × Type Effectiveness Multiplier
DEFENSE REDUCTION = TYPE DAMAGE ÷ (1 + DEF / 80)
FINAL DAMAGE = max(DEFENSE REDUCTION, 1)
CRITICAL DAMAGE = FINAL DAMAGE × 1.5
```

**Type Effectiveness Multipliers:**
- **Super Effective**: 1.5× damage
- **Neutral**: 1.0× damage
- **Not Very Effective**: 0.5× damage
- **Immune**: 0× damage

---

### Type Effectiveness System (6 Damage Types)

| Type | Icon | Strong Against | Weak Against |
|------|------|----------------|--------------|
| **Physical** | ⚔️ | Mage, Archer | Tank, Giant |
| **Fire** | 🔥 | Ice, Nature | Dragon, Demon |
| **Ice** | ❄️ | Dragon, Serpent | Fire, Giant |
| **Dark** | 🌑 | Cleric, Valkyrie | Assassin, Soul |
| **Holy** | ✨ | Demon, Soul, Assassin | None |
| **Nature** | 🌿 | Giant, Knight | Fire, Dragon |

**Troop Type Assignments:**
- **Medieval Knight**: Physical damage, resists Physical, weak to Fire/Dark
- **Stone Giant**: Physical damage, resists Physical/Ice, weak to Nature
- **Four-Headed Hydra**: Nature damage, resists Nature, weak to Ice/Fire
- **Dark Blood Dragon**: Fire damage, resists Fire, weak to Ice
- **Sky Serpent**: Ice damage, resists Ice/Nature, weak to Fire
- **Frost Valkyrie**: Ice damage, resists Ice, weak to Fire/Dark
- **Dark Magic Wizard**: Dark damage, resists Dark, weak to Holy
- **Demon of Darkness**: Dark/Fire damage, resists Dark/Fire, weak to Holy
- **Elven Archer**: Physical/Nature damage, resists Nature, weak to Dark/Fire
- **Celestial Cleric**: Holy damage, resists Holy/Dark, no weakness
- **Shadow Assassin**: Dark damage, resists Dark, weak to Holy
- **Infernal Soul**: Fire damage, resists Fire, weak to Ice/Holy

---

### Defensive Stances

| Stance | Bonus | Effect | Best For |
|--------|-------|--------|----------|
| **Brace** 🛡️ | +3 DEF | Take 20% less damage if hit | Tanking hits when you expect to get hit |
| **Dodge** ⚡ | +5 Evasion | No damage reduction if hit | Against low-accuracy Power moves |
| **Counter** ↩️ | No bonus | If enemy misses, deal 50% ATK back | Against precision attacks you think will miss |
| **Endure** 💪 | No bonus | If damage would kill you, survive at 1 HP (once per combat) | Clutch survival when you'd die |

---

### Status Effects

| Effect | Icon | Duration | Effect |
|--------|------|----------|--------|
| **Stunned** | ⚡ | 1 turn | Can't act! Auto-Brace if attacked |
| **Burned** | 🔥 | 3 turns | Take 20 damage per turn, -10% ATK |
| **Poisoned** | ☠️ | 3 turns | Take 15 damage per turn |
| **Slowed** | 🐢 | 2 turns | -1 to -2 Speed, Disadvantage on attacks |
| **Cursed** | 💀 | 2 turns | Take +30% damage from all sources |
| **Terrified** | 😱 | 2 turns | -25% ATK |
| **Rooted** | 🌿 | 2 turns | Can't move (can still attack) |
| **Stealth** | 👻 | 1 turn | Cannot be targeted, attacking/moving ends it |

**Immunities:**
- **Tanks** (Knight, Giant, Hydra): Immune to Terrified
- **Undead/Demon** (Demon, Soul): Immune to Poisoned
- **Air Units** (Dragon, Serpent, Valkyrie): Immune to Rooted

---

### Stat Stages (Pokémon-Style Buffs/Debuffs)

Buffs and debuffs stack in **stages** from -6 to +6.

| Stage | Multiplier |
|-------|------------|
| +6 | 4.00× |
| +3 | 2.50× |
| +2 | 2.00× |
| +1 | 1.50× |
| 0 | 1.00× |
| -1 | 0.67× |
| -2 | 0.50× |
| -3 | 0.40× |
| -6 | 0.25× |

**Stacking Rules:**
- Multiple sources stack (e.g., two -1 ATK = -2 ATK stage)
- Stages cap at +6 and -6
- Stages reset when troop dies and is revived

---

### Positioning Bonuses

| Condition | Bonus | How to Achieve |
|-----------|-------|----------------|
| **Flanking** | Advantage on attack | Allied troop adjacent to defender |
| **High Ground** | Advantage + 10% damage | Attacking from Hills/Peaks biome |
| **Surrounded** | Advantage on all attacks | 3+ enemies adjacent to defender |
| **Cover** | Disadvantage for attacker | Defender on Forest/Ruins hex |

**Note:** No direction-based bonuses (backstab removed for simplicity)

---

### Conditional Reactions (Automatic)

Each troop has one primary reaction that triggers automatically:

| Troop | Reaction | Trigger | Effect |
|-------|----------|---------|--------|
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

**Reaction Rules:**
- Reactions are automatic (no player input required)
- Reactions trigger after damage calculated, before applied
- Critical Hits bypass reactions

---

### Lethality Adjustments

To ensure longer, more strategic battles:

| Adjustment | Value |
|------------|-------|
| **HP Scaling** | All troop HP increased by 30% |
| **Move Power** | All move power reduced by 15% |
| **Critical Multiplier** | 1.5× (reduced from 2×) |
| **Execute Threshold** | Bonus damage, not instant kill |
| **Defense Formula** | Divisor-based (never reduces to 0) |

**Target Time-to-Kill:**
- Glass cannon vs Glass cannon: 3-4 hits
- Balanced vs Balanced: 4-5 hits
- Tank vs Tank: 6-8 hits
- Glass cannon vs Tank: 5-6 hits
- With healing/support: 8+ hits

---

## Phase 7-13: Economy & Gameplay

### Phase 7-8: Gold System (✅ COMPLETE)

**Gold Manager**
- [x] Track player gold amounts
- [x] Gold UI display (starting: 150 gold)
- [x] Gold transactions (spending, earning)

**Gold Mine System:**
- [x] Mine placement on hex (max 5 per player, 100 gold cost)
- [x] Mine ownership tracking
- [x] Turn-based gold generation (at start of each player's turn)
- [x] Mine upgrade levels (1-5)
- [x] Minimum 3 hexes between mines
- [x] Cannot place on Peaks biome
- [x] Very low health (destroyed in one hit)

**Gold Generation Rates:**
- Level 1: 10 gold/turn
- Level 2: 25 gold/turn
- Level 3: 50 gold/turn
- Level 4: 100 gold/turn
- Level 5: 200 gold/turn

**Mine Upgrade Costs:**
- Level 1 mine: 100 gold (initial placement)
- Level 2 upgrade: 200 gold
- Level 3 upgrade: 400 gold
- Level 4 upgrade: 800 gold
- Level 5 upgrade: 1600 gold

---

### Phase 9: XP System (✅ COMPLETE)

**XP Manager**
- [x] Track player XP amounts (starting: 0 XP)
- [x] XP gained from killing enemy troops
- [x] XP gained from killing NPCs
- [x] XP UI display
- [x] XP transactions (spending, earning)

---

### Phase 10: NPC System (✅ COMPLETE)

**NPC Types and Loot:**

| NPC | HP | ATK | DEF | Gold | XP | Rare Drop |
|-----|-----|-----|-----|------|-----|-----------|
| **Goblin** | 50 | 30 | 20 | 5 | 10 | Speed Potion (10%) - +1 Speed for 3 turns |
| **Orc** | 100 | 60 | 40 | 15 | 25 | Whetstone (15%) - +10 ATK next attack |
| **Troll** | 200 | 80 | 60 | 30 | 50 | Phoenix Feather (20%) - Respawn 1 troop |

**NPC Spawning Rules:**
- [x] 5% spawn chance when ANY troop moves to a hex
- [x] NPCs cannot spawn on occupied hexes
- [x] No fog of war (all hexes visible)
- [x] NPCs do NOT move (stationary)
- [x] NPCs attack nearest player unit in range 2 each turn
- [x] Defeated NPCs do NOT respawn
- [x] NPCs do NOT attack each other

**Player Inventory:**
- [x] Max 3 consumable items
- [x] Using an item costs 1 action
- [x] Items cannot be traded or stolen

---

### Phase 11: Upgrade System (✅ COMPLETE)

**Upgrade Costs (per level):**
- Level 1 → 2: 50 gold + 25 XP
- Level 2 → 3: 100 gold + 50 XP
- Level 3 → 4: 200 gold + 100 XP
- Level 4 → 5: 400 gold + 200 XP

**Stat Increases per Level:**
- **+10% HP** (percentage-based, scales with unit)
- **+5 ATK** (flat increase)
- **+3 DEF** (flat increase)

**Upgrade Rules:**
- [x] Maximum level: 5
- [x] Can upgrade during your turn (uses action)
- [x] Upgrades cannot be undone
- [x] Upgrade UI (mines and troops)

---

### Phase 12: Game Manager (✅ COMPLETE)

**Game Manager (`scripts/gameplay/game_manager.gd`)**
- [x] Main game state machine
- [x] Initialize game (player setup, board generation)
- [x] Coordinate between systems
- [x] Handle game flow (start, play, end)
- [x] Win condition checking (defeat all enemy troops)
- [x] Game initialization (dice roll for starting player)

**Win/Loss Conditions:**
- **Win**: Defeat all enemy troops
- **Draw**: Equal dice rolls in combat (re-roll up to 3 times, then defender wins)
- **Tie**: Both players eliminated simultaneously OR both have 0 troops at turn end

---

### Phase 13: UI Systems (✅ COMPLETE)

**Main Game UI:**
- [x] Main game HUD
- [x] Player info display
- [x] Turn indicator
- [x] Action buttons (move, attack, place mine, upgrade, end turn)
- [x] Card hand display
- [x] Gold/XP display

**Combat UI:**
- [x] Combat selection interface (move picker, stance picker)
- [x] Combat resolution display (dice rolls, damage calculation)
- [x] Move tooltips (power, accuracy, cooldown)
- [x] Type effectiveness indicators

**Card UI:**
- [x] Display selected cards (4-card hand)
- [x] Card selection interface (pre-game, deck restrictions)
- [x] Card stats display
- [x] Deck validation UI
- [x] Mana cost display

---

## Phase 14-17: Polish & Network

### Phase 14: Networking (✅ COMPLETE)

**Network Manager (`scripts/network/network_manager.gd`)**
- [x] ENetMultiplayerPeer connections (Host/Join)
- [x] Player connection/disconnection events
- [x] Synchronize game state (seed, turn, board)
- [x] Remote Procedure Calls (RPCs) for actions
- [x] Latency and state reconciliation

**Lobby UI:**
- [x] Host game button
- [x] Join game input (IP address/code)
- [x] Player list (lobby)
- [x] Ready state toggle

**Disconnection Handling (Future Online Mode):**
- Player has **3 minutes** to reconnect after disconnection
- If no reconnect within 3 minutes: Automatic win for opponent
- After **3 total disconnections**: Automatic win for opponent
- Disconnection timer visible to both players
- Game state preserved during disconnection

---

### Phase 15: Biome Strength Effects (✅ COMPLETE)

**Biome-Troop Modifier Table:**

| Troop | Forest | Peaks | Wastes | Plains | Ashlands | Hills | Swamp |
|-------|--------|-------|--------|--------|----------|-------|-------|
| Medieval Knight | — | — | -S | +S | — | +D | — |
| Stone Giant | — | +A | — | — | +S | +D | -S |
| Four-Headed Hydra | — | -S | +S | — | +A | — | +S |
| Dark Blood Dragon | -S | — | +A | — | +S | — | — |
| Sky Serpent | +S | +A | — | +S | -S | — | — |
| Frost Valkyrie | — | +A | -S | — | -S | +S | — |
| Dark Magic Wizard | +A | — | +S | — | — | — | +S |
| Demon of Darkness | -S | — | +S | -S | +A | — | — |
| Elven Archer | +A | — | -S | +S | — | +S | -S |
| Celestial Cleric | +S | +S | -S | +D | -S | — | — |
| Shadow Assassin | +A | -S | — | — | +S | — | +S |
| Infernal Soul | -S | -S | — | — | +A | — | +S |

---

### Phase 16: Polish & Testing (🔴 PENDING)

**Remaining Tasks:**
- [ ] UI polish (animations, transitions)
- [ ] Error handling improvements
- [ ] Game flow testing (edge cases)
- [ ] Bug fixes
- [ ] Performance optimization
- [ ] Balance tuning

---

### Phase 17: 3D Presentation (🔴 PENDING)

**Camera System:**
- [ ] Default: Top-down at 45-degree angle
- [ ] Free rotate 3D with orbit controls
- [ ] Zoom levels: Close → Mid → Far
- [ ] Edge pan or WASD movement

**Cutscene System:**

| Event | Duration | Effect |
|-------|----------|--------|
| Commencing Battle | 3-5 sec | Zoom to attacker/defender, dice roll animation |
| NPC Encounter | 2-3 sec | NPC emerges from terrain, camera shake |
| Attack Landing | 1-2 sec | Slow-mo impact, damage numbers, screen flash |
| Troop Death | 2-3 sec | Collapse animation, particle effects, fade out |
| Victory/Defeat | 5-8 sec | Cinematic celebration/defeat sequence |

**Settings:**
- Cutscenes toggleable (ON/OFF)
- Speed options: Full / Fast (50%) / Instant Skip

**Card Presentation (3D Card Table):**
- Physical 3D cards on ornate wooden table
- Cards have depth, lighting, shadows
- Hover animations
- Click card → camera focuses on corresponding troop

---

# Part 3: Visual Assets & Art Pipeline

## Asset Integration Overview

**Visual Style:** Grounded High Fantasy (Manor Lords aesthetic + fantasy elements)
**Theme Standard:** Realistic medieval materials with prominent magical effects
**Target Hardware:** Scalable from work laptops to gaming PCs
**Total Hexes:** 397 (flat with optional subtle height variation)

---

## Biome Textures (Phase 1 NOW) - ✅ COMPLETE

### All Textures Downloaded (Dec 28-29, 2024)
- **Total:** ~220 texture files (~8.6 GB)
- **Format:** 4K PNG with 5 PBR maps (Diffuse, Normal, Roughness, AO, Displacement)
- **Location:** `res://assets/textures/biomes/`

### 1. Enchanted Forest ✅

| Role | Asset Name | Source | Local File Prefix |
|------|------------|--------|-------------------|
| Primary | `forest_leaves_02` | Poly Haven | `enchanted_forest_primary_*` |
| Secondary | `brown_mud_leaves_01` | Poly Haven | `enchanted_forest_secondary_*` |
| Prop 1 | `bark_brown_01` | Poly Haven | `enchanted_forest_prop1_*` |
| Prop 2 | `bark_willow` | Poly Haven | `enchanted_forest_prop2_*` |
| Prop 3 | `coast_sand_rocks_02` | Poly Haven | `enchanted_forest_prop3_*` |

**Color Grading:** Deep greens (#2D5016), brown earth (#3E2A1C)

### 2. Frozen Peaks ✅

| Role | Asset Name | Source | Local File Prefix |
|------|------------|--------|-------------------|
| Primary | `snow_02` | Poly Haven | `frozen_peaks_primary_*` |
| Secondary | `aerial_rocks_02` | Poly Haven | `frozen_peaks_secondary_*` |
| Prop 1 | `cliff_side` | Poly Haven | `frozen_peaks_prop1_*` |
| Prop 3 | `asphalt_snow` | Poly Haven | `frozen_peaks_prop3_*` |

**Color Grading:** Blue-white (#D4E4F7), gray stone (#6B7A8F)

### 3. Desolate Wastes ✅

| Role | Asset Name | Source | Local File Prefix |
|------|------------|--------|-------------------|
| Primary | `aerial_beach_01` | Poly Haven | `desolate_wastes_primary_*` |
| Secondary | `dry_ground_01` | Poly Haven | `desolate_wastes_secondary_*` |
| Prop 1 | `dry_ground_rocks` | Poly Haven | `desolate_wastes_prop1_*` |
| Prop 2 | `cracked_red_ground` | Poly Haven | `desolate_wastes_prop2_*` |
| Prop 3 | `coast_sand_05` | Poly Haven | `desolate_wastes_prop3_*` |

**Color Grading:** Tan (#C9A66B), dry brown (#8B6F47)

### 4. Golden Plains ✅

| Role | Asset Name | Source | Local File Prefix |
|------|------------|--------|-------------------|
| Primary | `grass_path_2` | Poly Haven | `golden_plains_primary_*` |
| Secondary | `rocky_terrain_02` | Poly Haven | `golden_plains_secondary_*` |
| Alt Primary | `Grass004` | AmbientCG | `golden_plains_alt_primary_*` |
| Prop 1 | `forrest_ground_01` | Poly Haven | `golden_plains_prop1_*` |
| Prop 2 | `Ground037` | AmbientCG | `golden_plains_prop2_*` |

**Color Grading:** Golden yellow (#D4AF37), green (#6B8E23)

### 5. Ashlands ✅

| Role | Asset Name | Source | Local File Prefix |
|------|------------|--------|-------------------|
| Primary | `burned_ground_01` | Poly Haven | `ashlands_primary_*` |
| Secondary | `aerial_rocks_04` | Poly Haven | `ashlands_secondary_*` |
| Prop 1 | `cracked_concrete` | Poly Haven | `ashlands_prop1_*` |
| Prop 2 | `bitumen` | Poly Haven | `ashlands_prop2_*` |
| Prop 3 | `rock_boulder_dry` | Poly Haven | `ashlands_prop3_*` |

**Color Grading:** Charcoal (#2B2B2B), ember red (#8B2323)

### 6. Highlands (Rolling Hills) ✅

| Role | Asset Name | Source | Local File Prefix |
|------|------------|--------|-------------------|
| Primary | `grass_meadow` | *(Uses Golden Plains)* | `highlands_primary_*` |
| Secondary | `coast_sand_rocks_02` | *(Uses Enchanted Forest)* | `highlands_secondary_*` |
| Prop 1 | `aerial_grass_rock` | Poly Haven | `highlands_prop1_*` |
| Prop 2 | `aerial_rocks_01` | Poly Haven | `highlands_prop2_*` |
| Prop 3 | `brown_mud_rocks_01` | Poly Haven | `highlands_prop3_*` |

**Color Grading:** Sage green (#7A9D7E), brown (#654321)

### 7. Swamplands ✅

| Role | Asset Name | Source | Local File Prefix |
|------|------------|--------|-------------------|
| Primary | `brown_mud_02` | Poly Haven | `swamplands_primary_*` |
| Secondary | `brown_mud_03` | Poly Haven | `swamplands_secondary_*` |
| Prop 1 | `concrete_moss` | Poly Haven | `swamplands_prop1_*` |
| Prop 2 | `aerial_mud_1` | Poly Haven | `swamplands_prop2_*` |
| Prop 3 | `cobblestone_floor_04` | Poly Haven | `swamplands_prop3_*` |

**Color Grading:** Murky green (#4A5D23), brown mud (#5C4033)

---

### Board & Table Textures ✅ COMPLETE

| Purpose | Asset Name | Source | Local Prefix |
|---------|------------|--------|--------------|
| Table Wood | `dark_wood` | Poly Haven | `table_wood_*` |
| Table Wood Alt | `brown_planks_03`, `dark_wooden_planks` | Poly Haven | `table_wood_alt1_*`, `table_wood_alt2_*` |
| Frame Stone | `castle_brick_01` | Poly Haven | `frame_stone_*` |
| Frame Stone Alt | `castle_wall_slates`, `defense_wall` | Poly Haven | `frame_stone_alt1_*`, `frame_stone_alt2_*` |
| Frame Metal | `corrugated_iron` | Poly Haven | `frame_metal_*` |
| Frame Metal Alt | `blue_metal_plate` | Poly Haven | `frame_metal_alt_*` |
| UI Wood | `dark_wood` | Poly Haven | `ui_wood_*` |
| UI Stone | `castle_brick_01` | Poly Haven | `ui_stone_*` |
| UI Metal | `corrugated_iron` | Poly Haven | `ui_metal_*` |

---

### HDRI Environment ✅ COMPLETE

- **File:** `evening_road_01_4k.exr`
- **Source:** Poly Haven
- **Location:** `res://assets/hdri/`
- **Usage:** Global skybox and ambient lighting

---

### Godot Import Settings (All Textures)

```gdscript
Import As: Texture
Compression Mode: VRAM Compressed (for Low/Med settings)
                  VRAM Uncompressed (for High/Ultra settings)
Mipmaps: Enabled
Filter: Linear
Anisotropic: 16x (High/Ultra), 4x (Med), 2x (Low)
sRGB: Enabled for Albedo, Disabled for Normal/Roughness/AO
```

---

## Character Models & Animations (🔴 NEEDED)

### 12 Troop Models Required

**AI Generation Prompts Ready** - Use Meshy AI, Leonardo AI, or Stable Diffusion 3D

#### Ground Tanks

**1. Medieval Knight**
```
Prompt: Photorealistic 3D model of a medieval armored knight, full plate armor with 
chainmail, heraldic shield with crest, longsword at side, battle-worn but noble, 
standing proud pose, 4K textures, PBR materials (metallic armor, leather straps), 
Manor Lords art style, unreal engine quality
```

**2. Stone Giant**
```
Prompt: Photorealistic 3D model of a massive stone giant, body made of granite and 
boulders, moss and vines growing on rocky surface, ancient runes glowing faintly, 
imposing 10-foot tall figure, clenched fists, stoic expression, 4K textures, 
PBR materials (rough stone, luminescent runes), fantasy realism
```

**3. Four-Headed Hydra**
```
Prompt: Photorealistic 3D model of a four-headed hydra, serpentine body with dark 
green scales, each head unique expression (snarling, roaring, hissing, calm), 
dripping venom from fangs, coiled tail, muscular reptilian form, 4K textures, 
PBR materials (wet scales, sharp teeth), epic fantasy creature
```

#### Air/Hybrid Units

**4. Dark Blood Dragon**
```
Prompt: Photorealistic 3D model of a dark blood dragon, crimson and black scales, 
leathery bat-like wings spread wide, horned head with fierce eyes, smoke wisping 
from nostrils, muscular quadruped body, spiked tail, 4K textures, PBR materials 
(glossy scales, matte wings), menacing presence
```

**5. Sky Serpent**
```
Prompt: Photorealistic 3D model of a sky serpent, sleek azure and white scales, 
feathered wings like a bird of prey, elongated serpentine body flowing gracefully, 
lightning crackling around body, wise ancient eyes, 4K textures, PBR materials 
(iridescent scales, soft feathers), majestic aerial predator
```

**6. Frost Valkyrie**
```
Prompt: Photorealistic 3D model of a frost valkyrie warrior, icy blue and silver 
armor with fur trim, winged helmet, frosted feathered wings, wielding enchanted 
ice spear and shield, flowing white cape, battle-ready stance, 4K textures, 
PBR materials (frozen metal, frost effects), Nordic fantasy aesthetic
```

#### Ranged/Magic Units

**7. Dark Magic Wizard**
```
Prompt: Photorealistic 3D model of a dark magic wizard, hooded black and purple 
robes with arcane runes, gnarled wooden staff topped with dark crystal, wispy 
beard, glowing eyes under hood, spectral smoke swirling around, 4K textures, 
PBR materials (cloth robes, glowing runes), mysterious and powerful
```

**8. Demon of Darkness**
```
Prompt: Photorealistic 3D model of a demon of darkness, muscular humanoid form 
with obsidian black skin, burning red eyes, curved horns, bat-like wings, clawed 
hands wreathed in dark flames, spiked tail, intimidating 8-foot height, 4K textures, 
PBR materials (rough skin, glowing embers), infernal presence
```

**9. Elven Archer**
```
Prompt: Photorealistic 3D model of an elven archer, elegant green and brown leather 
armor with leaf motifs, ornate longbow with glowing string, quiver of enchanted 
arrows, graceful elven features with pointed ears, blonde hair in braids, poised 
aiming stance, 4K textures, PBR materials (supple leather, wooden bow), ethereal beauty
```

#### Flex/Support/Assassin Units

**10. Celestial Cleric**
```
Prompt: Photorealistic 3D model of a celestial cleric, white and gold holy robes 
with sun emblem, glowing halo above head, ornate staff with radiant crystal, 
serene compassionate expression, healing light emanating from hands, 4K textures, 
PBR materials (silk robes, luminous effects), divine healer aesthetic
```

**11. Shadow Assassin**
```
Prompt: Photorealistic 3D model of a shadow assassin, sleek black leather armor 
with hood and mask, twin daggers with dark runes, smoke-like shadows trailing 
from body, crouched stealth pose, piercing eyes visible through mask, 4K textures, 
PBR materials (matte leather, ethereal smoke), lethal and silent
```

**12. Infernal Soul**
```
Prompt: Photorealistic 3D model of an infernal soul, semi-translucent fiery spirit 
form, humanoid shape made of flickering flames and embers, burning eyes, skeletal 
features visible through fire, floating slightly above ground, hands ablaze, 
4K textures, PBR materials (fire simulation, heat distortion), chaotic fire elemental
```

---

### 3 NPC Models Required

**Goblin**
```
Prompt: Photorealistic 3D model of a goblin enemy, small 3-foot height, 
green-brown wrinkled skin, oversized ears and nose, clutching rusty dagger, 
ragged cloth scraps, hunched sneaky posture, yellow eyes, 4K textures, 
PBR materials (rough skin, tattered cloth), low-tier monster
```

**Orc**
```
Prompt: Photorealistic 3D model of an orc warrior, muscular 6-foot humanoid, 
gray-green skin with scars, tusks protruding from lower jaw, crude iron armor 
and battle axe, aggressive stance, tribal war paint, 4K textures, PBR materials 
(scarred skin, battered metal), mid-tier brute
```

**Troll**
```
Prompt: Photorealistic 3D model of a troll, massive 12-foot giant, moss-covered 
dark green skin, hunchbacked with long arms, club made from tree trunk, 
regenerating wounds visible, primitive loincloth, 4K textures, PBR materials 
(mossy skin, rough bark club), high-tier tank monster
```

---

### Animation Requirements (🔴 NEEDED)

**NOW Animations (Phase 1):**
- [ ] Idle loop (breathing, subtle movement)
- [ ] Attack animation (swing, cast, shoot - per troop type)
- [ ] Take damage animation (flinch, stagger)
- [ ] Death animation (collapse, fade out)

**LATER Animations (Phase 2):**
- [ ] Movement walk/run cycle
- [ ] Victory pose (celebrate)
- [ ] Defensive stance variations (brace, dodge, counter)
- [ ] Special ability animations (per unique move)
- [ ] Status effect reactions (stunned shake, burned writhing)

---

### Model Export Settings

**Format:** `.glb` (embedded textures)
**Polygon Budget:**
- Troops: 5,000-10,000 tris (medium poly)
- NPCs: 3,000-5,000 tris (low poly)
- Gold Mines: 1,000-2,000 tris (low poly)

**Godot Import Settings:**
```
Compression: VRAM Compressed
Generate LODs: Enabled (3 levels: 100%, 50%, 25%)
Mesh Compression: Enabled
Physics: Disabled (use collision shapes instead)
```

---

## UI Assets & Effects (🔴 NEEDED)

### Card Illustrations (12 Required)

**AI Generation Prompts** - Use Midjourney, DALL-E 3, or Stable Diffusion

**Example: Medieval Knight Card**
```
Prompt: Epic fantasy card art illustration of a medieval knight in shining plate 
armor, heroic pose with sword and shield raised, glowing heraldic crest, 
battlefield background with castle walls, dynamic lighting, painterly art style 
like Magic: The Gathering, vertical card format 2:3 aspect ratio, detailed 
illustration, vibrant colors
```

**Card Specifications:**
- **Resolution:** 512×768 (2:3 aspect ratio)
- **Format:** PNG with transparency
- **Style:** Painterly illustration (MTG/Hearthstone aesthetic)
- **Content:** Troop portrait, environment hint, dramatic lighting

---

### Particle Effects (🔴 NEEDED)

**NOW - Basic Combat (Phase 1):**
- [ ] Attack impact flash (white/red burst)
- [ ] Blood splatter (small particles)
- [ ] Healing sparkles (green/gold twinkle)
- [ ] Damage numbers (floating text particle)
- [ ] Death dissolve (fade particle)

**LATER - Advanced Effects (Phase 2):**
- [ ] Fire effects (flames, embers, smoke)
- [ ] Ice effects (frost crystals, icy mist)
- [ ] Dark magic (shadow tendrils, purple energy)
- [ ] Holy effects (golden light beams, divine sparkles)
- [ ] Nature effects (leaves, vines, earth chunks)
- [ ] Lightning bolts (electric arcs)
- [ ] Status effect visuals (burn aura, poison bubbles)

---

### Dice Models (🔴 NEEDED)

**Physical D20 Dice:**
- [ ] High-poly 3D d20 model (icosahedron)
- [ ] Numbers engraved on faces (1-20)
- [ ] PBR materials (ivory white, gold numbers)
- [ ] Physics-enabled for rolling animation

---

## Quality Settings System (✅ COMPLETE)

### Granular Quality Presets

**Low (Work Laptops):**
- Textures: 1K, VRAM compressed
- Shadows: Off
- Particles: Minimal
- LOD: Aggressive (50% at 10m, billboard at 20m)
- Grass: Off

**Medium (Mid-Range PCs):**
- Textures: 2K, VRAM compressed
- Shadows: Simple (no soft shadows)
- Particles: Moderate
- LOD: Moderate (75% at 15m, billboard at 30m)
- Grass: Low density

**High (Gaming PCs):**
- Textures: 4K, VRAM uncompressed
- Shadows: Soft shadows enabled
- Particles: Full
- LOD: Subtle (100% at 20m, 75% at 40m)
- Grass: High density

**Ultra (High-End PCs):**
- Textures: 4K, VRAM uncompressed
- Shadows: High-quality soft shadows
- Particles: Full with extra details
- LOD: Minimal (100% at 30m, 75% at 60m)
- Grass: Full Witcher 3 style

---

### Procedural Grass System (Witcher 3 Style)

**Implementation:**
- [ ] Use Godot's MultiMeshInstance3D for grass
- [ ] Wind shader (swaying animation)
- [ ] LOD system (fade at distance)
- [ ] Quality toggle (Ultra only)

**Biome-Specific Grass:**
- **Golden Plains:** Tall golden wheat
- **Enchanted Forest:** Short green grass with wildflowers
- **Highlands:** Medium sage grass
- **Swamplands:** Wet reeds and cattails

---

# Part 4: Combat UX & Accessibility

## Combat New Player Experience

### Overview

The combat system has been identified as **complex for new players** due to:
- 4 moves × 12 troops = 48 total moves to learn
- 6 damage types with 36 potential matchups
- 8 status effects
- Stat stages, positioning bonuses, defensive stances
- 10-second timer creating pressure

**Solution:** 7-phase refactoring plan to make combat accessible while preserving depth.

---

## Tutorial System (Phase 1 - 🔴 PENDING)

### 1.1 First Combat Tutorial (Scripted)
- [ ] Create `TutorialCombatManager` class extending `CombatManager`
- [ ] Implement scripted first combat (player always wins)
- [ ] Highlight UI elements one at a time with tooltips
- [ ] Pause timer during tutorial explanations
- [ ] Speech bubbles or modal popups for each step

### 1.2 Progressive Tutorial Battles
- [ ] **Tutorial 1: Basic Attack** — Only Standard move, explain hit/miss
- [ ] **Tutorial 2: Move Variety** — Unlock Power move, explain accuracy trade-off
- [ ] **Tutorial 3: Type Effectiveness** — Fight weak enemy, show damage multipliers
- [ ] **Tutorial 4: Defensive Stances** — Teach Brace vs Dodge decision
- [ ] **Tutorial 5: Positioning** — Demonstrate flanking advantage
- [ ] **Tutorial 6: Full Combat** — All mechanics unlocked

### 1.3 Tutorial Skip Option
- [ ] Add "Skip Tutorial" button for experienced players
- [ ] Store tutorial completion in player save data
- [ ] Allow re-accessing tutorials from settings menu

**Estimated Time:** 8-12 hours

---

## Simple Combat Mode (Phase 2 - ✅ COMPLETE)

### 2.1 Simple Combat Configuration
- [x] Add `combat_mode` setting: `SIMPLE` | `ENHANCED`
- [x] Simple mode reduces moves from 4 → 2 (Standard + 1 Special)
- [x] Simple mode removes Advantage/Disadvantage display
- [x] Simple mode auto-selects defender stance (always Brace)
- [x] Extend timer to 15 seconds in Simple mode

### 2.2 Type Effectiveness Simplification
- [x] Reduce damage types: Physical, Magic, Elemental (3 instead of 6)
- [x] Show "STRONG" / "WEAK" / "NEUTRAL" labels prominently
- [x] Color coding: Green = good, Red = bad, White = neutral

### 2.3 Difficulty Settings
- [x] Add AI difficulty slider (Easy, Normal, Hard)
- [x] Easy AI makes suboptimal move choices
- [x] Easy AI uses Standard move more often

**Status:** ✅ Core implementation complete. UI toggle pending.

---

## UI/UX Improvements (Phase 3 - 🔴 PENDING)

### 3.1 Move Button Redesign
- [ ] Redesign move buttons with clearer visual hierarchy
  - Large: Move Name
  - Medium: Power + Accuracy (icons, not text)
  - Small: Cooldown indicator
- [ ] Add move type icons (⚔️ Standard, 💥 Power, 🎯 Precision, ✨ Special)
- [ ] Show predicted damage range on hover
- [ ] Color-coded borders based on type effectiveness
- [ ] Pulsing highlight on "recommended" move for new players

### 3.2 Combat Prediction Preview
- [ ] Show "Expected Damage: XX-YY" when hovering over a move
- [ ] Show hit chance percentage (e.g., "78% to hit")
- [ ] Preview type effectiveness before selecting move
- [ ] "If you use this move:" summary panel

### 3.3 Combat Log / History
- [ ] Add collapsible combat log panel
- [ ] Log entries explain what happened (e.g., "Attack missed because d20=4 < DC=15")
- [ ] Color code log entries (green = good, red = bad)
- [ ] Allow clicking log entries for detailed breakdown

### 3.4 Timer Improvements
- [ ] Add timer sound cues at 5s and 3s remaining
- [ ] Flash timer when < 3 seconds
- [ ] Show what will happen on timeout (default move/stance)
- [ ] Add "Thinking..." animation while waiting for opponent

### 3.5 Stance Selection Improvements
- [ ] Add clear descriptions for each stance in UI
- [ ] Show when each stance is most useful
- [ ] Highlight recommended stance based on enemy's likely attack
- [ ] Add stance comparison view (side-by-side pros/cons)

**Estimated Time:** 10-14 hours

---

## Information Architecture (Phase 4 - 🔴 PENDING)

### 4.1 Type Chart Quick Reference
- [ ] Add "?" button that opens Type Chart overlay
- [ ] Type Chart shows all matchups with icons
- [ ] Highlight current attacker vs defender matchup
- [ ] Store in closable popup (not full screen)

### 4.2 Troop Info Cards
- [ ] Right-click troop for detailed info card
- [ ] Show all 4 moves with detailed descriptions
- [ ] Show troop's reaction ability
- [ ] Show type resistances/weaknesses
- [ ] Show stat breakdown (HP, ATK, DEF, SPD)

### 4.3 Contextual Hints
- [ ] Show contextual tips during combat selection
- [ ] Hint examples:
  - "Your opponent is on Forest cover! You have Disadvantage."
  - "This move is Super Effective against the target!"
  - "Warning: This move is on cooldown after use."
- [ ] Allow disabling hints in settings

### 4.4 Move Tooltip Enhancements
- [ ] Expand `MoveTooltipUI` with more details
- [ ] Show cooldown status and turns remaining
- [ ] Show special effects (status application, AoE pattern)
- [ ] Show damage type with visual icon

**Estimated Time:** 6-8 hours

---

## Combat Feedback (Phase 5 - 🔴 PENDING)

### 5.1 Roll Visualization
- [ ] Add animated dice roll (3D dice or 2D sprite)
- [ ] Show dice result prominently before comparison
- [ ] Add suspense delay before revealing hit/miss
- [ ] Celebrate critical hits with special effects
- [ ] Soften critical miss with encouraging message

### 5.2 Damage Number Display
- [ ] Show floating damage numbers above target
- [ ] Color code: Red = normal, Gold = crit, Orange = super effective
- [ ] Show small breakdown icons (🔥 = fire damage, etc.)
- [ ] Include heals as green floating numbers

### 5.3 Status Effect Feedback
- [ ] Show status effect icon on affected unit
- [ ] Add status effect application animation
- [ ] Show turns remaining on status effect hover
- [ ] Play unique sound for each status type

### 5.4 Reaction Feedback
- [ ] Highlight when a reaction triggers
- [ ] Show reaction name and effect in combat log
- [ ] Add unique animation for each reaction type
- [ ] Explain why reaction triggered

**Estimated Time:** 8-10 hours

---

## Practice Mode (Phase 6 - 🔴 PENDING)

### 6.1 Practice Arena
- [ ] Add "Practice Mode" option from main menu
- [ ] Allow selecting any troop vs any enemy
- [ ] Reset HP after each exchange
- [ ] No timer in practice mode
- [ ] Show all hidden calculations in detail

### 6.2 Move Encyclopedia
- [ ] Create browsable encyclopedia of all moves
- [ ] Filter by troop, damage type, move type
- [ ] Sort by power, accuracy, cooldown
- [ ] Mark moves as "Favorites"

### 6.3 Damage Calculator
- [ ] Add tool to calculate damage before combat
- [ ] Select attacker, defender, move
- [ ] Show expected damage range with breakdown
- [ ] Toggle positioning modifiers

**Estimated Time:** 8-10 hours

---

## AI Improvements (Phase 7 - 🔴 PENDING)

### 7.1 Difficulty Scaling
- [ ] **Easy AI**: Random moves weighted toward Standard
- [ ] **Normal AI**: Type-effective moves when available
- [ ] **Hard AI**: Optimal move selection, considers positioning
- [ ] Add adaptive difficulty (adjust if player struggling)

### 7.2 AI Personality Hints
- [ ] Show AI "thinking" messages
- [ ] AI occasionally makes "readable" moves for counterplay
- [ ] AI announces impactful moves

**Estimated Time:** 4-6 hours

---

## Implementation Priority

| Priority | Phase | Impact | Effort | Recommendation |
|----------|-------|--------|--------|----------------|
| 🔴 HIGH | Phase 3 (UI Improvements) | High | Medium | Start here |
| 🔴 HIGH | Phase 1 (Tutorial) | High | High | Essential for new players |
| 🟡 MEDIUM | Phase 4 (Information) | Medium | Low | Quick win |
| 🟡 MEDIUM | Phase 5 (Feedback) | High | Medium | Polish that delights |
| 🟢 LOW | Phase 2 (Simple Mode) | Medium | Medium | ✅ Already done! |
| 🟢 LOW | Phase 6 (Practice) | Low | High | Nice-to-have |
| 🟢 LOW | Phase 7 (AI) | Medium | Low | Improves replayability |

---

# Part 5: Reference Documentation

## Combat Guide (Player-Facing)

### Overview

Combat uses a **D&D × Pokémon hybrid system** combining dice-based attack rolls with type effectiveness and unique moves.

---

### How Combat Works

**1. Initiating Combat:**
- Attacker chooses a **Move** from 4 available moves
- Defender chooses a **Defensive Stance**
- Both choices made simultaneously with **10-second timer**
- Choices revealed, dice rolled, damage calculated

**2. Attack Resolution:**
```
Attack Roll = d20 + ATK stat + Accuracy Modifier + Position Bonuses
Defense DC = 10 + DEF stat + Stance Bonus + Position Bonuses

If Attack Roll > Defense DC → HIT!
If Attack Roll ≤ Defense DC → MISS!
```

**3. Critical Hits & Misses:**
- **Natural 18-20**: Critical Hit! Double damage!
- **Natural 1**: Critical Miss! Automatic miss!

---

### Move Types

| Type | Power | Accuracy | Cooldown | Best For |
|------|-------|----------|----------|----------|
| **Standard** | 100% | +0 | None | Reliable damage every turn |
| **Power** | 150% | -3 | 3 turns | Big damage, risky accuracy |
| **Precision** | 80% | +5 | 2 turns | Guaranteed hits on tough targets |
| **Special** | 120% | +0 | 4 turns | Effects + good damage |

---

### Damage Types

| Type | Icon | Strong Against | Weak Against |
|------|------|----------------|--------------|
| **Physical** | ⚔️ | Varies | CONSTRUCT |
| **Fire** | 🔥 | UNDEAD, NATURE | ELEMENTAL |
| **Ice** | ❄️ | BEAST, NATURE | ELEMENTAL |
| **Dark** | 🌑 | SPIRIT | HOLY |
| **Holy** | ✨ | UNDEAD, DARK | None |
| **Nature** | 🌿 | BEAST | UNDEAD |

**Type Effectiveness:**
- **Super Effective**: Deal **1.5x** damage! 💥
- **Not Very Effective**: Deal **0.5x** damage...
- **Immune**: Deal **0** damage! 🛡️

---

### Defensive Stances

**Brace 🛡️**
- +3 DEF bonus to Defense DC
- Take 20% less damage if hit
- *Best for:* Tanking hits when you expect to get hit

**Dodge ⚡**
- +5 Evasion to Defense DC
- No damage reduction if hit
- *Best for:* Against low-accuracy Power moves

**Counter ↩️**
- No defensive bonus
- If enemy misses, deal 50% of your ATK back!
- *Best for:* Against precision attacks you think will miss

**Endure 💪**
- No defensive bonus
- If damage would kill you, survive at 1 HP!
- **Once per combat** - use wisely!
- *Best for:* Clutch survival when you'd die otherwise

---

### Positioning Bonuses

**Flanking (+3 Hit)**
- Have an ally adjacent to the defender when attacking

**High Ground (+2 Hit, +10% Damage)**
- Attack from Hills or Peaks terrain

**Cover (+3 DEF)**
- Defend from Forest or Ruins terrain

**Surrounded (-2 DEF)**
- Defender has 3+ enemies adjacent

---

### Status Effects

| Effect | Icon | Duration | Effect |
|--------|------|----------|--------|
| **Stunned** | ⚡ | 1 turn | Can't act! Auto-Brace if attacked |
| **Burned** | 🔥 | 3 turns | Take 10 damage per turn |
| **Poisoned** | ☠️ | 4 turns | Take 8 damage per turn |
| **Slowed** | 🐢 | 2 turns | -2 Speed |
| **Cursed** | 💀 | 3 turns | -25% ATK |
| **Terrified** | 😱 | 2 turns | -25% DEF |
| **Rooted** | 🌿 | 2 turns | Can't move |
| **Stealth** | 👻 | 3 turns | Next attack is guaranteed crit! |

---

### Combat Tips

1. **Don't spam Power moves** - Cooldown means you can't use them often
2. **Use Precision moves** against high-DEF tanks
3. **Counter stance** is high-risk, high-reward
4. **Save Endure** for when you really need it
5. **Watch type matchups** - 1.5x damage adds up fast!
6. **Position matters** - Fight from high ground when possible
7. **Focus fire** to trigger Surrounded debuff
8. **Cleanse debuffs** with Celestial Cleric's moves

---

## Troop Balance Reference

### Rebalanced Unit Table (Optimized for 1v1 – 4 Card Decks)

| Unit | HP | ATK | DEF | Range | Speed | Role | Mana | Biome Strength | Notes |
|------|-----|-----|-----|-------|-------|------|------|----------------|-------|
| Dark Magic Wizard | 80 | 95 | 55 | 3 (Magic) | 2 | Area Mage | 4 | Forest +A / Ashlands +S | Fragile, splash magic |
| Medieval Knight | 130 | 85 | 120 | 1 (Melee) | 3 | Tank / Melee | 5 | Plains +S / Hills +A | Standard all-rounder |
| Dark Blood Dragon | 150 | 100 | 80 | 3 (Air) | 5 | Air Tank | 8 | Ashlands +A / Plains +S | Air dominance |
| Infernal Soul | 65 | 90 | 45 | 1 (Melee) | 5 | Assassin | 3 | Forest +S / Wastes +A | Fast but fragile |
| Four-Headed Hydra | 240 | 130 | 150 | 1 (Melee) | 1 | Ground Tank | 9 | Swamp +A / Hills +D | Immovable powerhouse |
| Demon of Darkness | 140 | 135 | 100 | 2 (Magic) | 2 | Heavy Caster | 7 | Ashlands +A,D / Peaks +A | High damage dealer |
| Sky Serpent | 110 | 90 | 70 | 2 (Air) | 5 | Agile Air | 5 | Peaks +A / Plains +S | Counter to ranged |
| Stone Giant | 200 | 95 | 160 | 1 (Melee) | 1 | Siege / Tank | 8 | Hills +D / Ashlands –S | Slow fortress |
| Shadow Assassin | 75 | 110 | 55 | 1 (Melee) | 5 | Stealth / Burst | 4 | Forest +S / Swamp +A | Quick killer |
| Elven Archer | 90 | 85 | 60 | 3 (Ranged) | 3 | Ranged / Anti-Air | 4 | Forest +A / Plains +S | Reliable support |
| Frost Valkyrie | 120 | 100 | 90 | 2 (Hybrid) | 4 | Air-Ground Hybrid | 6 | Peaks +A / Plains +S | Balanced hybrid |
| Celestial Cleric | 100 | 65 | 100 | 2 (Support) | 2 | Healer / Buffer | 5 | Hills +D / Forest +A | Keeps allies alive |

---

### Deck-Building Rules

**Each player picks 4 cards with these restrictions:**
- 🛡️ 1 Ground Tank (Knight, Hydra, Giant, Demon)
- ✈️ 1 Air or Hybrid Unit (Dragon, Serpent, Valkyrie)
- 🏹 1 Ranged or Magic (Wizard, Archer)
- ⚡ 1 Flex / Support / Assassin (Infernal Soul, Shadow Assassin, Cleric)
- **Mana total per deck:** ≤ 22 (average ~5.5 each)

---

### Design Philosophy

- **Power normalized by cost:** High-cost units are stronger but slower and rarer
- **Biome effects give tactical edges:** Not total dominance
- **Speed = tactical reach:** Slower units control space via defense or area attacks

---

## Complete Game Rules

### Spawn Points

- **4 spawn hexes per player** at extreme edges of board (opposite sides)
- Spawn hexes are **4 hexes straight across** at each player's edge
- All 4 troops spawn immediately at game start (one per spawn hex)
- Respawned troops appear at any available spawn hex on player's side

---

### Respawn System (Phoenix Feather)

**Phoenix Feather (Respawn Item):**
- Rare drop from defeating **Troll NPCs** (20% drop chance)
- When used (costs 1 action): Respawns one destroyed troop at a spawn point
- Each player can hold max **1 feather** at a time
- Cannot be stolen by enemies
- Appears in player inventory when obtained

---

### Aggression Bounty System

**Anti-Turtle Mechanic:** Rewards aggressive play to prevent stalling.

| Bonus | Reward | Trigger |
|-------|--------|--------|
| **First Blood** | +50 Gold | First enemy troop killed in match |
| **Kill Streak** | +25% → +50% → +100% XP | 2nd, 3rd, 4th+ consecutive kills |
| **Revenge Kill** | +25% Gold | Kill the unit that killed your troop |
| **Mine Raider** | +20 Gold | Destroy enemy gold mine |

---

### Keyboard Controls

| Key | Action |
|-----|--------|
| 1-4 | Select troop by card slot |
| Space | End turn |
| Esc | Pause menu |

---

### Settings Menu

- Music volume
- SFX volume
- Cutscene speed (Full/Fast/Skip)
- Turn timer (1min/2min/Off)
- Combat mode (Simple/Enhanced)
- Resolution/Fullscreen

---

# Part 6: Implementation Checklists

## Master TODO List

### ✅ COMPLETED (29/30)

1. ✅ **setup-project** - Project structure created
2. ✅ **hex-coordinates** - Hex coordinate system implemented
3. ✅ **hex-board** - 397 hexagon board generated
4. ✅ **biome-procedural** - Procedural biome generation
5. ✅ **biome-system** - 7 biome types with properties
6. ✅ **player-system** - Player class and PlayerManager
7. ✅ **turn-system** - TurnManager with actions and timer
8. ✅ **card-system** - 12 troop card data structure
9. ✅ **deck-validation** - Deck building restrictions
10. ✅ **troop-system** - Troop class with stats and spawning
11. ✅ **movement-system** - Pathfinding and movement
12. ✅ **combat-system** - D&D × Pokémon hybrid combat
13. ✅ **gold-system** - Gold tracking and display
14. ✅ **gold-mine-placement** - Mine placement validation
15. ✅ **gold-mine-generation** - Turn-based gold generation
16. ✅ **xp-system** - XP tracking and display
17. ✅ **combat-xp-rewards** - XP from killing troops
18. ✅ **npc-system** - NPC spawning and combat
19. ✅ **npc-xp-rewards** - XP from killing NPCs
20. ✅ **gold-mine-upgrades** - Mine upgrade system
21. ✅ **troop-upgrades** - Troop stat upgrades
22. ✅ **game-manager** - GameManager state machine
23. ✅ **game-ui** - Main game HUD
24. ✅ **dice-ui** - Dice rolling interface
25. ✅ **card-selection-ui** - Pre-game deck builder
26. ✅ **biome-strength-effects** - Biome bonuses/penalties
27. ✅ **network-manager** - ENet multiplayer setup
28. ✅ **lobby-ui** - Host/Join lobby system
29. ✅ **rpc-implementation** - Network action synchronization

### 🔴 PENDING (1/30)

30. ⏳ **polish-testing** - UI polish, animations, bug fixes, optimization

---

## Asset Acquisition Checklist

### ✅ Textures Complete (220 files, ~8.6 GB)

**Biome Textures:**
- [x] Enchanted Forest (5 textures × 5 maps)
- [x] Frozen Peaks (4 textures × 5 maps)
- [x] Desolate Wastes (5 textures × 5 maps)
- [x] Golden Plains (5 textures × 5 maps)
- [x] Ashlands (5 textures × 5 maps)
- [x] Highlands (5 textures × 5 maps)
- [x] Swamplands (5 textures × 5 maps)

**Board & UI Textures:**
- [x] Table wood (3 textures × 5 maps)
- [x] Frame stone (3 textures × 5 maps)
- [x] Frame metal (2 textures × 5 maps)
- [x] UI materials (3 textures × 5 maps)

**Environment:**
- [x] HDRI: `evening_road_01_4k.exr`

---

### 🔴 3D Models Needed (15 models)

**Troops (12):**
- [ ] Medieval Knight
- [ ] Stone Giant
- [ ] Four-Headed Hydra
- [ ] Dark Blood Dragon
- [ ] Sky Serpent
- [ ] Frost Valkyrie
- [ ] Dark Magic Wizard
- [ ] Demon of Darkness
- [ ] Elven Archer
- [ ] Celestial Cleric
- [ ] Shadow Assassin
- [ ] Infernal Soul

**NPCs (3):**
- [ ] Goblin
- [ ] Orc
- [ ] Troll

**Environment:**
- [ ] Hex base mesh (`hex_base.glb`)
- [ ] Gold mine buildings (5 levels)
- [ ] Spawn platform/altar

---

### 🔴 Card Illustrations Needed (12 cards)

- [ ] Medieval Knight card art
- [ ] Stone Giant card art
- [ ] Four-Headed Hydra card art
- [ ] Dark Blood Dragon card art
- [ ] Sky Serpent card art
- [ ] Frost Valkyrie card art
- [ ] Dark Magic Wizard card art
- [ ] Demon of Darkness card art
- [ ] Elven Archer card art
- [ ] Celestial Cleric card art
- [ ] Shadow Assassin card art
- [ ] Infernal Soul card art

---

### 🔴 Animations Needed

**NOW (Basic Combat):**
- [ ] Attack animations (12 troops)
- [ ] Damage animations (12 troops)
- [ ] Death animations (12 troops)

**LATER (Advanced):**
- [ ] Movement cycles (12 troops)
- [ ] Victory poses (12 troops)
- [ ] Special ability animations (48 moves)
- [ ] Status effect reactions (8 effects)

---

### 🔴 Particle Effects Needed

**NOW (Basic):**
- [ ] Attack impact flash
- [ ] Blood splatter
- [ ] Healing sparkles
- [ ] Damage numbers
- [ ] Death dissolve

**LATER (Advanced):**
- [ ] Fire effects
- [ ] Ice effects
- [ ] Dark magic
- [ ] Holy effects
- [ ] Nature effects
- [ ] Lightning
- [ ] Status visuals

---

### 🔴 Dice Model Needed

- [ ] D20 3D model (high-poly, physics-enabled)

---

### 🔴 Audio Needed (End of MVP)

**SFX:**
- [ ] UI clicks
- [ ] Troop movement
- [ ] Attack sounds (per damage type)
- [ ] Dice roll
- [ ] Gold/XP gain
- [ ] NPC encounter

**Music:**
- [ ] Main menu theme
- [ ] Gameplay ambient
- [ ] Combat music
- [ ] Victory fanfare
- [ ] Defeat theme

---

## Progress Tracking

### Phase 1: NOW - Core Assets

| Section | Tasks | Completed | Progress |
|---------|-------|-----------|----------|
| 1. Asset Acquisition | 60 | 35 | 58% |
| 2. Godot Import | 24 | 0 | 0% |
| 3. Materials & Shaders | 22 | 1 | 5% |
| 4. Board & Environment | 18 | 0 | 0% |
| 5. UI System | 23 | 0 | 0% |
| 6. Particle Effects | 16 | 0 | 0% |
| 7. Quality Settings | 18 | 18 | 100% |
| 8. Dice System | 14 | 0 | 0% |
| 9. Testing & Polish | 20 | 0 | 0% |
| **Phase 1 Total** | **215** | **54** | **25%** |

---

### Phase 2: LATER - Polish

| Section | Tasks | Completed | Progress |
|---------|-------|-----------|----------|
| 10. Advanced Animations | 14 | 0 | 0% |
| 11. Advanced Particles | 17 | 0 | 0% |
| 12. Audio System | 32 | 0 | 0% |
| 13. Camera Enhancements | 14 | 0 | 0% |
| 14. Advanced UI | 12 | 0 | 0% |
| 15. Optimization | 10 | 0 | 0% |
| 16. Future Features | 14 | 0 | 0% |
| **Phase 2 Total** | **113** | **0** | **0%** |

---

### Combat UX Improvements

| Phase | Tasks | Completed | Status |
|-------|-------|-----------|--------|
| Phase 1: Tutorial System | ~15 | 0 | 🔴 Pending |
| Phase 2: Simple Mode | 9 | 9 | ✅ Complete |
| Phase 3: UI Improvements | ~20 | 0 | 🔴 Pending |
| Phase 4: Information Architecture | ~15 | 0 | 🔴 Pending |
| Phase 5: Combat Feedback | ~15 | 0 | 🔴 Pending |
| Phase 6: Practice Mode | ~12 | 0 | 🔴 Pending |
| Phase 7: AI Improvements | ~8 | 0 | 🔴 Pending |
| **Total** | **~94** | **9** | **10%** |

---

### Grand Total

**All Systems:** 328 tasks (Phase 1 & 2 assets)
**Game Systems:** 30 tasks (implementation)
**Combat UX:** 94 tasks (accessibility)

**Overall Progress:**
- ✅ **Game Systems:** 29/30 (97%)
- 🟡 **Assets:** 54/328 (16%)
- 🟡 **Combat UX:** 9/94 (10%)

---

# Appendix: Asset Request Protocol

**IMPORTANT:** During development, when any asset (image, video, audio, 3D model) is required, follow this process:

1. **Pause implementation** of the feature requiring the asset
2. **Create an asset request** with specifications
3. **Asset delivery folder**: `assets/pending/`
4. **Notify user** with complete request details
5. **Resume implementation** once assets are provided

---

**Asset Request Template:**

```
### ASSET REQUEST
- **Type**: [Image/Audio/Video/3D Model]
- **Name**: [descriptive_filename]
- **Description**: [What it should contain]
- **Specifications**:
  - Resolution/Duration: [value]
  - Format: [value]
  - Other: [any special requirements]
- **Usage**: [Where this asset will be used in the game]
- **Priority**: [Critical/High/Medium/Low]
```

---

**For 3D Models:**
- Description of the model
- Polygon budget (low/medium/high poly)
- Texture requirements
- Animation requirements
- Format: `.glb` (embedded textures)

**For Images:**
- Description of content
- Resolution (e.g., 512×512, 1920×1080)
- Aspect ratio (e.g., 1:1, 16:9, 4:3)
- File format (PNG, JPG, WebP)
- Transparency requirements

**For Audio:**
- Description of sound/music
- Duration/length
- Format (MP3, OGG, WAV)
- Loop requirements (seamless loop, one-shot)
- Mood/tone

---

# Development Tools

## Godot MCP (Model Context Protocol) Server

Throughout development, leverage the **godot-mcp** tool for enhanced productivity.

**Available Tools:**
- `mcp_godot_create_scene` - Create new scene files
- `mcp_godot_add_node` - Add nodes to scenes
- `mcp_godot_load_sprite` - Load sprites into Sprite2D
- `mcp_godot_save_scene` - Save scene changes
- `mcp_godot_run_project` - Run project and capture output
- `mcp_godot_stop_project` - Stop running project
- `mcp_godot_launch_editor` - Launch Godot editor
- `mcp_godot_get_project_info` - Retrieve project metadata
- `mcp_godot_get_debug_output` - Get debug output/errors
- `mcp_godot_list_projects` - List projects in directory

**Use Cases:**
- Scene creation (hex tiles, troops, UI elements)
- Node management (configure without manual editor work)
- Testing & debugging (run project, capture console)
- Rapid prototyping (create test scenes programmatically)

---

# Future Enhancements (Out of Scope for Core)

- Spell system
- Gambling/mini-games
- Treasure chests
- Card shop system
- Save/load game (implemented via JSON)
- Online ranked matchmaking
- AI opponents (basic difficulty implemented)
- Replay system
- Achievements
- Mobile port

---

**Document Version:** 1.0  
**Created:** January 29, 2026  
**Combines:** implementation-plan.md, asset_integration_master_plan.md, combat-new-player-refactoring-plan.md, combat_guide.md, troop-cards-philosophy.txt

**Status:**
- ✅ Combat System Complete (191/191 tasks)
- ✅ Game Systems Complete (29/30 tasks)
- 🟡 Visual Assets Partial (54/328 tasks)
- 🟡 Combat UX Partial (9/94 tasks)
