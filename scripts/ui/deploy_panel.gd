## deploy_panel.gd
## 底部部署面板 — 角色部署 + 金矿建造（两套独立选中状态）
## extends CanvasLayer

extends CanvasLayer

class CharButtonData:
	var id: String
	var name_str: String
	var cost: int
	var deploy_type: String
	var range_cells: float
	var color: Color
	var button: Button
	var bg_texture_rect: TextureRect = null  # 按钮背景图节点

# 角色选中状态
var selected_char_id: String = ""
var char_buttons: Array = []

# 金矿选中状态（独立于角色）
var mine_selected: bool = false

# 攻击范围预览圈（最初版：单一柔和 Polygon2D 圆）
var range_preview: Polygon2D = null  # 单一柔和圆环
var hovered_slot_pos: Vector2 = Vector2.ZERO  # 当前鼠标悬浮的部署位位置

# 已部署角色操作面板（类明日方舟：点击角色后显示撤回操作）
var selected_recall_slot: Node = null
var selected_recall_character: Node2D = null
var recall_panel: Panel = null
var recall_title: Label = null
var recall_info: Label = null
var recall_button: Button = null
var recall_close_button: Button = null

@onready var pioneer_btn: Button = $PioneerBtn
@onready var defender_btn: Button = $DefenderBtn
@onready var sniper_btn: Button = $SniperBtn
@onready var mine_btn: Button = $MineBtn
@onready var selected_indicator: Control = $SelectedIndicator

const SCENE_PIONEER := "res://scenes/main_game/character_pioneer.tscn"
const SCENE_DEFENDER := "res://scenes/main_game/character_defender.tscn"
const SCENE_SNIPER := "res://scenes/main_game/character_sniper.tscn"
const MINE_COST := 50
const MAX_MINES := 2  # 策划书 3.5: 金矿上限 2 个


func _ready() -> void:
	_setup_button(pioneer_btn, Constants.CHAR_PIONEER, "先锋", 20, "ground", 1.0, Color(0.3, 0.6, 0.95, 0.3))
	_setup_button(defender_btn, Constants.CHAR_DEFENDER, "重装", 40, "ground", 1.0, Color(0.9, 0.3, 0.3, 0.25))
	_setup_button(sniper_btn, Constants.CHAR_SNIPER, "狙击", 45, "high", 6.0, Color(1.0, 0.7, 0.2, 0.22))

	if pioneer_btn:
		pioneer_btn.pressed.connect(_on_pioneer_pressed)
	if defender_btn:
		defender_btn.pressed.connect(_on_defender_pressed)
	if sniper_btn:
		sniper_btn.pressed.connect(_on_sniper_pressed)
	if mine_btn:
		mine_btn.pressed.connect(_on_mine_pressed)
	if selected_indicator:
		selected_indicator.visible = false

	_build_recall_panel()

	# 监听部署位 hover 事件，更新范围预览位置
	# (SignalBus 由 deploy_slot 在 _ready 中 connect)

	SignalBus.gold_changed.connect(_refresh_buttons)
	SignalBus.cycle_phase_changed.connect(_on_phase_changed)
	SignalBus.char_background_changed.connect(_on_char_background_changed)
	_refresh_buttons()


func _process(_delta: float) -> void:
	_update_selected_indicator()
	_update_range_preview()
	# 每帧检查按钮状态（确保金币变化后立即更新，避免信号遗漏）
	_check_buttons_state()


## 每帧检查按钮是否需要刷新（只在金币或选中状态变化时才真正刷新）
var _last_gold: int = -1
var _last_selected: String = ""
var _last_mine_sel: bool = false
var _last_mine_count: int = -1
func _check_buttons_state() -> void:
	var g := Economy.gold
	var mc := Economy.mines.size()
	if g != _last_gold or selected_char_id != _last_selected or mine_selected != _last_mine_sel or mc != _last_mine_count:
		_last_gold = g
		_last_selected = selected_char_id
		_last_mine_sel = mine_selected
		_last_mine_count = mc
		_refresh_buttons()


