# Fantasy World — Task List
> **Legend:** 🐛 Bug Fix · ✨ New Feature · 🔧 Change/Improvement

---

## 🎨 Visual Design & Theme
*Set the visual direction first — everything else builds on this.*

- [ ] 🔧 **Establish Game Theme Direction** — Set the overall visual and tonal direction to match **Dark Souls / Elden Ring / The Witcher 3** — gritty, atmospheric, grounded dark fantasy. This should serve as the reference point for all future art, UI, and lighting decisions.
- [ ] 🔧 **Redo UI Theme** — Completely rebuild the UITheme based on the refreshed UI component designs. Fix all graphical UI bugs in the current theme. Apply the new theme consistently across all menus and pages — with special attention to the **Deck Selection page**.
- [ ] 🐛 **Remove Main Menu Background Dark Opacity** — The dark opacity overlay on the main menu background should be removed so the revolving cinematic backgrounds (Cozy Tavern, Battlefield Tent, etc.) show through clearly.
- [ ] ✨ **Add Menu Box Background Opacity** — Settings and related menus need a semi-transparent dark panel behind content for legibility. Apply to Settings and any other menus that currently lack it.
- [ ] ✨ **Add Witcher 3 / Dark Souls 2–Style Lighting** — Implement moody atmospheric lighting with warm/cool contrast, volumetric effects, and dramatic shadows. The current studio lighting should remain accessible as a toggleable option in the debug menu.

---

## 🗺️ Biome & World Generation
*Fix generation before layering decoration on top.*

- [ ] 🐛 **Fix Biome Generation Artifacts** — Strange lines and unnatural clumps are appearing in procedural biome generation. Investigate `biome_generator.gd` and smooth out these artifacts so biome boundaries look organic.
- [ ] ✨ **Add Nature Decoration to Biomes** — Populate biomes with environmental props — trees, rocks, bushes, grass clumps, fallen logs, etc. Evaluate whether the `biome_decoration` datapack is appropriate, or if a lighter-weight solution is needed to stay within performance targets.

---

## ⏳ Loading & Transitions
*Needs to be in place before camera and dice work is tested end-to-end.*

- [ ] ✨ **Terrain Generation Loading Screen** — After deck selection is complete, terrain generation (397 hexes, 7 biomes) should happen behind a dedicated loading screen rather than blocking the UI or happening invisibly.

---

## 📷 Camera & View Angles
*Fix foundational angles before building combat camera behavior on top.*

- [ ] 🐛 **Fix Default View Angle** — The default camera angle is too high and too far out. It should be lower and closer to the board for a more immersive, grounded perspective.
- [ ] 🐛 **Fix Character-Focus View Angle** — When the camera is focused on a character, it should similarly be lower and more close-up than it currently is.
- [ ] 🔧 **Combat Camera — Attack/Defense Selection** — During the attack or defense selection phase, the camera should automatically switch to a **front-quarter view** (similar to Mortal Kombat's perspective). The attack/defense choice UI should move to the **bottom-center** of the screen during this phase to avoid covering the characters.
- [ ] 🔧 **Combat Camera — Post-Selection** — Once choices are locked in, the camera should pivot to **frame the attacking character as the main subject**, while always keeping the opponent visible in shot.

---

## 🎲 Turn Start — Dice Roll

- [ ] 🔧 **Replace Dice GUI with In-World Dice Animation** — The current dice GUI at the start of the game should be replaced with an animation of dice being physically rolled on either side of the table. A button should appear at the **bottom-center** of the screen to throw the dice, with a **10-second auto-throw** if the player doesn't interact.

---

## 🖥️ HUD & In-Game UI
*Apply after the new UITheme is in place.*

- [ ] 🔧 **Replace Stat Fractions with Bars** — Anywhere stats are displayed as raw fractions (e.g. `80/150 HP`), replace with visual bars that contain the fraction as a label inside or beside them. Applies to the selected troop info panel and any other stat displays.
- [ ] 🔧 **Move Player Resources to the Top Bar** — Player **Gold** and **XP** should be displayed in the **top bar on the left side** of the screen. The mine count should be removed from the top bar entirely (see below).
- [ ] 🔧 **Replace Mine Count with Mine Cards in Hand** — Instead of a mine count in the top bar, each gold mine a player owns should appear as a **card in the player's hand** alongside their troop cards. The card should reflect the mine's current state at all times:
  - **Added** to hand when a new mine is placed
  - **Updated** (stats refresh on the card) when the mine is upgraded
  - **Removed** from hand when the mine is destroyed
- [ ] ✨ **Show Gold Mine Stats in Bottom-Left Panel** — When a player clicks on a mine card in their hand (or the mine on the board), its stats (level, gold per turn, upgrade cost) should appear in the **bottom-left info panel** — the same way troop stats are shown when a troop is selected.

---

## ⚙️ Settings

- [ ] ✨ **Hex Border Thickness Setting** — Add a setting under the Video or Controls tab that lets players customize the **thickness of hexagon border lines** for tile visibility. Useful for accessibility and personal preference.

---

## 🌐 Multiplayer

- [ ] ⏳ **Continue Host Game Page** — The Host Multiplayer Game screen is partially built. Continue its implementation per the UI/UX map — specifically the three-panel layout (World & Atmosphere, The Rulebook, Connectivity) with room code generation and the player list.

---

## 🎵 Audio

- [ ] ✨ **Add Main Menu Music** — Add a background music track that fits the dark fantasy theme and loops cleanly.
- [ ] ✨ **Add In-Game Music** — Add ambient/atmospheric background music during gameplay, separate from the main menu track. Should ideally vary by situation (exploration vs. combat).

---

## 💾 Save System

- [ ] ✨ **Save Game Feature (Local)** — Add the ability to save a local game in progress. Should integrate with the Pause Menu's existing "Save Game" flow — save slot selection, overwrite confirmation, save success toast, and auto-save every 5 turns.

---

## 🔩 Physics & Collision
*Last, since it's a full rebuild and touches movement throughout the game.*

- [ ] 🔧 **Redo Collision System from Scratch** — Full rebuild of collision mechanics:
  - **Walls:** Forward or backward movement into a wall should be countered and stopped. Turning the camera into a wall should also be blocked.
  - **Objects:** Same stopping behavior when walking into objects. If the **camera clips inside an object**, the object should go **fully transparent** until the camera exits, then revert to normal.
