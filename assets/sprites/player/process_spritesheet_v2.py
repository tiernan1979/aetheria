#!/usr/bin/env python3
"""
Aetheria Spritesheet Processor V2
Better grid line removal and character extraction
"""

from PIL import Image
import os

SPRITES_DIR = os.path.dirname(os.path.abspath(__file__))
INPUT_FILE = "player_sheet_new.png"
OUTPUT_FILE = "player_sheet.png"

FRAME_WIDTH = 20
FRAME_HEIGHT = 32
COLUMNS = 6
ROWS = 7

def find_grid_lines(img):
    """Detect vertical and horizontal grid lines by analyzing pixel columns/rows"""
    width, height = img.width, img.height

    # Analyze columns to find vertical lines (dark/bright columns)
    vertical_lines = []
    for x in range(width):
        col = img.crop((x, 0, x+1, height))
        pixels = list(col.getdata())
        # Check if this column is mostly black (grid line)
        black_count = sum(1 for p in pixels if p[0] < 30 and p[1] < 30 and p[2] < 30)
        if black_count > height * 0.8:  # 80% black pixels
            vertical_lines.append(x)

    # Analyze rows to find horizontal lines
    horizontal_lines = []
    for y in range(height):
        row = img.crop((0, y, width, y+1))
        pixels = list(row.getdata())
        black_count = sum(1 for p in pixels if p[0] < 30 and p[1] < 30 and p[2] < 30)
        if black_count > width * 0.8:
            horizontal_lines.append(y)

    return vertical_lines, horizontal_lines

def remove_grid_and_extract(img, grid_cols, grid_rows):
    """Remove grid lines and extract clean cells"""
    width, height = img.width, img.height

    # If no grid detected, fall back to uniform division
    if not grid_cols or not grid_rows:
        cell_w = width // COLUMNS
        cell_h = height // ROWS
        return cell_w, cell_h

    # Calculate cell dimensions from grid positions
    if len(grid_cols) >= COLUMNS - 1:
        cell_w = grid_cols[COLUMNS - 2]  # Last cell ends before last grid
    else:
        cell_w = width // COLUMNS

    if len(grid_rows) >= ROWS - 1:
        cell_h = grid_rows[ROWS - 2]
    else:
        cell_h = height // ROWS

    return cell_w, cell_h

def create_clean_spritesheet():
    input_path = os.path.join(SPRITES_DIR, INPUT_FILE)
    if not os.path.exists(input_path):
        print(f"Error: {input_path} not found")
        return

    print("Creating clean spritesheet...")

    img = Image.open(input_path)
    if img.mode != 'RGBA':
        img = img.convert('RGBA')

    width, height = img.width, img.height
    print(f"Source: {width}x{height}")

    # Find grid lines
    v_lines, h_lines = find_grid_lines(img)
    print(f"Detected {len(v_lines)} vertical grid lines, {len(h_lines)} horizontal")

    # Create output
    output_width = FRAME_WIDTH * COLUMNS
    output_height = FRAME_HEIGHT * ROWS
    output = Image.new('RGBA', (output_width, output_height), (0, 0, 0, 0))

    # Animation frame counts
    ANIM_FRAMES = {0: 4, 1: 6, 2: 2, 3: 2, 4: 4, 5: 4, 6: 5}

    # Calculate cell positions based on detected grid or uniform division
    cell_width = width // COLUMNS
    cell_height = height // ROWS

    # If grid lines detected, use them for more precise cell positions
    if v_lines and len(v_lines) >= COLUMNS:
        cell_width = min(cell_width, v_lines[-1] // COLUMNS + 10)
    if h_lines and len(h_lines) >= ROWS:
        cell_height = min(cell_height, h_lines[-1] // ROWS + 10)

    # Add padding for grid lines (trim edges)
    trim_margin = 5

    for row in range(ROWS):
        for col in range(COLUMNS):
            # Source position with trimming to remove grid artifacts
            src_x = col * (width // COLUMNS) + trim_margin
            src_y = row * (height // ROWS) + trim_margin
            src_w = (width // COLUMNS) - trim_margin * 2
            src_h = (height // ROWS) - trim_margin * 2

            # Extract cell
            cell = img.crop((src_x, src_y, src_x + src_w, src_y + src_h))

            # Scale to target frame size
            cell = cell.resize((FRAME_WIDTH, FRAME_HEIGHT), Image.NEAREST)

            # Make transparent pixels truly transparent
            # (in case there are dark artifacts)
            cell = cell.convert('RGBA')
            pixels = cell.load()
            for py in range(FRAME_HEIGHT):
                for px in range(FRAME_WIDTH):
                    r, g, b, a = pixels[px, py]
                    # If pixel is very dark and near edges of frame, make transparent
                    if r < 20 and g < 20 and b < 20 and a < 50:
                        pixels[px, py] = (0, 0, 0, 0)

            # Destination
            dst_x = col * FRAME_WIDTH
            dst_y = row * FRAME_HEIGHT
            output.paste(cell, (dst_x, dst_y))

    # Save
    output_path = os.path.join(SPRITES_DIR, OUTPUT_FILE)
    output.save(output_path)
    print(f"Saved: {OUTPUT_FILE} ({output_width}x{output_height})")

    # Preview at 4x
    preview = output.resize((output_width * 4, output_height * 4), Image.NEAREST)
    preview.save(os.path.join(SPRITES_DIR, "player_sheet_preview.png"))
    print("Created preview")

    print("\nReady for Godot!")
    print("- Animation frames: idle=4, run=6, jump=2, fall=2, swing=4, mine=4, die=5")

if __name__ == "__main__":
    create_clean_spritesheet()