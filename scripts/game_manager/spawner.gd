extends Node

const ENEMY_SCENES: Dictionary = {
	Constants.ENEMY_GRUNT:  preload("res://scenes/main_game/enemy_grunt.tscn"),
	Constants.ENEMY_GHOST:  preload("res://scenes/main_game/enemy_ghost.tscn"),
	Constants.ENEMY_ELITE:  preload("res://scenes/main_game/enemy_elite.tscn"),
	Constants.BOSS_SHADOW_LORD: preload("res://scenes/main_game/boss_shadow_lord.tscn"),
}
@export var spawn_position: Vector2 = Vector2(32, 320)

var spawn_timer: float = 0.0
var spawned_count: int = 0
var is_spawning: bool = true
var current_plan: Array = []
var current_interval: float = 8.0

var level_config: Dictionary = {}
var is_boss_spawned: bool = false


const DUSK_WAVES := {
	1: {
		"plan": ["chaos_grunt", "chaos_grunt", "chaos_grunt"],
		"interval": 8.0,
	},
	2: {
		"plan": ["chaos_grunt", "chaos_grunt", "swift_ghost", "chaos_grunt", "swift_ghost"],
		"interval": 5.0,
	},
	3: {
		"plan": ["chaos_grunt", "swift_ghost", "chaos_grunt", "swift_ghost", "iron_elite"],
		"interval": 4.0,
	},
}

const TUTORIAL_WAVES := {
	1: {
		"plan": [
			"chaos_grunt", "chaos_grunt", "chaos_grunt",
			"chaos_grunt", "chaos_grunt", "chaos_grunt",
			"chaos_grunt", "chaos_grunt"
		],
		"interval": 10.0,
	},
	2: {
		"plan": [
			"chaos_grunt", "chaos_grunt", "swift_ghost",
			"chaos_grunt", "chaos_grunt", "swift_ghost",
			"chaos_grunt", "swift_ghost", "chaos_grunt",
			"chaos_grunt", "swift_ghost", "chaos_grunt",
			"chaos_grunt", "chaos_grunt", "swift_ghost", "chaos_grunt"
		],
		"interval": 5.0,
	},
	3: {
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
		"interval": 3.5,
	},
}


func _ready() -> void:
	for enemy_type in ENEMY_SCENES:
		if not ENEMY_SCENES[enemy_type]:
			printerr("[Spawner] 场景资源加载失败: ", enemy_type)
		print("[Spawner] 已加载敌人场景: ", enemy_type)

	_load_level_config()
	SignalBus.cycle_phase_changed.connect(_on_phase_changed)
	SignalBus.day_completed.connect(_on_day_completed)


func _load_level_config() -> void:
	var level_id := GameManager.current_level
	var config_path := "res://resources/config/levels/level_%s.json" % level_id
	if FileAccess.file_exists(config_path):
		var file := FileAccess.open(config_path, FileAccess.READ)
		if file:
			var content := file.get_as_text()
			file.close()
			var json := JSON.new()
			if json.parse(content) == OK:
				level_config = json.data
				print("[Spawner] 加载关卡配置: %s" % level_id)
				return
	print("[Spawner] 未找到关卡配置，使用默认教程关")


func _process(delta: float) -> void:
	if not is_spawning:
		return

	if not TimeCycle.is_cycle_active:
		return

	if TimeCycle.current_phase != TimeCycle.Phase.DUSK and TimeCycle.current_phase != TimeCycle.Phase.NIGHT:
		return

	if current_plan.is_empty():
		_check_boss_spawn()
		return

	if spawned_count >= current_plan.size():
		_check_boss_spawn()
		return

	spawn_timer += delta
	if spawn_timer >= current_interval:
		spawn_timer = 0.0
		_spawn_enemy()


func _check_boss_spawn() -> void:
	if is_boss_spawned:
		return

	if level_config.has("boss"):
		var boss_cfg := level_config["boss"]
		if boss_cfg.get("enabled", false):
			if GameManager.current_day == boss_cfg.get("spawn_day", 3):
				if TimeCycle.current_phase == TimeCycle.Phase.NIGHT:
					_spawn_boss(boss_cfg)
					is_boss_spawned = true


func _spawn_boss(boss_cfg: Dictionary) -> void:
	var boss_type := boss_cfg.get("boss_type", "shadow_lord")
	var scene: PackedScene = ENEMY_SCENES.get(boss_type)
	if not scene:
		printerr("[Spawner] 未找到 Boss 场景: ", boss_type)
		return

	var boss := scene.instantiate()
	boss.position = spawn_position

	var root := get_tree().current_scene
	if root:
		var enemies_container := root.find_child("Enemies", false, false)
		if enemies_container:
			enemies_container.add_child(boss)
		else:
			root.add_child(boss)

	is_spawning = false
	print("[Spawner] Boss 生成: %s" % boss_type)
	SignalBus.boss_spawned.emit(boss_type)


