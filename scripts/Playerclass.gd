# PlayerClass.gd
# Autoload or attach as Node to Player.
# Handles class selection, stat bonuses, passive effects, and active abilities.
# Usage:
#   PlayerClass.set_class(player, "wizard")
#   PlayerClass.use_ability(player, 0)   # slot 0 = first class ability

extends Node

# ─────────────────────────────────────────────────────────────────────────────
#  CLASS DEFINITIONS
# ─────────────────────────────────────────────────────────────────────────────
const CLASSES: Dictionary = {

	"warrior": {
		"display_name":  "Warrior",
		"description":   "Masters of melee combat. High defense, strong melee damage. Passive armor aura.",
		"icon":          "res://assets/sprites/ui/class_warrior.png",
		"color":         Color(0.85, 0.25, 0.18),
		# Flat stat bonuses applied on top of base player stats
		"stat_bonus": {
			"base_max_hp":    50,
			"defense":        8,
			"damage_bonus":   0.15,
			"move_speed":    -10.0,   # slower but tankier
			"crit_chance":    0.03,
		},
		# Passive: increases defense by 50% while standing still
		"passive_id":    "iron_stance",
		"passive_desc":  "Gain +50% defense while not moving",
		# Active abilities (Q, E, R, T or whatever you bind)
		"abilities": [
			{
				"id":       "shield_bash",
				"name":     "Shield Bash",
				"desc":     "Deal 2× melee damage + stun nearby enemies for 1 s",
				"cooldown": 8.0,
				"mana_cost": 0,
				"icon":     "res://assets/sprites/ui/ability_bash.png",
			},
			{
				"id":       "war_cry",
				"name":     "War Cry",
				"desc":     "+30% damage & defense for 10 s. Nearby allies also buffed.",
				"cooldown": 30.0,
				"mana_cost": 0,
				"icon":     "res://assets/sprites/ui/ability_warcry.png",
			},
			{
				"id":       "whirlwind",
				"name":     "Whirlwind",
				"desc":     "Spin dealing 1.5× melee dmg to all enemies in 80px radius",
				"cooldown": 12.0,
				"mana_cost": 0,
				"icon":     "res://assets/sprites/ui/ability_whirlwind.png",
			},
		],
	},

	"rogue": {
		"display_name":  "Rogue",
		"description":   "Swift and lethal. High crit chance, backstab bonus, dodge roll.",
		"icon":          "res://assets/sprites/ui/class_rogue.png",
		"color":         Color(0.25, 0.75, 0.45),
		"stat_bonus": {
			"base_max_hp":   -20,
			"defense":       -2,
			"damage_bonus":   0.20,
			"move_speed":    30.0,
			"crit_chance":   0.15,   # rogues crit A LOT
		},
		"passive_id":    "backstab",
		"passive_desc":  "Attacks from behind deal +50% damage",
		"abilities": [
			{
				"id":       "dodge_roll",
				"name":     "Dodge Roll",
				"desc":     "Dash 120px in facing direction, invincible during roll",
				"cooldown": 4.0,
				"mana_cost": 0,
				"icon":     "res://assets/sprites/ui/ability_dodge.png",
			},
			{
				"id":       "vanish",
				"name":     "Vanish",
				"desc":     "Become invisible for 5 s. Next attack crits guaranteed.",
				"cooldown": 25.0,
				"mana_cost": 15,
				"icon":     "res://assets/sprites/ui/ability_vanish.png",
			},
			{
				"id":       "poison_blade",
				"name":     "Poison Blade",
				"desc":     "Next 3 attacks apply Poison DoT (20 dmg/s, 6 s)",
				"cooldown": 14.0,
				"mana_cost": 10,
				"icon":     "res://assets/sprites/ui/ability_poison.png",
			},
		],
	},

	"wizard": {
		"display_name":  "Wizard",
		"description":   "Powerful mana-based caster. Low HP, high spell damage and mana pool.",
		"icon":          "res://assets/sprites/ui/class_wizard.png",
		"color":         Color(0.45, 0.35, 0.95),
		"stat_bonus": {
			"base_max_hp":   -30,
			"base_max_mana":  80,    # extra mana pool
			"defense":       -4,
			"damage_bonus":   0.35,  # spells hit HARD
			"move_speed":    -5.0,
			"crit_chance":   0.08,
		},
		"passive_id":    "arcane_surge",
		"passive_desc":  "Every 8th spell cast releases a free Arcane Explosion",
		"abilities": [
			{
				"id":       "frost_nova",
				"name":     "Frost Nova",
				"desc":     "Freeze all nearby enemies for 3 s (80px radius)",
				"cooldown": 16.0,
				"mana_cost": 40,
				"icon":     "res://assets/sprites/ui/ability_frost.png",
			},
			{
				"id":       "arcane_missile",
				"name":     "Arcane Missiles",
				"desc":     "Fire 5 rapid homing bolts, each dealing 60% spell power",
				"cooldown": 10.0,
				"mana_cost": 35,
				"icon":     "res://assets/sprites/ui/ability_missile.png",
			},
			{
				"id":       "blink",
				"name":     "Blink",
				"desc":     "Teleport to mouse cursor position (max 200px)",
				"cooldown": 8.0,
				"mana_cost": 20,
				"icon":     "res://assets/sprites/ui/ability_blink.png",
			},
		],
	},

	"paladin": {
		"display_name":  "Paladin",
		"description":   "Holy warrior who heals allies and smites evil. Great survivability.",
		"icon":          "res://assets/sprites/ui/class_paladin.png",
		"color":         Color(0.95, 0.85, 0.25),
		"stat_bonus": {
			"base_max_hp":    40,
			"base_max_mana":  20,
			"defense":        6,
			"damage_bonus":   0.08,
			"move_speed":    -15.0,
			"crit_chance":    0.04,
		},
		"passive_id":    "holy_shield",
		"passive_desc":  "When hit below 30% HP, gain a shield absorbing 40 damage",
		"abilities": [
			{
				"id":       "holy_smite",
				"name":     "Holy Smite",
				"desc":     "Radiant burst dealing 3× damage. Extra vs undead enemies.",
				"cooldown": 10.0,
				"mana_cost": 30,
				"icon":     "res://assets/sprites/ui/ability_smite.png",
			},
			{
				"id":       "lay_on_hands",
				"name":     "Lay on Hands",
				"desc":     "Instantly restore 200 HP to yourself",
				"cooldown": 45.0,
				"mana_cost": 0,
				"icon":     "res://assets/sprites/ui/ability_heal.png",
			},
			{
				"id":       "consecrate",
				"name":     "Consecrate",
				"desc":     "Hallow the ground for 8 s. Enemies in area take 15 dmg/s.",
				"cooldown": 20.0,
				"mana_cost": 25,
				"icon":     "res://assets/sprites/ui/ability_consecrate.png",
			},
		],
	},

	"ranger": {
		"display_name":  "Ranger",
		"description":   "Long-range expert. Traps, high arrow damage, and superior mobility.",
		"icon":          "res://assets/sprites/ui/class_ranger.png",
		"color":         Color(0.35, 0.75, 0.25),
		"stat_bonus": {
			"base_max_hp":    10,
			"defense":       -1,
			"damage_bonus":   0.25,   # applies to bow shots
			"move_speed":    20.0,
			"crit_chance":   0.10,
		},
		"passive_id":    "eagle_eye",
		"passive_desc":  "Arrow range +50%. First shot on an enemy always crits.",
		"abilities": [
			{
				"id":       "rain_of_arrows",
				"name":     "Rain of Arrows",
				"desc":     "Fire 8 arrows in a 120° arc ahead of you",
				"cooldown": 12.0,
				"mana_cost": 0,
				"icon":     "res://assets/sprites/ui/ability_rain.png",
			},
			{
				"id":       "bear_trap",
				"name":     "Bear Trap",
				"desc":     "Place a trap. Enemy that steps on it is rooted for 4 s.",
				"cooldown": 8.0,
				"mana_cost": 0,
				"icon":     "res://assets/sprites/ui/ability_trap.png",
			},
			{
				"id":       "hunters_mark",
				"name":     "Hunter's Mark",
				"desc":     "Mark a target. All damage to it +40% for 12 s.",
				"cooldown": 20.0,
				"mana_cost": 15,
				"icon":     "res://assets/sprites/ui/ability_mark.png",
			},
		],
	},
}

