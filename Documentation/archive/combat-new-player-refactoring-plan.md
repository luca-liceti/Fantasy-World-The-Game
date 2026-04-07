# Combat System New Player Experience Refactoring Plan

## Executive Summary

This document outlines a comprehensive plan to refactor the combat gameplay to make it more accessible and enjoyable for new players while maintaining the strategic depth that experienced players appreciate.

---

## Current System Analysis

### Complexity Assessment

The current D&D × Pokémon hybrid combat system has **high complexity**:

| System | Concepts to Learn |
|--------|-------------------|
| **Move System** | 4 unique moves per troop × 12 troops = 48 total moves |
| **Damage Types** | 6 types (Physical, Fire, Ice, Dark, Holy, Nature) |
| **Type Matchups** | 6×6 effectiveness chart = 36 potential matchups |
| **Status Effects** | 8 different conditions (Stunned, Burned, etc.) |
| **Stat Stages** | -6 to +6 multipliers (13 stages) |
| **Positioning** | Flanking, High Ground, Cover, Surrounded |
| **Advantage/Disadvantage** | 5 sources each = 10 modifiers |
| **Defensive Stances** | 4 options (Brace, Dodge, Counter, Endure) |
| **Cooldowns** | Track cooldowns for non-Standard moves |
| **Dice System** | d20 rolls, DC calculations, crits |

**New Player Cognitive Load:** Very High (estimated 10+ minutes just to understand basics)

### Identified Pain Points

1. **Information Overload**: Too much information presented at once during combat
2. **Unclear Outcomes**: Players don't understand why attacks hit/miss
3. **Hidden Mechanics**: Type effectiveness isn't clearly communicated
4. **Timer Pressure**: 10-second timer creates anxiety for players still learning
5. **No Learning Curve**: Players are thrown into full complexity immediately
6. **Move Selection Paralysis**: 4 moves with stats feels overwhelming

---

## Phase 1: Onboarding Tutorial System

**Goal:** Introduce combat mechanics gradually through guided tutorials.

### 1.1 First Combat Tutorial (Scripted)
- [ ] 1.1.1 Create `TutorialCombatManager` class that extends `CombatManager`
- [ ] 1.1.2 Implement scripted first combat (player always wins first attack)
- [ ] 1.1.3 Highlight UI elements one at a time with explanatory tooltips
- [ ] 1.1.4 Pause timer during tutorial explanations
- [ ] 1.1.5 Use speech bubbles or modal popups to explain each step

### 1.2 Progressive Tutorial Battles
- [ ] 1.2.1 **Tutorial 1: Basic Attack** — Only Standard move available, explain hit/miss
- [ ] 1.2.2 **Tutorial 2: Move Variety** — Unlock Power move, explain accuracy trade-off
- [ ] 1.2.3 **Tutorial 3: Type Effectiveness** — Fight weak enemy, show damage multipliers
- [ ] 1.2.4 **Tutorial 4: Defensive Stances** — Teach Brace vs Dodge decision
- [ ] 1.2.5 **Tutorial 5: Positioning** — Demonstrate flanking advantage
- [ ] 1.2.6 **Tutorial 6: Full Combat** — All mechanics unlocked

### 1.3 Tutorial Skip Option
- [ ] 1.3.1 Add "Skip Tutorial" button for experienced players
- [ ] 1.3.2 Store tutorial completion in player save data
- [ ] 1.3.3 Allow re-accessing tutorials from settings menu

**Estimated Time:** 8-12 hours

---

## Phase 2: Simplified Combat Mode ✅ IMPLEMENTED

**Goal:** Offer a "Simple Combat" mode that reduces complexity for casual players.

### 2.1 Simple Combat Configuration
- [x] 2.1.1 Add `combat_mode` setting: `SIMPLE` | `ENHANCED` — Added to `game_config.gd`
- [x] 2.1.2 Simple mode reduces moves from 4 → 2 (Standard + 1 Special) — Implemented in `combat_selection_ui.gd`
- [x] 2.1.3 Simple mode removes Advantage/Disadvantage display (just roll d20) — Configurable via mode_config
- [x] 2.1.4 Simple mode auto-selects defender stance (always Brace) — Implemented auto-stance
- [x] 2.1.5 Extend timer to 15 seconds in Simple mode — Added `SIMPLE_MODE_TIME_LIMIT`

