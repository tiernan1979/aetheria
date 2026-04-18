# HUD.gd — complete Terraria-style HUD
# Attach to the HUD Control node (child of UI CanvasLayer in World.tscn)
extends Control

# ── NODE REFS ─────────────────────────────────────────────────
@onready var hp_bar:         ProgressBar   = $StatsPanel/HPBar
@onready var mana_bar:       ProgressBar   = $StatsPanel/ManaBar
@onready var time_label:     Label         = $TimeLabel
@onready var depth_label:    Label         = $StatsPanel/DepthLabel
@onready var mine_bar:       ProgressBar   = $MineBar
@onready var popup_label:    Label         = $Popup
@onready var hotbar_slots:   HBoxContainer = $Hotbar
@onready var inv_panel:      Control       = $InventoryPanel
@onready var craft_panel:    Control       = $CraftingPanel
@onready var death_screen:   Control       = $DeathScreen

var _player       = null
var _popup_timer: float = 0.0
var _drag_item:   String = ""
var _drag_from:   int   = -1    # hotbar index or -1 for inventory
var _drag_icon:   TextureRect = null

# ── INIT ──────────────────────────────────────────────────────
func _ready() -> void:
	mine_bar.visible     = false
	popup_label.visible  = false
	inv_panel.visible    = false
	craft_panel.visible  = false
	death_screen.visible = false
	_build_hotbar()

func set_player(p) -> void:
	_player = p
	p.hp_changed.connect(_on_hp_changed)
	p.mana_changed.connect(_on_mana_changed)
	p.inventory_changed.connect(_on_inventory_changed)
	hp_bar.max_value   = p.max_hp;  hp_bar.value   = p.hp
	mana_bar.max_value = p.max_mana; mana_bar.value = p.mana
	await get_tree().process_frame
	update_hotbar(0)

# ── PROCESS ───────────────────────────────────────────────────
func _process(delta: float) -> void:
	if _popup_timer > 0.0:
		_popup_timer -= delta
		if _popup_timer <= 0.0: popup_label.visible = false
	if not _player: return
	# Depth label
	var depth_m = int(_player.global_position.y / 16.0) - 220
	depth_label.text = ("Depth: %dm" % depth_m) if depth_m > 0 else "Surface"
	# Highlight selected slot
	if hotbar_slots:
		for i in hotbar_slots.get_child_count():
			var slot = hotbar_slots.get_child(i)
			if i == _player.hotbar_slot:
				slot.modulate = Color(1.5, 1.3, 0.3)
			else:
				slot.modulate = Color.WHITE

# ── HOTBAR ────────────────────────────────────────────────────
func _build_hotbar() -> void:
	for child in hotbar_slots.get_children():
		child.queue_free()
	for i in 10:
		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(52, 52)
		panel.name = "Slot%d" % i
		# Slot background style
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.1, 0.08, 0.16, 0.88)
		sb.border_color = Color(0.45, 0.28, 0.72, 1.0)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(3)
		panel.add_theme_stylebox_override("panel", sb)
		# Item icon
		var icon = TextureRect.new()
		icon.name = "Icon"
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.anchor_right = 1.0; icon.anchor_bottom = 1.0
		icon.offset_left = 4; icon.offset_top = 4
		icon.offset_right = -4; icon.offset_bottom = -12
		panel.add_child(icon)
		# Count label
		var cnt = Label.new()
		cnt.name = "Count"
		cnt.anchor_left = 0; cnt.anchor_top = 1.0
		cnt.anchor_right = 1.0; cnt.anchor_bottom = 1.0
		cnt.offset_top = -14; cnt.offset_bottom = 0
		cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cnt.add_theme_font_size_override("font_size", 11)
		cnt.add_theme_color_override("font_color", Color(1,1,1,0.9))
		cnt.add_theme_color_override("font_shadow_color", Color(0,0,0,1))
		cnt.add_theme_constant_override("shadow_offset_x", 1)
		cnt.add_theme_constant_override("shadow_offset_y", 1)
		panel.add_child(cnt)
		# Slot number
		var num = Label.new()
		num.text = str((i+1) % 10)
		num.anchor_left = 0; num.anchor_top = 0
		num.offset_left = 3; num.offset_top = 2
		num.add_theme_font_size_override("font_size", 10)
		num.add_theme_color_override("font_color", Color(0.7,0.6,1.0,0.7))
		panel.add_child(num)
		# Drop target: accepts items from inventory drag
		var slot_idx = i
		panel.set_drag_forwarding(
			func(pos): return null,
			func(_pos, data): return typeof(data) == TYPE_DICTIONARY and data.has("item_id"),
			func(data): _on_hotbar_drop(data.item_id, slot_idx)
		)
		hotbar_slots.add_child(panel)

