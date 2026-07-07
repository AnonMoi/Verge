extends CanvasLayer

@onready var panel: Panel = $Panel
@onready var name_label: Label = $Panel/NameLabel
@onready var text_label: Label = $Panel/TextLabel
@onready var continue_label: Label = $Panel/ContinueLabel

var dialogues: Array = []
var current_index: int = 0
var is_typing: bool = false
var typing_speed: float = 0.03
var full_text: String = ""
var displayed_text: String = ""
var typing_timer: Timer = null

func _ready() -> void:
	panel.visible = false
	continue_label.visible = false
	
	typing_timer = Timer.new()
	typing_timer.autostart = false
	typing_timer.wait_time = typing_speed
	typing_timer.timeout.connect(_on_typing_timeout)
	add_child(typing_timer)
	
	panel.gui_input.connect(_on_panel_input)
	SignalBus.show_dialogue.connect(_on_show_dialogue)
	SignalBus.dialogue_finished.connect(_on_dialogue_finished)
	print("[DialoguePanel] 初始化完成，信号已连接")

func _on_show_dialogue(dialogue_list: Array) -> void:
	print("[DialoguePanel] ✅ 收到对话信号! 对话数量: %d" % dialogue_list.size())
	if dialogue_list.size() > 0:
		print("[DialoguePanel] 第一条对话: ", dialogue_list[0])
	dialogues = dialogue_list
	current_index = 0
	panel.visible = true
	Engine.time_scale = 0.0
	_show_current_dialogue()

func _show_current_dialogue() -> void:
	if current_index >= dialogues.size():
		_end_dialogue()
		return
	
	var dialogue := dialogues[current_index]
	var speaker := dialogue.get("speaker", "")
	full_text = dialogue.get("text", "")
	
	name_label.text = speaker
	name_label.visible = speaker != ""
	
	displayed_text = ""
	text_label.text = displayed_text
	is_typing = true
	continue_label.visible = false
	
	typing_timer.start()

func _on_typing_timeout() -> void:
	if displayed_text.length() < full_text.length():
		displayed_text += full_text[displayed_text.length()]
		text_label.text = displayed_text
	else:
		_typing_complete()

func _typing_complete() -> void:
	is_typing = false
	typing_timer.stop()
	continue_label.visible = true
	text_label.text = full_text

func _on_panel_input(event: InputEvent) -> void:
	if not panel.visible:
		return
	
	if event is InputEventMouseButton and event.pressed:
		_handle_input()
	
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_handle_input()

func _handle_input() -> void:
	if is_typing:
		_typing_complete()
	else:
		current_index += 1
		if current_index < dialogues.size():
			_show_current_dialogue()
		else:
			_end_dialogue()

func _end_dialogue() -> void:
	panel.visible = false
	Engine.time_scale = 1.0
	StoryManager.dialogue_finished()

func _on_dialogue_finished() -> void:
	panel.visible = false
