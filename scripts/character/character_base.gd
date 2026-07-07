## character_base.gd
## 角色基类脚本 — 所有角色（先锋/近卫/狙击）的通用逻辑
## 挂载在角色预制体的根节点（CharacterBody2D）上

extends CharacterBody2D

# ---------- 导出属性（子类/预制体中配置不同数值） ----------
@export var char_id: String = "pioneer"          # 角色ID
@export var char_name: String = "先锋"            # 显示名称
@export var deploy_cost: int = 10                 # 部署费用
@export var max_hp: float = 150.0                 # 最大生命值
@export var attack_damage: float = 20.0           # 攻击伤害
@export var block_count: int = 2                  # 阻挡数量（近战用）
@export var range_cells: float = 1.0              # 攻击范围（格数，近战=1, 远程=6）
@export var attack_cooldown: float = 1.0          # 攻击冷却（秒）
@export var deploy_type: String = "ground"        # 可部署位置："ground" / "high"
@export var is_ranged: bool = false               # 是否远程攻击

# ---------- 运行时变量 ----------
var current_hp: float = 150.0                    # 当前 HP（_ready 中设为 max_hp）
var cooldown_timer: float = 0.0                   # 攻击冷却计时器
var current_target: Node2D = null                 # 当前攻击目标
var is_dead: bool = false                         # 是否死亡

# 节点引用
@onready var visual: ColorRect = _find_node("Visual") as ColorRect  # 视觉方块（部分角色可能没有）
@onready var hp_bar_bg: ColorRect = $HPBarBg      # HP条背景
@onready var hp_bar_fill: ColorRect = $HPBarBg/HPBarFill  # HP条前景
@onready var label: Label = _find_node("Label") as Label    # 角色名称标签（部分角色可能没有）
@onready var attack_area: Area2D = $AttackArea    # 攻击检测区域（近战用）
@onready var attack_anim_controller: Node = _find_attack_anim_controller()  # 攻击动画控制器（仅部分角色有）

# 攻击范围指示器（选中角色时显示，淡黄半透明圆）
# 用 Polygon2D 实现 64 段圆，radius = range_cells * 64
var range_indicator: Polygon2D = null

# ---------- 先锋特性：已删除回费机制（避免与金矿功能冲突） ----------
# 策划书最初设计：先锋首次部署后10秒内每秒+2金
# 实际开发决策（2026-07-01）：回费与金矿定位冲突，先锋回归"廉价挡怪"基础角色
# 保留基础数值（10/150/20/1.0/2），靠金矿产出+击杀赏金作为经济来源


# ---------- 生命周期 ----------
func _ready() -> void:
	# 初始化 HP
	current_hp = max_hp
	_update_hp_bar()

	# 设置名称标签
	if label:
		label.text = char_name

	# 创建攻击范围指示器（默认隐藏，选中时显示）
	_create_range_indicator()

	# 连接攻击动画控制器信号
	_setup_attack_animation_controller()


## 查找攻击动画控制器（子节点中名为 AttackAnimationController 的节点）
func _find_attack_anim_controller() -> Node:
	return find_child("AttackAnimationController", false, false)


## 安全查找子节点（找不到返回 null，避免 $ 路径不存在时报错）
func _find_node(node_name: String) -> Node:
	return find_child(node_name, false, false)


## 连接动画控制器信号
func _setup_attack_animation_controller() -> void:
	if not attack_anim_controller:
		return
	if not attack_anim_controller.has_signal("attack_animation_finished"):
		return
	
	# 动画播放完毕后执行伤害
	attack_anim_controller.connect("attack_animation_finished", self._on_attack_animation_finished)


