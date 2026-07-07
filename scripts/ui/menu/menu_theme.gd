## menu_theme.gd
## 菜单公共视觉工具 — 统一暗色调（杀戮尖塔2 风格）
## 提供静态方法：背景（渐变 + 余烬粒子）、按钮 Theme、标题（金属发光）、开发中提示 Toast
## 所有三个菜单场景共用，保持视觉一致 + 代码 DRY
##
## 美术策略（与项目 progress.md 一致）：
##   Demo 阶段不引入外部美术素材，纯代码用渐变 + 粒子 + StyleBoxFlat + Tween 实现质感。

class_name MenuTheme
extends RefCounted

# ============ 调色板（暗色 + 金属暖色点缀） ============
const BG_TOP: Color = Color(0.035, 0.035, 0.06)        # 顶部近黑（微蓝）
const BG_BOTTOM: Color = Color(0.11, 0.08, 0.15)      # 底部深紫
const ACCENT: Color = Color(0.86, 0.66, 0.26)         # 金属琥珀
const ACCENT_BRIGHT: Color = Color(1.0, 0.86, 0.46)   # 亮金
const TEXT: Color = Color(0.92, 0.90, 0.85)           # 暖白
const TEXT_DIM: Color = Color(0.52, 0.50, 0.47)       # 灰
const PANEL: Color = Color(0.07, 0.07, 0.11, 0.92)    # 面板底
const EMBER: Color = Color(1.0, 0.52, 0.18, 0.45)     # 余烬橙

const CORNER: float = 6.0
const TITLE_FONT_SIZE: int = 92


# ============ 背景：渐变 ColorRect + 余烬粒子 ============
## 在 parent（通常是根 Control）上叠加暗色渐变背景 + 缓慢上升的余烬粒子。
## 返回创建的粒子节点（调用方可忽略）。
static func add_background(parent: Control) -> CPUParticles2D:
	# 1) 纵向渐变背景（ColorRect 无渐变 → 用 GradientTexture2D + TextureRect）
	var grad := Gradient.new()
	grad.set_color(0, BG_TOP)
	grad.set_color(1, BG_BOTTOM)
	var tex := TextureRect.new()
	tex.name = "Background"
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	var gtex := GradientTexture2D.new()
	gtex.gradient = grad
	gtex.fill = GradientTexture2D.FILL_LINEAR
	gtex.fill_from = Vector2(0.5, 0.0)
	gtex.fill_to = Vector2(0.5, 1.0)
	tex.texture = gtex
	parent.add_child(tex)
	parent.move_child(tex, 0)  # 始终垫在最底

	# 2) 暗角（径向感）— 四角加深
	var vignette := ColorRect.new()
	vignette.name = "Vignette"
	vignette.color = Color(0, 0, 0, 0.0)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(vignette)
	parent.move_child(vignette, 1)  # 在背景之上、其余 UI 之下

	# 3) 余烬粒子（缓慢上升、横向铺满整屏）
	var embers := CPUParticles2D.new()
	embers.name = "Embers"
	embers.position = Vector2(640.0, 740.0)  # 屏幕底部居中（基准 1280×720）
	embers.emitting = true
	embers.amount = 70
	embers.lifetime = 6.0
	embers.one_shot = false
	embers.preprocess = 3.0
	embers.explosiveness = 0.0
	embers.randomness = 0.5
	# 发射方向：向上散开
	embers.direction = Vector2(0, -1)
	embers.spread = 30.0
	embers.gravity = Vector2(0, -6)
	# 速度
	embers.initial_velocity_min = 12.0
	embers.initial_velocity_max = 36.0
	# 大小
	embers.scale_amount_min = 1.5
	embers.scale_amount_max = 3.5
	# 颜色：从亮橙渐隐到透明
	var cgrad := Gradient.new()
	cgrad.set_color(0, EMBER)
	cgrad.set_color(1, Color(EMBER.r, EMBER.g, EMBER.b, 0.0))
	embers.color_ramp = cgrad
	# 横向铺满：用矩形发射区域（宽 1400，让粒子从整屏底部随机出现）
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(700.0, 10.0)
	parent.add_child(embers)
	parent.move_child(embers, 2)  # 在暗角之上、其余 UI 之下
	return embers


