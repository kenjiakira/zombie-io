extends CharacterBody2D

signal hp_changed(current_hp, max_hp)
signal died
signal weapon_changed(weapon_id, weapon_name)
signal ammo_changed(current_ammo, reserve_ammo, magazine_size)
signal reload_state_changed(is_reloading)

const WeaponDatabase = preload("res://scripts/data/weapon_database.gd")
const PLAYER_SPRITE_SHEETS := {
	"idle_down": preload("res://assets/Character/Idle/Character_down_idle-Sheet6.png"),
	"idle_side": preload("res://assets/Character/Idle/Character_side_idle-Sheet6.png"),
	"idle_up": preload("res://assets/Character/Idle/Character_up_idle-Sheet6.png"),
	"run_down": preload("res://assets/Character/Run/Character_down_run-Sheet6.png"),
	"run_side": preload("res://assets/Character/Run/Character_side_run-Sheet6.png"),
	"run_up": preload("res://assets/Character/Run/Character_up_run-Sheet6.png")
}
const PLAYER_ANIM_FRAME_COUNTS := {
	"idle_down": 6,
	"idle_side": 6,
	"idle_up": 6,
	"run_down": 6,
	"run_side": 6,
	"run_up": 6
}

@export var speed: float = 230.0
@export var max_hp: int = 100
@export var damage: int = 25
@export var bullet_scene: PackedScene
@export var starting_weapon_id: String = "pistol"

@onready var body: Node2D = $Body
@onready var animated_sprite: AnimatedSprite2D = $Body/AnimatedSprite2D
@onready var shoot_timer: Timer = $ShootTimer

var hp: int
var facing_dir: Vector2 = Vector2.RIGHT
var is_hurt_animating: bool = false
var current_weapon_id: String = "pistol"
var weapon_data: Dictionary = {}
var weapons: Dictionary = {}
var ammo_state: Dictionary = {}
var is_reloading: bool = false
var reload_token: int = 0
var reloading_weapon_id: String = ""
var prev_reload_key_pressed: bool = false
var prev_weapon_key_pressed: Dictionary = {}

func _ready():
	hp = max_hp
	add_to_group("player")
	hp_changed.emit(hp, max_hp)
	weapons = {}
	ammo_state = {}
	if not add_weapon(starting_weapon_id):
		add_weapon("pistol")
		starting_weapon_id = "pistol"
	equip_weapon(starting_weapon_id)
	_setup_sprite_frames()
	update_animation(Vector2.ZERO)

func _setup_sprite_frames():
	if animated_sprite == null:
		return

	var sprite_frames := SpriteFrames.new()
	for anim_name in PLAYER_SPRITE_SHEETS.keys():
		var texture: Texture2D = PLAYER_SPRITE_SHEETS[anim_name]
		var frame_count: int = PLAYER_ANIM_FRAME_COUNTS[anim_name]
		sprite_frames.add_animation(anim_name)
		sprite_frames.set_animation_speed(anim_name, 8.0 if anim_name.begins_with("run_") else 6.0)
		sprite_frames.set_animation_loop(anim_name, true)
		_add_sheet_frames(sprite_frames, anim_name, texture, frame_count)

	animated_sprite.sprite_frames = sprite_frames
	animated_sprite.centered = true
	animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	animated_sprite.play("idle_side")

func _add_sheet_frames(sprite_frames: SpriteFrames, anim_name: String, texture: Texture2D, frame_count: int):
	if texture == null or frame_count <= 0:
		return

	var frame_width := texture.get_width() / frame_count
	var frame_height := texture.get_height()

	for frame_index in range(frame_count):
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = texture
		atlas_texture.region = Rect2(frame_width * frame_index, 0, frame_width, frame_height)
		sprite_frames.add_frame(anim_name, atlas_texture)

func _physics_process(delta):
	_handle_weapon_switch_input()

	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if input_dir != Vector2.ZERO:
		facing_dir = input_dir

	velocity = input_dir * speed
	move_and_slide()
	update_animation(input_dir)

func _handle_weapon_switch_input():
	var reload_key_pressed = Input.is_key_pressed(KEY_R)
	if reload_key_pressed and not prev_reload_key_pressed:
		reload_current_weapon()
		prev_reload_key_pressed = reload_key_pressed
		return

	prev_reload_key_pressed = reload_key_pressed

	var weapon_ids = WeaponDatabase.get_weapon_ids()
	var weapon_keys = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0]
	var slot_count = min(weapon_keys.size(), weapon_ids.size())

	for i in range(slot_count):
		var weapon_id = String(weapon_ids[i])
		var key_code = weapon_keys[i]
		var key_pressed = Input.is_key_pressed(key_code)
		var prev_pressed = bool(prev_weapon_key_pressed.get(key_code, false))

		prev_weapon_key_pressed[key_code] = key_pressed

		if key_pressed and not prev_pressed and has_weapon(weapon_id) and current_weapon_id != weapon_id:
			equip_weapon(weapon_id)
			return

	if not reload_key_pressed:
		prev_reload_key_pressed = false

