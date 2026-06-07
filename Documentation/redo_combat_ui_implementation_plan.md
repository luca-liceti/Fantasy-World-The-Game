# Combat Overhaul — Full Implementation Plan

Four streams, executed in sequence. No changes to game logic, damage formulas, or balance.

---

## Target Visual Design

![Combat UI Mockup](combat_ui_mockup_v2_1780787328764.png)

The panel anchors to the **bottom of the screen** (not a floating centred popup). The 3D board stays fully visible above it. Dark, atmospheric, premium. Cinzel font throughout.

---

## Stream 1 · Remove Dual Combat Mode

The `SIMPLE` / `ENHANCED` split is completely removed. One mode only.

### Files

#### [MODIFY] [game_config.gd](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/data/game_config.gd)
- Delete `CombatMode` enum, `DEFAULT_COMBAT_MODE`, `SIMPLE_MODE_CONFIG`, `ENHANCED_MODE_CONFIG`, `get_combat_mode_config()`.
- Remaining single config values baked directly where needed.

#### [MODIFY] [game_manager.gd](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/gameplay/game_manager.gd)
- Remove `set_combat_mode()`, `get_combat_mode()`.
- Remove `"combat_mode"` from game settings dict.

#### [MODIFY] [combat_selection_ui.gd](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/ui/combat_selection_ui.gd)
- Remove `combat_mode`, `mode_config`, `set_combat_mode()`.
- Remove all `if combat_mode == GameConfig.CombatMode.SIMPLE` branches.
- Remove `_get_filtered_moves()`, `_build_simple_move_text()`, `_get_power_stars()`, `_estimate_hit_chance()`, `_calculate_recommended_move()`, `_style_move_button_with_recommendation()`, `recommended_move_index`.
- Remove the `auto_defender_stance` early-return in `show_defender_selection()` — defender always sees the stance panel.

#### [MODIFY] [main.gd](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/main.gd)
- Remove `combat_selection_ui.set_combat_mode(...)` calls and `combat_mode` variable references.

#### Any settings/lobby UI with a "Combat Mode" toggle → remove the control.

---

## Stream 2 · Full Combat UI Visual Redesign

The existing `combat_selection_ui.gd` panel is a centred floating box with an arbitrary `650×500` fixed size, using generic `StyleBoxFlat` blocks with no coherent visual design. It is **completely rebuilt**.

### New Layout Architecture

```
┌─────────────────────────────────── FULL SCREEN WIDTH ────────────────────────────────────┐
│                                                                                           │
│                              [ 3D BOARD — always visible ]                                │
│                                                                                           │
├────── TOP INFO BAR (36px, full width) ────────────────────────────────────────────────── │
│  ⚔️ Medieval Knight → Four-Headed Hydra · DEF 120 · HP 185/200        ⏱ 8s [====----]  │
├──────────────────────────────────────────────────────┬────────────────────────────────── │
│  YOUR MOVE  (left 65% of panel)                      │  YOUR STANCE  (right 35%)         │
│                                                      │                                   │
│  [2×2 grid of move buttons]                          │  [4 stacked stance buttons]        │
│                                                      │                                   │
└──────────────────────────────────────────────────────┴────────────────────────────────── │
```

**Panel anchor:** `PRESET_BOTTOM_WIDE`, height ~310px. No overlay dimming — the board stays fully visible and interactive-looking behind it.

**Top border:** Single 2px gold line (`UITheme.C_GOLD.darkened(0.3)`).

**Background:** `Color(0.035, 0.035, 0.06, 0.97)` — very dark near-black with a slight blue undertone.

### Top Info Bar

Single `HBoxContainer` 36px tall, left-padded 16px, right-padded 16px:
- Left: `"⚔️ {attacker} → {defender}  ·  DEF {n}  ·  HP {n}/{n}"` — Cinzel 13pt gold
- Right: `"⏱ {n}s"` + thin `ProgressBar` 140px wide — fills gold, depletes red at 3s

### Move Buttons (attacker panel)

2×2 grid. Each button:
- Size: `(panel_width * 0.65 / 2 - 12) × 90px`
- Background: `Color(0.06, 0.06, 0.10)`
- Border 2px, color from move type:
  - Standard → `Color(0.55, 0.55, 0.62)` (silver-gray)
  - Power → `Color(0.78, 0.22, 0.22)` (deep red)
  - Precision → `Color(0.22, 0.45, 0.82)` (steel blue)
  - Special → `Color(0.55, 0.22, 0.80)` (royal purple)