# ============ 按钮 Theme ============
## 返回一个暗色调 Theme：normal/hover/pressed/disabled 四态 + 中文字色。
static func make_button_theme() -> Theme:
	var theme := Theme.new()

	# 字号
	theme.set_font_size("font_size", "Button", 22)

	# 各态 StyleBoxFlat
	theme.set_stylebox("normal", "Button", _sb(Color(0.13, 0.13, 0.18, 0.92), ACCENT * 0.55))
	theme.set_stylebox("hover", "Button", _sb(Color(0.20, 0.18, 0.24, 0.96), ACCENT))
	theme.set_stylebox("pressed", "Button", _sb(Color(0.08, 0.08, 0.12, 0.96), ACCENT_BRIGHT))
	theme.set_stylebox("disabled", "Button", _sb(Color(0.10, 0.10, 0.12, 0.7), Color(0.3, 0.3, 0.3, 0.4)))

	# 字色
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", ACCENT_BRIGHT)
	theme.set_color("font_pressed_color", "Button", ACCENT_BRIGHT)
	theme.set_color("font_disabled_color", "Button", TEXT_DIM)

	return theme


## 构造一个圆角带边框的 StyleBoxFlat（含内容留白，作为按钮 padding）
static func _sb(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = border_color
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(int(CORNER))
	# 内容留白（左右 18，上下 10）— 作为按钮内文字 padding
	sb.content_margin_left = 18.0
	sb.content_margin_right = 18.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	return sb


# ============ 标题（金属发光 + 呼吸） ============
## 创建居中的大标题 Label（返回后需自行加入场景 + 定位）。
## name_text: 显示文字；带金属描边，并通过 Tween 做缓慢呼吸。
static func make_title(name_text: String) -> Label:
	var title := Label.new()
	title.name = "Title"
	title.text = name_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	# 金属色字
	title.add_theme_color_override("font_color", ACCENT_BRIGHT)
	# 深色描边制造立体金属感
	title.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.03))
	title.add_theme_constant_override("outline_size", 8)
	return title


# ============ 开发中 Toast（自动消失） ============
## 在 parent 中央弹出 "正在开发中" 类提示，duration 秒后淡出销毁。
## parent 应是一个 Control（通常为场景根）。
static func show_toast(parent: Control, text: String, duration: float = 1.8) -> void:
	if not parent or not is_instance_valid(parent):
		return

	var layer := CanvasLayer.new()
	layer.name = "ToastLayer"
	layer.layer = 500
	parent.add_child(layer)

	var box := Panel.new()
	box.name = "Toast"
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(420, 110)
	box.position = -box.custom_minimum_size / 2.0
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	# 暗色描边面板
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.05, 0.09, 0.95)
	sb.border_color = ACCENT
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(18.0)
	box.add_theme_stylebox_override("panel", sb)
	layer.add_child(box)

	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", ACCENT_BRIGHT)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.add_child(label)

	# 入场放大 → 停留 → 淡出销毁
	box.scale = Vector2(0.8, 0.8)
	box.modulate.a = 0.0
	var tween := parent.create_tween()
	tween.tween_property(box, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(box, "modulate:a", 1.0, 0.18)
	tween.tween_interval(duration)
	tween.tween_property(box, "modulate:a", 0.0, 0.3)
	tween.tween_callback(layer.queue_free)


# ============ 暂存已解锁章节（持久化，简化版） ============
## 用一个静态变量记录已解锁的最高章节索引（从 0 起）。
## 默认只解锁第一章（教程关）。后续关卡实现后可扩展为存档系统。
static var unlocked_chapter_index: int = 0


# ============ 通用过渡：切换到下一个场景 ============
## 统一封装 change_scene_to_file，便于后续加转场动画。
static func change_scene(path: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.change_scene_to_file(path)


# ============ 按钮音效绑定 ============
## 给按钮绑定触碰（hover）和点击（pressed）音效。
## 任何创建按钮的地方都可以调用此方法。
static func attach_button_sfx(btn: Button) -> void:
	btn.mouse_entered.connect(func() -> void:
		AudioManager.play_sfx("button_hover", 0.5))
	btn.pressed.connect(func() -> void:
		AudioManager.play_sfx("button_click", 0.6))
