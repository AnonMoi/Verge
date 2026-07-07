## enemy_movement.gd
## 敌人移动脚本 — 沿预设路径点移动，到达终点后对核心造成伤害，可被攻击死亡
## 挂载在 enemy.tscn 的根节点（CharacterBody2D）上

extends CharacterBody2D

# ---------- 属性 ----------
# 默认数值对应 chaos_grunt，可在 .tscn 覆盖或运行时由 spawner 设定
@export var max_hp: float = 100.0          # 最大生命值
var hp: float = 0.0                        # 当前生命值（在 _ready 中初始化）
@export var speed: float = 80.0            # 移动速度（像素/秒）
@export var core_damage: float = 15.0      # 撞到核心时的伤害值
@export var enemy_type: String = "chaos_grunt"  # 敌人类型标识
var is_dead: bool = false                  # 是否已死亡

# 各敌人类型默认配置（与 enemies.json 保持一致）
const DEFAULT_STATS := {
	Constants.ENEMY_GRUNT:  {"max_hp": 100.0, "speed": 80.0,  "core_damage": 15.0},
	Constants.ENEMY_GHOST:  {"max_hp": 70.0,  "speed": 144.0, "core_damage": 12.0},
	Constants.ENEMY_ELITE:  {"max_hp": 500.0, "speed": 56.0,  "core_damage": 35.0},
}

# 路径点数组（世界坐标，像素）
# 路径：左边缘 → 水平右移 → 向下拐 → 继续右移 → 到达核心附近
var path_points: Array[Vector2] = []
var current_path_index: int = 0             # 当前目标路径点索引
var has_reached_core: bool = false          # 是否已到达核心

# 拐点等待：用累积 delta（已被 Engine.time_scale 缩放）——倍速越快等待越短
var wait_remaining: float = 0.0             # 剩余等待时间（游戏内时间，秒）

# 核心节点引用（在 _ready 中查找）
var core_node: Node2D = null

# 节点引用
@onready var anim_controller: Node = find_child("EnemyAnimationController", false, false)  # 敌人动画控制器（可选）


# ---------- 生命周期 ----------
func _ready() -> void:
	# 根据 enemy_type 应用默认数值（若不存在则使用导出值）
	if DEFAULT_STATS.has(enemy_type):
		var stats: Dictionary = DEFAULT_STATS[enemy_type]
		max_hp = stats.max_hp
		speed = stats.speed
		core_damage = stats.core_damage
	hp = max_hp  # 初始化当前生命
	# 从 PathManager 动态获取路径点（兼容旧版：如果 PathManager 未初始化则 fallback 硬编码）
	path_points = _load_path_points()

	# 设置初始位置为第一个路径点
	if path_points.size() > 0:
		position = path_points[0]
		current_path_index = 1  # 下一个目标

	# 查找场景中的核心节点
	core_node = _find_core_node()
	if core_node:
		print("[EnemyMovement] 找到核心节点: ", core_node.name)
	else:
		printerr("[EnemyMovement] 未找到核心节点!")

## 加载路径点：优先从 PathManager，fallback 硬编码
func _load_path_points() -> Array[Vector2]:
	# 检查 PathManager autoload
	if _has_path_manager():
		var points := PathManager.get_path_points()
		if points and points.size() > 1:
			# 调整终点 y 坐标与核心对齐（原逻辑中终点为 352 而非 320）
			var last: Vector2 = Vector2(points[-1])
			last.y = 352.0  # 与原核心位置对齐
			points[-1] = last
			print("[EnemyMovement] 从 PathManager 加载路径点: ", points)
			return points

	# Fallback: 硬编码路径点（与原始 ColorRect 布局对齐）
	# 格子大小 64px，坐标取格子中心
	# 路径：左边缘(32,320) → 右到拐点1(416,320) → 下到拐点2(416,448)
	#         → 右到拐点3(800,448) → 向上到终点/核心(800,352)
	print("[EnemyMovement] PathManager 无数据，使用硬编码路径点")
	return [
		Vector2(32, 320),      # 起点：左侧边缘
		Vector2(416, 320),     # 拐点1：水平右移结束，准备向下
		Vector2(416, 448),     # 拐点2：竖直下移结束，准备向右
		Vector2(800, 448),     # 拐点3：水平右移结束，准备向上
		Vector2(800, 352),     # 终点：核心位置
	]

## 检查 PathManager autoload 是否可用
func _has_path_manager() -> bool:
	var root := get_tree().root
	return root != null and root.has_node("PathManager")


# ---------- 每帧移动 ----------
func _process(delta: float) -> void:
	if has_reached_core or is_dead:
		return

	if current_path_index >= path_points.size():
		# 已到达最后一个路径点 → 对核心造成伤害
		_reach_core()
		return

	# 拐点等待（用累积 delta，受 Engine.time_scale 缩放 → 倍速越快等得越短）
	if wait_remaining > 0.0:
		wait_remaining -= delta
		return

	# 获取当前目标点
	var target := path_points[current_path_index]
	var direction := target - position

	if direction.length() < 2.0:
		# 已到达当前路径点 → 切换到下一个
		# 在拐点（index>0）延迟约 0.5s 游戏内时间 = spawn 周期的一半
		# 由于 delta 已被 time_scale 缩放，所以 2x 下等 0.25s 真实 → 同步加速
		if current_path_index > 0:
			wait_remaining = 0.5
		position = target
		current_path_index += 1
	else:
		# 向目标点移动（避开前方敌人，防止堵车）
		var min_distance := 32.0  # 敌人之间最小间距
		var effective_speed := speed
		for other in _get_others_ahead():
			var d := position.distance_to(other.position)
			if d < min_distance and d > 0.0:
				# 越近越慢（防止堆叠）
				effective_speed *= maxf(0.3, d / min_distance)
				break
		var velocity := direction.normalized() * effective_speed
		position += velocity * delta


