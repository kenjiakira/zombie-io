extends Node

@export var damage_number_scene: PackedScene
@export var death_effect_scene: PackedScene
@export var death_burst_scene: PackedScene
@export var hit_flash_scene: PackedScene
@export var rare_drop_scene: PackedScene

var world_container: Node

func setup(p_world_container: Node) -> void:
	world_container = p_world_container

func spawn_damage_number(world_position: Vector2, amount: int, is_critical: bool = false) -> void:
	if damage_number_scene == null or world_container == null:
		return

	var damage_number = damage_number_scene.instantiate()
	damage_number.global_position = world_position + Vector2(0, -18)
	if damage_number.has_method("setup"):
		var damage_text = "-" + str(amount)
		if is_critical:
			damage_text = "CRIT " + damage_text
		damage_number.setup(damage_text, is_critical)

	world_container.add_child(damage_number)

func spawn_hit_flash(world_position: Vector2, boss_flash: bool = false) -> void:
	if hit_flash_scene == null or world_container == null:
		return

	var flash = hit_flash_scene.instantiate()
	flash.global_position = world_position
	if flash.has_method("setup"):
		flash.setup(world_position, boss_flash)

	world_container.add_child(flash)

func spawn_death_effect(world_position: Vector2, boss_effect: bool = false) -> void:
	if death_effect_scene == null or world_container == null:
		return

	var effect = death_effect_scene.instantiate()
	effect.global_position = world_position
	if effect.has_method("setup"):
		effect.setup(world_position, boss_effect)

	world_container.add_child(effect)

func spawn_death_burst(world_position: Vector2, boss_burst: bool = false, custom_color: Color = Color(0, 0, 0, 0)) -> void:
	if death_burst_scene == null or world_container == null:
		return

	var burst = death_burst_scene.instantiate()
	burst.global_position = world_position
	if burst.has_method("setup"):
		burst.setup(world_position, boss_burst, custom_color)

	world_container.add_child(burst)

func spawn_rare_drop(world_position: Vector2) -> Node:
	if rare_drop_scene == null or world_container == null:
		return null

	var drop = rare_drop_scene.instantiate()
	drop.global_position = world_position
	world_container.add_child(drop)
	return drop
