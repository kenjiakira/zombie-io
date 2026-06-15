extends CharacterBody2D

signal hp_changed(current_hp, max_hp)
signal died
signal weapon_changed(weapon_id, weapon_name)

@export var speed: float = 230.0
@export var max_hp: int = 100
@export var damage: int = 25
@export var bullet_scene: PackedScene
@export var starting_weapon_id: String = "pistol"

@onready var body: Polygon2D = $Body
@onready var shoot_timer: Timer = $ShootTimer

var hp: int
var facing_dir: Vector2 = Vector2.RIGHT
var anim_time: float = 0.0
var is_hurt_animating: bool = false
var current_weapon_id: String = "pistol"
var weapon_data: Dictionary = {}
var weapons: Dictionary = {}

const WEAPON_LIBRARY := {
	"pistol": {
		"name": "Pistol",
		"shoot_rate": 0.45,
		"bullet_speed": 650.0,
		"bullet_damage": 25,
		"bullet_life_time": 1.2,
		"projectile_count": 1,
		"spread_degrees": 0.0
	},
	"shotgun": {
		"name": "Shotgun",
		"shoot_rate": 0.95,
		"bullet_speed": 560.0,
		"bullet_damage": 16,
		"bullet_life_time": 0.95,
		"projectile_count": 5,
		"spread_degrees": 18.0
	},
	"smg": {
		"name": "SMG",
		"shoot_rate": 0.14,
		"bullet_speed": 610.0,
		"bullet_damage": 11,
		"bullet_life_time": 1.0,
		"projectile_count": 1,
		"spread_degrees": 4.0
	},
	"rifle": {
		"name": "Rifle",
		"shoot_rate": 0.22,
		"bullet_speed": 780.0,
		"bullet_damage": 18,
		"bullet_life_time": 1.35,
		"projectile_count": 1,
		"spread_degrees": 0.0
	}
}

func _ready():
	hp = max_hp
	add_to_group("player")
	hp_changed.emit(hp, max_hp)
	weapons = {}
	add_weapon(starting_weapon_id)
	equip_weapon(starting_weapon_id)

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
	_handle_weapon_switch_input()

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

func _handle_weapon_switch_input():
	if Input.is_key_pressed(KEY_1) and current_weapon_id != "pistol":
		equip_weapon("pistol")
	elif Input.is_key_pressed(KEY_2) and has_weapon("shotgun") and current_weapon_id != "shotgun":
		equip_weapon("shotgun")
	elif Input.is_key_pressed(KEY_3) and has_weapon("smg") and current_weapon_id != "smg":
		equip_weapon("smg")
	elif Input.is_key_pressed(KEY_4) and has_weapon("rifle") and current_weapon_id != "rifle":
		equip_weapon("rifle")

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

func equip_weapon(weapon_id: String):
	if not weapons.has(weapon_id):
		weapon_id = "pistol"

	current_weapon_id = weapon_id
	weapon_data = weapons[current_weapon_id]
	damage = int(weapon_data.get("bullet_damage", damage))
	shoot_timer.wait_time = float(weapon_data.get("shoot_rate", 0.45))
	weapons[current_weapon_id] = weapon_data
	weapon_changed.emit(current_weapon_id, get_current_weapon_name())

func add_weapon(weapon_id: String) -> bool:
	if WEAPON_LIBRARY.has(weapon_id):
		weapons[weapon_id] = WEAPON_LIBRARY[weapon_id].duplicate(true)
		return true

	return false

func has_weapon(weapon_id: String) -> bool:
	return weapons.has(weapon_id)

func pickup_weapon(weapon_id: String):
	if not WEAPON_LIBRARY.has(weapon_id):
		return

	add_weapon(weapon_id)
	equip_weapon(weapon_id)

func get_current_weapon_name() -> String:
	return String(weapon_data.get("name", "Pistol"))

func get_weapon_ids() -> Array:
	return weapons.keys()

func upgrade_current_weapon_damage(amount: int):
	weapon_data["bullet_damage"] = int(weapon_data.get("bullet_damage", damage)) + amount
	damage = int(weapon_data["bullet_damage"])
	weapons[current_weapon_id] = weapon_data

func upgrade_current_weapon_speed(amount: float):
	weapon_data["bullet_speed"] = float(weapon_data.get("bullet_speed", 650.0)) + amount
	weapons[current_weapon_id] = weapon_data

func upgrade_current_weapon_fire_rate(delta: float):
	weapon_data["shoot_rate"] = maxf(0.08, float(weapon_data.get("shoot_rate", shoot_timer.wait_time)) - delta)
	shoot_timer.wait_time = float(weapon_data["shoot_rate"])
	weapons[current_weapon_id] = weapon_data

func upgrade_current_weapon_spread(delta: float):
	weapon_data["spread_degrees"] = maxf(0.0, float(weapon_data.get("spread_degrees", 0.0)) - delta)
	weapons[current_weapon_id] = weapon_data

func upgrade_current_weapon_projectiles(amount: int):
	weapon_data["projectile_count"] = max(1, int(weapon_data.get("projectile_count", 1)) + amount)
	weapons[current_weapon_id] = weapon_data

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

	var direction = (target.global_position - global_position).normalized()
	_fire_weapon(direction)

func _fire_weapon(direction: Vector2):
	if bullet_scene == null:
		return

	var projectile_count := int(weapon_data.get("projectile_count", 1))
	var spread_degrees := float(weapon_data.get("spread_degrees", 0.0))
	var bullet_speed := float(weapon_data.get("bullet_speed", 650.0))
	var bullet_damage := int(weapon_data.get("bullet_damage", damage))
	var bullet_life_time := float(weapon_data.get("bullet_life_time", 1.2))

	if projectile_count <= 1:
		_spawn_bullet(direction, bullet_speed, bullet_damage, bullet_life_time)
		return

	var spread_radians = deg_to_rad(spread_degrees)
	var step = 0.0

	if projectile_count > 1:
		step = spread_radians / float(projectile_count - 1)

	var start_angle = -spread_radians * 0.5

	for i in range(projectile_count):
		var angle = start_angle + step * float(i)
		var shot_direction = direction.rotated(angle)
		_spawn_bullet(shot_direction, bullet_speed, bullet_damage, bullet_life_time)

func _spawn_bullet(direction: Vector2, bullet_speed: float, bullet_damage: int, bullet_life_time: float):
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position

	if bullet.has_method("configure"):
		bullet.configure(direction, bullet_speed, bullet_damage, bullet_life_time)
	else:
		bullet.direction = direction

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