- Corner radius: 10px
- Hover: border brightens + faint background color tint
- Selected: border glows, background lifts slightly
- Disabled (cooldown): bg `Color(0.04, 0.04, 0.06, 0.6)`, all text dimmed, border gray

**Button content layout** (left-aligned, padded 10px):
```
[ICON]  Move Name              [BADGE if super/weak]
        Tagline — plain English hook
        100% DMG  ·  No cooldown            ← tiny, dimmed
```

- Icon: emoji, 20pt
- Name: Cinzel Bold 14pt, `UITheme.C_GOLD`
- Tagline: Cinzel Regular 11pt italic, `UITheme.C_WARM_WHITE`
- Stats: Cinzel Regular 10pt, `UITheme.C_DIM`
- Badge (top-right, absolutely positioned): small RoundedRect pill
  - Super Effective: `Color(0.15, 0.55, 0.25)` bg, white text "✨ Super Effective" 9pt
  - Resisted: `Color(0.4, 0.4, 0.4)` bg, "↓ Resisted" 9pt
  - Immune: dark gray, "🛡 Immune" 9pt
- Cooldown overlay: semi-transparent gray mask + `"⏳ Ready in {n} turns"` centered, orange

**Tagline → Hook line table:**

| Move type | Icon | Hook |
|---|---|---|
| Standard | ⚔️ | `Reliable strike — safe every turn` |
| Power | 💥 | `Heavy blow — risky but hits hard` |
| Precision | 🎯 | `Careful strike — high accuracy` |
| Special | ✨ | `Unique ability — use it wisely` |

**Stats line builder:**
- Power: `"{n}% DMG"` (e.g. `"80% DMG"`, `"150% DMG"`)
- Accuracy (omit if ±0): `"+5 ACC"` or `"−3 ACC"`
- Cooldown: `"No cooldown"` or `"{n}-turn cooldown"`
- Effect chance (if any): `"· {n}% {effect name}"`

### Stance Buttons (defender panel)

4 buttons stacked vertically, full width of right column, each 60px tall, 6px gap.

Same dark background, border color:
- Brace: `Color(0.28, 0.45, 0.75)` (steel blue)
- Dodge: `Color(0.28, 0.72, 0.35)` (forest green)
- Counter: `Color(0.82, 0.50, 0.10)` (amber)
- Endure: `Color(0.75, 0.20, 0.20)` (crimson)

Selected stance: gold glow border `UITheme.C_GOLD_BRIGHT`, faint gold bg tint.

**Button content** (left-aligned):
```
[ICON]  Stance Name
        Tagline hook
        Stat line                ← tiny, dimmed
```

**Tagline table:**

| Stance | Icon | Hook | Stats |
|---|---|---|---|
| Brace | 🛡️ | `Tank the hit — less damage, no knockback.` | `+3 DEF · −20% damage` |
| Dodge | ⚡ | `Try to sidestep — harder to hit you.` | `+5 Evasion` |
| Counter | ↩️ | `Gamble — if they miss, you hit back.` | `50% ATK on miss` |
| Endure | 💪 | `Last resort — survive a fatal blow at 1 HP.` | `Once per match` |

Endure shows `"(Used)"` dimmed badge when `endure_uses_remaining <= 0`.

### Ready Button

Replaced with a `"✅ CONFIRM"` button using `UITheme.apply_hud_button()`, anchored bottom-right of the panel. Pressing it locks in the selection. Disappears once locked (shows `"⏳ Waiting..."` label instead).

### Positioning Modifiers Row

Single line between the info bar and the two columns, shown only when modifiers are active:
- `"⚔️ Flanking (+3 to hit)  ·  🌲 Cover (+3 their DEF)"`
- Cinzel 11pt, gold, centered

### Files Modified

#### [MODIFY] [combat_selection_ui.gd](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/ui/combat_selection_ui.gd)
Complete rewrite of `_create_ui()` and all sub-builders. Logic for signal emissions, timer, and state tracking is preserved.

---

## Stream 3 · Remove DiceUI Popup → Split-Screen 3D Dice

### What is removed

- `DiceUI` popup panel (the overlaid "ATTACKER vs DEFENDER" number card) — no longer shown.
- `CombatResolutionUI` popup — no longer shown.
- Both are replaced by a purely 3D camera sequence.

### New Flow

