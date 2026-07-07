## path_tile.gd
## 路径块脚本 — 单个路径格子的视觉表现节点（使用 AnimatedSprite2D）
## 支持通过 @export 设置 SpriteFrames 动画素材
## 挂载在 path_tile.tscn 的根节点（Node2D）上

extends Node2D

@export var tile_direction: String = "h"   # 方向类型: "h","v","corner_down","corner_up","corner_right","start","end"
@export var tile_animation: SpriteFrames = null  # 自定义动画素材
@export var default_anim_name: String = "default"  # 默认播放的动画名
@export var grid_pos: Vector2i = Vector2i.ZERO  # 网格坐标 (x, y)

var _anim: AnimatedSprite2D = null


func _ready() -> void:
	_setup_visual()


## 初始化视觉表现（AnimatedSprite2D）
func _setup_visual() -> void:
	# 查找子节点中的 AnimatedSprite2D
	_anim = null
	for child in get_children():
		if child is AnimatedSprite2D:
			_anim = child
			break

	if not _anim:
		_anim = AnimatedSprite2D.new()
		_anim.name = "Anim"
		add_child(_anim)

	# 有动画素材则赋值并播放
	if tile_animation:
		_anim.sprite_frames = tile_animation
		if default_anim_name:
			_anim.play(default_anim_name)
		_anim.visible = true
	else:
		_anim.visible = false


## 运行时设置动画素材
func set_animation(frames: SpriteFrames) -> void:
	tile_animation = frames
	if _anim:
		_anim.sprite_frames = frames
		if frames:
			_anim.visible = true
			if default_anim_name and frames.has_animation(default_anim_name):
				_anim.play(default_anim_name)
			elif frames:
				var names := frames.get_animation_names()
				if names.size() > 0:
					_anim.play(names[0])
		else:
			_anim.visible = false


## 播放指定动画
func play_anim(name: String) -> void:
	if _anim and _anim.sprite_frames and _anim.sprite_frames.has_animation(name):
		_anim.play(name)


## 获取 AnimatedSprite2D 节点引用
func get_anim() -> AnimatedSprite2D:
	return _anim
