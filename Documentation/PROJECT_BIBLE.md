# 🎮 Fantasy World: The Game — Project Bible

> **Single Source of Truth** for the Fantasy World medieval strategy board game project.
> This document consolidates all design decisions, implementation details, and project documentation.

---

## Table of Contents

1. [Overview & Philosophy](#overview--philosophy)
2. [Project Structure](#project-structure)
3. [Game Systems Architecture](#game-systems-architecture)
4. [Troops & Cards](#troops--cards)
5. [Combat System](#combat-system)
6. [Biome System](#biome-system)
7. [Economy & Progression](#economy--progression)
8. [NPC System](#npc-system)
9. [Multiplayer & Networking](#multiplayer--networking)
10. [New Player Experience (UX)](#new-player-experience-ux)
11. [Asset Integration](#asset-integration)
12. [UI/UX Design](#uiux-design)
13. [Visual Design](#visual-design)
14. [Game Rule Clarifications](#game-rule-clarifications)
15. [Performance Guidelines](#performance-guidelines)
16. [Technical Documentation](#technical-documentation)
17. [Implementation Progress & Roadmap](#implementation-progress--roadmap)
18. [Known Issues & Game Design Notes](#known-issues--game-design-notes)
19. [Changelog](#changelog)

---

# Overview & Philosophy

## Project Vision

Fantasy World is a **1v1 turn-based strategy board game** built in Godot 4.5, combining elements of card games (deck building), tactical board games (hex grid positioning), and RPG combat systems (D&D-style dice rolls with Pokémon-style type effectiveness).

## Core Design Philosophy

1. **Power normalized by cost**: High-cost units are stronger but slower and rarer
2. **Biome effects give tactical edges** — not total dominance
3. **Speed = tactical reach**: Slower units can still control space via defense or area attacks
4. **Strategic depth** through simultaneous decision-making and positioning
5. **MVP Focus**: Version 1.0 targets a playable, polished game with 12 troops

## Target Experience

- **Visual Style**: Grounded High Fantasy (The Witcher 3 lighting aesthetic + fantasy elements)
- **Lighting Style**: Witcher 3-inspired — moody, atmospheric, with warm/cool contrast, volumetric effects, and dramatic shadows
- **Target Hardware**: Scalable from work laptops to gaming PCs
- **Board Size**: 397 hexagons (12 hexagons per side, hexagonal pattern)
- **Player Count**: 2 players (1v1 networked multiplayer)

---

# Project Structure

The game is built in **Godot 4.5** using **GDScript**.

```
fantasy-world-game/
├── scenes/
│   ├── main.tscn                    # Main game scene
│   ├── board/
│   │   ├── hex_board.tscn           # Hex grid container
│   │   ├── hex_tile.tscn            # Individual hex tile
│   │   └── biome_manager.tscn       # Biome assignment
│   ├── gameplay/
│   │   ├── game_manager.tscn        # Core game state
│   │   ├── turn_manager.tscn        # Turn handling
│   │   ├── player_manager.tscn      # Player data
│   │   └── combat_manager.tscn      # Combat resolution
│   ├── ui/
│   │   ├── game_ui.tscn             # HUD and overlays
│   │   ├── card_ui.tscn             # Card display
│   │   ├── dice_ui.tscn             # Dice rolling
│   │   └── gold_ui.tscn             # Resource display
│   └── entities/
│       ├── troop.tscn               # Troop unit
│       ├── gold_mine.tscn           # Gold mine building
│       ├── npc.tscn                 # NPC encounters
│       └── card.tscn                # Card representation
├── scripts/
│   ├── board/
│   │   ├── hex_board.gd
│   │   ├── hex_tile.gd
│   │   ├── hex_coordinates.gd       # Hex math utilities
│   │   ├── biome_manager.gd
│   │   └── biome_generator.gd       # Procedural generation
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
│   │   └── gold_ui.gd
│   ├── entities/
│   │   ├── troop.gd
│   │   ├── gold_mine.gd
│   │   ├── npc.gd
│   │   └── card.gd
│   └── network/
│       ├── network_manager.gd       # ENet connections/RPCs
│       └── lobby_manager.gd         # Room code/discovery
├── data/
│   ├── biomes.gd                    # Biome definitions
│   ├── card_data.gd                 # 12 troop definitions
│   ├── move_data.gd                 # 48 move definitions
│   ├── combat_balance_config.gd     # Combat balance values
│   └── game_config.gd               # Game constants
└── assets/
    ├── models/                      # 3D models
    ├── textures/                    # PBR textures
    ├── shaders/                     # Custom shaders
    └── themes/                      # UI themes
```

---

# Game Systems Architecture

## 1. Hexagonal Board System

- **Grid Size**: 397 hexagons (12 per side, hexagonal pattern)
- **Coordinate System**: Axial coordinates (q, r)
- **Features**: Neighbor calculation, distance calculation, pathfinding (A*)
- **Height Variation**: Optional per-biome (toggle in settings)

## 2. Biome System

Seven biomes with procedural generation:
- **Enchanted Forest** 🌲
- **Frozen Peaks** ❄️
- **Desolate Wastes** 🏜️
- **Golden Plains** 🌾
- **Ashlands** 🌋
- **Highlands** ⛰️
- **Swamplands** 🌿

All 7 biomes are guaranteed present in every game.

## 3. Turn System

- **One action per troop per turn** (Move OR Attack OR Place Mine OR Upgrade)
- **Turn timer**: 1-2 minutes (configurable, agreed before game)
- **Turn order**: Determined by initial dice roll
- **Movement is always free** of resource cost

**Timer Rules:**
- When timer expires: Turn immediately passes (remaining actions lost)
- Timer **pauses** during combat animations and UI interactions (upgrade menu, etc.)
- Turns cannot be skipped — player must perform at least one action or end turn

## 4. Win Condition

**Defeat all enemy troops** — simple and clear.

---

# Troops & Cards

## Troop Count: 12 (Fixed)

There are exactly **12 troops** in the game, organized into 4 roles:

### Ground Tank Role (Pick 1)

| Troop | HP | ATK | DEF | Range | Speed | Mana | Ability |
|-------|-----|-----|-----|-------|-------|------|---------|
| **Medieval Knight** | 150 | 80 | 130 | 1 (Melee) | 2 | 5 | None |
| **Stone Giant** | 220 | 90 | 150 | 1 (Melee) | 1 | 8 | None |
| **Four-Headed Hydra** | 200 | 120 | 120 | 1 (Melee) | 1 | 9 | Multi-Strike |

### Air/Hybrid Role (Pick 1)

| Troop | HP | ATK | DEF | Range | Speed | Mana | Ability |
|-------|-----|-----|-----|-------|-------|------|---------|
| **Dark Blood Dragon** | 140 | 110 | 70 | 2 (Air) | 4 | 8 | None |
| **Sky Serpent** | 100 | 85 | 60 | 2 (Air) | 5 | 5 | None |
| **Frost Valkyrie** | 120 | 95 | 85 | 2 (Hybrid) | 4 | 6 | Anti-Air |

### Ranged/Magic Role (Pick 1)

| Troop | HP | ATK | DEF | Range | Speed | Mana | Ability |
|-------|-----|-----|-----|-------|-------|------|---------|
| **Dark Magic Wizard** | 75 | 100 | 50 | 3 (Magic) | 2 | 4 | Magic (ignores 25% DEF) |
| **Demon of Darkness** | 130 | 120 | 90 | 2 (Magic) | 2 | 7 | Magic (ignores 25% DEF) |
| **Elven Archer** | 80 | 90 | 55 | 3 (Ranged) | 3 | 4 | Anti-Air 2x |

### Flex/Support/Assassin Role (Pick 1)

| Troop | HP | ATK | DEF | Range | Speed | Mana | Ability |
|-------|-----|-----|-----|-------|-------|------|---------|
| **Celestial Cleric** | 110 | 55 | 100 | 2 (Support) | 2 | 5 | Heal (35 HP) |
| **Shadow Assassin** | 70 | 115 | 45 | 1 (Melee) | 5 | 4 | None (glass cannon) |
| **Infernal Soul** | 60 | 85 | 40 | 1 (Melee) | 5 | 3 | Death Burst (30 dmg) |

## Deck-Building Rules

- **1 Ground Tank** + **1 Air/Hybrid** + **1 Ranged/Magic** + **1 Flex**
- **Mana total ≤ 22** (enforced during deck selection)
- Selection happens **simultaneously** (30-second timer)
- Both players can pick the same troop (duplicates allowed)

## Moves Per Troop

Each troop has **4 unique moves** defined in `move_data.gd`:
- **Standard**: 100% power, no cooldown, reliable
- **Power**: 150% power, -3 accuracy, 3-turn cooldown
- **Precision**: 80% power, +5 accuracy, 2-turn cooldown
- **Special**: 120% power, status effect chance, 4-turn cooldown

**Total Moves in Game**: 48 (4 moves × 12 troops)

---

# Combat System

## Enhanced Combat System (D&D × Pokémon Hybrid)

The combat system combines simultaneous move/stance selection, type effectiveness, and status effects.

### Combat Flow

1. **Attacker** initiates combat by selecting a target
2. **Simultaneous Selection Phase** (10 seconds):
   - Attacker chooses a **Move** (4 unique moves per troop)
   - Defender chooses a **Defensive Stance** (Brace, Dodge, Counter, Endure)
3. Selections revealed simultaneously
4. Dice rolled, modifiers applied, damage calculated

### Dice System

- **Dice Type**: d20 (1-20 range)
- **Attack Roll** = d20 + ATK stat + Move Accuracy + Position Bonuses
- **Defense DC** = 10 + DEF stat + Stance Bonus + Position Bonuses
- **Attack Succeeds** if: Attack Roll > Defense DC

### Critical Hits/Misses

- **Natural 18-20**: Critical Hit! **Double damage!**
- **Natural 1**: Critical Miss! **Automatic miss!**

### Damage Formula

```
If attack succeeds:
  Damage = (ATK × Power% × Type Effectiveness) - DEF/2
  Damage is always at least 1
  Critical hits deal 2× damage
```

### Move Types

| Type | Power | Accuracy | Cooldown | Best For |
|------|-------|----------|----------|----------|
| **Standard** | 100% | +0 | None | Reliable damage every turn |
| **Power** | 150% | -3 | 3 turns | Big damage, risky accuracy |
| **Precision** | 80% | +5 | 2 turns | Guaranteed hits on tough targets |
| **Special** | 120% | +0 | 4 turns | Effects + good damage |

### Defensive Stances

| Stance | Effect | Best For |
|--------|--------|----------|
| **Brace** 🛡️ | +3 DEF, take 20% less damage | Tanking expected hits |
| **Dodge** ⚡ | +5 Evasion to DC | Against low-accuracy Power moves |
| **Counter** ↩️ | If missed, deal 50% ATK back | Punishing risky attacks |
| **Endure** 💪 | Survive at 1 HP (once per combat) | Clutch survival |

### Damage Types (6 Types)

| Type | Icon | Strong Against | Weak Against |
|------|------|----------------|--------------|
| **Physical** | ⚔️ | Varies | CONSTRUCT |
| **Fire** | 🔥 | UNDEAD, NATURE | ELEMENTAL |
| **Ice** | ❄️ | BEAST, NATURE | ELEMENTAL |
| **Dark** | 🌑 | SPIRIT | HOLY |
| **Holy** | ✨ | UNDEAD, DARK | None |
| **Nature** | 🌿 | BEAST | UNDEAD |

### Type Effectiveness Multipliers

- **Super Effective**: 1.5× damage
- **Not Very Effective**: 0.5× damage
- **Immune**: 0× damage

### Status Effects (8 Types)

| Effect | Duration | Effect |
|--------|----------|--------|
| **Stunned** ⚡ | 1 turn | Can't act! Auto-Brace if attacked |
| **Burned** 🔥 | 3 turns | Take 10 damage per turn |
| **Poisoned** ☠️ | 4 turns | Take 8 damage per turn |
| **Slowed** 🐢 | 2 turns | -2 Speed |
| **Cursed** 💀 | 3 turns | -25% ATK |
| **Terrified** 😱 | 2 turns | -25% DEF |
| **Rooted** 🌿 | 2 turns | Can't move |
| **Stealth** 👻 | 3 turns | Next attack is guaranteed crit! |

### Status Immunities

- **Infernal Soul**: Immune to Burned
- **Frost Revenant**: Immune to Slowed
- **Celestial Cleric**: Immune to Cursed
- **Shadow Assassin**: Starts with Stealth

### Positioning Bonuses

| Bonus | Effect | Condition |
|-------|--------|-----------|
| **Flanking** | +3 hit | Ally adjacent to defender |
| **High Ground** | +2 hit, +10% damage | Attack from Hills/Peaks |
| **Cover** | +3 DEF | Defender on Forest/Ruins |
| **Surrounded** | -2 DEF | 3+ enemies adjacent to defender |

### Combat Rules Summary

- Each troop can perform **ONE action per turn** (Move OR Attack, not both)
- Attack requires target to be in range
- Line of sight required for ranged/magic attacks (no biome blocking)
- Air units can attack all ground units
- Only Ranged and Magic ground units can attack air units

### Range & Line of Sight

**Range Calculation:**
- Range counts hex distance (hexagonal distance algorithm)
- Range 1 = adjacent hex only
- Range 2 = up to 2 hexes away
- Range 3 = up to 3 hexes away
- Count from the troop's hex, not adjacent

**Line of Sight:**
- Algorithm: Bresenham line from attacker to target
- **No biome LOS blocking** — all terrain is transparent
- Units do NOT block line of sight
- *Rationale*: Simplified rules, focus on positioning

### Draw vs Tie Rules

- **Draw**: Equal dice rolls → re-roll (max 3×), then defender wins
- **Tie**: Both players eliminated simultaneously = game ends with no winner
- Option to rematch after tie

---


# Biome System

## Biome Modifier System

**Modifier Types:**
- **+A (Advantage)**: +25% damage dealt
- **+S (Strength)**: +15% damage dealt
- **+D (Defense)**: -15% incoming damage
- **-S (Weakness)**: -25% damage dealt

**Rules:**
- Modifiers do NOT stack — use strongest applicable
- All troops can move through all biomes (no movement restrictions)

### Biome-Troop Modifier Table

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

# Economy & Progression

## Starting Resources

- **Starting Gold**: 150
- **Starting XP**: 0

## Gold Mines

### Placement Costs
| Level | Cost |
|-------|------|
| Level 1 (Place) | 100 gold |
| Level 2 | 200 gold |
| Level 3 | 400 gold |
| Level 4 | 800 gold |
| Level 5 | 1600 gold |

### Generation Rates (per turn)
| Level | Gold/Turn |
|-------|-----------|
| Level 1 | 10 |
| Level 2 | 25 |
| Level 3 | 50 |
| Level 4 | 100 |
| Level 5 | 200 |

### Placement Rules
- Max **5 mines** per player
- Minimum **3 hexes** between mines
- Cannot place on **Peaks** biome
- Mines have very little health (destroyed in one hit)
- Uses the placing troop's action

## Troop Upgrades

### Upgrade Costs
| Level | Cost |
|-------|------|
| 1 → 2 | 50 gold + 25 XP |
| 2 → 3 | 100 gold + 50 XP |
| 3 → 4 | 200 gold + 100 XP |
| 4 → 5 | 400 gold + 200 XP |

### Stat Increases Per Level
- **+10% HP** (percentage-based)
- **+5 ATK** (flat)
- **+3 DEF** (flat)

---

# NPC System

## NPC Types

| NPC | HP | ATK | DEF | Gold | XP | Rare Drop |
|-----|-----|-----|-----|------|-----|-----------|
| Goblin | 50 | 30 | 20 | 5 | 10 | Speed Potion (10%) |
| Orc | 100 | 60 | 40 | 15 | 25 | Whetstone (15%) |
| Troll | 200 | 80 | 60 | 30 | 50 | Phoenix Feather (20%) |

## NPC Behavior

- **Spawn Chance**: 5% when any troop moves to a hex
- NPCs do NOT spawn on occupied hexes
- NPCs are **stationary** (do not move)
- NPCs attack nearest player unit in range 2 each turn
- Defeated NPCs do NOT respawn

## Items

- **Speed Potion**: +1 Speed for 3 turns
- **Whetstone**: +10 ATK next attack
- **Phoenix Feather**: Respawn 1 destroyed troop at spawn point

**Inventory Rules:**
- Max 3 consumable items per player
- Using an item costs 1 action
- Items cannot be traded or stolen

## Spawn Points

- **4 spawn hexes per player** at opposing extreme edges (8 total)
- Hexes are 4 straight across at each edge
- All 4 troops spawn immediately at game start (one per spawn hex)
- Respawned troops appear at any available spawn hex on player's side

---

# Multiplayer & Networking

## Implementation

- **Architecture**: Peer-to-Peer (Host acts as Server)
- **Protocol**: Godot High-Level Multiplayer API (ENet)
- **Connection**: IP Direct Connect or LAN discovery

## Synchronization Strategy

- Exchange RNG seed at start for identical board generation
- Use reliable RPCs for turn actions (Move, Attack, End Turn)
- Use `multiplayer.is_server()` checks for authority

## Disconnection Handling

- Player has **3 minutes** to reconnect
- If not reconnected: Automatic win for opponent
- After **3 total disconnections**: Automatic win for opponent
- Game state preserved during disconnection period

---

# New Player Experience (UX)

## Simplified Combat Mode ✅ IMPLEMENTED

For casual players, a Simple Combat mode reduces complexity:

- **Moves**: 4 → 2 (Standard + 1 Special)
- **Damage Types**: 6 → 3 (Physical, Magic, Elemental)
- **Defender Stance**: Auto-selects Brace
- **Timer**: Extended to 15 seconds
- **Display**: Shows STRONG/WEAK/NEUTRAL labels with color coding

## AI Difficulty Settings ✅ IMPLEMENTED

| Difficulty | Behavior |
|------------|----------|
| **Easy** | Uses random moves weighted toward Standard |
| **Normal** | Uses type-effective moves when available |
| **Hard** | Optimal move selection, considers positioning |

## Planned Tutorial System

1. **Tutorial 1**: Basic Attack (only Standard move)
2. **Tutorial 2**: Move Variety (unlock Power move)
3. **Tutorial 3**: Type Effectiveness
4. **Tutorial 4**: Defensive Stances
5. **Tutorial 5**: Positioning
6. **Tutorial 6**: Full Combat

## Planned UI Improvements

- Hit chance percentage display
- Predicted damage range on hover
- Combat log with explanations
- Type effectiveness color-coding on move buttons
- Contextual hints (toggleable)

## UX Implementation Priority

| Priority | Feature | Impact | Effort |
|----------|---------|--------|--------|
| 🔴 HIGH | Combat UI Improvements | High | Medium |
| 🔴 HIGH | Tutorial System | High | High |
| 🟡 MEDIUM | Information Architecture | Medium | Low |
| 🟡 MEDIUM | Combat Feedback Polish | High | Medium |
| 🟢 LOW | Practice Mode | Low | High |
| 🟢 LOW | AI Personality | Medium | Low |

## Quick Wins (Next Steps)

1. **Hit Chance Display** — Show percentage before attack
2. **Type Labels on Moves** — Color-code move buttons by effectiveness
3. **Combat Log** — Explain what happened after each exchange
4. **Contextual Hints** — Help new players during selection phase
5. **Extended Timer Option** — Let struggling players have more time

---

# Asset Integration

## Overview

- **Visual Style**: Grounded High Fantasy (The Witcher 3 lighting aesthetic)
- **Lighting Style**: Witcher 3-inspired — warm firelight, cool moonlight, volumetric fog, and atmospheric depth
- **Quality System**: Granular settings with hardware-adaptive presets
- **Theme**: Realistic medieval materials with prominent magical effects

## Environment Selection System

**User-Selectable Environments**: Players can choose their preferred 3D environment scene when starting a game.

### Available Environments

| Environment | File | Description |
|-------------|------|-------------|
| **Tavern Room 1** | `tavern_room_1.glb` | Cozy medieval tavern interior with warm lighting |
| **Tavern Room 2** | `tavern_room_2.glb` | Larger tavern variant with more elaborate details |

### Environment Selection Rules

- Environment selection happens at **game start** (in pregame lobby)
- Host can select the environment, or both players agree
- Environments are loaded from `res://assets/models/rooms/`
- New environments can be added by placing `.glb` files in the rooms folder

### Future Environments (To Add)

- Castle dining hall
- Forest clearing
- Battlefield tent

## ⚠️ CRITICAL: Character Scaling Rule

**ALL characters MUST maintain a 1:1 realistic scale ratio relative to each other and the environment.**

### Scaling Guidelines

1. **Relative Size**: Characters must be proportionally scaled to each other based on their in-universe size
   - Medieval Knight should be human-sized (~1.8m)
   - Dark Blood Dragon should be MUCH larger than a Knight (5-8x scale)
   - Stone Giant should tower over humanoids (3-4x human scale)
   - Infernal Soul (imp-like) should be smaller than a human (0.6-0.8x scale)

2. **Environmental Consistency**: Characters must be to-scale with environmental objects
   - A Knight should look correct standing next to a tree or rock
   - Dragons should dwarf trees and boulders
   - Small creatures should fit naturally in the environment

3. **Before Adding ANY Model**: Review the scale against existing models
   - Compare new model to Medieval Knight (baseline human reference)
   - Check scale against environmental decorations (trees, rocks, furniture)
   - Adjust import scale in Godot to maintain consistency

### Reference Scale Chart

| Character Category | Size Relative to Knight | Example Characters |
|--------------------|------------------------|--------------------|
| **Small** | 0.5-0.8x | Infernal Soul, Goblins |
| **Human-sized** | 1.0x | Medieval Knight, Shadow Assassin, Elven Archer |
| **Large Humanoid** | 1.5-2.0x | Demon of Darkness, Celestial Cleric |
| **Giant** | 3.0-4.0x | Stone Giant, Troll |
| **Massive Creature** | 5.0-8.0x | Dark Blood Dragon, Four-Headed Hydra |
| **Aerial/Serpent** | 4.0-6.0x (length) | Sky Serpent |

## Hex Tile Specifications

- **Geometry**: 6-sided flat hex, UV unwrapped
- **Dimensions**: 1 unit diameter, 0.05 unit thickness
- **Format**: `.glb` export from Blender
- **LOD Levels**: 3 (100%, 50%, 25%)

**Height Variants:**
- `hex_flat.glb` — 0.0 elevation (Plains, Forest)
- `hex_low.glb` — 0.1-0.2 elevation (Swamp, Wastes)
- `hex_high.glb` — 0.3-0.5 elevation (Peaks, Hills)

## Asset Status

### Textures ✅ DOWNLOADED

All biome, board, and UI textures downloaded (~8.6 GB):
- **Source**: Poly Haven (CC0), AmbientCG (CC0)
- **Format**: 4K PNG with PBR maps (Diffuse, Normal, Roughness, AO, Displacement)
- **Location**: `res://assets/textures/biomes/` and `res://assets/textures/board/`

### 3D Models ✅ IMPLEMENTED (Troops, Dice, Card Art)

| Category | Count | Status |
|----------|-------|--------|
| Troop Models | 12 | ✅ GLB models imported via `CharacterModelLoader` |
| NPC Models | 3 | ⏳ Pending AI generation |
| Gold Mine Models | 5 levels | ✅ Imported in `res://assets/models/mines/` |
| Dice Model | 1 | ✅ `d20-gold.glb` imported |
| Card Art | 15 | ✅ All 12 troop + 3 NPC card art PNGs in `res://assets/textures/cards/` |

### Character Model Integration

- **Loader**: `CharacterModelLoader` (`res://scripts/managers/character_model_loader.gd`)
- **Models Location**: `res://assets/models/characters/`
- **Card Art Location**: `res://assets/textures/cards/`
- **Loading Strategy**: Models are cached on first load; placeholder shapes used as fallback
- **Scale System**: Per-character scale factors in `CharacterModelLoader.MODEL_SCALES`
- **Card Art in UI**: Shown in Deck Selection UI and in-game HUD troop cards

**Polygon Budget:**
- Low: 5,000-8,000 tris
- Medium: 10,000-15,000 tris
- High: 20,000-30,000 tris
- Ultra: 40,000-60,000 tris

## AI Generation Prompts (3D Models)

**Platform Recommendations:**
- **Meshy.ai** — Best for armored humanoids
- **Luma Labs AI** — Best for complex creatures (dragons, hydras)
- **Tripo3D** — Best for simpler creatures (imps, goblins)

### Troop Models (12)

| Troop | Polygon Target | Key Prompt Elements |
|-------|----------------|---------------------|
| Medieval Knight | 15K (Med) | Full plate armor, sword+shield, T-pose, metal textures |
| Stone Giant | 25K (High) | Massive boulder body, moss patches, rough stone skin |
| Four-Headed Hydra | 35K (High) | 4 serpent heads, scaled body, swamp colors |
| Dark Blood Dragon | 30K (High) | Leathery wings, dark red scales, menacing pose |
| Sky Serpent | 20K (Med-High) | Eastern dragon, long serpentine, iridescent scales |
| Frost Valkyrie | 18K (Med) | Nordic armor, feathered wings, frost-touched |
| Dark Magic Wizard | 12K (Med) | Dark robes, glowing staff, pale skin, purple glow |
| Demon of Darkness | 22K (Med-High) | Large horns, muscular, dark magic flames |
| Elven Archer | 10K (Low-Med) | Leather armor, longbow, pointed ears |
| Celestial Cleric | 14K (Med) | White+gold robes, glowing staff, divine aura |
| Shadow Assassin | 9K (Low-Med) | Dark leather, twin daggers, hooded cloak |
| Infernal Soul | 8K (Low) | Imp-like, charred red-black skin, ember glow |

### NPC Models (3)

| NPC | Polygon Target | Key Prompt Elements |
|-----|----------------|---------------------|
| Goblin | 6K (Low) | Green skin, ragged loincloth, crude club |
| Orc | 12K (Med) | Gray-green skin, rusted armor, battle axe |
| Troll | 20K (Med-High) | Stone-like skin, moss, tree trunk club |

### Gold Mine Models (5 levels)

| Level | Description |
|-------|-------------|
| 1 | Simple wooden frame, single bucket |
| 2 | Reinforced wood, pulley system |
| 3 | Stone foundation, multiple buckets |
| 4 | Full stone structure, rail cart |
| 5 | Ornate gold-inlaid stone, glowing effects |

### Card Art (15 images)

- **Style**: Portrait-oriented, dramatic lighting, character-focused
- **Resolution**: 1024×1536 (2:3 aspect ratio)
- **12 Troop cards** + **3 NPC cards**
- Generate matching poses to 3D models

## Animations

### Required Animations (Phase 1)

| Animation | Duration | Notes |
|-----------|----------|-------|
| Idle | Loop | Breathing, subtle movement |
| Attack | 1.5-2 sec | Weapon swing or spell cast |
| Damage | 0.5-1 sec | Flinch reaction |
| Death | 2-3 sec | Collapse, fade out |

**Source**: Mixamo.com (free humanoid animations, retarget to custom rigs)

### Phase 2 Animations (Future)

- Walk/Run cycles
- Victory celebration
- Spell casting variations
- Special ability animations

## Physical Dice System

- **Model**: 20-sided polyhedron (D20)
- **Physics**: RigidBody3D with realistic bounce
- **Materials**: Metal with engraved numbers
- **Collision**: ConvexPolygonShape3D
- **Roll Detection**: Check when angular velocity < threshold

## Audio 🔮 FUTURE

Audio will be added at the **end of MVP development**.

### Music Tracks

| Track | Duration | Loop | Style |
|-------|----------|------|-------|
| Main Menu | 2-3 min | Yes | Epic orchestral, building tension |
| Deck Selection | 1-2 min | Yes | Mysterious, anticipation |
| Gameplay (Calm) | 3-4 min | Yes | Medieval ambiance, lute/strings |
| Gameplay (Tense) | 2-3 min | Yes | Drums, rising stakes |
| Combat | 1-2 min | Yes | Intense, fast-paced |
| Victory | 30 sec | No | Triumphant fanfare |
| Defeat | 30 sec | No | Somber, reflective |

### Sound Effects (SFX)

**UI Sounds:**
- Button click / hover
- Card select / deselect
- Turn start / end chime
- Timer warning (5s, 3s)
- Error / invalid action buzz

**Combat Sounds (Generic):**
- Dice roll (physical dice tumble)
- Dice land (impact)
- Attack miss (whoosh)
- Critical hit (dramatic impact + screen shake)
- Heal (sparkle/chime)

**Movement Sounds:**
- Tile hover (soft click)
- Tile select (confirm chime)

**Economy Sounds:**
- Gold gain (coins clink)
- Gold mine place (construction hammer)
- Upgrade complete (level up chime)

### Character Sound Effects (12 Troops)

Each troop has unique sounds based on their nature:

| Troop | Move | Attack | Damage | Death | Special |
|-------|------|--------|--------|-------|---------|
| **Medieval Knight** | Metal armor clanking | Sword slash, shield bash | Metal impact grunt | Armor collapse, sword drop | Shield block (clang) |
| **Stone Giant** | Heavy thuds, ground shake | Boulder smash, earth rumble | Rock crack | Crumble, rocks falling | Ground slam (earthquake) |
| **Four-Headed Hydra** | Slithering, multiple hisses | Multi-bite snaps, acid spit | Screech per head | Writhing collapse, final hiss | Regeneration (wet growth) |
| **Dark Blood Dragon** | Wing flaps, deep growl | Fire breath roar, claw swipe | Roar of pain | Crash landing, dying roar | Inferno (fire explosion) |
| **Sky Serpent** | Wind whoosh, ethereal hum | Lightning crackle, tail whip | High-pitched cry | Fade into wind | Storm surge (thunder) |
| **Frost Valkyrie** | Wingbeats, ice crystals | Ice lance throw, sword swing | Ice shatter grunt | Feathers scatter, freeze | Blizzard (howling wind) |
| **Dark Magic Wizard** | Robes rustling, staff tap | Dark energy blast, spell chant | Magical disruption | Dark implosion, soul escape | Curse cast (ominous whisper) |
| **Demon of Darkness** | Heavy hooves, fire crackle | Dark flames, demonic roar | Angry growl | Banishment scream, void pull | Hellfire (infernal boom) |
| **Elven Archer** | Light footsteps, quiver rustle | Bow draw, arrow whistle | Light grunt | Arrow clatter, soft fall | Precision shot (slow-mo loose) |
| **Celestial Cleric** | Soft footsteps, holy chime | Staff glow, divine beam | Holy shield absorb | Peaceful exhale, light ascend | Mass heal (choir swell) |
| **Shadow Assassin** | Silent/near-silent | Dagger slice, backstab plunge | Muffled grunt | Shadow dissipate | Stealth (shadow whisper) |
| **Infernal Soul** | Crackling embers, chittering | Fire bolt, imp shriek | High-pitched yelp | Explosion, flame out | Soul burn (demonic laugh) |

### NPC Sound Effects (3 NPCs)

| NPC | Move | Attack | Damage | Death | Loot Drop |
|-----|------|--------|--------|-------|-----------|
| **Goblin** | Scurrying feet, snickering | Club bonk, goblin yell | Squeal | Defeated whimper | Coins scatter |
| **Orc** | Heavy boots, grunt | Axe whoosh, war cry | Angry roar | Death bellow | Armor drop |
| **Troll** | Ground shake, lumber | Tree trunk swing, bellow | Stone crack | Collapse, earthquake | Treasure reveal |

### Ambient Sounds (Per Biome)

| Biome | Ambient Sounds |
|-------|----------------|
| Enchanted Forest | Birds, rustling leaves, magical hum |
| Frozen Peaks | Howling wind, ice cracking |
| Desolate Wastes | Dry wind, distant thunder |
| Golden Plains | Gentle breeze, crickets |
| Ashlands | Crackling embers, volcanic rumble |
| Highlands | Wind gusts, eagle cries |
| Swamplands | Frogs, bubbling water, insects |

### Audio Implementation Notes

- **Format**: OGG Vorbis (compressed, good quality)
- **Sample Rate**: 44.1 kHz
- **Music Bus**: Separate volume slider
- **SFX Bus**: Separate volume slider
- **Integration**: Godot AudioStreamPlayer / AudioStreamPlayer3D

## Quality Presets

| Preset | Target Hardware | Target FPS |
|--------|-----------------|------------|
| **Low** | Work laptops, integrated graphics | 30 |
| **Medium** | Mid-range laptops (GTX 1050-1650) | 60 |
| **High** | Gaming laptops (RTX 2060-3060) | 60 stable |
| **Ultra** | Gaming desktops (RTX 3070+) | 120+ |

### Quality Settings

- Texture Quality (512-4096)
- Model Detail (LOD levels)
- Shadow Quality (Off/Low/Med/High/Ultra)
- Particle Effects (25%-100%)
- Terrain Height Variation (toggle)
- Spell Effect Intensity (slider)
- Anti-Aliasing (Off/FXAA/TAA/MSAA)
- Ambient Occlusion (toggle)
- Bloom/Glow (toggle + intensity)
- VSync (toggle)

---

# UI/UX Design

## Menu Structure

- **Main Menu**: Play, Settings, Help, Credits
- **Deck Selection**: Grid of 12 cards, click 4 to select, 30-second timer
- **Pause Menu**: Resume, Settings, Save, Quit

## In-Game HUD Layout

- **Bottom bar**: Your 4 cards, gold/XP display
- **Corner panels**: Turn indicator, enemy info
- **Minimal overlay** with 3D card table for immersion

## Action Menu

- **Right-click radial menu** on selected troop
- Options: Move, Attack, Place Mine, Upgrade, Use Item, End Turn

**Button States:**
- **Normal** (white): Clickable
- **Disabled** (gray, 50% opacity): Cannot perform (tooltip shows why)
- **Hover** (highlighted border): Shows action details
- **Pressed** (darker shade): Currently clicking

## Keyboard Controls

| Key | Action |
|-----|--------|
| WASD | Camera pan |
| Q/E | Camera rotate |
| Scroll | Zoom |
| 1-4 | Select troop by card slot |
| Space | End turn |
| Esc | Pause menu |

## Damage Numbers

- **Normal hits**: Small, subtle number near unit
- **Big hits (50+)**: Arcade style, larger and punchy
- **Critical (18-20)**: Gold text with "CRITICAL!"
- **Healing**: Soft green, subtle

## Visual Feedback

- Selection highlights on selected troops
- Movement range visualization (blue hexes)
- Attack range visualization (red hexes)
- Hover tooltips (stats, costs, ranges)
- Invalid action: shake + error tooltip
- Team distinction: armor/accent tint recoloring

---

# Visual Design

## Art Style

- **Realistic Fantasy** (like Total War: Warhammer meets The Witcher 3)
- Immersive, impressive visuals
- **Lighting**: Witcher 3-inspired atmospheric lighting with:
  - Warm firelight sources (candles, torches, lanterns)
  - Cool ambient moonlight/skylight
  - Volumetric fog and light shafts
  - Dramatic shadows with soft falloff
  - Time-of-day color grading (optional)

## Biome Visual Style

- 7 biomes with natural terrain flow
- Seamless blend between hexes (faded borders)

## Spawn Zone Appearance

- Stone platform/altar at each spawn point
- Matches board aesthetic

## Troop Models

- Full 3D creatures (living, breathing monsters)
- **⚠️ CRITICAL: 1:1 Realistic Scale Ratio** — See [Character Scaling Rule](#-critical-character-scaling-rule)
- Dragons/giants should be MUCH larger than humanoids (5-8x scale difference)
- Small creatures (imps, goblins) should be smaller than knights
- All characters must be proportional to environmental objects (trees, rocks, furniture)
- Team distinction via armor/accent tint recoloring

## 3D Presentation

**Camera System:**
- Default: Top-down at 45° angle
- Free rotate (mouse drag)
- Zoom levels: Close → Mid → Far (whole board)
- Edge pan or WASD for movement

**Cutscenes:**
- Combat, NPC encounters, victory/defeat
- Toggleable (ON/OFF in settings)
- Speed: Full / Fast (50%) / Skip

**Card Table:**
- Physical 3D cards on ornate wooden table
- Hover: glow effect + stat tooltip
- Click: camera focuses on corresponding troop

---

# Game Rule Clarifications

## Edge Cases

**Hydra Multi-Strike:**
- When Hydra has 3+ adjacent enemies → player chooses which 2 to attack

**Full Inventory:**
- At 3 items, new drop → choose: swap OR leave on hex
- Items left on hex can be picked up by any troop later

**Running Out of Gold:**
- Player can still fight, just can't buy/upgrade
- No passive income beyond mines

**Friendly Fire (Mines):**
- Players cannot attack their own mines

**Cleric Healing:**
- Heals **35 HP** per action, Range 2
- Can heal any friendly unit including itself
- No cooldown (limited by action economy)

---

# Performance Guidelines

## Optimization Strategies

1. **Object pooling**: Reuse troop/mine/NPC nodes
2. **Hex board**: Custom hex grid (avoid 1000+ individual nodes)
3. **Pathfinding**: Cache paths, limit search depth
4. **Rendering**: 3D with LOD for distant objects
5. **Cutscene preloading**: Pre-cache combat animations

## Save/Load System (Future)

- **Format**: JSON (human-readable, debuggable)
- **Location**: `user://saves/` (cross-platform)
- **Auto-save**: Every 5 turns
- **Includes**: Board state, troops, mines, resources, turn number, inventories

---

# Technical Documentation

## Vertex Height System

The terrain uses vertex-based height generation with the following key features:

### Height Calculation

```
Final Height = Base Height + (Noise × Multiplier × Dampening)
```

**Key Parameters:**
- Height Multiplier: 2.0 (was 4.0 before fix)
- Border Dampening: Gradual reduction near edges
- Seamless Borders: Edge tiles clamp to border height

### Biome Base Heights

| Biome | Base Height |
|-------|-------------|
| Plains, Forest | 0.0 |
| Swamp, Wastes | 0.1-0.2 |
| Peaks, Hills, Ashlands | 0.3-0.5 |

### Key Fixes Applied

1. **Additive Height Fix**: Changed from additive to multiplicative noise
2. **Border Seal Fix**: Edge tiles now properly meet the board frame
3. **Height Spike Fix**: Dampening prevents extreme variations
4. **Neighbor Connectivity**: Adjacent tiles share vertex heights for seamless terrain

### Configuration (game_config.gd)

```gdscript
const TERRAIN_HEIGHT_ENABLED: bool = true
const HEIGHT_MULTIPLIER: float = 2.0
const BORDER_DAMPENING_DISTANCE: int = 2
const MINIMUM_EDGE_HEIGHT: float = 0.0
```

---

# Implementation Progress & Roadmap

## 📍 Where You Are Now

> **All core game systems are functional.** The game is playable in a local 2-player session with
> full combat, economy, biomes, and networking. What remains is: bug fixes, completing 3D models,
> adding animations, adding audio, and polishing the overall experience.

### Status Overview

| Category | Status | Completion |
|----------|--------|------------|
| Core Systems (Board, Grid, Data) | ✅ Done | ~95% |
| Gameplay (Game, Turn, Player, Combat) | ✅ Done | ~90% |
| Combat Sub-systems (Damage, Dice, Types) | ✅ Done | ~95% |
| UI Layer (Menus, HUD, Combat UI) | ✅ Done | ~85% |
| Visual & Effects (Lighting, Particles) | ✅ Done | ~75% |
| Environment & Rooms (Tavern, Furniture) | ✅ Done | ~80% |
| Entities (Troops, Mines, NPCs) | ✅ Done | ~90% |
| Networking (P2P, Lobby) | ✅ Done | ~70% |
| Audio | 🔶 Skeleton | ~10% |
| Asset Integration | 🔶 Partial | ~55% |
| Testing | 🔶 Partial | ~30% |
| Polish & QA | ❌ Not Started | 0% |

---

## 🗺️ Development Roadmap — Vertical Slice Strategy

> **Philosophy**: This roadmap prioritizes **micro-wins** and **vertical slices** over sequential phases.
> Each bucket contains self-contained goals you can complete independently for maximum motivation.

```
  🪣 BUCKET 1              🪣 BUCKET 2                🪣 BUCKET 3              🪣 BUCKET 4
  STABILIZATION            KNIGHT SLICE               TROOP ROSTER             WORLD & AMBIENCE
┌────────────────┐      ┌─────────────────┐      ┌──────────────────┐      ┌──────────────────┐
│ • Room builder │      │ Medieval Knight │      │ 8 remaining      │      │ Biome decorations│
│ • Bug fixes    │─────▶│ Model → Scale   │─────▶│ troops (any      │  ◀──▶│ Music & SFX      │
│ • UI polish    │      │ → Animate → SFX │      │ order, each a    │      │ Ambient audio    │
│ • Test gaps    │      │ = Pipeline Proof │      │ vertical slice)  │      │ Audio wiring     │
└────────────────┘      └─────────────────┘      └──────────────────┘      └──────────────────┘
  START HERE              THEN THIS                 ITERATE (parallel)      ANYTIME (parallel)
                       (1:1 Scale Reference)       + 3 NPCs optional
```

---

## ✅ Phase 0 — COMPLETE (What's Already Built)

> Everything listed below is functional and in the codebase today.

### Board & Grid (`scripts/board/`) — 6 scripts

| Component | File | Size | Status | Notes |
|-----------|------|------|--------|-------|
| Hex Board | `hex_board.gd` | 29KB | ✅ Complete | 397-hex generation, tile management, signals |
| Hex Tile | `hex_tile.gd` | 24KB | ✅ Complete | Individual tile behavior, selection, hover states |
| Hex Coordinates | `hex_coordinates.gd` | 11KB | ✅ Complete | Axial coords, neighbor calc, distance, pathfinding (A*) |
| Biome Generator | `biome_generator.gd` | 21KB | ✅ Complete | Procedural 7-biome generation, all biomes guaranteed |
| Biome Materials | `biome_material_manager.gd` | 20KB | ✅ Complete | PBR material loading, texture assignment per biome |
| Board Environment | `board_environment.gd` | 42KB | ✅ Complete | Board frame, edge cliffs, table surface, vertex height variation |

### Data Layer (`data/`) — 5 scripts

| Component | File | Size | Status | Notes |
|-----------|------|------|--------|-------|
| Biome Definitions | `biomes.gd` | 7KB | ✅ Complete | 7 biomes with modifier tables (+A/+S/+D/-S) |
| Card Data | `card_data.gd` | 11KB | ✅ Complete | All 12 troop stat definitions (HP/ATK/DEF/Range/Speed/Mana) |
| Move Data | `move_data.gd` | 27KB | ✅ Complete | All 48 moves (4 per troop × 12 troops) |
| Game Config | `game_config.gd` | 9KB | ✅ Complete | Constants, terrain settings, combat modes, spawn rules |
| Combat Balance | `combat_balance_config.gd` | 11KB | ✅ Complete | Balance tuning values, damage scaling |

### Gameplay Systems (`scripts/gameplay/`) — 6 scripts

| Component | File | Size | Status | Notes |
|-----------|------|------|--------|-------|
| Game Manager | `game_manager.gd` | 22KB | ✅ Complete | Core game state machine, phase transitions, win condition |
| Turn Manager | `turn_manager.gd` | 19KB | ✅ Complete | Turn flow, configurable timer, action tracking per troop |
| Player | `player.gd` | 13KB | ✅ Complete | Player data: gold, XP, inventory (max 3 items), deck |
| Player Manager | `player_manager.gd` | 10KB | ✅ Complete | 2-player management, 4 spawn points per player |
| Combat Manager | `combat_manager.gd` | 32KB | ✅ Complete | Combat flow orchestration, attack initiation, resolution |
| Combat Edge Cases | `combat_edge_cases.gd` | 11KB | ✅ Complete | Hydra multi-strike, draw/tie rules, special interactions |

### Combat Sub-systems (`data/`) — 6 scripts

| Component | File | Size | Status | Notes |
|-----------|------|------|--------|-------|
| Damage Calculation | `damage_calculation.gd` | 9KB | ✅ Complete | `(ATK × Power% × Type Effectiveness) - DEF/2` formula |
| Roll Resolution | `roll_resolution.gd` | 14KB | ✅ Complete | d20 system, crit on 18-20 (2× damage), fumble on natural 1 |
| Type Effectiveness | `type_effectiveness.gd` | 10KB | ✅ Complete | 6 damage types, 1.5×/0.5×/0× multiplier matrix |
| Defensive Stances | `defensive_stances.gd` | 4KB | ✅ Complete | Brace (+3 DEF), Dodge (+5 evasion), Counter (reflect), Endure (survive at 1 HP) |
| Status Effects | `status_effects.gd` | 6KB | ✅ Complete | 8 status types with durations; troop-specific immunities |
| Conditional Reactions | `conditional_reactions.gd` | 14KB | ✅ Complete | Stance-triggered effects: Counter reflect, Endure survival, combo interactions |

### UI Layer (`scripts/ui/`) — 13 scripts

| Component | File | Size | Status | Notes |
|-----------|------|------|--------|-------|
| Start Menu | `start_menu.gd` | 14KB | ✅ Complete | Main menu: Play, Settings, Help, Credits |
| Lobby UI | `lobby_ui.gd` | 25KB | ✅ Complete | Host/join flow, room codes, player ready states |
| Card Selection UI | `card_selection_ui.gd` | 22KB | ✅ Complete | 12-card grid, mana ≤22 validation, 30s timer, role enforcement |
| Game UI (HUD) | `game_ui.gd` | 19KB | ✅ Complete | Bottom card bar, gold/XP display, action radial menu |
| Combat Selection UI | `combat_selection_ui.gd` | 30KB | ✅ Complete | Simultaneous move/stance selection, 10s timer, Simple/Enhanced modes |
| Combat Resolution UI | `combat_resolution_ui.gd` | 15KB | ✅ Complete | Dice results display, damage breakdown, outcome presentation |
| Dice UI | `dice_ui.gd` | 15KB | ✅ Complete | d20 roll animation, crit/miss visual feedback |
| First-Move Dice UI | `first_move_dice_ui.gd` | 15KB | ✅ Complete | Turn-order initiative roll at game start |
| Troop Status UI | `troop_status_ui.gd` | 8KB | ✅ Complete | HP bar, status effect icons, level indicator |
| Move Tooltip UI | `move_tooltip_ui.gd` | 8KB | ✅ Complete | Hover detail: power%, accuracy, cooldown, type |
| Settings Menu | `settings_menu.gd` | 21KB | ✅ Complete | Quality presets, keybinds, volume sliders, display options |
| Medieval Theme Builder | `medieval_theme_builder.gd` | 9KB | ✅ Complete | Programmatic UI theme (fonts, colors, borders, hover states) |
| Theme Generator | `generate_medieval_theme.gd` | <1KB | ✅ Complete | Helper utility for theme resource creation |

### Visual & Effects — 6 scripts + 1 shader

| Component | File | Size | Status | Notes |
|-----------|------|------|--------|-------|
| Lighting Manager | `managers/lighting_manager.gd` | 14KB | ✅ Complete | Witcher 3-style: warm/cool contrast, volumetric, directional + fill |
| Settings Manager | `managers/settings_manager.gd` | 23KB | ✅ Complete | Quality presets (Low→Ultra), persistent save/load of preferences |
| Scene Manager | `managers/scene_manager.gd` | 7KB | ✅ Complete | Scene transitions, async loading |
| Combat Effects | `effects/combat_effects.gd` | 11KB | ✅ Complete | Hit flash, floating damage numbers, crit visual burst |
| Grass System | `effects/grass_system.gd` | 18KB | ✅ Complete | Per-biome grass instancing with custom shader |
| Biome Particles | `effects/biome_particle_emitter.gd` | 6KB | ✅ Complete | Ambient particles per biome (embers, snow, fireflies, etc.) |
| Grass Shader | `shaders/grass_shader.gdshader` | 6KB | ✅ Complete | Wind animation, color variation, distance-based LOD |

### Environment & Rooms (`scripts/environment/`) — 2 scripts (+1 missing)

| Component | File | Size | Status | Notes |
|-----------|------|------|--------|-------|
| Medieval Room | `medieval_room.gd` | 8KB | ✅ Complete | Room scene loading, tavern environment management |
| Medieval Room Setup | `medieval_room_setup.gd` | 25KB | ✅ Complete | Furniture placement, decoration layout, table positioning |
| Physical Room Builder | `physical_room_builder.gd` | — | ⚠️ Missing | Only `.uid` reference file exists — **script not present** |

### Entities (`scripts/entities/`) — 3 scripts

| Component | File | Size | Status | Notes |
|-----------|------|------|--------|-------|
| Troop | `troop.gd` | 25KB | ✅ Complete | HP, ATK, DEF, movement, actions, upgrades, status effects, team color |
| Gold Mine | `gold_mine.gd` | 6KB | ✅ Complete | Placement rules, 5-level generation rates, upgrade costs |
| NPC | `npc.gd` | 9KB | ✅ Complete | Goblin/Orc/Troll behavior, loot drops, spawn-on-move logic |

### Networking (`scripts/network/`) — 1 script

| Component | File | Size | Status | Notes |
|-----------|------|------|--------|-------|
| Network Manager | `network_manager.gd` | 10KB | ✅ Complete | ENet P2P, host/join, reliable RPCs, seed sync |
| Lobby Manager | — | — | ❌ Not Present | Lobby logic is embedded in `lobby_ui.gd`; no standalone manager |

### Audio (`scripts/audio/`) — 1 skeleton script

| Component | File | Size | Status | Notes |
|-----------|------|------|--------|-------|
| Combat Audio Manager | `combat_audio_manager.gd` | 10KB | 🔶 Skeleton | Manager structure exists; **no audio assets** loaded yet |

### Main Entry Point & Utilities

| Component | File | Size | Status | Notes |
|-----------|------|------|--------|-------|
| Main Script | `main.gd` | 61KB (1879 lines) | ✅ Complete | Game entry, camera system (5 views), full input handling, game flow |
| Screenshot Tool | `debug/screenshot_tool.gd` | <1KB | ✅ Complete | Debug screenshot capture utility |

### Testing (`tests/`) — 2 scripts

| Component | File | Size | Status | Notes |
|-----------|------|------|--------|-------|
| Combat System Tests | `combat_system_tests.gd` | 48KB | ✅ Complete | Comprehensive combat formula and edge-case tests |
| Test Runner | `run_combat_tests.gd` | 2KB | ✅ Complete | Test execution harness |

### Scenes (`scenes/`)

| Scene | File | Status | Notes |
|-------|------|--------|-------|
| Main Scene | `main.tscn` (5KB) | ✅ Complete | Root game scene with all system nodes |
| Game Root | `game_root.tscn` (<1KB) | ✅ Complete | Minimal root for scene switching |
| Board Scenes | `board/` (2 files) | ✅ Complete | Hex board scene setup |
| Environment | `environment/` (1 file) | ✅ Complete | Room/environment container |
| UI Scenes | `ui/` (2 files) | ✅ Complete | UI canvas layers |
| Test Scenes | `test/` (3 files) | ✅ Complete | Test harness scenes |

### Assets Already Done

| Category | Count | Status | Location |
|----------|-------|--------|----------|
| Biome Textures (PBR) | 7 biomes × 3 variants | ✅ Complete | `assets/textures/biomes/` |
| Board Frame Textures | 8 material sets (stone, metals) | ✅ Complete | `assets/textures/board/` |
| Table Textures | 8 wood variants (PBR) | ✅ Complete | `assets/textures/board/` |
| Edge Textures | 2 sets (cliff + rock) | ✅ Complete | `assets/textures/board/` |
| Card Art — Troops | **12/12** portraits | ✅ Complete | `assets/textures/cards/` |
| Card Art — NPCs | **3/3** portraits | ✅ Complete | `assets/textures/cards/` |
| Card Type Backgrounds | **7/7** biome card backs | ✅ Complete | `assets/textures/cards/Card Types/` |
| Grass Textures | 5 biome-specific types | ✅ Complete | `assets/textures/effects/` |
| Dark Blood Dragon model | 2 variants (.glb + PBR) | ✅ Complete | `assets/models/characters/` |
| Demon of Darkness model | 1 model (.glb + PBR) | ✅ Complete | `assets/models/characters/` |
| Sky Serpent model | 1 model (.glb) | ✅ Complete | `assets/models/characters/` |
| Gold Mine Models | **5/5** (lvl 1–5) | ✅ Complete | `assets/models/mines/mine_still/` |
| Dice Model (D20) | **1/1** | ✅ Complete | `assets/models/d20-gold.glb` (~5MB) |
| Room Environments | **2/2** tavern rooms | ✅ Complete | `assets/models/rooms/` |
| Room Decoration | **30+ models** | ✅ Complete | `assets/models/room_decoration/` |

**Room Decoration Inventory** (30+ models in `room_decoration/`):
- **Furniture**: ArmChair, GothicBed, GothicCabinet, GothicCommode, GreenChair, Ottoman, Rockingchair, Shelf, Sofa, WoodenChair, WoodenTable, bar_chair_round, gallinera_table, gothic_coffee_table
- **Lighting**: Chandelier (×2 variants), Lantern, brass_diya_lantern, brass_candleholders
- **Decorative**: antique_ceramic_vase, brass_vase (×2), brass_goblets, horse_statue, chess_set, book_encyclopedia_set, fancy_picture_frame (×2)
- **Weapons**: antique_estoc, antique_katana

---

## 🪣 Bucket 1 — Stabilization & Foundation *(Current Priority)*

> **Goal**: Make what exists work perfectly.
> **Theme**: Fix critical blockers, squash bugs, polish UI.
> **Depends on**: Nothing — start here.

### 1A — ⚠️ Critical Blocker

| Task | Details | Priority |
|------|---------|----------|
| **Restore `physical_room_builder.gd`** | Referenced in `main.tscn` line 5 as `ext_resource id="3_room_builder"`. Only `.uid` file exists (`uid://dqjxf7p0ntbec`). **Game will error on launch without this script.** | 🔴 CRITICAL |

**What it probably does** (based on context):
- Likely handles procedural placement/instantiation of room decoration models
- Works with `medieval_room_setup.gd` to build the physical tavern environment
- May handle collision, lighting, or furniture arrangement

---

### 1B — Known Bug Fixes

| # | Issue | Category | Priority |
|---|-------|----------|----------|
| 1 | Visual black line glitch on board border (Z-fighting / mesh gap) | Rendering | 🔴 High |
| 2 | Hex highlight visibility — hover/select highlight sometimes obscured | UX | 🔴 High |
| 3 | Troop positioning gap — troops should stand flush on tiles | Visual | 🔴 High |
| 4 | Keybind configuration — needs reconfiguration/cleanup | Input | 🟡 Medium |
| 5 | Particle system — remove or optimize current particle effects | Performance | 🟡 Medium |

---

### 1C — UI Polish (Quick Wins)

| Task | Details | Micro-Win |
|------|---------|----------|
| Hit chance % display | Show percentage before confirming attack | "Players can see their odds!" |
| Type effectiveness labels | Color-code move buttons by effectiveness | "STRONG/WEAK instantly visible!" |
| Combat log | Explain what happened after each exchange | "No more 'what just happened?'" |
| Contextual hints | Help new players during selection phase | "Tooltips guide decisions!" |
| Extended timer option | Let struggling players have more time | "Accessibility win!" |
| UI Textures | `assets/textures/ui/` folder is empty — create or add assets | "Buttons look premium!" |

---

### 1D — Testing & Cleanup

| Task | Details | Priority |
|------|---------|----------|
| Board/pathfinding tests | Hex grid generation, A* pathfinding, neighbor calc validation | 🟡 Medium |
| UI interaction tests | Deck selection validation, action menu states | 🟢 Low |
| Network tests | RPC reliability, reconnection handling | 🟡 Medium |
| Extract Lobby Manager | Separate lobby logic from `lobby_ui.gd` into standalone `lobby_manager.gd` | 🟢 Low |

---

## 🪣 Bucket 2 — The Medieval Knight: Character Vertical Slice *(The Prototype)*

> **Goal**: Complete ONE character from model → scale → animation → SFX.
> **Theme**: Prove the entire character pipeline end-to-end.
> **Depends on**: Bucket 1A (room builder fix), 1B-3 (troop positioning fix).
> **Why the Knight?**: Human-sized baseline — all other characters scale relative to this.

### 🏆 Micro-Win Checklist: Medieval Knight

- [ ] **2.1** — 3D model generated (platform: **Meshy.ai**, 15K polys)
- [ ] **2.2** — Model imported into Godot (.glb)
- [ ] **2.3** — Scale validated against Medieval Knight (1:1 ratio: **1.0× = ~1.8m**)
- [ ] **2.4** — Scale validated against environment (tavern furniture: chairs, tables)
- [ ] **2.5** — Idle animation added (source: **Mixamo**, loop)
- [ ] **2.6** — Attack animation added (source: **Mixamo**, 1.5–2s, sword swing)
- [ ] **2.7** — Damage animation added (source: **Mixamo**, 0.5–1s, flinch)
- [ ] **2.8** — Death animation added (source: **Mixamo**, 2–3s, collapse)
- [ ] **2.9** — Character SFX added:
  - Move: Metal armor clanking
  - Attack: Sword slash, shield bash
  - Damage: Metal impact grunt
  - Death: Armor collapse, sword drop
  - Special: Shield block (clang)
- [ ] **2.10** — In-game integration test passed (combat loop plays smoothly)

**📐 Scale Reference**: Once complete, the Knight becomes the **1:1 scale baseline** for all future models.

---

### Why This Approach?

Instead of:
```
Model all 12 troops → Animate all 15 characters → Add all SFX
```

You do:
```
Knight: Model → Scale → Animate → SFX → ✅ DONE
```

This gives you:
- **Proof the pipeline works** before committing to 11 more characters
- **Immediate playable feedback** — you can fight with a fully-realized Knight
- **Clear 1:1 scale reference** — all future models compare to "does it look right next to the Knight?"
- **Template for the next 11 characters** — copy this checklist, change the name

---

## 🪣 Bucket 3 — The Troop Roster *(Iterative)*

> **Goal**: Repeat the proven pipeline for the remaining 8 troops.
> **Theme**: Each character is a self-contained vertical slice.
> **Depends on**: Bucket 2 complete (Knight = proven pipeline + scale reference).
> **Flexibility**: Do these in ANY order — pick based on motivation!

### How This Works

Each character below gets the **same Micro-Win Checklist** from Bucket 2. Copy the checklist, swap "Medieval Knight" for the character name, adjust the scale multiplier, and go.

**Order is YOUR choice** — want to do the easy humanoids first? Go for it. Want to tackle the challenging hydra when you're feeling ambitious? Do it. Each completion is a **visible win**.

---

### 3.1 — Stone Giant *(Tests Giant Scaling)*

**Scale**: 3.0–4.0× Knight (~5.4–7.2m tall)  
**Platform**: Meshy.ai (25K polys)  
**Key Challenge**: Giant scaling, ensuring it towers over humanoids  
**SFX**: Heavy thuds, ground shake, boulder smash, rock crack, crumble

---

### 3.2 — Elven Archer *(Humanoid with Prop)*

**Scale**: 1.0× Knight (~1.8m)  
**Platform**: Meshy.ai (10K polys)  
**Key Challenge**: Longbow prop, arrow animations  
**SFX**: Light footsteps, bow draw, arrow whistle, arrow clatter

---

### 3.3 — Shadow Assassin *(Fast & Small)*

**Scale**: 0.9–1.0× Knight (~1.6–1.8m)  
**Platform**: Meshy.ai (9K polys)  
**Key Challenge**: Twin daggers, stealth aesthetic, speed 5 feel  
**SFX**: Silent/near-silent move, dagger slice, backstab plunge, shadow dissipate

---

### 3.4 — Frost Valkyrie *(Wings + Armor)*

**Scale**: 1.2–1.5× Knight (~2.1–2.7m with wings)  
**Platform**: Meshy.ai (18K polys)  
**Key Challenge**: Feathered wings, Nordic armor, frost effects  
**SFX**: Wingbeats, ice crystals, ice lance throw, ice shatter, blizzard howl

---

### 3.5 — Dark Magic Wizard *(Robes + Staff)*

**Scale**: 1.0× Knight (~1.8m)  
**Platform**: Meshy.ai (12K polys)  
**Key Challenge**: Glowing staff, dark magic visual effects  
**SFX**: Robes rustling, staff tap, dark energy blast, spell chant, curse whisper

---

### 3.6 — Celestial Cleric *(Holy Aura)*

**Scale**: 1.1–1.3× Knight (~2.0–2.3m)  
**Platform**: Meshy.ai (14K polys)  
**Key Challenge**: White+gold robes, divine aura glow, healing animations  
**SFX**: Soft footsteps, holy chime, staff glow, divine beam, mass heal choir

---

### 3.7 — Infernal Soul *(Tiny Imp)*

**Scale**: 0.6–0.8× Knight (~1.1–1.4m, imp-like)  
**Platform**: Tripo3D (8K polys)  
**Key Challenge**: Smallest character, charred skin, ember glow  
**SFX**: Crackling embers, chittering, fire bolt, imp shriek, explosion flame-out

---

### 3.8 — Four-Headed Hydra *(Most Complex)*

**Scale**: 6.0–8.0× Knight (~10.8–14.4m, massive serpent)  
**Platform**: Luma Labs AI (35K polys)  
**Key Challenge**: 4 independent serpent heads, creature rig, swamp aesthetic  
**SFX**: Slithering, multiple hisses, multi-bite snaps, acid spit, writhing collapse

---

### 3.9 — NPC Models *(Optional Add-ons)*

You can **interleave these** with the main roster or do them after. Same checklist, lighter SFX needs:

| NPC | Scale | Platform | Key Challenge |
|-----|-------|----------|---------------|
| **Goblin** | 0.7× Knight (~1.3m) | Tripo3D (6K polys) | Green skin, ragged loincloth, crude club |
| **Orc** | 1.2× Knight (~2.1m) | Meshy.ai (12K polys) | Gray-green skin, rusted armor, battle axe |
| **Troll** | 3.5× Knight (~6.3m) | Meshy.ai (20K polys) | Stone-like skin, moss, tree trunk club |

---

### 🎯 Progress Tracker

**Troops Complete**: ☐☐☐☐☐☐☐☐ (0/8)  
**NPCs Complete**: ☐☐☐ (0/3)

**Next Micro-Win**: _______________

---

## 🪣 Bucket 4 — World & Ambience *(Polish Layer)*

> **Goal**: Make the world feel alive with environment decoration, music, and ambient audio.
> **Theme**: Polish layer that enhances immersion.
> **Depends on**: Nothing! Can work on this **in parallel** with Bucket 3.
> **Flexibility**: Pick a sub-goal when you need a break from character work.

**Note**: Character-specific SFX are handled in Buckets 2 & 3 (part of each character's vertical slice). This bucket is for **world-level** audio and decoration.

---

### 4A — Biome Decorations *(From Datapacks)*

| Task | Source | What You'll Get | Target Biomes |
|------|--------|-----------------|---------------|
| Extract Namaqualand assets | `namaqualand.zip` | Desert rocks, arid shrubs, cacti | Ashlands, Desolate Wastes |
| Extract Pine Forest assets | `pine_forest.zip` | Pine trees, forest floor debris, stumps | Enchanted Forest |
| Extract Verdant Trail assets | `verdant_trail.zip` | Lush vegetation, flowers, bushes | Golden Plains, Swamplands, Highlands |
| Scale & place decorations | — | Place in `res://assets/models/environment/` | All biomes |

**Micro-Win**: Each biome extraction/placement is a standalone task — "Ashlands now has desert rocks!"

---

### 4B — Core Music Tracks

| Track | Duration | Loop | Style | When You Hear It |
|-------|----------|------|-------|------------------|
| **Main Menu** | 2–3 min | Yes | Epic orchestral, building tension | "Game feels EPIC from first boot!" |
| **Gameplay (Calm)** | 3–4 min | Yes | Medieval ambiance, lute/strings | "Strategic thinking music!" |
| **Combat** | 1–2 min | Yes | Intense, fast-paced drums | "Combat feels INTENSE!" |
| **Victory** | 30 sec | No | Triumphant fanfare | "I WON! 🎺" |
| **Defeat** | 30 sec | No | Somber, reflective | "Honor in defeat 🎻" |

**Lower Priority**:
- Deck Selection (1–2 min, mysterious anticipation)
- Gameplay Tense (2–3 min, rising stakes variant)

---

### 4C — Essential UI & Combat SFX

These are the **most impactful** sounds — prioritize these first:

| Category | Sounds | Micro-Win |
|----------|--------|----------|
| **Dice** 🎲 | Roll (tumble), land (impact) | "Dice feel PHYSICAL!" |
| **Combat** ⚔️ | Attack hit, attack miss, crit (+shake) | "Every swing has WEIGHT!" |
| **UI** 🖱️ | Button click/hover, card select, turn chime | "Interface feels RESPONSIVE!" |
| **Economy** 💰 | Gold gain (coins), mine place (hammer), upgrade (level-up chime) | "Money sounds satisfying!" |

**Medium Priority**:
- Movement (tile hover soft click, tile select confirm)
- Timer (warning beeps at 5s, 3s)

---

### 4D — Ambient Biome Audio *(Post-MVP / Optional)*

| Biome | Ambient Soundscape | When to Add |
|-------|-------------------|-------------|
| Enchanted Forest | Birds, rustling leaves, magical hum | When you want immersion++ |
| Frozen Peaks | Howling wind, ice cracking | Same |
| Desolate Wastes | Dry wind, distant thunder | Same |
| Golden Plains | Gentle breeze, crickets | Same |
| Ashlands | Crackling embers, volcanic rumble | Same |
| Highlands | Wind gusts, eagle cries | Same |
| Swamplands | Frogs, bubbling water, insects | Same |

**Note**: These are **nice-to-have**. Core music (4B) + UI/Combat SFX (4C) give you 90% of the audio impact.

---

### 4E — Audio Integration

| Task | Details | Micro-Win |
|------|---------|----------|
| Wire up `combat_audio_manager.gd` | Connect skeleton script to actual audio assets | "Audio system ALIVE!" |
| Music playback system | AudioStreamPlayer, bus routing, volume sliders in settings | "Music plays and is controllable!" |
| SFX playback system | AudioStreamPlayer3D for positional combat sounds | "Sound comes from battlefield!" |
| Format all audio | OGG Vorbis, 44.1 kHz, separate music/SFX buses | "Optimized & organized!" |

---

### 🎵 Audio Progress Tracker

**Music Tracks**: ☐☐☐☐☐ (0/5 core)  
**Essential SFX**: ☐☐☐☐ (0/4 categories)  
**Biome Ambient**: ☐☐☐☐☐☐☐ (0/7 optional)  
**Integration**: ☐☐☐☐ (0/4 systems)

---

## 🪣 Bucket 5 — Polish, QA & Final Testing *(Ship-Ready)*

> **Goal**: Transform "it works" into "it's READY."
> **Theme**: No rough edges — ship-quality experience.
> **Depends on**: Buckets 1–4 substantially complete (doesn't need to be 100%).
> **When to do this**: When you have at least 4–6 characters done and want to playtest end-to-end.

---

### 5A — Gameplay Polish

| Task | What This Means | Micro-Win |
|------|----------------|----------|
| Full 2-player playtest sessions | Play complete games, note friction points | "I played a REAL match!" |
| Balance pass | Review combat numbers after seeing real games | "Combat feels FAIR!" |
| Disconnection handling QA | Test 3-min reconnection, 3-disconnect auto-loss | "Network resilience confirmed!" |
| Turn timer edge cases | Timer pause during animations, exact-expiry behavior | "Timer feels RIGHT!" |
| Aggression Bounty validation | Test First Blood, Kill Streak, Revenge Kill, Mine Raider | "Anti-turtle works!" |

---

### 5B — Visual Polish

| Task | What This Means | Micro-Win |
|------|----------------|----------|
| Combat cutscene timing | Smooth camera transitions during combat | "Combat looks CINEMATIC!" |
| Damage number feel | Big hits (>50) feel impactful, crits feel dramatic | "Numbers have PUNCH!" |
| Selection & highlight clarity | Final pass on hex highlight visibility | "I always know what I'm selecting!" |
| LOD tuning | Verify 3-level LOD works at all quality presets | "Performance scales perfectly!" |

---

### 5C — Testing Coverage

| Task | What This Means | Priority |
|------|----------------|----------|
| Board system tests | Hex generation, biome distribution, pathfinding edge cases | 🟡 Medium |
| UI interaction tests | Deck validation, action menu disable states, timer behavior | 🟡 Medium |
| Network tests | RPC reliability, host disconnect, client disconnect, seed sync | 🔴 High |
| Performance profiling | Hit 30/60/120 FPS at Low/Med/High/Ultra presets | 🟡 Medium |

---

## 🔮 Bucket 6 — Post-MVP Enhancements *(FUTURE)*

> **Goal**: Expand the game beyond the initial release.
> **Theme**: New features, not fixes.
> **Depends on**: Buckets 1–5 complete + game shipped.

| Feature | Description | Effort | Priority |
|---------|-------------|--------|----------|
| **Tutorial System** | 6 guided tutorials (basic attack → full combat) | High | 🔴 High |
| **AI Opponents** | Easy/Normal/Hard AI for single-player (logic exists in UX plan) | High | 🔴 High |
| **Practice Mode** | Combat training arena vs AI | Medium | 🟡 Medium |
| **Different Board Sizes** | Options beyond 397-hex board | Medium | 🟡 Medium |
| **Replay System** | Save and playback matches | High | 🟡 Medium |
| **Achievements** | Progression rewards, stat tracking | Medium | 🟢 Low |
| **Save/Load System** | JSON format, `user://saves/`, auto-save every 5 turns | Medium | 🟢 Low |
| **Additional Environments** | Castle throne room, forest clearing, mountain fortress, cave, battlefield tent | Low each | 🟢 Low |
| **Mobile Port** | Touch controls and mobile optimization | Very High | 🟢 Low |

### Out of Scope for MVP

- Spell system
- Gambling/mini-games
- Treasure chests
- Card shop system

---

# Known Issues & Game Design Notes

> **Bug fixes and future features are now tracked in the [Roadmap](#%EF%B8%8F-development-roadmap):**
> - Known bugs → [Phase 1](#%EF%B8%8F-phase-1--bug-fixes--script-fixes-do-next)
> - 3D models → [Phase 2](#%EF%B8%8F-phase-2--remaining-3d-models-then)
> - Animations → [Phase 3](#%EF%B8%8F-phase-3--animations-then)
> - Audio → [Phase 4](#%EF%B8%8F-phase-4--audio-then)
> - Polish & testing → [Phase 5](#%EF%B8%8F-phase-5--polish-qa--final-testing-then)
> - Post-MVP features → [Phase 6](#-phase-6--post-mvp-enhancements-future)

## Aggression Bounty System (Anti-Turtle)

Rewards aggressive play to prevent stalling strategies:

| Bonus | Reward | Trigger |
|-------|--------|--------|
| **First Blood** | +50 Gold | First enemy troop killed in match |
| **Kill Streak** | +25% → +50% → +100% XP | 2nd, 3rd, 4th+ consecutive kills |
| **Revenge Kill** | +25% Gold | Kill the unit that killed your troop |
| **Mine Raider** | +20 Gold | Destroy enemy gold mine |

## Environmental Decoration — Expected Assets

When extracting from datapacks (see [Phase 2.3](#23--environmental-decoration-from-datapacks)):

- **Trees**: Pine, oak, dead trees, stumps
- **Rocks**: Boulders, rock clusters, stone formations
- **Logs**: Fallen logs, cut logs, log piles
- **Vegetation**: Bushes, grass clumps, flowers
- **Ground debris**: Leaves, branches, moss patches

---

# Changelog

## Document Consolidation (2026-02-05)

This PROJECT_BIBLE.md consolidates the following documentation files:

| Original File | Status | Notes |
|---------------|--------|-------|
| `implementation-plan.md` | ✅ Integrated | Core source of truth |
| `asset_integration_master_plan.md` | ✅ Integrated | Asset specs and checklists |
| `combat_guide.md` | ✅ Integrated | Player-facing combat reference |
| `combat-new-player-refactoring-plan.md` | ✅ Integrated | UX improvements for new players |
| `troop-cards-philosophy.txt` | ✅ Integrated | Design philosophy |
| `THINGS TO FIX.txt` | ✅ Integrated | Known issues section |
| `Archive/enhanced-combat-system.md` | ⚠️ Archived | Combat system is implemented |
| `Archive/enhanced-combat-implementation-plan.md` | ⚠️ Archived | 100% complete |
| `VERTEX_HEIGHT_FIX.md` | ✅ Integrated | Technical documentation |
| `VERTEX_TERRAIN_REFACTORING.md` | ⚠️ Superseded | Overlaps with HEIGHT_FIX |

### Redundancies Removed

- **Combat mechanics** duplicated across multiple files — consolidated to single section
- **Troop movesets** listed in both implementation-plan and combat docs — kept in Troops section
- **Vertex height logic** overlapped between two files — kept comprehensive version

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-05 | Initial consolidation of all documentation |
| 1.1 | 2026-02-05 | Full integration: Added UI/UX, Visual Design, Game Rules, Performance, Asset Prompts |
| 1.2 | 2026-02-06 | Lighting overhaul (Witcher 3 style), Environment Selection System, Character Scaling Rules (1:1 ratio), Environmental Decoration Assets roadmap |
| 1.3 | 2026-02-10 | **Implementation Progress overhaul**: Expanded from 30-item checklist to full per-file audit. Fixed asset tracking (card art 15/15, mines 5/5, dice 1/1, troops 3/12). Added system categories: Visual/Effects, Environment, Audio, Managers, Testing, Scenes. Added completion percentages, file sizes, and detailed notes. |
| 1.4 | 2026-02-10 | **Roadmap restructure**: Reorganized Implementation Progress into phased development roadmap (Phase 0–6). Added visual pipeline diagram, dependency chain, time estimates, and priority ordering per phase. Consolidated Known Issues & Future Work into roadmap phases to avoid duplication. |
| 1.5 | 2026-02-11 | **Vertical Slice / Goal-Based Roadmap**: Refactored from sequential Phase 1–5 pipeline to Bucket-based system prioritizing micro-wins. Medieval Knight becomes complete character vertical slice (model→scale→animation→SFX). Each remaining troop is independent goal. Identified `physical_room_builder.gd` as critical blocker (referenced in `main.tscn` but file missing). Buckets 3 & 4 can be worked in parallel. Added reusable Micro-Win Checklist template. |
| 1.7 | 2026-03-01 | **CHANGED: UI/UX Mindmap — Environment Selection entries** (`UI_UX_MENU_MINDMAP.md`): Replaced placeholder "Tavern Room 1 / Tavern Room 2" stubs under `Environment Selection` with the four canonical dynamic background entries that match the Main Menu (`Cozy Tavern`, `Battlefield Tent`, `Dining Hall`, `Deforested Woods`), keeping the mindmap consistent throughout. |
| 1.6 | 2026-02-19 | **CHANGED: Edge Tile Border Seal** (`hex_board.gd` → `_generate_vertex_heights()`): Replaced imprecise 95% radial distance threshold ("ZERO-G BORDER SEAL") with proper perimeter vertex detection. Interior hex vertices are shared by exactly 3 tiles; perimeter vertices by 1–2 tiles. Checking `height_array.size() < 3` now accurately identifies every perimeter vertex and pins it to `0.0`, eliminating the vertical gap between high edge tiles (e.g. Peaks, Ashlands) and the stone border frame. |
| 1.8 | 2026-03-07 | **MAJOR: UI/UX Mindmap comprehensive expansion** (`UI_UX_MENU_MINDMAP.md`): Added 20+ new sections from gap analysis against PROJECT_BIBLE. New: NPC encounter flow, item inventory HUD, gold mine management, spawn placement phase, Help menu, save/load flow, loading/transitions, notification toast system, camera system, visual feedback layer, keyboard shortcuts overlay, aggression bounty notifications, positioning bonuses in combat, draw/re-roll handling, simplified combat mode branch, all 8 status effects, all 6 damage types, all 12 troop options in deck selection, FTUE first-launch flow, match history (🔮), tutorial progress tracking. Added ✅/⏳/🔮 status markers for implementation tracking. |

---

*Fantasy World: The Game — Building the ultimate medieval board game experience!* 🎮⚔️🏰
