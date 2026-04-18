# Aetheria  —  Godot 4.6.1

A Terraria-inspired 2D sandbox platformer built with Godot 4.6.1 (Compatibility renderer).

---

## Project structure

```
aetheria/
├── assets/
│   ├── placeholder/
│   │   └── icon.png                 Project icon
│   ├── sprites/
│   │   ├── armor/                   Armour set sprites (head/chest/legs/boots per tier)
│   │   ├── backgrounds/             Parallax sky & biome background layers
│   │   ├── bars/                    Smelted ingot icons
│   │   ├── consumables/             Potion & consumable item icons
│   │   ├── enemies/                 Enemy spritesheets
│   │   ├── furniture/               Placeable furniture item icons
│   │   ├── misc/                    Drop items (gel, bone, gems, etc.)
│   │   ├── ores/                    Raw ore item icons (drop sprites, not tiles)
│   │   ├── player/
│   │   │   └── player_sheet.png     6×7 animation spritesheet (96×112 px)
│   │   ├── tools/                   Tool item icons (pickaxe, axe, hammer)
│   │   ├── trees/                   Tree sprites (tree_sm/md/lg/xl.png)
│   │   ├── ui/                      HUD icons (heart, mana star, hotbar slots)
│   │   └── weapons/                 Weapon item icons (sword, bow, staff)
│   └── tilesets/
│       └── world_tiles.png          Master tileset atlas  256×256 px  16×16 tiles
│                                    16 columns × 16 rows  (ATLAS_COLS = 16)
│                                    Row 0: terrain ids 0-14
│                                      0=dirt  1=grass  2=stone  3=sand  4=sandstone
│                                      5=ice   6=snow   7=mud    8=obsidian
│                                      9=wood(ghost)  10=stone_brick  11=platform
│                                      12=bedrock  13=glass  14=leaves
│                                    Row 1: plants ids 16-18 (ghost — VegetationSway renders them)
│                                      16=weed  17=flower_red  18=flower_yellow
│                                    Row 6: tier 1-4 ores  ids 96-103
│                                      96=coprite  97=stannite  98=ferrite  99=plumbite
│                                      100=argite  101=volframite  102=aurite  103=palatite
│                                    Row 7: hardmode ores  ids 112-116
│                                      112=aethril  113=veridite  114=draconite
│                                      115=solite   116=voidite
├── scenes/
│   ├── World.tscn                   Main game scene
│   ├── Player.tscn                  Player character
│   ├── MainMenu.tscn
│   ├── LoadingScreen.tscn
│   ├── enemies/GreenSlime.tscn
│   └── ui/HUD.tscn
├── scripts/
│   ├── World.gd                     Scene root — world gen orchestration, tile access
│   ├── WorldGen.gd                  Procedural world generator
│   ├── TileSetBuilder.gd            Builds TileSet at runtime from world_tiles.png
│   ├── Player.gd                    Player physics, mining, inventory
│   ├── HeldItem.gd                  Weapon/tool sprite at player's hand
│   ├── EnemyManager.gd              Spawns and culls enemies
│   ├── EnemyBase.gd                 Base class for all enemy types
│   ├── ItemDatabase.gd              Autoload — all item definitions
│   ├── CraftingDatabase.gd          Autoload — all crafting recipes
│   ├── HUD.gd                       Heads-up display (hotbar, HP/mana, inventory)
│   ├── VegetationSway.gd            Animated plant overlays (weed/flower sprites)
│   ├── TreeSprite.gd                Visual tree node (trunk + swaying canopy)
│   ├── TileBreakFX.gd               Block-break particle bursts
│   ├── AnimationHelper.gd           Builds player animations from spritesheet at runtime
│   ├── DayNightCycle.gd             Day/night sky light system
│   ├── SaveSystem.gd                Autoload — save/load game state
│   ├── AudioManager.gd              Autoload — music and SFX playback
│   ├── MountSystem.gd               Autoload — mount bonuses
│   ├── bosses/                      Boss scripts (Skelethor, WyrmQueen)
│   ├── enemies/                     Enemy scripts (GreenSlime)
│   └── npcs/                        NPC scripts (Guide, Merchant, Blacksmith, Nurse)
└── project.godot
```

---

## Key constants

| Constant | Value | Location |
|---|---|---|
| Tile size | 16 × 16 px | TileSetBuilder, World.gd |
| Atlas columns | 16 | TileSetBuilder, WorldGen |
| World width | 4200 tiles | WorldGen |
| World height | 1200 tiles | WorldGen |
| Camera zoom | 3× | Player.tscn |
| Player capsule | radius=6 height=14 | Player.tscn |

---

## Tile ID reference

Ghost tiles (ids 9, 16, 17, 18) are stored in the TileMapLayer for game-logic reads
(`get_tile_id_at`, axe detection, `break_tile`) but have **no atlas entry** so they
render as nothing in the tilemap. Their visuals come from dedicated Sprite2D nodes:

- `T_WOOD  (9)` → `TreeSprite` node under `$Trees`
- `T_WEED  (16)` / `T_FLOWER_R (17)` / `T_FLOWER_Y (18)` → `VegetationSway` node

---

## Autoloads (project.godot)

| Name | Script |
|---|---|
| `ItemDB` | `scripts/ItemDatabase.gd` |
| `CraftDB` | `scripts/CraftingDatabase.gd` |
| `SaveSystem` | `scripts/SaveSystem.gd` |
| `MountSystem` | `scripts/MountSystem.gd` |
| `AudioManager` | `scripts/AudioManager.gd` |

---

## Changelog — v32

- **FIX** `EnemyManager.gd` — `extends Node2D` (was `Node`) to match scene node type
- **FIX** `EnemyManager.gd` — Added `start(player, tilemap)` function called by `World.gd`
- **FIX** `World.tscn` — `EnemyManager` node type changed from `Node` → `Node2D`
- **FIX** `TileSetBuilder.gd` — Tile size reverted to 16×16 px; `ATLAS_COLS=16`; `HE=8.0`
- **FIX** `World.gd` — Spawn position maths uses 8 px (half of 16) tile half-extent
- **FIX** `Player.gd` — World boundary `tile_size` corrected from 32 → 16
- **FIX** `VegetationSway.gd` — Plant anchor offset uses 8 px (16px tile)
- **FIX** `TreeSprite.gd` — Tree anchor offset uses 8 px
- **FIX** `EnemyManager.gd` — Enemy spawn tile conversion uses `/ 16.0`; tile_top uses `- 8.0`
- **NEW** `world_tiles.png` — Rebuilt 256×256 atlas (16×16 tiles) with procedural
  noise, edge lighting, ore veins, crack details for all terrain and ore tiles
- **CLEAN** Removed `tools/` folder (23 Python generator scripts — dev only)
- **CLEAN** Removed `sprite_preview.png`, `sprite_preview_v3.png`
- **CLEAN** Removed `assets/sprites/tiles/` (19 individual tile PNGs — world_tiles.png is canonical)
- **CLEAN** Removed stale zip-extraction artefact folders (`{bosses,enemies,…}`)
- **UPDATED** Camera zoom: 1.5× → 3× to match halved physical world scale
