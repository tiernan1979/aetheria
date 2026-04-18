# LoadingScreen.gd — shown while world generates
# Node tree:
#   LoadingScreen (CanvasLayer, layer 100)
#   ├── Background (ColorRect, full screen)
#   ├── Logo (Label)
#   ├── StatusLabel (Label)
#   ├── ProgressBar (ProgressBar)
#   └── TipLabel (Label)

extends CanvasLayer

signal generation_complete

@onready var status_label: Label       = $Background/StatusLabel
@onready var tip_label:    Label       = $Background/TipLabel
@onready var progress_bar: ProgressBar = $Background/ProgressBar
@onready var logo:         Label       = $Background/Logo

var _tips = [
    "Tip: Blazite is the weakest ore — look for it near the surface.",
    "Tip: Craft a Furnace before an Anvil — you'll need it for bars.",
    "Tip: Verdite ore glows faintly green underground.",
    "Tip: The deeper you dig, the more powerful the ores.",
    "Tip: Build walls in your shelter to keep enemies out at night.",
    "Tip: Moonite shines like starlight — rare but worth the search.",
    "Tip: Craft a bed to set your spawn point.",
    "Tip: Aethite appears only after a boss is defeated.",
    "Tip: Radiance ore is found deepest — endgame material.",
    "Tip: Slimes drop gel — needed for torches early game.",
]
var _current_tip: int = 0
var _tip_timer: float = 0.0

func _ready() -> void:
    layer = 100
    if tip_label:
        tip_label.text = _tips[randi() % _tips.size()]
    if progress_bar:
        progress_bar.value = 0
        progress_bar.max_value = 100

func _process(delta: float) -> void:
    _tip_timer += delta
    if _tip_timer > 5.0:
        _tip_timer = 0.0
        _current_tip = (_current_tip + 1) % _tips.size()
        if tip_label:
            tip_label.text = _tips[_current_tip]

func set_status(text: String, progress: float) -> void:
    if status_label: status_label.text = text
    if progress_bar: progress_bar.value = progress

func hide_screen() -> void:
    var tw = create_tween()
    tw.tween_property(self, "layer", 100, 0.0)
    if $Background:
        tw.tween_property($Background, "modulate:a", 0.0, 0.5)
    tw.tween_callback(queue_free)