func _setup_button(btn: Button, id: String, name_str: String, cost: int, deploy_type: String, range_cells: float, range_color: Color) -> void:
	if not btn:
		return
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.focus_mode = Control.FOCUS_NONE  # 防止焦点干扰

	# 创建背景图 TextureRect 子节点（放在按钮文字层下方）
	var bg_rect := TextureRect.new()
	bg_rect.name = "BgTexture"
	bg_rect.stretch_mode = 4  # TextureRect.StretchMode.KEEP_ASPECT_COVER
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_rect.visible = false  # 默认隐藏，有纹理时才显示
	btn.add_child(bg_rect, false)  # add_child(front=false) → 放在最底层

	var data := CharButtonData.new()
	data.id = id
	data.name_str = name_str
	data.cost = cost
	data.deploy_type = deploy_type
	data.range_cells = range_cells
	data.color = range_color
	data.button = btn
	data.bg_texture_rect = bg_rect
	char_buttons.append(data)


# ==================== 按钮背景图设置 ====================

## 公开方法：通过纹理路径设置角色按钮背景图
## char_id: 角色ID（如 "pioneer", "defender", "sniper"）
## texture_path: 纹理资源路径（如 "res://ui/char_bg.png"）
func set_char_background(char_id: String, texture_path: String) -> void:
	var texture := load(texture_path)
	set_char_background_texture(char_id, texture)


## 公开方法：直接传入 Texture2D 对象设置角色按钮背景图
func set_char_background_texture(char_id: String, texture: Texture2D) -> void:
	for data in char_buttons:
		if data.id == char_id and data.bg_texture_rect:
			data.bg_texture_rect.texture = texture
			data.bg_texture_rect.visible = (texture != null)
			print("[DeployPanel] 角色 %s 按钮背景图已更新: %s" % [char_id, texture.resource_path if texture else "null"])
			return
	printerr("[DeployPanel] 未找到角色按钮: ", char_id)


## SignalBus 信号回调 — 其他模块可通过信号触发背景图更换
func _on_char_background_changed(char_id: String, texture_path: String) -> void:
	set_char_background(char_id, texture_path)


# ==================== 角色选中 ====================
func _on_pioneer_pressed() -> void:
	_select_char(Constants.CHAR_PIONEER)

func _on_defender_pressed() -> void:
	_select_char(Constants.CHAR_DEFENDER)

func _on_sniper_pressed() -> void:
	_select_char(Constants.CHAR_SNIPER)

func _select_char(char_id: String) -> void:
	print("[DeployPanel] _select_char 调用: 传入=%s 当前=%s" % [char_id, selected_char_id])
	_hide_recall_panel()
	mine_selected = false
	if selected_char_id == char_id:
		selected_char_id = ""
		_hide_range_preview()
		print("[DeployPanel] → 取消选中")
	else:
		selected_char_id = char_id
		_show_range_preview_for(char_id)
		print("[DeployPanel] → 切换选中 → %s" % char_id)


# ==================== 攻击范围预览（最初版：单一柔和 Polygon2D 圆） ====================
## 选中角色时创建/显示范围预览
func _show_range_preview_for(char_id: String) -> void:
	var data: CharButtonData = null
	for d in char_buttons:
		if d.id == char_id:
			data = d
			break
	if not data:
		return

	# 创建一次，后续重用
	if not range_preview:
		range_preview = Polygon2D.new()
		# 用 64 段圆逼近
		var segments: int = 64
		var points: PackedVector2Array = PackedVector2Array()
		for i in range(segments + 1):
			var angle: float = TAU * float(i) / float(segments)
			points.append(Vector2(cos(angle), sin(angle)))
		range_preview.polygon = points
		range_preview.z_index = 5
		# 放在 DeployPanel 自己的 CanvasLayer 中
		add_child(range_preview)

	# 按选中角色缩放/着色
	var radius_px: float = data.range_cells * Constants.GRID_CELL_SIZE
	range_preview.scale = Vector2(radius_px, radius_px)
	range_preview.color = data.color
	range_preview.visible = true
	# 重要：reparent 到 MainGame（世界坐标系）这样 position 用世界坐标
	if range_preview.get_parent() != get_tree().current_scene:
		var old_parent = range_preview.get_parent()
		if old_parent:
			old_parent.remove_child(range_preview)
		get_tree().current_scene.add_child(range_preview)
		range_preview.z_index = 5


## 取消选中/部署完成后 → 隐藏范围
func _hide_range_preview() -> void:
	if range_preview:
		range_preview.visible = false


