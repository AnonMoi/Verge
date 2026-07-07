## deploy_slot.gd
## 部署位脚本 — 管理单个部署格子状态和点击交互
## 挂载在 main_game.tscn 的 DeploySlot 节点上

extends Area2D

# ---------- 属性 ----------
@export var slot_type: String = "ground"   # 部署位类型："ground" / "high"
@export var slot_index: int = 0            # 编号标识

var is_occupied: bool = false              # 是否已被占用
var deployed_character: Node2D = null      # 当前部署的角色引用
var _click_token: int = 0                  # 点击防抖 token（防 input_event + _input 重复触发）

## 2026-07-01: 真实占用状态检查（金矿/角色被摧毁后 is_occupied 应自动失效）
func is_actually_occupied() -> bool:
	if not is_occupied:
		return false
	# 角色/金矿实例被 queue_free 后 is_occupied 仍为 true，需要重新判定
	if deployed_character and not is_instance_valid(deployed_character):
		is_occupied = false
		deployed_character = null
		return false
	return true

# 节点引用
# 2026-07-01: 仅 high 槽保留 Highlight 节点（选中狙击时显示），其他槽无任何视觉提示
@onready var highlight: ColorRect = get_node_or_null("Highlight")


# ---------- 生命周期 ----------
func _ready() -> void:
	# 确保 Area2D 可接收输入
	input_pickable = true
	# 连接 Area2D 的输入信号
	if not input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)
	# 连接 hover 信号（用于更新攻击范围预览位置）
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	# Highlight 节点仅 high 槽有，启动时强制隐藏
	if highlight:
		highlight.visible = false


func _process(_delta: float) -> void:
	# 2026-07-01 方案 3：仅 high 槽在选中狙击时显示 Highlight
	_check_high_slot_highlight()


# ---------- 高台槽高亮（方案 3） ----------
## 选中狙击（deploy_type=high）时，让 high 槽显示浅蓝色 Highlight
func _check_high_slot_highlight() -> void:
	if not highlight:
		return  # ground 槽无 Highlight 节点
	if is_actually_occupied():
		highlight.visible = false
		return

	var panel := _get_deploy_panel()
	if not panel:
		highlight.visible = false
		return

	# 检查是否选中狙击
	var sel_char = panel.get("selected_char_id")
	if sel_char == null or sel_char == "":
		highlight.visible = false
		return

	# 遍历角色按钮数据，找到狙击的 deploy_type
	var char_buttons = panel.get("char_buttons")
	if char_buttons == null:
		highlight.visible = false
		return

	for data in char_buttons:
		if data.get("id") == sel_char and data.get("deploy_type") == "high":
			highlight.visible = true
			return

	highlight.visible = false


# ---------- 点击输入 ----------
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not event is InputEventMouseButton:
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return

	# 点击了部署位
	_on_clicked()


func _on_clicked() -> void:
	if is_actually_occupied():
		return
	# 防止 input_event 和 _input 兜底同时触发一次点击两次
	_click_token = _click_token + 1
	var my_token := _click_token
	await get_tree().process_frame
	if my_token != _click_token or is_actually_occupied():
		return
	var panel := _get_deploy_panel()
	if panel and panel.has_method("on_slot_clicked"):
		panel.on_slot_clicked(self)
	elif slot_type == "mine":
		_try_place_mine()


# 全局点击兜底（Area2D input_event 可能被 CanvasLayer 拦截）
func _input(event: InputEvent) -> void:
	if is_actually_occupied():
		return
	if not event is InputEventMouseButton:
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	# 检查点击是否在这个部署位的区域内
	var local_pos := to_local(mb.global_position)
	var shape_rect := Rect2(-32, -32, 64, 64)
	if shape_rect.has_point(local_pos):
		print("[DeploySlot] _input 点击命中! 位%d local=%s" % [slot_index, local_pos])
		_on_clicked()
		get_viewport().set_input_as_handled()


# ---------- 鼠标悬停 ----------
func _on_mouse_entered() -> void:
	# 通知 DeployPanel 更新攻击范围预览位置
	var panel := _get_deploy_panel()
	if panel and panel.has_method("on_slot_hover"):
		panel.on_slot_hover(self)


func _on_mouse_exited() -> void:
	# 通知 DeployPanel 取消 hover（让范围圈回到鼠标位置或隐藏）
	var panel := _get_deploy_panel()
	if panel and panel.has_method("on_slot_unhover"):
		panel.on_slot_unhover()


