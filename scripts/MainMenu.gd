# MainMenu.gd  — Godot 4.6.1
# Attach to root Control node of MainMenu.tscn
extends Control

const WORLD_SCENE = "res://scenes/World.tscn"
const SAVE_PATH   = "user://saves/aetheria_save_0.json"

@onready var new_game_btn:  Button = $VBox/NewGameBtn
@onready var continue_btn:  Button = $VBox/ContinueBtn
@onready var settings_btn:  Button = $VBox/SettingsBtn
@onready var quit_btn:      Button = $VBox/QuitBtn
@onready var title_label:   Label  = $TitleLabel
@onready var subtitle_label:Label  = $SubtitleLabel
@onready var particles_node:Node2D = $Particles
@onready var fade_overlay:  ColorRect = $FadeOverlay

var _fade_tween: Tween = null
var _particle_timer: float = 0.0

func _ready() -> void:
	continue_btn.disabled = not FileAccess.file_exists(SAVE_PATH)
	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	settings_btn.pressed.connect(_on_settings)
	quit_btn.pressed.connect(_on_quit)
	for btn in [new_game_btn, continue_btn, settings_btn, quit_btn]:
		btn.mouse_entered.connect(_on_hover.bind(btn))
		btn.mouse_exited.connect(_on_unhover.bind(btn))
	# Fade in from black
	fade_overlay.color = Color(0, 0, 0, 1)
	var tw = create_tween()
	tw.tween_property(fade_overlay, "color:a", 0.0, 1.2)

func _process(delta: float) -> void:
	_particle_timer += delta
	if _particle_timer > 0.35:
		_particle_timer = 0.0
		_spawn_particle()

func _spawn_particle() -> void:
	var p = ColorRect.new()
	var sz = randf_range(3, 8)
	p.size = Vector2(sz, sz)
	var colors = [Color(0.6,0.2,1.0,0.7), Color(0.3,0.5,1.0,0.6),
	              Color(1.0,0.7,0.2,0.5), Color(0.2,0.9,0.8,0.6),
	              Color(0.9,0.3,0.6,0.5)]
	p.color = colors[randi() % colors.size()]
	p.position = Vector2(randf_range(0, get_viewport_rect().size.x),
	                     get_viewport_rect().size.y + 5)
	particles_node.add_child(p)
	var tw = p.create_tween()
	tw.tween_property(p, "position:y", p.position.y - randf_range(500, 1100), randf_range(4.5, 9.0))
	tw.parallel().tween_property(p, "modulate:a", 0.0, randf_range(3.5, 7.5))
	tw.tween_callback(p.queue_free)

func _on_hover(btn: Button) -> void:
	var tw = btn.create_tween()
	tw.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.1).set_ease(Tween.EASE_OUT)

func _on_unhover(btn: Button) -> void:
	var tw = btn.create_tween()
	tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.12).set_ease(Tween.EASE_OUT)

func _on_new_game() -> void:
	DirAccess.make_dir_recursive_absolute("user://saves")
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	_load_world()

func _on_continue() -> void:
	_load_world()

func _load_world() -> void:
	new_game_btn.disabled = true
	continue_btn.disabled = true
	var tw = create_tween()
	tw.tween_property(fade_overlay, "color:a", 1.0, 0.6)
	tw.tween_callback(func(): get_tree().change_scene_to_file(WORLD_SCENE))

func _on_settings() -> void:
	pass  # TODO: settings dialog

func _on_quit() -> void:
	var tw = create_tween()
	tw.tween_property(fade_overlay, "color:a", 1.0, 0.5)
	tw.tween_callback(get_tree().quit)
