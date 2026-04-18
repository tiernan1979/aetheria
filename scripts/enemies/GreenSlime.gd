# ════════════════════════════════════════════════════════════
#  ENEMY TYPES  — each is its own .gd file, but collected here
#  for the design document.  Copy each class to its own file:
#    scripts/enemies/Slime.gd
#    scripts/enemies/GreenSlime.gd  etc.
# ════════════════════════════════════════════════════════════

# ─── GREEN SLIME  (scripts/enemies/GreenSlime.gd) ────────────
# class_name GreenSlime
extends EnemyBase
#
# Stats:  HP=35  DMG=8  SPD=60  aggro=300  xp=3  coins=1
# Drops:  Gel (always 1-3), occasionally Slime Crown (rare)
# Behavior: Hops toward player. Splits into 2 tiny slimes on death (if above 20% HP).
# Spawns: Surface biome (any), day and night.

# ─── CAVE SLIME  ─────────────────────────────────────────────
# Stats:  HP=55  DMG=14  SPD=50  harder = blue/purple variant
# Drops:  Gel 2-5, Glowing Goo (rare) used in light crafting

# ─── DEMON EYE  ──────────────────────────────────────────────
# Flying enemy, surface nights.
# Stats:  HP=60  DMG=15  SPD=120 (flies)  aggro=450
# Drops:  Lens (1, 33%), Demon Eye Feather (rare)
# Behavior: Charges at player in straight line every 2s, then resets.

# ─── GIANT BAT  ──────────────────────────────────────────────
# Underground caves.
# Stats:  HP=45  DMG=12  SPD=140 (flies)
# Drops:  Fang 1-2 (50%), Bat Wing (rare) — needed for flying mount

# ─── ZOMBIE  ─────────────────────────────────────────────────
# Surface nights.
# Stats:  HP=80  DMG=18  SPD=55  knock_resist=0.2
# Drops:  Bone 1-3 (60%), Rotten Chunk (rare — summon ingredient)

# ─── SKELETON  ───────────────────────────────────────────────
# Underground.
# Stats:  HP=65  DMG=20  SPD=80
# Behavior: Throws bones as projectile (every 2.5s, arced).
# Drops:  Bone 2-5 (always), Skull (rare — trophy)

# ─── CAVE SPIDER  ─────────────────────────────────────────────
# Spawns on cave ceilings and drops down.
# Stats:  HP=70  DMG=22  SPD=110  poisonous=true
# Behavior: Jumps from ceiling, inflicts Poison DoT for 5s.
# Drops:  Silk 1-3 (60%), Spider Fang (30%)

# ─── GOBLIN WARRIOR  ─────────────────────────────────────────
# Surface events (Goblin Army — triggered after first gold ore mined).
# Stats:  HP=90  DMG=24  SPD=95
# Drops:  Iron Shackles (for Tinkerer NPC), Goblin Blade (rare weapon)

# ─── LAVA CRAB  ──────────────────────────────────────────────
# Underworld biome.
# Stats:  HP=120  DMG=35  SPD=70  fire_immune=true
# Behavior: Immune to fire damage. Splashes lava on death (2-tile radius).
# Drops:  Obsidian Shard 2-4, Fire Essence (rare — fire gear component)

# ─── WRAITH  ─────────────────────────────────────────────────
# Deep underground, post-hardmode.
# Stats:  HP=160  DMG=42  SPD=110 (flies, phases through walls briefly)
# Behavior: Can phase through up to 3 tiles of solid wall.
# Drops:  Ectoplasm 1-2 (70%), Spectral Eye (rare)

# ─── FROST GOLEM  ────────────────────────────────────────────
# Snow biome, hardmode.
# Stats:  HP=320  DMG=55  SPD=50  knock_resist=0.7
# Behavior: Smash attack (3-tile range), throws ice bolts every 4s.
# Drops:  Ice Core 1-3, Frost Crystal (rare — ice gear tier)

# ─── DRAGON WYVERN  ──────────────────────────────────────────
# Rare elite — spawns in sky/floating islands area.
# Stats:  HP=800  DMG=75  SPD=160 (flies)  knock_resist=0.5
# Drops:  Dragon Scale 3-6 (always), Wyvern Heart (rare — legendary mat)

# ════════════════════════════════════════════════════════════
#  BOSS ROSTER
# ════════════════════════════════════════════════════════════

# ─── BOSS 1: THE SLIME KING  ─────────────────────────────────
# Summoned by: Slime Crown (crafted: 99 gel + gold bar)
# HP: 2500  Phase 1: 2500-1000  Phase 2: <1000
# Phase 1: Hops, spawns mini slimes every 8s.
# Phase 2: Speed +50%, spawns slime rain (8 slimes from sky).
# Drops: Slime Hook, Royal Gel (accessory: 25% dmg to slimes), Gold Chest

# ─── BOSS 2: THE EYE OF THE ABYSS  ──────────────────────────
# Summoned by: Suspicious Eye (6 lens + 3 gel at night)
# HP: 5000  Two-phase mechanical eye.
# Phase 1 (>2500 HP): Orbits player, fires tear projectiles every 1.5s.
# Phase 2 (<2500): Enrages — charges at 250 speed, fires 3-way spread.
# Drops: Bionic Lens (accessory: +10% crit), Abyss Shard (crafting mat)

