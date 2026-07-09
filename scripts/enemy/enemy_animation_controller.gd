## enemy_animation_controller.gd
## 敌人动画控制器 — 挂载在 Enemy 根节点下
## 负责：通过同级的 AnimatedSprite2D 播放 移动(idle) / 受击(hit) / 攻击(attack) / 死亡(death) 动画

extends Node

# ---------- 信号 ----------
## 死亡动画播放完毕，可以安全销毁敌人了
signal death_animation_finished

## 攻击动画播放完毕，可以执行伤害+自毁了
signal attack_animation_finished

# ---------- 节点引用 ----------
@onready var parent_enemy: CharacterBody2D = get_parent()
@onready var animated_sprite: AnimatedSprite2D = _find_animated_sprite()

# ---------- 动画状态 ----------
var _death_in_progress: bool = false


## 查找同级 AnimatedSprite2D
func _find_animated_sprite() -> AnimatedSprite2D:
	var sprite: Node = parent_enemy.find_child("AnimatedSprite2D", false, false)
	return sprite if sprite is AnimatedSprite2D else null


func _ready() -> void:
	if animated_sprite and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")


## 播放/切换到 移动状态（idle 待机动画）
func play_idle() -> void:
	if _death_in_progress:
		return
	if not animated_sprite:
		return
	if not animated_sprite.sprite_frames.has_animation("idle"):
		return
	if animated_sprite.animation != "idle":
		animated_sprite.play("idle")


## 受击闪烁 — 播放 hit 动画，播放完毕自动回到 idle
func play_hit() -> void:
	if _death_in_progress:
		return
	if not animated_sprite:
		return
	if not animated_sprite.sprite_frames.has_animation("hit"):
		return

	animated_sprite.play("hit")
	# 用 await 代替 animation_finished 信号
	var frames_count: int = animated_sprite.sprite_frames.get_frame_count("hit")
	var anim_speed: float = animated_sprite.sprite_frames.get_animation_speed("hit")
	var anim_duration: float = float(frames_count) / float(anim_speed) if anim_speed > 0 else 0.2
	await get_tree().create_timer(anim_duration).timeout
	if _death_in_progress or not is_instance_valid(self) or not is_instance_valid(animated_sprite):
		return
	if animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")


func _on_hit_finished() -> void:
	if animated_sprite and animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")


## 攻击动画 — 敌人到达核心时播放，播放完毕后 emit attack_animation_finished
func play_attack() -> void:
	if _death_in_progress:
		attack_animation_finished.emit()
		return
	if not animated_sprite:
		attack_animation_finished.emit()
		return

	if not animated_sprite.sprite_frames.has_animation("attack"):
		attack_animation_finished.emit()
		return

	animated_sprite.play("attack")
	# 用 await 代替 animation_finished 信号
	var frames_count: int = animated_sprite.sprite_frames.get_frame_count("attack")
	var anim_speed: float = animated_sprite.sprite_frames.get_animation_speed("attack")
	var anim_duration: float = float(frames_count) / float(anim_speed) if anim_speed > 0 else 0.3
	await get_tree().create_timer(anim_duration).timeout
	if _death_in_progress or not is_instance_valid(self):
		return
	attack_animation_finished.emit()


func _on_attack_finished() -> void:
	attack_animation_finished.emit()


## 死亡动画 — 播放完毕后 emit death_animation_finished
func play_death() -> void:
	if _death_in_progress:
		return
	_death_in_progress = true

	if not animated_sprite:
		_death_immediate()
		return

	if not animated_sprite.sprite_frames.has_animation("death"):
		_death_immediate()
		return

	# 播放 death 动画，并强制从第 0 帧开始，避免被停在攻击/受击最后一帧
	animated_sprite.stop()
	animated_sprite.frame = 0
	animated_sprite.frame_progress = 0.0
	animated_sprite.play("death")
	var frames_count: int = animated_sprite.sprite_frames.get_frame_count("death")
	var anim_speed: float = animated_sprite.sprite_frames.get_animation_speed("death")
	var anim_duration: float = float(frames_count) / float(anim_speed) if anim_speed > 0 else 0.4
	await get_tree().create_timer(anim_duration + 0.05).timeout
	if not is_instance_valid(self) or not is_instance_valid(animated_sprite):
		return
	if animated_sprite.animation != "death":
		animated_sprite.play("death")
	death_animation_finished.emit()


func _on_death_finished() -> void:
	death_animation_finished.emit()


func set_dead_state() -> void:
	_death_in_progress = true


func _death_immediate() -> void:
	death_animation_finished.emit()