# ─────────────────────────────────────────────────────────────────────────────
#  RUNTIME STATE
# ─────────────────────────────────────────────────────────────────────────────
var current_class_id: String = ""
var ability_cooldowns: Array  = [0.0, 0.0, 0.0]   # per ability slot
var passive_counter:  int    = 0   # for arcane surge, etc.

# Passive state flags
var _vanish_active:      bool  = false
var _poison_stacks:      int   = 0
var _holy_shield_active: bool  = false
var _holy_shield_hp:     int   = 0
var _first_shot_crit:    bool  = true  # ranger eagle eye per-enemy

signal class_changed(class_id: String)
signal ability_used(slot: int, class_id: String)
signal ability_ready(slot: int)

func _process(delta: float) -> void:
	for i in ability_cooldowns.size():
		if ability_cooldowns[i] > 0.0:
			var was_ready = ability_cooldowns[i] <= 0.0
			ability_cooldowns[i] = max(0.0, ability_cooldowns[i] - delta)
			if not was_ready and ability_cooldowns[i] <= 0.0:
				emit_signal("ability_ready", i)

# ─────────────────────────────────────────────────────────────────────────────
#  CLASS MANAGEMENT
# ─────────────────────────────────────────────────────────────────────────────
func set_class(player: Node, class_id: String) -> bool:
	if not CLASSES.has(class_id):
		push_warning("PlayerClass: unknown class '%s'" % class_id)
		return false

	# Remove old class bonuses
	if current_class_id != "":
		_remove_class_bonuses(player, current_class_id)

	current_class_id = class_id
	ability_cooldowns = [0.0, 0.0, 0.0]
	_apply_class_bonuses(player, class_id)
	emit_signal("class_changed", class_id)
	print("PlayerClass: set to '%s'" % class_id)
	return true

