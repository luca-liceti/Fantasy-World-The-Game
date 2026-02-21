# Fantasy World Core Gameplay Implementation Plan

## Project Structure

The game will be built in Godot 4.5 using GDScript. The project structure will be:

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
│   │   ├── hex_coordinates.gd (utility for hex math)
│   │   ├── biome_manager.gd
│   │   └── biome_generator.gd (procedural biome placement)
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
│   └── entities/
│       ├── troop.gd
│       ├── gold_mine.gd
│       ├── npc.gd
│       └── card.gd
  ├── network/
  │   ├── network_manager.gd (handles connections/RPCs)
  │   └── lobby_manager.gd (handles room code/discovery)
├── data/
│   ├── biomes.gd (biome definitions)
│   ├── card_data.gd (12 troop definitions)
│   └── game_config.gd (game constants)
└── assets/
    └── (imported from Documentation folder)
```

## Development Tools

### Godot MCP (Model Context Protocol) Server

Throughout the development and debugging process, you can leverage the **godot-mcp** tool for enhanced productivity. This MCP server provides direct integration with Godot Engine, enabling:

**Available Tools:**
- `mcp_godot_create_scene` - Create new Godot scene files programmatically
- `mcp_godot_add_node` - Add nodes to existing scenes with properties
- `mcp_godot_load_sprite` - Load sprites into Sprite2D nodes
- `mcp_godot_save_scene` - Save changes to scene files
- `mcp_godot_run_project` - Run the Godot project and capture output
- `mcp_godot_stop_project` - Stop the currently running project
- `mcp_godot_launch_editor` - Launch Godot editor for the project
- `mcp_godot_get_project_info` - Retrieve project metadata
- `mcp_godot_get_godot_version` - Check installed Godot version
- `mcp_godot_get_debug_output` - Get current debug output and errors
- `mcp_godot_list_projects` - List Godot projects in a directory
- `mcp_godot_export_mesh_library` - Export scenes as MeshLibrary resources
- `mcp_godot_get_uid` - Get UIDs for files (Godot 4.4+)
- `mcp_godot_update_project_uids` - Update UID references (Godot 4.4+)

**Use Cases:**
- **Scene Creation**: Quickly scaffold new scenes for hex tiles, troops, UI elements
- **Node Management**: Add and configure nodes without manual editor work
- **Testing & Debugging**: Run the project and capture console output for debugging
- **Project Inspection**: Check project structure and metadata
- **Rapid Prototyping**: Create test scenes and configurations programmatically

**Integration Points:**
- Use during Phase 1-3 for rapid scene prototyping (hex board, biomes, UI)
- Leverage for automated testing during Phase 6 (combat system validation)
- Utilize for debugging network synchronization in Phase 14
- Apply for batch scene creation when setting up multiple similar entities (troops, NPCs)

**Example Workflow:**
```gdscript
# Example: Using godot-mcp to create a new troop scene
# 1. Create base scene with mcp_godot_create_scene
# 2. Add CharacterBody3D node with mcp_godot_add_node
# 3. Add MeshInstance3D child node
# 4. Save scene with mcp_godot_save_scene
# 5. Test with mcp_godot_run_project
```

**Note:** The godot-mcp tool is available throughout all implementation phases and can significantly speed up repetitive tasks and debugging workflows.

## Core Systems Implementation

### 1. Hexagonal Board System

**Hex Board (`scripts/board/hex_board.gd`)**
- Generate 397 hexagons in hexagonal pattern (12 hexagons per side)
- Implement axial/cube coordinate system for hex math
- Calculate neighbor relationships between hexes
- Handle hex selection and highlighting
- Store hex data (coordinates, biome, occupants)

**Hex Tile (`scenes/board/hex_tile.tscn` + `scripts/board/hex_tile.gd`)**
- Visual representation of a single hex
- Display biome visuals
- Handle mouse input for selection
- Show/hide highlights for movement/attack ranges

**Hex Coordinates (`scripts/board/hex_coordinates.gd`)**
- Utility class for hex coordinate math (axial/cube)
- Distance calculation between hexes
- Pathfinding algorithms (A* for hex grids)
- Coordinate conversion (pixel to hex, hex to pixel)

### 2. Biome System & Procedural Generation

**Biome Manager (`scripts/board/biome_manager.gd`)**
- Define 7 biome types with unique properties
- Procedural board generation: Generate new board layout for each game
- Biome placement algorithm: Ensure all 7 biomes are present in every board
- Harmonious biome flow: Create natural transitions and clustering
- Visual representation per biome
- Biome-specific properties (movement cost, defense bonus, resource generation, etc.)
- Biome strength/weakness system: Troops gain bonuses/penalties based on biome

**Biome Generator (`scripts/board/biome_generator.gd`)**
- Procedural generation algorithm
- Ensure all 7 biomes are included in every board
- Biome region placement (create clusters of similar biomes)
- Biome adjacency/transition rules
- Distribution algorithm (ensure balanced coverage across 169 hexes)
- Validation: Verify all 7 biomes are present before finalizing board

**Biome Data (`data/biomes.gd`)**
- 7 biome definitions: Enchanted Forest, Frozen Peaks, Desolate Wastes, Golden Plains, Ashlands, Highlands/Rolling Hills, Swamplands
- Visual assets/colors per biome
- Biome adjacency rules and clustering preferences
- Biome strength/weakness modifiers for troops (+A = advantage, +S = strength, +D = defense, -S = weakness)

### 3. Player System

**Player (`scripts/gameplay/player.gd`)**
- Player data (ID, name, team color)
- Gold amount
- XP amount
- Selected cards (4 cards per player, pre-selected with deck-building restrictions)
- Mana cost tracking (deck total should be ≤ 22 mana)
- Troops on board
- Gold mines owned

**Player Manager (`scripts/gameplay/player_manager.gd`)**
- Manage 2 players (1v1 game)
- Initialize players at game start
- Handle player turn order
- Track active player
- Player win/loss conditions
- Deck validation (ensure deck-building rules are followed)

### 4. Turn System

**Turn Manager (`scripts/gameplay/turn_manager.gd`)**
- Track current turn and phase
- Handle turn order (determined by initial dice roll)
- Multiple actions per turn system
- 60-second turn timer (optional, configurable)
- Action queue (move, attack, place mine, upgrade)
- End turn functionality

### 5. Card/Troop System

**Card (`scripts/entities/card.gd`)**
- Card data (name, type, stats, mana cost)
- 12 troop types with stats (HP, ATK, DEF, Range, Speed, Role, Biome Strength)
- Pre-selected cards (4 per player with deck restrictions)
- Card types: Ground Tank, Air/Hybrid, Ranged/Magic, Flex/Support/Assassin
- Card UI representation

**Troop (`scenes/entities/troop.tscn` + `scripts/entities/troop.gd`)**
- Troop instance on board
- Stats: HP, ATK, DEF, Range (1-3), Speed (hexes), Role
- Range types: Melee, Ranged, Magic, Air, Hybrid, Support
- Team/player ownership
- Visual representation on hex
- Spawn position
- Biome strength/weakness modifiers

**Card Data (`data/card_data.gd`)**
- 12 troop definitions with all stats (Clash Royale balanced):

**Ground Tank Role (pick 1):**
  1. Medieval Knight (150 HP, 80 ATK, 130 DEF, Range 1 Melee, Speed 2, Mana 5)
  2. Stone Giant (220 HP, 90 ATK, 150 DEF, Range 1 Melee, Speed 1, Mana 8)
  3. Four-Headed Hydra (200 HP, 120 ATK, 120 DEF, Range 1 Melee, Speed 1, Mana 9) - **Multi-Strike**: attacks 2 adjacent enemies

**Air/Hybrid Role (pick 1):**
  4. Dark Blood Dragon (140 HP, 110 ATK, 70 DEF, Range 2 Air, Speed 4, Mana 8)
  5. Sky Serpent (100 HP, 85 ATK, 60 DEF, Range 2 Air, Speed 5, Mana 5)
  6. Frost Valkyrie (120 HP, 95 ATK, 85 DEF, Range 2 Hybrid, Speed 4, Mana 6) - **Anti-Air**: can attack air units

**Ranged/Magic Role (pick 1) - All have Anti-Air:**
  7. Dark Magic Wizard (75 HP, 100 ATK, 50 DEF, Range 3 Magic, Speed 2, Mana 4) - **Magic**: ignores 25% DEF
  8. Demon of Darkness (130 HP, 120 ATK, 90 DEF, Range 2 Magic, Speed 2, Mana 7) - **Magic**: ignores 25% DEF
  9. Elven Archer (80 HP, 90 ATK, 55 DEF, Range 3 Ranged, Speed 3, Mana 4) - **Anti-Air 2x**: deals double damage to air units

**Flex Role - Support/Assassin (pick 1):**
  10. Celestial Cleric (110 HP, 55 ATK, 100 DEF, Range 2 Support, Speed 2, Mana 5) - **Heal**: 35 HP to ally in range
  11. Shadow Assassin (70 HP, 115 ATK, 45 DEF, Range 1 Melee, Speed 5, Mana 4) - No special (pure glass cannon)
  12. Infernal Soul (60 HP, 85 ATK, 40 DEF, Range 1 Melee, Speed 5, Mana 3) - **Death Burst**: 30 damage to adjacent on death

- Deck-building rules: 1 Ground Tank + 1 Air/Hybrid + 1 Ranged/Magic + 1 Flex
- Mana cost validation (≤ 22 total)

### 6. Movement System

**Movement (in `hex_board.gd` or `game_manager.gd`)**
- Calculate valid movement hexes (based on troop Speed stat)
- Pathfinding between hexes (hex-based A*)
- Move troop action
- Validate movement (check if hex is occupied, movement range)
- No biome movement modifiers (all terrain = same speed)
- Animate troop movement

### 7. Combat System

**Combat Manager (`scripts/gameplay/combat_manager.gd`)**
- Initiate combat (attacker places troop in range of defender)
- Dice rolling system (d20 dice: 1-20 range)
- Combat resolution:
  - Attacker Roll = d20 + ATK stat
  - Defender Roll = d20 + DEF stat
  - If attacker roll > defender roll: Attack succeeds
  - If attacker roll ≤ defender roll: Attack blocked
  - If equal: Re-roll (max 3 times, then defender wins)
- Damage calculation: (ATK - DEF/2), minimum 1
- Determine combat winner
- Apply damage/eliminate troops
- XP rewards for killing enemy troops
- Combat UI with dice animations

**Dice System (`scripts/ui/dice_ui.gd`)**
- Visual dice representation
- Roll animation
- Display rolled value
- Handle multiple dice rolls

### 8. Gold System

**Gold Manager (in `game_manager.gd` or separate)**
- Track player gold amounts
- Gold UI display
- Gold transactions (spending, earning)

**Gold Mine (`scenes/entities/gold_mine.tscn` + `scripts/entities/gold_mine.gd`)**
- Mine placement on hex (max 5 per player, 100 gold cost)
- Mine ownership
- Gold generation: Turn-based (generates at start of each player's turn)
- Gold generation rates: 10/25/50/100/200 gold per turn (levels 1-5)
- Mine upgrade levels (1-5)
- Minimum 3 hexes between mines
- Cannot place on Peaks biome
- Very low health (destroyed in one hit)
- Visual representation

### 9. XP System

**XP Manager (in `game_manager.gd` or separate)**
- Track player XP amounts
- XP gained from killing enemy troops
- XP gained from killing NPCs
- XP UI display
- XP transactions (spending, earning)

### 10. NPC System

**NPC (`scenes/entities/npc.tscn` + `scripts/entities/npc.gd`)**
- NPCs spawn in different biomes
- NPC types per biome (forest spirits, fire elementals, etc.)
- NPC combat system
- NPC XP rewards
- NPC stats and behavior

### 11. Upgrade System

**Upgrade Manager (in `game_manager.gd` or separate)**
- Gold mine upgrades (use XP to upgrade mines)
- Mine upgrade levels and benefits (increased gold generation rate)
- Troop stat upgrades (use gold and XP to upgrade troop stats)
- Stat modification system (HP, ATK, DEF increases)
- Upgrade UI (mines and troops)
- Upgrade validation (check if player has enough gold/XP)

### 12. Game Manager

**Game Manager (`scripts/gameplay/game_manager.gd`)**
- Main game state machine
- Initialize game (player setup, board generation)
- Coordinate between systems
- Handle game flow (start, play, end)
- Win condition checking (defeat all enemy troops)
- Game initialization (dice roll for starting player)

### 13. UI System

**Game UI (`scenes/ui/game_ui.tscn` + `scripts/ui/game_ui.gd`)**
- Main game HUD
- Player info display
- Turn indicator
- Action buttons (move, attack, place mine, upgrade, end turn)
- Card hand display
- Gold/XP display

**Card UI (`scripts/ui/card_ui.gd`)**
- Display selected cards
- Card selection interface (pre-game, 4 cards with deck restrictions)
- Card stats display
- Deck validation UI

**Dice UI (`scripts/ui/dice_ui.gd`)**
- Dice rolling interface
- Dice animation
- Combat dice display

**Gold/XP UI (`scripts/ui/gold_ui.gd`)**
- Gold amount display
- XP amount display
- Gold mine management UI
- Gold generation timer
- Upgrade UI

### 14. Networking System

**Network Manager (`scripts/network/network_manager.gd`)**
- Manage ENetMultiplayerPeer connections (Host/Join)
- Handle player connection/disconnection events
- Synchronize game state (seed, turn, board)
- Manage Remote Procedure Calls (RPCs) for actions
- Handle latency and state reconciliation

**Lobby UI (`scenes/ui/lobby_ui.tscn`)**
- Host game button
- Join game input (IP address/code)
- Player list (lobby)
- Ready state toggle

## Implementation Phases

### Phase 1: Foundation (Critical)
- Set up project structure
- Implement hex coordinate system
- Create basic hex board (397 hexagons, 12 hexagons per side, hexagonal pattern)
- Basic hex tile rendering

### Phase 2: Biome System (Critical)
- Procedural biome generation (ensure all 7 biomes present)
- Harmonious biome flow and clustering
- Visual biome representation
- Biome properties and effects

### Phase 3: Player & Turn System (Critical)
- Player data structure (2 players, gold, XP)
- Player manager (1v1 game)
- Turn system with multiple actions
- Turn order (initial dice roll)
- Basic UI for turn management

### Phase 4: Card & Troop System (Critical)
- Card data structure (12 troop types with all stats)
- Card selection (pre-game, 4 cards with deck restrictions)
- Deck validation (1 Ground Tank, 1 Air/Hybrid, 1 Ranged/Magic, 1 Flex, mana ≤ 22)
- Troop spawning
- Troop representation on board
- Troop stats and properties

### Phase 5: Movement System (Critical)
- Movement range calculation (based on Speed stat)
- Pathfinding (hex-based A*)
- Movement validation
- Move troop action
- No biome movement modifiers (all terrain = same speed)

### Phase 6: Combat System (Critical)
- Combat initiation (range check, line of sight)
- Dice rolling system (d20: 1-20 range)
- Combat resolution logic (attacker vs defender rolls with stat modifiers)
- Damage calculation (ATK - DEF/2, minimum 1)
- Air vs ground combat rules
- Combat UI

### Phase 7: Gold System (Important)
- Gold tracking per player
- Gold display in UI

### Phase 8: Gold Mine System (Important)
- Gold mine placement (max 5 per player)
- Gold mine generation timer (60 seconds)
- Gold mine UI

### Phase 9: XP System (Important)
- XP tracking per player
- XP gained from killing enemy troops
- XP display in UI

### Phase 10: NPC System (Important)
- NPCs spawn in different biomes
- NPC types per biome
- NPC combat system
- NPC XP rewards

### Phase 11: Upgrade System (Important)
- Gold mine upgrades (use XP)
- Troop stat upgrades (use gold and XP)
- Upgrade UI
- Stat modification system

### Phase 12: Game Flow (Important)
- Game initialization
- Win condition checking
- Game state management
- Game manager coordination

### Phase 13: UI Systems (Important)
- Main game UI
- Card selection UI
- Dice UI
- Gold/XP UI

### Phase 14: Networking (Critical)
- NetworkManager implementation (Host/Join)
- Lobby UI
- RPC conversions for all game actions (Move, Attack, etc.)
- State synchronization (Board sync, Random seed sync)
- Testing connection and latency handling

### Phase 14: Biome Strength Effects (Nice to Have)
- Troops gain bonuses/penalties based on biome
- Biome strength/weakness calculations

### Phase 15: Polish & Testing (Nice to Have)
- UI polish
- Animations
- Error handling
- Game flow testing
- Bug fixes
- Performance optimization

## TODO List (Prioritized)

1. ✅ **setup-project** - Set up project structure: create folders (scenes/, scripts/, data/, assets/), organize Documentation assets
2. ✅ **hex-coordinates** - Implement hex coordinate system utility (axial/cube coordinates, distance, neighbors, pixel conversion)
3. ✅ **hex-board** - Create hex board system: generate 169 hexagons (8 hexagons per side) in hexagonal pattern, hex tile scene and script
4. ✅ **biome-procedural** - Implement procedural biome generation: ensure all 7 biomes present, harmonious biome flow, biome regions and clustering
5. ✅ **biome-system** - Implement biome system: define 7 biome types with properties, visual representation, biome effects
6. ✅ **player-system** - Create player system: Player class, PlayerManager for 2 players (1v1), player data (gold, XP, cards, troops)
7. ✅ **turn-system** - Implement turn system: TurnManager with multiple actions per turn, turn order (initial dice roll), turn timer
8. ✅ **card-system** - Create card system: Card data structure with 12 troop types (all stats: HP, ATK, DEF, Range, Speed, Mana), card selection (pre-game, 4 cards)
9. ✅ **deck-validation** - Implement deck validation: 1 Ground Tank, 1 Air/Hybrid, 1 Ranged/Magic, 1 Flex/Support/Assassin, mana total ≤ 22
10. ✅ **troop-system** - Implement troop system: Troop class with stats (HP, ATK, DEF, Range, Speed), troop spawning, visual representation on board
11. ✅ **movement-system** - Create movement system: pathfinding (hex A*), movement range based on Speed stat, move validation, move action
12. ✅ **combat-system** - Implement combat system: combat initiation (adjacent troops), dice rolling (d20), combat resolution (attacker vs defender), damage application
13. ✅ **gold-system** - Create gold system: gold tracking per player, gold display in UI
14. ✅ **gold-mine-placement** - Implement gold mine placement: allow players to place mines on hexes (max 5 per player), mine placement validation
15. ✅ **gold-mine-generation** - Implement gold mine generation: mines generate gold at configurable rate (turn-based), gold generation at turn start
16. ✅ **xp-system** - Create XP system: XP tracking per player, XP display in UI
17. ✅ **combat-xp-rewards** - Implement XP rewards from combat: XP gained from killing enemy troops
18. ✅ **npc-system** - Implement NPC system: NPCs spawn in different biomes, NPC types per biome, NPC combat, NPC stats and behavior
19. ✅ **npc-xp-rewards** - Implement NPC XP rewards: XP gained from killing NPCs in biomes
20. ✅ **gold-mine-upgrades** - Implement gold mine upgrades: use XP to upgrade mines, mine upgrade levels and benefits (increased gold generation rate), upgrade UI
21. ✅ **troop-upgrades** - Implement troop stat upgrades: use gold and XP to upgrade troop stats (HP, ATK, DEF), upgrade UI, stat modification system
22. ✅ **game-manager** - Implement GameManager: game state machine, initialization, win conditions (defeat all enemy troops), coordinate all systems
23. ✅ **game-ui** - Create main game UI: HUD, player info, turn indicator, action buttons, card display, gold/XP display
24. ✅ **dice-ui** - Implement dice UI: visual dice representation, roll animation, combat dice display
25. ✅ **card-selection-ui** - Create card selection UI: pre-game deck builder (4 cards), deck validation UI, mana cost display
26. ✅ **biome-strength-effects** - Implement biome strength/weakness effects: troops gain bonuses/penalties based on biome (e.g., Forest +A, Ashlands +S)
27. ✅ **network-manager** - Implement NetworkManager: ENet setup, Host/Join functions, connection signals, RNG seed syncing
28. ✅ **lobby-ui** - Create Lobby UI: Host/Join buttons, IP input, Ready system for starting game
29. ✅ **rpc-implementation** - Convert actions to RPCs: Update Move, Attack, End Turn to use `@rpc` annotations for network sync
30. ⏳ **polish-testing** - Polish and testing: UI polish, animations, error handling, game flow testing, bug fixes, performance optimization

## Technical Considerations

- **Hex Coordinate System**: Use axial coordinates (q, r) for hex grid math
- **Pathfinding**: Implement A* algorithm adapted for hexagonal grids
- **State Management**: Use a state machine pattern for game states
- **Signal System**: Use Godot's signal system for communication between systems
- **Data Persistence**: Use Resources for card/biome data
- **Asset Import**: Import images from Documentation folder as textures
- **Performance**: Use object pooling for troops/mines/NPCs if needed
- **UI Scaling**: Design UI to work with different screen sizes
- **Networking**: Use Godot's High-Level Multiplayer API (ENet)
  - Authority: Server-authoritative logic for critical calculations (combat/rng)
  - State Sync: RPCs for actions, reliable for game state, unreliable for fast visual updates
  - Seed Sync: Sync RNG seed at start for deterministic procedural generation

## Assets to Import

From Documentation folder:
- Gold coin images (100, 500, 1000, 5000)
- Board reference image
- Card images (GAME CARDS.png)
- Logo images
- Roulette images (for future use)

## Configuration

**Game Config (`data/game_config.gd`)**
- Number of players: 2 (1v1)
- Turn timer duration: 60-120 seconds (1-2 minutes, configurable)
- Gold generation rate: Turn-based (see Finalized Game Rules)
- Maximum gold mines per player: 5
- Board size: 397 hexagons (12 hexagons per side)
- Dice type: d20 (1-20 range)
- Starting gold: 150
- Starting XP: 0
- XP rewards: From killing enemy troops and NPCs (see Finalized Game Rules)

## Finalized Game Rules & Decisions

This section documents all finalized design decisions and game rules that must be implemented.

### Turn Structure

**Decision: One action per troop per turn**

- Each player can perform one action per troop per turn
- Actions available: Move, Attack, Place Mine, Upgrade, Use Item (Phoenix Feather)
- Each troop can perform one action per turn (move OR attack OR place mine OR upgrade)
- Turn passes when player manually ends turn or all actions are used
- **Rationale**: Better strategic depth, fairer time usage, prevents one player from moving everything while the other waits

### Combat System

**🆕 ENHANCED COMBAT SYSTEM (D&D × Pokémon Hybrid)**

The combat system has been upgraded to feature simultaneous move/stance selection, type effectiveness, and status effects.

**Combat Flow:**
1. Attacker initiates combat by selecting a target
2. **Simultaneous Selection Phase** (10 seconds):
   - Attacker chooses a **Move** (4 unique moves per troop)
   - Defender chooses a **Defensive Stance** (Brace, Dodge, Counter, Endure)
3. Selections revealed simultaneously
4. Dice rolled, modifiers applied, damage calculated

**Dice System:**
- Dice type: **d20** (1-20 range)
- Attacker Roll = d20 + ATK stat + Move Accuracy + Position Bonuses
- Defense DC = 10 + DEF stat + Stance Bonus + Position Bonuses
- If attacker roll > Defense DC: Attack succeeds
- If attacker roll ≤ Defense DC: Attack misses

**Critical Hits/Misses:**
- **Natural 18-20**: Critical Hit! Double damage!
- **Natural 1**: Critical Miss! Automatic miss!

**Damage Formula:**
- If attack succeeds: Damage = (ATK × Power% × Type Effectiveness) - DEF/2
- Damage is always at least 1
- Critical hits deal 2× damage

**Move Types (4 per troop):**
- **Standard**: 100% power, +0 accuracy, no cooldown
- **Power**: 150% power, -3 accuracy, 3-turn cooldown
- **Precision**: 80% power, +5 accuracy, 2-turn cooldown
- **Special**: 120% power, effect chance, 4-turn cooldown

**Defensive Stances:**
- **Brace**: +3 DEF, take 20% less damage
- **Dodge**: +5 Evasion (adds to DC)
- **Counter**: If missed, deal 50% ATK back to attacker
- **Endure**: Survive at 1 HP (once per combat)

**Type Effectiveness (6 damage types):**
- Physical ⚔️, Fire 🔥, Ice ❄️, Dark 🌑, Holy ✨, Nature 🌿
- Super Effective: 1.5× damage
- Not Effective: 0.5× damage
- Immune: 0× damage

**Status Effects (8 types):**
- Stunned, Burned, Poisoned, Slowed, Cursed, Terrified, Rooted, Stealth
- Applied by Special moves with effect chance
- Tick at turn start (DoT effects)

**Positioning Bonuses:**
- Flanking: +3 hit (ally adjacent to defender)
- High Ground: +2 hit, +10% damage (from Hills/Peaks)
- Cover: +3 DEF (defender on Forest/Ruins)
- Surrounded: -2 DEF (3+ enemies adjacent)

**See:** `Documentation/enhanced-combat-system.md` for full details
**See:** `Documentation/combat_guide.md` for player guide

---

**Legacy Combat (Fallback):**
- Dice type: **d20** (1-20 range)
- Attacker Roll = d20 + ATK stat
- Defender Roll = d20 + DEF stat
- If attacker roll > defender roll: Attack succeeds
- If attacker roll ≤ defender roll: Attack is blocked (no damage)
- If rolls are equal: Re-roll (maximum 3 re-rolls)
- If still equal after 3 re-rolls: Defender wins (defensive advantage)

**Combat Rules:**
- Each troop can perform ONE action per turn (Move OR Attack, not both)
- Troops can only attack once per turn
- Attack requires target to be in range
- Line of sight required for ranged/magic attacks
- Air units can attack all ground units
- Only Ranged (Elven Archer) and Magic (Dark Magic Wizard, Demon of Darkness) ground units can attack air units
- Melee units (Knight, Hydra, Giant, Assassins) cannot attack air units

### Range & Line of Sight

**Range Calculation:**
- Range counts hex distance (hexagonal distance algorithm)
- Range 1 = adjacent hex only
- Range 2 = up to 2 hexes away
- Range 3 = up to 3 hexes away
- Count from the troop's hex, not the hex next to it

**Line of Sight:**
- Algorithm: Bresenham line algorithm from attacker hex to target hex
- **No biome LOS blocking** - all terrain is transparent for ranged attacks
- Units (friendly or enemy) do NOT block line of sight
- **Rationale**: Simplified rules, focus on positioning rather than terrain complexity

### Biome Modifier System

**Modifier Types:**
- **+A (Advantage)**: +25% damage dealt
- **+S (Strength)**: +15% damage dealt
- **+D (Defense)**: -15% incoming damage (reduces damage taken, not damage dealt)
- **-S (Weakness)**: -25% damage dealt

**Modifier Rules:**
- Modifiers do NOT stack - use the strongest applicable modifier
- Modifiers apply to damage calculation after base damage is calculated
- All troops can move through all biomes (no movement restrictions)
- Each troop has biomes where they gain strength AND biomes where they lose strength (balanced)

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

**Modifier Legend:**
- **+A (Advantage)**: +25% damage dealt (strong affinity)
- **+S (Strength)**: +15% damage dealt (moderate affinity)
- **+D (Defense)**: -15% incoming damage (defensive affinity)
- **-S (Weakness)**: -25% damage dealt (hostile environment)
- **—**: No modifier (neutral terrain)
- Biome modifiers affect combat effectiveness, making positioning strategic

### Economy System

**Starting Resources:**
- Starting Gold: **150**
- Starting XP: **0**

**Gold Mine Costs:**
- Level 1 mine: **100 gold** (initial placement)
- Level 2 upgrade: **200 gold**
- Level 3 upgrade: **400 gold**
- Level 4 upgrade: **800 gold**
- Level 5 upgrade: **1600 gold**

**Gold Mine Generation:**
- Mines generate gold at the start of each player's turn (both players)
- Level 1: **10 gold/turn**
- Level 2: **25 gold/turn**
- Level 3: **50 gold/turn**
- Level 4: **100 gold/turn**
- Level 5: **200 gold/turn**
- **Rationale**: Turn-based generation is predictable. Both players benefit from their mines each turn. Exponential returns reward investment

**Mine Placement Rules:**
- Cost: 100 gold to place
- Can place multiple mines (max 5 per player)
- Minimum 3 hexes between mines
- Can place on any biome except Peaks (too rocky)
- Uses the placing troop's action
- Mines have very little health and can be destroyed with one hit from any troop
- Mines cannot defend against attacks

### Upgrade System

**Upgrade Costs (per level):**
- Level 1 → 2: **50 gold + 25 XP**
- Level 2 → 3: **100 gold + 50 XP**
- Level 3 → 4: **200 gold + 100 XP**
- Level 4 → 5: **400 gold + 200 XP**

**Stat Increases per Level:**
- **+10% HP** (percentage-based, scales with unit)
- **+5 ATK** (flat increase)
- **+3 DEF** (flat increase)

**Upgrade Rules:**
- Maximum level: **5**
- Can upgrade during your turn (uses action)
- Upgrades cannot be undone
- **Rationale**: Exponential costs create meaningful choices. Percentage HP scales with unit. Flat ATK/DEF are predictable

### Support Healing (Celestial Cleric)

**Healing Mechanics:**
- Heals **35 HP** per action
- Range: **2 hexes**
- Can heal any friendly unit (including itself)
- Uses the troop's action (can't move and heal same turn)
- No cooldown, but limited by action economy
- **Rationale**: 30 HP is meaningful but not overpowered. Range 2 keeps positioning relevant. Self-heal allows survival

### NPC System

**NPC Types and Loot:**
| NPC | HP | ATK | DEF | Gold | XP | Rare Drop |
|-----|-----|-----|-----|------|-----|------|
| Goblin | 50 | 30 | 20 | 5 | 10 | Speed Potion (10%) - +1 Speed for 3 turns |
| Orc | 100 | 60 | 40 | 15 | 25 | Whetstone (15%) - +10 ATK next attack |
| Troll | 200 | 80 | 60 | 30 | 50 | Phoenix Feather (20%) - Respawn 1 troop |

**NPC Spawning:**
- Spawn chance: **5%** when ANY troop moves to a hex (including revisited hexes)
- **NPCs cannot spawn on occupied hexes** - if spawn triggered on occupied hex, no NPC appears
- No fog of war - all hexes visible, but NPCs can spawn anytime
- NPCs do NOT move (stationary)
- NPCs attack nearest player unit in range 2 each turn
- Defeated NPCs do NOT respawn
- NPCs do NOT attack each other

**Player Inventory:**
- Max 3 consumable items
- Using an item costs 1 action
- Items cannot be traded or stolen

### Respawn System

**Phoenix Feather (Respawn Item):**
- Rare drop from defeating **Troll NPCs** (20% drop chance)
- When used (takes action): Respawns one destroyed troop at a spawn point
- Each player can hold max **1 feather** at a time
- Cannot be stolen by enemies
- Appears in player inventory when obtained
- **Rationale**: Rare but meaningful. Troll-only drop creates a goal. Single use and inventory limit prevent abuse

**Spawn Points:**
- 4 spawn hexes per player at the **extreme edges** of the board (opposite sides)
- Spawn hexes are 4 hexes straight across at each player's edge
- All 4 troops spawn immediately at game start (one per spawn hex)
- Respawned troops appear at any available spawn hex on player's side

### Turn Timer

**Timer Rules:**
- Turn timer: **1-2 minutes** (agreed before game starts)
- When timer expires: Player loses remaining actions for that turn, turn immediately passes to opponent
- No penalty beyond lost actions
- Timer pauses during combat animations and UI interactions (upgrade menu, etc.)
- **Movement is always free** - even with 0 gold/XP, players can always move their troops
- **Rationale**: Prevents stalling. No extra penalty keeps it fair. Pausing during animations/UI avoids frustration

### Win/Loss Conditions

**Win Condition:**
- Defeat all enemy troops

**Draw vs Tie:**
- **Draw**: Equal dice rolls in combat (re-roll up to 3 times, then defender wins)
- **Tie**: Both players eliminated simultaneously OR both players have 0 troops at turn end
- Tie results in game end with no winner, option to rematch

### Board Generation

**Board Specifications:**
- Board size: **397 hexagons** (12 hexagons per side, hexagonal pattern)
- Procedural generation for each game

**Biome Distribution:**
- 20% Plains
- 15% Forest
- 15% Hills
- 12% Swamp
- 12% Ashlands
- 10% Peaks
- 10% Wastes
- 6% special biomes

**Spawn Points:**
- 4 spawn hexes per player at opposing extreme edges (8 total)
- Hexes are 4 straight across at each edge
- Biomes placed with weighted random, ensuring each player has access to diverse terrain
- **Rationale**: Procedural keeps games varied. 397 hexes (12 per side) provides epic-scale battles with strategic depth. Weighted distribution ensures balance

### Deck Selection

**Selection Rules:**
- Each player selects 4 cards from the full 12-card pool
- Selection happens **simultaneously** (can't see opponent's selection until both confirm)
- Each player can pick any cards (duplicates allowed if both want same card)
- Selection happens in a separate screen before board setup
- **30-second selection timer**
- **Rationale**: Simultaneous selection prevents copying. Duplicates allowed keeps it simple. Timer prevents stalling

### Save/Load System

**Save Format:**
- **JSON format** (human-readable, debuggable)
- Save location: `user://saves/` in Godot (cross-platform)

