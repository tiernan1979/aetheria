# DayNightCycle.gd — Autoload-safe Node, attach as $DayNightCycle in World.tscn
extends Node

signal dawn
signal dusk
signal midnight

const DAY_LENGTH   = 1440.0   # 24 real seconds = 1 game day
var time_of_day:   float = 0.35   # 0.0=midnight  0.5=noon
var is_daytime:    bool  = true
var _running:      bool  = false
var _was_daytime:  bool  = true

func start() -> void:
	_running = true

func stop() -> void:
	_running = false

func _process(delta: float) -> void:
	if not _running: return
	time_of_day = fmod(time_of_day + delta / DAY_LENGTH, 1.0)
	var now_day = time_of_day > 0.2 and time_of_day < 0.8
	if now_day and not _was_daytime:
		emit_signal("dawn")
	elif not now_day and _was_daytime:
		emit_signal("dusk")
	if time_of_day < 0.01:
		emit_signal("midnight")
	_was_daytime = now_day
	is_daytime   = now_day
