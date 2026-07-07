## background_controller.gd
## 背景切换控制器 — 白天/黑夜分别使用不同背景图，带淡入淡出过渡
## 挂载在 main_game.tscn 的 Background (TextureRect) 节点上

extends TextureRect

@export var day_bg: Texture2D   # 白天背景 (Bright)
@export var night_bg: Texture2D  # 夜晚背景 (Pale)

const TRANSITION_DURATION: float = 0.8
var _is_transitioning: bool = false

func _ready() -> void:
	# 默认显示白天背景
	texture = day_bg
	modulate.a = 1.0

	# 监听阶段切换信号
	SignalBus.cycle_phase_changed.connect(_on_phase_changed)


func _on_phase_changed(phase_name: String) -> void:
	if TimeCycle.current_phase == TimeCycle.Phase.NIGHT:
		_switch_to(night_bg)
	else:
		# DAY / DUSK → 白天背景
		_switch_to(day_bg)


func _switch_to(new_texture: Texture2D) -> void:
	if _is_transitioning:
		return
	if texture == new_texture:
		return

	_is_transitioning = true

	# 淡出
	var tween_out := create_tween()
	tween_out.tween_property(self, "modulate:a", 0.0, TRANSITION_DURATION / 2.0)
	tween_out.connect("finished", _on_transition_out_done.bind(new_texture))


func _on_transition_out_done(new_texture: Texture2D) -> void:
	# 切换纹理
	texture = new_texture

	# 淡入
	var tween_in := create_tween()
	tween_in.tween_property(self, "modulate:a", 1.0, TRANSITION_DURATION / 2.0)
	tween_in.connect("finished", _on_transition_in_done)


func _on_transition_in_done() -> void:
	_is_transitioning = false
