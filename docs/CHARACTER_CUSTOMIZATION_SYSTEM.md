# Character Customization System - Complete Documentation

## Overview

The **Aetheria Character Customization System** is a modular, layer-based character creation system that supports:
- **Gender selection** (Male, Female, Neutral)
- **Face expressions** (Stoic, Fierce, Calm, Battle)
- **Hair colors** with dynamic wind-affected flow (Black, Brown, Blonde, Red)
- **Class-based arms** (Warrior, Wizard, Archer)
- **Default clothes** (Tunic, Shirt, Robe, Pants)
- **Equipment system** (Light/Heavy armor, helmets, boots)
- **Wind physics** for realistic hair flow

---

## System Architecture

### Core Scripts

| Script | Purpose |
|--------|---------|
| `CharacterCustomizer.gd` | Main modular sprite system with all customization |
| `WindSystem.gd` | Global wind simulation with direction/strength |
| `HairFlowSystem.gd` | Hair physics and wind response |
| `PlayerIntegration.gd` | Player bridge with save/load |
| `CharacterSaveSystem.gd` | Save/load functionality |
| `CharacterCreatorUI.gd` | Character creation UI controller |

### Layer Order (Back to Front)

```
Layer 0: BASE_LEGS      - Base leg sprites
Layer 1: BASE_ARMS      - Class-specific arms
Layer 2: BASE_TORSO     - Gender-specific torso
Layer 3: CLOTHES_PANTS  - Default pants
Layer 4: CLOTHES_TOP    - Default top
Layer 5: EQUIP_BOOTS    - Armor boots
Layer 6: EQUIP_CHEST    - Armor chest
Layer 7: BASE_FACE      - Face expression
Layer 8: HAIR           - Wind-affected hair (animated)
Layer 9: EQUIP_HELMET   - Helmet (covers hair)
```

---

## Wind System

### WindSystem.gd

The wind system simulates realistic environmental wind:

```gdscript
# Configuration
base_wind_direction: Vector2  # Direction wind blows (default: right)
base_wind_strength: float     # Strength 0.0-3.0 (default: 1.0)
wind_turbulence: float        # Variation amount (default: 0.3)
wind_change_interval: float   # How often wind changes (default: 2.0s)
```

### Wind Effects on Hair

| Wind State | Strength | Hair Animation |
|------------|----------|----------------|
| NORMAL | < 1.0 | Static hair sprite |
| LIGHT | 1.0-2.0 | wind1 sprite + gentle bob |
| MEDIUM | 2.0-3.0 | wind1 sprite + moderate motion |
| STRONG | > 3.0 | wind2 sprite + dramatic flow |

### Hair Wind Sprites

The system uses 4 wind-affected sprites per gender/color:
- `hair_[color]_wind1.png` - Light breeze effect
- `hair_[color]_wind2.png` - Strong wind effect
- `hair_female_[color]_wind1.png` - Female light breeze
- `hair_female_[color]_wind2.png` - Female strong wind

---

## Usage

### Basic Setup

```gdscript
# Add as child of player
var customizer = CharacterCustomizer.new()
add_child(customizer)

# Set appearance
customizer.set_gender("female")
customizer.set_hair_color("blonde")
customizer.set_class("wizard")
```

### Wind System Setup

```gdscript
# Global wind (singleton pattern)
var wind = WindSystem.new()
get_tree().root.add_child(wind)

# Or local wind zones
wind.add_wind_zone(player_position, 100.0, Vector2.LEFT, 2.0)
```

### Character Creation Flow

```gdscript
# 1. Create UI
var ui = preload("res://scenes/CharacterCreator.tscn").instantiate()
add_child(ui)

# 2. Connect signal
ui.character_confirmed.connect(_on_character_confirmed)

# 3. Handle confirmation
func _on_character_confirmed(data: Dictionary):
    customizer.load_appearance_data(data)
    save_character(data)
```

### Saving/Loading

```gdscript
# Save
var save_system = CharacterSaveSystem.new()
save_system.save_character(customizer.get_appearance_data())

# Load
var data = save_system.load_character()
customizer.load_appearance_data(data)
```

---

## Sprite Files

### Location
`res://assets/sprites/player/parts/`

### Base Bodies
- `base_torso_male.png`
- `base_torso_female.png`
- `base_legs.png`

### Arms (Class-based)
- `arms_warrior.png` - Muscular arms
- `arms_wizard.png` - Thin arms
- `arms_archer.png` - Athletic arms
- `arms_neutral.png` - Generic arms

### Heads
- `head_male.png`
- `head_female.png`
- `head_neutral.png`

### Faces
- `face_male_stoic.png`
- `face_male_fierce.png`
- `face_female_calm.png`
- `face_female_battle.png`

### Hair Colors
- `hair_black.png` / `hair_female_black.png`
- `hair_brown.png` / `hair_female_brown.png`
- `hair_blonde.png` / `hair_female_blonde.png`
- `hair_red.png` / `hair_female_red.png`

### Hair Wind Animation
- `hair_black_wind1.png` / `hair_black_wind2.png`
- `hair_female_black_wind1.png` / `hair_female_black_wind2.png`
- (Same pattern for all colors)

### Clothes
- `clothes_tunic.png`
- `clothes_shirt.png`
- `clothes_robe.png`
- `clothes_pants.png`

### Armor
- `armor_chest_light.png`
- `armor_chest_heavy.png`
- `armor_chest_robes.png`
- `boots_light.png`
- `boots_heavy.png`
- `helmet_full.png`
- `helmet_hood.png`

---

## Signals

| Signal | Parameters | Description |
|--------|------------|-------------|
| `appearance_changed` | `Dictionary` | Character appearance updated |
| `animation_changed` | `String` | Animation state changed |
| `hair_state_changed` | `String` | Wind hair state changed |

---

## Configuration Options

### Gender Options
- `"male"` - Male body type
- `"female"` - Female body type
- `"neutral"` - Neutral/unisex body

### Face Options
- `"stoic"` - Neutral expression
- `"fierce"` - Aggressive/intense
- `"calm"` - Peaceful/serene
- `"battle"` - Combat-ready

### Hair Colors
- `"black"` - Dark hair
- `"brown"` - Brown hair
- `"blonde"` - Blonde hair
- `"red"` - Red hair

### Classes
- `"warrior"` - Thick muscular arms
- `"wizard"` - Thin arcane arms
- `"archer"` - Athletic arms
- `"neutral"` - Generic arms

### Clothes
- `"tunic"` - Basic adventurer garb
- `"shirt"` - Simple shirt
- `"robe"` - Wizard/mage robe
- `"pants"` - Basic leg covering

---

## Integration with Existing Player

Replace or extend your existing `Player.gd`:

```gdscript
extends CharacterBody2D

var character_customizer: Node2D
var wind_system: Node

func _ready():
    # Use PlayerIntegration.gd or manually setup
    character_customizer = CharacterCustomizer.new()
    add_child(character_customizer)

    wind_system = WindSystem.new()
    get_tree().root.add_child(wind_system)

func _physics_process(delta):
    # Update velocity for movement-based wind
    character_customizer.set_player_velocity(velocity)
```

---

## Performance Considerations

- Wind calculations run every frame (lightweight)
- Hair sprite swapping only occurs on state change
- Animation frames cached in memory
- Consider disabling hair flow in indoor areas

---

## Future Enhancements

- Cape/cloak physics with wind
- Floating particle effects in wind
- Season-specific wind patterns
- Weather system integration
