extends Node

@export var zombie_scene: PackedScene
@export var boss_scene: PackedScene

var world_container: Node
var wave_manager: Node
var player: Node

func setup(p_world_container: Node, p_wave_manager: Node, p_player: Node) -> void:
	world_container = p_world_container
	wave_manager = p_wave_manager
	player = p_player

func spawn_zombie_of_type(zombie_type: String, spawn_position: Vector2) -> Node:
	if zombie_scene == null or world_container == null:
		return null

	var zombie = zombie_scene.instantiate()
	zombie.global_position = spawn_position

	if zombie.has_method("configure_zombie"):
		zombie.configure_zombie(zombie_type)

	world_container.add_child(zombie)

	if wave_manager != null and wave_manager.has_method("notify_enemy_spawned"):
		wave_manager.notify_enemy_spawned()

	return zombie

func spawn_boss_of_type(boss_type: String, spawn_position: Vector2) -> Node:
	if boss_scene == null or world_container == null:
		return null

	var boss = boss_scene.instantiate()
	boss.global_position = spawn_position

	if boss.has_method("configure_boss"):
		boss.configure_boss(boss_type)

	world_container.add_child(boss)

	if wave_manager != null and wave_manager.has_method("notify_enemy_spawned"):
		wave_manager.notify_enemy_spawned()

	return boss
