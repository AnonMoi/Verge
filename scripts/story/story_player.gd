## story_player.gd
## 通用剧情播放器 — 黑屏 + 打字机文字
## 播放 MenuTheme.pending_story_id 对应的剧情,结束后跳转 pending_story_next_scene
## 交互:任意键/点击推进;打字机进行中点击则瞬间显示完整;右上角可跳过
## 类型:title(标题,居中大字淡入) / narration(旁白) / dialogue(对话,带角色名)

extends Control

# ---------- 配色(与 MenuTheme 暗色调一致) ----------
const COLOR_BG := Color(0, 0, 0, 1)
const COLOR_TITLE := Color(1.0, 0.86, 0.46)        # 亮金(同 MenuTheme.ACCENT_BRIGHT)
const COLOR_NARRATION := Color(0.82, 0.80, 0.76)   # 暖白偏暗
const COLOR_TEXT_DIALOGUE := Color(0.92, 0.90, 0.85)
const COLOR_KANE := Color(0.70, 0.85, 1.0)         # 主角冷蓝
const COLOR_RITA := Color(1.0, 0.75, 0.55)         # 丽塔暖橙
const COLOR_CONTINUE := Color(0.52, 0.50, 0.47)    # 灰

const TYPEWRITER_INTERVAL: float = 0.03  # 每字符 30ms

# ---------- 运行时状态 ----------
var _frames: Array = []
var _current_index: int = 0
var _is_typing: bool = false
var _can_advance: bool = true  # 标题淡入期间短暂锁定

# ---------- UI 节点 ----------
var _bg: ColorRect
var _speaker_label: Label
var _text_label: Label
var _continue_hint: Label
var _skip_button: Button
var _typewriter_timer: Timer


func _ready() -> void:
	Engine.time_scale = 1.0
	_build_ui()
	_load_story()
	if _frames.is_empty():
		_finish_story()
		return
	_show_frame(0)


# ============ UI 构建 ============
func _build_ui() -> void:
	# 全屏黑背景
	_bg = ColorRect.new()
	_bg.color = COLOR_BG
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	# 角色名(中上部,左对齐)
	_speaker_label = Label.new()
	_speaker_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_speaker_label.offset_left = 120.0
	_speaker_label.offset_top = 210.0
	_speaker_label.offset_right = -120.0
	_speaker_label.offset_bottom = 260.0
	_speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_speaker_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_speaker_label.add_theme_font_size_override("font_size", 28)
	add_child(_speaker_label)

	# 正文(旁白/对话/标题共用,自动换行)
	_text_label = Label.new()
	_text_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_text_label.offset_left = 120.0
	_text_label.offset_top = 270.0
	_text_label.offset_right = -120.0
	_text_label.offset_bottom = 540.0
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_font_size_override("font_size", 22)
	_text_label.add_theme_color_override("font_color", COLOR_NARRATION)
	add_child(_text_label)

	# "点击继续" 提示(底部居中,闪烁)
	_continue_hint = Label.new()
	_continue_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_continue_hint.offset_left = -100.0
	_continue_hint.offset_top = -60.0
	_continue_hint.offset_right = 100.0
	_continue_hint.offset_bottom = -28.0
	_continue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_continue_hint.text = "点击继续 ▼"
	_continue_hint.add_theme_font_size_override("font_size", 18)
	_continue_hint.add_theme_color_override("font_color", COLOR_CONTINUE)
	add_child(_continue_hint)

	# 闪烁动画
	var tw := create_tween().set_loops()
	tw.tween_property(_continue_hint, "modulate:a", 0.3, 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_continue_hint, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)

	# 跳过按钮(右上角)
	_skip_button = Button.new()
	_skip_button.text = "跳过 >>"
	_skip_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_skip_button.offset_left = -130.0
	_skip_button.offset_top = 20.0
	_skip_button.offset_right = -20.0
	_skip_button.offset_bottom = 56.0
	_skip_button.add_theme_font_size_override("font_size", 16)
	_skip_button.pressed.connect(_on_skip)
	MenuTheme.attach_button_sfx(_skip_button)
	add_child(_skip_button)

	# 打字机计时器
	_typewriter_timer = Timer.new()
	_typewriter_timer.wait_time = TYPEWRITER_INTERVAL
	_typewriter_timer.one_shot = false
	_typewriter_timer.timeout.connect(_on_typewriter_tick)
	add_child(_typewriter_timer)


