extends Node

var blessings: Array = []
var active_blessings: Dictionary = {}

func _ready() -> void:
	_load_blessings()
	SignalBus.dawn_triggered.connect(_on_dawn_triggered)

func _load_blessings() -> void:
	var json_path := "res://resources/data/blessings/blessings.json"
	if not FileAccess.file_exists(json_path):
		return

	var file := FileAccess.open(json_path, FileAccess.READ)
	if not file:
		return
	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(content) != OK:
		printerr("[BlessingManager] JSON 解析失败: ", json.get_error_message())
		return

	var data: Dictionary = json.data
	if data.has("blessings"):
		blessings = data["blessings"]
		print("[BlessingManager] 加载了 %d 个祝福" % blessings.size())

func _on_dawn_triggered(day_index: int) -> void:
	if day_index >= 2:
		_offer_blessing()

func _offer_blessing() -> void:
	if blessings.is_empty():
		return

	var random_blessing := blessings[randi() % blessings.size()]
	_apply_blessing(random_blessing)

	var message := "%s: %s" % [random_blessing.get("icon", ""), random_blessing.get("description", "")]
	SignalBus.show_notification.emit(message, 3.0)
	print("[BlessingManager] 黎明祝福: %s" % random_blessing.get("name", ""))

func _apply_blessing(blessing: Dictionary) -> void:
	var effect_type := blessing.get("effect_type", "")
	var value := blessing.get("value", 1.0)
	var duration := blessing.get("duration", 1)
	var blessing_id := blessing.get("id", "")

	match effect_type:
		"gold_multiplier":
			active_blessings["gold_multiplier"] = value
		"defense_multiplier":
			active_blessings["defense_multiplier"] = value
		"attack_multiplier":
			active_blessings["attack_multiplier"] = value
		"core_heal":
			CoreNode.heal(value)
		"deploy_cost_multiplier":
			active_blessings["deploy_cost_multiplier"] = value
		"character_heal":
			_heal_all_characters(value)

	if duration > 0:
		await get_tree().create_timer(120.0 * duration).timeout
		_remove_blessing(effect_type)

func _remove_blessing(effect_type: String) -> void:
	if active_blessings.has(effect_type):
		active_blessings.erase(effect_type)
		print("[BlessingManager] 祝福效果结束: %s" % effect_type)

func _heal_all_characters(percent: float) -> void:
	var root := get_tree().current_scene
	if not root:
		return

	var characters := root.find_child("Characters", false, false)
	if not characters:
		return

	for child in characters.get_children():
		if child.has_method("heal"):
			var max_hp := child.get("max_hp", 100.0)
			var heal_amount := max_hp * percent
			child.heal(heal_amount)

func get_effect(effect_type: String) -> float:
	return active_blessings.get(effect_type, 1.0)