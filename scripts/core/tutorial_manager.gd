extends Node

var current_step: int = 0
var is_tutorial_active: bool = true
var tutorial_steps: Array = []
var displayed_steps: Array = []

const TUTORIAL_DATA = [
	{
		"id": "welcome",
		"trigger": "game_start",
		"text": "欢迎来到 Verge。那个钟摆就是你要守护的核心。",
		"position": Vector2(600, 100)
	},
	{
		"id": "gold_mine",
		"trigger": "day_start",
		"text": "点击地面格子来放置一个金矿。",
		"position": Vector2(200, 300),
		"day": 1
	},
	{
		"id": "gold_produce",
		"trigger": "mine_placed",
		"text": "金矿正在为你产生金币...现在你有足够的钱来部署第一位角色了！",
		"position": Vector2(200, 300)
	},
	{
		"id": "deploy_pioneer",
		"trigger": "gold_changed",
		"text": "在地面部署一位先锋。她可以阻挡敌人的前进。",
		"position": Vector2(300, 300),
		"min_gold": 20
	},
	{
		"id": "dusk_warning",
		"trigger": "phase_dusk",
		"text": "黄昏了！敌人即将来临，检查你的防线...",
		"position": Vector2(600, 100),
		"day": 1
	},
	{
		"id": "night_battle",
		"trigger": "phase_night",
		"text": "夜晚降临！你的先锋正在自动攻击敌人。",
		"position": Vector2(600, 100),
		"day": 1
	},
	{
		"id": "dawn_victory",
		"trigger": "phase_dawn",
		"text": "太棒了！黎明到来——钟摆敲响丧钟，剩余敌人被清除！",
		"position": Vector2(600, 100),
		"day": 1
	},
	{
		"id": "day2_deploy_sniper",
		"trigger": "day_start",
		"text": "第二天！尝试在高台部署一位狙击手，她可以远距离攻击敌人。",
		"position": Vector2(500, 200),
		"day": 2
	},
	{
		"id": "day3_final",
		"trigger": "day_start",
		"text": "最后一天！合理分配资源，坚守防线直到黎明！",
		"position": Vector2(600, 100),
		"day": 3
	}
]

func _ready() -> void:
	SignalBus.game_started.connect(_on_game_start)
	SignalBus.cycle_phase_changed.connect(_on_phase_changed)
	SignalBus.day_completed.connect(_on_day_completed)
	SignalBus.gold_changed.connect(_on_gold_changed)
	SignalBus.mine_placed.connect(_on_mine_placed)
	SignalBus.character_deployed.connect(_on_character_deployed)

func _on_game_start() -> void:
	if not is_tutorial_active:
		return
	_show_tutorial("welcome")

func _on_phase_changed(phase_name: String) -> void:
	if not is_tutorial_active:
		return
	
	var trigger_map: Dictionary = {
		"白天": "phase_day",
		"黄昏": "phase_dusk",
		"夜晚": "phase_night",
		"黎明": "phase_dawn"
	}
	
	var trigger := trigger_map.get(phase_name, "")
	if trigger == "":
		return
	
	for step in TUTORIAL_DATA:
		if step.get("trigger") == trigger and step.get("id") not in displayed_steps:
			var required_day := step.get("day", 0)
			if required_day > 0 and required_day != GameManager.current_day:
				continue
			_show_tutorial(step["id"])
			break

func _on_day_completed(day_index: int) -> void:
	if not is_tutorial_active:
		return
	
	for step in TUTORIAL_DATA:
		if step.get("trigger") == "day_start" and step.get("id") not in displayed_steps:
			if step.get("day", 0) == day_index + 1:
				_show_tutorial(step["id"])
				break

func _on_gold_changed(gold: int) -> void:
	if not is_tutorial_active:
		return
	
	for step in TUTORIAL_DATA:
		if step.get("trigger") == "gold_changed" and step.get("id") not in displayed_steps:
			var min_gold := step.get("min_gold", 0)
			if gold >= min_gold:
				_show_tutorial(step["id"])
				break

func _on_mine_placed() -> void:
	if not is_tutorial_active:
		return
	_show_tutorial("gold_produce")

func _on_character_deployed(char_id: String) -> void:
	if not is_tutorial_active:
		return
	
	var deploy_triggers: Dictionary = {
		"pioneer": "deploy_pioneer",
		"sniper": "deploy_sniper"
	}
	
	var trigger := deploy_triggers.get(char_id, "")
	if trigger == "":
		return
	
	for step in TUTORIAL_DATA:
		if step.get("trigger") == trigger and step.get("id") not in displayed_steps:
			_show_tutorial(step["id"])
			break

func _show_tutorial(step_id: String) -> void:
	for step in TUTORIAL_DATA:
		if step["id"] == step_id and step_id not in displayed_steps:
			displayed_steps.append(step_id)
			var position := step.get("position", Vector2(600, 100))
			SignalBus.show_tutorial.emit(step["text"], position)
			print("[Tutorial] 显示教学步骤: ", step_id)
			break

func set_active(active: bool) -> void:
	is_tutorial_active = active

func reset() -> void:
	current_step = 0
	displayed_steps.clear()
	is_tutorial_active = true