**Save Data Includes:**
- Board state (hexes, biomes)
- All troop positions/stats/levels
- All mine positions/levels
- Player resources (gold/XP)
- Turn number
- Current player
- NPC positions/stats
- Player inventories (Phoenix Feathers)
- Game settings (turn timer)

**Save Rules:**
- Auto-save every 5 turns
- Manual save available
- **Rationale**: JSON is human-readable and debuggable. Godot's `user://` is cross-platform. Auto-save prevents data loss

### UI/UX Decisions

**Main Menu Structure:**
- Play, Settings, Help, Credits
- Standard menu flow

**Deck Selection Screen:**
- Grid of 12 cards, click 4 to select
- Show mana cost total, validate ≤22
- 30-second selection timer

**In-Game HUD Layout (Hybrid):**
- Bottom bar: Your 4 cards, gold/XP display
- Corner panels: Turn indicator, enemy info
- Minimal overlay, 3D card table for immersion

**Action Menu:**
- Right-click radial menu on selected troop
- Options: Move, Attack, Place Mine, Upgrade, Use Item, End Turn

**Action Button States:**
- **Normal** (white, clickable): Can perform action
- **Disabled** (gray, 50% opacity, not clickable): Cannot perform (shows tooltip why)
- **Hover** (highlighted border, tooltip): Mouse over, shows action details
- **Pressed** (darker shade): Currently clicking

