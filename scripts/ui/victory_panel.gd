## victory_panel.gd
## 胜利结算面板 — 诗意标题 + 星级评定 + 结算数据 + 按钮
## 监听 game_won 信号

extends CanvasLayer

const CHAPTER_SELECT_SCENE := "res://scenes/menu/chapter_select.tscn"

const TITLES := {
	3: "守望终有回音",
	2: "夜色尚未退去",
	1: "黑暗中无人沉睡",
}

var _overlay: ColorRect
var _panel: Panel
var _title_label: Label
var _stars: Array = []
var _data_rows: Array = []
var _btn_row: HBoxContainer
var _next_btn: Button
var _is_open: bool = false


func _ready() -> void:
	layer = 180
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false
	SignalBus.game_won.connect(_on_game_won)


func _on_game_won() -> void:
	_show_victory()


# ============ UI 构建 ============
func _build_ui() -> void:
	var panel_size := Vector2(440, 560)
	var margin := 32

	# 1) 全屏遮罩
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.7)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	# 2) 居中面板
	_panel = Panel.new()
	_panel.size = panel_size
	_panel.position = Vector2(640 - panel_size.x / 2.0, 360 - panel_size.y / 2.0)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.07, 0.12, 0.97)
	sb.border_color = Color(1, 1, 1, 0.08)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	# 3) 标题（绝对定位）
	_title_label = Label.new()
	_title_label.text = ""
	_title_label.position = Vector2(margin, 20)
	_title_label.size = Vector2(panel_size.x - margin * 2, 50)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 30)
	_title_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	_panel.add_child(_title_label)

	# 4) 星级
	var star_container := HBoxContainer.new()
	star_container.position = Vector2(margin, 80)
	star_container.size = Vector2(panel_size.x - margin * 2, 50)
	star_container.alignment = BoxContainer.ALIGNMENT_CENTER
	star_container.add_theme_constant_override("separation", 20)
	_panel.add_child(star_container)
	for i in 3:
		var star := Label.new()
		star.text = "★"
		star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star.add_theme_font_size_override("font_size", 42)
		star.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
		_stars.append(star)
		star_container.add_child(star)

	# 5) 分割线
	var divider := ColorRect.new()
	divider.color = Color(1, 1, 1, 0.1)
	divider.position = Vector2(margin, 145)
	divider.size = Vector2(panel_size.x - margin * 2, 1)
	_panel.add_child(divider)

	# 6) 结算数据（5行）
	var data_labels := ["耗时", "核心剩余", "金币收入", "部署单位", "消灭敌人"]
	var data_y := 165
	for i in data_labels.size():
		var row := HBoxContainer.new()
		row.position = Vector2(margin, data_y + i * 30)
		row.size = Vector2(panel_size.x - margin * 2, 26)
		_panel.add_child(row)

		var label := Label.new()
		label.text = data_labels[i]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.62))
		row.add_child(label)

		var value := Label.new()
		value.text = "—"
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.add_theme_font_size_override("font_size", 16)
		value.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
		row.add_child(value)

		_data_rows.append({"row": row, "label": label, "value": value})

	# 7) 按钮组（绝对定位，放在面板底部）
	_btn_row = HBoxContainer.new()
	_btn_row.position = Vector2(margin, 470)
	_btn_row.size = Vector2(panel_size.x - margin * 2, 50)
	_btn_row.add_theme_constant_override("separation", 16)
	_btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(_btn_row)

	# 返回章节列表
	var back_btn := Button.new()
	back_btn.text = "返回章节列表"
	back_btn.custom_minimum_size = Vector2(170, 48)
	back_btn.add_theme_font_size_override("font_size", 18)
	_apply_secondary_style(back_btn)
	back_btn.pressed.connect(_on_return_chapters)
	_btn_row.add_child(back_btn)

	# 下一关（disabled）
	_next_btn = Button.new()
	_next_btn.text = "下一关 ▶"
	_next_btn.custom_minimum_size = Vector2(170, 48)
	_next_btn.add_theme_font_size_override("font_size", 18)
	_apply_primary_style(_next_btn)
	_next_btn.pressed.connect(_on_next_level)
	_next_btn.disabled = true
	_next_btn.tooltip_text = "通关解锁后开放"
	_btn_row.add_child(_next_btn)


# ============ 按钮样式 ============
func _apply_primary_style(btn: Button) -> void:
	var sb_n := StyleBoxFlat.new()
	sb_n.bg_color = Color(0.2, 0.5, 0.3)
	sb_n.border_color = Color(1, 1, 1, 0.15)
	sb_n.set_border_width_all(1)
	sb_n.set_corner_radius_all(8)
	sb_n.set_content_margin_all(12)
	btn.add_theme_stylebox_override("normal", sb_n)
	btn.add_theme_stylebox_override("hover", _make_hover(sb_n))
	btn.add_theme_stylebox_override("pressed", _make_pressed(sb_n))
	var sb_d := StyleBoxFlat.new()
	sb_d.bg_color = Color(0.15, 0.15, 0.18)
	sb_d.border_color = Color(0.3, 0.3, 0.3)
	sb_d.set_border_width_all(1)
	sb_d.set_corner_radius_all(8)
	sb_d.set_content_margin_all(12)
	btn.add_theme_stylebox_override("disabled", sb_d)
	btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))


