#!/usr/bin/env python3
"""
Download Missing Grass Textures for Golden Plains Biome
Downloads from Poly Haven and AmbientCG to fill gaps in the original download.
"""

import json
import os
import sys
import urllib.request
import urllib.error
import zipfile
import shutil
from pathlib import Path
from typing import Optional, Dict

# Configuration
RESOLUTION = "4k"
FORMAT = "png"
USER_AGENT = "FantasyWorldBoardGame/1.0 (github.com/luca-liceti)"

# Paths
PROJECT_DIR = Path("/home/luca/Documents/Github Projects/Fantasy World The Video Game 12-20-2025")
TEXTURES_DIR = PROJECT_DIR / "fantasy-world-game" / "assets" / "textures" / "biomes"
TEMP_DIR = PROJECT_DIR / "temp_downloads"

# Colors for terminal output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'

# Map types we want
MAP_TYPES = {
    "diffuse": ["Diffuse", "diff"],
    "normal": ["nor_gl"],
    "roughness": ["Rough", "rough"],
    "ao": ["AO", "ao"],
    "displacement": ["Displacement", "disp"]
}

# Counters
stats = {"total": 0, "success": 0, "skipped": 0, "failed": 0}

def print_header():
    print(f"{Colors.BLUE}")
    print("=" * 70)
    print(" Missing Grass Texture Downloader")
    print(" Fantasy World Board Game - Golden Plains Biome")
    print("=" * 70)
    print(f"{Colors.NC}")

def fetch_polyhaven_asset(asset_name: str) -> Optional[Dict]:
    """Fetch asset info from Poly Haven API."""
    url = f"https://api.polyhaven.com/files/{asset_name}"
    request = urllib.request.Request(url)
    request.add_header('User-Agent', USER_AGENT)
    
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.loads(response.read().decode())
    except Exception as e:
        print(f"  {Colors.RED}✗ Error fetching {asset_name}: {e}{Colors.NC}")
        return None

def find_map_url(asset_data: Dict, map_type: str) -> Optional[str]:
    """Find download URL for a map type."""
    possible_keys = MAP_TYPES.get(map_type, [map_type])
    
    for key in possible_keys:
        if key in asset_data:
            map_data = asset_data[key]
            if RESOLUTION in map_data and FORMAT in map_data[RESOLUTION]:
                return map_data[RESOLUTION][FORMAT].get("url")
    return None

def download_file(url: str, output_path: Path) -> bool:
    """Download a file from URL."""
    request = urllib.request.Request(url)
    request.add_header('User-Agent', USER_AGENT)
    
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            with open(output_path, 'wb') as f:
                while True:
                    chunk = response.read(8192)
                    if not chunk:
                        break
                    f.write(chunk)
        return True
    except Exception as e:
        print(f"  {Colors.RED}✗ Download failed: {e}{Colors.NC}")
        if output_path.exists():
            output_path.unlink()
        return False

def download_polyhaven_texture(asset_name: str, output_prefix: str):
    """Download a Poly Haven texture set."""
    print(f"{Colors.GREEN}Downloading from Poly Haven:{Colors.NC} {asset_name} → {output_prefix}")
    
    asset_data = fetch_polyhaven_asset(asset_name)
    if not asset_data:
        stats["failed"] += len(MAP_TYPES)
        stats["total"] += len(MAP_TYPES)
        return
    
    for map_type in MAP_TYPES.keys():
        stats["total"] += 1
        output_file = TEXTURES_DIR / f"{output_prefix}_{map_type}.{FORMAT}"
        
        if output_file.exists():
            print(f"  {Colors.YELLOW}⊘ Skipping{Colors.NC} {output_file.name} (already exists)")
            stats["skipped"] += 1
            continue
        
        url = find_map_url(asset_data, map_type)
        if not url:
            print(f"  {Colors.YELLOW}⊘ Skipping{Colors.NC} {output_file.name} (not available)")
            stats["skipped"] += 1
            continue
        
        print(f"  {Colors.BLUE}↓ Downloading{Colors.NC} {output_file.name}...")
        
        if download_file(url, output_file):
            size_mb = output_file.stat().st_size / (1024 * 1024)
            print(f"  {Colors.GREEN}✓ Downloaded{Colors.NC} {output_file.name} ({size_mb:.1f} MB)")
            stats["success"] += 1
        else:
            stats["failed"] += 1
    
    print()

