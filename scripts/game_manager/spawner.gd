## spawner.gd
## 敌人生成器 — 按教程关 3 天波次表生成敌人
## 策划书 4.1:
##   黄昏(30s): 少量先锋怪试探性进入
##   夜晚(90s): 怪潮来袭
##   Day 1: 黄昏3普通 / 夜晚8普通
##   Day 2: 黄昏3普通+2快速 / 夜晚12普通+4快速
##   Day 3: 黄昏2普通+2快速+1精英 / 夜晚16普通+6快速+3精英
## 挂载在 main_game.tscn 的 EnemySpawner 节点上

extends Node

# ---------- 属性 ----------
# 三种敌人场景（按类型选择对应场景）
const ENEMY_SCENES: Dictionary = {
	Constants.ENEMY_GRUNT:  preload("res://scenes/main_game/enemy_grunt.tscn"),
	Constants.ENEMY_GHOST:  preload("res://scenes/main_game/enemy_ghost.tscn"),
	Constants.ENEMY_ELITE:  preload("res://scenes/main_game/enemy_elite.tscn"),
}
@export var spawn_position: Vector2 = Vector2(32, 320)

var spawn_timer: float = 0.0
var spawned_count: int = 0
var is_spawning: bool = true
var current_plan: Array = []  # 当前阶段的生成计划（enemy_type 列表）
var current_interval: float = 8.0  # 当前生成间隔（秒）


# ---------- 教程关黄昏波次（少量试探） ----------
const DUSK_WAVES := {
	1: {  # Day 1 黄昏: 3 普通怪试探（让玩家实战练习）
		"plan": ["chaos_grunt", "chaos_grunt", "chaos_grunt"],
		"interval": 8.0,
	},
	2: {  # Day 2 黄昏: 3 普通 + 2 快速
		"plan": ["chaos_grunt", "chaos_grunt", "swift_ghost", "chaos_grunt", "swift_ghost"],
		"interval": 5.0,
	},
	3: {  # Day 3 黄昏: 2 普通 + 2 快速 + 1 精英（含精英压迫）
		"plan": ["chaos_grunt", "swift_ghost", "chaos_grunt", "swift_ghost", "iron_elite"],
		"interval": 4.0,
	},
}

# ---------- 教程关夜晚波次（怪潮） ----------
const TUTORIAL_WAVES := {
	1: {  # Day 1 夜晚: 8 只普通怪
		"plan": [
			"chaos_grunt", "chaos_grunt", "chaos_grunt",
			"chaos_grunt", "chaos_grunt", "chaos_grunt",
			"chaos_grunt", "chaos_grunt"
		],
		"interval": 10.0,  # 间隔 10 秒/只
	},
	2: {  # Day 2 夜晚: 12 普通 + 4 快速（=16只）
		"plan": [
			"chaos_grunt", "chaos_grunt", "swift_ghost",
			"chaos_grunt", "chaos_grunt", "swift_ghost",
			"chaos_grunt", "swift_ghost", "chaos_grunt",
			"chaos_grunt", "swift_ghost", "chaos_grunt",
			"chaos_grunt", "chaos_grunt", "swift_ghost", "chaos_grunt"
		],
		"interval": 5.0,  # 间隔 5 秒/只
	},
	3: {  # Day 3 夜晚: 16 普通 + 6 快速 + 3 精英（=25只）
		"plan": [
			"chaos_grunt", "chaos_grunt", "swift_ghost",
			"chaos_grunt", "swift_ghost", "chaos_grunt",
			"iron_elite", "chaos_grunt", "swift_ghost",
			"chaos_grunt", "chaos_grunt", "swift_ghost",
			"iron_elite", "chaos_grunt", "swift_ghost",
			"chaos_grunt", "iron_elite", "swift_ghost",
			"chaos_grunt", "chaos_grunt", "swift_ghost",
			"chaos_grunt", "swift_ghost", "chaos_grunt", "chaos_grunt"
		],
		"interval": 3.5,  # 间隔 3.5 秒/只（90秒内 25只）
	},
}


func _ready() -> void:
	# 验证三种敌人场景资源是否加载成功
	for enemy_type in ENEMY_SCENES:
		if not ENEMY_SCENES[enemy_type]:
			printerr("[Spawner] 场景资源加载失败: ", enemy_type)
		print("[Spawner] 已加载敌人场景: ", enemy_type)

	SignalBus.cycle_phase_changed.connect(_on_phase_changed)
	SignalBus.day_completed.connect(_on_day_completed)


func _process(delta: float) -> void:
	if not is_spawning:
		return

	if not TimeCycle.is_cycle_active:
		return

	# 黄昏和夜晚都生成敌人
	if TimeCycle.current_phase != TimeCycle.Phase.DUSK and TimeCycle.current_phase != TimeCycle.Phase.NIGHT:
		return

	if current_plan.is_empty():
		return

	if spawned_count >= current_plan.size():
		return

	spawn_timer += delta
	if spawn_timer >= current_interval:
		spawn_timer = 0.0
		_spawn_enemy()


