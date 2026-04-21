#!/usr/bin/env python3
"""
Aetheria Clean Spritesheet Assembler
Assembles individual animation rows into a seamless spritesheet
"""

from PIL import Image
import os

SPRITES_DIR = os.path.dirname(os.path.abspath(__file__))

# Animation rows (in order)
ANIMATION_ROWS = [
    ("idle_row.png",   4),   # Row 0: idle - 4 frames
    ("run_row.png",    6),   # Row 1: run - 6 frames
    ("jump_row.png",   2),   # Row 2: jump - 2 frames
    ("fall_row.png",   2),   # Row 3: fall - 2 frames
    ("swing_row.png",  4),   # Row 4: swing - 4 frames
    ("mine_row.png",   4),   # Row 5: mine - 4 frames
    ("die_row.png",    5),   # Row 6: die - 5 frames
]

FRAME_WIDTH = 20
FRAME_HEIGHT = 32
COLUMNS = 6
ROWS = 7

def assemble_clean_spritesheet():
    print("Assembling clean spritesheet...")

    # Create output canvas
    output_width = FRAME_WIDTH * COLUMNS   # 120px
    output_height = FRAME_HEIGHT * ROWS    # 224px
    output = Image.new('RGBA', (output_width, output_height), (0, 0, 0, 0))

    for row_idx, (filename, expected_frames) in enumerate(ANIMATION_ROWS):
        row_path = os.path.join(SPRITES_DIR, filename)
        if not os.path.exists(row_path):
            print(f"Warning: {filename} not found, skipping row {row_idx}")
            continue

        # Load the row
        row_img = Image.open(row_path)
        if row_img.mode != 'RGBA':
            row_img = row_img.convert('RGBA')

        # Get actual frames in this row by dividing by frame width
        actual_frames = row_img.width // FRAME_WIDTH
        print(f"Row {row_idx} ({filename}): {actual_frames} frames detected")

        # Extract each frame
        for col in range(COLUMNS):
            # Source x position
            if col < actual_frames:
                src_x = col * FRAME_WIDTH
                frame = row_img.crop((src_x, 0, src_x + FRAME_WIDTH, FRAME_HEIGHT))
            else:
                # Empty frame - create transparent
                frame = Image.new('RGBA', (FRAME_WIDTH, FRAME_HEIGHT), (0, 0, 0, 0))

            # Destination position
            dst_x = col * FRAME_WIDTH
            dst_y = row_idx * FRAME_HEIGHT

            # Paste frame
            output.paste(frame, (dst_x, dst_y))

    # Save final spritesheet
    output_path = os.path.join(SPRITES_DIR, "player_sheet.png")
    output.save(output_path)
    print(f"\nSaved: player_sheet.png ({output_width}x{output_height} pixels)")

    # Create 4x preview
    preview = output.resize((output_width * 4, output_height * 4), Image.NEAREST)
    preview_path = os.path.join(SPRITES_DIR, "player_sheet_preview.png")
    preview.save(preview_path)
    print(f"Created preview: player_sheet_preview.png")

    # Summary
    print("\n" + "=" * 50)
    print("SPRITESHEET READY FOR GODOT")
    print("=" * 50)
    print(f"Dimensions: {output_width} x {output_height} pixels")
    print(f"Frame size: {FRAME_WIDTH} x {FRAME_HEIGHT} pixels")
    print(f"Grid: {COLUMNS} columns x {ROWS} rows")
    print("\nAnimation breakdown:")
    names = ["idle", "run", "jump", "fall", "swing", "mine", "die"]
    for i, (name, frames) in enumerate(names):
        print(f"  Row {i} ({name}): {frames} frames")
    print("\nCopy player_sheet.png to your Godot project!")

if __name__ == "__main__":
    assemble_clean_spritesheet()