### 2.2 Type Effectiveness Simplification (Simple Mode)
- [x] 2.2.1 Reduce damage types: Physical, Magic, Elemental (3 instead of 6) — Added to `combat_balance_config.gd`
- [x] 2.2.2 Show "STRONG" / "WEAK" / "NEUTRAL" labels prominently — Implemented in UI
- [x] 2.2.3 Use color coding: Green = good, Red = bad, White = neutral — Added to Simple Mode text

### 2.3 Difficulty Settings
- [x] 2.3.1 Add AI difficulty slider (Easy, Normal, Hard) — Added `AIDifficulty` enum
- [x] 2.3.2 Easy AI makes suboptimal move choices — Added `AI_MOVE_WEIGHTS` config
- [x] 2.3.3 Easy AI has slower reaction (uses Standard move more often) — Weighted in config

**Estimated Time:** 6-8 hours
**Actual Time:** ~4 hours
**Status:** ✅ Core implementation complete. UI toggle for mode switch pending.

---

## Phase 3: Combat UI Improvements

**Goal:** Reduce visual clutter and surface relevant information contextually.

### 3.1 Move Button Redesign
- [ ] 3.1.1 Redesign move buttons with clearer visual hierarchy
    - Large: Move Name
    - Medium: Power + Accuracy (icons, not text)
    - Small: Cooldown indicator
- [ ] 3.1.2 Add move type icons (⚔️ Standard, 💥 Power, 🎯 Precision, ✨ Special)
- [ ] 3.1.3 Show predicted damage range on hover
- [ ] 3.1.4 Use color-coded borders based on type effectiveness vs current target
- [ ] 3.1.5 Add pulsing highlight on "recommended" move for new players

### 3.2 Combat Prediction Preview
- [ ] 3.2.1 Show "Expected Damage: XX-YY" when hovering over a move
- [ ] 3.2.2 Show hit chance percentage (e.g., "78% to hit")
- [ ] 3.2.3 Preview type effectiveness before selecting move
- [ ] 3.2.4 Show "If you use this move:" summary panel

### 3.3 Combat Log / History
- [ ] 3.3.1 Add collapsible combat log panel showing recent events
- [ ] 3.3.2 Log entries explain what happened (e.g., "Attack missed because d20=4 < DC=15")
- [ ] 3.3.3 Color code log entries (green = good, red = bad)
- [ ] 3.3.4 Allow clicking log entries for detailed breakdown

### 3.4 Timer Improvements
- [ ] 3.4.1 Add timer sound cues at 5s and 3s remaining
- [ ] 3.4.2 Flash timer when < 3 seconds
- [ ] 3.4.3 Show what will happen on timeout (default move/stance)
- [ ] 3.4.4 Add "Thinking..." animation while waiting for opponent

### 3.5 Stance Selection Improvements
- [ ] 3.5.1 Add clear descriptions for each stance in UI
- [ ] 3.5.2 Show when each stance is most useful (e.g., "Best vs Power moves")
- [ ] 3.5.3 Highlight recommended stance based on enemy's likely attack
- [ ] 3.5.4 Add stance comparison view (side-by-side pros/cons)

**Estimated Time:** 10-14 hours

---

## Phase 4: Information Architecture

**Goal:** Make information discoverable without overwhelming the player.

### 4.1 Type Chart Quick Reference
- [ ] 4.1.1 Add "?" button that opens Type Chart overlay
- [ ] 4.1.2 Type Chart shows all matchups with icons
- [ ] 4.1.3 Highlight current attacker vs defender matchup
- [ ] 4.1.4 Store in a closable popup (not full screen takeover)

### 4.2 Troop Info Cards
- [ ] 4.2.1 Create detailed troop info card accessible via right-click
- [ ] 4.2.2 Show all 4 moves with detailed descriptions
- [ ] 4.2.3 Show troop's reaction ability
- [ ] 4.2.4 Show type resistances/weaknesses
- [ ] 4.2.5 Show stat breakdown (HP, ATK, DEF, SPD)

### 4.3 Contextual Hints
- [ ] 4.3.1 Show contextual tips during combat selection phase
- [ ] 4.3.2 Hint examples:
    - "Your opponent is on Forest cover! You have Disadvantage."
    - "This move is Super Effective against the target!"
    - "Warning: This move is on cooldown after use."
- [ ] 4.3.3 Allow disabling hints in settings

