## 通用剧情播放器 — 黑屏章节卡片 + 发言人铭牌 + 打字机文字
## 播放 MenuTheme.pending_story_id 对应的剧情，结束后跳转 pending_story_next_scene
## 交互：仅左键推进；打字机进行中点击则瞬间显示完整；右上角可跳过
## 类型：title(旧标题帧，现按旁白显示) / narration(旁白) / dialogue(对话，带角色名)

extends Control

# ---------- 配色 ----------
const COLOR_BG := Color(0, 0, 0, 1)
const COLOR_TITLE := Color(1.0, 0.86, 0.46)
const COLOR_NARRATION := Color(0.82, 0.80, 0.76)
const COLOR_TEXT_DIALOGUE := Color(1.0, 0.96, 0.84)

const COLOR_KANE := Color(0.70, 0.85, 1.0)
const COLOR_RITA := Color(1.0, 0.75, 0.55)
const COLOR_CONTINUE := Color(0.52, 0.50, 0.47)
const COLOR_NAMEPLATE_BG := Color(0.12, 0.10, 0.08, 0.92)
const COLOR_NAMEPLATE_BORDER := Color(0.70, 0.58, 0.32, 0.95)
const COLOR_DIALOGUE_BOX_BG := Color(0.045, 0.035, 0.028, 0.94)
const COLOR_DIALOGUE_BOX_BORDER := Color(0.82, 0.66, 0.32, 0.95)


const TYPEWRITER_INTERVAL: float = 0.028
const FRAME_FADE_TIME: float = 0.22
const CHAPTER_CARD_FADE_IN: float = 0.55
const CHAPTER_CARD_HOLD: float = 1.8
const CHAPTER_CARD_FADE_OUT: float = 0.55

# ---------- 运行时状态 ----------
var _frames: Array = []
var _current_index: int = 0
var _is_typing: bool = false
var _can_advance: bool = true

# ---------- UI 节点 ----------
var _bg: ColorRect
var _dialogue_box: Panel
var _speaker_plate: Panel
var _speaker_label: Label
var _text_label: Label

var _title_label: Label
var _chapter_card_layer: CanvasLayer
var _chapter_card_root: Control
var _chapter_card_label: Label
var _continue_hint: Label
var _skip_button: Button
var _typewriter_timer: Timer
var _continue_hint_tween: Tween


func _ready() -> void:
	Engine.time_scale = 1.0
	_build_ui()
	_load_story()
	if _frames.is_empty():
		_finish_story()
		return
	_play_chapter_card()


