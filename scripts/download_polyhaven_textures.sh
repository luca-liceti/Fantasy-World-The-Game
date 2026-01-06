#!/bin/bash
# =============================================================================
# Poly Haven Texture Downloader for Fantasy World Board Game
# =============================================================================
# Downloads 4K PNG textures from Poly Haven API
# Maps: Diffuse (Albedo), Normal (OpenGL), Roughness, AO, Displacement
# =============================================================================

set -e

# Configuration
RESOLUTION="4k"
FORMAT="png"
USER_AGENT="FantasyWorldBoardGame/1.0 (github.com/luca-liceti)"
API_BASE="https://api.polyhaven.com/files"
DL_BASE="https://dl.polyhaven.org/file/ph-assets"

# Base directories
PROJECT_DIR="/home/luca/Documents/Github Projects/Fantasy World The Video Game 12-20-2025"
ASSETS_DIR="$PROJECT_DIR/fantasy-world-game/assets"
TEXTURES_DIR="$ASSETS_DIR/textures"
HDRI_DIR="$ASSETS_DIR/hdri"

# Map types to download (Poly Haven naming convention)
# Diffuse = Albedo, nor_gl = Normal OpenGL, Rough = Roughness, AO = Ambient Occlusion, Displacement = Height
declare -a MAP_TYPES=("diffuse" "nor_gl" "rough" "ao" "disp")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_DOWNLOADS=0
SUCCESSFUL_DOWNLOADS=0
FAILED_DOWNLOADS=0
SKIPPED_DOWNLOADS=0

# =============================================================================
# TEXTURE DEFINITIONS
# =============================================================================

# Biome textures - Primary and Secondary for each biome
declare -A BIOME_TEXTURES=(
    # Enchanted Forest
    ["enchanted_forest_primary"]="forest_leaves_02"
    ["enchanted_forest_secondary"]="brown_mud_leaves_01"
    ["enchanted_forest_prop1"]="bark_brown_01"
    ["enchanted_forest_prop2"]="bark_willow"
    ["enchanted_forest_prop3"]="coast_sand_rocks_02"
    
    # Frozen Peaks
    ["frozen_peaks_primary"]="snow_02"
    ["frozen_peaks_secondary"]="aerial_rocks_02"
    ["frozen_peaks_prop1"]="cliff_side"
    ["frozen_peaks_prop2"]="snow_field"
    ["frozen_peaks_prop3"]="asphalt_snow"
    
    # Desolate Wastes
    ["desolate_wastes_primary"]="aerial_beach_01"
    ["desolate_wastes_secondary"]="dry_ground_01"
    ["desolate_wastes_prop1"]="dry_ground_rocks"
    ["desolate_wastes_prop2"]="cracked_red_ground"
    ["desolate_wastes_prop3"]="coast_sand_05"
    
    # Golden Plains
    ["golden_plains_primary"]="grass_meadow"
    ["golden_plains_secondary"]="grass_path_1"
    ["golden_plains_prop1"]="forrest_ground_01"
    ["golden_plains_prop2"]="ground_grass_gen_01"
    
    # Ashlands
    ["ashlands_primary"]="burned_ground_01"
    ["ashlands_secondary"]="aerial_rocks_04"
    ["ashlands_prop1"]="cracked_concrete"
    ["ashlands_prop2"]="bitumen"
    ["ashlands_prop3"]="rock_boulder_dry"
    
    # Highlands
    ["highlands_primary"]="grass_meadow"
    ["highlands_secondary"]="coast_sand_rocks_02"
    ["highlands_prop1"]="aerial_grass_rock"
    ["highlands_prop2"]="aerial_rocks_01"
    ["highlands_prop3"]="brown_mud_rocks_01"
    
    # Swamplands
    ["swamplands_primary"]="brown_mud_02"
    ["swamplands_secondary"]="brown_mud_03"
    ["swamplands_prop1"]="concrete_moss"
    ["swamplands_prop2"]="aerial_mud_1"
    ["swamplands_prop3"]="cobblestone_floor_04"
)

# Board textures
declare -A BOARD_TEXTURES=(
    ["table_wood"]="dark_wood"
    ["table_wood_alt1"]="brown_planks_03"
    ["table_wood_alt2"]="dark_wooden_planks"
    ["frame_stone"]="castle_brick_01"
    ["frame_stone_alt1"]="castle_wall_slates"
    ["frame_stone_alt2"]="defense_wall"
    ["frame_metal"]="corrugated_iron"
    ["frame_metal_alt"]="blue_metal_plate"
)

# UI textures
declare -A UI_TEXTURES=(
    ["ui_wood"]="dark_wood"
    ["ui_stone"]="castle_brick_01"
    ["ui_metal"]="corrugated_iron"
)

# HDRI (different download pattern)
HDRI_NAME="evening_road_01"

# =============================================================================
# FUNCTIONS
# =============================================================================

print_header() {
    echo -e "${BLUE}"
    echo "============================================================================="
    echo " Poly Haven Texture Downloader"
    echo " Fantasy World Board Game - Asset Integration"
    echo "============================================================================="
    echo -e "${NC}"
    echo "Resolution: ${RESOLUTION}"
    echo "Format: ${FORMAT}"
    echo "Target: ${TEXTURES_DIR}"
    echo ""
}

create_directories() {
    echo -e "${YELLOW}Creating directory structure...${NC}"
    mkdir -p "$TEXTURES_DIR/biomes"
    mkdir -p "$TEXTURES_DIR/board"
    mkdir -p "$TEXTURES_DIR/ui"
    mkdir -p "$HDRI_DIR"
    echo -e "${GREEN}✓ Directories created${NC}"
    echo ""
}

