# Fantasy World — Task List
> **Legend:** 🐛 Bug Fix · ✨ New Feature · 🔧 Change/Improvement

---

## 🎨 Visual Design & Theme

### 🔧 Establish Game Theme Direction
Set the overall visual and tonal direction to match **Dark Souls / Elden Ring / The Witcher 3** — gritty, atmospheric, grounded dark fantasy. This should serve as the reference point for all future art, UI, and lighting decisions.

### 🔧 Redo UI Theme
Completely rebuild the UITheme based on the refreshed UI component designs. Fix all graphical UI bugs discovered in the current theme. Once complete, apply the new theme consistently across all menus and pages — with special attention to the **Deck Selection page**, which needs the most work.

### 🐛 Remove Main Menu Background Dark Opacity
The dark opacity overlay on the main menu background should be removed. The revolving cinematic backgrounds (Cozy Tavern, Battlefield Tent, etc.) should show through clearly.

### ✨ Add Menu Box Background Opacity
Settings and related menus need a semi-transparent dark panel behind their content for legibility. Without this, text is hard to read over the background imagery. Apply to Settings and any other menus that currently lack it.

### ✨ Add Witcher 3 / Dark Souls 2–Style Lighting
Implement moody, atmospheric lighting inspired by The Witcher 3 and Dark Souls 2 — warm/cool contrast, volumetric effects, dramatic shadows. The current studio lighting should remain accessible as a toggleable option in the debug menu.

---

## 🖥️ HUD & In-Game UI

### 🔧 Replace Stat Fractions with Bars
Anywhere stats are currently displayed as raw fractions (e.g. `80/150 HP`), replace with **visual bars that contain the fraction as a label inside or beside them**. Applies to the selected troop info panel and any other stat displays.

### 🔧 Move Player Resources to the Top Bar
Player **Gold**, **XP**, and **Mine Count** should be displayed in the **top bar on the left side** of the screen, not in a separate panel.

### ✨ Show Gold Mine Stats in Bottom-Left Panel
When a player clicks on one of their gold mines, its stats (level, gold per turn, upgrade cost) should appear in the **bottom-left info panel** — the same way troop stats are shown when a troop is selected.

---

## 🗺️ Biome & World Generation

### 🐛 Fix Biome Generation Artifacts
Strange lines and unnatural clumps are appearing in procedural biome generation. Investigate the generation algorithm (`biome_generator.gd`) and smooth out these artifacts so biome boundaries look organic.

### ✨ Add Nature Decoration to Biomes
Populate biomes with environmental props — trees, rocks, bushes, grass clumps, fallen logs, etc. Evaluate whether the `biome_decoration` datapack is appropriate, or if a lighter-weight solution is needed to stay within performance targets.

---

## 📷 Camera & View Angles

All of the following view angle issues should be addressed together as a single camera pass.

### 🐛 Fix Default View Angle
The default camera angle is currently too high and too far out. It should be **lower and closer to the board** to give a more immersive, grounded perspective.

### 🐛 Fix Character-Focus View Angle
When the camera is focused on a character, it should similarly be **lower and more close-up** than it currently is.

### 🔧 Combat Camera — Attack/Defense Selection
During the attack or defense selection phase of combat, the camera should automatically **switch to a front-quarter view** (similar to Mortal Kombat's perspective) so players can clearly see the characters. The attack/defense choice UI should move to the **bottom-center** of the screen during this phase to avoid covering the characters.

### 🔧 Combat Camera — Post-Selection
Once attack and defense choices are locked in, the camera angle should **pivot to frame the attacking character as the main subject**, while always keeping the opponent visible somewhere in shot.

---

## 🎲 Turn Start — Dice Roll

### 🔧 Replace Dice GUI with In-World Dice Animation
The current dice GUI at the start of the game should be replaced with an **animation of dice being physically rolled on either side of the table**. 

A button should appear at the **bottom-center of the screen** prompting the player to throw the dice. If the player doesn't interact, the dice should **automatically throw after 10 seconds**.

---

## ⏳ Loading & Transitions

### ✨ Terrain Generation Loading Screen
After deck selection is complete, terrain generation (397 hexes, 7 biomes) should happen behind a **dedicated loading screen** rather than blocking the UI or happening invisibly. This loading screen is already referenced in the UI/UX map — implement it here.

---

## 🎵 Audio

### ✨ Add Main Menu Music
The main menu currently has no music. Add a background music track that fits the dark fantasy theme and loops cleanly.

### ✨ Add In-Game Music
Add ambient/atmospheric background music during gameplay. Should be separate from the main menu track and ideally vary by situation (exploration vs. combat).

---

## ⚙️ Settings

### ✨ Hex Border Thickness Setting
Add a setting under the Video or Controls tab that lets players **customize the thickness of hexagon border lines** for tile visibility. Useful for accessibility and personal preference.

---

## 🌐 Multiplayer

### ⏳ Continue Host Game Page
The Host Multiplayer Game screen is partially built. Continue its implementation per the UI/UX map — specifically the three-panel layout (World & Atmosphere, The Rulebook, Connectivity) with room code generation and the player list.

---

## 💾 Local Game

### ✨ Save Game Feature
Add the ability to save a local game in progress. This should integrate with the Pause Menu's existing "Save Game" flow (save slot selection, overwrite confirmation, save success toast). Auto-save every 5 turns as designed.

---

## 🔩 Physics & Collision

### 🔧 Redo Collision System from Scratch
The current collision mechanics need a full rebuild. Requirements:

- **Walls:** Moving forward into a wall or backing into one should be countered — the player should be physically stopped. Turning the camera into a wall should also be blocked.
- **Objects:** Same stopping behavior as walls when walking into objects. However, if the **camera clips into an object**, the object should become **fully transparent** while the camera is inside it, then revert to normal opacity once the camera exits.
