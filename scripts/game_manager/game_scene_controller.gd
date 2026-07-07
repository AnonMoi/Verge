## game_scene_controller.gd
## 主游戏场景控制器 — 初始化游戏循环、连接各模块信号
## 挂载在 main_game.tscn 的根节点 MainGame 上

extends Node2D

# ---------- 生命周期 ----------
func _ready() -> void:
	print("[GameScene] === 游戏场景加载完成 ===")

	# 1. 启动时间循环
	_start_time_cycle()

	# 2. 连接黎明特效
	_connect_dawn_effect()

	# 3. 初始化经济系统
	_init_economy()

	# 4. 连接核心销毁 → 游戏结束
	_connect_game_over()

	# 5. 通知 GameManager
	GameManager.start_level("tutorial")


func _process(_delta: float) -> void:
	pass


# ---------- 初始化方法 ----------
## 启动时间循环
func _start_time_cycle() -> void:
	if not TimeCycle.is_cycle_active:
		TimeCycle.start_cycle()
		print("[GameScene] 时间循环已启动!")


## 连接黎明特效
func _connect_dawn_effect() -> void:
	var dawn := find_child("DawnEffect", true, false)
	if dawn and dawn.has_method("play_dawn_effect"):
		SignalBus.dawn_triggered.connect(dawn.play_dawn_effect)
		print("[GameScene] 黎明特效已连接")


## 初始化经济（确保初始金币正确）
func _init_economy() -> void:
	if Economy.gold == 0:
		Economy.gold = Economy.starting_gold
	Economy.broadcast_gold_changed(0)


## 核心被摧毁 → 游戏结束
func _connect_game_over() -> void:
	SignalBus.core_destroyed.connect(_on_core_destroyed)


func _on_core_destroyed() -> void:
	print("[GameScene] 核心被摧毁! 游戏结束")
	GameManager.trigger_game_over()
	SignalBus.game_over.emit()
