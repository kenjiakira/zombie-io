extends Node2D

@export var life_time: float = 0.08
@export var flash_color: Color = Color(1.0, 1.0, 1.0, 0.75)
@export var flash_scale: float = 1.2

@onready var body: Polygon2D = $Body

var _world_position: Vector2 = Vector2.ZERO
var _has_position: bool = false
var _boss_flash: bool = false

func setup(world_position: Vector2, boss_flash: bool = false):
	_world_position = world_position
	_has_position = true
	_boss_flash = boss_flash
	if is_inside_tree():
		global_position = world_position

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	if _has_position:
		global_position = _world_position

	if body != null:
		body.polygon = PackedVector2Array([
			Vector2(0, -12),
			Vector2(10, 0),
			Vector2(0, 12),
			Vector2(-10, 0)
		])

		if _boss_flash:
			body.color = Color(1.0, 0.65, 0.2, 0.8)
			body.scale = Vector2.ONE * 1.45
		else:
			body.color = flash_color
			body.scale = Vector2.ONE * flash_scale

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(body, "scale", body.scale * 1.1, life_time)
	tween.tween_property(body, "modulate:a", 0.0, life_time)

	await tween.finished
	queue_free()
