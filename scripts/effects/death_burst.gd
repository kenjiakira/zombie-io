extends Node2D

@export var particle_count: int = 10
@export var spread_radius: float = 10.0
@export var travel_distance: float = 26.0
@export var life_time: float = 0.22
@export var is_boss_burst: bool = false

var _custom_color: Color = Color(0, 0, 0, 0)
var _world_position: Vector2 = Vector2.ZERO
var _has_position: bool = false

func setup(world_position: Vector2, boss_burst: bool = false, custom_color: Color = Color(0, 0, 0, 0)):
	_world_position = world_position
	_has_position = true
	is_boss_burst = boss_burst
	_custom_color = custom_color
	if is_inside_tree():
		global_position = world_position

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	if _has_position:
		global_position = _world_position

	var base_color = _get_burst_color()
	var count = particle_count * (2 if is_boss_burst else 1)

	for i in range(count):
		var particle = Polygon2D.new()
		particle.polygon = PackedVector2Array([
			Vector2(0, -4),
			Vector2(4, 0),
			Vector2(0, 4),
			Vector2(-4, 0)
		])
		particle.color = base_color
		particle.position = Vector2.ZERO
		particle.scale = Vector2.ONE * (1.3 if is_boss_burst else 1.0)
		add_child(particle)

		var angle = randf() * TAU
		var radius = randf_range(0.0, spread_radius)
		particle.position = Vector2(cos(angle), sin(angle)) * radius

		var target = particle.position + Vector2(cos(angle), sin(angle)) * travel_distance * randf_range(0.8, 1.2)
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position", target, life_time)
		tween.tween_property(particle, "modulate:a", 0.0, life_time)

	var fade = create_tween()
	fade.tween_interval(life_time)
	fade.tween_callback(queue_free)

func _get_burst_color() -> Color:
	if _custom_color.a > 0.0:
		return _custom_color

	if is_boss_burst:
		return Color(1.0, 0.6, 0.2, 1.0)

	return Color(0.45, 1.0, 0.45, 1.0)
