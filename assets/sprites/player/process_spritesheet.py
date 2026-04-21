#!/usr/bin/env python3
"""
Aetheria Spritesheet Processor
Removes grid lines and creates a clean spritesheet for Godot
"""

from PIL import Image
import os

# Configuration
SPRITES_DIR = os.path.dirname(os.path.abspath(__file__))
INPUT_FILE = "player_sheet_new.png"
OUTPUT_FILE = "player_sheet.png"

# Target frame dimensions
FRAME_WIDTH = 20
FRAME_HEIGHT = 32
COLUMNS = 6
ROWS = 7

def process_spritesheet():
    input_path = os.path.join(SPRITES_DIR, INPUT_FILE)
    if not os.path.exists(input_path):
        print(f"Error: {input_path} not found")
        return

    print("Processing spritesheet...")

    # Load the image
    img = Image.open(input_path)
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    width, height = img.width, img.height
    print(f"Input image: {width}x{height} pixels")

    # Calculate cell dimensions
    cell_width = width // COLUMNS
    cell_height = height // ROWS
    print(f"Cell size: {cell_width}x{cell_height} pixels")

    # Create output spritesheet
    output_width = FRAME_WIDTH * COLUMNS  # 120px
    output_height = FRAME_HEIGHT * ROWS    # 224px
    output = Image.new('RGBA', (output_width, output_height), (0, 0, 0, 0))

    # Animation configuration: frames per row (rest are empty/transparent)
    ANIM_FRAMES = {
        0: 4,   # idle
        1: 6,   # run
        2: 2,   # jump
        3: 2,   # fall
        4: 4,   # swing
        5: 4,   # mine
        6: 5,   # die
    }

    for row in range(ROWS):
        frames_in_row = ANIM_FRAMES.get(row, 0)

        for col in range(COLUMNS):
            # Source cell position
            src_x = col * cell_width
            src_y = row * cell_height

            # Extract the cell
            cell = img.crop((
                src_x,
                src_y,
                src_x + cell_width,
                src_y + cell_height
            ))

            # Scale down to target frame size (20x32)
            cell = cell.resize((FRAME_WIDTH, FRAME_HEIGHT), Image.NEAREST)

            # Destination position
            dst_x = col * FRAME_WIDTH
            dst_y = row * FRAME_HEIGHT

            # Paste into output
            output.paste(cell, (dst_x, dst_y))

    # Save the processed spritesheet
    output_path = os.path.join(SPRITES_DIR, OUTPUT_FILE)
    output.save(output_path)
    print(f"Saved: {OUTPUT_FILE} ({output_width}x{output_height} pixels)")

    # Create a 4x preview for inspection
    preview = output.resize((output_width * 4, output_height * 4), Image.NEAREST)
    preview_path = os.path.join(SPRITES_DIR, "player_sheet_preview.png")
    preview.save(preview_path)
    print(f"Created preview: player_sheet_preview.png")

    print("\nAnimation row summary:")
    for row, frames in ANIM_FRAMES.items():
        row_names = ["idle", "run", "jump", "fall", "swing", "mine", "die"]
        print(f"  Row {row} ({row_names[row]}): {frames} animation frames + {COLUMNS - frames} empty slots")

    print("\nDone! Copy player_sheet.png to your Godot project.")

if __name__ == "__main__":
    process_spritesheet()