func update_hotbar(selected: int) -> void:
	if not _player or not hotbar_slots: return
	for i in 10:
		var slot = hotbar_slots.get_child(i)
		if not slot: continue
		var icon  = slot.get_node_or_null("Icon")
		var cnt   = slot.get_node_or_null("Count")
		var item_id = _player.hotbar[i] if i < _player.hotbar.size() else ""
		if item_id == "":
			if icon: icon.texture = null
			if cnt:  cnt.text = ""
			continue
		var item = ItemDB.get_item(item_id)
		if not item:
			if icon: icon.texture = null
			continue
		var tex_path = "res://assets/sprites/%s.png" % item.sprite
		if icon:
			if ResourceLoader.exists(tex_path):
				icon.texture = load(tex_path)
				icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			else:
				icon.texture = null
		if cnt:
			var qty = _player.inventory.get(item_id, 0)
			cnt.text = str(qty) if (qty > 1 and item.max_stack > 1) else ""

# ── INVENTORY PANEL ───────────────────────────────────────────
func toggle_inventory() -> void:
	inv_panel.visible = not inv_panel.visible
	if inv_panel.visible: _refresh_inventory()

func _refresh_inventory() -> void:
	if not inv_panel.visible or not _player: return
	var grid = inv_panel.get_node_or_null("Grid")
	if not grid: return
	for child in grid.get_children(): child.queue_free()
	# Sort inventory items
	var items = []
	for id in _player.inventory:
		if _player.inventory[id] > 0:
			items.append(id)
	items.sort()
	for item_id in items:
		var qty = _player.inventory[item_id]
		var item = ItemDB.get_item(item_id)
		if not item: continue
		var btn = _make_inv_slot(item, qty)
		grid.add_child(btn)

func _make_inv_slot(item, qty: int) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(52, 52)
	btn.tooltip_text = item.name
	# Enable drag from inventory
	btn.set_drag_forwarding(
		func(pos): return _create_drag_data(item.id),
		func(data): return false,
		func(data): pass
	)
	# Icon
	var icon = TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.anchor_right = 1.0; icon.anchor_bottom = 1.0
	icon.offset_left = 4; icon.offset_top = 4; icon.offset_right = -4; icon.offset_bottom = -10
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex_path = "res://assets/sprites/%s.png" % item.sprite
	if ResourceLoader.exists(tex_path):
		icon.texture = load(tex_path)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn.add_child(icon)
	# Count
	var lbl = Label.new()
	lbl.text = str(qty) if qty > 1 else ""
	lbl.anchor_left = 0; lbl.anchor_top = 1.0; lbl.anchor_right = 1.0
	lbl.offset_top = -14; lbl.add_theme_font_size_override("font_size", 11)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)
	# Click: add to first empty hotbar slot
	btn.pressed.connect(func():
		_try_add_to_hotbar(item.id))
	# Right-click: use/equip
	btn.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_RIGHT and ev.pressed:
			_use_item(item.id))
	return btn

func _create_drag_data(item_id: String) -> Dictionary:
	var drag = {"item_id": item_id}
	# Create visual drag icon
	var icon_preview = TextureRect.new()
	var item = ItemDB.get_item(item_id)
	if item:
		var tex_path = "res://assets/sprites/%s.png" % item.sprite
		if ResourceLoader.exists(tex_path):
			icon_preview.texture = load(tex_path)
			icon_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon_preview.size = Vector2(40,40)
	set_drag_preview(icon_preview)
	return drag