func update_animation(input_dir: Vector2):
	if animated_sprite == null:
		return

	var is_moving := input_dir.length_squared() > 0.0001
	var direction := facing_dir if is_moving else facing_dir.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT

	var direction_suffix := _get_direction_suffix(direction)
	var anim_prefix := "run_" if is_moving else "idle_"
	var animation_name := anim_prefix + direction_suffix

	animated_sprite.flip_h = direction_suffix == "side" and direction.x < 0.0

	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)
	elif not animated_sprite.is_playing():
		animated_sprite.play()

func _get_direction_suffix(direction: Vector2) -> String:
	if absf(direction.x) > absf(direction.y):
		return "side"
	if direction.y < 0.0:
		return "up"
	return "down"

func take_damage(amount: int):
	hp -= amount
	hp = max(hp, 0)
	hp_changed.emit(hp, max_hp)

	play_hurt_animation()

	if hp <= 0:
		died.emit()

func equip_weapon(weapon_id: String):
	if not weapons.has(weapon_id):
		if weapons.has("pistol"):
			weapon_id = "pistol"
		elif not weapons.is_empty():
			var owned_weapon_ids = get_weapon_ids()
			if not owned_weapon_ids.is_empty():
				weapon_id = String(owned_weapon_ids[0])
			else:
				weapon_id = String(weapons.keys()[0])
		else:
			return

	if is_reloading:
		_cancel_reload()

	current_weapon_id = weapon_id
	weapon_data = weapons[current_weapon_id]
	damage = int(weapon_data.get("bullet_damage", damage))
	shoot_timer.wait_time = float(weapon_data.get("shoot_rate", 0.45))
	if shoot_timer != null and shoot_timer.is_stopped():
		shoot_timer.start()
	weapons[current_weapon_id] = weapon_data
	weapon_changed.emit(current_weapon_id, get_current_weapon_name())
	_emit_ammo_state()

func add_weapon(weapon_id: String) -> bool:
	if WeaponDatabase.has_weapon(weapon_id):
		weapons[weapon_id] = WeaponDatabase.get_weapon_data(weapon_id)
		ammo_state[weapon_id] = _create_ammo_state(weapons[weapon_id])
		return true

	return false

func has_weapon(weapon_id: String) -> bool:
	return weapons.has(weapon_id)

func pickup_weapon(weapon_id: String):
	if not WeaponDatabase.has_weapon(weapon_id):
		return

	var was_new = not weapons.has(weapon_id)
	add_weapon(weapon_id)
	if was_new:
		ammo_state[weapon_id] = _create_ammo_state(weapons[weapon_id])
	equip_weapon(weapon_id)

func get_current_weapon_name() -> String:
	return String(weapon_data.get("name", "Pistol"))

func get_weapon_ids() -> Array:
	var owned_weapon_ids: Array = []
	for weapon_id in WeaponDatabase.get_weapon_ids():
		if weapons.has(weapon_id):
			owned_weapon_ids.append(weapon_id)
	return owned_weapon_ids

func get_current_ammo() -> int:
	return int(ammo_state.get(current_weapon_id, {}).get("current_ammo", 0))

func get_current_reserve_ammo() -> int:
	return int(ammo_state.get(current_weapon_id, {}).get("reserve_ammo", 0))

func get_current_magazine_size() -> int:
	return int(weapon_data.get("magazine_size", 1))

func is_current_weapon_reloading() -> bool:
	return is_reloading

func reload_current_weapon():
	if is_reloading or weapon_data.is_empty():
		return

	var state = ammo_state.get(current_weapon_id, {})
	var current_ammo = int(state.get("current_ammo", 0))
	var reserve_ammo = int(state.get("reserve_ammo", 0))
	var magazine_size = int(weapon_data.get("magazine_size", 1))

	if current_ammo >= magazine_size or reserve_ammo <= 0:
		return

	is_reloading = true
	reloading_weapon_id = current_weapon_id
	reload_token += 1
	var local_reload_token = reload_token
	reload_state_changed.emit(true)

	if shoot_timer != null:
		shoot_timer.stop()

	var reload_time = float(weapon_data.get("reload_time", 1.0))
	await get_tree().create_timer(reload_time).timeout

	if not is_instance_valid(self):
		return

	if local_reload_token != reload_token or reloading_weapon_id != current_weapon_id:
		return

	state = ammo_state.get(current_weapon_id, {})
	current_ammo = int(state.get("current_ammo", 0))
	reserve_ammo = int(state.get("reserve_ammo", 0))
	magazine_size = int(weapon_data.get("magazine_size", 1))

	var missing_ammo = max(magazine_size - current_ammo, 0)
	var ammo_to_load = min(missing_ammo, reserve_ammo)
	current_ammo += ammo_to_load
	reserve_ammo -= ammo_to_load

	ammo_state[current_weapon_id] = {
		"current_ammo": current_ammo,
		"reserve_ammo": reserve_ammo
	}

	is_reloading = false
	reloading_weapon_id = ""
	reload_state_changed.emit(false)
	_emit_ammo_state()

	if shoot_timer != null:
		shoot_timer.start()