func _on_phase_changed(phase_name: String) -> void:
	match phase_name:
		"黄昏":
			_load_dusk_plan(GameManager.current_day)
			spawned_count = 0
			spawn_timer = current_interval * 0.5
			is_spawning = true
			print("[Spawner] 黄昏来临! 当前计划: %d 只" % current_plan.size())
		"夜晚":
			_load_plan_for_day(GameManager.current_day)
			spawned_count = 0
			spawn_timer = current_interval * 0.5
			is_spawning = true
			print("[Spawner] 夜晚来临! 当前计划: %d 只" % current_plan.size())
		"白天":
			is_spawning = false
		"黎明":
			is_spawning = false
			is_boss_spawned = false
			print("[Spawner] 黎明! 停止生成")


func _on_day_completed(day_index: int) -> void:
	is_boss_spawned = false
	_load_plan_for_day(day_index)


func _load_plan_for_day(day_index: int) -> void:
	if level_config.has("waves") and level_config["waves"].has("night"):
		var night_waves := level_config["waves"]["night"]
		var day_key := "day_%d" % day_index
		if night_waves.has(day_key):
			var wave := night_waves[day_key]
			current_plan = _expand_enemy_plan(wave.get("enemies", []))
			current_interval = wave.get("spawn_interval", 5.0)
			print("[Spawner] Day %d 夜晚计划已加载: %d 只, 间隔 %.1fs" % [day_index, current_plan.size(), current_interval])
			return

	if TUTORIAL_WAVES.has(day_index):
		var wave = TUTORIAL_WAVES[day_index]
		current_plan = wave.plan.duplicate()
		current_interval = wave.interval
		print("[Spawner] Day %d 夜晚计划已加载: %d 只, 间隔 %.1fs" % [day_index, current_plan.size(), current_interval])
	else:
		current_plan = []
		is_spawning = false
		print("[Spawner] Day %d 超出波次表, 停止生成" % day_index)


func _load_dusk_plan(day_index: int) -> void:
	if level_config.has("waves") and level_config["waves"].has("dusk"):
		var dusk_waves := level_config["waves"]["dusk"]
		var day_key := "day_%d" % day_index
		if dusk_waves.has(day_key):
			var wave := dusk_waves[day_key]
			current_plan = _expand_enemy_plan(wave.get("enemies", []))
			current_interval = wave.get("spawn_interval", 6.0)
			print("[Spawner] Day %d 黄昏计划已加载: %d 只, 间隔 %.1fs" % [day_index, current_plan.size(), current_interval])
			return

	if DUSK_WAVES.has(day_index):
		var wave = DUSK_WAVES[day_index]
		current_plan = wave.plan.duplicate()
		current_interval = wave.interval
		print("[Spawner] Day %d 黄昏计划已加载: %d 只, 间隔 %.1fs" % [day_index, current_plan.size(), current_interval])
	else:
		current_plan = []
		is_spawning = false


func _expand_enemy_plan(enemies: Array) -> Array:
	var plan: Array = []
	for enemy in enemies:
		var enemy_type := enemy.get("type", "chaos_grunt")
		var count := enemy.get("count", 1)
		for i in range(count):
			plan.append(enemy_type)
	return plan


func _spawn_enemy() -> void:
	if spawned_count >= current_plan.size():
		return

	var enemy_type: String = current_plan[spawned_count]

	var scene: PackedScene = ENEMY_SCENES.get(enemy_type)
	if not scene:
		printerr("[Spawner] 未找到敌人类型对应场景: ", enemy_type)
		return

	var enemy := scene.instantiate()
	enemy.position = spawn_position

	_apply_enemy_stats(enemy, enemy_type)

	var root := get_tree().current_scene
	if root:
		var enemies_container := root.find_child("Enemies", false, false)
		if enemies_container:
			enemies_container.add_child(enemy)
		else:
			root.add_child(enemy)

	spawned_count += 1
	print("[Spawner] 生成敌人 #%d (%s) (位置: %.0f, %.0f)" % [spawned_count, enemy_type, spawn_position.x, spawn_position.y])

	SignalBus.enemy_spawned.emit(enemy_type, "left_entry")


func _apply_enemy_stats(enemy: Node, enemy_type: String) -> void:
	enemy.set("enemy_type", enemy_type)

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
	enemy.set("max_hp", float(cfg.get("hp", 50)))
	enemy.set("hp", float(cfg.get("hp", 50)))
	enemy.set("speed", float(cfg.get("speed", 80)))
	enemy.set("core_damage", float(cfg.get("core_damage", 10)))