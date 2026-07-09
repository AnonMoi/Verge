## 启动画面 — 先展示独立黑屏免责声明卡片，再进入正式启动标题，随后自动切到主菜单/序章。
## 启动页保留任意键 / 鼠标点击跳过。

extends Control

const MAIN_MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const STORY_PLAYER_SCENE := "res://scenes/story/story_player.tscn"
const DISCLAIMER_FADE_IN: float = 0.5
const DISCLAIMER_HOLD: float = 1.4
const DISCLAIMER_FADE_OUT: float = 0.5
const SPLASH_INTRO_TIME: float = 1.8
const WAIT_TIME: float = DISCLAIMER_FADE_IN + DISCLAIMER_HOLD + DISCLAIMER_FADE_OUT + SPLASH_INTRO_TIME

var _elapsed: float = 0.0
var _disclaimer_layer: CanvasLayer
var _disclaimer_root: Control
var _disclaimer_finished: bool = false


func _ready() -> void:
	# 暗色渐变背景 + 余烬粒子（与主菜单同源，保证衔接顺滑）
	MenuTheme.add_background(self)

	# 播放主菜单 BGM
	AudioManager.play_bgm("menu")

	# 居中大标题 "Verge"（金属发光 + 描边）
	var title := MenuTheme.make_title("Verge")
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.modulate.a = 0.0
	title.scale = Vector2(0.85, 0.85)
	add_child(title)

	# 副标题（在标题下方，使用 PRESET_CENTER + Y 偏移，避免与标题垂直重叠）
	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "钟摆未眠，黎明将至"
	subtitle.set_anchors_preset(Control.PRESET_CENTER)
	subtitle.position = Vector2(-160, 70)
	subtitle.custom_minimum_size = Vector2(320, 40)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", MenuTheme.TEXT_DIM)
	subtitle.modulate.a = 0.0
	add_child(subtitle)

	_build_disclaimer_layer()
	_play_disclaimer(title, subtitle)

	# 确保 Engine.time_scale 是正常的（防止上局倍速残留）
	Engine.time_scale = 1.0


func _build_disclaimer_layer() -> void:
	_disclaimer_layer = CanvasLayer.new()
	_disclaimer_layer.layer = 300
	add_child(_disclaimer_layer)

	_disclaimer_root = Control.new()
	_disclaimer_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_disclaimer_root.modulate.a = 0.0
	_disclaimer_layer.add_child(_disclaimer_root)

	var disclaimer_bg := ColorRect.new()
	disclaimer_bg.color = Color(0, 0, 0, 1)
	disclaimer_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_disclaimer_root.add_child(disclaimer_bg)

	var disclaimer_label := Label.new()
	disclaimer_label.name = "Disclaimer"
	disclaimer_label.text = "本作品仅供课程展示与体验\n并非完整开发版本"
	disclaimer_label.set_anchors_preset(Control.PRESET_CENTER)
	disclaimer_label.offset_left = -320.0
	disclaimer_label.offset_top = -40.0
	disclaimer_label.offset_right = 320.0
	disclaimer_label.offset_bottom = 40.0
	disclaimer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	disclaimer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	disclaimer_label.add_theme_font_size_override("font_size", 24)
	disclaimer_label.add_theme_color_override("font_color", Color(0.82, 0.79, 0.75, 0.96))
	disclaimer_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03, 1.0))
	disclaimer_label.add_theme_constant_override("outline_size", 4)
	_disclaimer_root.add_child(disclaimer_label)


func _play_disclaimer(title: Label, subtitle: Label) -> void:
	var tween := create_tween()
	tween.tween_property(_disclaimer_root, "modulate:a", 1.0, DISCLAIMER_FADE_IN)
	tween.tween_interval(DISCLAIMER_HOLD)
	tween.tween_property(_disclaimer_root, "modulate:a", 0.0, DISCLAIMER_FADE_OUT)
	tween.tween_callback(func() -> void:
		_disclaimer_finished = true
		if is_instance_valid(_disclaimer_layer):
			_disclaimer_layer.queue_free()
		var intro := create_tween()
		intro.tween_property(title, "modulate:a", 1.0, 0.7)
		intro.parallel().tween_property(title, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_BACK)
		intro.parallel().tween_property(subtitle, "modulate:a", 1.0, 0.45).set_delay(0.35)
	)


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= WAIT_TIME and _disclaimer_finished:
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
	set_process(false)
	set_process_unhandled_input(false)
	# 首次启动:先播序章世界观;后续启动直接进主菜单
	if not MenuTheme.prologue_watched:
		MenuTheme.start_story(StoryData.PROLOGUE, MAIN_MENU_SCENE, STORY_PLAYER_SCENE, "Chapter 0 - 序章")
	else:
		MenuTheme.change_scene(MAIN_MENU_SCENE)