### 4.4 Move Tooltip Enhancements
- [ ] 4.4.1 Expand existing `MoveTooltipUI` with more details
- [ ] 4.4.2 Show cooldown status and turns remaining
- [ ] 4.4.3 Show special effects (status application, AoE pattern)
- [ ] 4.4.4 Show damage type with visual icon

**Estimated Time:** 6-8 hours

---

## Phase 5: Combat Feedback Improvements

**Goal:** Make combat outcomes feel fair and understandable.

### 5.1 Roll Visualization
- [ ] 5.1.1 Add animated dice roll (3D dice or 2D sprite animation)
- [ ] 5.1.2 Show dice result prominently before comparison
- [ ] 5.1.3 Add suspense delay before revealing hit/miss
- [ ] 5.1.4 Celebrate critical hits with special effects
- [ ] 5.1.5 Soften critical miss with encouraging message

### 5.2 Damage Number Display
- [ ] 5.2.1 Show floating damage numbers above target
- [ ] 5.2.2 Color code: Red = normal, Gold = crit, Orange = super effective
- [ ] 5.2.3 Show small breakdown icons (🔥 = fire damage, etc.)
- [ ] 5.2.4 Include heals as green floating numbers

### 5.3 Status Effect Feedback
- [ ] 5.3.1 Show status effect icon on affected unit
- [ ] 5.3.2 Add status effect application animation
- [ ] 5.3.3 Show turns remaining on status effect hover
- [ ] 5.3.4 Play unique sound for each status type

### 5.4 Reaction Feedback
- [ ] 5.4.1 Highlight when a reaction triggers
- [ ] 5.4.2 Show reaction name and effect in combat log
- [ ] 5.4.3 Add unique animation for each reaction type
- [ ] 5.4.4 Explain why reaction triggered (e.g., "Riposte: Enemy missed!")

**Estimated Time:** 8-10 hours

---

## Phase 6: Practice Mode

**Goal:** Allow players to experiment with combat without stakes.

### 6.1 Practice Arena
- [ ] 6.1.1 Add "Practice Mode" option from main menu
- [ ] 6.1.2 Allow selecting any troop vs any enemy
- [ ] 6.1.3 Reset HP after each exchange
- [ ] 6.1.4 No timer in practice mode
- [ ] 6.1.5 Show all hidden calculations in detail

### 6.2 Move Encyclopedia
- [ ] 6.2.1 Create browsable encyclopedia of all moves
- [ ] 6.2.2 Filter by troop, damage type, move type
- [ ] 6.2.3 Sort by power, accuracy, cooldown
- [ ] 6.2.4 Mark moves as "Favorites" for quick access

### 6.3 Damage Calculator
- [ ] 6.3.1 Add tool to calculate damage before combat
- [ ] 6.3.2 Select attacker, defender, move
- [ ] 6.3.3 Show expected damage range with breakdown
- [ ] 6.3.4 Toggle positioning modifiers (flanking, cover, etc.)

**Estimated Time:** 8-10 hours

---

## Phase 7: AI Improvements for Fair Play

**Goal:** Make AI opponents fun to fight at all skill levels.

### 7.1 Difficulty Scaling
- [ ] 7.1.1 **Easy AI**: Uses random moves weighted toward Standard
- [ ] 7.1.2 **Normal AI**: Uses type-effective moves when available
- [ ] 7.1.3 **Hard AI**: Optimal move selection, considers positioning
- [ ] 7.1.4 Add adaptive difficulty (adjust if player is struggling)

### 7.2 AI Personality Hints
- [ ] 7.2.1 Show AI "thinking" messages (humanizes opponent)
- [ ] 7.2.2 AI occasionally makes "readable" moves for counterplay
- [ ] 7.2.3 AI announces impactful moves ("I'll crush you!")

**Estimated Time:** 4-6 hours

---

## Implementation Priority

| Priority | Phase | Impact | Effort | Recommendation |
|----------|-------|--------|--------|----------------|
| 🔴 HIGH | Phase 3 (UI Improvements) | High | Medium | Start here - biggest bang for buck |
| 🔴 HIGH | Phase 1 (Tutorial) | High | High | Essential for new players |
| 🟡 MEDIUM | Phase 4 (Information) | Medium | Low | Quick win |
| 🟡 MEDIUM | Phase 5 (Feedback) | High | Medium | Polish that delights |
| 🟢 LOW | Phase 2 (Simple Mode) | Medium | Medium | Optional for casual audience |
| 🟢 LOW | Phase 6 (Practice) | Low | High | Nice-to-have |
| 🟢 LOW | Phase 7 (AI) | Medium | Low | Improves replayability |

