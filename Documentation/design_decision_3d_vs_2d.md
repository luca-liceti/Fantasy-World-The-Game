# Design Decision: 3D vs 2D Systems

## Decision Required Before Asset Integration

This document outlines design decisions needed regarding 3D vs 2D implementations for dice and card systems.

---

## 1. Dice System

### Current Implementation (2D)
- **File:** `scripts/ui/dice_ui.gd`
- **Type:** 2D animated UI overlay
- **Features:**
  - Sprite-based dice animation
  - Fast, responsive
  - No physics simulation
  - Result shown via animated sprites

### Asset Plan Proposal (3D Physics)
- **Plan Section:** Phase 6 - Physical Dice System
- **Type:** RigidBody3D with physics simulation
- **Features:**
  - Realistic dice rolling physics
  - 3D model with face detection
  - Rolling arena with boundaries
  - Camera zoom during roll

### Recommendation: **Keep 2D Dice** ✅

**Rationale:**
1. **Performance:** 3D physics simulation is expensive for a simple random number
2. **Consistency:** Combat is fast-paced; 3D dice would slow down battles
3. **Implementation Cost:** 3D dice requires:
   - Custom 3D model with numbered faces
   - Physics material tuning
   - Face detection algorithm
   - ~8-12 hours additional work
4. **Player Experience:** Quick animated 2D dice feels responsive
5. **Combat Mode:** Simple Combat Mode benefits from faster resolution

**Alternative Enhancement (Optional):**
- Add 3D dice as "Cinematic Mode" toggle in settings
- Use 2D by default, 3D for dramatic moments (first blood, game-winning roll)

---

## 2. Card System

### Current Implementation (2D)
- **Files:** `scripts/ui/card_selection_ui.gd`, `scripts/ui/game_ui.gd`
- **Type:** 2D UI cards in CanvasLayer
- **Features:**
  - Texture-based card display
  - Hover effects (scale, glow)
  - Card stats overlay
  - Selection highlighting

### Asset Plan Proposal (3D Cards)
- **Plan Section:** Phase 4.5 - 3D Card Plane Setup
- **Type:** 3D quad planes with card textures
- **Features:**
  - 3D card planes (0.6 x 0.9 units)
  - Physical card positioning on table
  - Hover lift/tilt animations
  - Fan arrangement in 3D space

### Recommendation: **Keep 2D Cards** ✅

**Rationale:**
1. **Readability:** 2D cards are always screen-facing, easier to read
2. **UI Precision:** 2D allows pixel-perfect stat display
3. **Mobile Future:** 2D cards scale better for potential mobile port
4. **Performance:** Less draw calls, no depth sorting issues
5. **Existing Code:** Significant work already done in 2D card UI
6. **Implementation Cost:** 3D cards would require:
   - Complete rewrite of card selection
   - 3D hover/selection logic
   - Camera coordination
   - ~10-15 hours additional work

**Alternative Enhancement (Optional):**
- Add "Card Table View" as separate 3D showcase scene
- Use 2D for gameplay, 3D for deck building preview

---

## Summary: Design Decisions

| System | Current | Plan | Decision | Action |
|--------|---------|------|----------|--------|
| Dice | 2D UI | 3D Physics | **Keep 2D** | No change needed |
| Cards | 2D UI | 3D Planes | **Keep 2D** | No change needed |

### Benefits of Keeping 2D:
- ✅ Faster implementation timeline
- ✅ Better performance on lower-end hardware
- ✅ Simpler debugging and maintenance
- ✅ Consistent with Simple Combat Mode accessibility goals
- ✅ No blocking dependencies for asset integration

### 3D Elements That WILL Be Implemented:
- ✅ **Troops:** 3D models on hex board
- ✅ **Hex Board:** 3D with biome materials
- ✅ **Gold Mines:** 3D building models
- ✅ **NPCs:** 3D character models
- ✅ **Particles:** 3D GPU particles for effects
- ✅ **Environment:** 3D lighting, HDRI sky

---

## Update Asset Integration Plan

Remove or mark as "OPTIONAL" the following sections:
- Section 6 (Physical Dice System): Mark as optional cinematic feature
- Section 4.5 (3D Card Plane Setup): Remove from Phase 1, move to "Nice to Have"

---

*Decision Date: 2025-12-24*
*Status: Approved - Proceed with 2D dice and cards*
