# Asset Optimization Plan — Fantasy World: The Game (v8 — FINAL)

## 🖥️ Locked-In Specs
| Parameter | Value |
|---|---|
| Target Resolution | 1080p–1440p |
| Target GPU | Entry-Level (~4GB VRAM, GTX 1060 / RX 580 class) |
| Hard VRAM Ceiling | **3.5 GB** |
| GI | SDFGI |
| Bottlenecks | VRAM & Loading Times |
| Units on Board | Max 15 (8 player + 7 NPC) |
| Biomes | 6 types, **coexisting simultaneously** |
| Peak Decorations | 500+ — ✅ Already `MultiMeshInstance3D` |
| Grass | ✅ Already `MultiMeshInstance3D` per tile — safe |
| Max Mines on Board | **10** (5 per player × 2 players) |
| Card Previews | Live 3D model (kept — see note below) |

---

## ✅ Confirmed Safe Systems (No Action Needed)

### Grass System
- Already uses `MultiMeshInstance3D` per tile.
- At High quality: up to ~48,000 blades (Plains). GrassSystem doc itself notes 100k+ is comfortable.
- Shadows disabled by default — correct for performance.
- **No structural changes needed.** Only tweak: consider setting default quality to `MEDIUM` (2) for entry-level GPU users instead of HIGH.

### Decoration System
- Already `MultiMeshInstance3D` — batches all instances of a mesh into one draw call.
- Only missing: LODs on the individual mesh assets.

---

## ⚠️ Key Findings

### Mine VRAM Worst-Case
- Max 10 mines on board (5 per player).
- All 5 *level variants* (lvl1–lvl5) are always in VRAM regardless of what's on the board.
- After optimization (Draco + 512px textures): ~21 MB total on disk, ~5–10 MB VRAM. Acceptable.

### 6 Coexisting Biomes = 30 Textures Always in VRAM
- 6 biomes × 5 PBR maps = **30 terrain textures**
- Uncompressed at 2K RGBA: ~480 MB VRAM
- VRAM Compressed (S3TC) at 2K: **~120 MB** — well within budget
- **This single setting in Godot's Import tab is the highest-leverage action available.**

### Card Preview — Keep as Live 3D
Changing to static 2D renders would save ~0 VRAM at runtime (characters are already in memory for the board). The only gain would be eliminating a SubViewport render. Given the requirement for **same visual quality**, keeping live 3D is the correct call. The real fix is just optimizing the 3D models themselves.

---

## 🎨 Texture Budget (Final)

| Surface | Resolution | Format | VRAM (Compressed) |
|---|---|---|---|
| Tavern Hero (Foreground) | **2K** | WebP/JPG | ~4 MB |
| Tavern Mid-room | **1K** | WebP/JPG | ~1 MB |
| Tavern Far (dim, shadowed) | **512px** | JPG | ~0.25 MB |
| Biome Diffuse / Normal | **2K** | JPG | ~4 MB each |
| Biome Roughness / AO | **1K** | JPG Grayscale | ~1 MB each |
| Character (current still) | **1K** | GLB Embedded | ~1 MB |
| Character (future rigged) | **Shared 2K Atlas** | External | ~4 MB total |
| Mine Props | **512px** | GLB Embedded | ~0.25 MB each |
| Decoration Props | **512px** | GLB Embedded | ~0.25 MB each |

---

## 🔺 Polygon Budget (Final)

| Asset | LOD0 (Close) | LOD1 (Mid) | LOD2 (Far) | Notes |
|---|---|---|---|---|
| Grand Tavern (post-cull) | **< 300k** | — | — | No LOD; fixed camera, cull instead |
| Character — current still | **50k** | **10k** | **2k** | Placeholder; don't over-invest |
| Character — future rigged | **15k–25k** | **5k** | **800** | Industry standard |
| NPC | **30k** | **8k** | **1k** | Slightly simpler than player chars |
| Mine Prop (per level) | **30k–50k** | **8k** | **1k** | 5 GLBs always in VRAM |
| Decoration | **10k–20k** | **3k–5k** | **< 500** | 500+ instances; LODs critical |

### LOD Transition Distances (Table Scale)
The board is tabletop scale — LOD distances must be much tighter than a typical open-world game.

| LOD Level | Switch Distance | Equivalent | Reasoning |
|---|---|---|---|
| LOD0 → LOD1 | **5–8 units** | ~2–3 hex tiles away | Still clearly visible at this range |
| LOD1 → LOD2 | **15–20 units** | ~6–8 hex tiles away | Small on screen; silhouette only |
| LOD2 → Hidden | **35+ units** | Off the table edge | Godot's built-in visibility range |

