# ClassSelectionUI.gd
# Shown at world start before the player spawns.
# Displays all 5 classes with description, stat preview, and ability list.
# Signals World.gd when a class is selected.

extends Control

signal class_selected(class_id: String)

@onready var title_label:   Label       = $Panel/VBox/Title
@onready var class_grid:    HBoxContainer = $Panel/VBox/ClassGrid
@onready var detail_panel:  Control     = $Panel/VBox/DetailPanel
@onready var select_btn:    Button      = $Panel/VBox/SelectBtn

var _hovered_class: String = ""
var _selected_class: String = ""

const CLASS_DISPLAY_ORDER = ["warrior", "rogue", "wizard", "paladin", "ranger"]
const CLASS_EMOJIS = {
	"warrior": "⚔",
	"rogue":   "🗡",
	"wizard":  "✦",
	"paladin": "🛡",
	"ranger":  "🏹",
}

func _ready() -> void:
	visible = true
	_build_class_buttons()
	if select_btn:
		select_btn.pressed.connect(_on_select_pressed)
		select_btn.disabled = true
	_show_detail("")
	# Dark overlay style
	_style_panel()

func _style_panel() -> void:
	var root_panel = get_node_or_null("Panel")
	if not root_panel: return
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.02, 0.08, 0.97)
	sb.border_color = Color(0.55, 0.35, 0.90, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 12
	root_panel.add_theme_stylebox_override("panel", sb)

func _build_class_buttons() -> void:
	if not class_grid: return
	for child in class_grid.get_children(): child.queue_free()
	for cls_id in CLASS_DISPLAY_ORDER:
		var data = PlayerClass.CLASSES.get(cls_id, {})
		if data.is_empty(): continue
		var btn = _make_class_button(cls_id, data)
		class_grid.add_child(btn)

func _make_class_button(cls_id: String, data: Dictionary) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(148, 180)

	var sb = StyleBoxFlat.new()
	sb.bg_color     = Color(0.08, 0.06, 0.18, 0.92)
	sb.border_color = Color(0.35, 0.22, 0.65, 0.7)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", sb)

	var vbox = VBoxContainer.new()
	vbox.set_anchor_and_offset(SIDE_LEFT,   0, 8)
	vbox.set_anchor_and_offset(SIDE_TOP,    0, 8)
	vbox.set_anchor_and_offset(SIDE_RIGHT,  1, -8)
	vbox.set_anchor_and_offset(SIDE_BOTTOM, 1, -8)
	panel.add_child(vbox)

	# Class emoji / icon
	var emoji = Label.new()
	emoji.text = CLASS_EMOJIS.get(cls_id, "?")
	emoji.add_theme_font_size_override("font_size", 36)
	emoji.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji.modulate = data.get("color", Color.WHITE)
	vbox.add_child(emoji)

	# Name
	var name_lbl = Label.new()
	name_lbl.text = data.get("display_name", cls_id.capitalize())
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.82, 1.0))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	# Short descriptor
	var desc = data.get("description", "")
	var short_desc = desc.split(".")[0] + "." if "." in desc else desc
	var desc_lbl = Label.new()
	desc_lbl.text = short_desc
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.58, 0.82))
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)

	# Hover / click interaction via mouse events
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_select_class(cls_id)
		elif ev is InputEventMouseMotion:
			_hover_class(cls_id, panel, sb)
	)

	return panel

func _hover_class(cls_id: String, panel: Panel, sb: StyleBoxFlat) -> void:
	if _hovered_class == cls_id: return
	_hovered_class = cls_id
	_show_detail(cls_id)
	# Tint hovered button
	var data = PlayerClass.CLASSES.get(cls_id, {})
	sb.border_color = data.get("color", Color(0.7, 0.5, 1.0))
	sb.border_color.a = 1.0
	panel.add_theme_stylebox_override("panel", sb)

func _select_class(cls_id: String) -> void:
	_selected_class = cls_id
	if select_btn:
		select_btn.disabled = false
		var data = PlayerClass.CLASSES.get(cls_id, {})
		select_btn.text = "Play as %s →" % data.get("display_name", cls_id.capitalize())
	_show_detail(cls_id)

func _show_detail(cls_id: String) -> void:
	if not detail_panel: return
	for c in detail_panel.get_children(): c.queue_free()

	if cls_id == "": return
	var data = PlayerClass.CLASSES.get(cls_id, {})
	if data.is_empty(): return

	var col = data.get("color", Color(0.7, 0.5, 1.0))

	# Class name header
	var h = Label.new()
	h.text = data.get("display_name", "")
	h.add_theme_font_size_override("font_size", 20)
	h.add_theme_color_override("font_color", col)
	detail_panel.add_child(h)

	# Full description
	var d = Label.new()
	d.text = data.get("description", "")
	d.add_theme_font_size_override("font_size", 12)
	d.add_theme_color_override("font_color", Color(0.80, 0.74, 0.96))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_panel.add_child(d)

	# Passive
	var p_lbl = Label.new()
	p_lbl.text = "Passive: " + data.get("passive_desc", "")
	p_lbl.add_theme_font_size_override("font_size", 11)
	p_lbl.add_theme_color_override("font_color", Color(0.65, 0.85, 0.65))
	p_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_panel.add_child(p_lbl)

	# Stat preview
	var bonus = data.get("stat_bonus", {})
	var stat_lines = []
	if bonus.get("base_max_hp", 0) != 0:
		stat_lines.append("HP %s%d" % ["+" if bonus["base_max_hp"] > 0 else "", bonus["base_max_hp"]])
	if bonus.get("defense", 0) != 0:
		stat_lines.append("Defense %s%d" % ["+" if bonus["defense"] > 0 else "", bonus["defense"]])
	if bonus.get("damage_bonus", 0.0) != 0.0:
		stat_lines.append("Damage %+.0f%%" % (bonus.get("damage_bonus", 0.0) * 100.0))
	if bonus.get("move_speed", 0.0) != 0.0:
		stat_lines.append("Speed %+.0f" % bonus.get("move_speed", 0.0))
	if bonus.get("crit_chance", 0.0) != 0.0:
		stat_lines.append("Crit %+.0f%%" % (bonus.get("crit_chance", 0.0) * 100.0))

	var stats_lbl = Label.new()
	stats_lbl.text = "Stats: " + "  |  ".join(stat_lines)
	stats_lbl.add_theme_font_size_override("font_size", 11)
	stats_lbl.add_theme_color_override("font_color", Color(0.70, 0.80, 0.95))
	detail_panel.add_child(stats_lbl)

	# Abilities
	var ab_header = Label.new()
	ab_header.text = "Abilities"
	ab_header.add_theme_font_size_override("font_size", 13)
	ab_header.add_theme_color_override("font_color", Color(0.9, 0.82, 1.0))
	detail_panel.add_child(ab_header)

	for ab in data.get("abilities", []):
		var ab_lbl = Label.new()
		ab_lbl.text = "  %s — %s  (CD: %.0fs)" % [ab["name"], ab["desc"], ab["cooldown"]]
		ab_lbl.add_theme_font_size_override("font_size", 10)
		ab_lbl.add_theme_color_override("font_color", Color(0.72, 0.68, 0.90))
		ab_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail_panel.add_child(ab_lbl)

func _on_select_pressed() -> void:
	if _selected_class == "": return
	emit_signal("class_selected", _selected_class)
	# Fade out
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	tw.tween_callback(queue_free)
