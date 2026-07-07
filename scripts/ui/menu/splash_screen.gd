## splash_screen.gd
## 启动画面 — 展示游戏标题 "Verge"，淡入后持续约 2.5 秒，自动切到主菜单。
## 按任意键 / 鼠标点击可跳过。

extends Control

const MAIN_MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const WAIT_TIME: float = 2.5  # 总展示时长（秒）

var _elapsed: float = 0.0


func _ready() -> void:
	# 暗色渐变背景 + 余烬粒子（与主菜单同源，保证衔接顺滑）
	MenuTheme.add_background(self)

	# 播放主菜单 BGM
	AudioManager.play_bgm("menu")

	# 居中大标题 "Verge"（金属发光 + 描边）
	var title := MenuTheme.make_title("Verge")
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(title)

	# 副标题（在标题下方，使用 PRESET_CENTER + Y 偏移，避免与标题垂直重叠）
	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "钟摆未眠，黎明将至"
	subtitle.set_anchors_preset(Control.PRESET_CENTER)
	# 标题高度约 92px，副标题在标题底部下方约 40px 处
	subtitle.position = Vector2(-160, 70)
	subtitle.custom_minimum_size = Vector2(320, 40)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", MenuTheme.TEXT_DIM)
	add_child(subtitle)

	# 入场动画：标题从透明 + 放大 → 正常
	title.modulate.a = 0.0
	title.scale = Vector2(0.85, 0.85)
	var tween := create_tween()
	tween.tween_property(title, "modulate:a", 1.0, 0.6)
	tween.parallel().tween_property(title, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK)

	# 确保 Engine.time_scale 是正常的（防止上局倍速残留）
	Engine.time_scale = 1.0


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= WAIT_TIME:
		_go_to_menu()


func _unhandled_input(event: InputEvent) -> void:
	# 跳过：任意按键 或 鼠标点击
	if _elapsed < 0.4:  # 入场 0.4s 内不响应，避免误触
		return
	var is_skip := false
	if event is InputEventKey and event.pressed:
		is_skip = true
	elif event is InputEventMouseButton and event.pressed:
		is_skip = true
	if is_skip:
		_go_to_menu()


func _go_to_menu() -> void:
	set_process(false)          # 防止重复触发
	set_process_unhandled_input(false)
	MenuTheme.change_scene(MAIN_MENU_SCENE)
