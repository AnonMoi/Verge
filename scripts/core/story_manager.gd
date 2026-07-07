extends Node

var world_lore: Dictionary = {}
var characters: Dictionary = {}
var lords: Dictionary = {}
var chapters: Dictionary = {}
var dialogues: Dictionary = {}
var terminology: Dictionary = {}

var current_chapter: String = ""
var current_dialogue_index: int = 0
var is_dialogue_active: bool = false

const STORY_DIR: String = "res://resources/data/story/"

func _ready() -> void:
	_load_story_data()
	print("[StoryManager] 剧情数据加载完成")

func _load_story_data() -> void:
	_load_json("world_lore.json", "world_lore")
	_load_json("characters.json", "characters")
	_load_json("lords.json", "lords")
	_load_json("chapters.json", "chapters")
	_load_json("dialogues.json", "dialogues")
	_load_json("terminology.json", "terminology")

func _load_json(file_name: String, var_name: String) -> void:
	var file := FileAccess.open(STORY_DIR + file_name, FileAccess.READ)
	if not file:
		print("[StoryManager] ⚠ 无法加载: ", file_name)
		return
	var content := file.get_as_text()
	file.close()
	var json := JSON.new()
	var error := json.parse(content)
	if error == OK:
		set(var_name, json.data)
		print("[StoryManager] ✅ 加载成功: ", file_name)
	else:
		print("[StoryManager] ❌ JSON解析失败: ", file_name, " - ", json.get_error_message())

func set_current_chapter(chapter_id: String) -> void:
	current_chapter = chapter_id
	current_dialogue_index = 0

func get_chapter_data(chapter_id: String) -> Dictionary:
	return chapters.get(chapter_id, {})

func get_chapter_dialogues(chapter_id: String) -> Array:
	return dialogues.get(chapter_id, {}).get("opening", [])

func get_chapter_opening_dialogue(chapter_id: String) -> Array:
	var chapter_data := get_chapter_data(chapter_id)
	if chapter_id == "chapter_0":
		return _get_prologue_opening_dialogue()
	if chapter_data.has("opening_cg") and chapter_data["opening_cg"].has("dialogues"):
		return chapter_data["opening_cg"]["dialogues"]
	return get_chapter_dialogues(chapter_id)

func _get_prologue_opening_dialogue() -> Array:
	var prologue := chapters.get("prologue", {})
	print("[StoryManager] 章节数据: chapters.has('prologue')=%s" % chapters.has("prologue"))
	print("[StoryManager] prologue keys: ", prologue.keys())
	var dialogue_list := []
	if prologue.has("pre_level_dialogue"):
		var pre_dialogue := prologue["pre_level_dialogue"]
		print("[StoryManager] pre_level_dialogue keys: ", pre_dialogue.keys())
		if pre_dialogue.has("dialogues"):
			var dlg := pre_dialogue["dialogues"]
			print("[StoryManager] 对话数量: %d" % dlg.size())
			dialogue_list.append_array(dlg)
		if pre_dialogue.has("rita_house") and pre_dialogue["rita_house"].has("dialogues"):
			var rita_dlg := pre_dialogue["rita_house"]["dialogues"]
			print("[StoryManager] 丽塔对话数量: %d" % rita_dlg.size())
			dialogue_list.append_array(rita_dlg)
	return dialogue_list

func get_chapter_ending_dialogue(chapter_id: String) -> Array:
	var chapter_data := get_chapter_data(chapter_id)
	if chapter_data.has("key_plot") and chapter_data["key_plot"].has("dialogues"):
		return chapter_data["key_plot"]["dialogues"]
	var dialogue_data := dialogues.get(chapter_id, {})
	if dialogue_data.has("ending_dialogue"):
		return dialogue_data["ending_dialogue"]
	return []

func get_climax_dialogue(chapter_id: String) -> Array:
	var dialogue_data := dialogues.get(chapter_id, {})
	if dialogue_data.has("climax"):
		return dialogue_data["climax"]
	return []

func get_ending_redemption_dialogue() -> Dictionary:
	return dialogues.get("chapter_7", {}).get("ending_redemption", {})

func get_ending_annihilation_dialogue() -> Array:
	return dialogues.get("chapter_7", {}).get("ending_annihilation", [])

func get_character(character_id: String) -> Dictionary:
	return characters.get(character_id, {})

func get_lord(lord_id: String) -> Dictionary:
	return lords.get(lord_id, {})

func get_world_lore() -> Dictionary:
	return world_lore

func get_all_chapters() -> Array:
	var chapter_list := []
	if chapters.has("prologue"):
		var prologue := chapters["prologue"].duplicate()
		prologue["id"] = "chapter_0"
		chapter_list.append(prologue)
	for key in chapters:
		if key.begins_with("chapter_"):
			chapter_list.append(chapters[key])
	return chapter_list.sort_custom(func(a, b):
		var id_a := a.id.replace("chapter_", "")
		var id_b := b.id.replace("chapter_", "")
		return int(id_a) < int(id_b)
	)