## 获取前方（同路径段）最近的另一个敌人
func _get_others_ahead() -> Array:
	var result: Array = []
	var root := get_tree().current_scene
	if not root:
		return result
	var enemies := root.find_child("Enemies", false, false)
	if not enemies:
		return result
	for child in enemies.get_children():
		if child == self or not is_instance_valid(child):
			continue
		if not (child is CharacterBody2D):
			continue
		# 只考虑同一路径上、已超过自己位置的
		if child.current_path_index > current_path_index:
			result.append(child)
	return result


# ---------- 到达核心 ----------
## 敌人到达路径终点，播放攻击动画 → 对核心造成伤害并自毁
func _reach_core() -> void:
	if has_reached_core or is_dead:
		return
	has_reached_core = true

	# 如果有动画控制器，播放攻击动画后再执行伤害
	if anim_controller and anim_controller.has_method("play_attack"):
		if anim_controller.has_signal("attack_animation_finished"):
			anim_controller.connect("attack_animation_finished", self._on_core_attack_finished, CONNECT_ONE_SHOT)
		anim_controller.play_attack()
	else:
		# 没有动画控制器，直接执行
		_core_attack_execute()


## 攻击动画播放完毕后的回调
func _on_core_attack_finished() -> void:
	_core_attack_execute()


## 实际执行对核心造成伤害+销毁
func _core_attack_execute() -> void:
	if is_dead:
		return

	print("[EnemyMovement] 敌人(%s)到达核心，造成 %.0f 伤害" % [enemy_type, core_damage])

	# 对核心造成伤害
	if core_node and core_node.has_method("take_damage"):
		core_node.take_damage(core_damage)

	# 发送敌人到达核心信号
	SignalBus.enemy_reached_core.emit(enemy_type)

	# 敌人到核心后销毁（策划书：敌人被阻挡或到核心都消失）
	queue_free()


# ---------- 受伤（被角色攻击） ----------
## 受到来自角色的伤害，HP归零时死亡
func take_damage(amount: float) -> void:
	if is_dead:
		return

	hp = maxf(0.0, hp - amount)
	print("[EnemyMovement] 敌人(%s)受到 %.0f 伤害, 剩余 HP: %.0f/%.0f" % [enemy_type, amount, hp, max_hp])

	# 受击像素特效（火花 + 伤害浮字）
	EffectsManager.spawn_hit_effect(global_position)
	EffectsManager.spawn_damage_number(global_position, int(amount))

	# 受击动画（AnimatedSprite2D 有 hit 动画则播放，没有则自动跳过）
	if anim_controller and anim_controller.has_method("play_hit"):
		anim_controller.play_hit()

	if hp <= 0:
		_die()


## 死亡处理 —— 缩小消失 + 掉金币
func _die() -> void:
	if is_dead:
		return
	is_dead = true

	print("[EnemyMovement] 敌人(%s)被击杀!" % enemy_type)

	# 死亡像素爆炸特效
	EffectsManager.spawn_death_effect(global_position)

	# 发出死亡信号（Economy 会给奖励）
	SignalBus.enemy_died.emit(enemy_type, _get_kill_reward())

	# 给 Economy 加金币
	Economy.on_enemy_killed(enemy_type)

	# 死亡动画：通过动画控制器播放（有 death 动画则播放，否则立即销毁）
	if anim_controller and anim_controller.has_method("play_death"):
		if anim_controller.has_signal("death_animation_finished"):
			anim_controller.connect("death_animation_finished", self.queue_free, CONNECT_ONE_SHOT)
		anim_controller.play_death()
		# 兜底：2秒后强制销毁（防止动画控制器信号不触发导致尸体残留）
		get_tree().create_timer(2.0).timeout.connect(func(): if is_instance_valid(self): queue_free())
	else:
		# 兼容旧逻辑：没有动画控制器时用 Tween
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.4)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.4)
		tween.connect("finished", queue_free)


# ---------- 工具函数 ----------
## 获取该类型敌人的击杀奖励金（与 economy.gd 保持一致，2026-07-01 调整）
func _get_kill_reward() -> int:
	match enemy_type:
		Constants.ENEMY_GRUNT:
			return 3   # 普通 5→3
		Constants.ENEMY_GHOST:
			return 5   # 快速 8→5
		Constants.ENEMY_ELITE:
			return 12  # 精英 25→12
		_:
			return 3


## 在场景树中查找核心节点
func _find_core_node() -> Node2D:
	# 从场景根节点查找名为 "Core" 的子节点
	var root := get_tree().current_scene
	if root:
		var core := root.find_child("Core", true, false)
		if core is Node2D:
			return core
	return null