func _on_hotbar_drop(item_id: String, slot_idx: int) -> void:
	if not _player: return
	# Place item into this hotbar slot
	# If slot is occupied, swap to inventory
	var prev_id = _player.hotbar[slot_idx]
	if prev_id != "" and prev_id != item_id:
		_player.hotbar[slot_idx] = item_id
		show_popup("Moved to slot %d" % (slot_idx+1), 1.0)
	else:
		_player.hotbar[slot_idx] = item_id
	update_hotbar(_player.hotbar_slot)


func _try_add_to_hotbar(item_id: String) -> void:
	if not _player: return
	# Check if already in hotbar
	if item_id in _player.hotbar: return
	# Find first empty slot
	for i in _player.hotbar.size():
		if _player.hotbar[i] == "":
			_player.hotbar[i] = item_id
			update_hotbar(_player.hotbar_slot)
			show_popup("Added to hotbar slot %d" % (i+1), 1.5)
			return
	show_popup("Hotbar full!", 1.5)

func _use_item(item_id: String) -> void:
	if not _player: return
	var item = ItemDB.get_item(item_id)
	if not item: return
	if item.category == ItemDB.Category.CONSUMABLE:
		if _player.has_method("use_consumable"):
			_player.use_consumable(item_id)

# ── BUILD MENU ────────────────────────────────────────────────
# (triggered by B key — see _input in Player.gd)

# ── CRAFTING ──────────────────────────────────────────────────
func toggle_crafting() -> void:
	craft_panel.visible = not craft_panel.visible
	if craft_panel.visible: _refresh_crafting()

func _refresh_crafting(station: String = "hand") -> void:
	if not craft_panel.visible or not _player: return
	var list = craft_panel.get_node_or_null("RecipeList")
	if not list: return
	for child in list.get_children(): child.queue_free()
	var recipes = CraftDB.get_recipes_for_station(station)
	for recipe in recipes:
		if not CraftDB.can_craft(recipe, _player.inventory): continue
		var btn = _make_recipe_button(recipe)
		list.add_child(btn)

func _make_recipe_button(recipe) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 42)
	var out_item = ItemDB.get_item(recipe.result_id)
	if out_item:
		var tex_path = "res://assets/sprites/%s.png" % out_item.sprite
		if ResourceLoader.exists(tex_path):
			btn.icon = load(tex_path)
	btn.text = "  %s" % (out_item.name if out_item else recipe.result_id)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.pressed.connect(func():
		if CraftDB.can_craft(recipe, _player.inventory):
			for ing in recipe.ingredients:
				if _player.has_method("remove_item"):
					_player.remove_item(ing.id, ing.count)
				else:
					_player.inventory[ing.id] = max(0, _player.inventory.get(ing.id,0) - ing.count)
			_player.add_item(recipe.result_id, recipe.result_count)
			show_popup("Crafted: %s" % (out_item.name if out_item else recipe.result_id), 1.5)
			_refresh_crafting()
			update_hotbar(_player.hotbar_slot)
	)
	return btn

# ── HP / MANA SIGNALS ─────────────────────────────────────────
func _on_hp_changed(new_hp: int, max_hp_val: int) -> void:
	hp_bar.max_value = max_hp_val
	hp_bar.value     = new_hp

func _on_mana_changed(new_mana: int, max_mana_val: int) -> void:
	mana_bar.max_value = max_mana_val
	mana_bar.value     = new_mana

func _on_inventory_changed() -> void:
	if _player:
		update_hotbar(_player.hotbar_slot)
		if inv_panel.visible: _refresh_inventory()
		if craft_panel.visible: _refresh_crafting()

# ── MINE BAR ──────────────────────────────────────────────────
func show_mine_bar(progress: float) -> void:
	mine_bar.visible = true
	mine_bar.value   = clamp(progress * 100.0, 0, 100)

func hide_mine_bar() -> void:
	mine_bar.visible = false; mine_bar.value = 0

# ── POPUP ─────────────────────────────────────────────────────
func show_popup(text: String, duration: float = 2.5) -> void:
	popup_label.text    = text
	popup_label.visible = true
	_popup_timer        = duration

# ── BOSS BAR ─────────────────────────────────────────────────
func show_boss_bar(boss_name: String, max_hp_val: int) -> void:
	pass  # TODO

# ── DEATH SCREEN ─────────────────────────────────────────────
func show_death_screen() -> void:
	death_screen.visible = true

func hide_death_screen() -> void:
	death_screen.visible = false
