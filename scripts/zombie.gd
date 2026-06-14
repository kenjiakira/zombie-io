extends CharacterBody2D

@export var speed: float = 90.0
@export var max_hp: int = 50
@export var damage: int = 10
@export var exp_value: int = 1
@export var exp_gem_scene: PackedScene

@onready var body: Polygon2D = $Body
@export var death_effect_scene: PackedScene

var hp: int
var player = null
var anim_time: float = 0.0
var is_hurt_animating: bool = false
var knockback: Vector2 = Vector2.ZERO

func _ready():
	hp = max_hp
	add_to_group("zombie")

	setup_placeholder_visual()

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func setup_placeholder_visual():
	body.polygon = PackedVector2Array([
		Vector2(0, -18),
		Vector2(15, -7),
		Vector2(12, 12),
		Vector2(0, 18),
		Vector2(-14, 10),
		Vector2(-16, -8)
	])

	body.color = Color(0.25, 0.9, 0.35)

func _physics_process(delta):
	if player == null:
		return

	var dir = (player.global_position - global_position).normalized()

	velocity = dir * speed + knockback
	move_and_slide()

	knockback = knockback.move_toward(Vector2.ZERO, 700 * delta)

	update_animation(delta, dir)

func update_animation(delta, dir: Vector2):
	if is_hurt_animating:
		return

	anim_time += delta

	body.rotation = dir.angle()

	var wobble_x = 1.0 + sin(anim_time * 8.0) * 0.08
	var wobble_y = 1.0 + cos(anim_time * 8.0) * 0.05
	body.scale = Vector2(wobble_x, wobble_y)

func take_damage(amount: int):
	hp -= amount

	if player != null:
		knockback = (global_position - player.global_position).normalized() * 220

	play_hurt_animation()

	if hp <= 0:
		die()

func play_hurt_animation():
	if is_hurt_animating:
		return

	is_hurt_animating = true

	body.color = Color(1.0, 1.0, 1.0)
	body.scale = Vector2(1.35, 1.35)

	await get_tree().create_timer(0.07).timeout

	body.color = Color(0.25, 0.9, 0.35)
	body.scale = Vector2.ONE

	is_hurt_animating = false

func die():
	var main = get_tree().current_scene

	if death_effect_scene != null:
		var effect = death_effect_scene.instantiate()
		effect.global_position = global_position
		main.add_child(effect)

	if main.has_method("add_score"):
		main.add_score(1)

	if exp_gem_scene != null:
		var gem = exp_gem_scene.instantiate()
		gem.global_position = global_position
		main.add_child(gem)

	queue_free()

func play_death_effect():
	pass

func _on_attack_area_body_entered(body_hit):
	if body_hit.is_in_group("player"):
		player = body_hit

func _on_damage_timer_timeout():
	if player == null:
		return

	var distance = global_position.distance_to(player.global_position)

	if distance < 42:
		player.take_damage(damage)
