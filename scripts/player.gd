extends CharacterBody2D

signal hp_changed(current_hp, max_hp)
signal died

@export var speed: float = 230.0
@export var max_hp: int = 100
@export var bullet_scene: PackedScene

@onready var body: Polygon2D = $Body
@onready var shoot_timer: Timer = $ShootTimer

var hp: int
var facing_dir: Vector2 = Vector2.RIGHT
var anim_time: float = 0.0
var is_hurt_animating: bool = false

func _ready():
	hp = max_hp
	add_to_group("player")
	hp_changed.emit(hp, max_hp)

	setup_placeholder_visual()

func setup_placeholder_visual():
	body.polygon = PackedVector2Array([
		Vector2(18, 0),
		Vector2(-12, -12),
		Vector2(-8, 0),
		Vector2(-12, 12)
	])

	body.color = Color(0.25, 0.75, 1.0)

func _physics_process(delta):
	var input_dir = Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	if input_dir != Vector2.ZERO:
		facing_dir = input_dir
		body.rotation = facing_dir.angle()

	velocity = input_dir * speed
	move_and_slide()

	update_animation(delta, input_dir)

func update_animation(delta, input_dir: Vector2):
	if is_hurt_animating:
		return

	anim_time += delta

	if input_dir == Vector2.ZERO:
		# Idle: thở nhẹ
		var pulse = 1.0 + sin(anim_time * 4.0) * 0.03
		body.scale = Vector2(pulse, pulse)
	else:
		# Move: hơi nảy nhẹ
		var bounce = 1.0 + sin(anim_time * 12.0) * 0.06
		body.scale = Vector2(1.0, bounce)

func take_damage(amount: int):
	hp -= amount
	hp = max(hp, 0)
	hp_changed.emit(hp, max_hp)

	play_hurt_animation()

	if hp <= 0:
		died.emit()
		get_tree().reload_current_scene()

func play_hurt_animation():
	is_hurt_animating = true

	body.color = Color(1.0, 0.3, 0.3)
	body.scale = Vector2(1.25, 1.25)

	await get_tree().create_timer(0.08).timeout

	body.color = Color(0.25, 0.75, 1.0)
	body.scale = Vector2.ONE
	is_hurt_animating = false

func _on_shoot_timer_timeout():
	var target = get_nearest_zombie()

	if target == null:
		return

	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.direction = (target.global_position - global_position).normalized()

	get_tree().current_scene.add_child(bullet)

func get_nearest_zombie():
	var zombies = get_tree().get_nodes_in_group("zombie")

	if zombies.is_empty():
		return null

	var nearest = zombies[0]
	var nearest_distance = global_position.distance_to(nearest.global_position)

	for zombie in zombies:
		var distance = global_position.distance_to(zombie.global_position)

		if distance < nearest_distance:
			nearest = zombie
			nearest_distance = distance

	return nearest