1. Combat resolves → `_on_combat_resolved(result)` fires.
2. A new `CombatDiceSplitUI` node takes over the camera.
3. The viewport is split 50/50 using two `SubViewportContainer` nodes, each with their own `Camera3D`.
4. Two 3D dice are spawned simultaneously — one on each player's side (reusing `P1_SETTLE` / `P2_SETTLE` coords from `FirstMoveDiceUI`).
5. Both dice tumble simultaneously (~1.6s, same as existing launch logic).
6. Dice settle → each half shows a minimal HUD overlay:
   ```
   🎲 Rolled 17 + 8 = 25
   ```
   Cinzel 18pt gold, bottom-center of each half.
7. Result banner fades in full-width at bottom-center of screen:
   - Hit: `"✓ HIT — 47 damage"` green
   - Crit: `"⚡ CRITICAL HIT — 94 damage!"` gold, pulse animation
   - Miss: `"✗ Missed"` dimmed gray
   - If Endure: `"💪 Endured at 1 HP!"` crimson
   - If Counter: `"↩️ Counter! 32 damage back"` amber
   - If status applied: append `" · 🔥 Burned (3 turns)"` etc.
8. Auto-advance after **2.5 seconds** hold (or instant skip with any key press).
9. Camera restores → gameplay resumes.

### Camera Setup

Each SubViewport camera:
- Position: directly overhead the settled die, `pitch = 88°` (near-top-down), `distance = 5.5`
- Vertical divider: thin 2px `Color(UITheme.C_GOLD, 0.4)` line between the two halves
- Left half labeled `"PLAYER 1"` top-center, right half `"PLAYER 2"` — Cinzel 14pt gold

### New File

#### [NEW] [combat_dice_split_ui.gd](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/ui/combat_dice_split_ui.gd)

Public API:
```gdscript
func show_combat_roll(
    attacker_name: String, defender_name: String,
    atk_natural: int, atk_stat: int, atk_total: int,
    def_dc: int,
    attack_succeeded: bool, damage: int,
    is_critical: bool,
    result: Dictionary   # for status, counter, endure etc
) -> void

signal roll_complete()   # emitted when auto-advance fires
```

### Files Modified

#### [MODIFY] [dice_ui.gd](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/ui/dice_ui.gd)
Strip out the CanvasLayer panel UI. Keep `_spawn_combat_die`, `_launch_combat_die`, `_face_rotation_for`, `D20_FACE_MAP`, `_reduce_shininess` as utility methods callable by `combat_dice_split_ui.gd`.

#### [MODIFY] [combat_resolution_ui.gd](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/ui/combat_resolution_ui.gd)
Remove from flow. File kept but `show_resolution()` is no longer called.

#### [MODIFY] [main.gd](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/main.gd)
- Instantiate `CombatDiceSplitUI` instead of `DiceUI`.
- In `_on_combat_resolved()`: call `combat_dice_split_ui.show_combat_roll(...)`.
- Connect `combat_dice_split_ui.roll_complete` → cleanup handler.
- Remove `CombatResolutionUIScene` preload.

---

## Open Questions

> [!IMPORTANT]
> **Q1 — Panel height:** The mockup shows the combat panel at ~310px from the bottom. Is that comfortable, or should it be taller (more breathing room) / shorter (see more board)?

> [!IMPORTANT]
> **Q2 — Skip input for dice:** Any key press skips the 2.5s dice hold and advances immediately. Is that the right behaviour, or should the dice always play to completion (no skip)?

> [!IMPORTANT]
> **Q3 — Settings menu cleanup:** Is there a Custom Match / Lobby settings screen with a "Combat Mode" dropdown that needs to be found and removed?

> [!IMPORTANT]
> **Q4 — READY button:** Currently there's a separate "✅ READY" button to confirm a selection. Do you want to keep explicit confirmation (click move, then click READY), or should clicking a move/stance directly confirm it immediately with no secondary button?

---

## Verification Plan

1. Combat panel appears as bottom overlay (not centred popup) with board visible above.
2. All 4 move buttons display icon · name · tagline · stats correctly.
3. Cooldown badges, effectiveness badges render correctly.
4. All 4 stance buttons display with correct hooks and stats.
5. Brace is pre-selected (gold border) by default.
6. Confirming triggers the split-screen dice sequence.
7. Both dice animate simultaneously; labels show correct math.
8. Result banner shows correct outcome text.
9. Auto-advances after 2.5s; any key skips (if Q2 is yes).
10. `FirstMoveDiceUI` (draft roll) is completely unaffected.
11. No "Combat Mode" option appears anywhere in menus.
