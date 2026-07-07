## game_over_panel.gd
## 失败结算面板 — 诗意标题 + 失败数据 + 按钮（与胜利面板同构）
## 监听 core_destroyed / game_over 信号
## 注意：不用 Tween（Engine.time_scale=0 时 Tween 不推进，见 progress.md 陷阱 4.1）

extends CanvasLayer

const CHAPTER_SELECT_SCENE := "res://scenes/menu/chapter_select.tscn"

# 失败标题文案（根据坚持到的天数）
const TITLES := {
	1: "第一夜便已失守",      # Day 1 就失败
	2: "守候止于次夜",        # Day 2 失败
	3: "黎明前最后的溃败",    # Day 3 失败（最接近胜利）
}

var _overlay: ColorRect
var _panel: Panel
var _title_label: Label
var _subtitle_label: Label
var _data_rows: Array = []
var _btn_row: HBoxContainer
var _is_open: bool = false


func _ready() -> void:
	layer = 200  # 在暂停菜单(150)和胜利面板(180)之上
	process_mode = Node.PROCESS_MODE_ALWAYS  # 暂停时也能响应按钮
	_build_ui()
	visible = false
	SignalBus.core_destroyed.connect(_on_core_destroyed)
	SignalBus.game_over.connect(_on_game_over)


# ============ 信号回调 ============
func _on_core_destroyed() -> void:
	_show_game_over()

func _on_game_over() -> void:
	_show_game_over()


# ============ UI 构建 ============
func _build_ui() -> void:
	var panel_size := Vector2(440, 520)
	var margin := 32

	# 1) 全屏遮罩
	_overlay = ColorRect.new()
	_overlay.color = Color(0.1, 0.0, 0.0, 0.75)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	# 2) 居中面板（绝对坐标）
	_panel = Panel.new()
	_panel.size = panel_size
	_panel.position = Vector2(640 - panel_size.x / 2.0, 360 - panel_size.y / 2.0)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.05, 0.07, 0.97)
	sb.border_color = Color(0.6, 0.15, 0.15, 0.4)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	# 3) 标题
	_title_label = Label.new()
	_title_label.text = ""
	_title_label.position = Vector2(margin, 20)
	_title_label.size = Vector2(panel_size.x - margin * 2, 50)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 30)
	_title_label.add_theme_color_override("font_color", Color(0.95, 0.35, 0.35))
	_panel.add_child(_title_label)

	# 4) 副标题
	_subtitle_label = Label.new()
	_subtitle_label.text = "— 核心被摧毁 · 守候失败 —"
	_subtitle_label.position = Vector2(margin, 72)
	_subtitle_label.size = Vector2(panel_size.x - margin * 2, 24)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.add_theme_font_size_override("font_size", 16)
	_subtitle_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.72))
	_panel.add_child(_subtitle_label)

	# 5) 分割线
	var divider := ColorRect.new()
	divider.color = Color(0.6, 0.15, 0.15, 0.25)
	divider.position = Vector2(margin, 110)
	divider.size = Vector2(panel_size.x - margin * 2, 1)
	_panel.add_child(divider)

	# 6) 失败数据（5行）
	var data_labels := ["坚持天数", "坚持时长", "消灭敌人", "部署单位", "核心剩余"]
	var data_y := 130
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

	# 7) 按钮组（绝对定位，底部）
	_btn_row = HBoxContainer.new()
	_btn_row.position = Vector2(margin, 430)
	_btn_row.size = Vector2(panel_size.x - margin * 2, 50)
	_btn_row.add_theme_constant_override("separation", 16)
	_btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(_btn_row)

	# 重新开始（主按钮，红色调）
	var restart_btn := Button.new()
	restart_btn.text = "重新开始"
	restart_btn.custom_minimum_size = Vector2(170, 48)
	restart_btn.add_theme_font_size_override("font_size", 18)
	_apply_restart_style(restart_btn)
	restart_btn.pressed.connect(_on_restart)
	restart_btn.process_mode = Node.PROCESS_MODE_ALWAYS  # 暂停时可点击
	_btn_row.add_child(restart_btn)

	# 返回章节列表（次按钮）
	var back_btn := Button.new()
	back_btn.text = "返回章节列表"
	back_btn.custom_minimum_size = Vector2(170, 48)
	back_btn.add_theme_font_size_override("font_size", 18)
	_apply_secondary_style(back_btn)
	back_btn.pressed.connect(_on_return_chapters)
	back_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_btn_row.add_child(back_btn)