## 创建攻击范围圆环（明日方舟式范围可视化）
func _create_range_indicator() -> void:
	if range_indicator:
		return
	var radius_px: float = range_cells * Constants.GRID_CELL_SIZE
	range_indicator = Polygon2D.new()
	# 用 64 段圆逼近
	var points: PackedVector2Array = PackedVector2Array()
	var segments: int = 64
	for i in range(segments + 1):
		var angle: float = TAU * float(i) / float(segments)
		points.append(Vector2(cos(angle) * radius_px, sin(angle) * radius_px))
	range_indicator.polygon = points
	# 不同角色用不同颜色（参考明日方舟: 狙击=橙黄, 先锋=蓝, 重装=红）
	range_indicator.color = _get_range_color()
	range_indicator.z_index = -1  # 画在角色下方
	range_indicator.visible = false
	add_child(range_indicator)


## 选中角色时由 deploy_panel 调用 → 显示范围
func show_range_indicator() -> void:
	if range_indicator:
		range_indicator.visible = true


## 取消选中/部署完成 → 隐藏范围
func hide_range_indicator() -> void:
	if range_indicator:
		range_indicator.visible = false


## 范围颜色（按角色类型区分：明日方舟风格）
func _get_range_color() -> Color:
	match char_id:
		Constants.CHAR_SNIPER:
			return Color(1.0, 0.7, 0.2, 0.25)  # 橙黄（远程）
		Constants.CHAR_DEFENDER:
			return Color(0.9, 0.3, 0.3, 0.25)   # 红（重装）
		Constants.CHAR_PIONEER:
			return Color(0.3, 0.6, 0.95, 0.3)   # 蓝（先锋）
		_:
			return Color(1, 1, 0.4, 0.3)


func _process(delta: float) -> void:
	if is_dead:
		return

	# 攻击冷却倒计时
	if cooldown_timer > 0.0:
		cooldown_timer -= delta

	# 寻找目标 + 攻击
	_try_attack(delta)


# ---------- 攻击系统 ----------
## 尝试寻找并攻击范围内的敌人
func _try_attack(_delta: float) -> void:
	# 冷却未结束 → 不攻击
	if cooldown_timer > 0.0:
		return

	# 寻找目标
	current_target = _find_target()
	if not current_target:
		return

	# 执行攻击
	_perform_attack()
	# 重置冷却
	cooldown_timer = attack_cooldown


## 找到射程内的敌人（优先最近的）
func _find_target() -> Node2D:
	var best_target: Node2D = null
	var best_distance := range_cells * Constants.GRID_CELL_SIZE  # 射程转像素

	# 从场景 Enemies 容器中找敌人
	var enemies_container := _get_enemies_container()
	if not enemies_container:
		return null

	for child in enemies_container.get_children():
		if not (child is CharacterBody2D):
			continue
		if not is_instance_valid(child):
			continue
		var enemy := child as CharacterBody2D
		# 检查 enemy 有没有 take_damage 方法（是敌人的标志）
		if not enemy.has_method("take_damage"):
			continue
		# 跳过已死亡的敌人（防止鞭尸）
		if "is_dead" in enemy and enemy.get("is_dead") == true:
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance <= best_distance:
			best_distance = distance
			best_target = enemy

	return best_target


## 执行攻击动作
func _perform_attack() -> void:
	if not current_target:
		return

	# 播放攻击音效（按角色类型）
	_play_attack_sfx()

	if is_ranged:
		_perform_ranged_attack(current_target)
	else:
		_perform_melee_attack(current_target)


## 按角色类型播放攻击音效
func _play_attack_sfx() -> void:
	match char_id:
		Constants.CHAR_PIONEER:
			AudioManager.play_sfx("pioneer_attack", 1.0)
		Constants.CHAR_DEFENDER:
			AudioManager.play_sfx("defender_attack", 1.0)
		Constants.CHAR_SNIPER:
			AudioManager.play_sfx("sniper_attack", 1.0)

	# 仅当敌人实际死亡时才发送击杀信号（在 _die() 中已由 enemy_movement 发送 enemy_died）
	# 这里不发送 character_killed_enemy，因为"击杀"由 enemy 端确认更准确


## 近战攻击（支持动画控制器）
func _perform_melee_attack(target: Node2D) -> void:
	if not is_instance_valid(target):
		return

	# 如果有动画控制器，等待动画结束后再造成伤害
	if attack_anim_controller and attack_anim_controller.has_method("play_attack_animation"):
		attack_anim_controller.play_attack_animation(target)
	else:
		# 没有动画控制器，直接造成伤害（兼容旧逻辑）
		_deal_melee_damage(target)