# ==================== 已部署角色撤回面板 ====================
func _build_recall_panel() -> void:
	if recall_panel:
		return
	recall_panel = Panel.new()
	recall_panel.visible = false
	recall_panel.z_index = 80
	recall_panel.custom_minimum_size = Vector2(190, 118)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.12, 0.94)
	sb.border_color = Color(1.0, 0.85, 0.35, 0.8)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(10.0)
	recall_panel.add_theme_stylebox_override("panel", sb)
	add_child(recall_panel)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 10
	box.offset_top = 8
	box.offset_right = -10
	box.offset_bottom = -8
	box.add_theme_constant_override("separation", 6)
	recall_panel.add_child(box)

	recall_title = Label.new()
	recall_title.text = "角色"
	recall_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recall_title.add_theme_font_size_override("font_size", 18)
	recall_title.add_theme_color_override("font_color", Color(0.95, 0.9, 0.75))
	box.add_child(recall_title)

	recall_info = Label.new()
	recall_info.text = ""
	recall_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recall_info.add_theme_font_size_override("font_size", 13)
	recall_info.add_theme_color_override("font_color", Color(0.75, 0.78, 0.86))
	box.add_child(recall_info)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)

	recall_button = Button.new()
	recall_button.text = "撤回"
	recall_button.custom_minimum_size = Vector2(82, 34)
	recall_button.pressed.connect(_on_recall_confirmed)
	row.add_child(recall_button)

	recall_close_button = Button.new()
	recall_close_button.text = "取消"
	recall_close_button.custom_minimum_size = Vector2(82, 34)
	recall_close_button.pressed.connect(_hide_recall_panel)
	row.add_child(recall_close_button)


func on_occupied_slot_clicked(slot: Node, character: Node2D) -> void:
	if not slot or not character or not is_instance_valid(character):
		_hide_recall_panel()
		return
	selected_char_id = ""
	mine_selected = false
	_hide_range_preview()
	selected_recall_slot = slot
	selected_recall_character = character
	_show_recall_panel(slot, character)


func _show_recall_panel(slot: Node, character: Node2D) -> void:
	if not recall_panel:
		return
	var char_name_value: Variant = character.get("char_name")
	var deploy_cost_value: Variant = character.get("deploy_cost")
	var char_name: String = str(char_name_value) if char_name_value != null else character.name
	var deploy_cost: int = int(deploy_cost_value) if deploy_cost_value != null else 0
	var refund: int = deploy_cost / 2
	recall_title.text = char_name
	recall_info.text = "返还 %d 金" % refund
	if slot is Node2D:
		recall_panel.position = (slot as Node2D).global_position + Vector2(-95, -150)
	recall_panel.visible = true


func _hide_recall_panel() -> void:
	if recall_panel:
		recall_panel.visible = false
	selected_recall_slot = null
	selected_recall_character = null


func _on_recall_confirmed() -> void:
	if not selected_recall_slot or not is_instance_valid(selected_recall_slot):
		_hide_recall_panel()
		return
	if selected_recall_slot.has_method("recall_character"):
		selected_recall_slot.recall_character()
	_hide_recall_panel()


## 每帧更新范围圈位置（跟随鼠标悬浮的部署位）
func _update_range_preview() -> void:
	if not range_preview or not range_preview.visible:
		return

	# 2026-07-01: 防御性 — 未选中任何角色时强制隐藏范围圈
	if selected_char_id == "" and not mine_selected:
		range_preview.visible = false
		return

	# 优先：显示在最后一个被 hover 的部署位上
	if hovered_slot_pos != Vector2.ZERO:
		range_preview.position = hovered_slot_pos
		return

	# 退而求其次：显示在鼠标全局坐标
	# 注意：CanvasLayer 没有 get_global_mouse_position()，但 Viewport 有
	var vp := get_viewport()
	if vp:
		range_preview.position = vp.get_mouse_position()


## 部署位 hover 时由 deploy_slot 调用，更新范围圈位置
func on_slot_hover(slot: Node) -> void:
	if slot and slot is Node2D:
		hovered_slot_pos = (slot as Node2D).global_position


## 部署位取消 hover
func on_slot_unhover() -> void:
	hovered_slot_pos = Vector2.ZERO


# ==================== 金矿选中（独立） ====================
func _on_mine_pressed() -> void:
	# 选金矿时自动取消角色选中 + 隐藏残留的范围圈
	_hide_recall_panel()
	selected_char_id = ""
	_hide_range_preview()
	mine_selected = not mine_selected