# ============ 按钮样式 ============
func _apply_restart_style(btn: Button) -> void:
	var sb_n := StyleBoxFlat.new()
	sb_n.bg_color = Color(0.5, 0.15, 0.15)
	sb_n.border_color = Color(1, 1, 1, 0.15)
	sb_n.set_border_width_all(1)
	sb_n.set_corner_radius_all(8)
	sb_n.set_content_margin_all(12)
	btn.add_theme_stylebox_override("normal", sb_n)
	btn.add_theme_stylebox_override("hover", _make_hover(sb_n))
	btn.add_theme_stylebox_override("pressed", _make_pressed(sb_n))
	btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))


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


# ============ 显示失败结算 ============
func _show_game_over() -> void:
	if _is_open:
		return
	_is_open = true

	# 计算标题（根据当前天数）
	var day := GameManager.current_day
	var title_text: String = TITLES.get(day, TITLES[1])

	# 填充失败数据
	var elapsed := Time.get_ticks_msec() / 1000.0 - GameManager.level_start_time
	var mins := int(elapsed) / 60
	var secs := int(elapsed) % 60
	var hp_percent := _get_core_hp_percent()

	_data_rows[0].value.text = "第 %d 天" % day
	_data_rows[1].value.text = "%d:%02d" % [mins, secs]
	_data_rows[2].value.text = "%d 只" % GameManager.total_kills
	_data_rows[3].value.text = "%d 个" % GameManager.total_deployed
	_data_rows[4].value.text = "%.0f%%" % (hp_percent * 100)

	_title_label.text = title_text

	# 立即显示
	visible = true

	# 暂停游戏
	GameManager.set_paused(true)
	Engine.time_scale = 0.0
	_pause_all_characters_and_enemies()

	print("[GameOver] 钟摆已停摆 — 守候失败, 第%d天" % day)


# ============ 获取核心HP百分比 ============
func _get_core_hp_percent() -> float:
	var scene := get_tree().current_scene
	if not scene:
		return 0.0
	var core := scene.find_child("Core", true, false)
	if not core:
		return 0.0
	if not ("current_hp" in core) or not ("max_hp" in core):
		return 0.0
	var hp_val = core.get("current_hp")
	var max_val = core.get("max_hp")
	if hp_val == null or max_val == null:
		return 0.0
	var hp: float = float(hp_val)
	var max_hp: float = float(max_val)
	if max_hp <= 0:
		return 0.0
	return clampf(hp / max_hp, 0.0, 1.0)


## 让所有敌人和角色的 process_mode 设为 DISABLED
func _pause_all_characters_and_enemies() -> void:
	var root := get_tree().current_scene
	if not root:
		return
	for container_name in ["Enemies", "Characters"]:
		var container := root.find_child(container_name, false, false)
		if not container:
			continue
		for child in container.get_children():
			child.process_mode = Node.PROCESS_MODE_DISABLED


# ============ 按钮回调 ============
func _on_restart() -> void:
	_reset_global_state()
	get_tree().reload_current_scene()


func _on_return_chapters() -> void:
	_reset_global_state()
	# 延后一帧切场景（避免暂停状态竞争）
	_do_change_scene.call_deferred(CHAPTER_SELECT_SCENE)


func _do_change_scene(path: String) -> void:
	Engine.time_scale = 1.0
	GameManager.is_paused = false
	# 返回菜单时切换为主界面 BGM
	AudioManager.play_bgm("menu")
	get_tree().change_scene_to_file(path)


func _reset_global_state() -> void:
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


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_on_restart()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			_on_return_chapters()
			get_viewport().set_input_as_handled()
