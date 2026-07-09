## chapter_select.gd
## 章节选择界面 — 参考《空洞骑士》地图钉 / 《原神》章节列表的混合风格
## 暗色面板 + 可滚动章节卡片列表。每张卡片：
##   - 已解锁：彩色高亮（地形主题色），悬停放大 + 边框发光
##   - 未解锁：灰白，不可点击
## 点击行为：
##   - 第一章 新手教学 → 加载 main_game.tscn（已实现的教程关）
##   - 其他章节 → "正在开发中" Toast
##
## 解锁状态用 MenuTheme.unlocked_chapter_index（静态变量，简化版持久化）。

extends Control

const TUTORIAL_SCENE := "res://scenes/main_game/main_game.tscn"
const MAIN_MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const STORY_PLAYER_SCENE := "res://scenes/story/story_player.tscn"
const DEV_MSG: String = "正在开发中"

# 章节数据：id / 标题 / 副标题(地形·天气) / 主题色 / 是否已实现的关卡
class Chapter:
	var index: int
	var chapter_label: String   # "第一章"
	var name_str: String        # "新手教学"
	var terrain: String         # "平原"
	var weather: String         # "星月晴朗"
	var theme_color: Color      # 卡片主色
	var scene_path: String      # "" = 未实现

var chapters: Array[Chapter] = []
@onready var _list: VBoxContainer = $Panel/Scroll/List


func _ready() -> void:
	MenuTheme.add_background(self)

	_build_chapters()
	_populate()

	# 返回按钮（右上角）
	var back_btn: Button = $BackButton
	MenuTheme.attach_button_sfx(back_btn)
	back_btn.pressed.connect(_on_back)

	Engine.time_scale = 1.0


# ============ 章节数据（来自完整版策划书） ============
func _build_chapters() -> void:
	chapters.clear()
	_add(0, "教学", "新手教学", "平原", "星月晴朗", Color(0.30, 0.55, 0.30), TUTORIAL_SCENE)
	_add(1, "第一章", "暗夜突袭", "平原", "迷雾笼罩", Color(0.40, 0.45, 0.55), "")
	_add(2, "第二章", "熔岩前哨", "火山地脉", "烈日当空", Color(0.80, 0.32, 0.18), "")
	_add(3, "第三章", "冰封隘口", "极北冰原", "暴风雪", Color(0.45, 0.70, 0.90), "")
	_add(4, "第四章", "雷鸣峡谷", "风暴荒原", "雷暴交加", Color(0.55, 0.50, 0.85), "")
	_add(5, "第五章", "深渊港口", "深海裂隙", "倾盆大雨", Color(0.25, 0.40, 0.65), "")
	_add(6, "第六章", "迷踪密林", "腐化密林", "迷雾笼罩", Color(0.30, 0.45, 0.25), "")
	_add(7, "第七章", "绝壁要塞", "峡谷岩地", "狂风呼啸", Color(0.60, 0.50, 0.35), "")
	_add(8, "第八章", "元素圣殿", "混合地形", "渐变天气", Color(0.75, 0.60, 0.30), "")
	_add(9, "第九章", "Boss 前奏", "冰原·深海", "混合天气", Color(0.50, 0.55, 0.70), "")
	_add(10, "第十章", "深渊回响", "混沌虚空", "混沌气象", Color(0.65, 0.20, 0.55), "")


func _add(idx: int, ch: String, name_str: String, terrain: String, weather: String, color: Color, scene_path: String) -> void:
	var c := Chapter.new()
	c.index = idx
	c.chapter_label = ch
	c.name_str = name_str
	c.terrain = terrain
	c.weather = weather
	c.theme_color = color
	c.scene_path = scene_path
	chapters.append(c)


func _populate() -> void:
	for c in chapters:
		var unlocked: bool = c.index <= MenuTheme.unlocked_chapter_index
		_list.add_child(_make_card(c, unlocked))


