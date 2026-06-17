extends CharacterBody2D

const EnemyDatabase = preload("res://scripts/data/enemy_database.gd")

@export var zombie_type: String = "normal"
@export var exp_gem_scene: PackedScene
@export var weapon_drop_scene: PackedScene
@export var death_effect_scene: PackedScene
@export var death_burst_scene: PackedScene
@export var hit_flash_scene: PackedScene

@onready var body: Polygon2D = $Body
@onready var attack_area: Area2D = $AttackArea
@onready var damage_timer: Timer = $DamageTimer

var speed: float = 90.0
var max_hp: int = 50
var damage: int = 10
var exp_value: int = 1
var score_value: int = 1
var knockback_strength: float = 220.0
var can_attack: bool = true
var attack_cooldown: float = 0.8
var attack_range: float = 32.0
var base_visual_scale: Vector2 = Vector2.ONE
var hp: int
var player: Node2D
var anim_time: float = 0.0
var is_hurt_animating: bool = false
var knockback: Vector2 = Vector2.ZERO
var keep_distance: float = 24.0

func _ready():
	_apply_zombie_type(zombie_type)
	hp = max_hp
	add_to_group("zombie")
	setup_placeholder_visual()

	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player = players[0]

	if damage_timer != null:
		damage_timer.wait_time = attack_cooldown
		damage_timer.stop()

func configure_zombie(p_zombie_type: String):
	zombie_type = p_zombie_type
	_apply_zombie_type(zombie_type)
	hp = max_hp
	can_attack = true

func _apply_zombie_type(p_zombie_type: String):
	var zombie_data = EnemyDatabase.get_enemy_data(p_zombie_type)
	speed = float(zombie_data.get("speed", 90.0))
	max_hp = int(zombie_data.get("max_hp", 50))
	damage = int(zombie_data.get("damage", 10))
	exp_value = int(zombie_data.get("exp_value", 1))
	score_value = int(zombie_data.get("score_value", 1))
	knockback_strength = float(zombie_data.get("knockback_strength", 220.0))
	attack_cooldown = float(zombie_data.get("attack_cooldown", 0.8))
	attack_range = float(zombie_data.get("attack_range", 32.0))
	keep_distance = max(attack_range * 0.75, 24.0)
	base_visual_scale = zombie_data.get("visual_scale", Vector2.ONE)

	if body != null:
		body.color = zombie_data.get("color", Color(0.25, 0.9, 0.35))
		body.scale = base_visual_scale

func setup_placeholder_visual():
	if body == null:
		return

	body.polygon = PackedVector2Array([
		Vector2(0, -18),
		Vector2(15, -7),
		Vector2(12, 12),
		Vector2(0, 18),
		Vector2(-14, 10),
		Vector2(-16, -8)
	])

	if body.color == Color(0, 0, 0, 0):
		body.color = Color(0.25, 0.9, 0.35)

func _physics_process(delta):
	if player == null or not is_instance_valid(player):
		return

	var to_player = player.global_position - global_position
	var distance = to_player.length()
	var dir = to_player.normalized() if distance > 0.001 else Vector2.ZERO
	var move_velocity = Vector2.ZERO

	if distance > keep_distance:
		move_velocity = dir * speed
	elif distance < keep_distance * 0.6:
		move_velocity = -dir * speed * 0.7

	velocity = move_velocity + knockback
	move_and_slide()
	knockback = knockback.move_toward(Vector2.ZERO, 900.0 * delta)
	update_animation(delta, dir)
	try_attack_player()

func update_animation(delta, dir: Vector2):
	if is_hurt_animating or body == null:
		return

	anim_time += delta
	body.rotation = dir.angle()

	var wobble_x = 1.0 + sin(anim_time * 8.0) * 0.08
	var wobble_y = 1.0 + cos(anim_time * 8.0) * 0.05
	body.scale = Vector2(wobble_x, wobble_y) * base_visual_scale

func take_damage(amount: int, hit_direction: Vector2 = Vector2.ZERO):
	hp -= amount
	hp = max(hp, 0)

	if hit_direction != Vector2.ZERO:
		knockback = hit_direction.normalized() * knockback_strength
	elif player != null and is_instance_valid(player):
		knockback = (global_position - player.global_position).normalized() * knockback_strength

	_spawn_hit_flash()
	play_hurt_animation()

	if hp <= 0:
		die()

func _spawn_hit_flash():
	var main = get_tree().current_scene
	if main != null and main.has_method("spawn_hit_flash"):
		main.spawn_hit_flash(global_position, zombie_type == "mini_boss" or zombie_type == "boss")

func play_hurt_animation():
	if is_hurt_animating or body == null:
		return

	is_hurt_animating = true
	var old_color = body.color
	body.color = Color(1.0, 1.0, 1.0)
	body.scale = base_visual_scale * 1.35

	await get_tree().create_timer(0.08).timeout

	body.color = old_color
	body.scale = base_visual_scale
	is_hurt_animating = false

func die():
	var main = get_tree().current_scene
	if main == null:
		queue_free()
		return

	var boss_like := zombie_type == "mini_boss" or zombie_type == "boss"
	var burst_color := Color(0, 0, 0, 0)
	if zombie_type == "exploder":
		burst_color = Color(1.0, 0.55, 0.15, 1.0)

	if main.has_method("shake_camera") and boss_like:
		main.shake_camera(4.0, 0.18)

	if main.has_method("spawn_death_effect"):
		main.spawn_death_effect(global_position, boss_like)

	if main.has_method("spawn_death_burst"):
		main.spawn_death_burst(global_position, boss_like, burst_color)

	if main.has_method("add_score"):
		main.add_score(score_value)

	if main.has_method("add_exp"):
		main.add_exp(exp_value)

	if main.has_method("notify_zombie_died"):
		main.notify_zombie_died()

	if exp_gem_scene != null:
		var gem = exp_gem_scene.instantiate()
		gem.global_position = global_position
		main.add_child(gem)

	_spawn_weapon_drop(main)
	queue_free()

func _spawn_weapon_drop(main: Node):
	var zombie_data = EnemyDatabase.get_enemy_data(zombie_type)
	var drop_chance = float(zombie_data.get("weapon_drop_chance", 0.0))

	if weapon_drop_scene == null or randf() > drop_chance:
		return

	var weapon_id = _pick_weapon_drop_id(zombie_data.get("weapon_drop_weights", {}))
	if weapon_id == "":
		return

	var drop = weapon_drop_scene.instantiate()
	drop.global_position = global_position
	drop.weapon_id = weapon_id
	main.add_child(drop)

func _pick_weapon_drop_id(weights: Dictionary) -> String:
	if weights.is_empty():
		return ""

	var total_weight := 0
	for value in weights.values():
		total_weight += int(value)

	if total_weight <= 0:
		return ""

	var roll := randi() % total_weight
	var cumulative := 0
	for weapon_id in weights.keys():
		cumulative += int(weights[weapon_id])
		if roll < cumulative:
			return String(weapon_id)

	return ""

func _on_attack_area_body_entered(body_hit):
	if body_hit.is_in_group("player"):
		player = body_hit

func _on_damage_timer_timeout():
	can_attack = true

func try_attack_player():
	if player == null or not is_instance_valid(player):
		return

	if not can_attack:
		return

	var distance = global_position.distance_to(player.global_position)
	if distance > attack_range:
		return

	if player.has_method("take_damage"):
		can_attack = false
		player.take_damage(damage)
		if damage_timer != null:
			damage_timer.wait_time = attack_cooldown
			damage_timer.start()