# ─── BOSS 3: SKELETHOR, LORD OF BONES  ───────────────────────
# Summoned by: Worm Bone (10 bones + iron bar — drops naturally in cave)
# HP: 8000  Has a main skull + 2 detachable hands.
# Skull: HP=4000, fires skull projectiles, immune until hands destroyed.
# Hand L: HP=2000, melee grab (immobilizes player 1s).
# Hand R: HP=2000, fires bone arcs.
# Phase 2 (skull alone): Becomes airborne, rains bones.
# Drops: Bone Key, Skeletal Staff (staff fires bone fragments), Hardmode Ore unlocked

# ─── BOSS 4: THE WYRM QUEEN  ─────────────────────────────────
# Giant worm boss — underground, triggered by digging below Y=900
# HP: 18000 (segmented: head=4000, 12 body=700ea, tail=1000)
# Head: Fires acid spray, can burrow through walls.
# Body segments: Take double damage from explosives.
# Drops: Wyrm Scale 5-10, Dragon Fang (crafting mat for legendary bow)

# ─── BOSS 5: THE VOID HERALD (Final Boss)  ───────────────────
# Summoned by: Void Sigil (4 Luminite Bars + 1 Wyvern Heart)
# HP: 50000  Three phases.
# Phase 1: Fires void bolts (8-way), teleports every 5s.
# Phase 2 (<35000): Splits into 3 shadow clones. Kill clones to deal to boss.
# Phase 3 (<15000): Arena goes dark, boss gains void aura (reflect 20% dmg).
#                   Luminite Blade pierces the aura.
# Drops: Void Core (used to craft Portal Gun accessory + final armor)

# ════════════════════════════════════════════════════════════
#  ACTUAL CONCRETE ENEMY SCRIPT EXAMPLE: Green Slime
# ════════════════════════════════════════════════════════════


const JUMP_COOLDOWN = 2.0  # slower hops
const JUMP_FORCE    = -320.0  # lower hops

var _jump_timer: float = 0.0

func _ready() -> void:
	enemy_name      = "Green Slime"
	max_hp          = 35
	base_damage     = 8
	move_speed      = 40.0  # slower
	aggro_range     = 300.0
	attack_range    = 32.0
	attack_cooldown = 1.2
	xp_reward       = 3
	coin_reward     = 1
	super._ready()

func _setup_animations() -> void:
	if anim and sprite:
		sprite.scale = Vector2(0.9, 0.9)
		sprite.hframes = 4
		sprite.vframes = 1
		# Build simple animations: idle=frames 0-1, walk=frames 0-1, die=frame 3
		var anims = {"idle":[0,1],"walk":[0,1],"jump":[2],"die":[3]}
		for anim_name in anims:
			var a = anim.get_animation(anim_name) if anim.has_animation(anim_name) else Animation.new()
			a.length = 0.4 * len(anims[anim_name])
			a.loop_mode = Animation.LOOP_LINEAR
			var track = a.add_track(Animation.TYPE_VALUE)
			a.track_set_path(track, "%s:frame" % sprite.get_path())
			for fi in len(anims[anim_name]):
				a.track_insert_key(track, fi * 0.4, anims[anim_name][fi])
			if not anim.has_animation(anim_name):
				var lib = AnimationLibrary.new()
				lib.add_animation(anim_name, a)
				anim.add_animation_library(anim_name + "_lib", lib)


func _init_loot_table() -> void:
	loot_table = [
		{id="gel",  count_min=1, count_max=3, chance=1.0},
	]

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_jump_timer -= delta

func _state_chase(delta: float) -> void:
	if not _player:
		_change_state(State.WANDER)
		return
	var diff = _player.global_position - global_position
	_facing  = int(sign(diff.x)) if diff.x != 0 else _facing

	# Pure hop movement: only move on the frame of the jump, stop mid-air
	if is_on_floor():
		# Kill horizontal movement when landed (no sliding)
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
		if _jump_timer <= 0.0:
			# Jump toward player
			var hop_speed = clamp(abs(diff.x) / 1.5, move_speed, move_speed * 2.0)  # slower hops
			velocity.x = float(_facing) * hop_speed
			velocity.y = JUMP_FORCE
			_jump_timer = JUMP_COOLDOWN
			_safe_play("walk")
		else:
			_safe_play("idle")
	else:
		# In the air: don't control horizontal, let physics carry
		# Slight deceleration so they don't slide too far
		velocity.x = move_toward(velocity.x, 0.0, 60.0 * delta)
		_safe_play("walk")

	if diff.length() <= attack_range:
		_change_state(State.ATTACK)

func _state_wander(_delta: float) -> void:
	# Slimes also hop when wandering
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 300.0 * _delta)
		if _jump_timer <= 0.0:
			var wander_dir = 1 if randf() > 0.5 else -1
			_facing = wander_dir
			velocity.x = float(wander_dir) * move_speed * 1.5
			velocity.y = JUMP_FORCE * 0.7  # smaller wander hop
			_jump_timer = JUMP_COOLDOWN * 1.5  # wander slower
			_safe_play("walk")
		else:
			_safe_play("idle")
	else:
		velocity.x = move_toward(velocity.x, 0.0, 80.0 * _delta)
		_safe_play("walk")

func _die() -> void:
	# Spawn 2 tiny slimes if not tiny itself
	# Split into smaller slimes by spawning via EnemyManager (scene not needed)
	if max_hp > 15:
		var mgr = get_tree().get_first_node_in_group("enemy_manager")
		if mgr and mgr.has_method("spawn_at"):
			for _i in 2:
				mgr.spawn_at(global_position + Vector2(randf_range(-20,20), -10), "tiny")
	super._die()