# ============ 卡片构造 ============
func _make_card(c: Chapter, unlocked: bool) -> Control:
	# 容器（Panel 卡片）
	var card := Panel.new()
	card.custom_minimum_size = Vector2(720, 96)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.09, 0.13, 0.92)
	sb.border_color = c.theme_color if unlocked else Color(0.32, 0.32, 0.32)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(16.0)
	card.add_theme_stylebox_override("panel", sb)

	# 主标题（关卡名）
	var name_lbl := Label.new()
	name_lbl.text = "%s　%s" % [c.chapter_label, c.name_str]
	name_lbl.position = Vector2(22, 14)
	name_lbl.size = Vector2(560, 36)
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.add_theme_color_override("font_color", c.theme_color if unlocked else Color(0.55, 0.55, 0.55))
	card.add_child(name_lbl)

	# 副标题（地形 · 天气）
	var sub_lbl := Label.new()
	sub_lbl.text = "%s  ·  %s" % [c.terrain, c.weather]
	sub_lbl.position = Vector2(22, 52)
	sub_lbl.size = Vector2(560, 28)
	sub_lbl.add_theme_font_size_override("font_size", 16)
	sub_lbl.add_theme_color_override("font_color", Color(0.72, 0.70, 0.66) if unlocked else Color(0.45, 0.45, 0.45))
	card.add_child(sub_lbl)

	# 右侧状态标签
	var status_lbl := Label.new()
	status_lbl.position = Vector2(580, 36)
	status_lbl.size = Vector2(120, 30)
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_lbl.add_theme_font_size_override("font_size", 16)
	if unlocked:
		if c.scene_path != "":
			status_lbl.text = "▶ 进入"
			status_lbl.add_theme_color_override("font_color", MenuTheme.ACCENT_BRIGHT)
		else:
			status_lbl.text = "开发中"
			status_lbl.add_theme_color_override("font_color", MenuTheme.TEXT_DIM)
	else:
		status_lbl.text = "🔒 未解锁"
		status_lbl.add_theme_color_override("font_color", Color(0.42, 0.42, 0.42))
	card.add_child(status_lbl)

	# 已解锁的卡片 → 可点击 + 悬停反馈
	if unlocked:
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		var _c := c  # 捕获循环变量
		card.gui_input.connect(func(ev: InputEvent) -> void: _on_card_input(_c, ev))
		card.mouse_entered.connect(func() -> void:
			if is_instance_valid(card):
				_tween_card(card, sb, c.theme_color, 1.02)
		)
		card.mouse_exited.connect(func() -> void:
			if is_instance_valid(card):
				_tween_card(card, sb, c.theme_color, 1.0)
		)
	else:
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	return card


func _tween_card(card: Panel, sb: StyleBoxFlat, base_color: Color, target_scale: float) -> void:
	if not is_instance_valid(card):
		return
	# pivot 居中，缩放才不偏移
	if card.size.x > 0.0:
		card.pivot_offset = card.size / 2.0
	var tw := create_tween()
	tw.tween_property(card, "scale", Vector2(target_scale, target_scale), 0.10).set_trans(Tween.TRANS_SINE)
	# 悬停时边框向白色提亮，移出时还原主题色
	if target_scale > 1.0:
		sb.border_color = base_color.lerp(Color(1, 1, 1), 0.4)
	else:
		sb.border_color = base_color


# ============ 卡片点击 ============
func _on_card_input(c: Chapter, event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		_on_card_clicked(c)


func _on_card_clicked(c: Chapter) -> void:
	if c.index > MenuTheme.unlocked_chapter_index:
		return  # 未解锁（理论上不会进到这里）
	if c.scene_path == "":
		MenuTheme.show_toast(self, DEV_MSG)
		return
	# 已实现关卡：进入游戏前重置全局状态，保证从菜单进来的局是干净的
	MenuTheme.reset_global_run_state()
	# 教程关(index 0):先播放第一幕前置剧情,再进游戏

	if c.index == 0:
		MenuTheme.start_story(StoryData.TUTORIAL_INTRO, c.scene_path, STORY_PLAYER_SCENE, "Chapter 1 - 初次守候")
	else:
		MenuTheme.change_scene(c.scene_path)





func _on_back() -> void:

	MenuTheme.change_scene(MAIN_MENU_SCENE)
