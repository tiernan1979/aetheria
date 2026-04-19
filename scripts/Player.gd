# Player.gd  (Godot 4.6.1)
extends CharacterBody2D

signal hp_changed(new_hp: int, max_hp: int)
signal mana_changed(new_mana: int, max_mana: int)
signal inventory_changed
signal died
signal respawned

@export var move_speed:    float = 220.0
@export var jump_velocity: float = -540.0
@export var gravity:       float = 1200.0
@export var coyote_time:   float = 0.12
@export var jump_buffer:   float = 0.10
@export var mine_reach:    int   = 6
@export var place_reach:   int   = 6

var base_max_hp:   int   = 100
var base_max_mana: int   = 80
var max_hp:        int   = 100
var max_mana:      int   = 80
var hp:            int   = 100
var mana:          int   = 80
var defense:       int   = 0
var damage_bonus:  float = 1.0
var crit_chance:   float = 0.05
var speed_bonus:   float = 0.0
var mining_bonus:  float = 0.0

var buffs: Array = []
var inventory: Dictionary = {}
var equipped: Dictionary = {head="",chest="",legs="",feet=""}
const HOTBAR_SIZE = 10
var hotbar: Array = []
var hotbar_slot: int = 0
var kills: int = 0

var _coyote_left:   float = 0.0
var _jump_buffer:   float = 0.0
var _facing:        int   = 1
var _iframes:       float = 0.0
var _mine_progress: float = 0.0
var _mine_tile_pos: Vector2i = Vector2i(-9999,-9999)
var _swing_timer:   float = 0.0
var _is_swinging:   bool  = false
var _alive:         bool  = true
var _prev_slot:     int   = -1

var world_ref: Node = null

# Mount system fields (set by MountSystem autoload)
var is_mounted:        bool  = false
var mount_can_fly:     bool  = false
var mount_fly_speed:   float = 0.0
var mount_fall_immune: bool  = false
var mount_speed_bonus: float = 0.0
var mount_jump_bonus:  float = 0.0
var base_jump_velocity: float = -540.0

@onready var sprite:      Sprite2D        = $Sprite2D
@onready var anim:        AnimationPlayer = $AnimationPlayer
@onready var attack_box:  Area2D          = $AttackHitbox
@onready var arrow_spawn: Marker2D        = $ArrowSpawn
@onready var cam:         Camera2D        = $Camera2D

var PlayerClass = load("res://playerclass.gd")

# Safe animation — silently skips missing clips (clips are built in _ready).
func _safe_anim(clip: String) -> void:
	if not anim or not anim.has_animation(clip): return
	if anim.current_animation != clip:
		anim.play(clip)


func _ready() -> void:
	add_to_group("player")
	hotbar.resize(HOTBAR_SIZE)
	hotbar.fill("")
	attack_box.monitoring = false

	# Build animation clips from spritesheet at runtime (idle/run/jump/fall/swing/mine/die)
	if sprite and anim:
		sprite.hframes = 6
		sprite.vframes = 7
		AnimationHelper.setup_player(anim, sprite)
	else:
		push_warning("Player: Sprite2D or AnimationPlayer not found")

	_give_starter_items()
	_recalc_stats()
	emit_signal("hp_changed",   hp,   max_hp)
	emit_signal("mana_changed", mana, max_mana)

func _give_starter_items() -> void:
	add_item("wood_pickaxe", 1)
	add_item("wood_sword", 1)
	add_item("wood_axe", 1)
	add_item("torch", 10)
	add_item("healing_potion", 5)
	add_item("rope", 5)
	hotbar[0] = "wood_pickaxe"
	hotbar[1] = "wood_sword"
	hotbar[2] = "wood_axe"
	hotbar[3] = "torch"
	hotbar[4] = "healing_potion"
	# Force HUD update after items given
	await get_tree().process_frame
	emit_signal("inventory_changed")

