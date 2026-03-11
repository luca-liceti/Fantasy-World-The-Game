# Fantasy World — UI/UX Menu Flow Overview

This document contains the complete UI/UX hierarchy and menu flow map for the game, spanning from the diverse Main Menu backgrounds down into the deepest branches of gameplay, multiplayer lobbies, and settings.

> **Legend**: Nodes marked with 🔮 are planned post-MVP features. Nodes marked with ⏳ are designed but not yet implemented.

---

## Visual Design Language (from UI Templates)

All menus share a consistent dark medieval aesthetic:
- **Backgrounds**: Four revolving cinematic background images (Cozy Tavern, Battlefield Tent, Grand Dining Hall, Deforested Woods)
- **Title**: "FANTASY WORLD / THE BOARD GAME" — large serif/display font, top-center of every screen
- **Page Headers**: Large screen-title text below the game logo (e.g. "ONLINE MULTIPLAYER LOBBY", "SETTINGS")
- **Buttons (Menu)**: Wide trapezoidal/beveled dark panels with golden-toned text, no emoji icons, uppercase labels
- **Buttons (Action)**: Standard dark rectangular buttons with beveled border and golden/warm text (e.g. JOIN, COPY, BACK, APPLY CHANGES)
- **Panels**: Dark semi-transparent containers with a recessed border (double-line / shadow inset style)
- **Inputs / Selectors**: Dark inset fields with golden bracket notation (e.g. `[ PlayerOne ]`, `[ XY9-B2Z ]`)
- **Sliders**: Dark track with a centered thumb; die/randomise icon button on the right of each slider row
- **Tabs**: Horizontal tab row; active tab is highlighted with a bevel/lighter background
- **Back Button**: Always bottom-left of the screen
- **Corner Mark**: Compass/star glyph in the bottom-right corner of every screen
- **Separator line**: Thin ornamental line used below page headers

---