func get_class_data(class_id: String) -> Dictionary:
	return CLASSES.get(class_id, {})

func get_current_class() -> Dictionary:
	return CLASSES.get(current_class_id, {})

func _apply_class_bonuses(player: Node, class_id: String) -> void:
	var data = CLASSES[class_id]
	var bonus = data.get("stat_bonus", {})
	for stat in bonus:
		if stat in player:
			player.set(stat, player.get(stat) + bonus[stat])
	# Recompute derived stats
	if player.has_method("_recalc_stats"):
		player._recalc_stats()

func _remove_class_bonuses(player: Node, class_id: String) -> void:
	var data = CLASSES[class_id]
	var bonus = data.get("stat_bonus", {})
	for stat in bonus:
		if stat in player:
			player.set(stat, player.get(stat) - bonus[stat])
	if player.has_method("_recalc_stats"):
		player._recalc_stats()

# ─────────────────────────────────────────────────────────────────────────────
#  ABILITY USAGE
# ─────────────────────────────────────────────────────────────────────────────
func use_ability(player: Node, slot: int) -> bool:
	if current_class_id == "":
		return false
	if slot < 0 or slot >= ability_cooldowns.size():
		return false
	if ability_cooldowns[slot] > 0.0:
		return false   # on cooldown

	var class_data = CLASSES[current_class_id]
	var abilities  = class_data.get("abilities", [])
	if slot >= abilities.size():
		return false

	var ab = abilities[slot]

	# Check mana cost
	if player.mana < ab.get("mana_cost", 0):
		var hud = player.get_node_or_null("../UI/HUD")
		if hud: hud.show_popup("Not enough mana!", 1.2)
		return false

	# Deduct mana
	player.mana -= ab.get("mana_cost", 0)
	player.mana = max(0, player.mana)
	if player.has_signal("mana_changed"):
		player.emit_signal("mana_changed", player.mana, player.max_mana)

	# Set cooldown
	ability_cooldowns[slot] = ab.get("cooldown", 5.0)

	# Execute ability
	_execute_ability(player, ab["id"])
	emit_signal("ability_used", slot, current_class_id)
	return true

