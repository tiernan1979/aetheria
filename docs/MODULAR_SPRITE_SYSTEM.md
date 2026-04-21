# Aetheria Modular Character Sprite System

## Overview

This system allows for dynamic character customization using layered 2D sprites in Godot. Characters are composed of multiple interchangeable parts that can be swapped based on gender, class, and equipment.

## Sprite Architecture

### Layer Order (Bottom to Top)
1. **Base Legs** - Always visible, basic pants/leggings
2. **Base Torso** - Body shape (male/female variant)
3. **Base Arms** - Arm thickness (class variant)
4. **Equipment Boots** - Armor layer over legs
5. **Equipment Chest** - Armor/clothing layer over torso
6. **Equipment Helmet** - Head gear layer
7. **Head** - Face/hair (gender variant)

### Directory Structure
```
assets/sprites/player/parts/
├── base_legs.png              # Generic legs
├── base_torso_male.png        # Male torso
├── base_torso_female.png     # Female torso
├── base_torso_neutral.png     # Neutral torso
├── arms_warrior.png           # Muscular arms
├── arms_wizard.png            # Thin arms
├── arms_archer.png            # Athletic arms
├── arms_neutral.png           # Average arms
├── head_male.png              # Male face
├── head_female.png            # Female face
├── head_neutral.png           # Androgynous face
├── armor_chest_light.png      # Leather armor
├── armor_chest_heavy.png      # Plate armor
├── armor_chest_robes.png      # Mage robes
├── helmet_full.png            # Full helmet
├── helmet_hood.png            # Hood
├── boots_light.png            # Leather boots
├── boots_heavy.png            # Plate boots
```

## Sprite Specifications

- **Frame Size**: 20x32 pixels
- **Style**: Pixel art, nearest-neighbor filtering
- **Facing**: Right (flip horizontally for left)
- **Background**: Transparent (alpha channel)

## Usage in Godot

### Basic Setup
1. Copy `ModularPlayer.gd` to `scripts/`
2. Copy sprite parts to `assets/sprites/player/parts/`
3. Create a node structure:

```
Player (CharacterBody2D)
├── ModularPlayer.gd script
├── Layer_Legs (Sprite2D)
├── Layer_Base (Sprite2D)
├── Layer_Arms (Sprite2D)
├── Layer_Chest (Sprite2D)
├── Layer_Boots (Sprite2D)
├── Layer_Head (Sprite2D)
└── Layer_Helmet (Sprite2D)
```

### Script Usage

```gdscript
# Create a female warrior
player.gender = "female"
player.character_class = "warrior"

# Equip items
player.equip_item("helmet", "full_helm")
player.equip_item("chest", "heavy_plate")
player.equip_item("boots", "heavy_boots")

# Change facing
player.set_facing(1)  # Right
player.set_facing(-1) # Left
```

## Character Classes

| Class | Arm Sprite | Typical Role |
|-------|-----------|--------------|
| warrior | arms_warrior.png | Tank, melee DPS |
| wizard | arms_wizard.png | Mage, spellcaster |
| archer | arms_archer.png | Ranged, ranger |
| neutral | arms_neutral.png | Default, balanced |

## Genders

| Gender | Head Sprite | Torso Sprite |
|--------|-------------|--------------|
| male | head_male.png | base_torso_male.png |
| female | head_female.png | base_torso_female.png |
| neutral | head_neutral.png | base_torso_neutral.png |

## Equipment System

Equipment layers over base sprites, allowing infinite combinations:
- **Chest armor** overlays torso
- **Helmets** overlay head
- **Boots** overlay legs

Each equipment type can be expanded by adding new sprite variants.

## Animation Compatibility

The base sprites are designed to work with the existing `AnimationHelper.gd` system. Each layer sprite should use the same animation frames as the original player_sheet.

## Extending the System

To add new equipment:
1. Create sprite at 20x32 pixels
2. Name according to pattern: `{type}_{variant}.png`
3. Place in `assets/sprites/player/parts/`
4. Add texture loading in `ModularPlayer.gd`

## Future Enhancements

- [ ] Weapon sprites (layer over hands)
- [ ] Cape/cloak sprites (layer behind body)
- [ ] More gender variants
- [ ] Class-specific torso variations
- [ ] Animation support for each layer