func _physics_process(delta: float) -> void:
	if not _alive: return
	# World wrap — walking off one side teleports to the other.
	# Y is hard-clamped: no ceiling exit, no falling through the bottom.
	const TILE:   float = 16.0
	var world_w:  float = WorldGen.WORLD_WIDTH  * TILE
	var world_h:  float = WorldGen.WORLD_HEIGHT * TILE
	const WRAP_MARGIN: float = TILE * 2.0   # trigger wrap this far past the edge
	if global_position.x < -WRAP_MARGIN:
		global_position.x = world_w + global_position.x   # wrap right→left
	elif global_position.x > world_w + WRAP_MARGIN:
		global_position.x = global_position.x - world_w   # wrap left→right
	if global_position.y < TILE * 5:
		global_position.y = TILE * 5
		velocity.y = max(velocity.y, 0.0)
	const BORDER: float = WorldGen.BORDER_TILES * TILE
	if global_position.y > world_h - BORDER:
		global_position.y = world_h - BORDER
		velocity.y = min(velocity.y, 0.0)
	_handle_gravity(delta)
	_handle_movement(delta)
	_handle_jump(delta)
	_handle_interaction(delta)
	_handle_swing_timer(delta)
	_handle_buffs(delta)
	_regen_mana(delta)
	_tick_iframes(delta)
	move_and_slide()
	_update_animation()
	if hotbar_slot != _prev_slot:
		_prev_slot = hotbar_slot
		_update_held_item_visual()
		var hud2 = get_node_or_null("../UI/HUD")
		if hud2: hud2.update_hotbar(hotbar_slot)

func _input(event: InputEvent) -> void:
	if not _alive: return
	# ESC: close open panels or open options
	# Class abilities — Q, E, R
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			PlayerClass.use_ability(self, 0)
		elif event.keycode == KEY_F:
			PlayerClass.use_ability(self, 1)
		elif event.keycode == KEY_R:
			PlayerClass.use_ability(self, 2)
			
	if event.is_action_pressed("ui_cancel"):
		var hud = get_node_or_null("../UI/HUD")
		if not hud: return
		var inv = hud.get_node_or_null("InventoryPanel")
		var craft = hud.get_node_or_null("CraftingPanel")
		var build = hud.get_node_or_null("BuildMenu")
		var opts  = hud.get_node_or_null("OptionsMenu")
		if (inv and inv.visible) or (craft and craft.visible) or (build and build.visible):
			if inv:   inv.visible   = false
			if craft: craft.visible = false
			if build: build.visible = false
		else:
			if opts and opts.has_method("open"): opts.open()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("hotbar_next"):
		hotbar_slot = (hotbar_slot + 1) % HOTBAR_SIZE
		_update_held_item_visual()
	if event.is_action_pressed("hotbar_prev"):
		hotbar_slot = (hotbar_slot - 1 + HOTBAR_SIZE) % HOTBAR_SIZE
		_update_held_item_visual()
	# Number keys 1–9
	for i in range(9):
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_1 + i:
				hotbar_slot = i
				_update_held_item_visual()
	var hud = get_node_or_null("../UI/HUD")
	if event.is_action_pressed("inventory"):
		if hud: hud.toggle_inventory()
	if event.is_action_pressed("crafting"):
		if hud: hud.toggle_crafting()
	if event is InputEventKey and event.pressed and event.keycode == KEY_B:
		var build_menu = get_node_or_null("../UI/HUD/BuildMenu")
		if build_menu:
			if build_menu.visible: build_menu.close()
			else: build_menu.open(self)

func _handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y  = min(velocity.y, 1400.0)
		_coyote_left -= delta
	else:
		if _coyote_left <= 0.0 and velocity.y > 80.0:
			if has_node("/root/AudioManager"): AudioManager.play("land", 0.1)
		_coyote_left = coyote_time
		velocity.y   = 0.0

func _handle_movement(delta: float) -> void:
	var dir = Input.get_axis("move_left", "move_right")
	var spd = move_speed * (1.0 + speed_bonus)
	if dir != 0.0:
		velocity.x = lerp(velocity.x, dir * spd, 12.0 * delta)
		_facing    = int(sign(dir))
	else:
		velocity.x = lerp(velocity.x, 0.0, 16.0 * delta)
	sprite.flip_h = (_facing < 0)
	# Flip attack hitbox
	var ax = attack_box.get_node_or_null("CollisionShape2D")
	if ax: ax.position.x = abs(ax.position.x) * float(_facing)