func _execute_ability(player: Node, ability_id: String) -> void:
	match ability_id:
		# ── WARRIOR ──────────────────────────────────────────────────────────
		"shield_bash":
			_ability_shield_bash(player)
		"war_cry":
			_ability_war_cry(player)
		"whirlwind":
			_ability_whirlwind(player)

		# ── ROGUE ─────────────────────────────────────────────────────────────
		"dodge_roll":
			_ability_dodge_roll(player)
		"vanish":
			_ability_vanish(player)
		"poison_blade":
			_ability_poison_blade(player)

		# ── WIZARD ────────────────────────────────────────────────────────────
		"frost_nova":
			_ability_frost_nova(player)
		"arcane_missile":
			_ability_arcane_missiles(player)
		"blink":
			_ability_blink(player)

		# ── PALADIN ───────────────────────────────────────────────────────────
		"holy_smite":
			_ability_holy_smite(player)
		"lay_on_hands":
			_ability_lay_on_hands(player)
		"consecrate":
			_ability_consecrate(player)

		# ── RANGER ────────────────────────────────────────────────────────────
		"rain_of_arrows":
			_ability_rain_of_arrows(player)
		"bear_trap":
			_ability_bear_trap(player)
		"hunters_mark":
			_ability_hunters_mark(player)

# ─────────────────────────────────────────────────────────────────────────────
#  WARRIOR ABILITIES
# ─────────────────────────────────────────────────────────────────────────────
func _ability_shield_bash(player: Node) -> void:
	var radius = 80.0
	var hud = player.get_node_or_null("../UI/HUD")
	if hud: hud.show_popup("⚔ Shield Bash!", 1.5)
	# Flash gold
	_flash_player(player, Color(0.9, 0.7, 0.2), 0.18)
	# Hit all nearby enemies with 2× damage + stun
	for enemy in player.get_tree().get_nodes_in_group("enemy"):
		if enemy.global_position.distance_to(player.global_position) <= radius:
			var dmg = int(player._active_item().damage * player.damage_bonus * 2.0) if player._active_item() else 20
			enemy.take_damage(dmg, (enemy.global_position - player.global_position).normalized())
			if enemy.has_method("apply_debuff"):
				enemy.apply_debuff("stunned", 1.0)

func _ability_war_cry(player: Node) -> void:
	var hud = player.get_node_or_null("../UI/HUD")
	if hud: hud.show_popup("⚔ WAR CRY! +30% DMG & DEF", 3.0)
	_flash_player(player, Color(0.9, 0.35, 0.15), 0.25)
	player.damage_bonus += 0.30
	player.defense      += int(player.defense * 0.30)
	await player.get_tree().create_timer(10.0).timeout
	player.damage_bonus -= 0.30
	player.defense      -= int(player.defense * 0.231)  # approximate reverse

func _ability_whirlwind(player: Node) -> void:
	var hud = player.get_node_or_null("../UI/HUD")
	if hud: hud.show_popup("⚔ Whirlwind!", 1.0)
	_flash_player(player, Color(0.8, 0.5, 0.2), 0.12)
	var item = player._active_item() if player.has_method("_active_item") else null
	var base_dmg = item.damage if item else 15
	for enemy in player.get_tree().get_nodes_in_group("enemy"):
		if enemy.global_position.distance_to(player.global_position) <= 80.0:
			var dmg = int(base_dmg * player.damage_bonus * 1.5)
			enemy.take_damage(dmg, (enemy.global_position - player.global_position).normalized())

# ─────────────────────────────────────────────────────────────────────────────
#  ROGUE ABILITIES
# ─────────────────────────────────────────────────────────────────────────────
func _ability_dodge_roll(player: Node) -> void:
	var dir = Vector2(player._facing, 0)
	player.velocity = dir * 600.0
	player._iframes = 0.4  # invincible during roll
	_flash_player(player, Color(0.3, 0.9, 0.5, 0.7), 0.15)

func _ability_vanish(player: Node) -> void:
	_vanish_active = true
	var hud = player.get_node_or_null("../UI/HUD")
	if hud: hud.show_popup("Vanish! Next attack guaranteed crit.", 2.0)
	var tw = player.sprite.create_tween()
	tw.tween_property(player.sprite, "modulate:a", 0.2, 0.3)
	await player.get_tree().create_timer(5.0).timeout
	_vanish_active = false
	var tw2 = player.sprite.create_tween()
	tw2.tween_property(player.sprite, "modulate:a", 1.0, 0.3)

func _ability_poison_blade(player: Node) -> void:
	_poison_stacks = 3
	var hud = player.get_node_or_null("../UI/HUD")
	if hud: hud.show_popup("☠ Poison Blade — 3 charges!", 1.5)
	player.sprite.modulate = Color(0.4, 1.0, 0.3)
	await player.get_tree().create_timer(0.4).timeout
	player.sprite.modulate = Color.WHITE