# Download a single texture file
# Args: $1=asset_name, $2=map_type, $3=output_dir, $4=output_prefix
download_texture() {
    local asset_name="$1"
    local map_type="$2"
    local output_dir="$3"
    local output_prefix="$4"
    
    # Construct URL based on Poly Haven pattern
    local url="${DL_BASE}/Textures/${FORMAT}/${RESOLUTION}/${asset_name}/${asset_name}_${map_type}_${RESOLUTION}.${FORMAT}"
    local output_file="${output_dir}/${output_prefix}_${map_type}.${FORMAT}"
    
    ((TOTAL_DOWNLOADS++))
    
    # Check if file already exists
    if [[ -f "$output_file" ]]; then
        echo -e "  ${YELLOW}⊘ Skipping${NC} ${output_prefix}_${map_type}.${FORMAT} (already exists)"
        ((SKIPPED_DOWNLOADS++))
        return 0
    fi
    
    # Download with curl
    echo -e "  ${BLUE}↓ Downloading${NC} ${output_prefix}_${map_type}.${FORMAT}..."
    
    if curl -s -f -L \
        -H "User-Agent: ${USER_AGENT}" \
        -o "$output_file" \
        "$url" 2>/dev/null; then
        echo -e "  ${GREEN}✓ Downloaded${NC} ${output_prefix}_${map_type}.${FORMAT}"
        ((SUCCESSFUL_DOWNLOADS++))
        return 0
    else
        echo -e "  ${RED}✗ Failed${NC} ${output_prefix}_${map_type}.${FORMAT}"
        ((FAILED_DOWNLOADS++))
        # Remove partial file if it exists
        rm -f "$output_file"
        return 1
    fi
}

# Download all maps for a texture
# Args: $1=asset_name, $2=output_dir, $3=output_prefix
download_texture_set() {
    local asset_name="$1"
    local output_dir="$2"
    local output_prefix="$3"
    
    echo -e "${GREEN}Downloading texture set:${NC} ${asset_name} → ${output_prefix}"
    
    for map_type in "${MAP_TYPES[@]}"; do
        download_texture "$asset_name" "$map_type" "$output_dir" "$output_prefix"
    done
    
    echo ""
}

# Download HDRI (EXR format for HDRIs)
download_hdri() {
    local hdri_name="$1"
    local output_dir="$2"
    
    echo -e "${GREEN}Downloading HDRI:${NC} ${hdri_name}"
    
    local url="${DL_BASE}/HDRIs/exr/${RESOLUTION}/${hdri_name}_${RESOLUTION}.exr"
    local output_file="${output_dir}/${hdri_name}_${RESOLUTION}.exr"
    
    ((TOTAL_DOWNLOADS++))
    
    if [[ -f "$output_file" ]]; then
        echo -e "  ${YELLOW}⊘ Skipping${NC} ${hdri_name}_${RESOLUTION}.exr (already exists)"
        ((SKIPPED_DOWNLOADS++))
        return 0
    fi
    
    echo -e "  ${BLUE}↓ Downloading${NC} ${hdri_name}_${RESOLUTION}.exr..."
    
    if curl -s -f -L \
        -H "User-Agent: ${USER_AGENT}" \
        -o "$output_file" \
        "$url" 2>/dev/null; then
        echo -e "  ${GREEN}✓ Downloaded${NC} ${hdri_name}_${RESOLUTION}.exr"
        ((SUCCESSFUL_DOWNLOADS++))
        return 0
    else
        echo -e "  ${RED}✗ Failed${NC} ${hdri_name}_${RESOLUTION}.exr"
        ((FAILED_DOWNLOADS++))
        rm -f "$output_file"
        return 1
    fi
    
    echo ""
}

print_summary() {
    echo -e "${BLUE}"
    echo "============================================================================="
    echo " Download Summary"
    echo "============================================================================="
    echo -e "${NC}"
    echo -e "Total files:     ${TOTAL_DOWNLOADS}"
    echo -e "${GREEN}Successful:      ${SUCCESSFUL_DOWNLOADS}${NC}"
    echo -e "${YELLOW}Skipped:         ${SKIPPED_DOWNLOADS}${NC}"
    echo -e "${RED}Failed:          ${FAILED_DOWNLOADS}${NC}"
    echo ""
    
    if [[ $FAILED_DOWNLOADS -gt 0 ]]; then
        echo -e "${RED}Some downloads failed. These textures may not be available on Poly Haven.${NC}"
        echo -e "${YELLOW}Check the asset_integration_master_plan.md for alternative sources.${NC}"
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    print_header
    create_directories
    
    # Download Biome Textures
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}BIOME TEXTURES${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    for key in "${!BIOME_TEXTURES[@]}"; do
        asset_name="${BIOME_TEXTURES[$key]}"
        download_texture_set "$asset_name" "$TEXTURES_DIR/biomes" "$key"
    done
    
    # Download Board Textures
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}BOARD TEXTURES${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    for key in "${!BOARD_TEXTURES[@]}"; do
        asset_name="${BOARD_TEXTURES[$key]}"
        download_texture_set "$asset_name" "$TEXTURES_DIR/board" "$key"
    done
    
    # Download UI Textures
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}UI TEXTURES${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    for key in "${!UI_TEXTURES[@]}"; do
        asset_name="${UI_TEXTURES[$key]}"
        download_texture_set "$asset_name" "$TEXTURES_DIR/ui" "$key"
    done
    
    # Download HDRI
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}HDRI ENVIRONMENT${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    download_hdri "$HDRI_NAME" "$HDRI_DIR"
    
    echo ""
    print_summary
}

# Run main function
main "$@"
