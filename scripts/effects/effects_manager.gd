## effects_manager.gd
## 像素风特效管理器 — Autoload 单例
## 统一管理所有战斗/部署/黎明视觉特效
## 像素风格：小方块粒子 + NEAREST 滤镜 + 阶梯式动画 + 高饱和纯色
##
## 在 project.godot 中设为 Autoload: EffectsManager

extends Node

# ============ 像素风调色板（高饱和纯色）============
const COL_HIT_SPARK := Color(1.0, 0.95, 0.3)      # 命中火花（亮黄）
const COL_HIT_SPARK_2 := Color(1.0, 0.6, 0.1)     # 命中火花（橙）
const COL_DEATH := Color(0.9, 0.2, 0.25)          # 死亡（血红）
const COL_DEATH_2 := Color(1.0, 0.5, 0.2)         # 死亡（橙红）
const COL_DEPLOY := Color(0.3, 0.9, 1.0)          # 部署（青蓝）
const COL_DEPLOY_2 := Color(1.0, 1.0, 1.0)        # 部署（白）
const COL_GOLD := Color(1.0, 0.84, 0.2)           # 金币（金）
const COL_HEAL := Color(0.3, 1.0, 0.4)            # 治疗（绿）
const COL_DMG := Color(1.0, 0.3, 0.3)             # 伤害（红）
const COL_CORE := Color(0.6, 0.8, 1.0)            # 核心（淡蓝）
const COL_DAWN := Color(1.0, 0.95, 0.8)           # 黎明（暖白）

# 像素方块基础尺寸
const PIXEL_SIZE := 3.0

# 临时特效容器（运行时创建）
var _fx_layer: Node2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 延迟到主场景就绪后创建特效层
	call_deferred("_setup_fx_layer")


func _setup_fx_layer() -> void:
	# 特效层挂在主场景上，所有特效作为其子节点
	var tree := get_tree()
	if not tree:
		return
	await tree.create_timer(0.1).timeout
	_ensure_fx_layer()


## 确保特效层存在（挂在 current_scene 下）
func _ensure_fx_layer() -> Node2D:
	var scene := get_tree().current_scene
	if not scene:
		return null
	# 查找已存在的
	var existing := scene.get_node_or_null("EffectsLayer")
	if existing and existing is Node2D:
		_fx_layer = existing
		return _fx_layer
	# 新建
	_fx_layer = Node2D.new()
	_fx_layer.name = "EffectsLayer"
	# 特效层在所有游戏元素之上、UI 之下
	_fx_layer.z_index = 50
	scene.add_child(_fx_layer)
	return _fx_layer


# ============================================================
# 1. 攻击命中特效 — 像素火花迸发
# ============================================================
## 在 pos 处生成像素火花迸发特效（角色攻击命中敌人时）
func spawn_hit_effect(pos: Vector2) -> void:
	var layer := _ensure_fx_layer()
	if not layer:
		return
	# 中心闪光（像素方块放大+淡出）
	_spawn_pixel_flash(pos, COL_HIT_SPARK, 8.0, 0.18)
	# 火花粒子（8 个方向飞溅的像素方块）
	var dirs := [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN,
		Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]
	for i in range(dirs.size()):
		var spark := _make_pixel(COL_HIT_SPARK if i % 2 == 0 else COL_HIT_SPARK_2)
		spark.position = pos
		layer.add_child(spark)
		var dir: Vector2 = dirs[i].normalized()
		var dist := randf_range(10.0, 20.0)
		var tw := spark.create_tween()
		tw.tween_property(spark, "position", pos + dir * dist, 0.2).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(spark, "scale", Vector2(0.2, 0.2), 0.2)
		tw.parallel().tween_property(spark, "modulate:a", 0.0, 0.2)
		tw.tween_callback(spark.queue_free)


# ============================================================
# 2. 敌人死亡特效 — 像素爆炸消散
# ============================================================
## 在 pos 处生成像素爆炸消散特效
func spawn_death_effect(pos: Vector2) -> void:
	var layer := _ensure_fx_layer()
	if not layer:
		return
	# 中心爆闪
	_spawn_pixel_flash(pos, COL_DEATH, 14.0, 0.25)
	# 像素碎片飞溅（12 个碎片）
	for i in 12:
		var frag := _make_pixel(COL_DEATH if i % 2 == 0 else COL_DEATH_2, 4.0)
		frag.position = pos
		layer.add_child(frag)
		var angle := (PI * 2.0 / 12.0) * i + randf_range(-0.2, 0.2)
		var dir := Vector2(cos(angle), sin(angle))
		var dist := randf_range(18.0, 34.0)
		var tw := frag.create_tween()
		tw.tween_property(frag, "position", pos + dir * dist, 0.4).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(frag, "scale", Vector2(0.1, 0.1), 0.4)
		tw.parallel().tween_property(frag, "modulate:a", 0.0, 0.4)
		tw.tween_callback(frag.queue_free)
	# 烟雾消散（淡灰色像素块上浮）
	for i in 5:
		var smoke := _make_pixel(Color(0.4, 0.3, 0.3), 5.0)
		smoke.position = pos + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		layer.add_child(smoke)
		var tw := smoke.create_tween()
		tw.tween_property(smoke, "position:y", smoke.position.y - 20.0, 0.5)
		tw.parallel().tween_property(smoke, "modulate:a", 0.0, 0.5)
		tw.tween_callback(smoke.queue_free)


