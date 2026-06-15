extends Node2D

@export var zombie_scene: PackedScene
@export var boss_scene: PackedScene

@onready var player = $Player
@onready var zombie_container = $ZombieContainer
@onready var spawn_timer: Timer = $SpawnTimer
@onready var game_over_menu = $CanvasLayer/GameOverPanel
@onready var upgrade_menu = $UpgradeMenu

@onready var hp_bar: ProgressBar = $CanvasLayer/HPBar
@onready var hp_text: Label = $CanvasLayer/HPText
@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var level_label: Label = $CanvasLayer/LevelLabel

var score: int = 0
var exp: int = 0
var level: int = 1
var exp_to_next_level: int = 5
var wave: int = 1
var wave_spawned: int = 0
var wave_alive: int = 0
var wave_transitioning: bool = false
var pending_upgrades: Array = []
var current_wave_config: Dictionary = {}

const WAVE_INTERMISSION: float = 2.0

const UPGRADE_POOL = [
	{
		"id": "bullet_damage",
		"name": "Bullet Damage",
		"desc": "Increase bullet damage."
	},
	{
		"id": "bullet_speed",
		"name": "Bullet Speed",
		"desc": "Increase bullet speed."
	},
	{
		"id": "shoot_rate",
		"name": "Rapid Fire",
		"desc": "Shoot faster."
	},
	{
		"id": "player_speed",
		"name": "Move Speed",
		"desc": "Increase movement speed."
	},
	{
		"id": "max_hp",
		"name": "Max HP",
		"desc": "Increase max HP."
	}
]

func _ready():
	randomize()

	if player != null:
		player.hp_changed.connect(_on_player_hp_changed)
		player.died.connect(_on_player_died)

	if upgrade_menu != null:
		upgrade_menu.upgrade_selected.connect(_on_upgrade_selected)

	if game_over_menu != null:
		game_over_menu.restart_pressed.connect(_on_restart_pressed)

	if spawn_timer != null:
		if not spawn_timer.timeout.is_connected(_on_spawn_timer_timeout):
			spawn_timer.timeout.connect(_on_spawn_timer_timeout)

		spawn_timer.one_shot = false

	_start_wave(1)
	update_ui()

func _on_spawn_timer_timeout():
	if wave_transitioning:
		return

	if wave_spawned >= int(current_wave_config.get("total_zombies", 0)):
		if spawn_timer != null:
			spawn_timer.stop()

		if wave_alive <= 0:
			_queue_next_wave()

		return

	spawn_zombie()

func spawn_zombie():
	if zombie_scene == null:
		print("LỖI: Chưa gán Zombie Scene trong Inspector của Main")
		return

	if player == null:
		print("LỖI: Không tìm thấy Player")
		return

	var zombie = zombie_scene.instantiate()

	var spawn_distance = 520
	var random_angle = randf() * TAU
	var spawn_direction = Vector2(cos(random_angle), sin(random_angle))
	var spawn_position = player.global_position + spawn_direction * spawn_distance
	var zombie_type = _pick_zombie_type()

	zombie.global_position = spawn_position
	if zombie.has_method("configure_zombie"):
		zombie.configure_zombie(zombie_type)

	zombie_container.add_child(zombie)
	wave_spawned += 1
	wave_alive += 1

	if wave_spawned >= int(current_wave_config.get("total_zombies", 0)) and spawn_timer != null:
		spawn_timer.stop()

func spawn_zombie_of_type(zombie_type: String, spawn_position: Vector2):
	if zombie_scene == null:
		return

	var zombie = zombie_scene.instantiate()
	zombie.global_position = spawn_position

	if zombie.has_method("configure_zombie"):
		zombie.configure_zombie(zombie_type)

	zombie_container.add_child(zombie)
	wave_alive += 1

func _pick_zombie_type() -> String:
	var weights: Dictionary = current_wave_config.get("weights", {})
	return _pick_weighted_zombie_type(weights)

func _pick_weighted_zombie_type(weights: Dictionary) -> String:
	if weights.is_empty():
		return "normal"

	var total_weight := 0
	for value in weights.values():
		total_weight += int(value)

	if total_weight <= 0:
		return "normal"

	var roll := randi() % total_weight
	var cumulative := 0

	for type_id in weights.keys():
		cumulative += int(weights[type_id])
		if roll < cumulative:
			return String(type_id)

	return "normal"

