extends CanvasLayer

@onready var hint_panel: Panel = $HintPanel
@onready var hint_label: Label = $HintPanel/HintLabel

var current_tween: Tween = null

const SHOW_DURATION: float = 4.0
const FADE_DURATION: float = 0.5

func _ready() -> void:
	hint_panel.visible = false
	SignalBus.show_tutorial.connect(_on_show_tutorial)

func _on_show_tutorial(text: String, position: Vector2) -> void:
	if current_tween:
		current_tween.kill()
	
	hint_label.text = text
	hint_panel.position = position
	hint_panel.visible = true
	hint_panel.modulate.a = 1.0
	
	current_tween = create_tween()
	current_tween.tween_interval(SHOW_DURATION)
	current_tween.tween_property(hint_panel, "modulate:a", 0.0, FADE_DURATION)
	current_tween.tween_callback(_hide_hint)

func _hide_hint() -> void:
	hint_panel.visible = false
