extends Area2D

@export var speed: float = 650.0
@export var damage: int = 25
@export var life_time: float = 1.2

@onready var body: Polygon2D = $Body

var direction: Vector2 = Vector2.RIGHT
var anim_time: float = 0.0

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

	global_position += direction * speed * delta
	body.rotation = direction.angle()

	var pulse = 1.0 + sin(anim_time * 20.0) * 0.15
	body.scale = Vector2(pulse, pulse)

func _on_body_entered(body_hit):
	if body_hit.is_in_group("zombie"):
		body_hit.take_damage(damage)
		queue_free()