**Damage Numbers (Hybrid Style):**
- Normal hits: Subtle, small number near unit
- Big hits (50+ damage): Arcade style, larger and punchy
- Critical dice (18-20): Gold text with "CRITICAL!"
- Healing: Soft green, subtle

**Visual Feedback:**
- Selection highlights on selected troops
- Movement range visualization (blue hexes)
- Attack range visualization (red hexes)
- Hover tooltips (stats, costs, ranges)
- Invalid action feedback (shake UI element, error tooltip)
- Team distinction via armor/accent tint recoloring

**Keyboard Controls:**
| Key | Action |
|-----|--------|
| WASD | Camera pan |
| Q/E | Camera rotate |
| Scroll | Zoom |
| 1-4 | Select troop by card slot |
| Space | End turn |
| Esc | Pause menu |

**Pause Menu:**
- Resume, Settings, Save, Quit

**Settings Menu:**
- Music volume
- SFX volume
- Cutscene speed (Full/Fast/Skip)
- Turn timer (1min/2min/Off)
- Resolution/Fullscreen

### Multiplayer Decision

**Decision: Networked Multiplayer (ENet)**

- **Implementation**: Godot High-Level Multiplayer API (ENet)
- **Architecture**: Peer-to-Peer (Host acts as Server)
- **Connection**: IP Direct Connect (simplest) or LAN discovery
- **Rationale**: User requested networked play. ENet is built-in, efficient, and sufficient for 1v1 turn-based strategy.
- **Sync Strategy**:
  - Exchange RNG seed at start for identical board generation
  - Use reliable RPCs for turn actions (Move, Attack, End Turn)
  - Use `multiplayer.is_server()` checks for authority