# ==================== 部署位点击 ====================
func on_slot_clicked(slot: Node) -> void:
	_hide_recall_panel()

	# 金矿模式（2026-07-01: 金矿可放在所有 ground/high 通用格上）
	if mine_selected:
		if slot.has_method("_try_place_mine"):
			slot.call("_try_place_mine")
		# 无论成败都取消选中（避免选中状态卡住让玩家迷惑）
		mine_selected = false
		_hide_range_preview()
		return

	# 角色模式
	if selected_char_id == "":
		return

	var data: CharButtonData = null
	for d in char_buttons:
		if d.id == selected_char_id:
			data = d
			break
	if not data:
		return

	var actual_cost: int = data.cost

	if slot.has_method("try_deploy"):
		var scene_path := _get_scene_for_char(selected_char_id)
		if scene_path:
			var scene := load(scene_path)
			var success: bool = slot.try_deploy(scene, actual_cost, data.deploy_type)
			if success:
				# 2026-07-01: 部署成功后关闭范围圈 + 取消选中
				selected_char_id = ""
				_hide_range_preview()


func _get_scene_for_char(char_id: String) -> String:
	match char_id:
		Constants.CHAR_PIONEER:
			return SCENE_PIONEER
		Constants.CHAR_DEFENDER:
			return SCENE_DEFENDER
		Constants.CHAR_SNIPER:
			return SCENE_SNIPER
	return ""


# ==================== 按钮刷新 ====================
func _refresh_buttons(_gold: int = -1) -> void:
	var current_gold: int = _gold if _gold >= 0 else Economy.gold
	print("[DeployPanel] _refresh_buttons: gold=%d, selected=%s, mine_sel=%s" % [current_gold, selected_char_id, mine_selected])

	for data in char_buttons:
		var btn: Button = data.button
		if not btn:
			continue
		var cost: int = data.cost
		# 已选中的角色按钮永远可点击（为了能取消选中）
		if data.id == selected_char_id:
			btn.disabled = false
		else:
			btn.disabled = (current_gold < cost)
		btn.text = "%s (%d)" % [data.name_str, data.cost]

	# 金矿按钮：钱不够 / 金矿已满 → 禁用
	if mine_btn:
		if mine_selected:
			mine_btn.disabled = false
		else:
			var can_afford: bool = Economy.can_afford(MINE_COST)
			var mines_full: bool = Economy.mines.size() >= MAX_MINES
			mine_btn.disabled = (not can_afford) or mines_full
			print("[DeployPanel] 金矿按钮: can_afford=%s, mines=%d/%d, disabled=%s" % [can_afford, Economy.mines.size(), MAX_MINES, mine_btn.disabled])


func _on_phase_changed(_phase_name: String) -> void:
	_refresh_buttons()


# ==================== 高亮查询 ====================
func can_deploy_on_slot(slot_type: String) -> bool:
	# 2026-07-01: 取消地面角色/金矿的放置位置限制 — 玩家想放哪格就放哪格
	# 唯一限制：只能放在敌人路径上的格（slot_type == "ground"）

	# 金矿模式：可放任意 ground 部署位
	if mine_selected:
		return slot_type == "ground" and Economy.can_afford(MINE_COST)

	# 角色模式
	if selected_char_id == "":
		return false

	for data in char_buttons:
		if data.id == selected_char_id:
			# 狙击 (high)：只放 high 部署位
			# 先锋/重装 (ground)：可放任意 ground 部署位（已是无类型限制）
			if data.deploy_type == "high" and slot_type != "high":
				return false
			if data.deploy_type == "ground" and slot_type != "ground":
				return false
			return Economy.can_afford(data.cost)
	return false


# ==================== 选中指示器 ====================
func _update_selected_indicator() -> void:
	if not selected_indicator:
		return

	# 优先显示角色选中
	if selected_char_id != "":
		selected_indicator.visible = true
		for data in char_buttons:
			if data.id == selected_char_id and data.button:
				selected_indicator.offset_left = data.button.offset_left
				selected_indicator.offset_top = data.button.offset_top
				selected_indicator.offset_right = data.button.offset_right
				selected_indicator.offset_bottom = data.button.offset_bottom
				return
	# 金矿选中
	elif mine_selected and mine_btn:
		selected_indicator.visible = true
		selected_indicator.offset_left = mine_btn.offset_left
		selected_indicator.offset_top = mine_btn.offset_top
		selected_indicator.offset_right = mine_btn.offset_right
		selected_indicator.offset_bottom = mine_btn.offset_bottom
	else:
		selected_indicator.visible = false
