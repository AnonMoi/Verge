## core_node.gd
## 钟摆核心节点脚本 — 管理核心 HP、受伤闪白、销毁信号
## 挂载在核心的根节点（Node2D）上

extends Node2D

# ---------- 属性 ----------
@export var max_hp: float = 1000.0          # 最大 HP（策划书 4.1: 1000）
var current_hp: float = max_hp              # 当前 HP
var damage: float = 10.0                    # 每次被敌人撞到的伤害
var is_destroyed: bool = false              # 是否已被摧毁（防止信号重复 emit）

# 闪白用
@onready var visual: Node2D = $Visual    # 核心视觉节点引用（AnimatedSprite2D）

# ---------- 生命周期 ----------
func _ready() -> void:
	# 初始化 HP
	current_hp = max_hp
	print("[CoreNode] 核心初始化完成, HP: %d/%d" % [current_hp, max_hp])

# ---------- 受伤逻辑 ----------
## 受到伤害，扣血后 emit 信号，HP≤0 时触发销毁
func take_damage(amount: float) -> void:
	if is_destroyed:
		return  # 已经炸了，不再受伤

	current_hp = maxf(0.0, current_hp - amount)
	print("[CoreNode] 核心受到 %.0f 点伤害! 剩余 HP: %.0f/%d" % [amount, current_hp, max_hp])

	# 发送信号
	SignalBus.core_damaged.emit(amount, current_hp)
	SignalBus.core_hp_changed.emit(current_hp)

	# 核心被击像素特效（抖动 + 冲击波 + 碎片）
	EffectsManager.spawn_core_hit_effect(self)

	# 受伤闪白效果
	_play_damage_flash()

	# HP 归零 → 游戏结束
	if current_hp <= 0:
		_destroy()

# ---------- 闪白效果 ----------
## 核心短暂闪白（通过 modulate 实现，AnimatedSprite2D / ColorRect 均适用）
func _play_damage_flash() -> void:
	if not visual:
		return

	visual.modulate = Color.WHITE
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color.WHITE, 0.0)
	tween.tween_property(visual, "modulate", Color(1, 1, 1, 1), 0.2)

# ---------- 销毁 ----------
## 核心被摧毁，发送信号并打印日志
func _destroy() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	print("[CoreNode] 核心被摧毁!")
	# 核心被摧毁大爆炸特效
	EffectsManager.spawn_core_destroyed_effect(global_position)
	SignalBus.core_destroyed.emit()
	# 后续由 GameManager 处理 game_over 流程
