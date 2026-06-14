extends Area2D

@export var exp_amount: int = 1
@export var move_speed: float = 220.0

@onready var body: Polygon2D = $Body

var player = null
var anim_time: float = 0.0

func _ready():
	body_entered.connect(_on_body_entered)
	setup_placeholder_visual()

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func setup_placeholder_visual():
	body.polygon = PackedVector2Array([
		Vector2(0, -10),
		Vector2(8, 0),
		Vector2(0, 10),
		Vector2(-8, 0)
	])

	body.color = Color(0.5, 0.4, 1.0)

func _physics_process(delta):
	anim_time += delta

	body.position.y = sin(anim_time * 5.0) * 3.0
	body.rotation += delta * 2.0

	if player == null:
		return

	var distance = global_position.distance_to(player.global_position)

	if distance < 140:
		var dir = (player.global_position - global_position).normalized()
		global_position += dir * move_speed * delta

func _on_body_entered(body_hit):
	if body_hit.is_in_group("player"):
		var main = get_tree().current_scene

		if main.has_method("add_exp"):
			main.add_exp(exp_amount)

		queue_free()
