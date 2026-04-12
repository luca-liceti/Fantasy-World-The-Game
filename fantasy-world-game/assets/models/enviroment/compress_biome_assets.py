"""
Fantasy World — Biome Asset Compressor
=======================================
Compresses all .gltf assets in any biome folder.
Works for forest, ashlands, swamp, plains — any biome decoration pack.

Usage:
    # Compress everything in the current folder:
    python compress_biome_assets.py

    # Skip specific files (e.g. assets your game already handles another way):
    python compress_biome_assets.py --skip grass_medium_01_2k.gltf rocky_trail_2k.gltf

    # Preview what would run without doing anything:
    python compress_biome_assets.py --dry-run

    # Compress only specific files:
    python compress_biome_assets.py --only pine_tree_01_2k.gltf fir_tree_01_2k.gltf

Requirements:
    npm install -g @gltf-transform/cli

Place this script anywhere — it compresses .gltf files in the same folder as itself.

Output:
    <same folder>/compressed/
"""

import subprocess
import sys
import shutil
import argparse
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
OUTPUT_DIR = SCRIPT_DIR / "compressed"

# ── Compression settings ──────────────────────────────────────────────────────
TEXTURE_SIZE   = 1024    # Max texture dimension in px (1K is plenty at board scale)
TEXTURE_FORMAT = "webp"  # Smallest format, Godot 4 supports it

# ─────────────────────────────────────────────────────────────────────────────

def find_gltf_transform():
    path = shutil.which("gltf-transform")
    if not path:
        print("ERROR: gltf-transform not found.")
        print("Install with:  npm install -g @gltf-transform/cli")
        sys.exit(1)
    return path


def compress_asset(gltf_path, gltf_transform, dry_run=False):
    stem   = gltf_path.stem.replace("_2k", "").replace("_1k", "").replace("_4k", "")
    output = OUTPUT_DIR / f"{stem}.glb"

    # Source size = .gltf JSON + .bin geometry buffer combined
    bin_path = SCRIPT_DIR / (stem + ".bin")
    src_size = gltf_path.stat().st_size + (bin_path.stat().st_size if bin_path.exists() else 0)

    print(f"\n{'─'*58}")
    print(f"  {gltf_path.name}  ({src_size / 1024 / 1024:.1f} MB)")

    if dry_run:
        print(f"  [DRY RUN] Would compress -> {output.name}")
        return src_size, 0, True

    # Remove stale output if it exists from a previous run
    if output.exists():
        output.unlink()

    cmd = [
        "node", "--max-old-space-size=8192", gltf_transform,
        "optimize", str(gltf_path), str(output),
        "--compress", "draco",
        "--texture-compress", TEXTURE_FORMAT,
        "--texture-size", str(TEXTURE_SIZE),
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)
    output_text = (result.stdout + result.stderr).strip()

    if result.returncode != 0:
        # Print full output on failure so the actual error is visible
        print("  FAILED:")
        for line in output_text.splitlines():
            print(f"    {line}")
        return src_size, 0, False
    else:
        # On success only print the final summary line, skip step-by-step noise
        for line in output_text.splitlines():
            if line.strip().startswith("info:"):
                print(f"  {line.strip()}")
        after = output.stat().st_size if output.exists() else 0
        reduction = (1 - after / src_size) * 100 if src_size > 0 else 0
        print(f"  DONE!  {src_size/1024/1024:.1f} MB  ->  {after/1024/1024:.2f} MB  (-{reduction:.0f}%)")
        return src_size, after, True