func add_ammo_to_current_weapon(amount: int):
	if amount <= 0 or weapon_data.is_empty():
		return

	var state = ammo_state.get(current_weapon_id, {})
	if state.is_empty():
		return

	state["reserve_ammo"] = int(state.get("reserve_ammo", 0)) + amount
	ammo_state[current_weapon_id] = state
	_emit_ammo_state()

func _create_ammo_state(weapon: Dictionary) -> Dictionary:
	var magazine_size = max(1, int(weapon.get("magazine_size", 1)))
	var reserve_ammo = max(0, int(weapon.get("reserve_ammo", 0)))
	return {
		"current_ammo": magazine_size,
		"reserve_ammo": reserve_ammo
	}

func _emit_ammo_state():
	var state = ammo_state.get(current_weapon_id, {})
	ammo_changed.emit(
		int(state.get("current_ammo", 0)),
		int(state.get("reserve_ammo", 0)),
		int(weapon_data.get("magazine_size", 1))
	)

func _cancel_reload():
	reload_token += 1
	is_reloading = false
	reloading_weapon_id = ""
	reload_state_changed.emit(false)

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

	if body != null:
		body.scale = Vector2(1.12, 1.12)
	if animated_sprite != null:
		animated_sprite.modulate = Color(1.0, 0.4, 0.4)

	await get_tree().create_timer(0.08).timeout

	if animated_sprite != null:
		animated_sprite.modulate = Color.WHITE
	if body != null:
		body.scale = Vector2.ONE

	is_hurt_animating = false

func _on_shoot_timer_timeout():
	if is_reloading:
		return

	var state = ammo_state.get(current_weapon_id, {})
	var current_ammo = int(state.get("current_ammo", 0))
	var reserve_ammo = int(state.get("reserve_ammo", 0))

	if current_ammo <= 0:
		if reserve_ammo > 0:
			reload_current_weapon()
		return

	var target = get_nearest_zombie()

	if target == null:
		return

	var direction = (target.global_position - global_position).normalized()
	_fire_weapon(direction)

func _fire_weapon(direction: Vector2):
	if bullet_scene == null:
		return

	var state = ammo_state.get(current_weapon_id, {})
	var current_ammo = int(state.get("current_ammo", 0))
	if current_ammo <= 0:
		if int(state.get("reserve_ammo", 0)) > 0:
			reload_current_weapon()
		return

	var projectile_count := int(weapon_data.get("projectile_count", 1))
	var spread_degrees := float(weapon_data.get("spread_degrees", 0.0))
	var bullet_speed := float(weapon_data.get("bullet_speed", 650.0))
	var bullet_damage := int(weapon_data.get("bullet_damage", damage))
	var bullet_life_time := float(weapon_data.get("bullet_life_time", 1.2))

	if projectile_count <= 1:
		_spawn_bullet(direction, bullet_speed, bullet_damage, bullet_life_time)
		_consume_ammo(1)
		return

	var spread_radians = deg_to_rad(spread_degrees)
	var step = spread_radians / float(max(projectile_count - 1, 1))
	var start_angle = -spread_radians * 0.5

	for i in range(projectile_count):
		var angle = start_angle + step * float(i)
		_spawn_bullet(direction.rotated(angle), bullet_speed, bullet_damage, bullet_life_time)

	_consume_ammo(1)

func _spawn_bullet(direction: Vector2, bullet_speed: float, bullet_damage: int, bullet_life_time: float):
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position

	if bullet.has_method("configure"):
		bullet.configure(direction, bullet_speed, bullet_damage, bullet_life_time)
	else:
		bullet.direction = direction

	get_tree().current_scene.add_child(bullet)

func _consume_ammo(amount: int):
	var state = ammo_state.get(current_weapon_id, {})
	if state.is_empty():
		return

	state["current_ammo"] = max(int(state.get("current_ammo", 0)) - amount, 0)
	ammo_state[current_weapon_id] = state
	_emit_ammo_state()

	if int(state.get("current_ammo", 0)) <= 0 and int(state.get("reserve_ammo", 0)) > 0:
		reload_current_weapon()

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