## 远程攻击（支持动画控制器）
func _perform_ranged_attack(target: Node2D) -> void:
	if not is_instance_valid(target):
		return
	if attack_anim_controller and attack_anim_controller.has_method("play_attack_animation"):
		attack_anim_controller.play_attack_animation(target)
	else:
		_fire_projectile(target.global_position)


## 攻击动画播放完毕后，由动画控制器回调此函数
func _on_attack_animation_finished(target: Node) -> void:
	if not is_instance_valid(target):
		return

	if is_ranged:
		_fire_projectile(target.global_position)
	else:
		_deal_melee_damage(target)


## 近战伤害
func _deal_melee_damage(target: Node2D) -> void:
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)


## 远程投射物
func _fire_projectile(target_pos: Vector2) -> void:
	# 加载投射物场景
	var projectile_scene := load("res://scenes/main_game/projectile.tscn")
	if not projectile_scene:
		printerr("[CharacterBase] 无法加载 projectile.tscn!")
		return

	var proj := projectile_scene.instantiate() as CharacterBody2D
	proj.global_position = global_position
	proj.set_meta("damage", attack_damage)
	proj.set_meta("target_pos", target_pos)
	proj.set_meta("owner", self)

	# 加入场景
	get_tree().current_scene.add_child(proj)


# ---------- 受伤 ----------
## 角色受到伤害
func take_damage(amount: float) -> void:
	if is_dead:
		return

	current_hp = maxf(0.0, current_hp - amount)
	_update_hp_bar()

	# 受伤闪白
	_play_damage_flash()

	if current_hp <= 0:
		_die()


## 死亡处理
func _die() -> void:
	if is_dead:
		return  # 防止同帧多敌命中导致重复 _die
	is_dead = true
	print("[CharacterBase] %s(%s)阵亡!" % [char_name, char_id])

	# 发送死亡信号
	SignalBus.character_died.emit(char_id)

	# 死亡动画：缩小+渐隐
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.4)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.4)
	tween.connect("finished", queue_free)


# ---------- HP 条更新 ----------
func _update_hp_bar() -> void:
	if not hp_bar_fill or not hp_bar_bg:
		return
	var hp_percent := current_hp / max_hp
	hp_bar_fill.size.x = hp_bar_bg.size.x * hp_percent

	# 低血量变红
	if hp_percent < 0.3:
		hp_bar_fill.color = Color(0.9, 0.2, 0.2)
	elif hp_percent < 0.6:
		hp_bar_fill.color = Color(0.9, 0.7, 0.1)
	else:
		hp_bar_fill.color = Color(0.2, 0.8, 0.2)


# ---------- 受伤闪白 ----------
func _play_damage_flash() -> void:
	if not visual:
		return
	var original_color := visual.color
	var tween := create_tween()
	tween.tween_property(visual, "color", Color.WHITE, 0.06)
	tween.tween_property(visual, "color", original_color, 0.06)


# ---------- 先锋回费（已删除 2026-07-01） ----------
# 原代码：启动先锋首次部署回费（10秒内每秒+2金）
# 删除原因：与金矿经济系统功能重复，先锋回归"廉价挡怪"基础定位
# 如需恢复请参考 git history 或回滚到删除前版本


# ---------- 黎明恢复 ----------
## 黎明时恢复一定比例 HP
func dawn_recover(recover_percent: float) -> void:
	if is_dead:
		return
	var recover_amount := max_hp * recover_percent
	current_hp = minf(max_hp, current_hp + recover_amount)
	_update_hp_bar()
	print("[CharacterBase] %s 黎明恢复 %.0f%% HP (+%.0f)" % [char_name, recover_percent * 100, recover_amount])


# ---------- 工具函数 ----------
## 获取场景中的敌人容器节点
func _get_enemies_container() -> Node:
	var root := get_tree().current_scene
	if root:
		return root.find_child("Enemies", false, false)
	return null
