# 🏰 Medieval Fantasy Board Game - Asset Integration Master Plan

## 📋 Project Overview

- **Visual Style:** Grounded High Fantasy (Manor Lords aesthetic + fantasy elements)
- **Theme Standard:** Realistic medieval materials with prominent magical effects
- **Target Hardware:** Scalable from work laptops to gaming PCs
- **Total Hexes:** 397 (flat with optional subtle height variation)
- **Quality System:** Granular settings with hardware-adaptive presets

---

## 📑 Table of Contents

### Phase 1: NOW (Core Gameplay Assets)
1. [Board & Hex System](#1️⃣-board--hex-system)
2. [Character Models (12 Troops + 3 NPCs)](#2️⃣-character-models-12-troops--3-npcs)
3. [NOW Animations (Attack, Damage, Death)](#3️⃣-now-animations-attack-damage-death)
4. [Card System (2D Art + 3D Planes)](#4️⃣-card-system-2d-art--3d-planes)
5. [Gold Mine Buildings](#5️⃣-gold-mine-buildings)
6. [Physical Dice System](#6️⃣-physical-dice-system)
7. [UI System (Medieval Stone/Iron/Wood Theme)](#7️⃣-ui-system-medieval-stoneironwood-theme)
8. [Lighting & Environment](#8️⃣-lighting--environment)
9. [Particle Effects (NOW - Basic Combat)](#9️⃣-particle-effects-now---basic-combat)
10. [Quality Settings System](#🔟-quality-settings-system)

### Phase 2: LATER (Polish & Advanced Features)
1. [Advanced Animations](#1️⃣-advanced-animations)
2. [Advanced Particle Effects](#2️⃣-advanced-particle-effects)
3. [Advanced Lighting & Post-Processing](#3️⃣-advanced-lighting--post-processing)
4. [Audio System](#4️⃣-audio-system-later-phase)
5. [Camera Enhancements](#5️⃣-camera-enhancements)
6. [Advanced UI](#6️⃣-advanced-ui)
7. [Polish & Optimization](#7️⃣-polish--optimization)
8. [Additional Features (Far Future)](#8️⃣-additional-features-far-future)

### Checklists & References
- [Implementation Checklist - Phase 1](#📝-implementation-checklist---phase-1-now)
- [Implementation Checklist - Phase 2](#📝-implementation-checklist---phase-2-later)
- [Quick Reference: Asset URLs](#🎯-quick-reference-asset-urls)
- [Asset Folder Structure](#📊-asset-folder-structure-final)

---

## 🛠️ Development Tools

### Godot MCP (Model Context Protocol) Server

Throughout the asset integration and implementation process, you can leverage the **godot-mcp** tool for enhanced productivity and debugging. This MCP server provides direct integration with Godot Engine.

**Available Tools:**
- `mcp_godot_create_scene` - Create new scene files for assets
- `mcp_godot_add_node` - Add nodes to scenes (MeshInstance3D, Sprite2D, etc.)
- `mcp_godot_load_sprite` - Load sprite textures into Sprite2D nodes
- `mcp_godot_save_scene` - Save scene modifications
- `mcp_godot_run_project` - Run project and capture output for testing
- `mcp_godot_stop_project` - Stop running project
- `mcp_godot_launch_editor` - Launch Godot editor
- `mcp_godot_get_project_info` - Retrieve project metadata
- `mcp_godot_get_debug_output` - Get debug output and errors
- `mcp_godot_export_mesh_library` - Export scenes as MeshLibrary resources

**Asset Integration Use Cases:**
- **Model Import Testing**: Quickly test imported 3D models by creating test scenes
- **Material Setup**: Programmatically configure materials with PBR textures
- **Batch Scene Creation**: Create multiple similar scenes (15 troop scenes, 7 biome variants)
- **Animation Testing**: Run project to verify animation imports and playback
- **Texture Validation**: Test texture imports and material assignments
- **Performance Testing**: Run project with different quality settings to test LODs
- **Debug Asset Issues**: Capture console output when assets fail to load

**Recommended Workflow:**
1. Import assets (models, textures) manually or via script
2. Use `mcp_godot_create_scene` to create container scenes
3. Use `mcp_godot_add_node` to add MeshInstance3D/Sprite2D nodes
4. Configure materials and properties programmatically
5. Use `mcp_godot_run_project` to test in-game appearance
6. Use `mcp_godot_get_debug_output` to catch import/loading errors
7. Iterate quickly without constant manual editor work

**Integration Points in This Plan:**
- **Phase 1.2 (Character Models)**: Batch create 15 troop scenes + 3 NPC scenes
- **Phase 1.3 (Animations)**: Test animation imports and playback
- **Phase 1.4 (Card System)**: Create 3D card plane scenes programmatically
- **Phase 1.7 (UI System)**: Rapid prototyping of UI scenes
- **Phase 1.10 (Quality Settings)**: Automated testing of different quality presets

**Note:** The godot-mcp tool is particularly valuable for repetitive asset integration tasks and can significantly reduce manual work in the Godot editor.

---

# 🎯 PHASE 1: NOW (Core Gameplay Assets)

## 1️⃣ Board & Hex System

### Hex Tile Base System

#### Flat Hex Geometry

- Create single hex mesh in Blender (6-sided, UV unwrapped)
- Export as `.glb` format
- Dimensions: 1 unit diameter, 0.05 unit thickness
- Import to Godot: `res://assets/models/hex_base.glb`

**Godot Import Settings (hex_base.glb):**
- Compression: VRAM Compressed
- Generate LODs: Enabled (3 levels: 100%, 50%, 25%)
- Mesh Compression: Enabled
- Physics: Disabled (use collision shape instead)

#### Optional Height Variation System

Create 3 hex variants with subtle displacement:
- `hex_flat.glb` (0.0 elevation)
- `hex_low.glb` (0.1-0.2 elevation - Swamp, Wastes)
- `hex_high.glb` (0.3-0.5 elevation - Peaks, Hills)

Toggle in Settings → Graphics → "Terrain Height Variation"


### Biome Textures (Poly Haven + AmbientCG)

> ✅ **DOWNLOAD STATUS:** All biome textures downloaded (Dec 2024)
> All textures: 4K resolution, PNG format, PBR workflow (Diffuse, Normal, Roughness, AO, Displacement)
> Local path: `res://assets/textures/biomes/`

#### 1. Enchanted Forest ✅

| Role | Asset Name | Source | Local File Prefix |
|------|------------|--------|-------------------|
| Primary | `forest_leaves_02` | Poly Haven | `enchanted_forest_primary_*` |
| Secondary | `brown_mud_leaves_01` | Poly Haven | `enchanted_forest_secondary_*` |
| Prop 1 | `bark_brown_01` | Poly Haven | `enchanted_forest_prop1_*` |
| Prop 2 | `bark_willow` | Poly Haven | `enchanted_forest_prop2_*` |
| Prop 3 | `coast_sand_rocks_02` | Poly Haven | `enchanted_forest_prop3_*` |

- **Color Grading:** Deep greens (#2D5016), brown earth (#3E2A1C)

#### 2. Frozen Peaks ✅

| Role | Asset Name | Source | Local File Prefix |
|------|------------|--------|-------------------|
| Primary | `snow_02` | Poly Haven | `frozen_peaks_primary_*` |
| Secondary | `aerial_rocks_02` | Poly Haven | `frozen_peaks_secondary_*` |
| Prop 1 | `cliff_side` | Poly Haven | `frozen_peaks_prop1_*` |
| Prop 3 | `asphalt_snow` | Poly Haven | `frozen_peaks_prop3_*` |

- **Color Grading:** Blue-white (#D4E4F7), gray stone (#6B7A8F)
- ⚠️ **Note:** `snow_field` is an HDRI, not a texture - excluded from download.

#### 3. Desolate Wastes ✅

| Role | Asset Name | Source | Local File Prefix |
|------|------------|--------|-------------------|
| Primary | `aerial_beach_01` | Poly Haven | `desolate_wastes_primary_*` |
| Secondary | `dry_ground_01` | Poly Haven | `desolate_wastes_secondary_*` |
| Prop 1 | `dry_ground_rocks` | Poly Haven | `desolate_wastes_prop1_*` |
| Prop 2 | `cracked_red_ground` | Poly Haven | `desolate_wastes_prop2_*` |
| Prop 3 | `coast_sand_05` | Poly Haven | `desolate_wastes_prop3_*` |

- **Color Grading:** Tan (#C9A66B), dry brown (#8B6F47)

#### 4. Golden Plains ✅

| Role | Asset Name | Source | Local File Prefix |
|------|------------|--------|-------------------|
| Primary | `grass_path_2` | Poly Haven | `golden_plains_primary_*` |
| Secondary | `rocky_terrain_02` | Poly Haven | `golden_plains_secondary_*` |
| Alt Primary | `Grass004` | AmbientCG | `golden_plains_alt_primary_*` |
| Prop 1 | `forrest_ground_01` | Poly Haven | `golden_plains_prop1_*` |
| Prop 2 | `Ground037` | AmbientCG | `golden_plains_prop2_*` |

- **Color Grading:** Golden yellow (#D4AF37), green (#6B8E23)
- ℹ️ **Note:** Original assets `grass_meadow`, `grass_path_1`, `ground_grass_gen_01` do not exist on Poly Haven. Replaced with equivalent alternatives that match the Manor Lords aesthetic.

#### 5. Ashlands ✅

| Role | Asset Name | Source | Local File Prefix |
|------|------------|--------|-------------------|
| Primary | `burned_ground_01` | Poly Haven | `ashlands_primary_*` |
| Secondary | `aerial_rocks_04` | Poly Haven | `ashlands_secondary_*` |
| Prop 1 | `cracked_concrete` | Poly Haven | `ashlands_prop1_*` |
| Prop 2 | `bitumen` | Poly Haven | `ashlands_prop2_*` |
| Prop 3 | `rock_boulder_dry` | Poly Haven | `ashlands_prop3_*` |

- **Color Grading:** Charcoal (#2B2B2B), ember red (#8B2323)

#### 6. Highlands (Rolling Hills) ✅

| Role | Asset Name | Source | Local File Prefix |
|------|------------|--------|-------------------|
| Primary | `grass_meadow` | *(Uses Golden Plains)* | `highlands_primary_*` |
| Secondary | `coast_sand_rocks_02` | *(Uses Enchanted Forest)* | `highlands_secondary_*` |
| Prop 1 | `aerial_grass_rock` | Poly Haven | `highlands_prop1_*` |
| Prop 2 | `aerial_rocks_01` | Poly Haven | `highlands_prop2_*` |
| Prop 3 | `brown_mud_rocks_01` | Poly Haven | `highlands_prop3_*` |

- **Color Grading:** Sage green (#7A9D7E), brown (#654321)
- ℹ️ **Note:** Highlands shares some textures with other biomes (Golden Plains primary, Enchanted Forest prop3).

#### 7. Swamplands ✅

| Role | Asset Name | Source | Local File Prefix |
|------|------------|--------|-------------------|
| Primary | `brown_mud_02` | Poly Haven | `swamplands_primary_*` |
| Secondary | `brown_mud_03` | Poly Haven | `swamplands_secondary_*` |
| Prop 1 | `concrete_moss` | Poly Haven | `swamplands_prop1_*` |
| Prop 2 | `aerial_mud_1` | Poly Haven | `swamplands_prop2_*` |
| Prop 3 | `cobblestone_floor_04` | Poly Haven | `swamplands_prop3_*` |

- **Color Grading:** Murky green (#4A5D23), brown mud (#5C4033)

### Godot Import Settings (All Textures)

```
Import As: Texture
Compression Mode: VRAM Compressed (for Low/Med settings)
                  VRAM Uncompressed (for High/Ultra settings)
Mipmaps: Enabled
Filter: Linear
Anisotropic: 16x (High/Ultra), 4x (Med), 2x (Low)
sRGB: Enabled for Albedo, Disabled for Normal/Roughness/AO
```

### Material Setup (StandardMaterial3D)

```gdscript
# Example: Enchanted Forest material (using actual downloaded file names)
var forest_material = StandardMaterial3D.new()
forest_material.albedo_texture = load("res://assets/textures/biomes/enchanted_forest_primary_diffuse.png")
forest_material.normal_texture = load("res://assets/textures/biomes/enchanted_forest_primary_normal.png")
forest_material.roughness_texture = load("res://assets/textures/biomes/enchanted_forest_primary_roughness.png")
forest_material.ao_texture = load("res://assets/textures/biomes/enchanted_forest_primary_ao.png")
forest_material.metallic = 0.0
forest_material.roughness = 0.8
```

---

### **Board Frame & Table** ✅

> ✅ **DOWNLOAD STATUS:** All board textures downloaded (Dec 2024)
> Local path: `res://assets/textures/board/`

**Wooden Table Surface:**

| Role | Asset Name | Source | Local File Prefix |
|------|------------|--------|-------------------|
| Primary | `dark_wood` | Poly Haven | `table_wood_*` |
| Alt 1 | `brown_planks_03` | Poly Haven | `table_wood_alt1_*` |
| Alt 2 | `dark_wooden_planks` | Poly Haven | `table_wood_alt2_*` |

- **Material:** Dark oak/mahogany appearance
- Dimensions: Large enough to fit 397 hex board + card zones
- Model: Create in Blender (no suitable Poly Haven 3D table model available)

**Board Frame (Stone/Iron):**

| Role | Asset Name | Source | Local File Prefix |
|------|------------|--------|-------------------|
| Stone | `castle_brick_01` | Poly Haven | `frame_stone_*` |
| Alt Stone 1 | `castle_wall_slates` | Poly Haven | `frame_stone_alt1_*` |
| Alt Stone 2 | `defense_wall` | Poly Haven | `frame_stone_alt2_*` |
| Metal | `corrugated_iron` | Poly Haven | `frame_metal_*` |
| Alt Metal | `blue_metal_plate` | Poly Haven | `frame_metal_alt_*` |

- Frame around hex grid perimeter
- Medieval fortress aesthetic

**Godot Setup:**
```
Table Model: res://assets/models/game_table.glb
Board Frame: res://assets/models/board_frame.glb
Import Settings: Same as hex_base.glb
```

---

## 2️⃣ **Character Models (12 Troops + 3 NPCs)**

### **AI Model Generation Strategy**

**Platforms to Use:**
1. **Tripo3D** (fastest, good for prototyping)
2. **Meshy.ai** (best quality, PBR textures included)
3. **Luma Labs AI** (best for complex creatures like dragons)

**Polygon Budget:**
- **Low Quality:** 5,000-8,000 tris per model
- **Medium Quality:** 10,000-15,000 tris per model
- **High Quality:** 20,000-30,000 tris per model
- **Ultra Quality:** 40,000-60,000 tris per model

**Export Format:** `.glb` or `.fbx` with embedded PBR textures

---

### **Troop Model Generation Prompts**

#### **Ground Tank Role**

**1. Medieval Knight**
```
Prompt: "Medieval knight in full plate armor, realistic steel armor with battle damage, 
holding longsword and shield, heroic standing pose, grounded high fantasy style, 
photorealistic materials, weathered metal texture, Manor Lords aesthetic, 
4K PBR textures, game-ready low-poly model"

Platform: Meshy.ai
Polygon Target: 15,000 tris (Medium)
Reference Style: Kingdom Come Deliverance knight
```

**2. Stone Giant**
```
Prompt: "Massive stone golem giant, rocky textured body made of granite and boulders, 
cracks with glowing orange magma seams, hulking muscular form, standing idle pose, 
realistic rock materials, grounded fantasy style, 4K PBR textures, game-ready model"

Platform: Luma Labs AI
Polygon Target: 25,000 tris (High)
Reference Style: God of War stone creatures
```

**3. Four-Headed Hydra**
```
Prompt: "Four-headed hydra monster, serpentine reptilian body with scales, 
four dragon-like heads on long necks, swamp creature aesthetic, realistic scales and skin, 
muddy green-brown coloration, standing menacing pose, grounded high fantasy, 
4K PBR textures, game-ready model"

Platform: Luma Labs AI
Polygon Target: 30,000 tris (High - complex geometry)
Reference Style: The Witcher 3 monsters
```

---

#### **Air/Hybrid Role**

**4. Dark Blood Dragon**
```
Prompt: "Fearsome dark dragon with massive wings, black and crimson scales, 
muscular quadrupedal body, horns and spikes, realistic reptilian texture, 
standing ground pose with wings folded, grounded high fantasy, 
4K PBR textures, game-ready model"

Platform: Luma Labs AI
Polygon Target: 35,000 tris (High - wings complex)
Reference Style: Skyrim dragon realism
```

**5. Sky Serpent**
```
Prompt: "Sleek flying serpent dragon, elongated body without legs, feathered wings, 
light blue-white scales, elegant and agile appearance, coiled flying pose, 
realistic feather and scale textures, grounded high fantasy, 4K PBR textures, game-ready model"

Platform: Meshy.ai
Polygon Target: 20,000 tris (Medium-High)
Reference Style: Chinese dragon mixed with bird of prey
```

**6. Frost Valkyrie**
```
Prompt: "Female warrior valkyrie with large feathered wings, Nordic armor with fur trim, 
ice-blue color scheme, wielding spear and shield, heroic standing pose, 
realistic armor and feather materials, grounded high fantasy, 4K PBR textures, game-ready model"

Platform: Meshy.ai
Polygon Target: 18,000 tris (Medium)
Reference Style: God of War Valkyrie armor
```

---

#### **Ranged/Magic Role**

**7. Dark Magic Wizard**
```
Prompt: "Mysterious dark wizard in tattered robes, gnarled wooden staff with glowing crystal, 
hooded face partially obscured, cloth and leather materials, standing casting pose, 
realistic fabric textures with magical glow accents, grounded high fantasy, 
4K PBR textures, game-ready model"

Platform: Meshy.ai
Polygon Target: 12,000 tris (Medium)
Reference Style: The Witcher 3 mages
```

**8. Demon of Darkness**
```
Prompt: "Hulking demon warrior with charred black skin, glowing red eyes and markings, 
large horns, muscular build, wielding dark magic flames, standing menacing pose, 
realistic skin and horn textures with emissive glow, grounded high fantasy, 
4K PBR textures, game-ready model"

Platform: Luma Labs AI
Polygon Target: 22,000 tris (Medium-High)
Reference Style: Diablo demon realism
```

**9. Elven Archer**
```
Prompt: "Slender elven archer in leather armor, longbow with arrows, elegant pointed ears, 
forest green and brown color scheme, dynamic aiming pose, realistic leather and cloth textures, 
grounded high fantasy, 4K PBR textures, game-ready model"

Platform: Meshy.ai
Polygon Target: 10,000 tris (Low-Medium)
Reference Style: Lord of the Rings Legolas realism
```

---

#### **Flex Role (Support/Assassin)**

**10. Celestial Cleric**
```
Prompt: "Holy cleric in white and gold robes, ornate staff with glowing crystal, 
divine light aura, serene standing pose with hands raised, realistic fabric and metal textures, 
soft golden glow effects, grounded high fantasy, 4K PBR textures, game-ready model"

Platform: Meshy.ai
Polygon Target: 14,000 tris (Medium)
Reference Style: Diablo 3 crusader/monk hybrid
```

**11. Shadow Assassin**
```
Prompt: "Stealthy assassin in dark leather armor, twin daggers, hooded cloak, 
lean athletic build, crouched stealth pose, realistic leather and cloth materials, 
dark gray-black color scheme, grounded high fantasy, 4K PBR textures, game-ready model"

Platform: Tripo3D
Polygon Target: 9,000 tris (Low-Medium)
Reference Style: Assassin's Creed medieval
```

**12. Infernal Soul**
```
Prompt: "Small imp-like demon creature, charred red-black skin, clawed hands, 
mischievous grin, crouched aggressive pose, realistic skin texture with ember glow, 
grounded high fantasy, 4K PBR textures, game-ready model"

Platform: Tripo3D
Polygon Target: 8,000 tris (Low)
Reference Style: Dark Souls minor demons
```

---

### **NPC Model Generation Prompts**

**1. Goblin (Common NPC)**
```
Prompt: "Small goblin creature, green wrinkled skin, ragged loincloth, crude club weapon, 
hunched aggressive pose, realistic skin and cloth textures, grounded high fantasy, 
4K PBR textures, game-ready model"

Platform: Tripo3D
Polygon Target: 6,000 tris (Low)
Reference Style: The Witcher 3 nekkers
```

**2. Orc (Medium NPC)**
```
Prompt: "Muscular orc warrior, gray-green skin, heavy rusted armor, battle axe, 
standing intimidating pose, realistic skin and metal textures, grounded high fantasy, 
4K PBR textures, game-ready model"

Platform: Meshy.ai
Polygon Target: 12,000 tris (Medium)
Reference Style: Shadow of Mordor orcs
```

**3. Troll (Rare NPC)**
```
Prompt: "Massive troll monster, gray stone-like skin, moss growing on back, 
tree trunk club, hulking menacing pose, realistic rock and organic textures, 
grounded high fantasy, 4K PBR textures, game-ready model"

Platform: Luma Labs AI
Polygon Target: 20,000 tris (Medium-High)
Reference Style: The Witcher 3 trolls
```

---

### **Model Import & Setup (Godot)**

**Import Settings for ALL Character Models:**
```
Animation → Import: Enabled
Meshes → Ensure Tangents: Enabled
Meshes → Generate LODs: Enabled (3 levels)
  - LOD0: 100% (original quality)
  - LOD1: 60% (Medium setting)
  - LOD2: 30% (Low setting)
Meshes → Create Shadow Meshes: Enabled
Meshes → Light Baking: Static Lightmaps (for environment lighting)
Materials → Location: Embedded (keep with model)
Compression: Mesh Compression Enabled
Physics: Disabled (use collision shapes separately)
```

**Post-Import Checklist:**
- Check model scale (should be ~1 unit = 1 meter in Godot)
- Verify materials have all PBR textures assigned
- Test LOD transitions (camera distance-based)
- Add collision shapes for gameplay (CapsuleShape3D for troops)

### Team Color Shader System

**Custom Shader for Recoloring (team_color_shader.gdshader):**

```glsl
shader_type spatial;
render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_texture : source_color;
uniform sampler2D normal_texture : hint_normal;
uniform sampler2D roughness_texture : hint_default_white;
uniform sampler2D metallic_texture : hint_default_black;
uniform sampler2D ao_texture : hint_default_white;

// Team color parameters
uniform vec3 team_primary_color : source_color = vec3(0.24, 0.31, 0.39); // Default Player 1 Blue
uniform vec3 team_accent_color : source_color = vec3(0.66, 0.71, 0.75); // Default Player 1 Silver
uniform float team_color_intensity : hint_range(0.0, 1.0) = 0.7;

// Mask texture (R = primary areas, G = accent areas, B = glow areas)
uniform sampler2D team_mask_texture : hint_default_black;

void fragment() {
    // Sample base textures
    vec4 albedo = texture(albedo_texture, UV);
    vec3 normal_map = texture(normal_texture, UV).rgb;
    float roughness = texture(roughness_texture, UV).r;
    float metallic = texture(metallic_texture, UV).r;
    float ao = texture(ao_texture, UV).r;
    
    // Sample team mask
    vec3 mask = texture(team_mask_texture, UV).rgb;
    
    // Apply team colors
    vec3 primary_tint = mix(albedo.rgb, team_primary_color, mask.r * team_color_intensity);
    vec3 accent_tint = mix(primary_tint, team_accent_color, mask.g * team_color_intensity);
    
    // Output
    ALBEDO = accent_tint * ao;
    NORMAL_MAP = normal_map;
    ROUGHNESS = roughness;
    METALLIC = metallic;
}
```

**Usage in GDScript:**

```gdscript
# Apply team colors to a troop model
func apply_team_color(troop_mesh: MeshInstance3D, team_id: int):
    var material = troop_mesh.get_surface_override_material(0).duplicate()
    
    if team_id == 1:  # Player 1 (Blue/Steel)
        material.set_shader_parameter("team_primary_color", Vector3(0.24, 0.31, 0.39))  # Faded Navy
        material.set_shader_parameter("team_accent_color", Vector3(0.66, 0.71, 0.75))   # Weathered Steel
    elif team_id == 2:  # Player 2 (Red/Bronze)
        material.set_shader_parameter("team_primary_color", Vector3(0.42, 0.17, 0.17))  # Deep Burgundy
        material.set_shader_parameter("team_accent_color", Vector3(0.61, 0.46, 0.33))   # Tarnished Bronze
    
    troop_mesh.set_surface_override_material(0, material)
```

**Team Mask Creation:**
- Create mask texture in Photoshop/GIMP for each model
- **Red channel:** Areas to apply primary team color (armor plates, cloth)
- **Green channel:** Areas to apply accent color (metal trim, details)
- **Blue channel:** Reserved for magical glow (later phase)
- Save as `troop_name_team_mask.png` (RGB, 1024x1024)

---

## 3️⃣ **NOW Animations (Attack, Damage, Death)**

### **Animation Requirements**

**Per Troop Model (3 animations total for NOW):**

1. **Attack Animation (1.5-2 seconds)**
   - Melee: Forward lunge/swing
   - Ranged: Draw bow/aim/release
   - Magic: Staff raise/casting gesture
   - Air: Wing flap + dive/swoop

2. **Damage Animation (0.5-1 second)**
   - Recoil/stagger backwards
   - Brief pain reaction
   - Return to idle

3. **Death Animation (2-3 seconds)**
   - Collapse/fall
   - Fade out (shader-based opacity reduction)
   - Optional: Particle effect on death

**Animation Creation Methods:**

**Option A: Mixamo (Free, Fast)**
- Upload generated model to https://www.mixamo.com
- Search animations: "Sword Attack", "Being Hit", "Death"
- Download with "In Place" option
- Import to Godot as `.fbx`

**Option B: Manual Blender Animation**
- Rig model in Blender (Auto-Rig Pro or manual)
- Animate key poses
- Export as `.glb` with animation embedded

**Option C: AI Animation (Cascadeur)**
- Use https://cascadeur.com for physics-based animation
- Upload model, create attack/damage/death poses
- Export as `.fbx`

**Recommended: Mix of Mixamo (fast) + manual tweaks in Blender**

---

### **Animation Import Settings (Godot)**
```
Import As: Scene
Animation → Storage: Embedded
Animation → Keep Custom Tracks: On
Animation → FPS: 30 (Low/Med), 60 (High/Ultra)
Animation → Trimming: Disabled
Animation → Import Tracks → Position: Enabled
Animation → Import Tracks → Rotation: Enabled
Animation → Import Tracks → Scale: Enabled
Optimizer → Enabled: Yes
  - Optimize Linear Error: 0.05
  - Optimize Angular Error: 0.01
```

**Animation Player Setup:**

```gdscript
# Example: Playing attack animation with combat system
func perform_attack():
    var anim_player = $TroopModel/AnimationPlayer
    anim_player.play("attack")
    await anim_player.animation_finished
    # Continue with combat resolution
```

---

## 4️⃣ **Card System (2D Art + 3D Planes)**

### **Card Art Generation (AI Image Generation)**

**Platform:** Midjourney (best quality) or Stable Diffusion (free alternative)

**Standard Card Art Prompt Template:**
```
"[Character Name] in epic fantasy environment, environmental scene with character prominently featured, 
dramatic medieval battle scene, realistic digital painting style, Manor Lords aesthetic, 
muted earthy colors with vibrant magical accents, cinematic composition, 
atmospheric lighting, highly detailed, trending on ArtStation, 
aspect ratio 2:3 portrait orientation, 4K resolution"
```

---

### **Individual Card Art Prompts**

**1. Medieval Knight Card**
```
"Medieval knight in full plate armor standing on golden plains battlefield, 
wheat fields and rolling hills in background, longsword planted in ground, 
realistic steel armor with weathered texture, sunset lighting, 
Manor Lords aesthetic, muted colors with warm glow, epic fantasy portrait, 
2:3 aspect ratio, 4K resolution"
```

**2. Stone Giant Card**
```
"Massive stone golem giant towering over rocky highlands, 
boulders and cliff faces in background, cracks with orange magma glow, 
realistic granite texture, moody overcast lighting, 
Manor Lords aesthetic, earth tones with ember accents, epic fantasy portrait, 
2:3 aspect ratio, 4K resolution"
```

**3. Four-Headed Hydra Card**
```
"Four-headed hydra monster emerging from misty swamplands, 
murky water and dead trees in background, serpentine scaled body, 
realistic reptilian texture, foggy atmospheric lighting, 
Manor Lords aesthetic, green-brown swamp colors, epic fantasy portrait, 
2:3 aspect ratio, 4K resolution"
```

**4. Dark Blood Dragon Card**
```
"Dark crimson dragon with massive wings perched on volcanic ashlands, 
lava flows and charred ground in background, black and red scales, 
realistic dragon texture, fiery atmospheric lighting, 
Manor Lords aesthetic, dark colors with red-orange glow, epic fantasy portrait, 
2:3 aspect ratio, 4K resolution"
```

**5. Sky Serpent Card**
```
"Elegant flying serpent dragon soaring above frozen mountain peaks, 
snow-capped mountains and clouds in background, blue-white feathered wings, 
realistic scale and feather texture, bright cold lighting, 
Manor Lords aesthetic, ice-blue colors, epic fantasy portrait, 
2:3 aspect ratio, 4K resolution"
```

**6. Frost Valkyrie Card**
```
"Warrior valkyrie with white wings standing on icy peaks, 
frozen landscape and aurora in background, Nordic armor with fur, 
realistic metal and feather texture, ethereal blue lighting, 
Manor Lords aesthetic, ice-blue and silver tones, epic fantasy portrait, 
2:3 aspect ratio, 4K resolution"
```

**7. Dark Magic Wizard Card**
```
"Mysterious wizard casting dark magic in enchanted forest, 
ancient trees and magical fog in background, tattered robes and glowing staff, 
realistic cloth texture with purple magical glow, mysterious shadowy lighting, 
Manor Lords aesthetic, dark greens with violet accents, epic fantasy portrait, 
2:3 aspect ratio, 4K resolution"
```

**8. Demon of Darkness Card**
```
"Hulking demon warrior wreathed in dark flames in ashlands, 
volcanic wasteland and fire in background, charred black skin with glowing markings, 
realistic demonic texture with emissive glow, intense fire lighting, 
Manor Lords aesthetic, black and crimson colors, epic fantasy portrait, 
2:3 aspect ratio, 4K resolution"
```

**9. Elven Archer Card**
```
"Elven archer drawing longbow in enchanted forest clearing, 
sunbeams through trees in background, leather armor and elegant features, 
realistic leather texture, soft natural lighting, 
Manor Lords aesthetic, forest greens and browns, epic fantasy portrait, 
2:3 aspect ratio, 4K resolution"
```

**10. Celestial Cleric Card**
```
"Holy cleric channeling divine light on golden plains, 
heavenly rays and blessed landscape in background, white robes and golden staff, 
realistic cloth texture with soft golden glow, divine ethereal lighting, 
Manor Lords aesthetic, white and gold tones, epic fantasy portrait, 
2:3 aspect ratio, 4K resolution"
```

**11. Shadow Assassin Card**
```
"Stealthy assassin lurking in dark forest shadows, 
moonlit trees and mist in background, dark leather armor and twin daggers, 
realistic leather texture, dramatic low-key lighting, 
Manor Lords aesthetic, dark grays and blacks, epic fantasy portrait, 
2:3 aspect ratio, 4K resolution"
```

**12. Infernal Soul Card**
```
"Small imp demon emerging from volcanic ashlands, 
lava and charred rocks in background, red-black skin with ember glow, 
realistic demonic texture, fiery dramatic lighting, 
Manor Lords aesthetic, red-orange fire colors, epic fantasy portrait, 
2:3 aspect ratio, 4K resolution"
```

---

### **NPC Card Art Prompts**

**Goblin Card**
```
"Goblin warrior in desolate wasteland ruins, 
crumbling structures in background, green wrinkled skin with crude armor, 
realistic creature texture, harsh sunlight, 
Manor Lords aesthetic, muted greens and browns, epic fantasy portrait, 
2:3 aspect ratio, 4K resolution"
```

**Orc Card**
```
"Orc berserker charging through highlands battlefield, 
rocky hills in background, gray-green skin with battle scars, 
realistic creature texture, stormy lighting, 
Manor Lords aesthetic, gray-green tones, epic fantasy portrait, 
2:3 aspect ratio, 4K resolution"
```

**Troll Card**
```
"Massive troll monster in dark swamp, 
murky water and twisted trees in background, mossy stone-like skin, 
realistic rock texture, foggy moody lighting, 
Manor Lords aesthetic, gray-green moss tones, epic fantasy portrait, 
2:3 aspect ratio, 4K resolution"
```

---

### **Card Frame Design**

**Option A: Ornate Medieval Frame**
- Create in Photoshop/Illustrator
- Stone/iron border with weathered texture
- Stat boxes integrated into bottom frame
- Team-colored accent border (blue or red trim)

**Option B: Poly Haven Composite Frame**
- Use stone texture: https://polyhaven.com/a/castle_brick_01
- Use metal trim: https://polyhaven.com/a/corrugated_iron
- Composite in image editor
- Add text overlays for stats

**Frame Specifications:**
- Resolution: 1024x1536 (2:3 ratio)
- Border width: 80-100 pixels
- Stat box area: Bottom 200 pixels
- Center art area: 864x1136 pixels

**Card Stats Layout (Bottom Section):**
```
┌─────────────────────────┐
│   [Name of Troop]       │
├──────┬─────┬─────┬──────┤
│ HP   │ ATK │ DEF │ MANA │
│ 150  │ 100 │ 80  │  8   │
├──────┴─────┴─────┴──────┤
│ Range: 3 (Air)          │
│ Speed: 5                │
└─────────────────────────┘
```

**Font Recommendation:**
- **Title:** Cinzel Bold (medieval serif)
- **Stats:** Roboto Condensed (readable numbers)
- **Download:** https://fonts.google.com/

### 3D Card Plane Setup

**Card Geometry:**
- Quad plane mesh (2 triangles)
- Dimensions: 0.6 x 0.9 units (2:3 ratio, scaled to game units)
- UV mapped to full card texture

**Card Material (StandardMaterial3D):**

```gdscript
var card_material = StandardMaterial3D.new()
card_material.albedo_texture = load("res://assets/textures/cards/knight_card.png")
card_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
card_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
card_material.disable_receive_shadows = false
card_material.cull_mode = BaseMaterial3D.CULL_BACK
```

**Card Hover/Select Effects:**

```gdscript
# Hover animation
func _on_card_hover():
    var tween = create_tween()
    tween.tween_property(self, "position:y", original_y + 0.05, 0.2)
    tween.parallel().tween_property(self, "rotation_degrees:x", -5, 0.2)
    
    # Glow effect (shader or emissive material)
    var material = $MeshInstance3D.get_surface_override_material(0)
    material.emission_enabled = true
    material.emission = Color(1.0, 1.0, 0.8, 1.0)
    material.emission_energy = 0.3
```

**Card 3D Positioning (Dynamic UI):**
- Cards appear when player opens hand (Button/Keybind)
- Position: Floating above table surface
- Layout: Fan arrangement or linear row
- Camera focus: Brief zoom to cards when opened

---

## 5️⃣ **Gold Mine Buildings**

### **Gold Mine Model**

**AI Generation Prompt:**
```
"Medieval mining structure building, small wooden shack with stone foundation, 
mining shaft entrance, ore cart and pickaxes nearby, weathered materials, 
realistic wood and stone textures, Manor Lords aesthetic, 
4K PBR textures, game-ready low-poly model"

Platform: Meshy.ai
Polygon Target: 3,000-5,000 tris (simple building)
Alternative: Poly Haven Assets

Base structure: Use AI generation (no suitable Poly Haven model)
Stone foundation: https://polyhaven.com/a/castle_wall_slates
Props: Use AI generation for mining cart/pickaxes

**Mine Level Visual Progression:**
- **Level 1:** Basic wooden shack, crude entrance
- **Level 2:** Reinforced structure, larger entrance
- **Level 3:** Stone reinforcement added
- **Level 4:** Metal accents, ore piles visible
- **Level 5:** Full stone structure, glowing ore veins

**Godot Import Settings:** Same as hex_base.glb
- Generate LODs: Enabled (2 levels)

---

## 6️⃣ **Physical Dice System**

### **Dice 3D Model**

**Option A: Poly Haven Asset**
- Search for "dice" or "die" on Poly Haven
- If not available, use AI generation

**Option B: AI Generation**

```
Prompt: "Medieval d20 dice, twenty-sided die, 
weathered bone material with carved numbers, 
realistic texture, Manor Lords aesthetic, 
4K PBR textures, game-ready model"

Platform: Tripo3D
Polygon Target: 2,000 tris (simple geometry)
```

**Option C: Blender Creation**
- Create icosahedron (20 faces)
- Bevel edges for realism
- UV unwrap and texture with numbers 1-20
- Export as `.glb`

**Dice Texture:**
- **Material:** Aged bone/ivory
- **Numbers:** Carved/painted in dark ink
- **Reference:** https://polyhaven.com/a/bone_texture (if available)

### **Dice Physics Setup (Godot)**

**RigidBody3D Configuration:**

```gdscript
extends RigidBody3D

@export var roll_force: float = 5.0
@export var roll_torque: float = 10.0

func roll_dice():
    # Random force and torque for realistic roll
    var random_force = Vector3(
        randf_range(-roll_force, roll_force),
        randf_range(5.0, 8.0),  # Upward force
        randf_range(-roll_force, roll_force)
    )
    var random_torque = Vector3(
        randf_range(-roll_torque, roll_torque),
        randf_range(-roll_torque, roll_torque),
        randf_range(-roll_torque, roll_torque)
    )
    
    apply_central_impulse(random_force)
    apply_torque_impulse(random_torque)
    
    # Wait for dice to settle
    await get_tree().create_timer(2.0).timeout
    var result = detect_top_face()
    return result

func detect_top_face() -> int:
    # Raycast downward from each face to determine which is up
    # Return face number (1-20)
    # Implementation depends on dice model structure
    pass
```

**Dice Rolling Arena:**
- Small section of wooden table
- Physics boundaries (invisible walls)
- Surface friction for realistic stopping

**Visual Polish:**
- Dice shadow (dynamic or baked)
- Subtle bounce/roll sounds (Phase 2)
- Camera focus on dice during roll

---

## 7️⃣ **UI System (Medieval Stone/Iron/Wood Theme)**

### **UI Background Textures**

**Main UI Panel:**
- **Stone Base:** https://polyhaven.com/a/castle_brick_01
- **Wood Trim:** https://polyhaven.com/a/brown_planks_03
- **Metal Accents:** https://polyhaven.com/a/corrugated_iron

**Button Textures:**
- **Normal State:** https://polyhaven.com/a/dark_wood (lighter wood)
- **Hover State:** Same texture with brightness +10%
- **Pressed State:** Same texture with brightness -10%
- **Disabled State:** Grayscale version with 50% opacity

**UI Element Specifications:**

**Action Buttons:**
```
Size: 128x64 pixels
Border: Iron frame (8px wide)
Background: Weathered wood texture
Text: White/cream (#F5E6D3)
Font: Cinzel (medieval serif)
Icon: Simple SVG icons (sword, shield, hammer, etc.)
```

**Resource Display (Gold/XP):**
```
Background: Dark stone panel
Icon: Gold coin (from Documentation folder, replace with Poly Haven gold texture)
Text: Large readable numbers
Border: Ornate metal trim
```

**Turn Timer:**
```
Position: Top-right corner
Background: Circular stone dial
Progress: Glowing ember effect (depletes clockwise)
Text: Countdown numbers in center
```

### **UI Material Setup (Godot)**

**Theme Resource (medieval_theme.tres):**

```gdscript
# Create custom Theme resource
var theme = Theme.new()

# Button styles
var button_normal = StyleBoxTexture.new()
button_normal.texture = load("res://assets/textures/ui/button_normal.png")
button_normal.margin_left = 8
button_normal.margin_right = 8
button_normal.margin_top = 8
button_normal.margin_bottom = 8

var button_hover = StyleBoxTexture.new()
button_hover.texture = load("res://assets/textures/ui/button_hover.png")
# ... same margins

var button_pressed = StyleBoxTexture.new()
button_pressed.texture = load("res://assets/textures/ui/button_pressed.png")
# ... same margins

var button_disabled = StyleBoxTexture.new()
button_disabled.texture = load("res://assets/textures/ui/button_disabled.png")
# ... same margins

theme.set_stylebox("normal", "Button", button_normal)
theme.set_stylebox("hover", "Button", button_hover)
theme.set_stylebox("pressed", "Button", button_pressed)
theme.set_stylebox("disabled", "Button", button_disabled)

# Save theme
ResourceSaver.save(theme, "res://assets/themes/medieval_theme.tres")
```

**Apply to UI:**

```gdscript
# In main UI scene
$CanvasLayer/GameUI.theme = load("res://assets/themes/medieval_theme.tres")
```

### **UI Icons (Simple SVG)**

**Create or download icons for:**
- Move action (footprint)
- Attack action (crossed swords)
- Place mine (pickaxe)
- Upgrade (hammer/anvil)
- Use item (potion bottle)
- End turn (hourglass)

**Icon Style:** Simple silhouettes, 64x64 pixels, white fill

---

## 8️⃣ **Lighting & Environment**

### **Global Lighting Setup**

**DirectionalLight3D (Sun):**

```gdscript
var sun = DirectionalLight3D.new()
sun.light_energy = 1.0  # Standard across all biomes
sun.light_color = Color(1.0, 0.95, 0.9)  # Warm natural light
sun.rotation_degrees = Vector3(-45, 30, 0)  # 45° angle from above
sun.shadow_enabled = true
sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
sun.directional_shadow_max_distance = 50.0
```

**WorldEnvironment (HDRI Background):**
- Poly Haven HDRI: https://polyhaven.com/a/evening_road_01
- Alternative: https://polyhaven.com/a/forest_slope
- Use neutral/atmospheric HDRI that doesn't overpower biomes

```gdscript
var environment = Environment.new()
var sky = Sky.new()
var sky_material = PanoramaSkyMaterial.new()
sky_material.panorama = load("res://assets/hdri/evening_road_01_4k.exr")
sky.sky_material = sky_material
environment.background_mode = Environment.BG_SKY
environment.sky = sky
environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
environment.ambient_light_energy = 0.5
environment.tonemap_mode = Environment.TONE_MAPPER_ACES  # Cinematic look
environment.ssao_enabled = true  # Ambient occlusion
environment.ssil_enabled = false  # Screen-space indirect lighting (expensive)
environment.glow_enabled = true  # For magical effects
environment.glow_intensity = 0.8
environment.glow_strength = 1.2
environment.glow_bloom = 0.1
```

> **Note:** Lighting is uniform across entire game. Biomes get atmosphere from textures and particle effects, not lighting changes.

---

## 9️⃣ **Particle Effects (NOW - Basic Combat)**

### **Particle Systems (Per Biome - Subtle Ambient)**

**Enchanted Forest:**
- Floating fireflies (small glowing particles)
- Falling leaves (occasional)

**Frozen Peaks:**
- Snow flurry (light snowflakes)
- Ice crystals (rare sparkles)

**Desolate Wastes:**

- Dust devils (small sand swirls)
- Heat shimmer (optional, expensive)

**Golden Plains:**
- Pollen/grass seeds (floating gently)

**Ashlands:**
- Ember particles (rising, glowing orange)
- Smoke wisps (dark gray)

**Highlands:**
- Wind-blown grass particles (subtle)

**Swamplands:**
- Fog tendrils (low-lying mist)
- Bubbles (occasional from murky water)

### **Combat Particle Effects**

**Melee Attack Hit:**
- Spark burst (small, brief)
- Impact dust (stone/dirt particles)

**Ranged Attack (Arrows):**
- Arrow trail (motion blur)
- Impact splinter (wood chips)

**Magic Attack:**
- Spell projectile (glowing orb trail)
- Impact explosion (colorful burst based on caster)
  - Dark Magic Wizard: Purple/black energy
  - Demon of Darkness: Red-orange flames
  - Celestial Cleric: Golden light

**Death Effects:**
- Fade-out (shader-based opacity reduction)
- Small dust/ash particle burst
- Optional: Soul wisp rising (ethereal particle)

### **Godot Particle Setup (GPUParticles3D)**

**Example: Ember Particles (Ashlands)**

```gdscript
var embers = GPUParticles3D.new()
embers.amount = 50
embers.lifetime = 5.0
embers.explosiveness = 0.0
embers.randomness = 0.5

var process_material = ParticleProcessMaterial.new()
process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
process_material.emission_box_extents = Vector3(2.0, 0.5, 2.0)  # Per hex
process_material.direction = Vector3(0, 1, 0)  # Upward
process_material.initial_velocity_min = 0.2
process_material.initial_velocity_max = 0.5
process_material.gravity = Vector3(0, 0.1, 0)  # Slight upward drift
process_material.scale_min = 0.02
process_material.scale_max = 0.05
process_material.color = Color(1.0, 0.4, 0.1, 0.8)  # Orange glow

embers.process_material = process_material
embers.draw_pass_1 = QuadMesh.new()  # Billboard quad for each particle
```

**Quality Settings for Particles:**
- **Low:** 25% particle count, no shadows
- **Medium:** 50% particle count, basic shadows
- **High:** 100% particle count, full shadows
- **Ultra:** 100% + additional detail particles

---

## 🔟 **Quality Settings System**

### **Graphics Settings Categories**

**1. Texture Quality**
- **Low:** 512x512 textures (downscaled)
- **Medium:** 1024x1024 textures
- **High:** 2048x2048 textures
- **Ultra:** 4096x4096 textures (original)

**Implementation:**

```gdscript
func set_texture_quality(level: int):
    var size_limit = [512, 1024, 2048, 4096][level]
    ProjectSettings.set_setting("rendering/textures/canvas_textures/default_texture_filter", level)
    # Force reload textures with new size limit
```

**2. Model Detail (LOD)**
- **Low:** LOD2 (30% polygons)
- **Medium:** LOD1 (60% polygons)
- **High:** LOD0 (100% polygons)
- **Ultra:** LOD0 + high-res textures

**Implementation:**

```gdscript
func set_model_quality(level: int):
    for troop in get_tree().get_nodes_in_group("troops"):
        var lod_level = [2, 1, 0, 0][level]
        troop.mesh_instance.set_lod_bias(lod_level)
```

**3. Shadow Quality**
- **Low:** No shadows
- **Medium:** Hard shadows, low resolution (512x512)
- **High:** Soft shadows, medium resolution (2048x2048)
- **Ultra:** Soft shadows, high resolution (4096x4096), PCF filtering

**Implementation:**

```gdscript
func set_shadow_quality(level: int):
    var sun = $DirectionalLight3D
    sun.shadow_enabled = (level > 0)
    sun.directional_shadow_split_1 = [0.1, 0.2, 0.3, 0.5][level]
    sun.directional_shadow_max_distance = [0, 25, 50, 100][level]
    
    var resolution = [0, 512, 2048, 4096][level]
    RenderingServer.directional_shadow_atlas_set_size(resolution)
```

**4. Particle Effects**

- **Low:** 25% particles, no glow
- **Medium:** 50% particles, basic glow
- **High:** 100% particles, full glow
- **Ultra:** 100% + extra detail particles

**5. Terrain Height Variation (Toggle)**
- **Off:** All hexes flat
- **On:** Biome-specific height variation

**6. Spell Effect Intensity (Slider: 0-100%)**
- Controls opacity/scale of magical glows and effects
- Affects: Wizard spells, demon fire, cleric auras, magical weapons

**7. Anti-Aliasing**
- **Off:** No AA
- **FXAA:** Fast, slight blur
- **TAA:** Temporal AA, smoother but ghosting
- **MSAA 2x/4x/8x:** High quality, expensive

**8. Ambient Occlusion (Toggle)**
- **Off:** No AO
- **On:** SSAO enabled

**9. Bloom/Glow (Toggle + Intensity Slider)**
- **Off:** No bloom
- **On:** Bloom for magical effects

**10. VSync (Toggle)**
- **Off:** Unlocked framerate
- **On:** Locked to monitor refresh rate

### **Hardware-Adaptive Presets**

**Auto-Detect System:**

```gdscript
func detect_hardware_preset() -> int:
    var gpu_name = RenderingServer.get_video_adapter_name()
    var vram = OS.get_video_adapter_driver_info()["VRAM"]  # In MB
    
    # Heuristic based on VRAM and GPU name
    if vram < 2000:  # Less than 2GB VRAM
        return 0  # Low preset
    elif vram < 4000:  # 2-4GB VRAM
        return 1  # Medium preset
    elif vram < 8000:  # 4-8GB VRAM
        return 2  # High preset
    else:  # 8GB+ VRAM
        return 3  # Ultra preset
```

**Preset Configurations:**

**Low Preset (Work Laptops, Integrated Graphics):**
- Texture Quality: Low (512x512)
- Model Detail: Low (LOD2)
- Shadow Quality: Off
- Particle Effects: Low (25%)
- Terrain Height: Off
- Spell Effects: 50%
- Anti-Aliasing: Off
- Ambient Occlusion: Off
- Bloom: Off
- VSync: On
- **Target:** 30 FPS minimum

**Medium Preset (Mid-Range Laptops, GTX 1050-1650):**
- Texture Quality: Medium (1024x1024)
- Model Detail: Medium (LOD1)
- Shadow Quality: Medium (512x512)
- Particle Effects: Medium (50%)
- Terrain Height: Optional
- Spell Effects: 75%
- Anti-Aliasing: FXAA
- Ambient Occlusion: Off
- Bloom: On (low intensity)
- VSync: On
- **Target:** 60 FPS

**High Preset (Gaming Laptops, RTX 2060-3060):**
- Texture Quality: High (2048x2048)
- Model Detail: High (LOD0)
- Shadow Quality: High (2048x2048, soft)
- Particle Effects: High (100%)
- Terrain Height: On
- Spell Effects: 100%
- Anti-Aliasing: TAA
- Ambient Occlusion: On
- Bloom: On (full intensity)
- VSync: On
- **Target:** 60 FPS stable

**Ultra Preset (Gaming Desktops, RTX 3070+):**
- Texture Quality: Ultra (4096x4096)
- Model Detail: Ultra (LOD0 + best textures)
- Shadow Quality: Ultra (4096x4096, PCF)
- Particle Effects: Ultra (100% + extras)
- Terrain Height: On
- Spell Effects: 100%
- Anti-Aliasing: MSAA 4x
- Ambient Occlusion: On
- Bloom: On (full intensity)
- VSync: Optional (unlocked FPS)
- **Target:** 120+ FPS

---

### **Settings UI Implementation**

**Settings Menu Structure:**
```
Settings
├─ Graphics
│  ├─ Preset: [Auto / Low / Medium / High / Ultra]
│  ├─ Texture Quality: [Low / Medium / High / Ultra]
│  ├─ Model Detail: [Low / Medium / High / Ultra]
│  ├─ Shadow Quality: [Off / Low / Medium / High / Ultra]
│  ├─ Particle Effects: [Low / Medium / High / Ultra]
│  ├─ Terrain Height Variation: [Off / On]
│  ├─ Spell Effect Intensity: [Slider 0-100%]
│  ├─ Anti-Aliasing: [Off / FXAA / TAA / MSAA 2x / 4x / 8x]
│  ├─ Ambient Occlusion: [Off / On]
│  ├─ Bloom/Glow: [Off / On]
│  ├─ Bloom Intensity: [Slider 0-100%]
│  ├─ VSync: [Off / On]
│  └─ Resolution: [1920x1080 / 2560x1440 / 3840x2160 / etc.]
├─ Audio (Phase 2)
├─ Controls
└─ Gameplay
```

**Save Settings:**

```gdscript
func save_settings():
    var config = ConfigFile.new()
    config.set_value("graphics", "preset", current_preset)
    config.set_value("graphics", "texture_quality", texture_quality)
    config.set_value("graphics", "model_detail", model_detail)
    # ... all settings
    config.save("user://settings.cfg")

func load_settings():
    var config = ConfigFile.new()
    var err = config.load("user://settings.cfg")
    if err == OK:
        current_preset = config.get_value("graphics", "preset", 1)  # Default Medium
        texture_quality = config.get_value("graphics", "texture_quality", 1)
        # ... apply all settings
        apply_graphics_settings()
```

---

## 📊 **Asset Folder Structure (Final)**
```
assets/
├── models/
│   ├── board/
│   │   ├── hex_base.glb
│   │   ├── hex_flat.glb
│   │   ├── hex_low.glb
│   │   ├── hex_high.glb
│   │   ├── game_table.glb
│   │   └── board_frame.glb
│   ├── troops/
│   │   ├── knight.glb (+ team_mask.png)
│   │   ├── stone_giant.glb (+ team_mask.png)
│   │   ├── hydra.glb (+ team_mask.png)
│   │   ├── dark_dragon.glb (+ team_mask.png)
│   │   ├── sky_serpent.glb (+ team_mask.png)
│   │   ├── frost_valkyrie.glb (+ team_mask.png)
│   │   ├── dark_wizard.glb (+ team_mask.png)
│   │   ├── demon.glb (+ team_mask.png)
│   │   ├── elven_archer.glb (+ team_mask.png)
│   │   ├── celestial_cleric.glb (+ team_mask.png)
│   │   ├── shadow_assassin.glb (+ team_mask.png)
│   │   └── infernal_soul.glb (+ team_mask.png)
│   ├── npcs/
│   │   ├── goblin.glb
│   │   ├── orc.glb
│   │   └── troll.glb
│   ├── structures/
│   │   ├── gold_mine_lv1.glb
│   │   ├── gold_mine_lv2.glb
│   │   ├── gold_mine_lv3.glb
│   │   ├── gold_mine_lv4.glb
│   │   └── gold_mine_lv5.glb
│   └── props/
│       └── dice_d20.glb
├── textures/                    # ✅ DOWNLOADED (Dec 2024) - ~8.6 GB total
│   ├── biomes/                  # ✅ 150+ files, ~6.1 GB
│   │   ├── # Enchanted Forest (5 texture sets)
│   │   ├── enchanted_forest_primary_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── enchanted_forest_secondary_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── enchanted_forest_prop1_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── enchanted_forest_prop2_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── enchanted_forest_prop3_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── # Frozen Peaks (4 texture sets)
│   │   ├── frozen_peaks_primary_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── frozen_peaks_secondary_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── frozen_peaks_prop1_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── frozen_peaks_prop3_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── # Desolate Wastes (5 texture sets)
│   │   ├── desolate_wastes_primary_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── desolate_wastes_secondary_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── desolate_wastes_prop1_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── desolate_wastes_prop2_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── desolate_wastes_prop3_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── # Golden Plains (5 texture sets - Poly Haven + AmbientCG)
│   │   ├── golden_plains_primary_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── golden_plains_secondary_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── golden_plains_alt_primary_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── golden_plains_prop1_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── golden_plains_prop2_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── # Ashlands (5 texture sets)
│   │   ├── ashlands_primary_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── ashlands_secondary_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── ashlands_prop1_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── ashlands_prop2_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── ashlands_prop3_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── # Highlands (5 texture sets)
│   │   ├── highlands_prop1_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── highlands_prop2_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── highlands_prop3_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── # Swamplands (5 texture sets)
│   │   ├── swamplands_primary_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── swamplands_secondary_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── swamplands_prop1_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── swamplands_prop2_[diffuse/normal/roughness/ao/displacement].png
│   │   └── swamplands_prop3_[diffuse/normal/roughness/ao/displacement].png
│   ├── board/                   # ✅ 40 files, ~1.7 GB
│   │   ├── table_wood_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── table_wood_alt1_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── table_wood_alt2_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── frame_stone_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── frame_stone_alt1_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── frame_stone_alt2_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── frame_metal_[diffuse/normal/roughness/ao/displacement].png
│   │   └── frame_metal_alt_[diffuse/normal/roughness/ao/displacement].png
│   ├── ui/                      # ✅ 15 files, ~760 MB
│   │   ├── ui_wood_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── ui_stone_[diffuse/normal/roughness/ao/displacement].png
│   │   ├── ui_metal_[diffuse/normal/roughness/ao/displacement].png
│   │   └── icons/
│   │       ├── move_icon.svg
│   │       ├── attack_icon.svg
│   │       ├── mine_icon.svg
│   │       ├── upgrade_icon.svg
│   │       ├── item_icon.svg
│   │       └── end_turn_icon.svg
│   └── cards/                   # ⏳ PENDING (AI-generated)
│       ├── knight_card.png
│       ├── stone_giant_card.png
│       ├── hydra_card.png
│       ├── dark_dragon_card.png
│       ├── sky_serpent_card.png
│       ├── frost_valkyrie_card.png
│       ├── dark_wizard_card.png
│       ├── demon_card.png
│       ├── elven_archer_card.png
│       ├── celestial_cleric_card.png
│       ├── shadow_assassin_card.png
│       ├── infernal_soul_card.png
│       ├── goblin_card.png
│       ├── orc_card.png
│       └── troll_card.png
├── hdri/
│   └── evening_road_01_4k.exr
├── shaders/
│   └── team_color_shader.gdshader
└── themes/
    └── medieval_theme.tres
```

---

# 🚀 PHASE 2: LATER (Polish & Advanced Features)

## 1️⃣ **Advanced Animations**

### **Movement Animations**

**Per Troop (1-2 seconds loop):**
- Walking/running cycle
- Flying cycle (for air units)
- Slithering (for Hydra/Sky Serpent)

**Animation Sources:**
- Mixamo (rigged walk/run cycles)
- Manual Blender animation
- AI animation (Cascadeur)

**Import Settings:** Same as Phase 1 animations

### **Idle Animations**

**Per Troop (2-4 seconds loop):**
- Breathing/shifting weight
- Weapon idle (sword rest, bow relax, staff glow pulse)
- Environmental reaction (looking around, adjusting stance)

**Idle Variation:**
- 2-3 idle animations per troop for variety
- Random selection on loop

### **Special Ability Animations**

**Hydra Multi-Strike:**
- All 4 heads strike simultaneously (1.5 seconds)

**Celestial Cleric Heal:**
- Staff raised, healing aura emanates (1.5 seconds)

**Infernal Soul Death Burst:**
- Explode animation with particle burst (1 second)

---

## 2️⃣ **Advanced Particle Effects**

### **Enhanced Biome Ambience**

**Enchanted Forest:**
- Magical sparkles (rare, colorful)
- Fairy dust trails
- Mushroom spores (glowing)

**Frozen Peaks:**
- Blizzard gusts (triggered by events)
- Ice crystal formations (sparkling)

**Desolate Wastes:**
- Sandstorms (intense, obscuring)
- Mirage effects (shader-based)

**Golden Plains:**
- Sun rays (god rays, expensive)
- Butterfly particles (rare)

**Ashlands:**
- Lava eruptions (rare, dramatic)
- Ash clouds (large particles)

**Highlands:**
- Storm clouds (distant lightning)
- Wind streaks (motion lines)

**Swamplands:**
- Poisonous gas (green wisps)
- Glowing algae (water surface)

### **Advanced Combat Effects**

**Critical Hits (Dice 18-20):**
- Large impact burst
- Screen shake
- Slow-motion effect (0.5 seconds)
- "CRITICAL!" text popup

**Magical Spell Effects:**
- **Dark Magic Wizard:** Purple energy projectile, explosion with tendrils
- **Demon of Darkness:** Fire column from sky, burning ground effect
- **Celestial Cleric:** Divine beam of light, healing sparkles

**Dragon Breath:**
- **Dark Blood Dragon:** Crimson fire cone
- **Sky Serpent:** Ice breath with freezing particles

---

## 3️⃣ **Advanced Lighting & Post-Processing**

### **Dynamic Time-of-Day (Optional)**

**3 Lighting States:**
- Morning (warm, soft shadows)
- Noon (bright, harsh shadows)
- Evening (cool, long shadows)

**Implementation:**

```gdscript
func set_time_of_day(time: int):
    var sun = $DirectionalLight3D
    match time:
        0:  # Morning
            sun.light_color = Color(1.0, 0.9, 0.8)
            sun.light_energy = 0.9
            sun.rotation_degrees.x = -30
        1:  # Noon
            sun.light_color = Color(1.0, 1.0, 1.0)
            sun.light_energy = 1.2
            sun.rotation_degrees.x = -60
        2:  # Evening
            sun.light_color = Color(1.0, 0.7, 0.5)
            sun.light_energy = 0.7
            sun.rotation_degrees.x = -20
```

> **Note:** This is cosmetic only, doesn't affect gameplay. Toggle in settings.

### **Color Grading & Film Grain**

**Post-Process Effects (Environment):**

```gdscript
environment.adjustment_enabled = true
environment.adjustment_brightness = 1.0
environment.adjustment_contrast = 1.1
environment.adjustment_saturation = 1.05

# Film grain (subtle texture overlay)
environment.background_mode = Environment.BG_CANVAS
# Add custom film grain shader overlay
```

---

## 4️⃣ **Audio System (Later Phase)**

### **Background Music**

**Tracks Needed:**
- Main Menu Theme (epic orchestral, 2-3 minutes loop)
- Gameplay Theme (strategic, medieval, 5-7 minutes loop)
- Combat Intensity (fast-paced, 2-3 minutes loop)
- Victory Fanfare (triumphant, 10-15 seconds)
- Defeat Theme (somber, 10-15 seconds)

**Music Style:** Orchestral medieval fantasy (like Manor Lords, Total War)
**Source:** Commission composer or use royalty-free (Incompetech, Audiojungle)

### **Sound Effects**

**UI Sounds:**
- Button click (wood knock)
- Card select (paper rustle)
- Card place (thud)
- Gold gain (coin clink)
- XP gain (magical chime)
- Turn end (bell toll)

**Gameplay Sounds:**
- Dice roll (wood clatter, dice bounce)
- Movement (footsteps on different biomes)
- Attack (weapon swings, impacts)
- Spell cast (magical whoosh)
- Damage taken (grunt/roar)
- Death (collapse, final breath)
- Mine placement (construction sounds)
- Mine generation (coin drop)

**Ambient Sounds (per biome):**
- **Forest:** Birds, rustling leaves, creek
- **Peaks:** Wind howl, ice cracking
- **Wastes:** Wind gusts, sand shifting
- **Plains:** Grass rustling, distant animals
- **Ashlands:** Fire crackle, lava bubbling
- **Hills:** Wind, distant thunder
- **Swamp:** Water drips, croaking frogs

**Audio Implementation:**

```gdscript
# Audio manager singleton
var audio_manager = AudioStreamPlayer.new()

func play_sound(sound_name: String):
    var stream = load("res://assets/audio/sfx/" + sound_name + ".ogg")
    audio_manager.stream = stream
    audio_manager.play()
```

---

## 5️⃣ **Camera Enhancements**

### **Cinematic Cutscenes (Toggle in Settings)**

**Combat Cutscene:**
- Zoom to attacker (0.5 sec)
- Show attack animation (1.5 sec)
- Dice roll dramatic reveal (2 sec)
- Zoom to defender receiving hit (1 sec)
- Return to gameplay camera (0.5 sec)

**NPC Encounter Cutscene:**
- Zoom to hex where NPC spawns (0.5 sec)
- NPC emerges from ground/terrain (2 sec)
- Camera circle around NPC (1 sec)
- Return to gameplay (0.5 sec)

**Victory Cutscene:**
- Zoom out to full board view (2 sec)
- Highlight winning player's troops (3 sec)
- Victory banner appears (2 sec)
- Fade to victory screen (1 sec)

**Camera Animation:**

```gdscript
func play_cutscene_zoom(target: Node3D, duration: float):
    var tween = create_tween()
    var camera = $Camera3D
    var target_pos = target.global_position + Vector3(2, 3, 2)
    tween.tween_property(camera, "global_position", target_pos, duration)
    tween.parallel().tween_property(camera, "look_at", target.global_position, duration)
```

---

### **Replay Camera**

**Post-Game Replay:**
- Record all actions during match
- Playback with free camera control
- Speed controls (0.5x, 1x, 2x)
- Scrubbing timeline

---

## 6️⃣ **Advanced UI**

### **Animated Tooltips**

**Hover Tooltips:**
- Troop stats (HP, ATK, DEF, Range, Speed)
- Biome effects (+A, +S, -S)
- Upgrade costs
- Item descriptions

**Tooltip Animation:**
- Fade in (0.2 sec)
- Follow cursor with slight lag (smooth)
- Rich text formatting (colors, icons)

---

### **Combat Log**

**Scrolling Combat Feed:**
- "Knight attacked Orc: 85 damage (rolled 17+85 vs 12+40)"
- "Goblin spawned at Hex (5, 3)"
- "Gold Mine level 2 generated 25 gold"

**Implementation:**
```gdscript
var combat_log = RichTextLabel.new()

func log_combat(message: String):
    combat_log.append_text("[" + Time.get_time_string_from_system() + "] " + message + "\n")
```

---

### **Stats Tracking Dashboard**

**Post-Game Stats:**
- Damage dealt/received
- Troops killed
- Gold earned/spent
- XP gained
- Mines placed/destroyed
- NPCs defeated

**Visual Charts:**
- Bar graph (damage comparison)
- Pie chart (resource distribution)

---

## 7️⃣ **Polish & Optimization**

### **Additional LOD Levels**

**5 LOD Levels Total:**
- LOD0: 100% (close-up)
- LOD1: 75% (medium distance)
- LOD2: 50% (far)
- LOD3: 25% (very far)
- LOD4: Impostor (2D billboard, extremely far)

---

### **Occlusion Culling**

**Portal-Based Culling:**
- Divide board into sectors
- Only render visible sectors
- Significant performance boost for 397 hexes

---

### **Asset Compression**

**Texture Compression:**
- VRAM Compressed (GPU-friendly)
- Basis Universal (cross-platform)

**Model Compression:**
- Draco compression for `.glb` files
- Reduces file size by 50-70%

---

### **Multithreading**

**Parallel Processing:**
- Pathfinding calculations (background thread)
- AI decisions (if AI opponents added)
- Asset loading (async)

---

## 8️⃣ **Additional Features (Far Future)**

### **Replay System**

- Save match replays
- Share replay files
- Spectator mode

### **AI Opponents**

- Behavior trees for NPC decision-making
- Difficulty levels (Easy/Medium/Hard)

### **Achievements**

- First Blood, Win Streak, Gold Hoarder, Dragon Slayer, etc.
- Steam achievements integration (if published)

### **Mobile Port (Far Future)**

- Touch controls
- Simplified UI
- Performance optimizations for mobile GPUs
- Portrait/landscape orientation support

---

# 📝 Step-by-Step Implementation Plan

---

## Overview

This section provides a comprehensive, actionable implementation plan with numbered tasks, time estimates, and dependencies. Check off tasks as you complete them.

**Estimated Total Implementation Time:** 40-60 hours

---

# 🎯 PHASE 1: NOW (Core Gameplay Assets)

## 1. Asset Acquisition

**Goal:** Download and generate all required assets before Godot integration.

**Estimated Time:** 8-12 hours

### 1.1 Poly Haven Texture Downloads

- [x] **1.1.1** Create asset folder structure: `assets/textures/biomes/`, `assets/textures/board/`, `assets/textures/ui/` ✅ (Created 2024-12-24)
- [ ] **1.1.2** Download Enchanted Forest textures:
  - [ ] `forest_leaves_02` (albedo, normal, roughness, ao)
  - [ ] `mossy_ground` (albedo, normal, roughness, ao)
- [ ] **1.1.3** Download Frozen Peaks textures:
  - [ ] `snow_02` (albedo, normal, roughness, ao)
  - [ ] `rock_face_01` (albedo, normal, roughness, ao)
- [ ] **1.1.4** Download Desolate Wastes textures:
  - [ ] `desert_sand_02` (albedo, normal, roughness, ao)
  - [ ] `cracked_ground` (albedo, normal, roughness, ao)
- [ ] **1.1.5** Download Golden Plains textures:
  - [ ] `grass_field_001` (albedo, normal, roughness, ao)
  - [ ] `dry_grass` (albedo, normal, roughness, ao)
- [ ] **1.1.6** Download Ashlands textures:
  - [ ] `volcanic_rock` (albedo, normal, roughness, ao)
  - [ ] `lava_rock_02` (albedo, normal, roughness, ao)
- [ ] **1.1.7** Download Highlands textures:
  - [ ] `hill_grass` (albedo, normal, roughness, ao)
  - [ ] `moss_001` (albedo, normal, roughness, ao)
- [ ] **1.1.8** Download Swamplands textures:
  - [ ] `mud_cracked_dry_03` (albedo, normal, roughness, ao)
  - [ ] `swamp_moss` (albedo, normal, roughness, ao)
- [ ] **1.1.9** Download board/table textures:
  - [ ] `wood_table_001` (albedo, normal, roughness, ao)
  - [ ] `castle_brick_07` (albedo, normal, roughness, ao)
  - [ ] `rusty_metal_02` (albedo, normal, roughness, ao)
- [ ] **1.1.10** Download HDRI environment:
  - [ ] `evening_road_01_4k.exr`

### 1.2 AI Model Generation (Troops)

- [ ] **1.2.1** Generate Medieval Knight model (Meshy.ai, 15K tris)
- [ ] **1.2.2** Generate Stone Giant model (Luma Labs, 25K tris)
- [ ] **1.2.3** Generate Four-Headed Hydra model (Luma Labs, 30K tris)
- [ ] **1.2.4** Generate Dark Blood Dragon model (Luma Labs, 35K tris)
- [ ] **1.2.5** Generate Sky Serpent model (Meshy.ai, 20K tris)
- [ ] **1.2.6** Generate Frost Valkyrie model (Meshy.ai, 18K tris)
- [ ] **1.2.7** Generate Dark Magic Wizard model (Meshy.ai, 12K tris)
- [ ] **1.2.8** Generate Demon of Darkness model (Luma Labs, 22K tris)
- [ ] **1.2.9** Generate Elven Archer model (Meshy.ai, 10K tris)
- [ ] **1.2.10** Generate Celestial Cleric model (Meshy.ai, 14K tris)
- [ ] **1.2.11** Generate Shadow Assassin model (Tripo3D, 9K tris)
- [ ] **1.2.12** Generate Infernal Soul model (Tripo3D, 8K tris)

### 1.3 AI Model Generation (NPCs & Structures)

- [ ] **1.3.1** Generate Goblin model (Tripo3D, 6K tris)
- [ ] **1.3.2** Generate Orc model (Meshy.ai, 12K tris)
- [ ] **1.3.3** Generate Troll model (Luma Labs, 20K tris)
- [ ] **1.3.4** Generate Gold Mine Level 1 model (Meshy.ai, 3K tris)
- [ ] **1.3.5** Generate Gold Mine Level 2 model (Meshy.ai, 4K tris)
- [ ] **1.3.6** Generate Gold Mine Level 3 model (Meshy.ai, 4K tris)
- [ ] **1.3.7** Generate Gold Mine Level 4 model (Meshy.ai, 5K tris)
- [ ] **1.3.8** Generate Gold Mine Level 5 model (Meshy.ai, 5K tris)
- [ ] **1.3.9** Generate or create D20 Dice model (Tripo3D/Blender, 2K tris)
- [ ] **1.3.10** Generate Game Table model (Meshy.ai, 5K tris)
- [ ] **1.3.11** Generate Board Frame model (Meshy.ai, 3K tris)

### 1.4 AI Card Art Generation

- [ ] **1.4.1** Generate Medieval Knight card art (Midjourney/SD)
- [ ] **1.4.2** Generate Stone Giant card art
- [ ] **1.4.3** Generate Four-Headed Hydra card art
- [ ] **1.4.4** Generate Dark Blood Dragon card art
- [ ] **1.4.5** Generate Sky Serpent card art
- [ ] **1.4.6** Generate Frost Valkyrie card art
- [ ] **1.4.7** Generate Dark Magic Wizard card art
- [ ] **1.4.8** Generate Demon of Darkness card art
- [ ] **1.4.9** Generate Elven Archer card art
- [ ] **1.4.10** Generate Celestial Cleric card art
- [ ] **1.4.11** Generate Shadow Assassin card art
- [ ] **1.4.12** Generate Infernal Soul card art
- [ ] **1.4.13** Generate Goblin NPC card art
- [ ] **1.4.14** Generate Orc NPC card art
- [ ] **1.4.15** Generate Troll NPC card art
- [ ] **1.4.16** Create card frame template in Photoshop/GIMP
- [ ] **1.4.17** Composite all 15 cards with frames and stats

### 1.5 Hex Base Models

- [ ] **1.5.1** Create hex_flat.glb in Blender (0.0 elevation)
- [ ] **1.5.2** Create hex_low.glb in Blender (0.1-0.2 elevation)
- [ ] **1.5.3** Create hex_high.glb in Blender (0.3-0.5 elevation)
- [ ] **1.5.4** UV unwrap all hex models for texture mapping
- [ ] **1.5.5** Export all models as .glb format

---

## 2. Godot Import & Configuration

**Goal:** Import all assets into Godot with correct settings.

**Estimated Time:** 6-8 hours

### 2.1 Texture Import

- [ ] **2.1.1** Import all biome textures to `res://assets/textures/biomes/`
- [ ] **2.1.2** Configure texture import settings:
  - [ ] Set Compression Mode: VRAM Compressed
  - [ ] Enable Mipmaps
  - [ ] Set Filter: Linear
  - [ ] Set Anisotropic: 16x
  - [ ] Set sRGB: Enabled for Albedo, Disabled for Normal/Roughness/AO
- [ ] **2.1.3** Import board/table textures to `res://assets/textures/board/`
- [ ] **2.1.4** Import UI textures to `res://assets/textures/ui/`
- [ ] **2.1.5** Import card textures to `res://assets/textures/cards/`
- [ ] **2.1.6** Import HDRI to `res://assets/hdri/`

### 2.2 Model Import (Troops)

- [ ] **2.2.1** Import all 12 troop models to `res://assets/models/troops/`
- [ ] **2.2.2** Configure model import settings:
  - [ ] Animation → Import: Enabled
  - [ ] Meshes → Ensure Tangents: Enabled
  - [ ] Meshes → Generate LODs: Enabled (3 levels: 100%, 60%, 30%)
  - [ ] Meshes → Create Shadow Meshes: Enabled
  - [ ] Materials → Location: Embedded
  - [ ] Mesh Compression: Enabled
- [ ] **2.2.3** Verify model scale (1 unit = 1 meter)
- [ ] **2.2.4** Test LOD transitions for each model
- [ ] **2.2.5** Add CapsuleShape3D collision shapes to each troop

### 2.3 Model Import (NPCs, Structures, Props)

- [ ] **2.3.1** Import 3 NPC models to `res://assets/models/npcs/`
- [ ] **2.3.2** Import 5 gold mine models to `res://assets/models/structures/`
- [ ] **2.3.3** Import dice model to `res://assets/models/props/`
- [ ] **2.3.4** Import table and board frame to `res://assets/models/board/`
- [ ] **2.3.5** Import hex base models to `res://assets/models/board/`
- [ ] **2.3.6** Apply same import settings as troop models

### 2.4 Animation Import

- [ ] **2.4.1** Upload troop models to Mixamo for animation
- [ ] **2.4.2** Download attack animations for all 12 troops
- [ ] **2.4.3** Download damage animations for all 12 troops
- [ ] **2.4.4** Download death animations for all 12 troops
- [ ] **2.4.5** Download attack/damage/death for 3 NPCs
- [ ] **2.4.6** Import all animations to Godot
- [ ] **2.4.7** Configure animation import settings:
  - [ ] Animation → Storage: Embedded
  - [ ] Animation → FPS: 30 (Low/Med), 60 (High/Ultra)
  - [ ] Optimizer → Enabled: Yes
- [ ] **2.4.8** Test all animations in AnimationPlayer for each model

---

## 3. Material & Shader Setup

**Goal:** Configure all materials and create team color system.

**Estimated Time:** 4-5 hours

### 3.1 Biome Materials

- [ ] **3.1.1** Create `forest_material.tres` with PBR textures
- [ ] **3.1.2** Create `peaks_material.tres` with PBR textures
- [ ] **3.1.3** Create `wastes_material.tres` with PBR textures
- [ ] **3.1.4** Create `plains_material.tres` with PBR textures
- [ ] **3.1.5** Create `ashlands_material.tres` with PBR textures
- [ ] **3.1.6** Create `highlands_material.tres` with PBR textures
- [ ] **3.1.7** Create `swamp_material.tres` with PBR textures
- [ ] **3.1.8** Configure StandardMaterial3D settings for each:
  - [ ] Assign Albedo, Normal, Roughness, AO textures
  - [ ] Set Metallic: 0.0
  - [ ] Set Roughness: 0.8

### 3.2 Team Color Shader

- [ ] **3.2.1** Create `team_color_shader.gdshader` file
- [ ] **3.2.2** Implement shader with team color parameters:
  - [ ] `team_primary_color` uniform
  - [ ] `team_accent_color` uniform
  - [ ] `team_color_intensity` uniform
  - [ ] `team_mask_texture` uniform
- [ ] **3.2.3** Create team mask texture for Medieval Knight
- [ ] **3.2.4** Create team mask texture for Stone Giant
- [ ] **3.2.5** Create team mask texture for Four-Headed Hydra
- [ ] **3.2.6** Create team mask texture for Dark Blood Dragon
- [ ] **3.2.7** Create team mask texture for Sky Serpent
- [ ] **3.2.8** Create team mask texture for Frost Valkyrie
- [ ] **3.2.9** Create team mask texture for Dark Magic Wizard
- [ ] **3.2.10** Create team mask texture for Demon of Darkness
- [ ] **3.2.11** Create team mask texture for Elven Archer
- [ ] **3.2.12** Create team mask texture for Celestial Cleric
- [ ] **3.2.13** Create team mask texture for Shadow Assassin
- [ ] **3.2.14** Create team mask texture for Infernal Soul

### 3.3 Material Application

- [ ] **3.3.1** Create ShaderMaterial for each troop with team_color_shader
- [ ] **3.3.2** Assign PBR textures to shader materials
- [ ] **3.3.3** Assign team mask textures to shader materials
- [ ] **3.3.4** Apply shader materials to all 12 troop models
- [ ] **3.3.5** Test team recoloring (Player 1 Blue, Player 2 Red)
- [ ] **3.3.6** Create `apply_team_color()` utility function in GDScript

---

## 4. Board & Environment Setup

**Goal:** Set up the game board and lighting environment.

**Estimated Time:** 4-5 hours

### 4.1 Hex Board Configuration

- [ ] **4.1.1** Update HexBoard to support 397 hexes (12 per side)
- [ ] **4.1.2** Create hex mesh instances for each tile
- [ ] **4.1.3** Assign biome materials based on procedural generation
- [ ] **4.1.4** Implement biome texture blending at borders (optional)
- [ ] **4.1.5** Test biome visual distribution

### 4.2 Height Variation System

- [ ] **4.2.1** Create height variation toggle in settings
- [ ] **4.2.2** Implement hex model swapping based on biome:
  - [ ] Flat: Plains, Forest
  - [ ] Low: Swamp, Wastes
  - [ ] High: Peaks, Hills, Ashlands
- [ ] **4.2.3** Test height variation on/off toggle

### 4.3 Table & Frame Setup

- [ ] **4.3.1** Position game table model in scene
- [ ] **4.3.2** Apply wood table material to table
- [ ] **4.3.3** Position board frame around hex grid
- [ ] **4.3.4** Apply stone/metal materials to frame
- [ ] **4.3.5** Verify board fits within frame

### 4.4 Lighting Configuration

- [ ] **4.4.1** Create DirectionalLight3D node (Sun)
- [ ] **4.4.2** Configure sun settings:
  - [ ] Light Energy: 1.0
  - [ ] Light Color: Warm natural (1.0, 0.95, 0.9)
  - [ ] Rotation: -45°, 30°, 0°
  - [ ] Shadow Enabled: true
  - [ ] Shadow Mode: Orthogonal
  - [ ] Max Distance: 50.0
- [ ] **4.4.3** Create WorldEnvironment node
- [ ] **4.4.4** Configure Environment resource:
  - [ ] Background Mode: Sky
  - [ ] Ambient Light Source: Sky
  - [ ] Ambient Light Energy: 0.5
  - [ ] Tonemap Mode: ACES
  - [ ] SSAO Enabled: true
  - [ ] Glow Enabled: true
- [ ] **4.4.5** Create Sky with PanoramaSkyMaterial
- [ ] **4.4.6** Assign HDRI texture to sky material
- [ ] **4.4.7** Test lighting on all biomes

---

## 5. UI System Implementation

**Goal:** Create medieval-themed UI system.

**Estimated Time:** 5-6 hours

### 5.1 UI Theme Creation

- [ ] **5.1.1** Create `medieval_theme.tres` Theme resource
- [ ] **5.1.2** Create button textures:
  - [ ] `button_normal.png` (wood texture)
  - [ ] `button_hover.png` (lighter wood)
  - [ ] `button_pressed.png` (darker wood)
  - [ ] `button_disabled.png` (grayscale)
- [ ] **5.1.3** Create StyleBoxTexture for each button state
- [ ] **5.1.4** Configure button margins (8px all sides)
- [ ] **5.1.5** Create panel textures:
  - [ ] `panel_stone.png`
  - [ ] `panel_wood.png`
- [ ] **5.1.6** Download medieval fonts (Cinzel Bold, Roboto Condensed)
- [ ] **5.1.7** Configure theme font settings

### 5.2 UI Icons

- [ ] **5.2.1** Create or download move action icon (footprint, 64x64)
- [ ] **5.2.2** Create or download attack action icon (crossed swords)
- [ ] **5.2.3** Create or download place mine icon (pickaxe)
- [ ] **5.2.4** Create or download upgrade icon (hammer/anvil)
- [ ] **5.2.5** Create or download use item icon (potion)
- [ ] **5.2.6** Create or download end turn icon (hourglass)
- [ ] **5.2.7** Import icons as SVG to `res://assets/textures/ui/icons/`

### 5.3 Resource Displays

- [ ] **5.3.1** Create Gold display panel (stone background, coin icon)
- [ ] **5.3.2** Create XP display panel (stone background, star icon)
- [ ] **5.3.3** Create turn timer display (circular stone dial)
- [ ] **5.3.4** Position displays in HUD layout
- [ ] **5.3.5** Connect displays to game state

### 5.4 Card Display System (3D)

- [ ] **5.4.1** Create card 3D plane mesh (0.6 x 0.9 units)
- [ ] **5.4.2** Create card material with card texture
- [ ] **5.4.3** Implement card hover animation (lift + tilt)
- [ ] **5.4.4** Implement card glow effect on hover
- [ ] **5.4.5** Create card hand layout (fan arrangement)
- [ ] **5.4.6** Connect card selection to troop focus

### 5.5 Settings Menu

- [ ] **5.5.1** Create settings menu scene
- [ ] **5.5.2** Add Graphics tab with all options
- [ ] **5.5.3** Add Preset dropdown (Auto/Low/Med/High/Ultra)
- [ ] **5.5.4** Add individual setting controls
- [ ] **5.5.5** Implement settings save/load with ConfigFile
- [ ] **5.5.6** Apply theme to all settings UI elements

---

## 6. Particle Effects

**Goal:** Create ambient biome and combat particles.

**Estimated Time:** 3-4 hours

### 6.1 Biome Ambient Particles

- [ ] **6.1.1** Create Forest firefly particles (GPUParticles3D)
- [ ] **6.1.2** Create Peaks snow flurry particles
- [ ] **6.1.3** Create Wastes dust devil particles
- [ ] **6.1.4** Create Plains pollen particles
- [ ] **6.1.5** Create Ashlands ember particles
- [ ] **6.1.6** Create Highlands wind particles
- [ ] **6.1.7** Create Swamp fog particles
- [ ] **6.1.8** Configure particle process materials for each
- [ ] **6.1.9** Test particles on respective biome hexes

### 6.2 Combat Particles

- [ ] **6.2.1** Create melee hit spark particles
- [ ] **6.2.2** Create melee hit dust particles
- [ ] **6.2.3** Create ranged arrow trail particles
- [ ] **6.2.4** Create ranged impact splinter particles
- [ ] **6.2.5** Create magic spell projectile particles (purple, red, gold variants)
- [ ] **6.2.6** Create magic impact explosion particles

### 6.3 Death Effect Particles

- [ ] **6.3.1** Create fade-out shader for death animation
- [ ] **6.3.2** Create dust/ash burst particles on death
- [ ] **6.3.3** Create soul wisp particles (optional)
- [ ] **6.3.4** Connect particles to death animation events

### 6.4 Particle Quality Settings

- [ ] **6.4.1** Create `set_particle_quality(level: int)` function
- [ ] **6.4.2** Implement particle count scaling:
  - [ ] Low: 25%
  - [ ] Medium: 50%
  - [ ] High: 100%
  - [ ] Ultra: 100% + extras
- [ ] **6.4.3** Connect to quality settings system

---

## 7. Quality Settings System

**Goal:** Implement hardware-adaptive graphics settings.

**Estimated Time:** 3-4 hours

### 7.1 Auto-Detection

- [ ] **7.1.1** Create `detect_hardware_preset()` function
- [ ] **7.1.2** Implement VRAM detection logic
- [ ] **7.1.3** Map VRAM ranges to quality presets:
  - [ ] <2GB → Low
  - [ ] 2-4GB → Medium
  - [ ] 4-8GB → High
  - [ ] 8GB+ → Ultra
- [ ] **7.1.4** Apply auto-detected preset on first launch

### 7.2 Quality Preset Functions

- [ ] **7.2.1** Create `apply_quality_preset(level: int)` function
- [ ] **7.2.2** Implement `set_texture_quality(level: int)`
- [ ] **7.2.3** Implement `set_model_quality(level: int)` (LOD bias)
- [ ] **7.2.4** Implement `set_shadow_quality(level: int)`
- [ ] **7.2.5** Implement `set_particle_quality(level: int)`
- [ ] **7.2.6** Implement `set_antialiasing(mode: int)`
- [ ] **7.2.7** Implement `set_ambient_occlusion(enabled: bool)`
- [ ] **7.2.8** Implement `set_bloom(enabled: bool, intensity: float)`

### 7.3 Preset Configurations

- [ ] **7.3.1** Define Low preset configuration dictionary
- [ ] **7.3.2** Define Medium preset configuration dictionary
- [ ] **7.3.3** Define High preset configuration dictionary
- [ ] **7.3.4** Define Ultra preset configuration dictionary
- [ ] **7.3.5** Create preset application function

### 7.4 Settings Persistence

- [ ] **7.4.1** Create `save_settings()` function using ConfigFile
- [ ] **7.4.2** Create `load_settings()` function
- [ ] **7.4.3** Save settings to `user://settings.cfg`
- [ ] **7.4.4** Load settings on game start
- [ ] **7.4.5** Apply loaded settings

---

## 8. Dice System

**Goal:** Implement physical dice rolling system.

**Estimated Time:** 2-3 hours

### 8.1 Dice Model Setup

- [ ] **8.1.1** Position dice model in scene
- [ ] **8.1.2** Create RigidBody3D for dice physics
- [ ] **8.1.3** Add collision shape (ConvexPolygonShape3D)
- [ ] **8.1.4** Configure physics properties:
  - [ ] Mass: 0.1
  - [ ] Bounce: 0.3
  - [ ] Friction: 0.7

### 8.2 Dice Rolling Arena

- [ ] **8.2.1** Create small table section for dice rolling
- [ ] **8.2.2** Add invisible boundary walls (StaticBody3D)
- [ ] **8.2.3** Configure surface friction for realistic rolling
- [ ] **8.2.4** Add shadow caster for dice area

### 8.3 Dice Rolling Logic

- [ ] **8.3.1** Create `DiceRoller` script
- [ ] **8.3.2** Implement `roll_dice()` function:
  - [ ] Apply random force and torque
  - [ ] Wait for dice to settle
  - [ ] Detect top face
  - [ ] Return result (1-20)
- [ ] **8.3.3** Create `detect_top_face()` function using raycasts
- [ ] **8.3.4** Test dice roll detection accuracy
- [ ] **8.3.5** Integrate with combat system

### 8.4 Dice Camera

- [ ] **8.4.1** Create camera position for dice view
- [ ] **8.4.2** Implement camera zoom to dice during roll
- [ ] **8.4.3** Return camera to game view after roll

---

## 9. Testing & Polish

**Goal:** Verify all assets work correctly and optimize.

**Estimated Time:** 3-4 hours

### 9.1 Asset Loading Tests

- [ ] **9.1.1** Verify all textures load without errors
- [ ] **9.1.2** Verify all models load without errors
- [ ] **9.1.3** Verify all animations play correctly
- [ ] **9.1.4** Verify all materials render correctly
- [ ] **9.1.5** Check for missing texture warnings

### 9.2 Visual Quality Tests

- [ ] **9.2.1** Test biome material appearance on hexes
- [ ] **9.2.2** Test troop model appearance and team colors
- [ ] **9.2.3** Test NPC model appearance
- [ ] **9.2.4** Test gold mine visual progression (levels 1-5)
- [ ] **9.2.5** Test card art clarity and frame design
- [ ] **9.2.6** Test UI theme consistency

### 9.3 Quality Settings Tests

- [ ] **9.3.1** Test Low preset FPS on integrated graphics
- [ ] **9.3.2** Test Medium preset on mid-range GPU
- [ ] **9.3.3** Test High preset on gaming GPU
- [ ] **9.3.4** Test Ultra preset on high-end GPU
- [ ] **9.3.5** Verify LOD transitions are smooth
- [ ] **9.3.6** Verify particle scaling works correctly

### 9.4 Performance Optimization

- [ ] **9.4.1** Check draw calls during gameplay
- [ ] **9.4.2** Verify no memory leaks during extended play
- [ ] **9.4.3** Optimize oversized textures if needed
- [ ] **9.4.4** Reduce polygon count on high-poly models if needed
- [ ] **9.4.5** Enable mesh compression on all models

### 9.5 Bug Fixes

- [ ] **9.5.1** Fix any visual glitches identified
- [ ] **9.5.2** Fix any material rendering issues
- [ ] **9.5.3** Fix any animation playback issues
- [ ] **9.5.4** Fix any particle effect issues
- [ ] **9.5.5** Fix any UI display issues

---

# 🚀 PHASE 2: LATER (Polish & Advanced Features)

## 10. Advanced Animations

**Goal:** Add movement, idle, and special ability animations.

**Estimated Time:** 6-8 hours

### 10.1 Movement Animations

- [ ] **10.1.1** Download/create walk cycle for 12 troops (Mixamo)
- [ ] **10.1.2** Download/create run cycle for 12 troops
- [ ] **10.1.3** Download/create fly cycle for 3 air units
- [ ] **10.1.4** Create slither animation for Hydra/Serpent
- [ ] **10.1.5** Import and test all movement animations

### 10.2 Idle Animations

- [ ] **10.2.1** Create 2-3 idle variants per troop
- [ ] **10.2.2** Implement idle animation random selection
- [ ] **10.2.3** Test idle animation loops
- [ ] **10.2.4** Add subtle weapon idle effects (glow pulse, etc.)

### 10.3 Special Ability Animations

- [ ] **10.3.1** Create Hydra multi-strike animation
- [ ] **10.3.2** Create Cleric healing aura animation
- [ ] **10.3.3** Create Infernal Soul self-destruct animation
- [ ] **10.3.4** Create Dragon fire breath animation
- [ ] **10.3.5** Create Wizard spell casting animation

---

## 11. Advanced Particle Effects

**Goal:** Enhanced visual effects for combat and biomes.

**Estimated Time:** 4-5 hours

### 11.1 Enhanced Biome Ambience

- [ ] **11.1.1** Add magical sparkles to Forest
- [ ] **11.1.2** Add blizzard gusts to Peaks (triggered)
- [ ] **11.1.3** Add sandstorm effects to Wastes
- [ ] **11.1.4** Add butterfly particles to Plains
- [ ] **11.1.5** Add lava eruption effects to Ashlands
- [ ] **11.1.6** Add storm clouds to Highlands
- [ ] **11.1.7** Add glowing algae to Swamp

### 11.2 Critical Hit Effects

- [ ] **11.2.1** Create large impact burst
- [ ] **11.2.2** Implement screen shake
- [ ] **11.2.3** Create slow-motion effect (0.5 sec)
- [ ] **11.2.4** Add "CRITICAL!" text popup

### 11.3 Spell Effects

- [ ] **11.3.1** Create Dark Wizard purple energy projectile
- [ ] **11.3.2** Create Demon fire column effect
- [ ] **11.3.3** Create Cleric divine beam effect
- [ ] **11.3.4** Create Dragon fire breath cone
- [ ] **11.3.5** Create Serpent ice breath effect

---

## 12. Audio System

**Goal:** Implement background music and sound effects.

**Estimated Time:** 6-8 hours

### 12.1 Music Acquisition

- [ ] **12.1.1** Acquire/commission Main Menu theme (2-3 min loop)
- [ ] **12.1.2** Acquire/commission Gameplay theme (5-7 min loop)
- [ ] **12.1.3** Acquire/commission Combat Intensity theme (2-3 min loop)
- [ ] **12.1.4** Acquire Victory Fanfare (10-15 sec)
- [ ] **12.1.5** Acquire Defeat Theme (10-15 sec)

### 12.2 UI Sound Effects

- [ ] **12.2.1** Acquire button click sound (wood knock)
- [ ] **12.2.2** Acquire card select sound (paper rustle)
- [ ] **12.2.3** Acquire card place sound (thud)
- [ ] **12.2.4** Acquire gold gain sound (coin clink)
- [ ] **12.2.5** Acquire XP gain sound (magical chime)
- [ ] **12.2.6** Acquire turn end sound (bell toll)

### 12.3 Gameplay Sound Effects

- [ ] **12.3.1** Acquire dice roll sounds (clatter, bounce)
- [ ] **12.3.2** Acquire footstep sounds (per biome type)
- [ ] **12.3.3** Acquire weapon swing sounds
- [ ] **12.3.4** Acquire impact sounds
- [ ] **12.3.5** Acquire spell cast sounds
- [ ] **12.3.6** Acquire damage grunt sounds
- [ ] **12.3.7** Acquire death sounds

### 12.4 Ambient Sounds

- [ ] **12.4.1** Acquire Forest ambience (birds, leaves)
- [ ] **12.4.2** Acquire Peaks ambience (wind howl)
- [ ] **12.4.3** Acquire Wastes ambience (wind, sand)
- [ ] **12.4.4** Acquire Plains ambience (grass, animals)
- [ ] **12.4.5** Acquire Ashlands ambience (fire, lava)
- [ ] **12.4.6** Acquire Highlands ambience (wind, thunder)
- [ ] **12.4.7** Acquire Swamp ambience (water, frogs)

### 12.5 Audio Implementation

- [ ] **12.5.1** Create AudioManager singleton
- [ ] **12.5.2** Implement music playback with crossfade
- [ ] **12.5.3** Implement SFX playback system
- [ ] **12.5.4** Create ambient sound zones per biome
- [ ] **12.5.5** Add volume controls to settings menu
- [ ] **12.5.6** Test audio on all quality presets

---

## 13. Camera Enhancements

**Goal:** Implement cinematic cutscenes and replay system.

**Estimated Time:** 4-5 hours

### 13.1 Combat Cutscenes

- [ ] **13.1.1** Create combat camera path (attacker → dice → defender)
- [ ] **13.1.2** Implement zoom to attacker (0.5 sec)
- [ ] **13.1.3** Implement dice roll camera focus (2 sec)
- [ ] **13.1.4** Implement zoom to defender (1 sec)
- [ ] **13.1.5** Implement return to gameplay (0.5 sec)
- [ ] **13.1.6** Add cutscene toggle to settings

### 13.2 Event Cutscenes

- [ ] **13.2.1** Create NPC encounter cutscene
- [ ] **13.2.2** Create Victory cutscene
- [ ] **13.2.3** Create Defeat cutscene
- [ ] **13.2.4** Add speed controls (Full/Fast/Skip)

### 13.3 Replay System

- [ ] **13.3.1** Create action recording system
- [ ] **13.3.2** Create replay playback system
- [ ] **13.3.3** Add free camera control during replay
- [ ] **13.3.4** Add speed controls (0.5x, 1x, 2x)
- [ ] **13.3.5** Add timeline scrubbing

---

## 14. Advanced UI

**Goal:** Implement animated tooltips, combat log, and stats.

**Estimated Time:** 3-4 hours

### 14.1 Animated Tooltips

- [ ] **14.1.1** Create tooltip scene with fade-in animation
- [ ] **14.1.2** Implement cursor tracking with lag
- [ ] **14.1.3** Add rich text formatting
- [ ] **14.1.4** Add icons in tooltips

### 14.2 Combat Log

- [ ] **14.2.1** Create scrolling combat feed panel
- [ ] **14.2.2** Implement log message formatting
- [ ] **14.2.3** Add timestamps to messages
- [ ] **14.2.4** Add color coding for combat types

### 14.3 Stats Dashboard

- [ ] **14.3.1** Create post-game stats panel
- [ ] **14.3.2** Track and display: damage dealt/received
- [ ] **14.3.3** Track and display: troops killed
- [ ] **14.3.4** Track and display: gold earned/spent
- [ ] **14.3.5** Create bar graph visualization
- [ ] **14.3.6** Create pie chart visualization

---

## 15. Optimization

**Goal:** Final performance optimization pass.

**Estimated Time:** 3-4 hours

### 15.1 LOD Enhancement

- [ ] **15.1.1** Create 5-level LOD system (100%, 75%, 50%, 25%, billboard)
- [ ] **15.1.2** Configure LOD distances for each level
- [ ] **15.1.3** Create billboard impostors for far troops

### 15.2 Culling

- [ ] **15.2.1** Implement occlusion culling
- [ ] **15.2.2** Divide board into culling sectors
- [ ] **15.2.3** Test culling performance improvement

### 15.3 Compression

- [ ] **15.3.1** Apply Draco compression to all .glb models
- [ ] **15.3.2** Verify compressed models load correctly
- [ ] **15.3.3** Apply Basis Universal to textures where appropriate

### 15.4 Multithreading

- [ ] **15.4.1** Move pathfinding to background thread
- [ ] **15.4.2** Implement async asset loading
- [ ] **15.4.3** Test threading on multi-core systems

---

## 16. Future Features

**Goal:** Optional advanced features for later development.

**Estimated Time:** Variable

### 16.1 Replay System

- [ ] **16.1.1** Save match replays to file
- [ ] **16.1.2** Load and playback replay files
- [ ] **16.1.3** Share replay files with other players

### 16.2 AI Opponents

- [ ] **16.2.1** Create behavior trees for NPC AI
- [ ] **16.2.2** Implement Easy difficulty
- [ ] **16.2.3** Implement Medium difficulty
- [ ] **16.2.4** Implement Hard difficulty

### 16.3 Achievements

- [ ] **16.3.1** Define achievement list
- [ ] **16.3.2** Implement achievement tracking
- [ ] **16.3.3** Create achievement UI
- [ ] **16.3.4** Steam integration (if publishing)

### 16.4 Mobile Port

- [ ] **16.4.1** Implement touch controls
- [ ] **16.4.2** Simplify UI for mobile
- [ ] **16.4.3** Optimize for mobile GPUs
- [ ] **16.4.4** Support portrait/landscape

---

# 📊 Progress Tracker

## ✅ Pre-Requisites Complete (2024-12-24)

| Pre-Requisite | Status | Notes |
|---------------|--------|-------|
| Asset folder structure | ✅ Complete | `assets/models/`, `assets/textures/`, `assets/shaders/`, etc. |
| Team color shader | ✅ Complete | `assets/shaders/team_color_shader.gdshader` |
| Quality settings system | ✅ Complete | Added to `settings_manager.gd` with all functions |
| Troop name verification | ✅ Complete | All names match between code and plan |
| 3D vs 2D design decision | ✅ Complete | Use 3D dice with physics rolling, 2D cards, 3D troops/board |
| **Texture Downloads** | ✅ Complete | Dec 28-29, 2024 - All biome, board, UI textures (~8.6 GB) |

## Phase 1: NOW - Core Assets

| Section | Tasks | Completed |
|---------|-------|-----------|
| 1. Asset Acquisition | 60 tasks | 35/60 ✅ (All textures downloaded) |
| 2. Godot Import | 24 tasks | 0/24 |
| 3. Materials & Shaders | 22 tasks | 1/22 |
| 4. Board & Environment | 18 tasks | 0/18 |
| 5. UI System | 23 tasks | 0/23 |
| 6. Particle Effects | 16 tasks | 0/16 |
| 7. Quality Settings | 18 tasks | 18/18 ✅ |
| 8. Dice System | 14 tasks | 0/14 |
| 9. Testing & Polish | 20 tasks | 0/20 |
| **Phase 1 Total** | **215 tasks** | **20/215** |

## Phase 2: LATER - Polish

| Section | Tasks | Completed |
|---------|-------|-----------|
| 10. Advanced Animations | 14 tasks | 0/14 |
| 11. Advanced Particles | 17 tasks | 0/17 |
| 12. Audio System | 32 tasks | 0/32 |
| 13. Camera Enhancements | 14 tasks | 0/14 |
| 14. Advanced UI | 12 tasks | 0/12 |
| 15. Optimization | 10 tasks | 0/10 |
| 16. Future Features | 14 tasks | 0/14 |
| **Phase 2 Total** | **113 tasks** | **0/113** |

---

**Grand Total: 328 tasks**

---

# 🎯 **Quick Reference: Downloaded Assets**

> ✅ **All terrain textures downloaded on December 28-29, 2024**
> Total: ~220 texture files (~8.6 GB)
> Format: 4K PNG with 5 PBR maps (Diffuse, Normal, Roughness, AO, Displacement)

## Biome Textures ✅ COMPLETE

| Biome | Primary Source | Secondary Source | Props Source |
|-------|----------------|------------------|--------------|
| Enchanted Forest | `forest_leaves_02` | `brown_mud_leaves_01` | `bark_brown_01`, `bark_willow`, `coast_sand_rocks_02` |
| Frozen Peaks | `snow_02` | `aerial_rocks_02` | `cliff_side`, `asphalt_snow` |
| Desolate Wastes | `aerial_beach_01` | `dry_ground_01` | `dry_ground_rocks`, `cracked_red_ground`, `coast_sand_05` |
| Golden Plains | `grass_path_2` | `rocky_terrain_02` | `forrest_ground_01`, `Grass004` (ACG), `Ground037` (ACG) |
| Ashlands | `burned_ground_01` | `aerial_rocks_04` | `cracked_concrete`, `bitumen`, `rock_boulder_dry` |
| Highlands | *(shares GP)* | *(shares EF)* | `aerial_grass_rock`, `aerial_rocks_01`, `brown_mud_rocks_01` |
| Swamplands | `brown_mud_02` | `brown_mud_03` | `concrete_moss`, `aerial_mud_1`, `cobblestone_floor_04` |

## Board & UI Textures ✅ COMPLETE

| Purpose | Asset Name | Source | Local Prefix |
|---------|------------|--------|--------------|
| Table Wood | `dark_wood` | Poly Haven | `table_wood_*` |
| Table Wood Alt | `brown_planks_03`, `dark_wooden_planks` | Poly Haven | `table_wood_alt1_*`, `table_wood_alt2_*` |
| Frame Stone | `castle_brick_01` | Poly Haven | `frame_stone_*` |
| Frame Stone Alt | `castle_wall_slates`, `defense_wall` | Poly Haven | `frame_stone_alt1_*`, `frame_stone_alt2_*` |
| Frame Metal | `corrugated_iron` | Poly Haven | `frame_metal_*` |
| Frame Metal Alt | `blue_metal_plate` | Poly Haven | `frame_metal_alt_*` |
| UI Wood | `dark_wood` | Poly Haven | `ui_wood_*` |
| UI Stone | `castle_brick_01` | Poly Haven | `ui_stone_*` |
| UI Metal | `corrugated_iron` | Poly Haven | `ui_metal_*` |

## HDRI Environment ✅ COMPLETE

- **File:** `evening_road_01_4k.exr`
- **Source:** Poly Haven
- **Location:** `res://assets/hdri/`

## Asset Sources

| Source | License | Textures Downloaded |
|--------|---------|---------------------|
| [Poly Haven](https://polyhaven.com) | CC0 | ~200 files |
| [AmbientCG](https://ambientcg.com) | CC0 | ~20 files (Golden Plains) |

## Still Needed (Optional Enhancements)

For specialized effects, consider sourcing from AmbientCG or Quixel Megascans:
- ❄️ Ice textures (Frozen Peaks - currently using snow alternatives)
- 🌋 Volcanic/lava rock (Ashlands - use shader effects for glow)
- 🌊 Water caustics (Swamplands - use shader-based effects)

---

# ✨ **Final Notes**

This plan provides **complete, actionable steps** for integrating high-quality assets into your medieval fantasy board game. The plan is structured to prioritize **Phase 1 (NOW)** for immediate gameplay needs, with **Phase 2 (LATER)** for polish and advanced features.

**Key Strengths:**
- ✅ Granular quality settings for scalability
- ✅ Manor Lords-inspired aesthetic with fantasy elements
- ✅ Consistent theme across all assets
- ✅ Hardware-adaptive performance
- ✅ Detailed Godot import instructions
- ✅ Specific AI generation prompts
- ✅ **All terrain textures downloaded and ready**

**Completed:**
- ✅ Poly Haven texture downloads (all biomes, board, UI)
- ✅ AmbientCG grass textures for Golden Plains
- ✅ HDRI environment lighting

**Next Steps:**
1. ~~Download Poly Haven textures~~ ✅ COMPLETE
2. Generate troop models via AI platforms
3. Generate card art illustrations
4. Import assets to Godot following specifications
5. Create materials using downloaded textures
6. Test on target hardware