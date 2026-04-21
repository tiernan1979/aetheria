#!/usr/bin/env python3
"""
Aetheria Player Sprite Sheet Assembler
Combines individual animation rows into a single 6x7 spritesheet
"""

from PIL import Image
import os

# Animation row configuration based on AnimationHelper.gd
ANIMATIONS = [
    ("player_sheet_idle.png",       4),  # Row 0: idle
    ("player_sheet_run.png",         6),  # Row 1: run
    ("player_sheet_jump.png",        2),  # Row 2: jump
    ("player_sheet_fall.png",        2),  # Row 3: fall
    ("player_sheet_swing.png",       4),  # Row 4: swing
    ("player_sheet_mine.png",        4),  # Row 5: mine
    ("player_sheet_die.png",         5),  # Row 6: die
]

# Target sprite dimensions
FRAME_WIDTH = 20
FRAME_HEIGHT = 32
COLUMNS = 6
ROWS = 7

def load_animation_row(filepath):
    """Load and validate an animation row image"""
    img_path = os.path.join(SPRITES_DIR, filepath)
    if not os.path.exists(img_path):
        print(f"Warning: {filepath} not found")
        return None

    img = Image.open(img_path)
    # Convert to RGBA to ensure transparency works
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    return img

def resize_frames(img, expected_frames):
    """Ensure the row has exactly the expected number of frames"""
    expected_width = FRAME_WIDTH * expected_frames
    expected_height = FRAME_HEIGHT

    current_width = img.width
    current_height = img.height

    # Calculate scaling factor to fit frame dimensions
    scale_w = expected_width / current_width
    scale_h = expected_height / current_height
    scale = min(scale_w, scale_h)  # Keep aspect ratio, fit within bounds

    new_width = int(current_width * scale)
    new_height = int(current_height * scale)

    # Resize using nearest neighbor for pixel art
    img = img.resize((new_width, new_height), Image.NEAREST)

    # If we have extra space, we need to handle it
    # For now, let's just ensure it's approximately correct
    return img

def assemble_spritesheet():
    """Assemble all animation rows into a single spritesheet"""
    # Create empty spritesheet with transparent background
    sheet_width = FRAME_WIDTH * COLUMNS  # 120px
    sheet_height = FRAME_HEIGHT * ROWS   # 224px

    spritesheet = Image.new('RGBA', (sheet_width, sheet_height), (0, 0, 0, 0))

    for row_idx, (filename, expected_frames) in enumerate(ANIMATIONS):
        row_path = os.path.join(SPRITES_DIR, filename)
        if not os.path.exists(row_path):
            print(f"Warning: {row_path} not found, skipping row {row_idx}")
            continue

        # Load the row image
        row_img = Image.open(row_path)
        if row_img.mode != 'RGBA':
            row_img = row_img.convert('RGBA')

        # Calculate how many frames are in this row
        frames_in_row = max(expected_frames, row_img.width // FRAME_WIDTH)

        # Extract each frame and place in the correct position
        for col in range(COLUMNS):
            frame_idx = col

            # Handle wrapping if we have fewer frames than columns
            if frame_idx >= frames_in_row:
                frame_idx = frame_idx % frames_in_row

            # Calculate source x position
            src_x = frame_idx * FRAME_WIDTH

            # If source image is wider, extract the frame
            if src_x < row_img.width:
                frame = row_img.crop((src_x, 0, src_x + FRAME_WIDTH, FRAME_HEIGHT))
            else:
                # Create empty frame if needed
                frame = Image.new('RGBA', (FRAME_WIDTH, FRAME_HEIGHT), (0, 0, 0, 0))

            # Calculate destination position
            dst_x = col * FRAME_WIDTH
            dst_y = row_idx * FRAME_HEIGHT

            # Paste frame into spritesheet
            spritesheet.paste(frame, (dst_x, dst_y))

    return spritesheet

def create_preview(spritesheet):
    """Create a larger preview version for inspection"""
    scale = 4  # 4x scale for 80x128 pixel frames
    preview = spritesheet.resize(
        (spritesheet.width * scale, spritesheet.height * scale),
        Image.NEAREST
    )
    preview.save(os.path.join(SPRITES_DIR, "player_sheet_preview.png"))
    print(f"Created preview: player_sheet_preview.png ({preview.width}x{preview.height})")

def main():
    global SPRITES_DIR
    SPRITES_DIR = os.path.dirname(os.path.abspath(__file__))

    print("Aetheria Player Spritesheet Assembler")
    print("=" * 40)

    # Assemble the spritesheet
    spritesheet = assemble_spritesheet()

    # Save the final spritesheet
    output_path = os.path.join(SPRITES_DIR, "player_sheet.png")
    spritesheet.save(output_path)
    print(f"Created spritesheet: player_sheet.png ({spritesheet.width}x{spritesheet.height})")

    # Create preview
    create_preview(spritesheet)

    # Print summary
    print("\nSpritesheet Summary:")
    print(f"  - Dimensions: {spritesheet.width} x {spritesheet.height} pixels")
    print(f"  - Frame size: {FRAME_WIDTH} x {FRAME_HEIGHT} pixels")
    print(f"  - Grid: {COLUMNS} columns x {ROWS} rows")
    print(f"  - Total frames: {COLUMNS * ROWS}")
    print("\nAnimation Rows:")
    for i, (name, frames) in enumerate(ANIMATIONS):
        print(f"  Row {i} ({name.replace('player_sheet_', '').replace('.png', '')}): {frames} frames")

    print("\nDone!")

if __name__ == "__main__":
    main()