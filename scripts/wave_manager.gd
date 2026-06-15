extends Node

signal wave_changed(wave: int)
signal time_changed(time_text: String)
signal enemies_changed(alive: int, total: int)
signal spawn_zombie_requested(zombie_type: String)
signal spawn_boss_requested(boss_type: String)

@export var start_wave: int = 1
@export var wave_intermission: float = 2.0

var wave: int = 1
var wave_spawned: int = 0
var wave_alive: int = 0
var wave_transitioning: bool = false
var current_wave_config: Dictionary = {}
var elapsed_time: float = 0.0

var spawn_timer: Timer
var _last_time_text: String = ""

func _ready():
	_setup_spawn_timer()

func start():
	elapsed_time = 0.0
	_start_wave(start_wave)
	_emit_time(true)

func _process(delta):
	elapsed_time += delta
	_emit_time()

func _setup_spawn_timer():
	if spawn_timer != null:
		return

	spawn_timer = Timer.new()
	spawn_timer.one_shot = false
	add_child(spawn_timer)

	if not spawn_timer.timeout.is_connected(_on_spawn_timer_timeout):
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func _on_spawn_timer_timeout():
	if wave_transitioning:
		return

	if wave_spawned >= int(current_wave_config.get("total_zombies", 0)):
		if spawn_timer != null:
			spawn_timer.stop()

		if wave_alive <= 0:
			_queue_next_wave()

		return

	var zombie_type = _pick_zombie_type()
	spawn_zombie_requested.emit(zombie_type)
	wave_spawned += 1

	if wave_spawned >= int(current_wave_config.get("total_zombies", 0)) and spawn_timer != null:
		spawn_timer.stop()

func notify_enemy_spawned():
	wave_alive += 1
	_emit_enemy_count()

func notify_enemy_died():
	wave_alive = max(wave_alive - 1, 0)
	_emit_enemy_count()

	if wave_alive == 0 and wave_spawned >= int(current_wave_config.get("total_zombies", 0)):
		_queue_next_wave()

func get_wave() -> int:
	return wave

func get_alive_count() -> int:
	return wave_alive

func get_total_count() -> int:
	return int(current_wave_config.get("total_zombies", 0))

func get_time_text() -> String:
	return _format_time(elapsed_time)

func get_wave_config() -> Dictionary:
	return current_wave_config

func _start_wave(p_wave: int):
	wave = p_wave
	wave_spawned = 0
	wave_alive = 0
	wave_transitioning = false
	current_wave_config = _get_wave_config(wave)

	if spawn_timer != null:
		spawn_timer.wait_time = float(current_wave_config.get("spawn_interval", 1.0))
		spawn_timer.start()

	_emit_wave()
	_emit_enemy_count()

	var boss_type = String(current_wave_config.get("boss_type", ""))
	if boss_type != "":
		spawn_boss_requested.emit(boss_type)

func _queue_next_wave():
	if wave_transitioning:
		return

	wave_transitioning = true

	if spawn_timer != null:
		spawn_timer.stop()

	await get_tree().create_timer(wave_intermission).timeout

	if not is_inside_tree():
		return

	_start_wave(wave + 1)

func _emit_wave():
	wave_changed.emit(wave)

func _emit_enemy_count():
	enemies_changed.emit(wave_alive, get_total_count())

func _emit_time(force: bool = false):
	var time_text = _format_time(elapsed_time)

	if force or time_text != _last_time_text:
		_last_time_text = time_text
		time_changed.emit(time_text)

func _format_time(seconds: float) -> String:
	var total_seconds = int(seconds)
	var minutes = total_seconds / 60
	var secs = total_seconds % 60
	return str(minutes).pad_zeros(2) + ":" + str(secs).pad_zeros(2)

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
	if p_wave <= 2:
		return {
			"total_zombies": 6 + (p_wave - 1) * 2,
			"spawn_interval": maxf(0.9, 1.15 - (p_wave - 1) * 0.12),
			"weights": {"normal": 100}
		}

	if p_wave <= 4:
		return {
			"total_zombies": 10 + (p_wave - 3) * 2,
			"spawn_interval": maxf(0.75, 0.9 - (p_wave - 3) * 0.08),
			"weights": {"normal": 65, "fast": 35}
		}

	if p_wave == 5:
		return {
			"total_zombies": 14,
			"spawn_interval": 0.72,
			"weights": {"normal": 45, "fast": 35, "tank": 20},
			"boss_type": "mini_boss"
		}

	if p_wave <= 9:
		var tank_weight = 25 + (p_wave - 6) * 10
		var fast_weight = max(15, 35 - (p_wave - 6) * 4)
		var normal_weight = max(10, 40 - (p_wave - 6) * 6)
		return {
			"total_zombies": 16 + (p_wave - 6) * 2,
			"spawn_interval": maxf(0.45, 0.68 - (p_wave - 6) * 0.04),
			"weights": {"normal": normal_weight, "fast": fast_weight, "tank": tank_weight}
		}

	if p_wave == 10:
		return {
			"total_zombies": 24,
			"spawn_interval": 0.5,
			"weights": {"normal": 15, "fast": 25, "tank": 60},
			"boss_type": "boss"
		}

	var extra_wave = p_wave - 10
	return {
		"total_zombies": 24 + extra_wave * 4,
		"spawn_interval": maxf(0.3, 0.5 - extra_wave * 0.03),
		"weights": {
			"normal": max(5, 15 - extra_wave),
			"fast": max(15, 25 - extra_wave),
			"tank": 60 + extra_wave * 2
		}
	}
