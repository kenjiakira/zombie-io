extends Node2D

@export var zombie_scene: PackedScene
@export var boss_scene: PackedScene

@onready var player = $Player
@onready var wave_manager = $WaveManager
@onready var spawn_manager = $SpawnManager
@onready var vfx_manager = $VFXManager
@onready var upgrade_manager = $UpgradeManager
@onready var zombie_container = $ZombieContainer
@onready var game_over_menu = $CanvasLayer/GameOverMenu
@onready var upgrade_menu = $CanvasLayer/UpgradeMenu

@onready var hp_bar: ProgressBar = $CanvasLayer/HUD/HPBar
@onready var hp_text: Label = $CanvasLayer/HUD/HPText
@onready var weapon_text: Label = $CanvasLayer/HUD/WeaponLabel
@onready var wave_text: Label = $CanvasLayer/HUD/WaveLabel
@onready var time_text: Label = $CanvasLayer/HUD/TimeLabel
@onready var enemies_text: Label = $CanvasLayer/HUD/EnemiesLabel
@onready var score_label: Label = $CanvasLayer/HUD/ScoreLabel
@onready var level_label: Label = $CanvasLayer/HUD/LevelLabel
@onready var camera: Camera2D = $Player/Camera2D

var score: int = 0
var exp: int = 0
var level: int = 1
var exp_to_next_level: int = 8
var upgrade_points: int = 0
var camera_shake_time: float = 0.0
var camera_shake_duration: float = 0.0
var camera_shake_strength: float = 0.0

func _ready():
	randomize()

	if spawn_manager != null:
		spawn_manager.zombie_scene = zombie_scene
		spawn_manager.boss_scene = boss_scene
		spawn_manager.setup(zombie_container, wave_manager, player)

	if vfx_manager != null:
		vfx_manager.setup(zombie_container)

	if player != null:
		player.hp_changed.connect(_on_player_hp_changed)
		player.died.connect(_on_player_died)
		if player.has_signal("weapon_changed"):
			player.weapon_changed.connect(_on_player_weapon_changed)

	if wave_manager != null:
		wave_manager.wave_changed.connect(_on_wave_changed)
		wave_manager.time_changed.connect(_on_wave_time_changed)
		wave_manager.enemies_changed.connect(_on_wave_enemies_changed)
		wave_manager.spawn_zombie_requested.connect(_on_wave_spawn_zombie_requested)
		wave_manager.spawn_boss_requested.connect(_on_wave_spawn_boss_requested)
		wave_manager.start()

	if upgrade_menu != null:
		upgrade_menu.upgrade_selected.connect(_on_upgrade_selected)
		upgrade_menu.set_upgrade_points(upgrade_points)

	if game_over_menu != null:
		game_over_menu.restart_pressed.connect(_on_restart_pressed)

	update_ui()

func _process(delta):
	if camera_shake_time <= 0.0:
		if camera != null:
			camera.offset = Vector2.ZERO
		return

	camera_shake_time = max(camera_shake_time - delta, 0.0)

	if camera != null:
		var intensity: float = camera_shake_strength * (camera_shake_time / max(camera_shake_duration, 0.001))
		camera.offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))

		if camera_shake_time <= 0.0:
			camera.offset = Vector2.ZERO

func _on_wave_changed(_wave: int):
	update_ui()

func _on_wave_time_changed(_time_text: String):
	if time_text != null:
		time_text.text = "Time: " + _time_text

func _on_wave_enemies_changed(alive: int, _total: int):
	if enemies_text != null:
		enemies_text.text = "Enemies: " + str(alive)

func _on_wave_spawn_zombie_requested(zombie_type: String):
	spawn_zombie_of_type(zombie_type)

func _on_wave_spawn_boss_requested(boss_type: String):
	spawn_boss_of_type(boss_type)

