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

# 受损反馈节点
@onready var damage_effects: Node2D = $DamageEffects  # 受损效果容器
@onready var crack_effect: Sprite2D = $DamageEffects/CrackEffect
@onready var spark_effect: AnimatedSprite2D = $DamageEffects/SparkEffect
@onready var warning_light: ColorRect = $DamageEffects/WarningLight

# 受损状态
var current_damage_state: int = 0  # 0:正常 1:裂纹 2:火花 3:红色警告

# 受损状态阈值（策划书 3.2）
const STATE_NORMAL = 0.75    # >75% HP: 正常
const STATE_CRACKS = 0.50    # 50%-75%: 裂纹
const STATE_SPARKS = 0.25    # 25%-50%: 火花
const STATE_WARNING = 0.0    # <25%: 红色警告

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

	# 更新受损反馈状态（策划书 3.2）
	_update_damage_state()

	# HP 归零 → 游戏结束
	if current_hp <= 0:
		_destroy()

# ---------- 受损状态更新 ----------
func _update_damage_state() -> void:
	var hp_ratio := current_hp / max_hp
	var new_state: int = 0

	if hp_ratio > STATE_NORMAL:
		new_state = 0
	elif hp_ratio > STATE_CRACKS:
		new_state = 1
	elif hp_ratio > STATE_SPARKS:
		new_state = 2
	else:
		new_state = 3

	if new_state != current_damage_state:
		current_damage_state = new_state
		_apply_damage_effects(new_state)
		print("[CoreNode] 受损状态变更: %d" % new_state)

func _apply_damage_effects(state: int) -> void:
	if crack_effect:
		crack_effect.visible = state >= 1
	if spark_effect:
		spark_effect.visible = state >= 2
		if state >= 2:
			spark_effect.play("spark")
		else:
			spark_effect.stop()
	if warning_light:
		warning_light.visible = state >= 3
		if state >= 3:
			warning_light.modulate = Color(1, 0.1, 0.1, 0.3)
			var tween := create_tween()
			tween.tween_property(warning_light, "modulate:a", 0.5, 0.5)
			tween.tween_property(warning_light, "modulate:a", 0.3, 0.5)
			tween.set_loop_mode(Tween.LOOP_FORWARD)

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