```mermaid
%%{init: {"flowchart": {"curve": "stepBefore"}}}%%
flowchart LR
    root["Fantasy World UI/UX Flow"] --> MainMenu["Main Menu"]

    %% ========================================================================
    %% MAIN MENU — REVOLVING BACKGROUNDS
    %% ========================================================================
    MainMenu --> MenuBackgrounds["Revolving Backgrounds\n(Auto-cycle every ~15s)"]
    MenuBackgrounds --> BG_Tavern["cozy_tavern_background.png ✅"]
    MenuBackgrounds --> BG_Tent["battlefield_tent_background.png ✅"]
    MenuBackgrounds --> BG_Hall["grand_dinning_hall_background.png ✅"]
    MenuBackgrounds --> BG_Woods["deforested_woods_background.png ✅"]
    MenuBackgrounds --> BG_Transition["Cross-fade Transition Between Backgrounds"]

    %% ========================================================================
    %% MAIN MENU — LAYOUT
    %% ========================================================================
    MainMenu --> MenuLayout["Layout: Title (top-center) + Centered Button Stack"]
    MenuLayout --> MenuTitle["FANTASY WORLD\nTHE BOARD GAME\n(Logo / Display Font, top-center)"]
    MenuLayout --> MenuButtons["7 Primary Buttons (stacked, trapezoidal style)"]
    MenuButtons --> BtnPlay["PLAY"]
    MenuButtons --> BtnMP["MULTIPLAYER"]
    MenuButtons --> BtnArchives["THE ARCHIVES"]
    MenuButtons --> BtnTutorial["TUTORIAL"]
    MenuButtons --> BtnSettings["SETTINGS"]
    MenuButtons --> BtnCredits["CREDITS"]
    MenuButtons --> BtnQuit["QUIT GAME"]
    MenuLayout --> CornerMark["★ Compass Glyph — Bottom Right"]
    MenuLayout --> VersionLabel["Version Label — Bottom Right (above glyph)"]

    %% ========================================================================
    %% MAIN MENU — FIRST-TIME USER EXPERIENCE
    %% ========================================================================
    MainMenu --> FTUE["First Launch Detection"]
    FTUE --> WelcomeModal["Welcome Modal"]
    WelcomeModal --> SkipTutorial["Skip Tutorial"]
    WelcomeModal --> StartTutorial["Start Tutorial"]
    WelcomeModal --> QuickSettings["Quick Settings (Volume, Display)"]

    %% ========================================================================
    %% PLAY — MODE SELECTION
    %% ========================================================================
    MainMenu --> PlayMenu["PLAY"]
    PlayMenu --> QuickPlay["QUICK PLAY\n(Default rules, random map)"]
    PlayMenu --> CustomMatch["CUSTOM MATCH\n(Open match config)"]
    PlayMenu --> VSBot["VS BOT / AI 🔮"]
    PlayMenu --> StoryMode["STORY MODE 🔮"]
    PlayMenu --> Achievements["ACHIEVEMENTS\n(Track milestones)"]
    PlayMenu --> LoadGame["Load Saved Game 🔮"]
    LoadGame --> SaveSlotList["Save Slot List"]
    SaveSlotList --> SelectSlot["Select Save → Resume Match"]

    QuickPlay --> QP_DeckSelect["Deck Selection → Dice Roll → Game"]

    %% --- Custom Match Config Screen ---
    CustomMatch --> CM_Layout["Layout: Logo + 'CUSTOM MATCH' Header"]

    CM_Layout --> CM_Panel_World["Panel 1 — WORLD & ATMOSPHERE"]
    CM_Panel_World --> CM_Env["Environment: Dropdown (Random / Cozy Tavern / ...)"]
    CM_Panel_World --> CM_Terrain["Terrain Height Variation: Toggle"]

    CM_Layout --> CM_Panel_Rules["Panel 2 — ON THE RULEBOOK"]
    CM_Panel_Rules --> CM_Timer["Turn Timer: Dropdown (30s / 60s / 90s / 120s / No Timer)"]
    CM_Panel_Rules --> CM_Combat["Combat Complexity: Dropdown (Enhanced / Simple)"]
    CM_Panel_Rules --> CM_Speed["Combat Speed: Dropdown (0.5× / 1× / 1.5× / 2×)"]
    CM_Panel_Rules --> CM_StartRes["Starting Gold: Dropdown (50 / 100 / 200 / 500)"]

    CM_Layout --> CM_Panel_Adv["Panel 3 — ADVANCED MECHANICS"]
    CM_Panel_Adv --> CM_NPC["NPC Encounters: Toggle"]
    CM_Panel_Adv --> CM_Bounty["Aggression Bounty System: Toggle"]

    CM_Layout --> CM_StartBtn["START MATCH Button — Bottom Center"]
    CM_Layout --> CM_Back["BACK Button — Bottom Left"]

    %% --- Achievements Screen (Coming Soon) ---
    Achievements --> AchieveCombat["Combat Milestones"]
    Achievements --> AchieveStrategy["Strategic Mastery"]
    Achievements --> AchieveExplore["Exploration Rewards"]
    Achievements --> AchieveCollect["Collection Goals"]
    Achievements --> AchieveChallenge["Challenge Runs"]

    %% Match Prep (same for both local and hosted/online multiplayer)
    CustomMatch --> MatchSetup["Match Setup"]
    MatchSetup --> DeckBuilding["Deck Selection Phase"]
    DeckBuilding --> DeckTimer["30-Second Selection Timer"]
    DeckBuilding --> SimultaneousPick["Simultaneous Selection (Both Players)"]
    DeckBuilding --> DuplicatesAllowed["Duplicates Allowed Label"]
    DeckBuilding --> GroundTank["Select 1 Ground Tank"]
    GroundTank --> GTKnight["Medieval Knight (5 Mana)"]
    GroundTank --> GTGiant["Stone Giant (8 Mana)"]
    GroundTank --> GTHydra["Four-Headed Hydra (9 Mana)"]
    DeckBuilding --> AirHybrid["Select 1 Air/Hybrid"]
    AirHybrid --> AHDragon["Dark Blood Dragon (8 Mana)"]
    AirHybrid --> AHSerpent["Sky Serpent (5 Mana)"]
    AirHybrid --> AHValkyrie["Frost Valkyrie (6 Mana)"]
    DeckBuilding --> RangedMagic["Select 1 Ranged/Magic"]
    RangedMagic --> RMWizard["Dark Magic Wizard (4 Mana)"]
    RangedMagic --> RMDemon["Demon of Darkness (7 Mana)"]
    RangedMagic --> RMArcher["Elven Archer (4 Mana)"]
    DeckBuilding --> FlexSupport["Select 1 Flex/Support"]
    FlexSupport --> FSCleric["Celestial Cleric (5 Mana)"]
    FlexSupport --> FSAssassin["Shadow Assassin (4 Mana)"]
    FlexSupport --> FSSoul["Infernal Soul (3 Mana)"]
    DeckBuilding --> ManaCheck["Verify Mana Total ≤ 22"]
    DeckBuilding --> CardPreview["Card Art + Stats Preview on Hover"]

    MatchSetup --> FirstMoveDice["First Move Dice Roll"]
    FirstMoveDice --> DiceP1["Player 1 d20 Roll"]
    FirstMoveDice --> DiceP2["Player 2 d20 Roll"]
    FirstMoveDice --> DiceWinner["Higher Roll Goes First"]
    FirstMoveDice --> DiceTie["Tie → Re-Roll"]

    MatchSetup --> SpawnPlacement["Troop Spawn Placement"]
    SpawnPlacement --> SpawnP1["Player 1: 4 Troops on Spawn Hexes (Left Edge)"]
    SpawnPlacement --> SpawnP2["Player 2: 4 Troops on Spawn Hexes (Right Edge)"]
    SpawnPlacement --> SpawnAuto["Auto-Placed (1 Troop Per Spawn Hex)"]

    %% ========================================================================
    %% LOADING / TRANSITIONS
    %% ========================================================================
    MatchSetup --> LoadingScreen["Loading Screen"]
    LoadingScreen --> BoardGenProgress["Board Generation (397 Hexes)"]
    LoadingScreen --> BiomeAssignment["Biome Assignment (7 Biomes)"]
    LoadingScreen --> EnvironmentLoad["Environment Scene Load"]
    LoadingScreen --> TransitionAnim["Scene Transition Animation"]

    %% ========================================================================
    %% IN-GAME VIEW — HUD
    %% ========================================================================
    CustomMatch --> InGamePlay["In-Game View"]
    InGamePlay --> HUD["Heads-Up Display"]
    HUD --> BottomBar["Bottom Bar - 4 Troop Cards"]
    BottomBar --> CardArtThumb["Card Art Thumbnail"]
    BottomBar --> CardHPDisplay["HP Bar Per Card"]
    BottomBar --> CardActionDone["✓ Done Indicator (Acted This Turn)"]
    BottomBar --> CardDeadState["💀 Dead Overlay"]
    BottomBar --> CardHotkey["Hotkey Labels (1-4)"]
    HUD --> ResourceDisplay["Gold & XP Counters"]
    HUD --> TurnIndicator["Turn Number & Phase Display"]
    TurnIndicator --> PhaseMovement["Movement Phase"]
    TurnIndicator --> PhaseAction["Action Phase"]
    TurnIndicator --> PhaseCombat["Combat Phase"]
    HUD --> TurnTimer["Turn Timer"]
    TurnTimer --> TimerNormal["Normal (White)"]
    TurnTimer --> TimerWarning["Warning < 60s (Yellow)"]
    TurnTimer --> TimerCritical["Critical < 30s (Red)"]
    TurnTimer --> TimerPause["Timer Pauses During Combat/UI"]
    HUD --> PlayerPanels["Player Info Panels (P1 Left / P2 Right)"]
    PlayerPanels --> PanelGold["💰 Gold Display"]
    PlayerPanels --> PanelXP["⭐ XP Display"]
    PlayerPanels --> PanelMineCount["⛏️ Mine Count (X/5)"]
    HUD --> SelectedTroopInfo["Selected Troop Stats Panel"]
    SelectedTroopInfo --> TroopName["Name & Level"]
    SelectedTroopInfo --> TroopHP["HP / Max HP"]
    SelectedTroopInfo --> TroopATKDEF["ATK | DEF"]
    SelectedTroopInfo --> TroopRangeSpeed["Range | Speed"]
    SelectedTroopInfo --> TroopStatusEffects["Active Status Effects"]
    SelectedTroopInfo --> TroopType["Damage Type & Category"]
    HUD --> CombatLog["Combat Log & Event Feed"]
    CombatLog --> LogAttacks["Attack Results"]
    CombatLog --> LogStatus["Status Effects Applied/Expired"]
    CombatLog --> LogEconomy["Gold/XP Gains"]
    CombatLog --> LogNPC["NPC Events"]
    HUD --> HitChance["Hit Chance & Damage Prediction"]
    HUD --> BiomeTooltip["Biome Modifier Tooltip on Hover"]
    HUD --> ItemInventory["Item Inventory Display (Max 3)"]
    ItemInventory --> InvSlot1["Item Slot 1"]
    ItemInventory --> InvSlot2["Item Slot 2"]
    ItemInventory --> InvSlot3["Item Slot 3"]
    HUD --> BountyNotifications["Aggression Bounty Notifications"]
    BountyNotifications --> FirstBlood["First Blood (+50 Gold)"]
    BountyNotifications --> KillStreak["Kill Streak (+25/50/100% XP)"]
    BountyNotifications --> RevengeKill["Revenge Kill (+25% Gold)"]
    BountyNotifications --> MineRaider["Mine Raider (+20 Gold)"]

    %% ========================================================================
    %% IN-GAME VIEW — NOTIFICATION / TOAST SYSTEM
    %% ========================================================================
    InGamePlay --> ToastSystem["Notification Toasts"]
    ToastSystem --> ToastMine["Gold Mine Placed! +X gold/turn"]
    ToastSystem --> ToastNPC["NPC Appeared!"]
    ToastSystem --> ToastElim["Enemy Troop Eliminated!"]
    ToastSystem --> ToastItem["Item Acquired: X"]
    ToastSystem --> ToastUpgrade["Troop Upgraded! +Stats"]
    ToastSystem --> ToastTimer["Timer Warning (30s / 10s / 5s)"]
    ToastSystem --> ToastError["Invalid Action (Shake + Tooltip)"]

    %% ========================================================================
    %% IN-GAME VIEW — CAMERA CONTROLS
    %% ========================================================================
    InGamePlay --> CameraSystem["Camera System"]
    CameraSystem --> CamTopDown["Default: Top-Down 45°"]
    CameraSystem --> CamRotate["Free Rotate (Mouse Drag / Q-E)"]
    CameraSystem --> CamZoom["Zoom Levels (Scroll)"]
    CamZoom --> CamZoomClose["Close (Unit Detail)"]
    CamZoom --> CamZoomMid["Mid (Tactical)"]
    CamZoom --> CamZoomFar["Far (Whole Board)"]
    CameraSystem --> CamPan["WASD / Edge Pan Movement"]
    CameraSystem --> CamCombat["Combat Camera (Auto-Zoom to Fight)"]
    CameraSystem --> CamTroopFocus["Click Card → Focus Troop"]

    %% ========================================================================
    %% IN-GAME VIEW — VISUAL FEEDBACK
    %% ========================================================================
    InGamePlay --> VisualFeedback["Visual Feedback Layer"]
    VisualFeedback --> HexHighlightMove["Blue Hex Highlight (Movement Range)"]
    VisualFeedback --> HexHighlightAttack["Red Hex Highlight (Attack Range)"]
    VisualFeedback --> HexHighlightSelect["Selection Glow (Selected Troop)"]
    VisualFeedback --> HexHighlightMine["Yellow Hex Highlight (Mine Placement)"]
    VisualFeedback --> HexHighlightHeal["Green Hex Highlight (Heal Range)"]
    VisualFeedback --> InvalidAction["Shake + Error Tooltip"]
    VisualFeedback --> TeamColors["Team Distinction (Armor/Accent Tint)"]
    VisualFeedback --> DamageNumbers["Floating Damage Numbers"]
    DamageNumbers --> DmgNormal["Normal Hit (Small, Subtle)"]
    DamageNumbers --> DmgBig["Big Hit 50+ (Large, Punchy)"]
    DamageNumbers --> DmgCrit["Critical 18-20 (Gold, CRITICAL!)"]
    DamageNumbers --> DmgHeal["Healing (Soft Green)"]

    %% ========================================================================
    %% IN-GAME VIEW — ACTION MENU
    %% ========================================================================
    InGamePlay --> ActionMenu["Radial Action Menu (Right-Click)"]
    ActionMenu --> MoveAction["Move - Blue Hexes"]
    MoveAction --> MovePathPreview["Path Preview on Hover"]
    MoveAction --> MoveConfirm["Click Tile to Confirm"]
    ActionMenu --> AttackAction["Combat Select - Red Hexes"]
    AttackAction --> AttackRangeCheck["Range & LOS Validation"]
    AttackAction --> SelectTarget["Click Enemy to Target"]
    AttackAction --> CombatStanceSelect["Auto / Manual Stance Select"]
    ActionMenu --> HealAction["Heal (Cleric Only)"]
    HealAction --> HealRange["Range 2 - Green Hexes"]
    HealAction --> HealTarget["Select Friendly Troop"]
    HealAction --> HealAmount["Heal 35 HP (No Cooldown)"]
    HealAction --> HealSelf["Can Heal Self"]
    ActionMenu --> MineAction["Place Gold Mine"]
    MineAction --> MineCost["Cost: 100 Gold"]
    MineAction --> MineValidation["Min 3 Hexes Between Mines"]
    MineAction --> MineNoPeaks["Cannot Place on Peaks Biome"]
    MineAction --> MineMaxCheck["Max 5 Mines Per Player"]
    ActionMenu --> UpgradeAction["Upgrade Troop"]
    UpgradeAction --> UpgradeCostDisplay["Show Cost: X Gold + Y XP"]
    UpgradeAction --> UpgradeConfirm["Confirm Purchase"]
    UpgradeAction --> UpgradeAnimation["Upgrade Animation"]
    UpgradeAction --> UpgradeStatGain["+10% HP, +5 ATK, +3 DEF"]
    UpgradeAction --> UpgradeMaxLevel["Max Level 5"]
    ActionMenu --> ItemAction["Use Consumable Item"]
    ItemAction --> SpeedPotion["Speed Potion (+1 Speed, 3 turns)"]
    ItemAction --> Whetstone["Whetstone (+10 ATK next attack)"]
    ItemAction --> PhoenixFeather["Phoenix Feather (Respawn 1 Troop)"]
    ActionMenu --> EndTurn["End Turn"]
    EndTurn --> EndTurnConfirm["Confirm if Actions Remaining (Setting)"]

    %% ========================================================================
    %% IN-GAME VIEW — GOLD MINE MANAGEMENT
    %% ========================================================================
    InGamePlay --> MineManagement["Gold Mine Management"]
    MineManagement --> MineInfoPanel["Mine Info Panel (Click Mine)"]
    MineInfoPanel --> MineLevel["Current Level & Generation Rate"]
    MineInfoPanel --> MineUpgradeCost["Upgrade Cost to Next Level"]
    MineManagement --> MineUpgradeFlow["Mine Upgrade Flow"]
    MineUpgradeFlow --> MineL1["Lv1: 10 gold/turn"]
    MineUpgradeFlow --> MineL2["Lv2: 25 gold/turn (200g)"]
    MineUpgradeFlow --> MineL3["Lv3: 50 gold/turn (400g)"]
    MineUpgradeFlow --> MineL4["Lv4: 100 gold/turn (800g)"]
    MineUpgradeFlow --> MineL5["Lv5: 200 gold/turn (1600g)"]

    %% ========================================================================
    %% IN-GAME VIEW — NPC ENCOUNTER FLOW
    %% ========================================================================
    InGamePlay --> NPCEncounter["NPC Encounter System"]
    NPCEncounter --> NPCSpawnTrigger["5% Spawn Chance on Troop Move"]
    NPCSpawnTrigger --> NPCAppearAnim["NPC Appears Animation"]
    NPCEncounter --> NPCTypes["NPC Types"]
    NPCTypes --> NPCGoblin["Goblin (50 HP, 5g, 10 XP)"]
    NPCTypes --> NPCOrc["Orc (100 HP, 15g, 25 XP)"]
    NPCTypes --> NPCTroll["Troll (200 HP, 30g, 50 XP)"]
    NPCEncounter --> NPCCombat["NPC Combat (Uses Combat Flow)"]
    NPCCombat --> NPCAttackRange["NPCs Attack Nearest (Range 2)"]
    NPCCombat --> NPCStationary["NPCs Do Not Move"]
    NPCEncounter --> NPCLootDrop["Loot Drop Modal"]
    NPCLootDrop --> LootSpeedPotion["Speed Potion (10% Drop)"]
    NPCLootDrop --> LootWhetstone["Whetstone (15% Drop)"]
    NPCLootDrop --> LootPhoenixFeather["Phoenix Feather (20% Drop)"]
    NPCLootDrop --> LootGoldXP["Gold + XP Reward"]
    NPCEncounter --> InventoryFullModal["Inventory Full (3/3)"]
    InventoryFullModal --> SwapItem["Swap with Existing Item"]
    InventoryFullModal --> LeaveOnHex["Leave Item on Hex"]

    %% ========================================================================
    %% IN-GAME VIEW — COMBAT FLOW
    %% ========================================================================
    InGamePlay --> CombatFlow["Combat Flow"]
    CombatFlow --> CombatInitiate["Attacker Selects Target"]
    CombatInitiate --> CombatPreview["Pre-Combat Preview"]
    CombatPreview --> PreviewHitChance["Hit Chance Percentage"]
    CombatPreview --> PreviewDmgRange["Damage Range Prediction"]
    CombatPreview --> PreviewTypeEffect["Type Effectiveness Indicator"]
    CombatPreview --> PreviewPositionBonus["Active Position Bonuses"]
    CombatFlow --> CombatSelection["Simultaneous Selection Phase (10s)"]
    CombatSelection --> AttackerMoveSelect["Attacker Chooses Move"]
    AttackerMoveSelect --> MoveStandard["Standard (100% dmg, +0 acc)"]
    AttackerMoveSelect --> MovePower["Power (150% dmg, -3 acc, 3t CD)"]
    AttackerMoveSelect --> MovePrecision["Precision (80% dmg, +5 acc, 2t CD)"]
    AttackerMoveSelect --> MoveSpecial["Special (120% dmg, status, 4t CD)"]
    AttackerMoveSelect --> MoveTypeColor["Type Effectiveness Color-Coding"]
    AttackerMoveSelect --> MoveCooldownState["Cooldown Grayed-Out Moves"]
    CombatSelection --> DefenderStanceSelect["Defender Chooses Stance"]
    DefenderStanceSelect --> StanceBrace["Brace (+3 DEF, -20% dmg)"]
    DefenderStanceSelect --> StanceDodge["Dodge (+5 Evasion)"]
    DefenderStanceSelect --> StanceCounter["Counter (50% ATK back on miss)"]
    DefenderStanceSelect --> StanceEndure["Endure (Survive at 1 HP, once)"]
    DefenderStanceSelect --> StanceAutoSimple["Auto-Brace (Simplified Mode)"]
    CombatSelection --> MoveTooltip["Move Tooltip (Power/Acc/CD/Type)"]
    CombatSelection --> SelectionTimer["10s Selection Timer"]
    CombatSelection --> ContextualHints["Contextual Hints (Toggleable)"]

    CombatFlow --> PositionBonuses["Positioning Bonuses Applied"]
    PositionBonuses --> PosFlanking["Flanking (+3 hit, ally adjacent)"]
    PositionBonuses --> PosHighGround["High Ground (+2 hit, +10% dmg)"]
    PositionBonuses --> PosCover["Cover (+3 DEF, Forest/Ruins)"]
    PositionBonuses --> PosSurrounded["Surrounded (-2 DEF, 3+ enemies)"]

    CombatFlow --> DiceRoll["Dice Roll Animation (d20)"]
    DiceRoll --> AttackerRoll["Attacker: d20 + ATK + Move Acc"]
    DiceRoll --> DefenderRoll["Defender: 10 + DEF + Stance Bonus"]
    DiceRoll --> CritRoll["Natural 18-20: Critical Hit! (2x Damage)"]
    DiceRoll --> FumbleRoll["Natural 1: Critical Miss! (Auto-Miss)"]

    CombatFlow --> DrawReRoll["Draw / Re-Roll Handling"]
    DrawReRoll --> EqualRoll["Equal Rolls → Re-Roll"]
    DrawReRoll --> MaxReRoll["Max 3 Re-Rolls"]
    DrawReRoll --> DrawDefenderWins["After 3 Draws → Defender Wins"]

    CombatFlow --> CombatResolution["Combat Resolution Overlay"]
    CombatResolution --> HitMissResult["HIT / MISS / CRITICAL Display"]
    CombatResolution --> DamageDisplay["Damage Number & Breakdown"]
    CombatResolution --> DamageFormula["(ATK × Power% × Type) - DEF/2"]
    CombatResolution --> TypeEffectDisplay["Type Effectiveness Label"]
    TypeEffectDisplay --> TypeSuperEff["Super Effective (1.5x)"]
    TypeEffectDisplay --> TypeNotVeryEff["Not Very Effective (0.5x)"]
    TypeEffectDisplay --> TypeImmune["Immune (0x)"]
    CombatResolution --> StatusEffectApplied["Status Effect Applied"]
    StatusEffectApplied --> SEStunned["⚡ Stunned (1 turn, can't act)"]
    StatusEffectApplied --> SEBurned["🔥 Burned (3 turns, 10 dmg/turn)"]
    StatusEffectApplied --> SEPoisoned["☠️ Poisoned (4 turns, 8 dmg/turn)"]
    StatusEffectApplied --> SESlowed["🐢 Slowed (2 turns, -2 Speed)"]
    StatusEffectApplied --> SECursed["💀 Cursed (3 turns, -25% ATK)"]
    StatusEffectApplied --> SETerrified["😱 Terrified (2 turns, -25% DEF)"]
    StatusEffectApplied --> SERooted["🌿 Rooted (2 turns, can't move)"]
    StatusEffectApplied --> SEStealth["👻 Stealth (3 turns, next = crit)"]
    CombatResolution --> DamagePopup["Floating Damage Number on Troop"]
    CombatResolution --> CounterAttackDisplay["Counter-Attack Result (if Counter Stance)"]

    %% ========================================================================
    %% IN-GAME VIEW — SIMPLIFIED COMBAT MODE
    %% ========================================================================
    CombatFlow --> SimplifiedMode["Simplified Combat Mode"]
    SimplifiedMode --> SimpleMovesOnly["2 Moves Only (Standard + Special)"]
    SimplifiedMode --> SimpleTypes["3 Types (Physical, Magic, Elemental)"]
    SimplifiedMode --> SimpleAutoBrace["Auto-Brace (No Stance Selection)"]
    SimplifiedMode --> SimpleExtendTimer["Extended Timer (15s)"]
    SimplifiedMode --> SimpleLabels["STRONG / WEAK / NEUTRAL Labels"]

    %% ========================================================================
    %% IN-GAME VIEW — TROOP STATUS
    %% ========================================================================
    InGamePlay --> TroopStatus["Troop Status Overhead UI"]
    TroopStatus --> HPBar["Health Bar"]
    TroopStatus --> StatusIcons["Active Status Effect Icons"]
    TroopStatus --> CooldownDisplay["Move Cooldown Indicators"]
    TroopStatus --> StatModifiers["ATK/DEF/SPD Stage Indicators"]
    TroopStatus --> LevelBadge["Level Badge (1-5)"]
    TroopStatus --> TeamIndicator["Team Color Indicator"]

    %% ========================================================================
    %% IN-GAME VIEW — KEYBOARD SHORTCUTS
    %% ========================================================================
    InGamePlay --> KeyboardOverlay["Keyboard Shortcuts (F1 / ?)"]
    KeyboardOverlay --> KeyWASD["WASD: Camera Pan"]
    KeyboardOverlay --> KeyQE["Q/E: Camera Rotate"]
    KeyboardOverlay --> KeyScroll["Scroll: Zoom"]
    KeyboardOverlay --> Key1234["1-4: Select Troop by Card Slot"]
    KeyboardOverlay --> KeySpace["Space: End Turn"]
    KeyboardOverlay --> KeyEsc["Esc: Pause Menu"]
    KeyboardOverlay --> KeyM["M: Move Mode"]
    KeyboardOverlay --> KeyT["T: Attack Mode"]

    %% ========================================================================
    %% IN-GAME VIEW — PAUSE MENU
    %% ========================================================================
    InGamePlay --> PauseMenu["Pause Menu (ESC)"]
    PauseMenu --> ResumeGame["Resume"]
    PauseMenu --> PauseSettings["Settings Overlay"]
    PauseMenu --> SaveGame["Save Game"]
    SaveGame --> SaveSlotSelect["Save Slot Selection"]
    SaveSlotSelect --> SaveOverwriteConfirm["Overwrite Confirmation"]
    SaveSlotSelect --> SaveSuccess["Save Successful Toast"]
    SaveGame --> AutoSaveInfo["Auto-Save Every 5 Turns"]
    PauseMenu --> QuitToMenu["Quit to Main Menu"]
    QuitToMenu --> ConfirmQuitMatch["Confirm: Forfeit Match?"]
    ConfirmQuitMatch --> YesQuitMatch["Yes - Return to Menu"]
    ConfirmQuitMatch --> NoCancelMatch["No - Resume Game"]
    PauseMenu --> QuitToDesktop["Quit to Desktop"]
    QuitToDesktop --> ConfirmQuitDesktop["Confirm: Exit Game?"]

    %% ========================================================================
    %% IN-GAME VIEW — END GAME
    %% ========================================================================
    InGamePlay --> EndGameScreen["Game Over Overlay"]
    EndGameScreen --> VictoryDefeat["Victory / Defeat Animation"]
    EndGameScreen --> MatchStats["Match Statistics Summary"]
    MatchStats --> TotalDamageDealt["Total Damage Dealt"]
    MatchStats --> DamageTaken["Total Damage Taken"]
    MatchStats --> TroopsEliminated["Troops Eliminated"]
    MatchStats --> TurnsPlayed["Turns Played"]
    MatchStats --> GoldEarned["Gold Earned"]
    MatchStats --> NPCsDefeated["NPCs Defeated"]
    MatchStats --> CriticalHits["Critical Hits Landed"]
    MatchStats --> BountiesEarned["Bounties Earned"]
    EndGameScreen --> RematchOption["Request Rematch"]
    EndGameScreen --> ReturnToMenu["Return to Menu"]

    %% ========================================================================
    %% ONLINE MULTIPLAYER
    %% ========================================================================
    MainMenu --> OnlineMultiplayer["MULTIPLAYER"]

    %% --- Online Multiplayer Lobby Screen ---
    OnlineMultiplayer --> MP_Lobby["Screen: MULTIPLAYER"]
    MP_Lobby --> MP_Layout["Layout: Logo + 'MULTIPLAYER' Header"]
    MP_Layout --> MP_LeftPanel["Left Panel — JOIN GAME"]
    MP_LeftPanel --> MP_RoomCode["Enter Room Code: [ _ _ _ - _ _ _ ]"]
    MP_LeftPanel --> MP_JoinBtn["JOIN Button"]
    MP_LeftPanel --> MP_BrowseHeader["BROWSE PUBLIC GAMES (with Refresh ↻ Button)"]
    MP_LeftPanel --> MP_ServerList["Server List (scrollable)"]
    MP_ServerList --> MP_ServerEntry["Row: SERVER N: [ HOST | MAP | PLAYERS ] + JOIN Button"]
    MP_Layout --> MP_RightPanel["Right Panel — MY STATUS"]
    MP_RightPanel --> MP_PlayerName["PLAYER NAME: [ PlayerOne ]"]
    MP_RightPanel --> MP_Region["REGION: [ US-West ]"]
    MP_Layout --> MP_BackBtn["BACK Button — Bottom Left"]

    %% --- Host Multiplayer Game Screen ---
    OnlineMultiplayer --> HostMatch["HOST MULTIPLAYER GAME"]
    HostMatch --> HMG_Layout["Layout: Logo + 'HOST MULTIPLAYER GAME' Header"]
    HMG_Layout --> HMG_ModeTabs["Mode Tabs: [ DEFAULT MODE ] / [ CUSTOM MODE ]"]
    HMG_ModeTabs --> HMG_Custom["Custom Mode: 3 Panels Side-By-Side"]

    HMG_Custom --> HMG_Panel_World["Panel 1 — WORLD & ATMOSPHERE"]
    HMG_Panel_World --> HMG_Env["Environment: Dropdown + Die"]
    HMG_Panel_World --> HMG_Terrain["Terrain Height: Slider + Die"]
    HMG_Panel_World --> HMG_Seed["World Seed: Input + Die"]

    HMG_Custom --> HMG_Panel_Rules["Panel 2 — THE RULEBOOK"]
    HMG_Panel_Rules --> HMG_Timer["Turn Timer: Slider + Die"]
    HMG_Panel_Rules --> HMG_Combat["Combat Complexity: Slider + Die"]
    HMG_Panel_Rules --> HMG_StartRes["Starting Resources: Slider + Die"]

    HMG_Custom --> HMG_Panel_Connect["Panel 3 — CONNECTIVITY"]
    HMG_Panel_Connect --> HMG_RoomCode["ROOM CODE: [ XY9-B2Z ] + COPY Button"]
    HMG_Panel_Connect --> HMG_PlayerList["PLAYER LIST"]
    HMG_Panel_Connect --> HMG_Host["HOST: [ Player Name ] (Ready)"]
    HMG_Panel_Connect --> HMG_Guest["GUEST: [ Waiting... ]"]

    HMG_Layout --> HMG_StartBtn["START MATCH Button — Bottom Center"]
    HMG_Layout --> HMG_BackBtn["BACK Button — Bottom Left"]

    %% --- Join Match (from Lobby) ---
    OnlineMultiplayer --> JoinMatch["Join Match (via Room Code or Browse)"]
    JoinMatch --> ClientLobby["Client Lobby"]
    ClientLobby --> ClientDeck["Simultaneous Deck Selection"]
    ClientLobby --> ReadyUpToggle["Toggle Ready Status"]

    %% ========================================================================
    %% MULTIPLAYER — IN-GAME COMMUNICATION
    %% ========================================================================
    OnlineMultiplayer --> MPComm["In-Game Communication 🔮"]
    MPComm --> Emotes["Quick Emotes"]
    MPComm --> QuickChat["Quick-Chat Phrases"]
    MPComm --> PingIndicator["Ping / Latency Display"]

    %% ========================================================================
    %% MULTIPLAYER — DISCONNECT HANDLING
    %% ========================================================================
    OnlineMultiplayer --> DisconnectHandling["Disconnection Handling"]
    DisconnectHandling --> DCOverlay["Disconnection Overlay"]
    DisconnectHandling --> ReconnectTimer["3 Minute Reconnect Window"]
    DisconnectHandling --> ReconnectProgress["Reconnection Progress Bar"]
    DisconnectHandling --> AutoForfeit["Auto-Forfeit After 3 Disconnects"]
    DisconnectHandling --> StatePreserved["Game State Preserved During DC"]
    DisconnectHandling --> OpponentWaiting["Opponent Sees: Waiting for Reconnect"]

    %% ========================================================================
    %% THE ARCHIVES
    %% ========================================================================
    MainMenu --> TheArchives["THE ARCHIVES"]
    TheArchives --> CardGallery["Troop Card Gallery"]
    CardGallery --> ViewStats["View Stats/Moves for all 12 Troops"]
    CardGallery --> View3DModel["View 3D Character Model"]
    CardGallery --> ViewCardArt["View Full Card Art"]
    CardGallery --> ViewMoves["View All 4 Moves per Troop"]
    CardGallery --> ViewBiomeMods["View Biome Modifiers per Troop"]

    TheArchives --> LoreBestiary["Rules & Lore Reference"]
    LoreBestiary --> NPCGlossary["NPCs: Goblin, Orc, Troll"]
    LoreBestiary --> BiomeEffects["Biome Modifier Effectiveness Chart"]
    LoreBestiary --> CombatRules["Hit Calculations & Ruleset"]
    LoreBestiary --> TypeChart["Type Effectiveness Chart (6 Types)"]
    TypeChart --> TypePhysical["⚔️ Physical"]
    TypeChart --> TypeFire["🔥 Fire"]
    TypeChart --> TypeIce["❄️ Ice"]
    TypeChart --> TypeDark["🌑 Dark"]
    TypeChart --> TypeHoly["✨ Holy"]
    TypeChart --> TypeNature["🌿 Nature"]
    LoreBestiary --> StanceGuide["Defensive Stances Guide"]
    LoreBestiary --> PositionGuide["Positioning Bonuses Guide"]
    LoreBestiary --> StatusGuide["Status Effects Reference"]

    TheArchives --> ItemCatalog["Item Catalog"]
    ItemCatalog --> ItemSpeedPotion["Speed Potion"]
    ItemCatalog --> ItemWhetstone["Whetstone"]
    ItemCatalog --> ItemPhoenixFeather["Phoenix Feather"]

    TheArchives --> MatchHistory["Match History 🔮"]
    MatchHistory --> PastMatchList["Past Match Results"]
    MatchHistory --> WinLossRecord["Win/Loss Record"]
    MatchHistory --> FavoriteTroops["Most Used Troops"]

    %% ========================================================================
    %% TUTORIAL
    %% ========================================================================
    MainMenu --> Tutorial["TUTORIAL"]
    Tutorial --> TutProgress["Progress Tracker (✓/✗ Per Lesson)"]
    Tutorial --> TutBasicAttack["1. Basic Attack"]
    Tutorial --> TutMoveVariety["2. Move Variety"]
    Tutorial --> TutTypeMatchups["3. Type Effectiveness"]
    Tutorial --> TutDefensiveStance["4. Defensive Stances"]
    Tutorial --> TutPositioning["5. Positioning & Cover"]
    Tutorial --> TutFullCombat["6. Full Combat Simulation"]
    Tutorial --> TutReplay["Replay Any Tutorial"]
    Tutorial --> TutSkip["Skip All Tutorials"]

    %% ========================================================================
    %% SETTINGS
    %% ========================================================================
    MainMenu --> Settings["SETTINGS"]
    Settings --> Settings_Layout["Layout: Logo + 'SETTINGS' Header + Separator Line"]
    Settings_Layout --> Settings_Tabs["4 Horizontal Tabs"]
    Settings_Tabs --> Tab_Video["VIDEO (default active tab)"]
    Settings_Tabs --> Tab_Audio["AUDIO"]
    Settings_Tabs --> Tab_Controls["CONTROLS"]
    Settings_Tabs --> Tab_Gameplay["GAMEPLAY"]

    Tab_Video --> Vid_WindowMode["WINDOW MODE: ◄ Borderless Fullscreen ► (cycle)"]
    Tab_Video --> Vid_Resolution["RESOLUTION: ◄ 1920x1080 ▼ (dropdown)"]
    Tab_Video --> Vid_VSync["VSYNC: On / Off toggle"]
    Tab_Video --> Vid_Quality["QUALITY PRESET: ◄ High ► (cycle)"]
    Tab_Video --> Vid_AdvGraphics["ADVANCED GRAPHICS: Settings... (sub-panel link)"]
    Tab_Video --> Vid_AdvPanel["Advanced Graphics Sub-Panel ⏳"]
    Vid_AdvPanel --> Vid_MSAA["Anti-Aliasing (Off / FXAA / TAA / MSAA)"]
    Vid_AdvPanel --> Vid_Shadow["Shadow Quality"]
    Vid_AdvPanel --> Vid_AO["Ambient Occlusion"]
    Vid_AdvPanel --> Vid_Bloom["Bloom Effects (Toggle + Intensity)"]
    Vid_AdvPanel --> Vid_Grass["Grass Quality"]
    Vid_AdvPanel --> Vid_Particles["Particle Effects (25-100%)"]
    Vid_AdvPanel --> Vid_TerrainH["Terrain Height Variation Toggle"]
    Vid_AdvPanel --> Vid_CamShake["Camera Shake Toggle"]
    Vid_AdvPanel --> Vid_FPS["FPS Limit"]

    Tab_Audio --> Aud_Master["MASTER VOLUME: Slider"]
    Tab_Audio --> Aud_Music["MUSIC VOLUME: Slider"]
    Tab_Audio --> Aud_SFX["SFX VOLUME: Slider"]
    Tab_Audio --> Aud_Voice["VOICE VOLUME: Slider"]
    Tab_Audio --> Aud_Mute["MUTE WHEN UNFOCUSED: Toggle"]

    Tab_Controls --> Ctrl_CamSens["CAMERA SENSITIVITY: Slider"]
    Tab_Controls --> Ctrl_InvertY["INVERT CAMERA Y-AXIS: Toggle"]
    Tab_Controls --> Ctrl_EdgePan["EDGE PANNING: Toggle + Speed Slider"]
    Tab_Controls --> Ctrl_Coords["SHOW TILE COORDINATES: Toggle"]
    Tab_Controls --> Ctrl_ConfirmEnd["CONFIRM BEFORE ENDING TURN: Toggle"]
    Tab_Controls --> Ctrl_Keybinds["KEYBINDING CUSTOMIZATION: List ⏳"]

    Tab_Gameplay --> GP_AutoEnd["AUTO-END TURN WHEN NO ACTIONS: Toggle"]
    Tab_Gameplay --> GP_DmgNums["SHOW DAMAGE NUMBERS: Toggle"]
    Tab_Gameplay --> GP_CombatAnims["SHOW COMBAT ANIMATIONS: Toggle"]
    Tab_Gameplay --> GP_Cutscene["CUTSCENE TOGGLE: On / Off"]
    Tab_Gameplay --> GP_CutsceneSpd["CUTSCENE SPEED: Full / Fast / Skip"]
    Tab_Gameplay --> GP_BiomeTip["SHOW BIOME TOOLTIPS: Toggle"]
    Tab_Gameplay --> GP_Hints["SHOW CONTEXTUAL HINTS: Toggle"]
    Tab_Gameplay --> GP_AI["AI LEVEL: Easy / Normal / Hard"]
    Tab_Gameplay --> GP_SmoothZoom["SMOOTH SCROLLING ZOOM: Toggle"]
    Tab_Gameplay --> GP_AutoSave["AUTO-SAVE FREQUENCY 🔮"]
    %% NOTE: Turn Timer, Combat Speed, and Combat Mode are now
    %% match-level settings configured in the Custom Match screen,
    %% not personal preferences in Settings.

    Settings_Layout --> Settings_Apply["APPLY CHANGES Button — Bottom Center"]
    Settings_Layout --> Settings_Back["BACK Button — Bottom Left"]

    %% Accessibility (accessible from within Settings tabs or a 5th tab) ⏳
    Settings --> AccessibilitySettings["Accessibility ⏳"]
    AccessibilitySettings --> TextSize["Text Size (80% - 140%)"]
    AccessibilitySettings --> HighContrast["High Contrast Mode"]
    AccessibilitySettings --> ColorblindMode["Colorblind Mode"]
    AccessibilitySettings --> ReduceMotion["Reduce Motion & Animations"]
    AccessibilitySettings --> ScreenReaderHints["Screen Reader Hints"]
    AccessibilitySettings --> ExtendedTimers["Extended Selection Timers"]

    %% ========================================================================
    %% CREDITS
    %% ========================================================================
    MainMenu --> Credits["CREDITS"]
    Credits --> TeamMembers["Development Team Roles"]
    Credits --> AssetCredits["Asset Sources & Acknowledgements"]
    Credits --> ToolCredits["Tools & Middleware"]
    Credits --> SpecialThanks["Special Thanks"]

    %% ========================================================================
    %% QUIT GAME
    %% ========================================================================
    MainMenu --> QuitGame["QUIT GAME"]
    QuitGame --> ConfirmQuit["Exit Confirmation Modal"]
    ConfirmQuit --> YesQuit["Yes - Exit to Desktop"]
    ConfirmQuit --> NoCancel["No - Return to Main Menu"]
```