func _get_spawn_position(spawn_distance: float) -> Vector2:
	if player == null:
		return Vector2.ZERO

	var random_angle = randf() * TAU
	var spawn_direction = Vector2(cos(random_angle), sin(random_angle))
	return player.global_position + spawn_direction * spawn_distance

func spawn_zombie_of_type(zombie_type: String, spawn_position: Vector2 = Vector2.INF):
	if player == null:
		return

	if spawn_position == Vector2.INF:
		spawn_position = _get_spawn_position(520.0)

	if spawn_manager != null:
		spawn_manager.spawn_zombie_of_type(zombie_type, spawn_position)

func spawn_boss_of_type(boss_type: String):
	if player == null:
		return

	if spawn_manager != null:
		spawn_manager.spawn_boss_of_type(boss_type, _get_spawn_position(420.0))

func notify_zombie_died():
	if wave_manager != null and wave_manager.has_method("notify_enemy_died"):
		wave_manager.notify_enemy_died()

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
	exp_to_next_level += 6
	upgrade_points += 1

	if upgrade_menu != null:
		upgrade_menu.set_upgrade_points(upgrade_points)

	update_ui()

func _on_upgrade_selected(upgrade_id: String):
	if upgrade_points <= 0:
		return

	_apply_upgrade(upgrade_id)
	upgrade_points = max(upgrade_points - 1, 0)

	if upgrade_menu != null:
		upgrade_menu.set_upgrade_points(upgrade_points)

	update_ui()

func _apply_upgrade(upgrade_id: String):
	if upgrade_manager == null:
		return

	upgrade_manager.apply_upgrade(player, upgrade_id)

func spawn_damage_number(world_position: Vector2, amount: int, is_critical: bool = false):
	if vfx_manager != null:
		vfx_manager.spawn_damage_number(world_position, amount, is_critical)

func spawn_hit_flash(world_position: Vector2, boss_flash: bool = false):
	if vfx_manager != null:
		vfx_manager.spawn_hit_flash(world_position, boss_flash)

func spawn_death_effect(world_position: Vector2, boss_effect: bool = false):
	if vfx_manager != null:
		vfx_manager.spawn_death_effect(world_position, boss_effect)

func spawn_death_burst(world_position: Vector2, boss_burst: bool = false, custom_color: Color = Color(0, 0, 0, 0)):
	if vfx_manager != null:
		vfx_manager.spawn_death_burst(world_position, boss_burst, custom_color)

func spawn_rare_drop(world_position: Vector2):
	if vfx_manager != null:
		vfx_manager.spawn_rare_drop(world_position)

func _on_player_died():
	if game_over_menu != null:
		game_over_menu.show_game_over(score, level)

	get_tree().paused = true

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func shake_camera(strength: float = 8.0, duration: float = 0.15):
	camera_shake_strength = max(strength, 0.0)
	camera_shake_duration = max(duration, 0.01)
	camera_shake_time = camera_shake_duration

func _on_player_hp_changed(_current_hp, _max_hp):
	update_ui()

func _on_player_weapon_changed(_weapon_id, _weapon_name):
	update_ui()

func update_ui():
	if player == null:
		return

	hp_bar.max_value = player.max_hp
	hp_bar.value = player.hp

	hp_text.text = "HP: " + str(player.hp) + "/" + str(player.max_hp)

	if player.has_method("get_current_weapon_name"):
		weapon_text.text = "Weapon: " + player.get_current_weapon_name()

	if wave_manager != null:
		if wave_text != null:
			wave_text.text = "Wave: " + str(wave_manager.get_wave())
		if time_text != null:
			time_text.text = "Time: " + wave_manager.get_time_text()
		if enemies_text != null:
			enemies_text.text = "Enemies: " + str(wave_manager.get_alive_count())

	score_label.text = "Score: " + str(score)
	level_label.text = "Lv: " + str(level) + "  EXP: " + str(exp) + "/" + str(exp_to_next_level)
