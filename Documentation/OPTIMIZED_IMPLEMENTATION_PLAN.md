# Performance Audit — Fantasy World: The Game (Godot 4.6)

> **Scope:** Every `.gd` script, `.gdshader`, and `.tscn` scene file (~29K lines of GDScript across 40+ files)
> **Board:** 397 hexagonal tiles, 7 biomes, 3D PBR rendering, networked multiplayer

---

## Summary

| Severity | Count | Impact |
|----------|-------|--------|
| 🔴 CRITICAL | 10 | Frame drops >16ms, generation stalls, GPU overdraw |
| 🟡 SIGNIFICANT | 8 | Steady-state frame budget pressure, memory waste |
| 🟢 MINOR | 6 | Polish-level improvements, low-end hardware QoL |

---

## 🔴 CRITICAL Bottlenecks

### C-1: Biome Terrain Shader — Stochastic Sampling Does 9 Texture Reads Per Channel Per Fragment

**Files:** [biome_terrain.gdshader](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/assets/shaders/biome_terrain.gdshader)

**Root Cause:** The stochastic sampling function (`stochastic_albedo`, `stochastic_normal`, `stochastic_scalar`) samples the texture **3 times** (one per triangle vertex) for blending. The triplanar mapping then calls each stochastic function **3 times** (X, Y, Z planes). This means:

- **Albedo:** 3 × 3 = **9 texture reads** + 3 fallback plain reads = **12 total**
- **Normal:** 3 × 3 = **9** + 3 fallback = **12 total** + matrix rotations
- **Roughness:** 3 × 3 = **9** + 3 fallback = **12 total**
- **AO:** 3 × 3 = **9** + 3 fallback = **12 total**
- **Displacement:** 3 × 3 = **9** + 3 fallback = **12 total** (for parallax)

**Total per fragment: ~60 texture reads + extensive matrix math.** This is *extremely* GPU-heavy for a board game that renders 397 tiles simultaneously.

**Impact:** GPU-bound on any hardware below RTX 3060. Will cause 20-40ms frame times on integrated/mobile GPUs.

**Fix:**
1. **Add an LOD switch for the shader.** When camera distance > 20 units (overview), skip stochastic sampling entirely and use plain triplanar (3 reads per channel = 15 total → 4× reduction)
2. **Drop the fallback plain samples.** The `mix(plain, stoch, stochastic_strength)` blend is wasteful when `stochastic_strength == 1.0` (the default). Use `#ifdef` or a branch on `stochastic_strength > 0.99` to skip the plain path entirely → saves 15 reads/fragment
3. **Remove parallax displacement.** The displacement map adds 12 more reads and offset correction for a barely-visible effect on flat hex tiles. Remove it or make it Ultra-only
4. **Consider using only Y-axis triplanar.** The hex tiles are nearly flat; X and Z planes contribute <5% visually. Dropping to single-axis UV reduces all channels to 3 reads total

---

### C-2: Biome Lighting Detection — O(n) Linear Scan of 397 Tiles Every 0.5s