# ─────────────────────────────────────────────────────────────────────────────
#  WIZARD ABILITIES
# ─────────────────────────────────────────────────────────────────────────────
func _ability_frost_nova(player: Node) -> void:
	var hud = player.get_node_or_null("../UI/HUD")
	if hud: hud.show_popup("❄ Frost Nova!", 1.5)
	_flash_player(player, Color(0.5, 0.85, 1.0), 0.2)
	for enemy in player.get_tree().get_nodes_in_group("enemy"):
		if enemy.global_position.distance_to(player.global_position) <= 80.0:
			enemy.take_damage(25, Vector2.ZERO)
			if enemy.has_method("apply_debuff"):
				enemy.apply_debuff("frozen", 3.0)
	# Visual ring
	_spawn_ring_fx(player, Color(0.5, 0.85, 1.0, 0.7), 80.0)

func _ability_arcane_missiles(player: Node) -> void:
	var hud = player.get_node_or_null("../UI/HUD")
	if hud: hud.show_popup("✦ Arcane Missiles!", 1.0)
	var target = _find_nearest_enemy(player, 400.0)
	if not target:
		if hud: hud.show_popup("No target in range.", 1.2)
		return
	var dmg = int(player.damage_bonus * 60.0)
	for i in 5:
		await player.get_tree().create_timer(i * 0.12).timeout
		if is_instance_valid(target):
			target.take_damage(dmg, Vector2.ZERO)
			_spawn_impact_fx(target.global_position, Color(0.6, 0.4, 1.0))

func _ability_blink(player: Node) -> void:
	var mouse_world = player.get_global_mouse_position()
	var dir         = (mouse_world - player.global_position).normalized()
	var dist        = min(player.global_position.distance_to(mouse_world), 200.0)
	var dest        = player.global_position + dir * dist
	_spawn_impact_fx(player.global_position, Color(0.5, 0.3, 1.0, 0.6))
	player.global_position = dest
	_spawn_impact_fx(dest, Color(0.7, 0.5, 1.0))

# ─────────────────────────────────────────────────────────────────────────────
#  PALADIN ABILITIES
# ─────────────────────────────────────────────────────────────────────────────
func _ability_holy_smite(player: Node) -> void:
	var hud = player.get_node_or_null("../UI/HUD")
	if hud: hud.show_popup("✦ Holy Smite!", 1.5)
	_flash_player(player, Color(1.0, 0.95, 0.4), 0.2)
	var item    = player._active_item() if player.has_method("_active_item") else null
	var base_d  = item.damage if item else 20
	var smite_d = int(base_d * player.damage_bonus * 3.0)
	var enemies = player.get_tree().get_nodes_in_group("enemy")
	var hit_any = false
	for enemy in enemies:
		if enemy.global_position.distance_to(player.global_position) <= 100.0:
			var bonus = 1.5 if enemy.is_in_group("undead") else 1.0
			enemy.take_damage(int(smite_d * bonus), Vector2.ZERO)
			hit_any = true
	if not hit_any and hud:
		hud.show_popup("No enemies in range.", 1.0)

func _ability_lay_on_hands(player: Node) -> void:
	player.hp = min(player.max_hp, player.hp + 200)
	player.emit_signal("hp_changed", player.hp, player.max_hp)
	_flash_player(player, Color(1.0, 0.95, 0.4), 0.3)
	var hud = player.get_node_or_null("../UI/HUD")
	if hud: hud.show_popup("✦ Lay on Hands — +200 HP!", 2.0)
	var dmg_node = player.get_tree().get_first_node_in_group("damage_numbers")
	if dmg_node and dmg_node.has_method("heal"):
		dmg_node.heal(player.global_position, 200)

func _ability_consecrate(player: Node) -> void:
	var hud = player.get_node_or_null("../UI/HUD")
	if hud: hud.show_popup("✦ Consecrate!", 1.5)
	var pos = player.global_position
	var end_time = Time.get_ticks_msec() / 1000.0 + 8.0
	_spawn_ring_fx(player, Color(1.0, 0.9, 0.3, 0.4), 60.0)
	# Tick damage every second for 8 s
	var ticks = 8
	for i in ticks:
		await player.get_tree().create_timer(1.0).timeout
		for enemy in player.get_tree().get_nodes_in_group("enemy"):
			if enemy.global_position.distance_to(pos) <= 60.0:
				enemy.take_damage(15, Vector2.ZERO)

