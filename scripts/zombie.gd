extends CharacterBody2D

const ZOMBIE_TYPES := {
	"normal": {
		"name": "Normal",
		"speed": 90.0,
		"max_hp": 50,
		"damage": 10,
		"exp_value": 1,
		"score_value": 1,
		"knockback_strength": 220.0,
		"attack_cooldown": 0.8,
		"attack_range": 32.0,
		"weapon_drop_chance": 0.10,
		"weapon_drop_weights": {"pistol": 60, "smg": 25, "shotgun": 15},
		"visual_scale": Vector2.ONE,
		"color": Color(0.25, 0.9, 0.35)
	},
	"fast": {
		"name": "Fast",
		"speed": 150.0,
		"max_hp": 35,
		"damage": 8,
		"exp_value": 1,
		"score_value": 1,
		"knockback_strength": 180.0,
		"attack_cooldown": 0.65,
		"attack_range": 28.0,
		"weapon_drop_chance": 0.12,
		"weapon_drop_weights": {"pistol": 20, "smg": 45, "shotgun": 35},
		"visual_scale": Vector2(0.9, 0.9),
		"color": Color(0.9, 0.8, 0.25)
	},
	"tank": {
		"name": "Tank",
		"speed": 60.0,
		"max_hp": 120,
		"damage": 18,
		"exp_value": 3,
		"score_value": 3,
		"knockback_strength": 300.0,
		"attack_cooldown": 1.0,
		"attack_range": 36.0,
		"weapon_drop_chance": 0.18,
		"weapon_drop_weights": {"smg": 15, "shotgun": 45, "rifle": 40},
		"visual_scale": Vector2(1.2, 1.2),
		"color": Color(0.75, 0.3, 0.85)
	},
	"mini_boss": {
		"name": "Mini Boss",
		"speed": 70.0,
		"max_hp": 280,
		"damage": 22,
		"exp_value": 8,
		"score_value": 10,
		"knockback_strength": 360.0,
		"attack_cooldown": 1.1,
		"attack_range": 42.0,
		"weapon_drop_chance": 1.0,
		"weapon_drop_weights": {"shotgun": 35, "smg": 35, "rifle": 30},
		"visual_scale": Vector2(1.55, 1.55),
		"color": Color(0.95, 0.45, 0.2)
	},
	"boss": {
		"name": "Boss",
		"speed": 55.0,
		"max_hp": 700,
		"damage": 35,
		"exp_value": 25,
		"score_value": 40,
		"knockback_strength": 480.0,
		"attack_cooldown": 1.25,
		"attack_range": 48.0,
		"weapon_drop_chance": 1.0,
		"weapon_drop_weights": {"shotgun": 20, "smg": 30, "rifle": 50},
		"visual_scale": Vector2(2.1, 2.1),
		"color": Color(0.95, 0.2, 0.2)
	}
}

@export var zombie_type: String = "normal"
@export var exp_gem_scene: PackedScene
@export var weapon_drop_scene: PackedScene
@export var death_effect_scene: PackedScene

@onready var body: Polygon2D = $Body
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
var player = null
var anim_time: float = 0.0
var is_hurt_animating: bool = false
var knockback: Vector2 = Vector2.ZERO

func _ready():
	_apply_zombie_type(zombie_type)
	hp = max_hp
	add_to_group("zombie")

	setup_placeholder_visual()

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	if damage_timer != null:
		damage_timer.stop()

func configure_zombie(p_zombie_type: String):
	zombie_type = p_zombie_type
	_apply_zombie_type(zombie_type)
	hp = max_hp

func _apply_zombie_type(p_zombie_type: String):
	var zombie_data = ZOMBIE_TYPES.get(p_zombie_type, ZOMBIE_TYPES["normal"])

	speed = zombie_data["speed"]
	max_hp = zombie_data["max_hp"]
	damage = zombie_data["damage"]
	exp_value = zombie_data["exp_value"]
	score_value = zombie_data["score_value"]
	knockback_strength = zombie_data["knockback_strength"]
	attack_cooldown = zombie_data["attack_cooldown"]
	attack_range = zombie_data["attack_range"]
	base_visual_scale = zombie_data["visual_scale"]

	if body != null:
		body.color = zombie_data["color"]

func setup_placeholder_visual():
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
	if player == null:
		return

	var dir = (player.global_position - global_position).normalized()

	velocity = dir * speed + knockback
	move_and_slide()

	knockback = knockback.move_toward(Vector2.ZERO, 700 * delta)

	update_animation(delta, dir)
	try_attack_player()

func update_animation(delta, dir: Vector2):
	if is_hurt_animating:
		return

	anim_time += delta

	body.rotation = dir.angle()

	var wobble_x = 1.0 + sin(anim_time * 8.0) * 0.08
	var wobble_y = 1.0 + cos(anim_time * 8.0) * 0.05
	body.scale = Vector2(wobble_x, wobble_y) * base_visual_scale

func take_damage(amount: int, hit_direction: Vector2 = Vector2.ZERO):
	hp -= amount

	if hit_direction != Vector2.ZERO:
		knockback = hit_direction.normalized() * knockback_strength
	elif player != null:
		knockback = (global_position - player.global_position).normalized() * knockback_strength

	play_hurt_animation()

	if hp <= 0:
		die()

func play_hurt_animation():
	if is_hurt_animating:
		return

	is_hurt_animating = true

	body.color = Color(1.0, 1.0, 1.0)
	body.scale = base_visual_scale * 1.35

	await get_tree().create_timer(0.07).timeout

	_apply_zombie_type(zombie_type)
	body.scale = base_visual_scale

	is_hurt_animating = false

func die():
	var main = get_tree().current_scene

	if death_effect_scene != null:
		var effect = death_effect_scene.instantiate()
		effect.global_position = global_position
		main.add_child(effect)

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
	var zombie_data = ZOMBIE_TYPES.get(zombie_type, ZOMBIE_TYPES["normal"])
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

func play_death_effect():
	pass

func _on_attack_area_body_entered(body_hit):
	if body_hit.is_in_group("player"):
		player = body_hit

func _on_damage_timer_timeout():
	pass

func try_attack_player():
	if player == null or not is_instance_valid(player):
		return

	if not can_attack:
		return

	var distance = global_position.distance_to(player.global_position)

	if distance <= attack_range:
		if player.has_method("take_damage"):
			can_attack = false
			player.take_damage(damage)

			await get_tree().create_timer(attack_cooldown).timeout
			can_attack = true