---

## Quick Wins (Implement First)

These changes can be implemented quickly with high impact:

1. **Hit Chance Display** (Phase 3.2.2) — Show percentage hit chance
2. **Type Effectiveness Labels** (Phase 3.1.4) — Color-code move buttons
3. **Extended Timer Option** (Phase 2.1.5) — Let new players extend timer
4. **Contextual Hints** (Phase 4.3) — Help new players make decisions
5. **Combat Log** (Phase 3.3) — Explain what happened after combat

---

## Metrics for Success

Track these metrics to evaluate the refactoring:

| Metric | Current (Estimated) | Target |
|--------|---------------------|--------|
| Tutorial Completion Rate | N/A | > 80% |
| First Combat Win Rate | ~50% | > 60% |
| Average Selection Time | < 10s (forced) | 6-8s (natural) |
| Combat Engagement (replays) | Unknown | +20% |
| "Confused" Feedback | High | Minimal |

---

## Technical Considerations

### New Files to Create
- `scripts/ui/tutorial_combat_ui.gd` — Tutorial overlay system
- `scripts/ui/combat_hints.gd` — Contextual hint system
- `scripts/ui/type_chart_ui.gd` — Type effectiveness reference
- `scripts/ui/move_encyclopedia_ui.gd` — Move browser
- `scripts/ui/damage_calculator_ui.gd` — Damage preview tool
- `scripts/gameplay/practice_mode.gd` — Practice arena logic
- `scripts/gameplay/tutorial_combat_manager.gd` — Tutorial combat logic

### Files to Modify
- `combat_selection_ui.gd` — Add hit chance, damage preview, hints
- `combat_resolution_ui.gd` — Improve roll visualization
- `combat_manager.gd` — Add prediction methods
- `game_manager.gd` — Add practice mode, tutorial state
- `move_tooltip_ui.gd` — Expand with more info
- `game_config.gd` — Add `combat_mode`, `tutorial_complete` settings

### Backward Compatibility
- All changes should be **additive** — existing gameplay unaffected
- New settings default to enhanced mode for existing players
- Save game format should not require migration

---

## Timeline Estimate

| Week | Focus |
|------|-------|
| Week 1 | Phase 3 (UI Improvements) — Quick Wins |
| Week 2 | Phase 1.1-1.2 (Tutorial System Basics) |
| Week 3 | Phase 4 (Information Architecture) |
| Week 4 | Phase 5 (Combat Feedback) |
| Week 5 | Phase 1.3, Phase 2 (Tutorial Completion + Simple Mode) |
| Week 6 | Phase 6, Phase 7 (Practice Mode + AI), Polish |

**Total Estimated Time:** 50-68 hours over 6 weeks

---

## Appendix: Player Personas

### Persona 1: "The Newcomer" (Primary Target)
- Never played strategy games
- Gets overwhelmed by too many options
- Needs clear guidance and feedback
- Wants to feel successful quickly

### Persona 2: "The Casual"
- Plays occasionally, forgets mechanics between sessions
- Appreciates reminders and tooltips
- Values quick, low-commitment sessions

### Persona 3: "The Strategist" (Current Audience)
- Enjoys complexity and optimization
- Wants access to all information
- May skip tutorials but uses reference tools

---

*Document Version: 1.1*
*Created: 2025-12-24*
*Last Updated: 2025-12-24*
*Related Documents: enhanced-combat-system.md, enhanced-combat-implementation-plan.md*

---

## Changelog

### v1.1 (2025-12-24)
- ✅ **Phase 2 Complete**: Implemented Simple Combat Mode
  - Added `CombatMode` enum (SIMPLE, ENHANCED) to `game_config.gd`
  - Added simplified damage types (Physical, Magic, Elemental) to `combat_balance_config.gd`
  - Added AI difficulty settings (Easy, Normal, Hard)
  - Updated `combat_selection_ui.gd` with:
    - Move filtering (2 moves in Simple Mode)
    - Auto-defender stance
    - Extended timer (15s)
    - Hit chance preview
    - Power star rating
    - Simplified effectiveness display
    - Recommended move highlighting
  - Updated `game_manager.gd` with mode setters/getters
  - Updated `main.gd` to propagate combat mode to UI