# ─────────────────────────────────────────────────────────────────────────────
#  RANGER ABILITIES
# ─────────────────────────────────────────────────────────────────────────────
func _ability_rain_of_arrows(player: Node) -> void:
	var hud = player.get_node_or_null("../UI/HUD")
	if hud: hud.show_popup("🏹 Rain of Arrows!", 1.0)
	var item  = player._active_item() if player.has_method("_active_item") else null
	var dmg   = int((item.damage if item else 12) * player.damage_bonus)
	var spread = 120.0
	var bolt_scene = load("res://scenes/spells/generic_bolt.tscn")
	if not bolt_scene: return
	for i in 8:
		var angle_deg = -spread * 0.5 + (spread / 7.0) * i
		var dir = Vector2(float(player._facing), 0).rotated(deg_to_rad(angle_deg))
		var bolt = bolt_scene.instantiate()
		bolt.global_position = player.global_position
		if bolt.has_method("setup"):
			bolt.setup(dir, dmg, 500.0)
		player.get_parent().add_child(bolt)

func _ability_bear_trap(player: Node) -> void:
	var hud = player.get_node_or_null("../UI/HUD")
	if hud: hud.show_popup("🏹 Bear Trap placed!", 1.0)
	var trap_pos = player.global_position + Vector2(float(player._facing) * 40.0, 0.0)
	_place_bear_trap(player, trap_pos)

func _place_bear_trap(player: Node, pos: Vector2) -> void:
	var trap = Area2D.new()
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 16.0
	shape.shape   = circle
	trap.add_child(shape)
	trap.collision_layer = 0
	trap.collision_mask  = 4  # enemy layer
	trap.global_position = pos
	player.get_parent().add_child(trap)

	# Visual indicator
	var vis = ColorRect.new()
	vis.size = Vector2(12, 12)
	vis.color = Color(0.6, 0.4, 0.1, 0.8)
	vis.position = Vector2(-6, -6)
	trap.add_child(vis)

	# Wait for enemy to step on it
	await trap.body_entered
	if not is_instance_valid(trap): return
	var body = trap.get_overlapping_bodies()[0] if trap.get_overlapping_bodies().size() > 0 else null
	if body and body.is_in_group("enemy"):
		if body.has_method("apply_debuff"):
			body.apply_debuff("rooted", 4.0)
		if player.get_node_or_null("../UI/HUD"):
			player.get_node_or_null("../UI/HUD").show_popup("Bear Trap — enemy rooted!", 1.5)
	trap.queue_free()

func _ability_hunters_mark(player: Node) -> void:
	var target = _find_nearest_enemy(player, 400.0)
	if not target:
		var hud = player.get_node_or_null("../UI/HUD")
		if hud: hud.show_popup("No target in range.", 1.0)
		return
	var hud = player.get_node_or_null("../UI/HUD")
	if hud: hud.show_popup("🏹 Hunter's Mark! +40% damage to target", 2.0)
	# Visual indicator on enemy
	var mark = Label.new()
	mark.text = "☆"
	mark.add_theme_font_size_override("font_size", 20)
	mark.add_theme_color_override("font_color", Color(1.0, 0.5, 0.1))
	mark.position = Vector2(-8, -50)
	target.add_child(mark)
	# Apply a temporary damage multiplier flag
	if "mark_damage_bonus" in target:
		target.mark_damage_bonus = 0.40
	await player.get_tree().create_timer(12.0).timeout
	if is_instance_valid(mark): mark.queue_free()
	if is_instance_valid(target) and "mark_damage_bonus" in target:
		target.mark_damage_bonus = 0.0

# ─────────────────────────────────────────────────────────────────────────────
#  PASSIVE HOOKS
#  Call these from Player.gd at the appropriate moments.
# ─────────────────────────────────────────────────────────────────────────────

# Call from Player when casting a spell (Wizard passive)
func on_spell_cast() -> void:
	if current_class_id != "wizard": return
	passive_counter += 1
	if passive_counter >= 8:
		passive_counter = 0
		print("Arcane Surge triggered!")
		# TODO: trigger explosion around player