def main():
    parser = argparse.ArgumentParser(description="Compress biome .gltf assets for Godot 4")
    parser.add_argument("--skip", nargs="+", metavar="FILE",
                        help="Filenames to skip (e.g. --skip grass_medium_01_2k.gltf)")
    parser.add_argument("--only", nargs="+", metavar="FILE",
                        help="Only compress these files (e.g. --only pine_tree_01_2k.gltf)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Show what would be compressed without doing anything")
    args = parser.parse_args()

    skip_set = set(args.skip) if args.skip else set()
    only_set = set(args.only) if args.only else set()

    print("\n" + "="*58)
    print("  FANTASY WORLD — Biome Asset Compressor")
    print("="*58)
    print(f"  Folder       : {SCRIPT_DIR.name}/")
    print(f"  Texture size : {TEXTURE_SIZE}px ({TEXTURE_FORMAT})")
    print(f"  Output dir   : compressed/")
    if args.dry_run:
        print(f"  Mode         : DRY RUN (no files will be written)")

    gltf_transform = find_gltf_transform()
    print(f"  gltf-transform: found\n")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # Find all gltf files, exclude _simplified temp files from previous runs
    all_gltf   = sorted(SCRIPT_DIR.glob("*.gltf"))
    gltf_files = [f for f in all_gltf if "_simplified" not in f.stem]

    if not gltf_files:
        print("No .gltf files found in this folder.")
        return

    # Apply --only filter
    if only_set:
        to_process = [f for f in gltf_files if f.name in only_set]
        skipped    = [f for f in gltf_files if f.name not in only_set]
    else:
        to_process = [f for f in gltf_files if f.name not in skip_set]
        skipped    = [f for f in gltf_files if f.name in skip_set]

    ignored = len(all_gltf) - len(gltf_files)
    print(f"  Found      : {len(gltf_files)} .gltf file(s)"
          + (f"  ({ignored} _simplified temp files ignored)" if ignored else ""))
    print(f"  Processing : {len(to_process)}")
    if skipped:
        print(f"  Skipping   : {len(skipped)}  ({', '.join(f.name for f in skipped)})")

    results = []
    for gltf_path in to_process:
        before, after, ok = compress_asset(gltf_path, gltf_transform, args.dry_run)
        stem = gltf_path.stem.replace("_2k", "").replace("_1k", "").replace("_4k", "")
        results.append((stem, before, after, ok))

    if args.dry_run:
        print(f"\n  Dry run complete — nothing was written.")
        return

    # Summary
    print(f"\n{'='*58}")
    print("  RESULTS SUMMARY")
    print(f"{'='*58}")
    total_before = total_after = 0
    for name, before, after, ok in results:
        total_before += before
        total_after  += after
        reduction = (1 - after / before) * 100 if before > 0 else 0
        status = "OK  " if ok else "FAIL"
        print(f"  [{status}] {name:35s} "
              f"{before/1024/1024:7.1f} MB -> {after/1024/1024:6.2f} MB  "
              f"(-{reduction:.0f}%)")

    if total_before > 0:
        total_reduction = (1 - total_after / total_before) * 100
        print(f"{'─'*58}")
        print(f"  {'TOTAL':35s} "
              f"{total_before/1024/1024:7.1f} MB -> {total_after/1024/1024:6.2f} MB  "
              f"(-{total_reduction:.0f}%)")

    failed = [name for name, _, _, ok in results if not ok]
    if failed:
        print(f"\n  Still failing: {', '.join(failed)}")
        print("  Try running manually with:")
        for name in failed:
            print(f"    node --max-old-space-size=8192 $(which gltf-transform) "
                  f"optimize {name}_2k.gltf compressed/{name}.glb "
                  f"--compress draco --texture-compress webp --texture-size 1024")

    print("""
  NEXT STEPS IN GODOT:
  ─────────────────────────────────────────────────────
  1. Drop compressed/ into the biome's asset folder in res://
  2. Select each .glb in the FileSystem panel -> Import tab
  3. Meshes -> Generate LODs: ON
  4. Textures -> Compress: VRAM Compressed
  5. Hit Reimport on each file
  6. Use MultiMeshInstance3D to scatter on biome hexes
""")


if __name__ == "__main__":
    main()
