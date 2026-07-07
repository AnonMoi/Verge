## game_manager.gd
## 全局游戏管理器 — 管理游戏状态、关卡切换等
## Autoload 单例

extends Node

var current_level: String = ""
var current_day: int = 1
var is_paused: bool = false
var is_game_over: bool = false
var is_game_won: bool = false
var perfect_clear: bool = false  # 核心 HP > 70%

# 关卡统计
var level_start_time: float = 0.0   # 关卡开始的时间戳
var total_gold_earned: int = 0     # 本关累计获得金币
var total_deployed: int = 0        # 本关部署单位数（含金矿）
var total_kills: int = 0           # 本关击杀敌人数

func _ready() -> void:
	print("[GameManager] 初始化完成")

# ============ 测试快捷键（发布前删除）============
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# F3 — 直接触发胜利结算（跳过 3 天流程）
		if event.keycode == KEY_F3:
			_trigger_test_victory()
		# F4 — 直接触发失败结算
		elif event.keycode == KEY_F4:
			_trigger_test_game_over()

func _trigger_test_victory() -> void:
	if is_game_won or is_game_over:
		return
	# 模拟一些统计数据（让结算面板有内容）
	if total_deployed == 0:
		total_deployed = 3
	if total_kills == 0:
		total_kills = 8
	if total_gold_earned == 0:
		total_gold_earned = 45
	print("[GameManager][TEST] F9 触发胜利结算")
	trigger_game_won(false)
	SignalBus.game_won.emit()

func _trigger_test_game_over() -> void:
	if is_game_won or is_game_over:
		return
	print("[GameManager][TEST] F10 触发失败结算")
	trigger_game_over()
	SignalBus.game_over.emit()

func start_level(level_name: String) -> void:
	current_level = level_name
	current_day = 1
	is_game_over = false
	is_game_won = false
	is_paused = false
	# 重置统计
	level_start_time = Time.get_ticks_msec() / 1000.0
	total_gold_earned = 0
	total_deployed = 0
	total_kills = 0
	print("[GameManager] 开始关卡: ", level_name)

func set_paused(paused: bool) -> void:
	is_paused = paused
	Engine.time_scale = 1.0 if not paused else 0.0

func trigger_game_over() -> void:
	is_game_over = true
	is_paused = true
	AudioManager.stop_bgm(0.3)
	print("[GameManager] 游戏结束 — 第 %d 天" % current_day)

func trigger_game_won(perfect: bool = false) -> void:
	is_game_won = true
	perfect_clear = perfect
	is_paused = false
	AudioManager.stop_bgm(0.3)
	print("[GameManager] 关卡胜利! 完美通关: ", perfect)

func next_day() -> void:
	current_day += 1
	print("[GameManager] 进入第 %d 天" % current_day)
	# 发送天数变化信号（HUD 等模块监听）
	SignalBus.day_completed.emit(current_day)