# ============ 剧情加载 ============
func _load_story() -> void:
	var story_id: String = MenuTheme.pending_story_id
	_frames = StoryData.get_story(story_id)


# ============ 帧播放 ============
func _show_frame(index: int) -> void:
	if index >= _frames.size():
		_finish_story()
		return
	_current_index = index
	_can_advance = false
	_speaker_label.visible = false

	var frame: Dictionary = _frames[index]
	var frame_type: String = frame.get("type", "narration")
	var text: String = frame.get("text", "")

	match frame_type:
		"title":
			_play_title(text)
		"dialogue":
			_play_dialogue(frame.get("speaker", ""), text)
		_:
			_play_narration(text)


## 标题:居中大字,淡入,短锁后可推进
func _play_title(text: String) -> void:
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text_label.add_theme_font_size_override("font_size", 44)
	_text_label.add_theme_color_override("font_color", COLOR_TITLE)
	_text_label.text = text
	_text_label.visible_characters = -1
	_text_label.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_text_label, "modulate:a", 1.0, 0.8)
	tw.tween_callback(func() -> void: _can_advance = true)


## 旁白:左对齐,打字机
func _play_narration(text: String) -> void:
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_text_label.add_theme_font_size_override("font_size", 22)
	_text_label.add_theme_color_override("font_color", COLOR_NARRATION)
	_start_typewriter(text)
	_can_advance = true


## 对话:角色名 + 正文,打字机
func _play_dialogue(speaker: String, text: String) -> void:
	_speaker_label.text = speaker
	_speaker_label.visible = true
	match speaker:
		"Kane":
			_speaker_label.add_theme_color_override("font_color", COLOR_KANE)
		"丽塔":
			_speaker_label.add_theme_color_override("font_color", COLOR_RITA)
		_:
			_speaker_label.add_theme_color_override("font_color", COLOR_NARRATION)

	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_text_label.add_theme_font_size_override("font_size", 22)
	_text_label.add_theme_color_override("font_color", COLOR_TEXT_DIALOGUE)
	_start_typewriter(text)
	_can_advance = true


# ============ 打字机 ============
func _start_typewriter(text: String) -> void:
	_text_label.text = text
	_text_label.visible_characters = 0
	_is_typing = true
	_typewriter_timer.start()


func _on_typewriter_tick() -> void:
	_text_label.visible_characters += 1
	if _text_label.visible_characters >= _text_label.get_total_character_count():
		_typewriter_timer.stop()
		_is_typing = false


# ============ 输入:推进 / 瞬显 / 跳过 ============
func _unhandled_input(event: InputEvent) -> void:
	if not _can_advance:
		return
	var is_advance := false
	if event is InputEventKey and event.pressed:
		is_advance = true
	elif event is InputEventMouseButton and event.pressed:
		is_advance = true
	if is_advance:
		_advance()


func _advance() -> void:
	if _is_typing:
		# 打字机进行中:瞬间显示完整文本
		_typewriter_timer.stop()
		_text_label.visible_characters = -1
		_is_typing = false
		return
	_show_frame(_current_index + 1)


func _on_skip() -> void:
	_finish_story()


# ============ 结束:标记 + 跳转 ============
func _finish_story() -> void:
	_typewriter_timer.stop()
	set_process_unhandled_input(false)
	# 序章标记为已看(后续启动直接进主菜单)
	if MenuTheme.pending_story_id == StoryData.PROLOGUE:
		MenuTheme.prologue_watched = true
	# 跳转到下一个场景(默认回主菜单)
	var next: String = MenuTheme.pending_story_next_scene
	if next == "":
		next = "res://scenes/menu/main_menu.tscn"
	MenuTheme.change_scene(next)