# Call from Player when applying melee damage (Rogue passives)
func modify_melee_damage(player: Node, base_dmg: int, enemy: Node) -> int:
	var dmg = base_dmg
	match current_class_id:
		"rogue":
			# Vanish: guaranteed crit on next attack
			if _vanish_active:
				_vanish_active = false
				dmg = int(dmg * 2.5)
				var hud = player.get_node_or_null("../UI/HUD")
				if hud: hud.show_popup("BACKSTAB CRIT!", 1.5)
			# Poison blade stacks
			if _poison_stacks > 0:
				_poison_stacks -= 1
				if enemy.has_method("apply_debuff"):
					enemy.apply_debuff("poisoned", 6.0)
		"ranger":
			# First shot crit (eagle eye)
			if not enemy.is_in_group("enemy_hit_before"):
				dmg = int(dmg * 2.0)
				enemy.add_to_group("enemy_hit_before")
		"warrior":
			pass  # handled in iron_stance

	return dmg

# Call from Player.take_damage (Paladin passive)
func on_player_take_damage(player: Node, amount: int) -> int:
	if current_class_id != "paladin": return amount
	if player.hp <= int(float(player.max_hp) * 0.30) and not _holy_shield_active:
		_holy_shield_active = true
		_holy_shield_hp     = 40
		var hud = player.get_node_or_null("../UI/HUD")
		if hud: hud.show_popup("✦ Holy Shield absorbed damage!", 2.0)
	if _holy_shield_active and _holy_shield_hp > 0:
		var absorbed = min(_holy_shield_hp, amount)
		_holy_shield_hp -= absorbed
		if _holy_shield_hp <= 0:
			_holy_shield_active = false
		return max(0, amount - absorbed)
	return amount

# ─────────────────────────────────────────────────────────────────────────────
#  VFX HELPERS
# ─────────────────────────────────────────────────────────────────────────────
func _flash_player(player: Node, col: Color, duration: float) -> void:
	if not player.has_node("Sprite2D"): return
	player.sprite.modulate = col
	await player.get_tree().create_timer(duration).timeout
	if is_instance_valid(player) and is_instance_valid(player.sprite):
		player.sprite.modulate = Color.WHITE

func _find_nearest_enemy(player: Node, max_dist: float) -> Node:
	var nearest: Node = null
	var best_d: float = max_dist
	for enemy in player.get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy): continue
		var d = enemy.global_position.distance_to(player.global_position)
		if d < best_d:
			best_d = d
			nearest = enemy
	return nearest

func _spawn_ring_fx(player: Node, col: Color, radius: float) -> void:
	# Expanding ring using a temporary Line2D circle
	var ring = Node2D.new()
	ring.global_position = player.global_position
	player.get_parent().add_child(ring)
	var line = Line2D.new()
	line.width = 3.0
	line.default_color = col
	for i in range(33):
		var a = float(i) / 32.0 * TAU
		line.add_point(Vector2(cos(a), sin(a)) * radius)
	ring.add_child(line)
	var tw = ring.create_tween()
	tw.tween_property(ring, "scale", Vector2(1.4, 1.4), 0.35)
	tw.parallel().tween_property(line, "modulate:a", 0.0, 0.35)
	tw.tween_callback(ring.queue_free)

func _spawn_impact_fx(pos: Vector2, col: Color) -> void:
	var particles_node = Engine.get_main_loop().current_scene.get_node_or_null("Particles")
	if not particles_node: return
	for _i in 6:
		var p = ColorRect.new()
		p.size = Vector2(randf_range(3, 6), randf_range(3, 6))
		p.color = col
		p.global_position = pos + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		particles_node.add_child(p)
		var tw = p.create_tween()
		tw.tween_property(p, "position:y", p.position.y - randf_range(10, 30), 0.3)
		tw.parallel().tween_property(p, "modulate:a", 0.0, 0.3)
		tw.tween_callback(p.queue_free)

# ─────────────────────────────────────────────────────────────────────────────
#  SAVE / LOAD
# ─────────────────────────────────────────────────────────────────────────────
func get_save_data() -> Dictionary:
	return {"class_id": current_class_id}

func load_save_data(data: Dictionary, player: Node) -> void:
	var saved_class = data.get("class_id", "")
	if saved_class != "":
		set_class(player, saved_class)