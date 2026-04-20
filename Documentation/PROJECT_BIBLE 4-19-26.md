# 🎮 Fantasy World: The Game — Project Bible

> **Single Source of Truth** for the Fantasy World medieval strategy board game project.
> This document consolidates all design decisions, implementation details, and project documentation.

---

## Table of Contents

1. [Overview & Philosophy](#overview--philosophy)
2. [Game Systems Architecture](#game-systems-architecture)
3. [Troops & Cards](#troops--cards)
4. [Combat System](#combat-system)
5. [Biome System](#biome-system)
6. [Economy & Progression](#economy--progression)
7. [NPC System](#npc-system)
8. [Multiplayer & Networking](#multiplayer--networking)
9. [New Player Experience (UX)](#new-player-experience-ux)
10. [Asset Integration](#asset-integration)
11. [UI/UX Design](#uiux-design)
12. [Visual Design](#visual-design)
13. [Game Rule Clarifications](#game-rule-clarifications)
14. [Performance Guidelines](#performance-guidelines)
15. [Technical Documentation](#technical-documentation)
16. [Implementation Progress](#implementation-progress)
17. [Known Issues & Future Work](#known-issues--future-work)
18. [Changelog](#changelog)

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
- **Swamplands** 🌿

All 6 biomes are guaranteed present in every game.

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
2. **Simultaneous Selection Phase** (30 seconds):
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

| NPC    | HP  | ATK | DEF | Gold | XP  | Rare Drop             |
| ------ | --- | --- | --- | ---- | --- | --------------------- |
| Goblin | 50  | 30  | 20  | 5    | 10  | Speed Potion (10%)    |
| Orc    | 100 | 60  | 40  | 15   | 25  | Whetstone (15%)       |
| Troll  | 200 | 80  | 60  | 30   | 50  | Phoenix Feather (20%) |

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

## AI Difficulty Settings ✅ IMPLEMENTED

| Difficulty | Behavior                                      |
| ---------- | --------------------------------------------- |
| **Easy**   | Uses random moves weighted toward Standard    |
| **Normal** | Uses type-effective moves when available      |
| **Hard**   | Optimal move selection, considers positioning |

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

| Environment       | File                | Description                                       |
| ----------------- | ------------------- | ------------------------------------------------- |
| **Tavern Room 1** | `tavern_room_1.glb` | Cozy medieval tavern interior with warm lighting  |

### Environment Selection Rules

- Environment selection happens at **game start** (in pregame lobby)
- Host can select the environment, or both players agree
- Environments are loaded from `res://assets/models/rooms/`
- New environments can be added by placing `.glb` files in the rooms folder

### Future Environments (To Add)

- Castle throne room
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

### 3D Models ⏳ PENDING

| Category | Count | Status |
|----------|-------|--------|
| Troop Models | 12 | Pending AI generation |
| NPC Models | 3 | Pending AI generation |
| Gold Mine Models | 5 levels | Pending AI generation |
| Dice Model | 1 | Pending |
| Card Art | 15 | Pending AI generation |

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

## Audio 

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

| Troop                 | Move                           | Attack                         | Damage             | Death                         | Special                        |
| --------------------- | ------------------------------ | ------------------------------ | ------------------ | ----------------------------- | ------------------------------ |
| **Medieval Knight**   | Metal armor clanking           | Sword slash, shield bash       | Metal impact grunt | Armor collapse, sword drop    | Shield block (clang)           |
| **Stone Giant**       | Heavy thuds, ground shake      | Boulder smash, earth rumble    | Rock crack         | Crumble, rocks falling        | Ground slam (earthquake)       |
| **Four-Headed Hydra** | Slithering, multiple hisses    | Multi-bite snaps, acid spit    | Screech per head   | Writhing collapse, final hiss | Regeneration (wet growth)      |
| **Dark Blood Dragon** | Wing flaps, deep growl         | Fire breath roar, claw swipe   | Roar of pain       | Crash landing, dying roar     | Inferno (fire explosion)       |
| **Sky Serpent**       | Wind whoosh, ethereal hum      | Lightning crackle, tail whip   | High-pitched cry   | Fade into wind                | Storm surge (thunder)          |
| **Frost Valkyrie**    | Wingbeats, ice crystals        | Ice lance throw, sword swing   | Ice shatter grunt  | Feathers scatter, freeze      | Blizzard (howling wind)        |
| **Dark Magic Wizard** | Robes rustling, staff tap      | Dark energy blast, spell chant | Magical disruption | Dark implosion, soul escape   | Curse cast (ominous whisper)   |
| **Demon of Darkness** | Heavy hooves, fire crackle     | Dark flames, demonic roar      | Angry growl        | Banishment scream, void pull  | Hellfire (infernal boom)       |
| **Elven Archer**      | Light footsteps, quiver rustle | Bow draw, arrow whistle        | Light grunt        | Arrow clatter, soft fall      | Precision shot (slow-mo loose) |
| **Celestial Cleric**  | Soft footsteps, holy chime     | Staff glow, divine beam        | Holy shield absorb | Peaceful exhale, light ascend | Mass heal (choir swell)        |
| **Shadow Assassin**   | Silent/near-silent             | Dagger slice, backstab plunge  | Muffled grunt      | Shadow dissipate              | Stealth (shadow whisper)       |
| **Infernal Soul**     | Crackling embers, chittering   | Fire bolt, imp shriek          | High-pitched yelp  | Explosion, flame out          | Soul burn (demonic laugh)      |

### NPC Sound Effects (3 NPCs)

| NPC        | Move                       | Attack                   | Damage      | Death                | Loot Drop       |
| ---------- | -------------------------- | ------------------------ | ----------- | -------------------- | --------------- |
| **Goblin** | Scurrying feet, snickering | Club bonk, goblin yell   | Squeal      | Defeated whimper     | Coins scatter   |
| **Orc**    | Heavy boots, grunt         | Axe whoosh, war cry      | Angry roar  | Death bellow         | Armor drop      |
| **Troll**  | Ground shake, lumber       | Tree trunk swing, bellow | Stone crack | Collapse, earthquake | Treasure reveal |

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

# Implementation Progress

## Core Systems (29/30 Complete)

### Foundation
- [x] Setup project structure
- [x] Hex coordinate system
- [x] Hex board (397 hexes)

### Biome System
- [x] Procedural biome generation
- [x] Biome system (7 types)
- [x] Biome strength effects

### Player & Turn Systems
- [x] Player system
- [x] Turn system

### Card & Troop Systems
- [x] Card system (12 troops)
- [x] Deck validation
- [x] Troop system
- [x] Movement system

### Combat System
- [x] Combat system
- [x] Combat XP rewards

### Economy System
- [x] Gold system
- [x] Gold mine placement
- [x] Gold mine generation
- [x] Gold mine upgrades
- [x] XP system
- [x] Troop upgrades

### NPC System
- [x] NPC system
- [x] NPC XP rewards

### UI Systems
- [x] Game Manager
- [x] Game UI
- [x] Dice UI
- [x] Card selection UI

### Networking
- [x] Network Manager
- [x] Lobby UI
- [x] RPC implementation

### Polish
- [ ] Polish and testing

---

## Asset Integration (53/137 = 39%)

### Textures ✅ COMPLETE
- [x] Biome Textures (35/35)
- [x] Board Textures (8/8)
- [x] UI Textures (10/10)

### 3D Models ⏳ PENDING
- [ ] Troop Models (0/12)
- [ ] NPC Models (0/3)
- [ ] Gold Mine Models (0/5)
- [ ] Dice Model (0/1)
- [ ] Card Art (0/15)

### Animations ⏳ PENDING
- [ ] Core Animations (0/48) — Idle, Attack, Damage, Death per troop

### Phase 2: Polish 🔮 FUTURE
- [ ] Advanced Animations (60+)
- [ ] Particle Effects (20+)
- [ ] Audio Assets (50+)

---

# Known Issues & Future Work

## Known Issues (To Fix)

1. **Visual black line glitch on board border** — Z-fighting or mesh gap issue
2. **Hex highlight visibility** — Hover/select highlight sometimes obscured
3. **Troop positioning gap** — Troops should stand flush on tiles with no gap underneath
4. **Keybind configuration** — Needs reconfiguration/cleanup
5. **Particle system** — Remove or optimize current particle effects

## Future Enhancements (To Add)

1. **Different board sizes** — 397 hex and other options
2. **Tutorial system** — Guided onboarding for new players
3. **Practice mode** — Combat training arena
4. **AI opponents** — Single-player vs AI
5. **Audio system** — Music and sound effects
6. **Replay system** — Save and playback matches
7. **Achievements** — Progression rewards
8. **Mobile port** — Touch controls and mobile optimization
9. **Environmental decoration models** — Add trees, rocks, logs, etc. from biome datapacks

## Environmental Decoration Assets (Soon To Add)

**Priority**: Add 3D models from biome decoration datapacks to enhance scene immersion.

### Available Datapack Sources

| Datapack | Location | Contents |
|----------|----------|----------|
| **Namaqualand** | `biome_decoration (datapacks)/namaqualand.zip` | Desert/arid environment assets |
| **Pine Forest** | `biome_decoration (datapacks)/pine_forest.zip` | Pine trees, forest floor, rocks |
| **Verdant Trail** | `biome_decoration (datapacks)/verdant_trail.zip` | Lush vegetation, trails, nature assets |

### Expected Model Types to Extract

- **Trees**: Pine, oak, dead trees, stumps
- **Rocks**: Boulders, rock clusters, stone formations
- **Logs**: Fallen logs, cut logs, log piles
- **Vegetation**: Bushes, grass clumps, flowers
- **Ground debris**: Leaves, branches, moss patches

### Integration Guidelines

1. Extract needed models from zip datapacks
2. Convert to `.glb` format if necessary
3. **Scale appropriately** — Trees/rocks must be to-scale with characters
4. Place in `res://assets/models/environment/` folder
5. Create scene variants with different decoration densities

## Aggression Bounty System (Anti-Turtle)

Rewards aggressive play to prevent stalling strategies:

| Bonus | Reward | Trigger |
|-------|--------|--------|
| **First Blood** | +50 Gold | First enemy troop killed in match |
| **Kill Streak** | +25% → +50% → +100% XP | 2nd, 3rd, 4th+ consecutive kills |
| **Revenge Kill** | +25% Gold | Kill the unit that killed your troop |
| **Mine Raider** | +20 Gold | Destroy enemy gold mine |

## Out of Scope for MVP

- Spell system
- Gambling/mini-games
- Treasure chests
- Card shop system
- AI opponents (MVP is multiplayer only)

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

---

*Fantasy World: The Game — Building the ultimate medieval board game experience!* 🎮⚔️🏰
