#!/usr/bin/env python3
"""
Poly Haven Texture Downloader for Fantasy World Board Game
Downloads 4K PNG textures using the Poly Haven API with proper URL resolution.
"""

import json
import os
import sys
import urllib.request
import urllib.error
from pathlib import Path
from typing import Optional, Dict, List, Tuple

# Configuration
RESOLUTION = "4k"
FORMAT = "png"
USER_AGENT = "FantasyWorldBoardGame/1.0 (github.com/luca-liceti)"
API_BASE = "https://api.polyhaven.com/files"

# Paths
PROJECT_DIR = Path("/home/luca/Documents/Github Projects/Fantasy World The Video Game 12-20-2025")
ASSETS_DIR = PROJECT_DIR / "fantasy-world-game" / "assets"
TEXTURES_DIR = ASSETS_DIR / "textures"
HDRI_DIR = ASSETS_DIR / "hdri"

# Map types we want to download (with fallback names)
# Format: (preferred_name, fallback_names...)
MAP_TYPES = {
    "diffuse": ["Diffuse", "diffuse", "diff"],
    "normal": ["nor_gl"],  # OpenGL normal map
    "roughness": ["Rough", "rough"],
    "ao": ["AO", "ao"],
    "displacement": ["Displacement", "disp"]
}

# Colors for terminal output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'  # No Color

# Counters
stats = {
    "total": 0,
    "success": 0,
    "skipped": 0,
    "failed": 0
}

# =============================================================================
# TEXTURE DEFINITIONS
# =============================================================================

# Biome textures from the asset integration plan
BIOME_TEXTURES = {
    # Enchanted Forest
    "enchanted_forest_primary": "forest_leaves_02",
    "enchanted_forest_secondary": "brown_mud_leaves_01",
    "enchanted_forest_prop1": "bark_brown_01",
    "enchanted_forest_prop2": "bark_willow",
    "enchanted_forest_prop3": "coast_sand_rocks_02",
    
    # Frozen Peaks
    "frozen_peaks_primary": "snow_02",
    "frozen_peaks_secondary": "aerial_rocks_02",
    "frozen_peaks_prop1": "cliff_side",
    # Note: snow_field is an HDRI, not a texture - skipping
    "frozen_peaks_prop3": "asphalt_snow",
    
    # Desolate Wastes
    "desolate_wastes_primary": "aerial_beach_01",
    "desolate_wastes_secondary": "dry_ground_01",
    "desolate_wastes_prop1": "dry_ground_rocks",
    "desolate_wastes_prop2": "cracked_red_ground",
    "desolate_wastes_prop3": "coast_sand_05",
    
    # Golden Plains
    "golden_plains_primary": "grass_meadow",
    "golden_plains_secondary": "grass_path_1",
    "golden_plains_prop1": "forrest_ground_01",
    "golden_plains_prop2": "ground_grass_gen_01",
    
    # Ashlands
    "ashlands_primary": "burned_ground_01",
    "ashlands_secondary": "aerial_rocks_04",
    "ashlands_prop1": "cracked_concrete",
    "ashlands_prop2": "bitumen",
    "ashlands_prop3": "rock_boulder_dry",
    
    # Highlands (shares grass_meadow with Golden Plains)
    "highlands_primary": "grass_meadow",  # Will be skipped if already downloaded
    "highlands_secondary": "coast_sand_rocks_02",  # Already in enchanted_forest
    "highlands_prop1": "aerial_grass_rock",
    "highlands_prop2": "aerial_rocks_01",
    "highlands_prop3": "brown_mud_rocks_01",
    
    # Swamplands
    "swamplands_primary": "brown_mud_02",
    "swamplands_secondary": "brown_mud_03",
    "swamplands_prop1": "concrete_moss",
    "swamplands_prop2": "aerial_mud_1",
    "swamplands_prop3": "cobblestone_floor_04",
}

# Board textures
BOARD_TEXTURES = {
    "table_wood": "dark_wood",
    "table_wood_alt1": "brown_planks_03",
    "table_wood_alt2": "dark_wooden_planks",
    "frame_stone": "castle_brick_01",
    "frame_stone_alt1": "castle_wall_slates",
    "frame_stone_alt2": "defense_wall",
    "frame_metal": "corrugated_iron",
    "frame_metal_alt": "blue_metal_plate",
}