# ============ UI 构建 ============
func _build_ui() -> void:
	# 全屏黑背景
	_bg = ColorRect.new()
	_bg.color = COLOR_BG
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	# 顶部弱化章节标识（进入正文后显示）
	_title_label = Label.new()
	_title_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_title_label.offset_left = 120.0
	_title_label.offset_top = 28.0
	_title_label.offset_right = -120.0
	_title_label.offset_bottom = 64.0
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", Color(COLOR_TITLE.r, COLOR_TITLE.g, COLOR_TITLE.b, 0.62))
	_title_label.add_theme_color_override("font_outline_color", Color(0.10, 0.07, 0.03, 0.8))
	_title_label.add_theme_constant_override("outline_size", 3)
	_title_label.visible = false
	add_child(_title_label)

	# 游戏式底部对话框（仅角色对话显示）
	_dialogue_box = Panel.new()
	_dialogue_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_dialogue_box.offset_left = 96.0
	_dialogue_box.offset_top = -190.0
	_dialogue_box.offset_right = -96.0
	_dialogue_box.offset_bottom = -46.0
	_dialogue_box.z_index = 80
	_dialogue_box.z_as_relative = false
	_dialogue_box.visible = false
	var box_style := StyleBoxFlat.new()
	box_style.bg_color = COLOR_DIALOGUE_BOX_BG
	box_style.border_color = COLOR_DIALOGUE_BOX_BORDER
	box_style.set_border_width_all(3)
	box_style.set_corner_radius_all(14)
	box_style.shadow_color = Color(0, 0, 0, 0.72)
	box_style.shadow_size = 18
	box_style.content_margin_left = 32.0
	box_style.content_margin_right = 32.0
	box_style.content_margin_top = 38.0
	box_style.content_margin_bottom = 20.0

	_dialogue_box.add_theme_stylebox_override("panel", box_style)
	add_child(_dialogue_box)

	# 发言人铭牌底板（压在对话框左上角）
	_speaker_plate = Panel.new()
	_speaker_plate.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_speaker_plate.offset_left = 130.0
	_speaker_plate.offset_top = 508.0
	_speaker_plate.offset_right = 300.0
	_speaker_plate.offset_bottom = 550.0

	_speaker_plate.z_index = 100
	_speaker_plate.z_as_relative = false
	_speaker_plate.visible = false
	var plate_style := StyleBoxFlat.new()
	plate_style.bg_color = COLOR_NAMEPLATE_BG
	plate_style.border_color = COLOR_NAMEPLATE_BORDER
	plate_style.set_border_width_all(2)
	plate_style.set_corner_radius_all(9)
	plate_style.shadow_color = Color(0, 0, 0, 0.55)
	plate_style.shadow_size = 8
	plate_style.content_margin_left = 16.0
	plate_style.content_margin_right = 16.0
	plate_style.content_margin_top = 6.0
	plate_style.content_margin_bottom = 6.0
	_speaker_plate.add_theme_stylebox_override("panel", plate_style)
	add_child(_speaker_plate)

	# 发言人名字
	_speaker_label = Label.new()
	_speaker_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_speaker_label.offset_left = 16.0
	_speaker_label.offset_right = -16.0
	_speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_speaker_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_speaker_label.add_theme_font_size_override("font_size", 22)
	_speaker_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03, 0.95))
	_speaker_label.add_theme_constant_override("outline_size", 3)
	_speaker_plate.add_child(_speaker_label)


	# 章节黑屏卡片
	_chapter_card_layer = CanvasLayer.new()
	_chapter_card_layer.layer = 250
	add_child(_chapter_card_layer)

	_chapter_card_root = Control.new()
	_chapter_card_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_chapter_card_root.modulate.a = 0.0
	_chapter_card_layer.add_child(_chapter_card_root)

	var chapter_bg := ColorRect.new()
	chapter_bg.color = Color(0, 0, 0, 1)
	chapter_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_chapter_card_root.add_child(chapter_bg)

	_chapter_card_label = Label.new()
	_chapter_card_label.set_anchors_preset(Control.PRESET_CENTER)
	_chapter_card_label.offset_left = -340.0
	_chapter_card_label.offset_top = -44.0
	_chapter_card_label.offset_right = 340.0
	_chapter_card_label.offset_bottom = 44.0
	_chapter_card_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chapter_card_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_chapter_card_label.add_theme_font_size_override("font_size", 34)
	_chapter_card_label.add_theme_color_override("font_color", COLOR_TITLE)
	_chapter_card_label.add_theme_color_override("font_outline_color", Color(0.10, 0.07, 0.03, 1.0))
	_chapter_card_label.add_theme_constant_override("outline_size", 5)
	_chapter_card_root.add_child(_chapter_card_label)

	# 正文
	_text_label = Label.new()
	_text_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_text_label.offset_left = 120.0
	_text_label.offset_top = 260.0
	_text_label.offset_right = -120.0
	_text_label.offset_bottom = 540.0
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_font_size_override("font_size", 22)
	_text_label.add_theme_color_override("font_color", COLOR_NARRATION)
	add_child(_text_label)

	# 点击继续提示
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
	_continue_hint.visible = false
	add_child(_continue_hint)

	_continue_hint_tween = create_tween().set_loops()
	_continue_hint_tween.tween_property(_continue_hint, "modulate:a", 0.3, 0.8).set_trans(Tween.TRANS_SINE)
	_continue_hint_tween.tween_property(_continue_hint, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)

	# 跳过按钮
	_skip_button = Button.new()
	_skip_button.text = "跳过 >>"
	_skip_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_skip_button.offset_left = -130.0
	_skip_button.offset_top = 20.0
	_skip_button.offset_right = -20.0
	_skip_button.offset_bottom = 56.0
	_skip_button.theme = MenuTheme.make_button_theme()
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
	var chapter_title: String = MenuTheme.pending_story_chapter_title
	if chapter_title == "":
		chapter_title = "Chapter"
	_title_label.text = chapter_title
	_chapter_card_label.text = chapter_title


