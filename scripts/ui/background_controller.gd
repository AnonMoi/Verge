## background_controller.gd
## 背景切换控制器 — 白天/黑夜分别使用不同背景图，带淡入淡出过渡
## 挂载在 main_game.tscn 的 Background (TextureRect) 节点上

extends TextureRect

@export var day_bg: Texture2D   # 白天背景 (Bright)
@export var night_bg: Texture2D  # 夜晚背景 (Pale)

const TRANSITION_DURATION: float = 0.85
const DAY_TINT: Color = Color(0.95, 0.98, 0.95, 1.0)
const DUSK_TINT: Color = Color(0.88, 0.80, 0.72, 1.0)
const NIGHT_TINT: Color = Color(0.76, 0.84, 0.96, 1.0)
const DAY_ALPHA: float = 0.98
const DUSK_ALPHA: float = 0.88
const NIGHT_ALPHA: float = 0.80


var _is_transitioning: bool = false
var _target_tint: Color = DAY_TINT
var _target_alpha: float = DAY_ALPHA

func _ready() -> void:
	# 默认显示白天背景
	texture = day_bg
	modulate = Color(DAY_TINT.r, DAY_TINT.g, DAY_TINT.b, DAY_ALPHA)

	# 监听阶段切换信号
	SignalBus.cycle_phase_changed.connect(_on_phase_changed)


func _on_phase_changed(_phase_name: String) -> void:
	match TimeCycle.current_phase:
		TimeCycle.Phase.DAY:
			_switch_to(day_bg, DAY_TINT, DAY_ALPHA)
		TimeCycle.Phase.DUSK:
			_switch_to(day_bg, DUSK_TINT, DUSK_ALPHA)
		TimeCycle.Phase.NIGHT:
			_switch_to(night_bg, NIGHT_TINT, NIGHT_ALPHA)


func _switch_to(new_texture: Texture2D, tint_color: Color, alpha: float) -> void:
	if _is_transitioning and texture == new_texture and is_equal_approx(_target_alpha, alpha) and _target_tint == tint_color:
		return

	_is_transitioning = true
	_target_tint = tint_color
	_target_alpha = alpha

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate", Color(tint_color.r, tint_color.g, tint_color.b, alpha), TRANSITION_DURATION)
	tween.connect("finished", func() -> void:
		texture = new_texture
		_is_transitioning = false
	)