# ============================================================
# 3. 角色部署特效 — 像素光环扩散
# ============================================================
## 在 pos 处生成角色部署光环特效
func spawn_deploy_effect(pos: Vector2) -> void:
	var layer := _ensure_fx_layer()
	if not layer:
		return
	# 三圈像素光环依次扩散
	for ring in 3:
		var delay := ring * 0.06
		get_tree().create_timer(delay).timeout.connect(func():
			if not is_instance_valid(layer):
				return
			_spawn_pixel_ring(pos, COL_DEPLOY if ring % 2 == 0 else COL_DEPLOY_2)
		)
	# 中心闪光
	_spawn_pixel_flash(pos, COL_DEPLOY, 10.0, 0.2)
	# 向上飞溅的像素星点
	for i in 6:
		var star := _make_pixel(COL_DEPLOY_2, 2.0)
		star.position = pos
		layer.add_child(star)
		var angle := -PI / 2.0 + randf_range(-0.8, 0.8)
		var dir := Vector2(cos(angle), sin(angle))
		var tw := star.create_tween()
		tw.tween_property(star, "position", pos + dir * 24.0, 0.35).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(star, "modulate:a", 0.0, 0.35)
		tw.tween_callback(star.queue_free)


# ============================================================
# 4. 伤害/治疗浮字 — 像素风数字
# ============================================================
## 在 pos 处生成伤害浮字（红色，向上飘）
func spawn_damage_number(pos: Vector2, value: int) -> void:
	_spawn_float_number(pos, "%d" % value, COL_DMG, 18)

## 在 pos 处生成治疗浮字（绿色）
func spawn_heal_number(pos: Vector2, value: int) -> void:
	_spawn_float_number(pos, "+%d" % value, COL_HEAL, 18)

## 在 pos 处生成金币浮字（金色 +N★）
func spawn_gold_number(pos: Vector2, amount: int) -> void:
	_spawn_float_number(pos, "+%d" % amount, COL_GOLD, 20, "★")


## 通用浮字生成
func _spawn_float_number(pos: Vector2, text: String, color: Color, font_size: int, suffix: String = "") -> void:
	var layer := _ensure_fx_layer()
	if not layer:
		return
	var label := Label.new()
	label.text = text + suffix
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	# 像素风：加粗黑色描边
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 4)
	# 关闭抗锯齿感（Label 无法直接设 NEAREST，但描边能增强像素感）
	label.position = pos + Vector2(randf_range(-12, 12), -20)
	layer.add_child(label)
	# 弹跳 + 上浮 + 淡出
	var tw := label.create_tween()
	tw.tween_property(label, "scale", Vector2(1.3, 1.3), 0.08).set_trans(Tween.TRANS_BACK)
	tw.tween_property(label, "scale", Vector2(1.0, 1.0), 0.08)
	tw.tween_property(label, "position:y", label.position.y - 36.0, 0.6).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 0.6)
	tw.tween_callback(label.queue_free)


# ============================================================
# 5. 核心被击特效 — 抖动 + 像素冲击波
# ============================================================
## 在核心位置生成被击特效（核心节点抖动 + 冲击粒子）
func spawn_core_hit_effect(core: Node2D) -> void:
	var layer := _ensure_fx_layer()
	if not layer:
		return
	var pos := core.global_position
	# 1. 核心抖动（像素阶梯式偏移）
	_shake_node(core, 4.0, 0.2)
	# 2. 冲击波（两圈像素方块扩散）
	_spawn_pixel_ring(pos, COL_CORE, 28.0)
	# 3. 像素碎片
	for i in 8:
		var frag := _make_pixel(COL_CORE, 3.0)
		frag.position = pos
		layer.add_child(frag)
		var angle := (PI * 2.0 / 8.0) * i
		var dir := Vector2(cos(angle), sin(angle))
		var tw := frag.create_tween()
		tw.tween_property(frag, "position", pos + dir * 22.0, 0.3).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(frag, "modulate:a", 0.0, 0.3)
		tw.tween_callback(frag.queue_free)


