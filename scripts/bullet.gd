extends Area2D

@export var speed: float = 650.0
@export var damage: int = 25
@export var life_time: float = 1.2

@onready var body: Polygon2D = $Body

var direction: Vector2 = Vector2.RIGHT
var anim_time: float = 0.0

func configure(p_direction: Vector2, p_speed: float = -1.0, p_damage: int = -1, p_life_time: float = -1.0):
	direction = p_direction

	if p_speed >= 0.0:
		speed = p_speed

	if p_damage >= 0:
		damage = p_damage

	if p_life_time >= 0.0:
		life_time = p_life_time

func _ready():
	body_entered.connect(_on_body_entered)
	setup_placeholder_visual()

	await get_tree().create_timer(life_time).timeout
	queue_free()

func setup_placeholder_visual():
	body.polygon = PackedVector2Array([
		Vector2(10, 0),
		Vector2(0, -5),
		Vector2(-10, 0),
		Vector2(0, 5)
	])

	body.color = Color(1.0, 0.9, 0.25)
	body.rotation = direction.angle()

func _physics_process(delta):
	anim_time += delta

	var move_dir = direction.normalized()
	global_position += move_dir * speed * delta
	body.rotation = move_dir.angle()

	var pulse = 1.0 + sin(anim_time * 20.0) * 0.15
	body.scale = Vector2(pulse, pulse)

func _on_body_entered(body_hit):
	if body_hit.is_in_group("zombie"):
		if body_hit.has_method("take_damage"):
			body_hit.take_damage(damage, direction)
		else:
			body_hit.take_damage(damage)
		queue_free()