# ---------- 部署操作 ----------
## 尝试在这个位置部署角色
## 返回 true 表示成功
func try_deploy(character_scene: PackedScene, cost: int, type: String) -> bool:
	if is_actually_occupied():
		printerr("[DeploySlot] 位%d已被占用!" % slot_index)
		return false

	# 2026-07-01: 取消类型检查，地面角色/金矿可放任何 ground 部署位
	# （狙击仍走自己的 high 部署位）

	# 检查金币
	if not Economy.can_afford(cost):
		printerr("[DeploySlot] 金币不足! 需要%d, 当前%d" % [cost, Economy.gold])
		return false

	# 扣钱
	if not Economy.spend_gold(cost):
		return false

	# 创建角色实例
	var character := character_scene.instantiate()
	character.set("position", position)

	# 添加到 Characters 容器
	var root := get_tree().current_scene
	if root:
		var chars_container := root.find_child("Characters", false, false)
		if chars_container:
			chars_container.add_child(character)
		else:
			root.add_child(character)

	# 更新状态
	is_occupied = true
	deployed_character = character

	print("[DeploySlot] 位%d部署成功! 角色:%s, 费用:%d" % [slot_index, character.get("char_name"), cost])

	# 统计
	GameManager.total_deployed += 1

	# 发送信号
	var char_id := character.get("char_id", "")
	SignalBus.character_deployed.emit(char_id)

	return true


## 撤回角色（黄昏半价返还）
func recall_character() -> void:
	if not is_occupied or not deployed_character:
		return

	var refund := int(deployed_character.get("deploy_cost")) / 2
	Economy.add_gold(refund)
	Economy.broadcast_gold_changed(refund)

	# 移除角色
	if is_instance_valid(deployed_character):
		deployed_character.queue_free()

	deployed_character = null
	is_occupied = false

	SignalBus.character_recalled.emit("")
	print("[DeploySlot] 位%d角色撤回, 返还%d金" % [slot_index, refund])


# ---------- 视觉更新 ----------
# 2026-07-01: 无任何视觉显示 — 部署位 0 颜色，完全无黄/蓝/任何色


# ---------- 工具函数 ----------
## 金矿位直接放置金矿（不经过 DeployPanel 选择）
func _try_place_mine() -> void:
	const MINE_COST := 50
	const MAX_MINES := 2  # 策划书 3.5: 金矿上限 2 个

	# 检查金矿数量上限
	var existing_mines := _count_existing_mines()
	if existing_mines >= MAX_MINES:
		print("[DeploySlot] 金矿已达上限 (%d 个)! 无法再建造" % MAX_MINES)
		return

	if not Economy.can_afford(MINE_COST):
		print("[DeploySlot] 金币不足! 无法建造金矿")
		return

	if not Economy.spend_gold(MINE_COST):
		return

	var mine_scene := load("res://scenes/main_game/gold_mine.tscn")
	if not mine_scene:
		printerr("[DeploySlot] 无法加载 gold_mine.tscn!")
		return

	var mine: Node2D = mine_scene.instantiate()
	mine.position = position

	var root := get_tree().current_scene
	if root:
		var buildings_container := root.find_child("Buildings", false, false)
		if buildings_container:
			buildings_container.add_child(mine)
		else:
			root.add_child(mine)

	is_occupied = true
	deployed_character = mine
	# 统计
	GameManager.total_deployed += 1
	SignalBus.mine_placed.emit()
	print("[DeploySlot] 金矿建造成功! 费用:%d (当前: %d/%d)" % [MINE_COST, _count_existing_mines(), 2])


## 统计当前场景中已存在的金矿数量
func _count_existing_mines() -> int:
	var root := get_tree().current_scene
	if not root:
		return 0
	var buildings := root.find_child("Buildings", false, false)
	if not buildings:
		return 0
	var count := 0
	for child in buildings.get_children():
		# 金矿场景的根脚本是 gold_mine.gd
		if child.get_script() and child.get_script().resource_path.ends_with("gold_mine.gd"):
			count += 1
	return count


func _get_deploy_panel() -> Node:
	var root := get_tree().current_scene
	if not root:
		return null
	# DeployPanel 是根的直接子节点（CanvasLayer）
	if root.has_node("DeployPanel"):
		return root.get_node("DeployPanel")
	# 递归兜底
	return root.find_child("DeployPanel", true, false)