---

## 📋 Final Priority Task List

### 🔴 1 — Background Music
```bash
ffmpeg -i input.mp3 -c:a libvorbis -q:a 3 -t 01:00:00 output.ogg
```
- Enable `Stream: ON` in Godot Import.
- **Savings: ~575 MB | VRAM: ~0 (streamed from disk)**

---

### 🔴 2 — Godot Import: VRAM Compression on ALL Textures
Before touching a single file in Blender, do this first — it's free and instant:
1. Select all textures in Godot's FileSystem dock.
2. Import tab → `Compress Mode: VRAM Compressed (S3TC/BC7)`.
3. Reimport.
- **VRAM Impact: up to ~360 MB saved on biome textures alone**

---

### 🔴 3 — Grand Tavern GLB (Blender)
1. Cull all geometry outside camera frustum.
2. `Alt+P > Clear and Keep Transformation` to safely unparent before deleting.
3. `P > Selection` in Edit Mode to isolate visible geometry.
4. Re-export: `Embed Textures: OFF`.
- **Savings: ~412 MB disk**

---

### 🔴 4 — Tavern Textures (3-Tier)
| Zone | Resolution | Reasoning |
|---|---|---|
| Foreground hero | 2K | Camera proximity demands it |
| Mid-room | 1K | Acceptable at distance |
| Far wall | 512px | Dim atmosphere makes this invisible |

- Convert all PNG → WebP (lossy) or JPG.
- Delete textures from culled geometry.
- **Savings: ~357 MB disk | ~200–400 MB VRAM**

---

### 🟠 5 — Decoration LODs
1. Add **3 LOD levels** to every decoration mesh in Blender (LOD0 / LOD1 / LOD2).
2. 512px textures per prop.
3. Draco compression on export.
- **Savings: ~195 MB disk | Critical for 500+ instance FPS**

---

### 🟠 6 — Character GLBs (Temporary Stills)
1. **LOD0**: Decimate to ~50k tris (base quality for close camera and card preview).
2. **LOD1**: Decimate to ~10k tris (mid-distance on board).
3. **LOD2**: Decimate to ~2k tris (distant/background — silhouette only).
4. 1K embedded textures.
5. Draco compression on export.
6. In **Godot Import → Advanced**: assign the 3 meshes as LOD0/LOD1/LOD2 at the distances defined in the polygon budget table above.
- **Don't over-invest on geometry quality — these will be replaced with rigged versions.**
- **Savings: ~741 MB disk | Significant render thread savings at 13 units**

---

### 🟡 7 — Mine Prop GLBs
1. **LOD0**: ~30k–50k tris (close camera / card preview).
2. **LOD1**: ~8k tris (mid-board view).
3. **LOD2**: ~1k tris (far side of board).
4. 512px embedded textures.
5. Draco compression on export.
6. In **Godot Import → Advanced**: assign LOD distances to match table above.
- **Savings: ~192 MB disk | Up to 10 mines on board simultaneously**

---

### 🟡 8 — Biome Terrain Textures
- Normal + Diffuse: 2K.
- Roughness / AO: 1K Grayscale.
- All VRAM Compressed in Godot Import (covered by Priority 2).
- **Savings: ~55 MB disk | ~360 MB VRAM**

---

### 🟢 9 — SFX WAVs
```bash
find assets/audio/sfx -name "*.wav" -exec sh -c \
  'ffmpeg -i "$1" -c:a libvorbis -q:a 4 "${1%.wav}.ogg"' _ {} \;
```
- **Savings: ~4 MB**

---

## 🧠 Architecture Notes

### SDFGI Recommended Settings
```
Cascades:        4
Min Cell Size:   0.25
Max Distance:    30m
Energy:          Low (preserves dim atmosphere)
```
Expected VRAM cost: **~200–400 MB**.

### Future Rigged Characters
- **Use a shared texture atlas** across all characters: 1 × 2K albedo + 1 × 2K normal instead of 13 individual sets.
- Saves hundreds of MB of VRAM at runtime when all characters are on the board.

### Background Render Thread
Once the assets are optimized, we should move the GLB loading to a background thread. With up to 15 units and 10 mines, this will prevent the main thread from hitching during late-game spawns.

### Grass Default Quality
- Consider defaulting to `MEDIUM` (55% density, high-poly mesh) instead of `HIGH` for entry-level GPUs.
- Plains at MEDIUM: ~33,000 blades vs ~48,000 at HIGH — a 30% reduction with minimal visual difference.
- Expose this as a **Graphics Quality** setting in the options menu.
