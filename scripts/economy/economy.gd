## economy.gd
## 经济系统 — 管理金币、金矿、击杀奖励等
## Autoload 单例

extends Node

var gold: int = 0
var mines: Array[Node] = []  # 金矿节点列表

func _ready() -> void:
	# Constants 是 Node 实例，"in" 检查对 Node 不可靠
	# 直接使用硬编码默认值（后续可从 game_config.json 读取）
	# 2026-07-01: 改成 50 金（PVZ 式开局 —— 刚好够放 1 个金矿）
	gold = 50
	print("[Economy] 初始资金: ", gold)


## 重置经济到初始状态（从菜单进入新一局前调用）。
## 清空残留的金矿引用（旧金矿节点已随场景销毁，引用变无效）。
func reset_state() -> void:
	gold = 50
	mines.clear()
	print("[Economy] 状态已重置, 初始资金: ", gold)

func add_gold(amount: int) -> void:
	gold += amount

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		broadcast_gold_changed(amount)
		return true
	return false

func can_afford(amount: int) -> bool:
	return gold >= amount

func on_enemy_killed(enemy_type: String) -> void:
	var reward = _get_kill_reward(enemy_type)
	gold += reward
	GameManager.total_gold_earned += reward
	GameManager.total_kills += 1
	print("[Economy] 击杀 %s, 获得 %d 金" % [enemy_type, reward])
	broadcast_gold_changed(reward)

func on_mine_produced(mine_node: Node) -> void:
	# 直接用金矿节点的 gold_per_tick（策划书 3.5: 10金/次）
	var amount: int = 10
	if mine_node and mine_node.get("gold_per_tick") != null:
		amount = int(mine_node.get("gold_per_tick"))
	gold += amount
	GameManager.total_gold_earned += amount
	broadcast_gold_changed(amount)
	# 金矿产出浮字（像素风 +N★）
	if mine_node is Node2D:
		EffectsManager.spawn_gold_number((mine_node as Node2D).global_position, amount)

func register_mine(mine_node: Node) -> void:
	mines.append(mine_node)

func unregister_mine(mine_node: Node) -> void:
	mines.erase(mine_node)

func broadcast_gold_changed(amount: int) -> void:
	SignalBus.gold_changed.emit(gold)
	SignalBus.gold_changed_display.emit(amount)

func _get_kill_reward(enemy_type: String) -> int:
	match enemy_type:
		Constants.ENEMY_GRUNT:  return 3   # 2026-07-01 调: 普通 5→3
		Constants.ENEMY_GHOST:  return 5   # 2026-07-01 调: 快速 8→5
		Constants.ENEMY_ELITE:  return 12  # 2026-07-01 调: 精英 25→12
	return 0
