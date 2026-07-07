## pause_menu.gd
## 暂停菜单 — 与胜利/失败面板同构的布局方式
## 三个页面（主菜单/设置/确认）共用一个 panel，通过显示/隐藏切换，不叠加层
##
## 重要：
## 1. 暂停时 Engine.time_scale = 0，不用 Tween，所有状态立即设置
## 2. process_mode = ALWAYS，暂停时按钮仍可点击
## 3. 三个页面互斥显示，不存在"看不见的层挡住按钮"的问题

extends CanvasLayer

const MAIN_MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const CHAPTER_SELECT_SCENE := "res://scenes/menu/chapter_select.tscn"

var _saved_time_scale: float = 1.0
var _is_open: bool = false

var _overlay: ColorRect
var _panel: Panel
# 三个页面容器（同时只有一个 visible）
var _page_main: VBoxContainer
var _page_settings: VBoxContainer
var _page_confirm: VBoxContainer
var _confirm_msg: Label

var _pending_confirm_callback: Callable = Callable()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 150
	_build_ui()
	_go_page_main()
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _is_open:
			_close()
		else:
			open()
		get_viewport().set_input_as_handled()


# ============ 打开 / 关闭 ============
func open() -> void:
	if _is_open:
		return
	if GameManager.is_game_over or GameManager.is_game_won:
		return
	_is_open = true
	_saved_time_scale = Engine.time_scale
	Engine.time_scale = 1.0
	_go_page_main()
	visible = true
	get_tree().paused = true
	GameManager.is_paused = true
	# 暂停 BGM（SFX 不受影响）
	AudioManager.set_bgm_paused(true)


func _close() -> void:
	if not _is_open:
		visible = false
		return
	_is_open = false
	get_tree().paused = false
	GameManager.is_paused = false
	Engine.time_scale = _saved_time_scale
	visible = false
	# 恢复 BGM
	AudioManager.set_bgm_paused(false)


# ============ 页面切换（互斥，不叠加）============
func _show_page(page: VBoxContainer) -> void:
	# 显示的页面：可见 + 允许鼠标事件
	_page_main.visible = (page == _page_main)
	_page_settings.visible = (page == _page_settings)
	_page_confirm.visible = (page == _page_confirm)
	# ⚠️ 关键：隐藏的页面必须设 MOUSE_FILTER_IGNORE，
	# 否则 Godot 4.x 中 visible=false 的 Control 仍可能拦截鼠标 → 挡住按钮
	_set_page_input(_page_main, page == _page_main)
	_set_page_input(_page_settings, page == _page_settings)
	_set_page_input(_page_confirm, page == _page_confirm)


func _set_page_input(page: VBoxContainer, active: bool) -> void:
	if active:
		page.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		page.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _go_page_main() -> void:
	_show_page(_page_main)


func _go_page_settings() -> void:
	_show_page(_page_settings)


func _go_page_confirm(msg: String, cb: Callable) -> void:
	_confirm_msg.text = msg
	_pending_confirm_callback = cb
	_show_page(_page_confirm)


# ============ UI 构建 ============
func _build_ui() -> void:
	var panel_size := Vector2(340, 400)

	# 1) 全屏遮罩
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.7)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)

	# 2) 居中面板
	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.size = panel_size
	_panel.custom_minimum_size = panel_size
	_panel.position = -panel_size / 2.0
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.14, 0.97)
	sb.border_color = Color(1, 1, 1, 0.12)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(24.0)
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	# 3) 内容容器（撑满 panel 的内容区）
	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 24
	content.offset_top = 24
	content.offset_right = -24
	content.offset_bottom = -24
	content.add_theme_constant_override("separation", 12)
	_panel.add_child(content)

	# 4) 三个页面（都是 VBoxContainer，同时只有一个可见）
	_page_main = _build_page_main()
	_page_settings = _build_page_settings()
	_page_confirm = _build_page_confirm()
	content.add_child(_page_main)
	content.add_child(_page_settings)
	content.add_child(_page_confirm)


# ============ 页面：主菜单 ============
func _build_page_main() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 12)
	page.alignment = BoxContainer.ALIGNMENT_CENTER

	# 标题
	var title := Label.new()
	title.text = "已暂停"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.92, 0.90, 0.85))
	page.add_child(title)

	# 按钮（ALIGNMENT_CENTER 会自动把内容居中，不需要 spacer）
	var btn_continue := _make_button("继续游戏", Color(0.2, 0.55, 0.3), true)
	btn_continue.pressed.connect(_on_continue_pressed)
	page.add_child(btn_continue)

	var btn_settings := _make_button("设置", Color(0.18, 0.18, 0.24), false)
	btn_settings.pressed.connect(_on_settings_pressed)
	page.add_child(btn_settings)

	var btn_chapters := _make_button("返回章节选择", Color(0.18, 0.18, 0.24), false)
	btn_chapters.pressed.connect(_on_return_chapters_pressed)
	page.add_child(btn_chapters)

	var btn_main := _make_button("返回主菜单", Color(0.4, 0.15, 0.15), false)
	btn_main.pressed.connect(_on_return_main_pressed)
	page.add_child(btn_main)

	return page


