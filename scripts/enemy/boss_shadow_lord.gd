extends CharacterBody2D

var max_hp: float = 3000.0
var hp: float = 3000.0
var speed: float = 40.0
var core_damage: float = 50.0
var defense: float = 20.0

var attack_cooldown: float = 3.0
var attack_timer: float = 0.0
var aoe_cooldown: float = 8.0
var aoe_timer: float = 0.0

var is_shield_active: bool = false
var shield_hp: float = 500.0
var shield_cooldown: float = 15.0
var shield_timer: float = 0.0

var is_dead: bool = false
var damage_taken_this_frame: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var shield_bar: ProgressBar = $ShieldBar
@onready var damage_text: DamageText = $DamageText

func _ready() -> void:
	health_bar.max_value = max_hp
	health_bar.value = hp
	shield_bar.value = 0.0
	shield_bar.visible = false
	SignalBus.boss_spawned.connect(_on_boss_spawned)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_move_towards_core(delta)

	attack_timer += delta
	aoe_timer += delta
	shield_timer += delta

	if shield_timer >= shield_cooldown and not is_shield_active:
		_activate_shield()

	if attack_timer >= attack_cooldown:
		_attack()

	if aoe_timer >= aoe_cooldown:
		_cast_aoe()

func _move_towards_core(delta: float) -> void:
	var core_pos: Vector2 = Vector2(1200, 320)
	var direction: Vector2 = (core_pos - position).normalized()
	move_and_slide(direction * speed * delta)

func _attack() -> void:
	attack_timer = 0.0
	sprite.play("attack")
	var area := Area2D.new()
	area.monitoring = true
	area.monitorable = false
	var shape := CircleShape2D.new()
	shape.radius = 80.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	area.add_child(collision)
	area.position = position + Vector2(40, 0)
	get_parent().add_child(area)

	for body in area.get_overlapping_bodies():
		if body.has_method("_take_damage"):
			body._take_damage(50.0)

	await get_tree().create_timer(0.5).timeout
	area.queue_free()

func _cast_aoe() -> void:
	aoe_timer = 0.0
	sprite.play("attack")
	var aoe_area := Area2D.new()
	aoe_area.monitoring = true
	aoe_area.monitorable = false
	var shape := CircleShape2D.new()
	shape.radius = 150.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	aoe_area.add_child(collision)
	aoe_area.position = position + Vector2(40, 0)
	get_parent().add_child(aoe_area)

	for body in aoe_area.get_overlapping_bodies():
		if body.has_method("_take_damage"):
			body._take_damage(100.0)

	await get_tree().create_timer(0.3).timeout
	aoe_area.queue_free()

func _activate_shield() -> void:
	is_shield_active = true
	shield_hp = 500.0
	shield_bar.value = shield_hp
	shield_bar.max_value = 500.0
	shield_bar.visible = true
	shield_timer = 0.0
	print("[ShadowLord] 护盾激活!")

func _take_damage(damage: float) -> void:
	if is_dead:
		return

	var actual_damage := max(damage - defense, 1.0)

	if is_shield_active:
		if shield_hp > 0:
			shield_hp -= actual_damage
			shield_bar.value = shield_hp
			if shield_hp <= 0:
				is_shield_active = false
				shield_bar.visible = false
				shield_timer = 0.0
				print("[ShadowLord] 护盾被打破!")
			return

	hp -= actual_damage
	health_bar.value = hp
	damage_taken_this_frame += actual_damage

	if hp <= 0:
		_die()

func _die() -> void:
	is_dead = true
	sprite.play("death")
	await get_tree().create_timer(1.5).timeout
	queue_free()
	SignalBus.boss_defeated.emit()

func _on_boss_spawned(boss_type: String) -> void:
	if boss_type == "shadow_lord":
		print("[ShadowLord] Boss 降临!")