# ---------- 阶段回调 ----------
func _on_phase_changed(phase_name: String) -> void:
	match phase_name:
		"黄昏":
			# 黄昏 → 加载少量试探怪
			_load_dusk_plan(GameManager.current_day)
			spawned_count = 0
			spawn_timer = current_interval * 0.5
			is_spawning = true
			print("[Spawner] 黄昏来临! 当前计划: %d 只" % current_plan.size())
		"夜晚":
			# 夜晚 → 加载怪潮计划
			_load_plan_for_day(GameManager.current_day)
			spawned_count = 0
			spawn_timer = current_interval * 0.5
			is_spawning = true
			print("[Spawner] 夜晚来临! 当前计划: %d 只" % current_plan.size())
		"白天":
			is_spawning = false
		"黎明":
			is_spawning = false
			print("[Spawner] 黎明! 停止生成")


# ---------- 天数回调 ----------
## 当前天数变化时 → 根据 Day N 加载对应波次计划
func _on_day_completed(day_index: int) -> void:
	# day_index 是 GameManager 递增后的"新一天"
	# 但生成计划按"第 N 夜的怪"对应 Day N 的夜晚
	# 所以当 day=N 时，准备的就是 Day N 夜晚要打的怪
	_load_plan_for_day(day_index)


## 按天数加载教程关的波次计划
func _load_plan_for_day(day_index: int) -> void:
	if TUTORIAL_WAVES.has(day_index):
		var wave = TUTORIAL_WAVES[day_index]
		current_plan = wave.plan.duplicate()
		current_interval = wave.interval
		print("[Spawner] Day %d 夜晚计划已加载: %d 只, 间隔 %.1fs" % [day_index, current_plan.size(), current_interval])
	else:
		# Day > 3: 教程关结束，不再生成
		current_plan = []
		is_spawning = false
		print("[Spawner] Day %d 超出教程关波次表, 停止生成" % day_index)


## 按天数加载黄昏波次计划（少量试探怪）
func _load_dusk_plan(day_index: int) -> void:
	if DUSK_WAVES.has(day_index):
		var wave = DUSK_WAVES[day_index]
		current_plan = wave.plan.duplicate()
		current_interval = wave.interval
		print("[Spawner] Day %d 黄昏计划已加载: %d 只, 间隔 %.1fs" % [day_index, current_plan.size(), current_interval])
	else:
		current_plan = []
		is_spawning = false


# ---------- 生成敌人 ----------
func _spawn_enemy() -> void:
	if spawned_count >= current_plan.size():
		return

	# 从 plan 中按顺序取出敌人类型
	var enemy_type: String = current_plan[spawned_count]

	# 根据类型选择对应场景
	var scene: PackedScene = ENEMY_SCENES.get(enemy_type)
	if not scene:
		printerr("[Spawner] 未找到敌人类型对应场景: ", enemy_type)
		return

	# 实例化敌人
	var enemy := scene.instantiate()
	enemy.position = spawn_position

	# 根据 enemy_type 应用数值（从 enemies.json 读取）
	_apply_enemy_stats(enemy, enemy_type)

	# 添加到场景根节点的 Enemies 容器下
	var root := get_tree().current_scene
	if root:
		var enemies_container := root.find_child("Enemies", false, false)
		if enemies_container:
			enemies_container.add_child(enemy)
		else:
			root.add_child(enemy)

	spawned_count += 1
	print("[Spawner] 生成敌人 #%d (%s) (位置: %.0f, %.0f)" % [spawned_count, enemy_type, spawn_position.x, spawn_position.y])

	# 发送敌人生成信号
	SignalBus.enemy_spawned.emit(enemy_type, "left_entry")


# ---------- 应用敌人数值（从 JSON 读取） ----------
func _apply_enemy_stats(enemy: Node, enemy_type: String) -> void:
	# 设置 enemy_type
	enemy.set("enemy_type", enemy_type)

	# 从 enemies.json 加载配置
	var json_path := "res://resources/data/enemies/enemies.json"
	if not FileAccess.file_exists(json_path):
		return

	var file := FileAccess.open(json_path, FileAccess.READ)
	if not file:
		return
	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(content) != OK:
		printerr("[Spawner] JSON 解析失败: ", json.get_error_message())
		return

	var data: Dictionary = json.data
	if not data.has("enemies"):
		return
	var enemies: Dictionary = data["enemies"]
	if not enemies.has(enemy_type):
		return

	var cfg: Dictionary = enemies[enemy_type]
	# 应用策划书定义的数值
	enemy.set("max_hp", float(cfg.get("hp", 50)))
	enemy.set("hp", float(cfg.get("hp", 50)))
	enemy.set("speed", float(cfg.get("speed", 80)))
	enemy.set("core_damage", float(cfg.get("core_damage", 10)))