def download_ambientcg_texture(asset_id: str, output_prefix: str):
    """Download a texture from AmbientCG (requires ZIP extraction)."""
    print(f"{Colors.GREEN}Downloading from AmbientCG:{Colors.NC} {asset_id} → {output_prefix}")
    
    # AmbientCG direct download URL for 4K PNG
    zip_url = f"https://ambientcg.com/get?file={asset_id}_4K-PNG.zip"
    zip_path = TEMP_DIR / f"{asset_id}_4K-PNG.zip"
    
    TEMP_DIR.mkdir(parents=True, exist_ok=True)
    
    print(f"  {Colors.BLUE}↓ Downloading ZIP archive{Colors.NC}...")
    
    request = urllib.request.Request(zip_url)
    request.add_header('User-Agent', USER_AGENT)
    
    try:
        with urllib.request.urlopen(request, timeout=300) as response:
            with open(zip_path, 'wb') as f:
                while True:
                    chunk = response.read(8192)
                    if not chunk:
                        break
                    f.write(chunk)
    except Exception as e:
        print(f"  {Colors.RED}✗ Download failed: {e}{Colors.NC}")
        stats["failed"] += 5  # Assume 5 maps
        stats["total"] += 5
        return
    
    # Extract and rename files
    print(f"  {Colors.BLUE}↓ Extracting and organizing files{Colors.NC}...")
    
    try:
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            extract_dir = TEMP_DIR / asset_id
            zip_ref.extractall(extract_dir)
            
            # AmbientCG naming convention: AssetID_Color.png, AssetID_NormalGL.png, etc.
            file_mappings = {
                "Color": "diffuse",
                "NormalGL": "normal",
                "Roughness": "roughness",
                "AmbientOcclusion": "ao",
                "Displacement": "displacement"
            }
            
            for acg_name, our_name in file_mappings.items():
                stats["total"] += 1
                
                # Find the source file (may have resolution suffix)
                source_file = None
                for f in extract_dir.iterdir():
                    if acg_name in f.name and f.suffix.lower() == '.png':
                        source_file = f
                        break
                
                if not source_file:
                    print(f"  {Colors.YELLOW}⊘ Skipping{Colors.NC} {output_prefix}_{our_name}.png (not in archive)")
                    stats["skipped"] += 1
                    continue
                
                dest_file = TEXTURES_DIR / f"{output_prefix}_{our_name}.png"
                
                if dest_file.exists():
                    print(f"  {Colors.YELLOW}⊘ Skipping{Colors.NC} {dest_file.name} (already exists)")
                    stats["skipped"] += 1
                    continue
                
                shutil.copy2(source_file, dest_file)
                size_mb = dest_file.stat().st_size / (1024 * 1024)
                print(f"  {Colors.GREEN}✓ Extracted{Colors.NC} {dest_file.name} ({size_mb:.1f} MB)")
                stats["success"] += 1
            
            # Cleanup extracted folder
            shutil.rmtree(extract_dir)
    
    except Exception as e:
        print(f"  {Colors.RED}✗ Extraction failed: {e}{Colors.NC}")
        stats["failed"] += 5
    
    # Cleanup ZIP
    if zip_path.exists():
        zip_path.unlink()
    
    print()

def print_summary():
    print(f"{Colors.BLUE}")
    print("=" * 70)
    print(" Download Summary")
    print("=" * 70)
    print(f"{Colors.NC}")
    print(f"Total files:     {stats['total']}")
    print(f"{Colors.GREEN}Successful:      {stats['success']}{Colors.NC}")
    print(f"{Colors.YELLOW}Skipped:         {stats['skipped']}{Colors.NC}")
    print(f"{Colors.RED}Failed:          {stats['failed']}{Colors.NC}")

def main():
    print_header()
    
    print(f"{Colors.CYAN}These textures will complete the Golden Plains biome:{Colors.NC}")
    print("""
    1. grass_path_2 (Poly Haven) - Primary: Dirt path with grass tufts
    2. rocky_terrain_02 (Poly Haven) - Secondary: Grassy terrain with rocks  
    3. Grass004 (AmbientCG) - Alt primary: Pure green grass
    4. Ground037 (AmbientCG) - Props: Forest grass with moss
    
    These textures match the "Manor Lords" aesthetic - grounded, realistic
    medieval terrain rather than stylized bright grass.
    """)
    
    # Download from Poly Haven
    print(f"\n{Colors.BLUE}━━━ POLY HAVEN TEXTURES ━━━{Colors.NC}\n")
    
    # grass_path_2 - Good for golden plains primary (worn dirt paths with grass)
    download_polyhaven_texture("grass_path_2", "golden_plains_primary")
    
    # rocky_terrain_02 - Excellent for secondary (grass with rocks - very Manor Lords)
    download_polyhaven_texture("rocky_terrain_02", "golden_plains_secondary")
    
    # Download from AmbientCG
    print(f"\n{Colors.BLUE}━━━ AMBIENTCG TEXTURES ━━━{Colors.NC}\n")
    
    # Grass004 - Pure grass for alternate primary
    download_ambientcg_texture("Grass004", "golden_plains_alt_primary")
    
    # Ground037 - Forest grass/moss for props
    download_ambientcg_texture("Ground037", "golden_plains_prop2")
    
    # Cleanup temp directory
    if TEMP_DIR.exists():
        shutil.rmtree(TEMP_DIR)
    
    print()
    print_summary()
    
    if stats["failed"] > 0:
        return 1
    return 0

if __name__ == "__main__":
    sys.exit(main())