# UI textures (may overlap with board)
UI_TEXTURES = {
    "ui_wood": "dark_wood",
    "ui_stone": "castle_brick_01", 
    "ui_metal": "corrugated_iron",
}

# HDRI
HDRI_NAME = "evening_road_01"

# =============================================================================
# FUNCTIONS
# =============================================================================

def print_header():
    print(f"{Colors.BLUE}")
    print("=" * 77)
    print(" Poly Haven Texture Downloader")
    print(" Fantasy World Board Game - Asset Integration")
    print("=" * 77)
    print(f"{Colors.NC}")
    print(f"Resolution: {RESOLUTION}")
    print(f"Format: {FORMAT}")
    print(f"Target: {TEXTURES_DIR}")
    print()


def create_directories():
    """Create the output directory structure."""
    print(f"{Colors.YELLOW}Creating directory structure...{Colors.NC}")
    (TEXTURES_DIR / "biomes").mkdir(parents=True, exist_ok=True)
    (TEXTURES_DIR / "board").mkdir(parents=True, exist_ok=True)
    (TEXTURES_DIR / "ui").mkdir(parents=True, exist_ok=True)
    HDRI_DIR.mkdir(parents=True, exist_ok=True)
    print(f"{Colors.GREEN}✓ Directories created{Colors.NC}\n")


def fetch_asset_info(asset_name: str) -> Optional[Dict]:
    """Fetch asset information from the Poly Haven API."""
    url = f"{API_BASE}/{asset_name}"
    request = urllib.request.Request(url)
    request.add_header('User-Agent', USER_AGENT)
    
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.loads(response.read().decode())
    except urllib.error.HTTPError as e:
        if e.code == 404:
            print(f"  {Colors.RED}✗ Asset not found on Poly Haven: {asset_name}{Colors.NC}")
        else:
            print(f"  {Colors.RED}✗ HTTP Error {e.code} for {asset_name}{Colors.NC}")
        return None
    except Exception as e:
        print(f"  {Colors.RED}✗ Error fetching {asset_name}: {e}{Colors.NC}")
        return None


def find_map_url(asset_data: Dict, map_type: str) -> Optional[Tuple[str, str]]:
    """Find the download URL for a specific map type."""
    # Try each possible key for this map type
    possible_keys = MAP_TYPES.get(map_type, [map_type])
    
    for key in possible_keys:
        if key in asset_data:
            map_data = asset_data[key]
            # Try to get the resolution we want
            if RESOLUTION in map_data:
                res_data = map_data[RESOLUTION]
                if FORMAT in res_data:
                    return res_data[FORMAT].get("url"), key
    
    return None, None


def download_file(url: str, output_path: Path) -> bool:
    """Download a file from URL to the specified path."""
    request = urllib.request.Request(url)
    request.add_header('User-Agent', USER_AGENT)
    
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            with open(output_path, 'wb') as f:
                # Download in chunks
                while True:
                    chunk = response.read(8192)
                    if not chunk:
                        break
                    f.write(chunk)
        return True
    except Exception as e:
        print(f"  {Colors.RED}✗ Download failed: {e}{Colors.NC}")
        # Clean up partial file
        if output_path.exists():
            output_path.unlink()
        return False


def download_texture_set(asset_name: str, output_dir: Path, output_prefix: str) -> bool:
    """Download all maps for a single texture asset."""
    print(f"{Colors.GREEN}Downloading texture set:{Colors.NC} {asset_name} → {output_prefix}")
    
    # Fetch asset info from API
    asset_data = fetch_asset_info(asset_name)
    if not asset_data:
        stats["failed"] += len(MAP_TYPES)
        stats["total"] += len(MAP_TYPES)
        return False
    
    success = True
    for map_type in MAP_TYPES.keys():
        stats["total"] += 1
        
        # Determine output filename
        output_file = output_dir / f"{output_prefix}_{map_type}.{FORMAT}"
        
        # Check if already exists
        if output_file.exists():
            print(f"  {Colors.YELLOW}⊘ Skipping{Colors.NC} {output_file.name} (already exists)")
            stats["skipped"] += 1
            continue
        
        # Find the URL for this map type
        url, found_key = find_map_url(asset_data, map_type)
        
        if not url:
            print(f"  {Colors.YELLOW}⊘ Skipping{Colors.NC} {output_file.name} (not available)")
            stats["skipped"] += 1
            continue
        
        # Download the file
        print(f"  {Colors.BLUE}↓ Downloading{Colors.NC} {output_file.name}...")
        
        if download_file(url, output_file):
            size_mb = output_file.stat().st_size / (1024 * 1024)
            print(f"  {Colors.GREEN}✓ Downloaded{Colors.NC} {output_file.name} ({size_mb:.1f} MB)")
            stats["success"] += 1
        else:
            stats["failed"] += 1
            success = False
    
    print()
    return success


