# BuildMenu.gd — Terraria-style build/crafting UI (B key)
# Shows categories on the left, items on the right
# Attach to BuildMenu Panel in HUD.tscn
extends Control

signal build_item_selected(item_id: String)

@onready var category_list: VBoxContainer = $CategoryList
@onready var item_grid:     GridContainer  = $ItemGrid
@onready var info_panel:    Control        = $InfoPanel
@onready var info_name:     Label          = $InfoPanel/Name
@onready var info_desc:     Label          = $InfoPanel/Desc
@onready var info_reqs:     Label          = $InfoPanel/Reqs
@onready var craft_btn:     Button         = $InfoPanel/CraftBtn

var _player   = null
var _selected_recipe = null
var _current_filter: String = ""

# Categories matching Terraria
const CATEGORIES = [
	{"name": "🏗️ Building",   "filter": "BLOCK"},
	{"name": "🪑 Furniture",   "filter": "FURNITURE"},
	{"name": "⚒️  Crafting",   "filter": "CRAFTING"},
	{"name": "🛡️ Armor",      "filter": "ARMOR"},
	{"name": "⚔️  Weapons",    "filter": "WEAPON"},
	{"name": "🔧 Tools",       "filter": "TOOL"},
	{"name": "🍶 Potions",     "filter": "CONSUMABLE"},
	{"name": "📦 All",         "filter": ""},
]

func _ready() -> void:
	visible = false
	# Solid dark styled background
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.12, 0.96)
	sb.border_color = Color(0.45, 0.32, 0.72, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", sb)
	if craft_btn: craft_btn.pressed.connect(_on_craft_pressed)
	_build_categories()

func open(player) -> void:
	_player = player
	visible = true
	_show_category("")

func close() -> void:
	visible = false

func _build_categories() -> void:
	if not category_list: return
	for cat in CATEGORIES:
		var btn = Button.new()
		btn.text = cat.name
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(140, 36)
		btn.pressed.connect(func(): _show_category(cat.filter))
		category_list.add_child(btn)

func _show_category(filter: String) -> void:
	_current_filter = filter
	if not item_grid or not _player: return
	for child in item_grid.get_children(): child.queue_free()
	# Only show recipes where player has AT LEAST ONE ingredient
	var all_recipes = CraftDB.get_all_recipes()
	var craftable_first = []
	var have_some = []
	for recipe in all_recipes:
		var out_item = ItemDB.get_item(recipe.result_id)
		if not out_item: continue
		var cat_name = ItemDB.Category.keys()[out_item.category] if out_item.category < ItemDB.Category.size() else ""
		if filter != "" and cat_name != filter: continue
		# Check if player has any ingredients
		var has_any = false
		for ing in recipe.ingredients:
			if _player.inventory.get(ing.id, 0) > 0: has_any = true
		if not has_any: continue
		if CraftDB.can_craft(recipe, _player.inventory):
			craftable_first.append([recipe, out_item])
		else:
			have_some.append([recipe, out_item])
	# Show craftable first, then partially-available
	for pair in craftable_first + have_some:
		var btn = _make_item_button(pair[0], pair[1])
		item_grid.add_child(btn)

func _make_item_button(recipe, out_item) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(48, 48)
	# Build tooltip with item name + requirements
	var tip = out_item.name + "\n"
	for ing in recipe.ingredients:
		var ing_item = ItemDB.get_item(ing.id)
		var iname = ing_item.name if ing_item else ing.id
		tip += "  • %dx %s\n" % [ing.count, iname]
	btn.tooltip_text = tip.strip_edges()
	# Check craftable
	var can = CraftDB.can_craft(recipe, _player.inventory)
	btn.modulate = Color.WHITE if can else Color(0.45, 0.45, 0.45)
	# Icon
	var tex_path = "res://assets/sprites/%s.png" % out_item.sprite
	if ResourceLoader.exists(tex_path):
		btn.icon = load(tex_path)
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Hover highlight style
	var sb_normal = StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.12, 0.10, 0.22, 0.8)
	sb_normal.set_border_width_all(1)
	sb_normal.border_color = Color(0.35, 0.25, 0.58, 0.6)
	sb_normal.set_corner_radius_all(3)
	var sb_hover = StyleBoxFlat.new()
	sb_hover.bg_color = Color(0.25, 0.18, 0.45, 0.9)
	sb_hover.set_border_width_all(2)
	sb_hover.border_color = Color(0.65, 0.48, 0.95, 1.0)
	sb_hover.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.pressed.connect(func():
		if CraftDB.can_craft(recipe, _player.inventory):
			for ing in recipe.ingredients:
				if _player.has_method("remove_item"): _player.remove_item(ing.id, ing.count)
				else: _player.inventory[ing.id] = max(0, _player.inventory.get(ing.id,0) - ing.count)
			_player.add_item(recipe.result_id, recipe.result_count)
			var hn = get_parent().get_parent() if get_parent() else null
			if hn and hn.has_method("show_popup"):
				hn.show_popup("Crafted: %s" % out_item.name, 1.5)
			_show_category(_current_filter)
		else:
			_select_recipe(recipe, out_item)
	)  # end connect
	return btn

func _select_recipe(recipe, out_item) -> void:
	_selected_recipe = recipe
	if info_name: info_name.text = out_item.name
	if info_desc: info_desc.text = ""  # ItemDef.description not always present
	# Build requirements text
	var req_lines = []
	for ing in _selected_recipe.ingredients:
		var in_item = ItemDB.get_item(ing.id)
		var name_str = in_item.name if in_item else ing.id
		var have = _player.inventory.get(ing.id, 0)
		var mark = "✓ " if have >= ing.count else "✗ "
		req_lines.append("%s%dx %s" % [mark, ing.count, name_str])
	if info_reqs:
		info_reqs.text = "Requirements:\n" + "\n".join(req_lines)
	if craft_btn:
		craft_btn.disabled = not CraftDB.can_craft(_selected_recipe, _player.inventory)

func _on_craft_pressed() -> void:
	if _selected_recipe == null or not _player: return
	if CraftDB.can_craft(_selected_recipe, _player.inventory):
		if CraftDB.has_method("craft"):
			CraftDB.craft(_selected_recipe.id, _player)
		_player.add_item(_selected_recipe.result_id, _selected_recipe.result_count)
		emit_signal("build_item_selected", _selected_recipe.result_id)
		_select_recipe(_selected_recipe, ItemDB.get_item(_selected_recipe.result_id))