**Disconnection Handling (Future Online Mode):**
- Player has **3 minutes** to reconnect after disconnection
- If player does not reconnect within 3 minutes: Automatic win for opponent
- After **3 total disconnections** in a single match: Automatic win for opponent (regardless of reconnection)
- Disconnection timer visible to both players
- Game state preserved during disconnection period

### Aggression Bounty System

**Anti-Turtle Mechanic:** Rewards aggressive play to prevent stalling strategies.

| Bonus | Reward | Trigger |
|-------|--------|--------|
| **First Blood** | +50 Gold | First enemy troop killed in match |
| **Kill Streak** | +25% → +50% → +100% XP | 2nd, 3rd, 4th+ consecutive kills |
| **Revenge Kill** | +25% Gold | Kill the unit that killed your troop |
| **Mine Raider** | +20 Gold | Destroy enemy gold mine |

**Rationale**: Positive rewards for aggression rather than punishment for passivity.

### 3D Presentation

**Camera System:**
- **Default Starting Position**: Top-down at **45-degree angle** looking down at board center
- Free rotate 3D with orbit controls (mouse drag to rotate)
- Zoom levels: Close (tactical) → Mid (overview) → Far (whole board)
- Edge pan or WASD for camera movement

**Cutscene System:**
| Event | Duration | Effect |
|-------|----------|--------|
| Commencing Battle | 3-5 sec | Zoom to attacker/defender, dice roll animation |
| NPC Encounter | 2-3 sec | NPC emerges from terrain, camera shake |
| Attack Landing | 1-2 sec | Slow-mo impact, damage numbers, screen flash |
| Troop Death | 2-3 sec | Collapse animation, particle effects, fade out |
| Victory/Defeat | 5-8 sec | Cinematic celebration/defeat sequence |

