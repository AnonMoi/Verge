## path_manager.gd
## 路径管理器 — 管理 PathVisual 下已有的 PathTile 节点
## 作为 Autoload 单例使用，核心功能：
## - 从 PathVisual 收集已有 tile 的路由信息
## - 通过 API 添加 tile、按方向批量设置动画素材
## - 对敌人暴露路径点

extends Node

var _path_tile_scene: PackedScene = null

# 格子大小
const TILE_SIZE: int = 64

# 按方向存储的默认动画素材 { "h" -> SpriteFrames, ... }
var _default_animations: Dictionary = {}

# 敌人路径点
var _path_points: Array[Vector2] = []


func _ready() -> void:
	# 延迟加载 path_tile 场景（避免 preload 编译链阻塞）
	_path_tile_scene = load("res://scenes/main_game/path_tile.tscn")
	await get_tree().process_frame
	_collect_path_from_node(get_node_or_null("%PathVisual"))


## 从 PathVisual 节点收集已有 tile 的路径点
func _collect_path_from_node(path_visual: Node) -> void:
	if not path_visual:
		print("[PathManager] 未找到 PathVisual 节点")
		return

	var tiles := _get_tile_nodes(path_visual)
	_path_points.clear()

	# 收集所有 tile 的世界坐标作为路径点
	for tile in tiles:
		if tile and is_instance_valid(tile):
			var wp := _grid_to_world(tile.grid_pos)
			if not _path_points.has(wp):
				_path_points.append(wp)

	if _path_points.size():
		print("[PathManager] 从 PathVisual 收集到 %d 个 tile, %d 个路径点" % [tiles.size(), _path_points.size()])

	# 终点 y 坐标与核心对齐
	if _path_points.size() > 1:
		var last := Vector2(_path_points[-1])
		last.y = TILE_SIZE * 5 + TILE_SIZE / 2.0 + 32.0  # 352
		_path_points[-1] = last


## 从给定节点收集所有 PathTile 子节点
func _get_tile_nodes(parent: Node) -> Array:
	var result: Array = []
	for child in parent.get_children():
		if child.get_script() and child.get_script().resource_path.ends_with("path_tile.gd"):
			result.append(child)
	return result


## 获取所有 PathTile
func get_all_tiles() -> Array:
	var pv := get_node_or_null("%PathVisual")
	if pv:
		return _get_tile_nodes(pv)
	return []


## 获取敌人路径点
func get_path_points() -> Array[Vector2]:
	return _path_points.duplicate()


## 添加路径块（在 PathVisual 下）
## anim_res_path: SpriteFrames 文件路径 (.res)
func add_tile(grid_x: int, grid_y: int, direction: String = "h", anim_res_path: String = "", name: String = "") -> Node:
	var pv := get_node_or_null("%PathVisual")
	if not pv:
		printerr("[PathManager] 找不到 %PathVisual，无法添加 tile")
		return null

	var tile := _path_tile_scene.instantiate()
	if not tile:
		printerr("[PathManager] 无法实例化 path_tile.tscn")
		return null

	var world_pos := _grid_to_world(Vector2i(grid_x, grid_y))
	tile.position = world_pos
	tile.tile_direction = direction
	tile.grid_pos = Vector2i(grid_x, grid_y)

	if name:
		tile.name = name

	# 动画素材
	if anim_res_path and anim_res_path != "":
		if ResourceLoader.exists(anim_res_path):
			tile.tile_animation = load(anim_res_path)
	elif _default_animations.has(direction):
		tile.tile_animation = _default_animations[direction]

	tile._setup_visual()
	pv.add_child(tile)

	# 更新路径点
	var wp := _grid_to_world(Vector2i(grid_x, grid_y))
	if not _path_points.has(wp):
		_path_points.append(wp)

	print("[PathManager] 添加 tile [%s] @ (%d,%d)", direction, grid_x, grid_y)
	return tile


## 按方向批量设置动画素材
func set_tile_animation(direction: String, frames: SpriteFrames) -> void:
	_default_animations[direction] = frames
	for tile in get_all_tiles():
		if tile.tile_direction == direction and not tile.tile_animation:
			tile.set_animation(frames)


## 网格坐标 -> 世界坐标（格子中心）
func _grid_to_world(pos: Vector2i) -> Vector2:
	return Vector2(pos.x * TILE_SIZE + TILE_SIZE / 2, pos.y * TILE_SIZE + TILE_SIZE / 2)


## 清空所有路径
func clear_all() -> void:
	var pv := get_node_or_null("%PathVisual")
	if pv:
		for child in pv.get_children():
			if child.get_script() and child.get_script().resource_path.ends_with("path_tile.gd"):
				child.queue_free()
	_path_points.clear()
	_default_animations.clear()
	print("[PathManager] 已清空")


## 获取路径块数量
func get_tile_count() -> int:
	return get_all_tiles().size()


## 按方向查找 tile
func get_tiles_by_direction(direction: String) -> Array:
	var result: Array = []
	for tile in get_all_tiles():
		if tile.tile_direction == direction:
			result.append(tile)
	return result
