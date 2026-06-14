extends Node2D

@export var zombie_scene: PackedScene

@onready var player = $Player
@onready var zombie_container = $ZombieContainer
@onready var spawn_timer: Timer = $SpawnTimer

@onready var hp_bar: ProgressBar = $CanvasLayer/HPBar
@onready var hp_text: Label = $CanvasLayer/HPText
@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var level_label: Label = $CanvasLayer/LevelLabel

var score: int = 0
var exp: int = 0
var level: int = 1
var exp_to_next_level: int = 5

func _ready():
	randomize()

	if player != null:
		player.hp_changed.connect(_on_player_hp_changed)

	if spawn_timer != null:
		if not spawn_timer.timeout.is_connected(_on_spawn_timer_timeout):
			spawn_timer.timeout.connect(_on_spawn_timer_timeout)

		spawn_timer.wait_time = 1.2
		spawn_timer.one_shot = false
		spawn_timer.start()

	update_ui()

func _on_spawn_timer_timeout():
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

	zombie.global_position = spawn_position

	zombie_container.add_child(zombie)

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

	if player != null:
		player.speed += 12

	update_ui()

func _on_player_hp_changed(current_hp, max_hp):
	update_ui()

func update_ui():
	if player == null:
		return

	hp_bar.max_value = player.max_hp
	hp_bar.value = player.hp

	hp_text.text = "HP: " + str(player.hp) + "/" + str(player.max_hp)
	score_label.text = "Score: " + str(score)
	level_label.text = "Level: " + str(level) + "  EXP: " + str(exp) + "/" + str(exp_to_next_level)