def download_hdri(hdri_name: str, output_dir: Path) -> bool:
    """Download an HDRI file."""
    print(f"{Colors.GREEN}Downloading HDRI:{Colors.NC} {hdri_name}")
    
    stats["total"] += 1
    
    output_file = output_dir / f"{hdri_name}_{RESOLUTION}.exr"
    
    if output_file.exists():
        print(f"  {Colors.YELLOW}⊘ Skipping{Colors.NC} {output_file.name} (already exists)")
        stats["skipped"] += 1
        return True
    
    # Fetch HDRI info
    asset_data = fetch_asset_info(hdri_name)
    if not asset_data:
        stats["failed"] += 1
        return False
    
    # HDRIs have a different structure
    if "hdri" in asset_data:
        hdri_data = asset_data["hdri"]
        if RESOLUTION in hdri_data and "exr" in hdri_data[RESOLUTION]:
            url = hdri_data[RESOLUTION]["exr"].get("url")
            
            print(f"  {Colors.BLUE}↓ Downloading{Colors.NC} {output_file.name}...")
            
            if url and download_file(url, output_file):
                size_mb = output_file.stat().st_size / (1024 * 1024)
                print(f"  {Colors.GREEN}✓ Downloaded{Colors.NC} {output_file.name} ({size_mb:.1f} MB)")
                stats["success"] += 1
                return True
    
    print(f"  {Colors.RED}✗ HDRI not found at {RESOLUTION} resolution{Colors.NC}")
    stats["failed"] += 1
    return False


def print_section_header(title: str):
    print(f"{Colors.BLUE}{'━' * 77}{Colors.NC}")
    print(f"{Colors.BLUE}{title}{Colors.NC}")
    print(f"{Colors.BLUE}{'━' * 77}{Colors.NC}\n")


def print_summary():
    print(f"{Colors.BLUE}")
    print("=" * 77)
    print(" Download Summary")
    print("=" * 77)
    print(f"{Colors.NC}")
    print(f"Total files:     {stats['total']}")
    print(f"{Colors.GREEN}Successful:      {stats['success']}{Colors.NC}")
    print(f"{Colors.YELLOW}Skipped:         {stats['skipped']}{Colors.NC}")
    print(f"{Colors.RED}Failed:          {stats['failed']}{Colors.NC}")
    print()
    
    if stats["failed"] > 0:
        print(f"{Colors.RED}Some downloads failed. These textures may not be available on Poly Haven.{Colors.NC}")
        print(f"{Colors.YELLOW}Check the asset_integration_master_plan.md for alternative sources.{Colors.NC}")


def main():
    print_header()
    create_directories()
    
    # Track downloaded assets to avoid duplicates
    downloaded_assets = set()
    
    # Download Biome Textures
    print_section_header("BIOME TEXTURES")
    
    for key, asset_name in BIOME_TEXTURES.items():
        if asset_name in downloaded_assets:
            print(f"{Colors.CYAN}Skipping duplicate:{Colors.NC} {asset_name} (already downloaded for another biome)\n")
            continue
        
        download_texture_set(asset_name, TEXTURES_DIR / "biomes", key)
        downloaded_assets.add(asset_name)
    
    # Download Board Textures
    print_section_header("BOARD TEXTURES")
    
    # Reset tracking for board (we want separate copies with different names)
    for key, asset_name in BOARD_TEXTURES.items():
        download_texture_set(asset_name, TEXTURES_DIR / "board", key)
    
    # Download UI Textures
    print_section_header("UI TEXTURES")
    
    for key, asset_name in UI_TEXTURES.items():
        download_texture_set(asset_name, TEXTURES_DIR / "ui", key)
    
    # Download HDRI
    print_section_header("HDRI ENVIRONMENT")
    download_hdri(HDRI_NAME, HDRI_DIR)
    
    print()
    print_summary()
    
    # Return exit code based on failures
    return 1 if stats["failed"] > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
