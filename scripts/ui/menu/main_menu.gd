## main_menu.gd
## 主菜单 — 杀戮尖塔2 风格暗色调
##   - 居中金属发光大标题 "Verge"（缓慢呼吸）
##   - 4 个按钮：主线模式 / 无尽模式 / 设置 / 退出游戏
##   - 悬停反馈：缩放 + 颜色提亮
## 按钮通过代码生成（布局简洁，避免冗长 .tscn），Theme 来自 MenuTheme。

extends Control

const CHAPTER_SELECT_SCENE := "res://scenes/menu/chapter_select.tscn"
const DEV_MSG: String = "正在开发中"

@onready var _buttons_container: VBoxContainer = $MenuContainer/Buttons


func _ready() -> void:
	# 暗色渐变背景 + 余烬粒子
	MenuTheme.add_background(self)

	# 标题呼吸（缩放微脉动）+ 副标题
	_animate_title()

	# 用 MenuTheme 的统一 Theme 给按钮容器（按钮会继承父级 Theme）
	_buttons_container.theme = MenuTheme.make_button_theme()
	_add_button("主线模式", _on_campaign)
	_add_button("无尽模式", _on_endless)
	_add_button("设置", _on_settings)
	_add_button("退出游戏", _on_quit)

	# 防止上局倍速残留
	Engine.time_scale = 1.0


func _animate_title() -> void:
	var title: Label = $MenuContainer/Title
	var subtitle: Label = $MenuContainer/Subtitle
	# 入场淡入
	title.modulate.a = 0.0
	subtitle.modulate.a = 0.0
	var intro := create_tween()
	intro.tween_property(title, "modulate:a", 1.0, 0.5)
	intro.tween_property(subtitle, "modulate:a", 1.0, 0.4)
	# 标题持续呼吸（modulate 亮度在 0.85 ↔ 1.0 循环）
	var breathe := create_tween().set_loops()
	breathe.tween_property(title, "modulate", Color(1.08, 1.02, 0.9), 2.4).set_trans(Tween.TRANS_SINE)
	breathe.tween_property(title, "modulate", Color(1.0, 1.0, 1.0), 2.4).set_trans(Tween.TRANS_SINE)


func _add_button(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(320, 56)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(callback)
	# 悬停缩放反馈（鼠标进入/离开）
	btn.mouse_entered.connect(func() -> void: _tween_scale(btn, 1.06))
	btn.mouse_exited.connect(func() -> void: _tween_scale(btn, 1.0))
	# 绑定按钮触碰和点击音效
	MenuTheme.attach_button_sfx(btn)
	_buttons_container.add_child(btn)
	return btn


func _tween_scale(btn: Button, target: float) -> void:
	if not is_instance_valid(btn):
		return
	# pivot 在中心，缩放才居中
	btn.pivot_offset = btn.size / 2.0
	var tw := create_tween()
	tw.tween_property(btn, "scale", Vector2(target, target), 0.12).set_trans(Tween.TRANS_SINE)


# ============ 按钮回调 ============
func _on_campaign() -> void:
	MenuTheme.change_scene(CHAPTER_SELECT_SCENE)


func _on_endless() -> void:
	MenuTheme.show_toast(self, DEV_MSG)


func _on_settings() -> void:
	MenuTheme.show_toast(self, DEV_MSG)


func _on_quit() -> void:
	get_tree().quit()
