# Troop Name Consistency Verification

## ✅ Verification Complete - All Names Match

This document verifies that troop names in `card_data.gd` match the asset generation prompts in `asset_integration_master_plan.md`.

## Troop Name Mapping

| # | Code ID (card_data.gd) | Display Name | Asset Plan Name | Status |
|---|------------------------|--------------|-----------------|--------|
| 1 | `medieval_knight` | Medieval Knight | Medieval Knight | ✅ Match |
| 2 | `stone_giant` | Stone Giant | Stone Giant | ✅ Match |
| 3 | `four_headed_hydra` | Four-Headed Hydra | Four-Headed Hydra | ✅ Match |
| 4 | `dark_blood_dragon` | Dark Blood Dragon | Dark Blood Dragon | ✅ Match |
| 5 | `sky_serpent` | Sky Serpent | Sky Serpent | ✅ Match |
| 6 | `frost_valkyrie` | Frost Valkyrie | Frost Valkyrie | ✅ Match |
| 7 | `dark_magic_wizard` | Dark Magic Wizard | Dark Magic Wizard | ✅ Match |
| 8 | `demon_of_darkness` | Demon of Darkness | Demon of Darkness | ✅ Match |
| 9 | `elven_archer` | Elven Archer | Elven Archer | ✅ Match |
| 10 | `celestial_cleric` | Celestial Cleric | Celestial Cleric | ✅ Match |
| 11 | `shadow_assassin` | Shadow Assassin | Shadow Assassin | ✅ Match |
| 12 | `infernal_soul` | Infernal Soul | Infernal Soul | ✅ Match |

## NPC Name Mapping

| # | Code ID (card_data.gd) | Display Name | Asset Plan Name | Status |
|---|------------------------|--------------|-----------------|--------|
| 1 | `goblin` | Goblin | Goblin | ✅ Match |
| 2 | `orc` | Orc | Orc | ✅ Match |
| 3 | `troll` | Troll | Troll | ✅ Match |

## Asset File Naming Convention

When generating/importing assets, use these exact filenames:

### 3D Models (`assets/models/troops/`)
```
knight.glb
stone_giant.glb
hydra.glb
dark_dragon.glb
sky_serpent.glb
frost_valkyrie.glb
dark_wizard.glb
demon.glb
elven_archer.glb
celestial_cleric.glb
shadow_assassin.glb
infernal_soul.glb
```

### Team Mask Textures (`assets/textures/troops/`)
```
knight_team_mask.png
stone_giant_team_mask.png
hydra_team_mask.png
dark_dragon_team_mask.png
sky_serpent_team_mask.png
frost_valkyrie_team_mask.png
dark_wizard_team_mask.png
demon_team_mask.png
elven_archer_team_mask.png
celestial_cleric_team_mask.png
shadow_assassin_team_mask.png
infernal_soul_team_mask.png
```

### Card Art (`assets/textures/cards/`)
```
knight_card.png
stone_giant_card.png
hydra_card.png
dark_dragon_card.png
sky_serpent_card.png
frost_valkyrie_card.png
dark_wizard_card.png
demon_card.png
elven_archer_card.png
celestial_cleric_card.png
shadow_assassin_card.png
infernal_soul_card.png
goblin_card.png
orc_card.png
troll_card.png
```

### NPC Models (`assets/models/npcs/`)
```
goblin.glb
orc.glb
troll.glb
```

## Code-to-Asset Loader Reference

When loading assets in code, use these mappings:

```gdscript
# Example: Load troop model based on card_data ID
const TROOP_MODEL_PATHS: Dictionary = {
    "medieval_knight": "res://assets/models/troops/knight.glb",
    "stone_giant": "res://assets/models/troops/stone_giant.glb",
    "four_headed_hydra": "res://assets/models/troops/hydra.glb",
    "dark_blood_dragon": "res://assets/models/troops/dark_dragon.glb",
    "sky_serpent": "res://assets/models/troops/sky_serpent.glb",
    "frost_valkyrie": "res://assets/models/troops/frost_valkyrie.glb",
    "dark_magic_wizard": "res://assets/models/troops/dark_wizard.glb",
    "demon_of_darkness": "res://assets/models/troops/demon.glb",
    "elven_archer": "res://assets/models/troops/elven_archer.glb",
    "celestial_cleric": "res://assets/models/troops/celestial_cleric.glb",
    "shadow_assassin": "res://assets/models/troops/shadow_assassin.glb",
    "infernal_soul": "res://assets/models/troops/infernal_soul.glb"
}

const NPC_MODEL_PATHS: Dictionary = {
    "goblin": "res://assets/models/npcs/goblin.glb",
    "orc": "res://assets/models/npcs/orc.glb",
    "troll": "res://assets/models/npcs/troll.glb"
}

const CARD_ART_PATHS: Dictionary = {
    "medieval_knight": "res://assets/textures/cards/knight_card.png",
    "stone_giant": "res://assets/textures/cards/stone_giant_card.png",
    "four_headed_hydra": "res://assets/textures/cards/hydra_card.png",
    "dark_blood_dragon": "res://assets/textures/cards/dark_dragon_card.png",
    "sky_serpent": "res://assets/textures/cards/sky_serpent_card.png",
    "frost_valkyrie": "res://assets/textures/cards/frost_valkyrie_card.png",
    "dark_magic_wizard": "res://assets/textures/cards/dark_wizard_card.png",
    "demon_of_darkness": "res://assets/textures/cards/demon_card.png",
    "elven_archer": "res://assets/textures/cards/elven_archer_card.png",
    "celestial_cleric": "res://assets/textures/cards/celestial_cleric_card.png",
    "shadow_assassin": "res://assets/textures/cards/shadow_assassin_card.png",
    "infernal_soul": "res://assets/textures/cards/infernal_soul_card.png"
}
```

---

*Verification Date: 2025-12-24*
*Status: All troop and NPC names are consistent between code and asset plan*
