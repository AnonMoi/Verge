## projectile.gd
## 投射物脚本 — 远程角色的攻击投射物
## 挂载在 projectile.tscn 的根节点（CharacterBody2D）上

extends CharacterBody2D

var damage: float = 45.0
var target_position: Vector2
var speed: float = 400.0
var has_hit: bool = false

@onready var visual: ColorRect = $Visual


func _ready() -> void:
	damage = float(get_meta("damage")) if has_meta("damage") else 45.0
	target_position = Vector2(get_meta("target_pos")) if has_meta("target_pos") else global_position


func _process(delta: float) -> void:
	if has_hit:
		return

	if not is_instance_valid(self):
		return

	var direction := target_position - global_position
	if direction.length() < 8.0:
		_check_hit()
		return

	var velocity := direction.normalized() * speed
	global_position += velocity * delta


func _check_hit() -> void:
	if has_hit:
		return
	has_hit = true

	var root := get_tree().current_scene
	if not root:
		_queue_destroy()
		return

	var enemies_container := root.find_child("Enemies", false, false)
	if not enemies_container:
		_queue_destroy()
		return

	for child in enemies_container.get_children():
		if not is_instance_valid(child):
			continue
		if not (child is CharacterBody2D):
			continue
		var enemy := child as CharacterBody2D
		if not enemy.has_method("take_damage"):
			continue

		if global_position.distance_to(enemy.global_position) < 40.0:
			enemy.take_damage(damage)
			# 命中像素火花特效
			EffectsManager.spawn_hit_effect(global_position)
			break

	_queue_destroy()


func _queue_destroy() -> void:
	if not is_instance_valid(self):
		return
	if visual:
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.12)
		tween.tween_callback(queue_free)
	else:
		queue_free()
