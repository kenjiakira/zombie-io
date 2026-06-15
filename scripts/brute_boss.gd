extends CharacterBody2D

const BOSS_TYPES := {
	"mini_boss": {
		"name": "Brute Zombie",
		"speed": 72.0,
		"max_hp": 320,
		"damage": 18,
		"score_value": 12,
		"exp_value": 10,
		"charge_speed": 260.0,
		"charge_damage": 22,
		"charge_duration": 0.65,
		"slam_damage": 28,
		"slam_radius": 90.0,
		"slam_windup": 0.4,
		"summon_count": 3,
		"summon_uses": 2,
		"attack_interval": 2.4,
		"recover_time": 0.45,
		"weapon_drop_chance": 1.0,
		"weapon_drop_weights": {"shotgun": 40, "smg": 35, "rifle": 25},
		"color": Color(0.95, 0.45, 0.2),
		"visual_scale": Vector2(1.55, 1.55),
		"summon_types": ["normal", "normal", "fast"]
	},
	"boss": {
		"name": "Brute Zombie",
		"speed": 55.0,
		"max_hp": 1100,
		"damage": 30,
		"score_value": 60,
		"exp_value": 35,
		"charge_speed": 330.0,
		"charge_damage": 34,
		"charge_duration": 0.8,
		"slam_damage": 44,
		"slam_radius": 120.0,
		"slam_windup": 0.5,
		"summon_count": 4,
		"summon_uses": 4,
		"attack_interval": 2.0,
		"recover_time": 0.5,
		"weapon_drop_chance": 1.0,
		"weapon_drop_weights": {"shotgun": 20, "smg": 30, "rifle": 50},
		"color": Color(0.95, 0.2, 0.2),
		"visual_scale": Vector2(2.15, 2.15),
		"summon_types": ["normal", "fast", "fast", "tank"]
	}
}

@export var boss_type: String = "mini_boss"
@export var exp_gem_scene: PackedScene
@export var weapon_drop_scene: PackedScene
@export var death_effect_scene: PackedScene

@onready var body: Polygon2D = $Body

var player: Node2D
var hp: int = 1
var max_hp: int = 1
var speed: float = 60.0
var damage: int = 20
var score_value: int = 10
var exp_value: int = 10
var charge_speed: float = 280.0
var charge_damage: int = 24
var charge_duration: float = 0.7
var slam_damage: int = 30
var slam_radius: float = 96.0
var slam_windup: float = 0.4
var summon_count: int = 3
var summon_uses_left: int = 2
var attack_interval: float = 2.4
var recover_time: float = 0.45
var base_visual_scale: Vector2 = Vector2.ONE
var summon_types: Array = ["normal"]
var boss_color: Color = Color(0.95, 0.2, 0.2)

var anim_time: float = 0.0
var state: String = "chase"
var state_time: float = 0.0
var attack_timer: float = 1.0
var charge_dir: Vector2 = Vector2.ZERO
var charge_hit_done: bool = false
var slam_done: bool = false
var knockback: Vector2 = Vector2.ZERO
var is_hurt_animating: bool = false

func _ready():
	setup_placeholder_visual()
	_apply_boss_type(boss_type)
	hp = max_hp

	add_to_group("zombie")

	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player = players[0]

func configure_boss(p_boss_type: String):
	boss_type = p_boss_type
	_apply_boss_type(boss_type)
	hp = max_hp

func _apply_boss_type(p_boss_type: String):
	var boss_data = BOSS_TYPES.get(p_boss_type, BOSS_TYPES["mini_boss"])

	speed = boss_data["speed"]
	max_hp = boss_data["max_hp"]
	damage = boss_data["damage"]
	score_value = boss_data["score_value"]
	exp_value = boss_data["exp_value"]
	charge_speed = boss_data["charge_speed"]
	charge_damage = boss_data["charge_damage"]
	charge_duration = boss_data["charge_duration"]
	slam_damage = boss_data["slam_damage"]
	slam_radius = boss_data["slam_radius"]
	slam_windup = boss_data["slam_windup"]
	summon_count = boss_data["summon_count"]
	summon_uses_left = boss_data["summon_uses"]
	attack_interval = boss_data["attack_interval"]
	recover_time = boss_data["recover_time"]
	base_visual_scale = boss_data["visual_scale"]
	summon_types = boss_data["summon_types"]
	boss_color = boss_data["color"]

	if body != null:
		body.color = boss_color