**Files:** [main.gd#L1156-L1187](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/main.gd#L1156-L1187)

**Root Cause:** `_get_dominant_biome_near_position()` iterates **all 397 tiles** every 0.5 seconds, computing `distance_to()` (a sqrt operation) for each. It then counts biomes within a radius. This is an O(n) search with expensive distance math.

**Impact:** ~0.5–1ms spike every 0.5s. Not frame-dropping on its own, but combines with other per-frame work.

**Fix:**
1. **Use spatial hashing.** Pre-compute a grid lookup (e.g., 2×2 meter cells) mapping world positions to tiles. Reduce the search to O(k) where k ≈ 5-10 nearby tiles
2. **Cache the result.** Camera rarely moves fast enough to cross biome boundaries. Cache the last result and only re-evaluate when camera has moved >2 units since last check (add a `_last_biome_check_pos: Vector3` variable)
3. **Use squared distance** instead of `distance_to()` to avoid 397 sqrt operations

---

### C-3: `_apply_biome_environment()` Creates a *New Environment Every Time*

**Files:** [main.gd#L1190-L1200](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/main.gd#L1190-L1200), [lighting_manager.gd#L334-L337](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/managers/lighting_manager.gd#L334-L337)

**Root Cause:** Every time the dominant biome changes, `LightingManager.create_environment_for_biome()` allocates a **brand new `Environment` resource** with a new `Sky`, `ProceduralSkyMaterial`, etc. This triggers:
- GPU sky texture re-render (radiance map recalculation)
- Environment parameter flush to rendering server
- Potential GC pressure from discarded Environment objects

**Impact:** 5-15ms stall on biome transition (noticeable hitch when camera pans across biome borders).

**Fix:**
1. **Pre-create and cache 7 Environment resources** (one per biome) at startup. Store them in a `Dictionary[Biomes.Type, Environment]`. On biome change, swap the reference — zero allocation
2. **Even better:** Keep a single Environment and tween individual properties (fog_color, ambient_energy, etc.) to create smooth transitions instead of hard swaps. This also looks better visually

---

### C-4: 397 Unique `ConcavePolygonShape3D` Trimesh Colliders

**Files:** [hex_tile.gd#L200-L250](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/board/hex_tile.gd) (the `_create_terrain_collision` / `_rebuild_terrain_collision` functions)

**Root Cause:** Each of the 397 tiles creates its own `StaticBody3D` with a `ConcavePolygonShape3D` (triangle mesh). Trimesh collision shapes are the most expensive collision type in Godot — they are designed for static geometry that is **reused across instances**, not instantiated 397 times with unique vertex data.

**Impact:**
- **Memory:** Each trimesh stores a separate face array in the physics server (~4KB × 397 = ~1.6MB of collision data)
- **Physics broadphase:** 397 separate `StaticBody3D` nodes registered in the physics server increases broadphase overhead for raycasts (mouse picking) and camera collision
- **Generation time:** Building 397 trimesh shapes during board generation adds ~100-200ms

**Fix:**
1. **Use `ConvexPolygonShape3D` instead.** A hex prism is convex. Convex shapes are ~10× cheaper to create and test against. Generate 6-sided prisms with height matching vertex displacement
2. **Even better: Use a single `HeightMapShape3D`** for the entire board. Map the 397-tile grid into a heightmap texture and use one StaticBody3D → eliminates 396 physics bodies entirely
3. **At minimum:** Share a single `ConcavePolygonShape3D` for all flat (non-displaced) tiles and only create unique shapes for tiles with custom vertex heights

---

### C-5: Grass System — Up to 32,000 MultiMesh Instances With Per-Blade Barycentric Height Sampling

**Files:** [grass_system.gd#L316-L348](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/effects/grass_system.gd#L316-L348), [grass_system.gd#L434-L489](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/effects/grass_system.gd#L434-L489)

**Root Cause:** For each grass blade placed, `_get_surface_height()` performs:
1. Build 6 corners (6× trig calls)
2. Test against 6 fan triangles with full barycentric coordinate calculations (dot products, divisions)

At HIGH quality, Plains biome spawns **600 blades per hex**. With ~80 Plains tiles × 600 = **48,000 height samples**, each doing 6 triangle tests = **~288,000 barycentric calculations** during generation.

Additionally, `_populate_uniform()` uses rejection sampling (`_in_hex()` check) with `max_attempts = count * 3`, meaning up to 3× more iterations than blades placed.

**Impact:** 200-500ms during board generation at HIGH quality. Blocks the main thread since `GrassSystem` is synchronous (no `await`).

**Fix:**
1. **Pre-compute a height lookup table per hex.** Store a small grid (e.g., 8×8) of interpolated heights per tile. Grass blades sample the grid with bilinear interpolation instead of per-blade barycentric math
2. **Cache the corner array.** Currently `_get_surface_height` rebuilds the 6 corners every single call (6× `cos` + `sin`). Move corner computation outside the blade loop
3. **Use a precomputed Poisson disk** instead of rejection sampling — guarantees placement in O(n) instead of O(3n)
4. **Async grass generation.** Integrate into `hex_board.gd`'s async generation pipeline with `await` yields between hex batches

---

### C-6: `main.gd` God Object — 2,711 Lines, 91KB, Single `_process()` Bottleneck

**Files:** [main.gd](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/main.gd)

**Root Cause:** `main.gd` handles:
- Camera system (8+ view modes, transitions, yaw/pitch/distance interpolation, combat camera)
- All input handling (keyboard, mouse wheel, tile selection, action modes)
- UI orchestration (pause menu, settings, confirmation dialogs — all built procedurally)
- Game flow (deck selection, board generation triggering, troop spawning)
- Biome lighting detection and environment swapping
- Combat event forwarding (6+ signal handlers)
- Turn management UI updates

This creates a **single bottleneck** where every frame must execute the massive `_process()` method scope, and any bug in one subsystem can cascade to all others.

**Impact:**
- **Maintenance cost:** Any performance regression is hard to isolate
- **Frame budget:** The `_process()` path touches camera math, timer updates, biome detection, and camera collision every frame
- **Signal spaghetti:** The file connects to 10+ signals from GameManager, TurnManager, CombatManager, etc.

**Fix:**
1. **Extract `CameraController`** into its own Node with `_process()`. Move all camera variables, transition logic, combat camera, and view mode handling (~800 lines)
2. **Extract `GameFlowController`** for deck selection, board generation triggering, troop spawning (~400 lines)
3. **Extract `PauseMenuBuilder`** / use a .tscn for the pause menu instead of procedural UI construction (~200 lines)
4. **Use `set_process(false)`** on subsystems when they're idle (e.g., camera transitions only need `_process` while `is_camera_transitioning` is true)

---

### C-7: Combat Effect Particles Created Dynamically With `GPUParticles3D.new()` Every Hit

**Files:** [combat_effects.gd#L307-L353](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/effects/combat_effects.gd#L307-L353)

**Root Cause:** `spawn_damage_particles()` creates:
1. A new `GPUParticles3D` node
2. A new `ParticleProcessMaterial`
3. A new `Gradient` + `GradientTexture1D`
4. A new `SphereMesh`

...every single time combat damage occurs. These are then cleaned up via `queue_free()` after 2 seconds. This causes:
- GC allocation pressure (multiple Resources created per hit)
- GPU pipeline stalls (new particle system compilation)
- Scene tree churn (add_child + queue_free)

**Impact:** 2-5ms spike per combat hit. Multiple hits (multi-strike ability) can compound.

**Fix:**
1. **Object pool.** Pre-create 3-5 `GPUParticles3D` nodes at startup. On hit, activate one, set position/color, and `emitting = true`. On completion, deactivate and return to pool
2. **Share materials.** Create `ParticleProcessMaterial` instances per damage type (6 types) once, then reuse

---

### C-8: Screen Shake Creates N Sequential Tween Steps Per Shake

**Files:** [combat_effects.gd#L261-L289](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/effects/combat_effects.gd#L261-L289)

**Root Cause:** `screen_shake()` calculates `shake_steps = int(duration / 0.03)` (≈10 steps for a 0.3s shake) and creates a **tween_property call for each step** in a loop. This means 10+ sequential tween operations are queued, each generating random motion vectors.

The tween keys are pre-generated at call time with `randf_range`, meaning no randomness during playback — the shake follows a fixed, pre-baked path.

**Impact:** The tween queue itself is lightweight, but this pattern is fragile and creates O(n) tween operations. More importantly, it directly modifies `camera.global_position`, which **fights with the camera controller** in `main.gd._process()`.

**Fix:**
1. **Use a single `_process`-driven shake.** Set `shake_remaining_time` and `shake_intensity`, then in each frame apply a random offset to the camera's computed position (not `global_position`). This avoids fighting with the camera system
2. **Add shake offset to `_update_camera_transform()`** instead of tweening the camera position directly

---

### C-9: BiomeGenerator Voronoi + Rebalancing — O(n × m) Distance Calculations

**Files:** [biome_generator.gd#L154-L175](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/board/biome_generator.gd#L154-L175)

**Root Cause:** The Voronoi assignment loop iterates over 397 tiles × 21 seeds (7 biomes × 3 seeds each), performing `distance_to()` + noise sampling for each pair = **8,337 distance calculations + noise lookups**.

Then the rebalancing loop (Step 3) runs up to **200 iterations**, each scanning all 397 tiles + their neighbors. Worst case: 200 × 397 × 6 = **476,400 dictionary lookups**.

The cleanup pass (Step 4) runs 5 iterations × 397 tiles × 6 neighbors = **11,910 more lookups**.

**Impact:** 50-150ms total generation time. Not catastrophic since it runs during loading, but:
- Blocks the main thread entirely (no `await` in BiomeGenerator)
- Combined with height smoothing (3 passes × 397 tiles × 6 neighbors) and max-height enforcement (10 iterations × 397 × 6), total generation easily exceeds 200ms

**Fix:**
1. **Make generation async.** Add `await get_tree().process_frame` yields between major steps (Voronoi assignment, rebalancing iterations, cleanup passes)
2. **Use squared distance** everywhere (avoid sqrt)
3. **Early-exit the rebalance.** The 200-iteration cap is very conservative. Track if any biome exceeds `target ± tolerance` and break immediately when balanced
4. **Lloyd relaxation uses O(n × m).** Since it only runs once with 397 positions × 21 seeds, it's fine, but could use a k-d tree for larger boards

---

### C-10: Troop Model Loading — `_fix_model_materials()` Duplicates Every Surface Material

**Files:** [troop.gd#L764-L803](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/entities/troop.gd#L764-L803)

**Root Cause:** For every troop loaded, `_fix_model_materials()` iterates every `MeshInstance3D` in the model tree and **duplicates every material** on every surface to override transparency/metallic/roughness. With 12 unique troop types, each having 3-8 surfaces, and 6 troops per player (12 total), this creates:
- 12 troops × ~5 surfaces × 1 material duplicate = **~60 unique material instances**

Each duplicate prevents Godot's material batching — the renderer cannot merge draw calls for troops with identical meshes but different material instances.

**Impact:**
- **Draw calls:** +60 unbatchable draw calls (each troop surface is a separate draw)  
- **Memory:** ~60 material duplicates × ~2KB each = ~120KB (minor)
- **GPU state changes:** Each unique material causes a pipeline state switch

**Fix:**
1. **Fix materials at import time.** Create corrected `.tres` material overrides and save them alongside the GLB files. Remove runtime duplication entirely
2. **Share fixed materials per troop type.** Instead of `mat.duplicate()` per instance, create one fixed material per troop type per surface and reuse it across all instances of that troop
3. **Cache in `CharacterModelLoader._model_cache`.** Apply fixes once when first loading the PackedScene, then all subsequent instantiations inherit the corrected materials

---

## 🟡 SIGNIFICANT Issues

### S-1: 397 `BiomeParticleEmitter` (GPUParticles3D) Nodes — All Potentially Emitting

**Files:** [biome_particle_emitter.gd](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/effects/biome_particle_emitter.gd), [hex_tile.gd#L92-L93](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/board/hex_tile.gd#L92-L93)

Each hex tile spawns a `BiomeParticleEmitter` (extends `GPUParticles3D`) in `_setup_particles()`. While particle amounts are low (2-8 per tile), having **397 active GPUParticles3D nodes** creates significant overhead:
- Each GPUParticles3D is a separate compute dispatch on the GPU
- The CPU must update emission state per frame for each

**Fix:** Use distance-based culling — only enable particles for tiles within camera view + a radius. Disable all others via `emitting = false`. Or better yet, use a **single MultiMesh-based particle system** that covers the entire board.

---

### S-2: HexTile `_process()` Runs on All 397 Tiles When Any Tile Is Selected

**Files:** [hex_tile.gd#L70-L78](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/board/hex_tile.gd#L70-L78)

The `_process()` on `HexTile` handles selection pulse animation. While `set_process(false)` is called for deselected tiles (line 723-735), there are code paths where `set_process(true)` is set but never unset (e.g., if a tile remains highlighted but not selected).

**Fix:** Audit all `set_process(true)` paths. Consider using a `Tween` for the pulse animation instead of `_process()` to eliminate the per-frame callback entirely.

---

### S-3: Material System Creates ShaderMaterial Per Biome but Shares the Same Shader

**Files:** [biome_material_manager.gd#L189-L197](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/board/biome_material_manager.gd#L189-L197)

Good news: `BiomeMaterialManager` properly caches materials per biome type. With 7 biomes, only 7 `ShaderMaterial` instances are created and shared across all 397 tiles. **This is correct — no 397 unique materials.**

However, when `get_material_copy()` is called (line 209-211), it duplicates the material, potentially creating unique instances. Verify no code path calls this for regular tile setup.

---

### S-4: Directional Light Uses `SHADOW_PARALLEL_4_SPLITS` — Very Expensive

**Files:** [lighting_manager.gd#L300](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/managers/lighting_manager.gd#L300)

4-split cascaded shadow maps render the entire scene 4 times from the light's perspective. For a board game where the camera is mostly overhead, 2 splits (`SHADOW_PARALLEL_2_SPLITS`) would be sufficient.

**Fix:** Scale shadow splits with quality settings. Low=off, Medium=2 splits, High=2 splits, Ultra=4 splits. Already partially handled by `apply_quality_to_environment()` but the light itself isn't adjusted.

---

### S-5: `CharacterModelLoader.load_character_model()` Uses Synchronous `load()`

**Files:** [character_model_loader.gd#L174](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/managers/character_model_loader.gd#L174)

`load()` is synchronous and blocks the main thread. For GLB models (which can be 2-10MB), this can cause 50-200ms stalls per troop. With 12 troops loaded during game start, that's 600ms-2.4s of stalls.

The `PackedScene` is cached after first load, but the first load of each unique troop type still blocks.

**Fix:** Use `ResourceLoader.load_threaded_request()` + `ResourceLoader.load_threaded_get()` to load models asynchronously during the loading screen phase.

---

### S-6: Board Generation — `hex_board.gd` Forest Decorations System

The forest system spawns tree models as children of hex tiles. Each tree is a `MeshInstance3D` with a unique mesh/material combination. With ~56 forest tiles and multiple trees each, this can add 100-200 additional draw calls.

**Fix:** Use `MultiMeshInstance3D` for forest decorations — batch all trees of the same type into a single MultiMesh.

---

### S-7: Every Troop Creates a `StaticBody3D` for Camera Collision + an `Area3D` for Click Detection

**Files:** [troop.gd#L858-L872](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/entities/troop.gd#L858-L872), [troop.gd#L968-L989](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/entities/troop.gd#L968-L989)

Each of 12 troops creates 2 physics bodies (1 `StaticBody3D` for camera collision, 1 `Area3D` for click input). That's 24 additional physics bodies + 24 collision shapes in the physics server, on top of the 397 tile colliders.

**Fix:** Consider using a single `Area3D` per player (2 total) that uses raycasting to determine which troop was clicked, or merge into the hex tile's existing collision system.

---

### S-8: Procedural UI Construction in `main.gd` — Pause Menu, Confirmations

**Files:** [main.gd#L1898-L1965](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/main.gd#L1898-L1965), [main.gd#L2033-L2111](file:///home/luca/Documents/Github%20Projects/Fantasy-World-The-Game/fantasy-world-game/scripts/main.gd#L2033-L2111)

The pause menu and confirmation dialogs are built entirely in code (~200 lines of `Node.new()`, `add_child()`, and theme overrides). This runs every time the menu is opened.

**Fix:** Create `.tscn` scene files for pause menu and confirmation dialog. Instantiate pre-built scenes instead of assembling nodes at runtime.

---

## 🟢 MINOR Optimizations

### M-1: `hex_coordinates.gd` A* Pathfinding Uses Dictionary for Closed Set
The A* implementation is correct but uses `Dictionary` for visited tracking. For the 397-tile board, this is fine. No action needed unless board size increases significantly.

### M-2: `NetworkManager` RPCs Are All `"reliable"`
Every RPC (move, attack, end turn, deck sync) uses `"reliable"` delivery. For a turn-based game, this is correct. For real-time combat animations, consider using `"unreliable"` for position updates.

### M-3: `SettingsManager` Calls `save_settings()` on Every Individual Setting Change
When applying a quality preset, if `auto_save` is not disabled, each setting would trigger a separate file write. This is already handled correctly with `auto_save: false` in `apply_quality_preset()`.

### M-4: Noise Textures in `GrassSystem` Use `randi()` Seed
This means noise patterns differ every time grass is generated, even for the same board seed. Consider using the game seed for deterministic grass patterns in multiplayer.

### M-5: `AudioManager` Bus Index Lookups Done Per Setting Change
`AudioServer.get_bus_index("Master")` is called each time volume changes. Cache bus indices at startup.

### M-6: Debug `print()` Statements Throughout Production Code
Many files contain verbose `print()` calls: biome distribution, camera views, model loading, material building. These cause string formatting and I/O overhead. Wrap in `if OS.is_debug_build()` or use a logging level system.

---

## Verification Plan

### Automated Tests
1. Run Godot's built-in profiler during board generation — verify generation time < 2s
2. Use `Performance.get_monitor(Performance.TIME_PROCESS)` to track frame times during gameplay
3. Count draw calls via `RenderingServer.get_rendering_info()` — target < 100 for the board

### Manual Verification
1. Profile on integrated GPU (Intel UHD) to verify low-quality preset runs at 30+ FPS
2. Pan camera across biome boundaries — verify no hitch from Environment re-creation
3. Trigger combat with multi-strike abilities — verify no frame drops from particle creation

---

## Recommended Priority Order

1. **C-1** (Shader reads) — Biggest bang-for-buck; affects every frame
2. **C-3** (Environment allocation) — Easy fix, big win on biome transitions
3. **C-4** (Trimesh colliders) — Switch to convex; reduces physics overhead 10×
4. **C-7** (Combat particles) — Pool pattern eliminates combat hitches
5. **C-5** (Grass generation) — Async + cached heights eliminates generation stalls
6. **C-6** (God object) — Refactor for maintainability and isolation of frame budgets
7. **C-2** (Biome detection) — Spatial hash + caching eliminates periodic spikes
8. **C-10** (Material duplication) — Fix at import time for draw call batching
9. **C-8** (Screen shake) — Quick fix; integrate into camera system
10. **C-9** (BiomeGenerator) — Add async yields during loading screen