- Cutscenes toggleable in settings (ON/OFF)
- Speed options: Full / Fast (50%) / Instant Skip

**Card Presentation (3D Card Table):**
- Physical 3D cards on ornate wooden table surface near board
- Cards have depth, lighting, shadows, subtle hover animations
- Click card → camera briefly focuses on corresponding troop
- Hover → glow effect and stat tooltip
- Selected card → lifts slightly with highlight ring

### Visual Design Specifications

**Art Style:**
- Realistic Fantasy (like Total War: Warhammer)
- Immersive, impressive visuals

**Biome Visual Style:**
- 7 biomes: Enchanted Forest, Frozen Peaks, Desolate Wastes, Golden Plains, Ashlands, Highlands, Swamplands
- Seamless blend between hexes (natural terrain flow, faded hex borders)

**Spawn Zone Appearance:**
- Stone platform/altar at each spawn point
- Matches board aesthetic

**Troop Models:**
- Full 3D creatures (living, breathing monsters)
- Minor size scaling (1.5x max difference by mana cost)
- Team distinction via armor/accent tint recoloring

### Game Rule Clarifications

**Hydra Multi-Strike:**
- When Four-Headed Hydra attacks with 3+ adjacent enemies, player chooses which 2 to attack

**Full Inventory:**
- When inventory has 3 items and new item drops, player chooses: swap with existing item OR leave new item on hex
- Items left on hex can be picked up later by any troop