func _get_wave_config(p_wave: int) -> Dictionary:
	match p_wave:
		1:
			return {
				"total_zombies": 6,
				"spawn_interval": 1.15,
				"weights": {"normal": 100}
			}
		2:
			return {
				"total_zombies": 8,
				"spawn_interval": 1.0,
				"weights": {"normal": 70, "fast": 30}
			}
		3:
			return {
				"total_zombies": 10,
				"spawn_interval": 0.9,
				"weights": {"normal": 60, "fast": 40}
			}
		4:
			return {
				"total_zombies": 12,
				"spawn_interval": 0.82,
				"weights": {"normal": 45, "fast": 35, "tank": 20}
			}
		5:
			return {
				"total_zombies": 14,
				"spawn_interval": 0.76,
				"weights": {"normal": 50, "fast": 30, "tank": 20},
				"boss_type": "mini_boss"
			}
		6:
			return {
				"total_zombies": 16,
				"spawn_interval": 0.7,
				"weights": {"normal": 35, "fast": 35, "tank": 30}
			}
		7:
			return {
				"total_zombies": 18,
				"spawn_interval": 0.66,
				"weights": {"normal": 30, "fast": 35, "tank": 35}
			}
		8:
			return {
				"total_zombies": 20,
				"spawn_interval": 0.62,
				"weights": {"normal": 25, "fast": 35, "tank": 40}
			}
		9:
			return {
				"total_zombies": 22,
				"spawn_interval": 0.58,
				"weights": {"normal": 20, "fast": 35, "tank": 45}
			}
		10:
			return {
				"total_zombies": 24,
				"spawn_interval": 0.54,
				"weights": {"normal": 20, "fast": 30, "tank": 50},
				"boss_type": "boss"
			}
		_:
			var extra_wave = p_wave - 10
			return {
				"total_zombies": 24 + extra_wave * 4,
				"spawn_interval": maxf(0.35, 0.54 - extra_wave * 0.03),
				"weights": {"normal": 15, "fast": 30, "tank": 55}
			}

func _start_wave(p_wave: int):
	wave = p_wave
	wave_spawned = 0
	wave_alive = 0
	wave_transitioning = false
	current_wave_config = _get_wave_config(wave)

	if spawn_timer != null:
		spawn_timer.wait_time = float(current_wave_config.get("spawn_interval", 1.0))
		spawn_timer.start()

	_spawn_wave_boss()
	update_ui()

func _spawn_wave_boss():
	var boss_type = String(current_wave_config.get("boss_type", ""))

	if boss_type == "" or boss_scene == null or player == null:
		return

	var boss = boss_scene.instantiate()
	var spawn_distance = 420
	var spawn_angle = randf() * TAU
	var spawn_direction = Vector2(cos(spawn_angle), sin(spawn_angle))
	var spawn_position = player.global_position + spawn_direction * spawn_distance

	boss.global_position = spawn_position

	if boss.has_method("configure_boss"):
		boss.configure_boss(boss_type)

	zombie_container.add_child(boss)
	wave_alive += 1

func _queue_next_wave():
	if wave_transitioning:
		return

	wave_transitioning = true
	if spawn_timer != null:
		spawn_timer.stop()

	await get_tree().create_timer(WAVE_INTERMISSION).timeout

	if not is_inside_tree() or player == null:
		return

	_start_wave(wave + 1)

func notify_zombie_died():
	wave_alive = max(wave_alive - 1, 0)

	if wave_alive == 0 and wave_spawned >= int(current_wave_config.get("total_zombies", 0)):
		_queue_next_wave()

func add_score(amount: int):
	score += amount
	update_ui()

func add_exp(amount: int):
	exp += amount

	if exp >= exp_to_next_level:
		level_up()

	update_ui()

func level_up():
	exp -= exp_to_next_level
	level += 1
	exp_to_next_level += 4
	update_ui()
	_show_upgrade_choices()

func _show_upgrade_choices():
	if upgrade_menu == null:
		_apply_upgrade("player_speed")
		update_ui()
		return

	pending_upgrades = _pick_upgrades(3)
	upgrade_menu.show_upgrades(pending_upgrades)
	get_tree().paused = true

func _pick_upgrades(count: int) -> Array:
	var available = UPGRADE_POOL.duplicate(true)
	var choices: Array = []

	while choices.size() < count and not available.is_empty():
		var index = randi() % available.size()
		choices.append(available[index])
		available.remove_at(index)

	return choices

func _on_upgrade_selected(upgrade_id: String):
	_apply_upgrade(upgrade_id)

	if upgrade_menu != null:
		upgrade_menu.hide_upgrades()

	pending_upgrades.clear()
	get_tree().paused = false
	update_ui()

func _apply_upgrade(upgrade_id: String):
	if player == null:
		return

	match upgrade_id:
		"bullet_damage":
			player.damage += 10
		"bullet_speed":
			player.bullet_speed += 120.0
		"shoot_rate":
			player.shoot_rate = maxf(0.12, player.shoot_rate - 0.05)
			player.shoot_timer.wait_time = player.shoot_rate
		"player_speed":
			player.speed += 12
		"max_hp":
			player.max_hp += 20
			player.hp = min(player.hp + 20, player.max_hp)
		_:
			return

func _on_player_died():
	if spawn_timer != null:
		spawn_timer.stop()

	if upgrade_menu != null:
		upgrade_menu.hide_upgrades()

	if game_over_menu != null:
		game_over_menu.show_game_over(score, level)

	get_tree().paused = true

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_player_hp_changed(current_hp, max_hp):
	update_ui()

func update_ui():
	if player == null:
		return

	hp_bar.max_value = player.max_hp
	hp_bar.value = player.hp

	hp_text.text = "HP: " + str(player.hp) + "/" + str(player.max_hp)
	score_label.text = "Score: " + str(score)
	level_label.text = "Wave: " + str(wave) + "  Lv: " + str(level) + "  EXP: " + str(exp) + "/" + str(exp_to_next_level)
