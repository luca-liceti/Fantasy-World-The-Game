#!/bin/bash

# optimize_audio.sh
# Finds all .mp3 and .wav files in the current directory and subdirectories
# Converts them to optimized OGG Vorbis (Quality 4, ~112-128kbps)
# Deletes the original file and its Godot .import file

echo "Starting Audio Optimization to OGG Vorbis..."

find . -type f \( -iname "*.mp3" -o -iname "*.wav" \) | while read -r file; do
    echo "Processing: $file"
    
    # Extract filename without extension
    base="${file%.*}"
    ogg_file="${base}.ogg"
    
    # Convert using ffmpeg
    ffmpeg -y -v warning -i "$file" -c:a libvorbis -q:a 4 "$ogg_file"
    
    if [ $? -eq 0 ]; then
        echo "Successfully converted to $ogg_file. Removing original..."
        rm "$file"
        
        # Remove Godot import file if it exists
        if [ -f "${file}.import" ]; then
            rm "${file}.import"
        fi
    else
        echo "Error converting $file"
    fi
done

echo "Audio Optimization Complete!"