func _apply_secondary_style(btn: Button) -> void:
	var sb_n := StyleBoxFlat.new()
	sb_n.bg_color = Color(0.12, 0.12, 0.16, 0.6)
	sb_n.border_color = Color(1, 1, 1, 0.2)
	sb_n.set_border_width_all(1)
	sb_n.set_corner_radius_all(8)
	sb_n.set_content_margin_all(12)
	btn.add_theme_stylebox_override("normal", sb_n)
	btn.add_theme_stylebox_override("hover", _make_hover(sb_n))
	btn.add_theme_stylebox_override("pressed", _make_pressed(sb_n))
	btn.add_theme_color_override("font_color", Color(0.92, 0.90, 0.85))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))


func _make_hover(base: StyleBoxFlat) -> StyleBoxFlat:
	var s := base.duplicate()
	s.bg_color = base.bg_color.lightened(0.12)
	s.border_color = Color(1, 1, 1, 0.3)
	return s


func _make_pressed(base: StyleBoxFlat) -> StyleBoxFlat:
	var s := base.duplicate()
	s.bg_color = base.bg_color.darkened(0.1)
	return s


# ============ 显示胜利结算 ============
func _show_victory() -> void:
	if _is_open:
		return
	_is_open = true

	var hp_percent := _get_core_hp_percent()
	var star_count := 1
	if hp_percent > 0.5:
		star_count = 3
	elif hp_percent > 0.2:
		star_count = 2
	var title_text: String = TITLES.get(star_count, TITLES[1])

	var elapsed := Time.get_ticks_msec() / 1000.0 - GameManager.level_start_time
	var mins := int(elapsed) / 60
	var secs := int(elapsed) % 60
	_data_rows[0].value.text = "%d:%02d" % [mins, secs]
	_data_rows[1].value.text = "%.0f%%" % (hp_percent * 100)
	_data_rows[2].value.text = "%d 金" % GameManager.total_gold_earned
	_data_rows[3].value.text = "%d 个" % GameManager.total_deployed
	_data_rows[4].value.text = "%d 只" % GameManager.total_kills

	_title_label.text = title_text

	# 星星
	for i in 3:
		if i < star_count:
			_stars[i].add_theme_color_override("font_color", Color(1.0, 0.84, 0.36))
		else:
			_stars[i].add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))

	visible = true

	# 暂停
	GameManager.set_paused(true)
	Engine.time_scale = 0.0

	print("[Victory] 胜利结算 — 星级=%d, 核心=%.0f%%" % [star_count, hp_percent * 100])


# ============ 获取核心HP ============
func _get_core_hp_percent() -> float:
	var scene := get_tree().current_scene
	if not scene:
		return 1.0
	var core := scene.find_child("Core", true, false)
	if not core:
		return 1.0
	if not ("current_hp" in core) or not ("max_hp" in core):
		return 1.0
	var hp_val = core.get("current_hp")
	var max_val = core.get("max_hp")
	if hp_val == null or max_val == null:
		return 1.0
	var hp: float = float(hp_val)
	var max_hp: float = float(max_val)
	if max_hp <= 0:
		return 0.0
	return clampf(hp / max_hp, 0.0, 1.0)


# ============ 按钮回调 ============
func _on_return_chapters() -> void:
	print("[Victory] 返回章节列表")
	_reset_and_change_scene(CHAPTER_SELECT_SCENE)


func _on_next_level() -> void:
	pass


func _reset_and_change_scene(scene_path: String) -> void:
	GameManager.set_paused(false)
	Engine.time_scale = 1.0
	GameManager.current_day = 1
	GameManager.is_game_over = false
	GameManager.is_game_won = false
	GameManager.is_paused = false
	GameManager.perfect_clear = false
	GameManager.total_gold_earned = 0
	GameManager.total_deployed = 0
	GameManager.total_kills = 0
	if TimeCycle.has_method("reset_state"):
		TimeCycle.reset_state()
	if Economy.has_method("reset_state"):
		Economy.reset_state()
	# 返回菜单时切换为主界面 BGM
	AudioManager.play_bgm("menu")
	get_tree().change_scene_to_file(scene_path)


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_close_panel()
		get_viewport().set_input_as_handled()


func _close_panel() -> void:
	_is_open = false
	visible = false
	var pm := get_tree().current_scene.find_child("PauseMenu", true, false) if get_tree().current_scene else null
	if pm and pm.has_method("open"):
		pm.open()