# ============ 帧播放 ============
func _show_frame(index: int) -> void:
	if index >= _frames.size():
		_finish_story()
		return
	_current_index = index
	_can_advance = false
	_dialogue_box.visible = false
	_speaker_plate.visible = false
	_title_label.visible = false
	_text_label.visible = true

	_text_label.modulate.a = 1.0
	_text_label.visible_characters = -1
	_continue_hint.visible = false


	var frame: Dictionary = _frames[index]
	var frame_type: String = frame.get("type", "narration")
	var text: String = frame.get("text", "")



	match frame_type:
		"dialogue":
			_play_dialogue(frame.get("speaker", ""), text)
		_:
			_play_narration(text)


func _play_chapter_card() -> void:
	var tween := create_tween()
	tween.tween_property(_chapter_card_root, "modulate:a", 1.0, CHAPTER_CARD_FADE_IN)
	tween.tween_interval(CHAPTER_CARD_HOLD)
	tween.tween_property(_chapter_card_root, "modulate:a", 0.0, CHAPTER_CARD_FADE_OUT)
	tween.tween_callback(func() -> void:
		if is_instance_valid(_chapter_card_layer):
			_chapter_card_layer.queue_free()
		_title_label.visible = false
		_show_frame(0)
	)


# ============ 旁白 / 对话 ============
func _play_narration(text: String) -> void:
	_dialogue_box.visible = false
	_speaker_plate.visible = false
	_text_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_text_label.offset_left = 120.0
	_text_label.offset_top = 260.0
	_text_label.offset_right = -120.0
	_text_label.offset_bottom = 540.0
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_text_label.add_theme_font_size_override("font_size", 22)
	_text_label.add_theme_color_override("font_color", COLOR_NARRATION)
	_start_typewriter(text)
	_can_advance = true



func _play_dialogue(speaker: String, text: String) -> void:
	_speaker_label.text = speaker
	_speaker_label.show()
	_speaker_plate.show()
	_speaker_plate.move_to_front()
	match speaker:

		"Kane":
			_speaker_label.add_theme_color_override("font_color", COLOR_KANE)
			(_speaker_plate.get_theme_stylebox("panel") as StyleBoxFlat).border_color = COLOR_KANE
		"丽塔":
			_speaker_label.add_theme_color_override("font_color", COLOR_RITA)
			(_speaker_plate.get_theme_stylebox("panel") as StyleBoxFlat).border_color = COLOR_RITA
		_:
			_speaker_label.add_theme_color_override("font_color", COLOR_NARRATION)
			(_speaker_plate.get_theme_stylebox("panel") as StyleBoxFlat).border_color = COLOR_NAMEPLATE_BORDER

	_text_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_text_label.offset_left = 130.0
	_text_label.offset_top = -142.0
	_text_label.offset_right = -130.0
	_text_label.offset_bottom = -76.0
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_text_label.z_index = 90
	_text_label.z_as_relative = false
	_text_label.add_theme_font_size_override("font_size", 24)
	_text_label.add_theme_color_override("font_color", COLOR_TEXT_DIALOGUE)
	_text_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_text_label.add_theme_constant_override("outline_size", 3)
	_start_typewriter(text)
	_dialogue_box.show()

	_dialogue_box.move_to_front()
	_speaker_plate.show()
	_speaker_plate.move_to_front()
	_text_label.move_to_front()
	_can_advance = true



# ============ 打字机 ============
func _start_typewriter(text: String) -> void:
	_text_label.text = text
	_text_label.visible_characters = 0
	_is_typing = true
	_continue_hint.visible = false
	_typewriter_timer.start()


func _on_typewriter_tick() -> void:
	_text_label.visible_characters += 1
	if _text_label.visible_characters >= _text_label.get_total_character_count():
		_typewriter_timer.stop()
		_is_typing = false
		_continue_hint.visible = true


# ============ 输入:推进 / 瞬显 / 跳过 ============
func _unhandled_input(event: InputEvent) -> void:
	if not _can_advance:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()


func _advance() -> void:
	if _is_typing:
		_typewriter_timer.stop()
		_text_label.visible_characters = -1
		_is_typing = false
		_continue_hint.visible = true
		return
	_show_frame(_current_index + 1)


func _on_skip() -> void:
	_finish_story()


# ============ 结束:标记 + 跳转 ============
func _finish_story() -> void:
	_typewriter_timer.stop()
	set_process_unhandled_input(false)
	if MenuTheme.pending_story_id == StoryData.PROLOGUE:
		MenuTheme.prologue_watched = true
	var next: String = MenuTheme.pending_story_next_scene
	if next == "":
		next = "res://scenes/menu/main_menu.tscn"
	MenuTheme.clear_story_context()
	MenuTheme.change_scene(next)
