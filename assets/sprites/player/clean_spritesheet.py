#!/usr/bin/env python3
"""
Advanced Spritesheet Cleaner
Removes grid lines, ensures proper transparency, creates clean game-ready spritesheet
"""

from PIL import Image
import os

SPRITES_DIR = os.path.dirname(os.path.abspath(__file__))

FRAME_WIDTH = 20
FRAME_HEIGHT = 32
COLUMNS = 6
ROWS = 7

def clean_spritesheet():
    print("Creating clean spritesheet from row images...")

    # Animation rows
    ANIMATION_ROWS = [
        ("idle_row.png",   4),
        ("run_row.png",    6),
        ("jump_row.png",   2),
        ("fall_row.png",   2),
        ("swing_row.png",  4),
        ("mine_row.png",   4),
        ("die_row.png",    5),
    ]

    output_width = FRAME_WIDTH * COLUMNS
    output_height = FRAME_HEIGHT * ROWS
    output = Image.new('RGBA', (output_width, output_height), (0, 0, 0, 0))

    for row_idx, (filename, expected_frames) in enumerate(ANIMATION_ROWS):
        row_path = os.path.join(SPRITES_DIR, filename)
        if not os.path.exists(row_path):
            print(f"Warning: {filename} not found")
            continue

        row_img = Image.open(row_path)
        if row_img.mode != 'RGBA':
            row_img = row_img.convert('RGBA')

        row_img = row_img.resize((FRAME_WIDTH * expected_frames, FRAME_HEIGHT), Image.NEAREST)

        # Clean each frame: make dark border pixels transparent
        pixels = row_img.load()
        for y in range(FRAME_HEIGHT):
            for x in range(row_img.width):
                r, g, b, a = pixels[x, y]
                # If pixel is very dark (likely grid line), make it transparent
                if r < 25 and g < 25 and b < 25:
                    pixels[x, y] = (0, 0, 0, 0)
                # If pixel is very light (likely grid background), make it transparent
                elif r > 240 and g > 240 and b > 240:
                    pixels[x, y] = (0, 0, 0, 0)

        # Place frames in the row
        for col in range(COLUMNS):
            if col < expected_frames:
                src_x = col * FRAME_WIDTH
                frame = row_img.crop((src_x, 0, src_x + FRAME_WIDTH, FRAME_HEIGHT))
            else:
                frame = Image.new('RGBA', (FRAME_WIDTH, FRAME_HEIGHT), (0, 0, 0, 0))

            dst_x = col * FRAME_WIDTH
            dst_y = row_idx * FRAME_HEIGHT
            output.paste(frame, (dst_x, dst_y))

        print(f"Row {row_idx} processed")

    # Save final spritesheet
    output_path = os.path.join(SPRITES_DIR, "player_sheet.png")
    output.save(output_path)
    print(f"\nSaved: player_sheet.png")

    # Create preview
    preview = output.resize((output_width * 4, output_height * 4), Image.NEAREST)
    preview.save(os.path.join(SPRITES_DIR, "player_sheet_preview.png"))
    print("Created preview")

    return output

if __name__ == "__main__":
    clean_spritesheet()