**Turn Skipping:**
- Turns cannot be skipped - player must perform at least one action or end turn
- Prevents stalemate/griefing

**Running Out of Gold:**
- Player can still fight, just can't buy/upgrade
- No passive income

**Friendly Fire (Mines):**
- Players cannot attack their own mines

**Tutorial System:**
- Help menu with rules documentation
- No interactive tutorial (future enhancement)

### Performance Optimization (Godot-Specific)

**Optimization Strategies:**
1. Object pooling: Reuse troop/mine/NPC nodes instead of creating/destroying
2. Hex board: Use TileMap or custom hex grid (don't create 1000+ individual hex nodes)
3. Pathfinding: Cache paths, limit search depth
4. Rendering: Full 3D with optimized LOD (Level of Detail) for distant objects
5. Update only visible/active objects
6. Cutscene preloading: Pre-cache combat animations

**Godot Best Practices:**
- Use `$NodeName` sparingly (cache references)
- Use signals instead of polling
- Use `set_process(false)` for inactive objects
- Use Godot 4.x rendering features (Vulkan/Forward+)

## Audio/Sound System

**Implementation Timing:** Audio will be added at the **end of MVP development** as it is the most challenging asset category to create.

**Audio Categories (Future):**
- Background music (menu, gameplay, combat)
- Sound effects (UI clicks, troop movement, attacks, dice rolls)
- Ambient sounds (biome-specific atmosphere)
- Victory/defeat fanfares

**Audio Integration Points:**
- Main menu background music
- In-game ambient music (adjusts by game state)
- Combat SFX (attack, hit, miss, death)
- UI SFX (button clicks, card selection, turn end)
- NPC encounter sounds
- Gold/XP gain sounds

## Asset Request Protocol

**IMPORTANT:** During development, when any asset (image, video, audio, etc.) is required, the following process must be followed:

1. **Pause implementation** of the feature requiring the asset
2. **Create an asset request** with the following specifications:

**For Images:**
- Description of what the image should contain/depict
- Resolution (e.g., 512x512, 1920x1080)
- Aspect ratio (e.g., 1:1, 16:9, 4:3)
- File format preference (PNG, JPG, WebP)
- Transparency requirements (yes/no)
- Style reference (realistic, stylized, etc.)

**For Audio:**
- Description of the sound/music
- Duration/length (e.g., 3 seconds, 2 minutes looping)
- Format preference (MP3, OGG, WAV)
- Loop requirements (seamless loop, one-shot)
- Mood/tone (epic, calm, tense, etc.)

**For Video/Animation:**
- Description of content
- Resolution and frame rate
- Duration
- Format preference

**For 3D Models:**
- Description of the model
- Polygon budget (low/medium/high poly)
- Texture requirements
- Animation requirements

3. **Asset delivery folder**: `assets/pending/` - User will upload requested media here
4. **Notify user** with complete asset request details
5. **Resume implementation** once assets are provided

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

## Future Enhancements (Out of Scope for Core)

- Spawn platforms and respawning
- Spell system
- Gambling/mini-games
- Treasure chest
- Card shop system
- Save/load game
- Online multiplayer
- AI opponents

---

## Changelog

### 2026-02-05: Documentation Consolidation
- **ADDED**: `PROJECT_BIBLE.md` — Single source of truth consolidating all documentation
- **CHANGED**: Archived redundant documentation files:
  - `enhanced-combat-system.md` (Archive) — combat system now fully implemented
  - `enhanced-combat-implementation-plan.md` (Archive) — 100% complete
  - `VERTEX_TERRAIN_REFACTORING.md` — superseded by `VERTEX_HEIGHT_FIX.md`
- **INTEGRATED** into PROJECT_BIBLE.md:
  - Implementation plan (this file)
  - Asset integration master plan
  - Combat guide
  - Combat new player refactoring plan
  - Troop cards philosophy
  - Known issues (THINGS TO FIX.txt)
  - Vertex height fix documentation