func trigger_chapter_opening(chapter_id: String) -> void:
	set_current_chapter(chapter_id)
	var dialogue_list := get_chapter_opening_dialogue(chapter_id)
	print("[StoryManager] 获取章节对话: chapter=%s, size=%d" % [chapter_id, dialogue_list.size()])
	if dialogue_list.size() > 0:
		is_dialogue_active = true
		SignalBus.show_dialogue.emit(dialogue_list)
		print("[StoryManager] ✅ 触发章节开场对话: ", chapter_id)
	else:
		print("[StoryManager] ❌ 对话列表为空: ", chapter_id)

func trigger_chapter_ending(chapter_id: String) -> void:
	var dialogue_list := get_chapter_ending_dialogue(chapter_id)
	if dialogue_list.size() > 0:
		is_dialogue_active = true
		SignalBus.show_dialogue.emit(dialogue_list)
		print("[StoryManager] 触发章节结局对话: ", chapter_id)

func trigger_climax(chapter_id: String) -> void:
	var dialogue_list := get_climax_dialogue(chapter_id)
	if dialogue_list.size() > 0:
		is_dialogue_active = true
		SignalBus.show_dialogue.emit(dialogue_list)
		print("[StoryManager] 触发高潮对话: ", chapter_id)

func dialogue_finished() -> void:
	is_dialogue_active = false
	SignalBus.dialogue_finished.emit()
	print("[StoryManager] 对话结束")

func get_chapter_title(chapter_id: String) -> String:
	var chapter_data := get_chapter_data(chapter_id)
	return chapter_data.get("title", "未知章节")

func get_chapter_map(chapter_id: String) -> String:
	var chapter_data := get_chapter_data(chapter_id)
	return chapter_data.get("map", "")

func get_chapter_lord(chapter_id: String) -> String:
	var chapter_data := get_chapter_data(chapter_id)
	return chapter_data.get("lord", "")

func get_boss_dialogue(chapter_id: String) -> Array:
	var dialogue_data := dialogues.get(chapter_id, {})
	if dialogue_data.has("night_boss"):
		var boss_dialogue := dialogue_data["night_boss"]
		if typeof(boss_dialogue) == TYPE_DICTIONARY:
			return [boss_dialogue]
		return boss_dialogue
	return []

func get_clear_dialogue(chapter_id: String) -> Array:
	var dialogue_data := dialogues.get(chapter_id, {})
	if dialogue_data.has("clear"):
		var clear_dialogue := dialogue_data["clear"]
		if typeof(clear_dialogue) == TYPE_DICTIONARY:
			return [clear_dialogue]
		return clear_dialogue
	return []

func get_branch_kill_dialogue(chapter_id: String) -> Array:
	var dialogue_data := dialogues.get(chapter_id, {})
	if dialogue_data.has("branch_kill"):
		var kill_dialogue := dialogue_data["branch_kill"]
		if typeof(kill_dialogue) == TYPE_DICTIONARY:
			return [kill_dialogue]
		return kill_dialogue
	return []

func get_branch_redemption_dialogue(chapter_id: String) -> Array:
	var dialogue_data := dialogues.get(chapter_id, {})
	if dialogue_data.has("branch_redemption"):
		var redemption_dialogue := dialogue_data["branch_redemption"]
		if typeof(redemption_dialogue) == TYPE_DICTIONARY:
			return [redemption_dialogue]
		return redemption_dialogue
	return []

func get_memory_text(chapter_id: String) -> String:
	var dialogue_data := dialogues.get(chapter_id, {})
	return dialogue_data.get("memory", "")

func get_ending_monologue(chapter_id: String) -> String:
	var dialogue_data := dialogues.get(chapter_id, {})
	return dialogue_data.get("ending_monologue", "")

func get_prologue_dialogue(key: String) -> Array:
	var prologue := dialogues.get("prologue", {})
	if prologue.has(key):
		var data := prologue[key]
		if typeof(data) == TYPE_DICTIONARY:
			return [data]
		return data
	return []

func get_terminology(term_id: String) -> Dictionary:
	if terminology.has("glossary"):
		for category in terminology["glossary"]:
			var terms := terminology["glossary"][category].get("terms", [])
			for term in terms:
				if term.get("id") == term_id:
					return term
	return {}

func get_terminology_by_category(category: String) -> Array:
	if terminology.has("glossary") and terminology["glossary"].has(category):
		return terminology["glossary"][category].get("terms", [])
	return []

func get_all_terminology() -> Dictionary:
	return terminology.get("glossary", {})

func get_revelation_dialogue() -> Array:
	return dialogues.get("chapter_7", {}).get("revelation", [])

func get_final_battle_dialogue() -> Array:
	return dialogues.get("chapter_7", {}).get("final_battle", [])