func setup_placeholder_visual():
	body.polygon = PackedVector2Array([
		Vector2(-24, -22),
		Vector2(22, -22),
		Vector2(30, -2),
		Vector2(22, 22),
		Vector2(-22, 22),
		Vector2(-30, 2)
	])
	body.color = boss_color

func _physics_process(delta):
	if player == null or not is_instance_valid(player):
		return

	anim_time += delta

	match state:
		"chase":
			_chase_player(delta)
			attack_timer -= delta
			if attack_timer <= 0.0:
				_choose_attack()
		"charge":
			_do_charge(delta)
		"slam_windup":
			_do_slam_windup(delta)
		"recover":
			_do_recover(delta)

func _chase_player(delta):
	var dir = (player.global_position - global_position).normalized()
	velocity = dir * speed + knockback
	move_and_slide()

	knockback = knockback.move_toward(Vector2.ZERO, 550 * delta)
	_apply_body_pose(dir, base_visual_scale)

func _choose_attack():
	attack_timer = attack_interval

	var distance = global_position.distance_to(player.global_position)

	if summon_uses_left > 0 and (distance > 180.0 or randf() < 0.25):
		_start_summon()
		return

	if distance <= slam_radius * 1.4 or randf() < 0.5:
		_start_slam()
		return

	_start_charge()

func _start_charge():
	state = "charge"
	state_time = charge_duration
	charge_dir = (player.global_position - global_position).normalized()
	charge_hit_done = false

func _do_charge(delta):
	velocity = charge_dir * charge_speed
	move_and_slide()

	_apply_body_pose(charge_dir, base_visual_scale * 1.12)
	state_time -= delta

	if not charge_hit_done and global_position.distance_to(player.global_position) <= 36.0:
		if player.has_method("take_damage"):
			player.take_damage(charge_damage)
		charge_hit_done = true

	if state_time <= 0.0:
		_start_recover()

func _start_slam():
	state = "slam_windup"
	state_time = slam_windup
	slam_done = false

func _do_slam_windup(delta):
	velocity = Vector2.ZERO
	move_and_slide()
	_apply_body_pose((player.global_position - global_position).normalized(), base_visual_scale * 1.08)
	state_time -= delta

	if state_time <= 0.0 and not slam_done:
		slam_done = true
		_perform_slam()
		_start_recover()

func _perform_slam():
	if global_position.distance_to(player.global_position) <= slam_radius:
		if player.has_method("take_damage"):
			player.take_damage(slam_damage)

func _start_summon():
	state = "recover"
	state_time = 0.2
	summon_uses_left -= 1
	_summon_minions()

func _summon_minions():
	var main = get_tree().current_scene
	if main == null or not main.has_method("spawn_zombie_of_type"):
		return

	var minion_types = summon_types.duplicate()
	var angle_step = TAU / float(summon_count)

	for i in range(summon_count):
		var angle = angle_step * float(i) + randf() * 0.35
		var offset = Vector2(cos(angle), sin(angle)) * 90.0
		var minion_type = String(minion_types[i % minion_types.size()])
		main.spawn_zombie_of_type(minion_type, global_position + offset)

func _start_recover():
	state = "recover"
	state_time = recover_time

func _do_recover(delta):
	velocity = Vector2.ZERO
	move_and_slide()
	_apply_body_pose(Vector2.RIGHT, base_visual_scale)
	state_time -= delta

	if state_time <= 0.0:
		state = "chase"
		attack_timer = attack_interval

func _apply_body_pose(dir: Vector2, visual_scale: Vector2):
	if is_hurt_animating:
		return

	if dir != Vector2.ZERO:
		body.rotation = dir.angle()

	var pulse = 1.0 + sin(anim_time * 5.0) * 0.04
	body.scale = visual_scale * pulse

func take_damage(amount: int, hit_direction: Vector2 = Vector2.ZERO):
	hp -= amount

	if hit_direction != Vector2.ZERO:
		knockback = hit_direction.normalized() * 220.0

	play_hurt_animation()

	if hp <= 0:
		die()

func play_hurt_animation():
	if is_hurt_animating:
		return

	is_hurt_animating = true
	body.color = Color(1.0, 1.0, 1.0)
	body.scale = base_visual_scale * 1.22

	await get_tree().create_timer(0.08).timeout

	body.color = boss_color
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
	var boss_data = BOSS_TYPES.get(boss_type, BOSS_TYPES["mini_boss"])
	var drop_chance = float(boss_data.get("weapon_drop_chance", 0.0))

	if weapon_drop_scene == null or randf() > drop_chance:
		return

	var weapon_id = _pick_weapon_drop_id(boss_data.get("weapon_drop_weights", {}))
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