func _handle_jump(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buffer = jump_buffer
	_jump_buffer -= delta
	if _jump_buffer > 0.0 and _coyote_left > 0.0:
		velocity.y   = jump_velocity
		_jump_buffer = 0.0
		if has_node("/root/AudioManager"): AudioManager.play("jump", 0.08)
		_coyote_left = 0.0

func _handle_interaction(delta: float) -> void:
	if not world_ref: return
	var mouse_world = get_global_mouse_position()
	var tile_pos    = world_ref.tilemap.local_to_map(mouse_world)
	var player_tile = world_ref.tilemap.local_to_map(global_position)
	var dist = (tile_pos - player_tile).length()
	var hud = get_node_or_null("../UI/HUD")
	var tool = _active_item()
	var tool_type = tool.tool_type if tool else ItemDB.ToolType.NONE
	# Consumables: use on left click (not held in hand)
	if tool and tool.category == ItemDB.Category.CONSUMABLE:
		if Input.is_action_just_pressed("attack"):
			use_consumable(hotbar[hotbar_slot])
		return

	if Input.is_action_pressed("attack"):
		var tid = world_ref.get_tile_id_at(tile_pos)
		var is_tree_tile = (tid == WorldGen.T_WOOD)  # leaves now visual-only sprites
		var is_plant_tile = (tid == 16 or tid == 17 or tid == 18)  # weeds/flowers
		var is_solid = (tid != -1 and tid != WorldGen.T_BEDROCK)  # -1=air, 12=bedrock
		# Slope, half-block, and variant tiles are also solid
		if not is_solid and ((tid >= 32 and tid < 86) or tid in [80,81,82,83,84,85]):
			is_solid = true
		# Tool restrictions
		var can_mine_this = false
		match tool_type:
			ItemDB.ToolType.PICKAXE:
				can_mine_this = is_solid and not is_tree_tile  # pickaxe: dirt/stone/ore only
			ItemDB.ToolType.AXE:
				can_mine_this = is_tree_tile or is_plant_tile  # axe: ONLY trees/plants
			ItemDB.ToolType.HAMMER:
				# Hammer cycles block shape (full → half → slope-L → slope-R → full)
				# It never mines — it only reshapes.
				if is_solid and not is_tree_tile and dist <= mine_reach:
					if Input.is_action_just_pressed("attack"):
						world_ref.cycle_block_shape(tile_pos)
						if has_node("/root/AudioManager"): AudioManager.play("swing", 0.08)
					return
				can_mine_this = false
			ItemDB.ToolType.SWORD, ItemDB.ToolType.STAFF, ItemDB.ToolType.BOW:
				can_mine_this = false  # weapons never dig
			_:
				can_mine_this = false  # bare hands: nothing
		if can_mine_this and dist <= mine_reach:
			_do_mine(tile_pos, tid, delta)
			return
		# Reset mine progress if switching tiles
		if _mine_tile_pos != tile_pos:
			_mine_progress = 0.0; _mine_tile_pos = Vector2i(-9999,-9999)
			if hud: hud.hide_mine_bar()
		if Input.is_action_just_pressed("attack"):
			_try_attack()
	elif not Input.is_action_pressed("attack"):
		if _mine_tile_pos != Vector2i(-9999,-9999):
			_mine_tile_pos = Vector2i(-9999,-9999)
			_mine_progress = 0.0
			if hud: hud.hide_mine_bar()

	if Input.is_action_just_pressed("place") and dist <= place_reach:
		var item = _active_item()
		if item and inventory.get(item.id, 0) > 0:
			var t_id = item.tile_id if "tile_id" in item else -1
			if t_id >= 0 and world_ref.place_tile(tile_pos, t_id):
				remove_item(item.id, 1)
				if hud: hud.update_hotbar(hotbar_slot)
				if item.id == "bed": world_ref.register_bed(world_ref.tilemap.map_to_local(tile_pos))
				# Show placement confirm flash
				var flash = ColorRect.new()
				flash.size = Vector2(16,16)
				flash.color = Color(1,1,1,0.5)
				flash.global_position = world_ref.tilemap.map_to_local(tile_pos) - Vector2(8,8)
				get_parent().add_child(flash)
				var tw = flash.create_tween()
				tw.tween_property(flash,"modulate:a",0.0,0.25)
				tw.tween_callback(flash.queue_free)

func _spawn_hit_sparks(world_pos: Vector2, tid: int) -> void:
	var fx = get_node_or_null("../Particles")
	if fx and fx.has_method("hit_spark"):
		fx.hit_spark(world_pos, tid)

func _do_mine(tp: Vector2i, tid: int, delta: float) -> void:
	var tool  = _active_item()
	var power = tool.mining_power if tool else 0
	# Axe always cuts wood tiles (id 9=trunk, 14=leaves)
	var is_axe = tool and tool.tool_type == ItemDB.ToolType.AXE
	if is_axe and (tid == 9 or tid == 14):
		power = max(power, 1)
	var hud = get_node_or_null("../UI/HUD")
	if power < world_ref.get_tile_req_power(tid):
		if hud and Input.is_action_just_pressed("attack"):
			hud.show_popup("Need a stronger tool!", 1.5)
		return
	if tp != _mine_tile_pos:
		_mine_tile_pos = tp
		_mine_progress = 0.0
	if world_ref:
		# Periodic hit sparks every 0.2s while mining
		var spark_interval = 0.2
		var prev_progress = _mine_progress - delta
		if int(_mine_progress / spark_interval) > int(prev_progress / spark_interval):
			_spawn_hit_sparks(world_ref.tilemap.map_to_local(tp), tid)
	# Play correct animation based on tool type + speed
	var anim_speed = (tool.speed if tool else 1.0) / 1.2
	if anim: anim.speed_scale = clamp(anim_speed, 0.7, 3.0)
	if is_axe: _safe_anim("swing")
	else: _safe_anim("mine")
	var spd = (tool.speed if tool else 0.8) * (1.0 + mining_bonus)
	_mine_progress += delta * spd * float(power + 1)
	var hardness = world_ref.get_tile_hardness(tid)
	if hud: hud.show_mine_bar(_mine_progress / hardness)
	if _mine_progress >= hardness:
		var drops = world_ref.break_tile(tp)
		# Spawn physical loot drops in world (not direct inventory)
		var loot_parent = get_tree().get_first_node_in_group("loot_drops")
		if not loot_parent: loot_parent = get_parent()
		var drop_script = load("res://scripts/LootDrop.gd")
		for drop in drops:
			if drop_script and loot_parent:
				var loot = RigidBody2D.new()
				loot.set_script(drop_script)
				var tile_world = world_ref.tilemap.map_to_local(tp)
				loot.global_position = tile_world + Vector2(randf_range(-6,6), -4)
				loot_parent.add_child(loot)
				if loot.has_method("setup"):
					loot.setup(drop.id, drop.get("count", 1))
			else:
				add_item(drop.id, drop.get("count", 1))  # fallback
		_mine_progress = 0.0
		_mine_tile_pos = Vector2i(-9999, -9999)
		if hud: hud.hide_mine_bar()
		if anim: anim.speed_scale = 1.0

func use_consumable(item_id: String) -> void:
	var item = ItemDB.get_item(item_id)
	if not item: return
	if inventory.get(item_id, 0) <= 0: return
	remove_item(item_id, 1)
	var hud = get_node_or_null("../UI/HUD")
	match item_id:
		"healing_potion":
			hp = min(max_hp, hp + 80)
			emit_signal("hp_changed", hp, max_hp)
			if hud: hud.show_popup("+80 HP", 1.5)
		"mana_potion":
			mana = min(max_mana, mana + 100)
			emit_signal("mana_changed", mana, max_mana)
			if hud: hud.show_popup("+100 Mana", 1.5)
		"battle_brew":
			damage_bonus += 0.25
			if hud: hud.show_popup("+25% Damage (5 min)", 1.5)
		"mining_potion":
			mining_bonus += 0.5
			if hud: hud.show_popup("+50% Mining Speed (5 min)", 1.5)
		_:
			if hud: hud.show_popup("Used: %s" % item.name, 1.5)
	if hud: hud.update_hotbar(hotbar_slot)


func _try_attack() -> void:
	if _is_swinging: return
	var item = _active_item()
	if not item: return
	# Use ItemDB autoload (registered in project.godot as "ItemDB")
	match item.tool_type:
		ItemDB.ToolType.SWORD, ItemDB.ToolType.PICKAXE, \
		ItemDB.ToolType.AXE,   ItemDB.ToolType.HAMMER:
			_start_melee(item)
		ItemDB.ToolType.BOW:
			_fire_arrow(item)
		ItemDB.ToolType.STAFF:
			_cast_spell(item)

func _start_melee(item) -> void:
	_is_swinging = true
	_swing_timer = 1.0 / item.speed
	attack_box.monitoring = true
	_safe_anim("swing")
	if anim: anim.speed_scale = clamp(item.speed / 1.2, 0.8, 3.0)
	await get_tree().create_timer(0.08).timeout
	# Area attack: hit enemies in arc in front of player
	# Reposition hitbox to be in front based on facing
	var ax_node = attack_box.get_node_or_null("CollisionShape2D")
	if ax_node: ax_node.position = Vector2(_facing * 22, -2)
	var i_reach = item.reach if "reach" in item else 3
	var reach_dist = float(i_reach) * 16.0 + 8.0
	for body in attack_box.get_overlapping_bodies():
		if not body.is_in_group("enemy"): continue
		var diff = body.global_position - global_position
		var dist = diff.length()
		if dist > reach_dist: continue
		# Check if enemy is in front (within 90deg arc)
		var fwd = Vector2(_facing, 0)
		if diff.normalized().dot(fwd) > -0.3:  # allows slight behind
			var is_crit = randf() < crit_chance
			var dmg = int(item.damage * damage_bonus * (1.25 if is_crit else 1.0))
			body.take_damage(dmg, fwd)
			var dmg_node = get_tree().get_first_node_in_group("damage_numbers")
			if dmg_node:
				if is_crit: dmg_node.crit(body.global_position, dmg)
				else:       dmg_node.damage(body.global_position, dmg)

func _handle_swing_timer(delta: float) -> void:
	if _is_swinging:
		_swing_timer -= delta
		if _swing_timer <= 0.0:
			_is_swinging      = false
			attack_box.monitoring = false
			if anim: anim.speed_scale = 1.0

func _fire_arrow(item) -> void:
	var scene = load("res://scenes/Arrow.tscn")
	if not scene: return
	var a   = scene.instantiate()
	var dir = (get_global_mouse_position() - global_position).normalized()
	a.global_position = arrow_spawn.global_position
	a.setup(dir, int(item.damage * damage_bonus))
	get_parent().add_child(a)
	_safe_anim("swing")

func _cast_spell(item) -> void:
	if mana < 10:
		var hud = get_node_or_null("../UI/HUD")
		if hud: hud.show_popup("Not enough mana!", 1.0)
		return
	mana -= 10
	PlayerClass.on_spell_cast()
	emit_signal("mana_changed", mana, max_mana)
	var scene = load("res://scenes/spells/generic_bolt.tscn")
	if scene:
		var b   = scene.instantiate()
		var dir = (get_global_mouse_position() - global_position).normalized()
		b.global_position = arrow_spawn.global_position
		if b.has_method("setup"): b.setup(dir, int(item.damage * damage_bonus))
		get_parent().add_child(b)
	_safe_anim("swing")

# ── DAMAGE ────────────────────────────────────────────────────
func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	#amount = PlayerClass.on_player_take_damage(self, amount)
	if has_node("/root/AudioManager"): AudioManager.play("hurt", 0.12)
	if _iframes > 0.0 or not _alive: return
	var dmg = max(1, amount - defense)
	hp -= dmg
	hp  = max(0, hp)
	emit_signal("hp_changed", hp, max_hp)
	_iframes = 0.65
	if knockback_dir != Vector2.ZERO:
		velocity = knockback_dir * 350.0
	sprite.modulate = Color(1.6, 0.3, 0.3)
	await get_tree().create_timer(0.12).timeout
	if _alive: sprite.modulate = Color.WHITE
	if hp <= 0: _die()

func _tick_iframes(delta: float) -> void:
	if _iframes > 0.0:
		_iframes -= delta
		sprite.visible = fmod(_iframes, 0.12) > 0.06
	else:
		sprite.visible = true

func _die() -> void:
	_alive = false
	sprite.visible = true
	emit_signal("died")
	var hud = get_node_or_null("../UI/HUD")
	if hud: hud.show_death_screen()

func respawn(spawn_pos: Vector2) -> void:
	global_position = spawn_pos
	hp    = max_hp
	mana  = max_mana
	_alive = true
	_iframes = 0.0
	sprite.visible  = true
	sprite.modulate = Color.WHITE
	emit_signal("respawned")
	emit_signal("hp_changed",   hp,   max_hp)
	emit_signal("mana_changed", mana, max_mana)

# ── INVENTORY ─────────────────────────────────────────────────
func add_item(id: String, count: int = 1) -> void:
	inventory[id] = inventory.get(id, 0) + count
	emit_signal("inventory_changed")

func remove_item(id: String, count: int = 1) -> bool:
	if inventory.get(id, 0) < count: return false
	inventory[id] -= count
	if inventory[id] <= 0: inventory.erase(id)
	emit_signal("inventory_changed")
	return true

func has_item(id: String, count: int = 1) -> bool:
	return inventory.get(id, 0) >= count

func _active_item():
	var id = hotbar[hotbar_slot]
	return ItemDB.get_item(id) if id != "" else null

# ── STATS RECALC ──────────────────────────────────────────────
func _recalc_stats() -> void:
	_update_held_item_visual()

func _update_held_item_visual() -> void:
	pass  # HeldItemSprite.gd handles this in _process()


	defense      = 0
	speed_bonus  = 0.0
	damage_bonus = 1.0
	crit_chance  = 0.05
	var set_counts: Dictionary = {}
	for slot in equipped:
		var id = equipped[slot]
		if id == "": continue
		var item = ItemDB.get_item(id)
		if not item: continue
		defense += item.defense
		var metal = id.split("_")[0]
		set_counts[metal] = set_counts.get(metal, 0) + 1
	for metal in set_counts:
		if set_counts[metal] >= 3: _apply_set_bonus(metal)
	max_hp   = base_max_hp   + defense * 2
	max_mana = base_max_mana

func _apply_set_bonus(metal: String) -> void:
	match metal:
		"shadow":       speed_bonus += 0.15; damage_bonus += 0.10
		"solarium":     damage_bonus += 0.10
		"aethermite":   speed_bonus  += 0.15
		"bloodrock":    damage_bonus += 0.20; crit_chance  += 0.15
		"voidcrystal":  damage_bonus += 0.30; crit_chance  += 0.10

func _handle_buffs(delta: float) -> void:
	var changed = false
	for i in range(buffs.size()-1, -1, -1):
		buffs[i].time_left -= delta
		if buffs[i].time_left <= 0.0:
			buffs.remove_at(i); changed = true
	if changed: _recalc_stats()

func _regen_mana(delta: float) -> void:
	if mana < max_mana:
		mana = min(max_mana, mana + int(10 * delta))
		emit_signal("mana_changed", mana, max_mana)

func _update_animation() -> void:
	if not _alive or _is_swinging: return
	if not is_on_floor():
		_safe_anim("jump" if velocity.y < 0 else "fall")
	elif abs(velocity.x) > 15.0:
		_safe_anim("run")
	else:
		_safe_anim("idle")
