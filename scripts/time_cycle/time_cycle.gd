## time_cycle.gd
## 时间循环系统 — 管理白天/黄昏/夜晚/黎明阶段切换
## Autoload 单例

extends Node

enum Phase { DAY, DUSK, NIGHT }

var current_phase: Phase = Phase.DAY
var current_timer: float = 0.0
var phase_duration: float = 0.0

var is_cycle_active: bool = false
var is_cycle_paused: bool = false

# 阶段名称（中文显示用）
func get_phase_name(phase: Phase) -> String:
	match phase:
		Phase.DAY:   return "白天"
		Phase.DUSK:  return "黄昏"
		Phase.NIGHT: return "夜晚"
	return "未知"

func get_phase_display_icon(phase: Phase) -> String:
	match phase:
		Phase.DAY:   return "☀️"
		Phase.DUSK:  return "🌆"
		Phase.NIGHT: return "🌙"
	return ""

func start_cycle() -> void:
	is_cycle_active = true
	start_phase(Phase.DAY)

func start_phase(phase: Phase) -> void:
	current_phase = phase
	match phase:
		Phase.DAY:
			phase_duration = Constants.DAY_DURATION
			AudioManager.play_bgm("day")
		Phase.DUSK:
			phase_duration = Constants.DUSK_DURATION
			AudioManager.play_bgm("dusk")
		Phase.NIGHT:
			phase_duration = Constants.NIGHT_DURATION
			AudioManager.play_bgm("night")
	current_timer = phase_duration

	# 发射阶段切换信号（供 UI、Spawner 等监听）
	var phase_name := get_phase_name(phase)
	SignalBus.cycle_phase_changed.emit(phase_name)
	print("[TimeCycle] 阶段切换 → %s (持续%.0f秒)" % [phase_name, phase_duration])

func _process(delta: float) -> void:
	if not is_cycle_active or is_cycle_paused:
		return

	current_timer -= delta
	if current_timer <= 0:
		advance_phase()

func advance_phase() -> void:
	match current_phase:
		Phase.DAY:
			start_phase(Phase.DUSK)
		Phase.DUSK:
			start_phase(Phase.NIGHT)
		Phase.NIGHT:
			trigger_dawn()

func trigger_dawn() -> void:
	print("[TimeCycle] 黎明! 第 %d 天结束 (day=%d)" % [GameManager.current_day, GameManager.current_day])

	# 发射黎明信号
	SignalBus.dawn_triggered.emit(GameManager.current_day)

	# 直接调用 DawnEffect.play_dawn_effect()（保险：信号链可能断）
	var scene := get_tree().current_scene
	if scene:
		var dawn := scene.find_child("DawnEffect", true, false)
		if dawn and dawn.has_method("play_dawn_effect"):
			print("[TimeCycle] ▶ 直接调用 DawnEffect.play_dawn_effect()")
			dawn.play_dawn_effect()
		else:
			print("[TimeCycle] ⚠ 找不到 DawnEffect 节点")

	# 黎明逻辑 —— 由 DawnEffect 处理敌人消散、角色恢复等视觉特效
	is_cycle_active = false

	# 用 Timer 节点等待 3 秒（比 await 更稳，避免 autoload await 状态问题）
	dawn_transition_timer.start(3.0)


# Timer 节点 - 在编辑器/代码中自动添加
var dawn_transition_timer: Timer

func _enter_tree() -> void:
	# 在 autoload 启动时创建一次性 Timer
	dawn_transition_timer = Timer.new()
	dawn_transition_timer.one_shot = true
	dawn_transition_timer.autostart = false
	dawn_transition_timer.timeout.connect(_on_dawn_transition_finished)
	add_child(dawn_transition_timer)


# 3 秒等待结束 → 进入下一天白天
func _on_dawn_transition_finished() -> void:
	print("[TimeCycle] ▶ 3秒等待结束, 准备进入下一天")
	GameManager.next_day()

	# 策划书 4.1: 教程关是 3 天循环，Day 3 黎明后胜利
	if GameManager.current_day > Constants.TUTORIAL_TOTAL_DAYS:
		# 计算 perfect_clear：核心 HP > 70% 视为完美通关
		var perfect := _check_perfect_clear()
		print("[TimeCycle] 🎉 第 %d 天黎明! 教程关胜利! 完美通关=%s" % [Constants.TUTORIAL_TOTAL_DAYS, perfect])
		is_cycle_active = false
		GameManager.trigger_game_won(perfect)
		SignalBus.game_won.emit()
		return

	# 重启循环（确保从 DawnEffect 留下的 pause 状态恢复）
	is_cycle_active = true
	is_cycle_paused = false
	resume()  # 兜底：万一 DawnEffect pause 了，这里强制恢复
	start_phase(Phase.DAY)
	print("[TimeCycle] ▶ 进入第 %d 天白天, current_timer=%.1f" % [GameManager.current_day, current_timer])

func pause() -> void:
	is_cycle_paused = true

func resume() -> void:
	is_cycle_paused = false


## 重置时间循环到初始状态（从菜单进入新一局前调用）。
## 停掉可能残留的黎明过渡计时器，避免上一局的回调串到新场景。
func reset_state() -> void:
	is_cycle_active = false
	is_cycle_paused = false
	current_phase = Phase.DAY
	current_timer = 0.0
	phase_duration = 0.0
	if dawn_transition_timer:
		dawn_transition_timer.stop()
	print("[TimeCycle] 状态已重置")


## 判断是否完美通关：核心 HP 比例 > 70%
func _check_perfect_clear() -> bool:
	var scene := get_tree().current_scene
	if not scene:
		return false
	var core := scene.find_child("Core", true, false)
	if not core:
		return false
	var hp: float = float(core.get("current_hp"))
	var max_hp_val: float = float(core.get("max_hp"))
	if max_hp_val <= 0.0:
		return false
	var ratio: float = hp / max_hp_val
	return ratio > Constants.DAWN_BONUS_CORE_THRESHOLD

func get_time_remaining() -> float:
	return maxf(0.0, current_timer)

func get_progress() -> float:
	if phase_duration <= 0:
		return 0.0
	return 1.0 - (current_timer / phase_duration)