# ============ 页面：设置 ============
func _build_page_settings() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 12)
	page.alignment = BoxContainer.ALIGNMENT_CENTER
	page.visible = false

	var title := Label.new()
	title.text = "设置"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.92, 0.90, 0.85))
	page.add_child(title)

	var info := Label.new()
	info.text = "音效 / 音乐设置\n\n（开发中）"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 18)
	info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	page.add_child(info)

	var back_btn := _make_button("← 返回", Color(0.18, 0.18, 0.24), true)
	back_btn.pressed.connect(_on_settings_back_pressed)
	page.add_child(back_btn)

	return page


# ============ 页面：确认弹窗 ============
func _build_page_confirm() -> VBoxContainer:
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 16)
	page.alignment = BoxContainer.ALIGNMENT_CENTER
	page.visible = false

	# 提示文字
	_confirm_msg = Label.new()
	_confirm_msg.text = ""
	_confirm_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_confirm_msg.add_theme_font_size_override("font_size", 18)
	_confirm_msg.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	page.add_child(_confirm_msg)

	# 按钮行
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 16)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	page.add_child(btn_row)

	var btn_yes := _make_button("确认", Color(0.4, 0.2, 0.2), true)
	btn_yes.custom_minimum_size = Vector2(130, 44)
	btn_yes.pressed.connect(_on_confirm_yes_pressed)
	btn_row.add_child(btn_yes)

	var btn_no := _make_button("取消", Color(0.25, 0.25, 0.3), false)
	btn_no.custom_minimum_size = Vector2(130, 44)
	btn_no.pressed.connect(_on_confirm_cancel_pressed)
	btn_row.add_child(btn_no)

	return page


# ============ 工具 ============
func _make_button(text: String, bg_color: Color, primary: bool) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(290, 48)
	btn.process_mode = Node.PROCESS_MODE_ALWAYS  # 暂停时可点击
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))

	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = bg_color
	sb_normal.border_color = Color(1, 1, 1, 0.3) if primary else Color(1, 1, 1, 0.08)
	sb_normal.set_border_width_all(1)
	sb_normal.set_corner_radius_all(10)
	sb_normal.content_margin_left = 16
	sb_normal.content_margin_right = 16
	sb_normal.content_margin_top = 10
	sb_normal.content_margin_bottom = 10
	btn.add_theme_stylebox_override("normal", sb_normal)

	var sb_hover := sb_normal.duplicate()
	sb_hover.bg_color = bg_color.lightened(0.15)
	sb_hover.border_color = Color(1, 1, 1, 0.4)
	btn.add_theme_stylebox_override("hover", sb_hover)

	var sb_pressed := sb_normal.duplicate()
	sb_pressed.bg_color = bg_color.darkened(0.1)
	btn.add_theme_stylebox_override("pressed", sb_pressed)

	return btn


# ============ 按钮回调 ============
func _on_continue_pressed() -> void:
	print("[PauseMenu] 继续游戏")
	_close()


func _on_settings_pressed() -> void:
	print("[PauseMenu] 设置")
	_go_page_settings()


func _on_settings_back_pressed() -> void:
	print("[PauseMenu] 设置←返回")
	_go_page_main()


func _on_return_chapters_pressed() -> void:
	print("[PauseMenu] 返回章节选择（请求确认）")
	_go_page_confirm("确定要返回章节选择吗？\n当前进度将丢失。", _do_return_chapters)


func _on_return_main_pressed() -> void:
	print("[PauseMenu] 返回主菜单（请求确认）")
	_go_page_confirm("确定要返回主菜单吗？\n当前进度将丢失。", _do_return_main_menu)


func _on_confirm_yes_pressed() -> void:
	print("[PauseMenu] 确认弹窗 → 确认")
	var cb := _pending_confirm_callback
	_pending_confirm_callback = Callable()
	if cb.is_valid():
		cb.call()


func _on_confirm_cancel_pressed() -> void:
	print("[PauseMenu] 确认弹窗 → 取消")
	_pending_confirm_callback = Callable()
	_go_page_main()


# ============ 场景切换 ============
func _do_return_chapters() -> void:
	_reset_global_state()
	_do_change_scene.call_deferred(CHAPTER_SELECT_SCENE)


func _do_return_main_menu() -> void:
	_reset_global_state()
	_do_change_scene.call_deferred(MAIN_MENU_SCENE)


func _do_change_scene(path: String) -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	GameManager.is_paused = false
	# 返回菜单时切换为主界面 BGM
	AudioManager.play_bgm("menu")
	get_tree().change_scene_to_file(path)


func _reset_global_state() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	GameManager.is_paused = false
	GameManager.is_game_over = false
	GameManager.is_game_won = false
	GameManager.current_day = 1
	GameManager.total_gold_earned = 0
	GameManager.total_deployed = 0
	GameManager.total_kills = 0
	if TimeCycle.has_method("reset_state"):
		TimeCycle.reset_state()
	if Economy.has_method("reset_state"):
		Economy.reset_state()
