extends Node2D

@onready var body: Polygon2D = $Body

var is_boss_effect: bool = false
var pending_position: Vector2 = Vector2.ZERO
var has_pending_position: bool = false

func setup(world_position: Vector2, boss_effect: bool = false):
	pending_position = world_position
	has_pending_position = true
	is_boss_effect = boss_effect
	if is_inside_tree():
		global_position = world_position

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	if has_pending_position:
		global_position = pending_position

	if body == null:
		return

	body.polygon = PackedVector2Array([
		Vector2(0, -16),
		Vector2(14, 0),
		Vector2(0, 16),
		Vector2(-14, 0)
	])
	if is_boss_effect:
		body.color = Color(1.0, 0.45, 0.2, 0.85)
	else:
		body.color = Color(0.7, 1.0, 0.7, 0.8)

	var target_scale = Vector2(3.0, 3.0) if is_boss_effect else Vector2(2.2, 2.2)
	var duration = 0.26 if is_boss_effect else 0.18
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(body, "scale", target_scale, duration)
	tween.tween_property(body, "modulate:a", 0.0, duration)

	await tween.finished
	queue_free()