## 核心被摧毁特效（大爆炸）
func spawn_core_destroyed_effect(pos: Vector2) -> void:
	var layer := _ensure_fx_layer()
	if not layer:
		return
	# 巨大爆闪
	_spawn_pixel_flash(pos, Color(1, 0.4, 0.3), 30.0, 0.5)
	# 多圈扩散
	for i in 3:
		get_tree().create_timer(i * 0.1).timeout.connect(func():
			_spawn_pixel_ring(pos, Color(1, 0.5, 0.2) if i % 2 == 0 else Color(1, 0.8, 0.3), 40.0 + i * 10.0)
		)
	# 大量碎片
	for i in 20:
		var frag := _make_pixel(Color(1, randf_range(0.3, 0.7), 0.2), 4.0)
		frag.position = pos
		layer.add_child(frag)
		var angle := (PI * 2.0 / 20.0) * i + randf_range(-0.1, 0.1)
		var dir := Vector2(cos(angle), sin(angle))
		var dist := randf_range(30.0, 60.0)
		var tw := frag.create_tween()
		tw.tween_property(frag, "position", pos + dir * dist, 0.6).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(frag, "scale", Vector2(0.1, 0.1), 0.6)
		tw.parallel().tween_property(frag, "modulate:a", 0.0, 0.6)
		tw.tween_callback(frag.queue_free)


# ============================================================
# 6. 黎明增强特效 — 白色像素粒子上升
# ============================================================
## 黎明时全屏白色像素粒子上升（配合 dawn_effect.gd 使用）
func spawn_dawn_particles() -> void:
	var scene := get_tree().current_scene
	if not scene:
		return
	# 创建一次性粒子发射器
	var particles := CPUParticles2D.new()
	particles.name = "DawnParticles"
	particles.position = Vector2(640, 720)
	particles.z_index = 60
	particles.emitting = true
	particles.amount = 60
	particles.lifetime = 3.0
	particles.one_shot = true
	particles.explosiveness = 0.0
	particles.randomness = 0.5
	particles.direction = Vector2(0, -1)
	particles.spread = 25.0
	particles.gravity = Vector2(0, -10)
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 90.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	# 白色渐隐
	var grad := Gradient.new()
	grad.set_color(0, COL_DAWN)
	grad.set_color(1, Color(1, 1, 1, 0))
	particles.color_ramp = grad
	# 横向铺满屏幕底部
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(640, 10)
	scene.add_child(particles)
	# 4 秒后销毁
	get_tree().create_timer(4.0).timeout.connect(func():
		if is_instance_valid(particles):
			particles.queue_free()
	)


# ============================================================
# 内部工具函数
# ============================================================

## 创建一个像素方块 ColorRect（NEAREST 滤镜 + 无抗锯齿感）
func _make_pixel(color: Color, size: float = PIXEL_SIZE) -> ColorRect:
	var px := ColorRect.new()
	px.color = color
	px.size = Vector2(size, size)
	# 居中偏移（让 position 代表中心点）
	px.position = Vector2(-size / 2.0, -size / 2.0)
	px.scale = Vector2.ONE
	return px


## 中心闪光（像素方块从大到小 + 淡出）
func _spawn_pixel_flash(pos: Vector2, color: Color, start_size: float, duration: float) -> void:
	var layer := _ensure_fx_layer()
	if not layer:
		return
	var flash := ColorRect.new()
	flash.color = color
	flash.size = Vector2(start_size, start_size)
	flash.position = Vector2(-start_size / 2.0, -start_size / 2.0)
	flash.global_position = pos
	flash.z_index = 55
	layer.add_child(flash)
	var tw := flash.create_tween()
	# 先放大再缩小淡出
	var peak := start_size * 1.8
	tw.tween_property(flash, "scale", Vector2(peak / start_size, peak / start_size), duration * 0.3)
	tw.tween_property(flash, "scale", Vector2(0.1, 0.1), duration * 0.7)
	tw.parallel().tween_property(flash, "modulate:a", 0.0, duration * 0.7)
	tw.tween_callback(flash.queue_free)


## 像素光环（一圈方块向外扩散）
func _spawn_pixel_ring(pos: Vector2, color: Color, max_radius: float = 24.0) -> void:
	var layer := _ensure_fx_layer()
	if not layer:
		return
	var count := 12
	for i in count:
		var px := _make_pixel(color, 3.0)
		px.position = pos
		layer.add_child(px)
		var angle := (PI * 2.0 / count) * i
		var dir := Vector2(cos(angle), sin(angle))
		var tw := px.create_tween()
		tw.tween_property(px, "position", pos + dir * max_radius, 0.3).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(px, "modulate:a", 0.0, 0.3)
		tw.tween_callback(px.queue_free)


## 节点抖动（像素阶梯式，受 Engine.time_scale 影响 → 暂停时不抖）
func _shake_node(node: Node2D, intensity: float, duration: float) -> void:
	if not is_instance_valid(node):
		return
	var orig := node.position
	var steps := 6
	var step_time := duration / float(steps)
	for i in steps:
		var offset := Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		node.position = orig + offset
		await get_tree().create_timer(step_time).timeout
	if is_instance_valid(node):
		node.position = orig
