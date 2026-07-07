## dawn_effect.gd
## 黎明清屏特效 — 全屏闪光、敌人消散、"黎明"大字、角色回血飘字
## 挂载在 main_game.tscn 的 DawnEffect 节点上 (CanvasLayer)

extends CanvasLayer

# ---------- 节点引用 ----------
@onready var flash_overlay: ColorRect = $FlashOverlay      # 全屏白色遮罩
@onready var dawn_label: Label = $DawnLabel                  # "黎明" 大字
@onready var heal_numbers: Node = $HealNumbers              # 回血飘字容器

# 特效参数
const FLASH_DURATION: float = 1.5                           # 闪光渐变时长
const DAWN_TEXT_DISPLAY: float = 2.0                        # "黎明"文字显示时长
const ENEMY_DISSOLVE_TIME: float = 0.8                      # 敌人消散时长
const HEAL_FLOAT_TIME: float = 1.5                          # 回血飘字时长


func _ready() -> void:
	# 初始隐藏
	if flash_overlay:
		flash_overlay.color = Color.WHITE
		flash_overlay.visible = false
	if dawn_label:
		dawn_label.visible = false
		dawn_label.text = "黎明"


# ---------- 触发黎明特效（由 TimeCycle.trigger_dawn 调用）----------
func play_dawn_effect() -> void:
	print("[DawnEffect] ▶ 开始黎明清屏特效!")

	# 1. 全屏白色闪光
	_play_flash()

	# 2. 显示"黎明"大字
	_show_dawn_text()

	# 3. 黎明白色像素粒子上升（增强效果）
	EffectsManager.spawn_dawn_particles()

	# 4. 敌人消散
	_dissolve_enemies()

	# 5. 角色恢复 HP + 飘字
	_heal_characters()

	# 6. 核心奖励检查
	_check_core_bonus()

	# 6. 清理完毕
	await get_tree().create_timer(FLASH_DURATION).timeout
	_cleanup()


# ---------- 全屏闪光 ----------
func _play_flash() -> void:
	if not flash_overlay:
		return

	flash_overlay.visible = true
	flash_overlay.color = Color.WHITE

	var tween := create_tween()
	tween.tween_property(flash_overlay, "color", Color(1, 1, 1, 0), FLASH_DURATION)


# ---------- "黎明" 大字 ----------
func _show_dawn_text() -> void:
	if not dawn_label:
		return

	dawn_label.visible = true
	dawn_label.modulate.a = 1.0
	dawn_label.scale = Vector2(0.5, 0.5)

	var tween := create_tween()
	tween.tween_property(dawn_label, "scale", Vector2(1.2, 1.2), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(dawn_label, "scale", Vector2(1.0, 1.0), 0.15)
	# 保持显示后淡出
	await get_tree().create_timer(DAWN_TEXT_DISPLAY).timeout
	tween = create_tween()
	tween.tween_property(dawn_label, "modulate:a", 0.0, 0.5)


# ---------- 敌人消散 ----------
func _dissolve_enemies() -> void:
	var root := get_tree().current_scene
	if not root:
		print("[DawnEffect] ❌ 没有 current_scene")
		return

	# 调试：找所有可能的敌人节点
	var enemies_container := root.find_child("Enemies", false, false)
	if not enemies_container:
		print("[DawnEffect] ❌ 找不到 Enemies 容器")
		# 看 root 下所有节点
		print("[DawnEffect] root 子节点: ")
		for child in root.get_children():
			print("  - %s (%s) child_count=%d" % [child.name, child.get_class(), child.get_child_count()])
		return

	var enemies := enemies_container.get_children()
	print("[DawnEffect] Enemies 容器里有 %d 个敌人" % enemies.size())

	if enemies.size() == 0:
		print("[DawnEffect] 无敌人需要消散")
		return

	# 关键修复：不要让敌人继续移动！
	# 先把 TimeCycle 标记为非夜晚 → Spawner 不再生成 + 已有敌人停止移动
	if TimeCycle.has_method("pause"):
		TimeCycle.pause()

	var valid_count := 0
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		# 停止敌人移动
		if "is_dead" in enemy:
			enemy.is_dead = true
		if "has_reached_core" in enemy:
			enemy.has_reached_core = true

		# 立即改 modulate + scale（直接显式，不靠 tween）
		enemy.scale = Vector2(0.05, 0.05)
		enemy.modulate = Color(1, 1, 1, 0)
		valid_count += 1

	print("[DawnEffect] 立即消散 %d 个敌人" % valid_count)

	# 然后再做 tween 动画
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		# 直接 queue_free（tween 之前已经直接改了 scale/modulate）
		enemy.queue_free()


# ---------- 角色回血 ----------
func _heal_characters() -> void:
	var root := get_tree().current_scene
	if not root:
		return

	var chars_container := root.find_child("Characters", false, false)
	if not chars_container:
		return

	var recover_percent := Constants.DAWN_REVIVE_HP_PERCENT  # 30%

	for char_node in chars_container.get_children():
		if not is_instance_valid(char_node):
			continue
		if not char_node.has_method("dawn_recover"):
			continue

		char_node.dawn_recover(recover_percent)
		_spawn_heal_number(char_node, recover_percent)


## 生成回血飘字
func _spawn_heal_number(target: Node, percent: float) -> void:
	var label := Label.new()
	label.text = "+%.0f%%" % (percent * 100)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))

	heal_numbers.add_child(label)

	var target_pos := Vector2.ZERO
	if target is Node2D:
		target_pos = target.global_position

	label.position = target_pos + Vector2(-20, -40)

	var tween := create_tween()
	tween.tween_property(label, "position:y", target_pos.y - 80, HEAL_FLOAT_TIME)
	tween.parallel().tween_property(label, "modulate:a", 0.0, HEAL_FLOAT_TIME)
	tween.connect("finished", label.queue_free)


# ---------- 核心 HP 奖励 ----------
func _check_core_bonus() -> void:
	var root := get_tree().current_scene
	if not root:
		return

	var core := root.find_child("Core", true, false)
	if not core:
		return

	# 安全读取 core_node.gd 的变量
	var hp: float = 0.0
	var max_hp_val: float = 100.0
	if core.get("current_hp") != null:
		hp = float(core.get("current_hp"))
	if core.get("max_hp") != null:
		max_hp_val = float(core.get("max_hp"))
	if hp <= 0 or max_hp_val <= 0:
		return
	var hp_ratio: float = hp / max_hp_val if max_hp_val > 0 else 0.0

	if hp_ratio > Constants.DAWN_BONUS_CORE_THRESHOLD:
		var bonus := Constants.DAWN_BONUS_GOLD  # 50
		Economy.add_gold(bonus)
		Economy.broadcast_gold_changed(bonus)
		print("[DawnEffect] 核心 HP %.0f%% > 70%%! 奖励 %d 金" % [hp_ratio * 100, bonus])
		_spawn_bonus_number(bonus)


## 奖励飘字
func _spawn_bonus_number(bonus: int) -> void:
	var label := Label.new()
	label.text = "+%d ★" % bonus
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))

	heal_numbers.add_child(label)
	label.position = Vector2(590, 300)

	var tween := create_tween()
	tween.tween_property(label, "position:y", 200, HEAL_FLOAT_TIME)
	tween.parallel().tween_property(label, "modulate:a", 0.0, HEAL_FLOAT_TIME)
	tween.connect("finished", label.queue_free)


# ---------- 清理 ----------
func _cleanup() -> void:
	if flash_overlay:
		flash_overlay.visible = false
	if dawn_label:
		dawn_label.visible = false
	print("[DawnEffect] ◀ 黎明特效完成")
