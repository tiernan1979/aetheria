# OptionsMenu.gd — ESC pause menu
extends Control

@onready var resume_btn:    Button  = $Panel/VBox/ResumeBtn
@onready var options_btn:   Button  = $Panel/VBox/OptionsBtn
@onready var quit_menu_btn: Button  = $Panel/VBox/QuitMenuBtn
@onready var quit_game_btn: Button  = $Panel/VBox/QuitGameBtn
@onready var vol_slider:    HSlider = $Panel/VBox/VolSlider
@onready var sub_options:   Control = $Panel/SubOptions
@onready var panel:         Panel   = $Panel

func _ready() -> void:
	visible = false
	_style_panel()
	if resume_btn:    resume_btn.pressed.connect(close)
	if options_btn:   options_btn.pressed.connect(_open_sub_options)
	if quit_menu_btn: quit_menu_btn.pressed.connect(_quit_to_menu)
	if quit_game_btn: quit_game_btn.pressed.connect(get_tree().quit)
	if sub_options:   sub_options.visible = false
	# Wire sub_options back button
	var back_btn = get_node_or_null("Panel/SubOptions/VBox2/BackBtn")
	if back_btn: back_btn.pressed.connect(func(): if sub_options: sub_options.visible = false)
	# Wire volume slider
	var vol2 = get_node_or_null("Panel/SubOptions/VBox2/VolSlider2")
	if vol2: vol2.value_changed.connect(func(v):
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(v)))

func _style_panel() -> void:
	if not panel: return
	var sb = StyleBoxFlat.new()
	sb.bg_color           = Color(0.05, 0.04, 0.14, 0.97)
	sb.border_color       = Color(0.55, 0.38, 0.85, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.shadow_color       = Color(0, 0, 0, 0.5)
	sb.shadow_size        = 6
	panel.add_theme_stylebox_override("panel", sb)
	# Style each button
	for btn_name in ["ResumeBtn","OptionsBtn","QuitMenuBtn","QuitGameBtn"]:
		var btn = get_node_or_null("Panel/VBox/%s" % btn_name)
		if not btn: continue
		var sb2 = StyleBoxFlat.new()
		sb2.bg_color     = Color(0.12, 0.10, 0.28, 0.9)
		sb2.border_color = Color(0.45, 0.32, 0.72, 0.8)
		sb2.set_border_width_all(1)
		sb2.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("normal", sb2)
		var sb3 = sb2.duplicate()
		sb3.bg_color     = Color(0.25, 0.18, 0.45, 0.95)
		sb3.border_color = Color(0.75, 0.55, 1.0, 1.0)
		sb3.set_border_width_all(2)
		btn.add_theme_stylebox_override("hover", sb3)
		var sb4 = sb2.duplicate()
		sb4.bg_color     = Color(0.18, 0.13, 0.35, 1.0)
		btn.add_theme_stylebox_override("pressed", sb4)
		btn.add_theme_color_override("font_color", Color(0.9, 0.82, 1.0))
		btn.add_theme_font_size_override("font_size", 16)

func open() -> void:
	visible = true
	if sub_options: sub_options.visible = false
	get_tree().paused = true

func close() -> void:
	visible = false
	get_tree().paused = false

func _open_sub_options() -> void:
	if sub_options:
		sub_options.visible = true
	else:
		# Sub options not in scene — show inline volume
		pass

func _quit_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
