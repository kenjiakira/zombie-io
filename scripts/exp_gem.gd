extends Area2D

@export var exp_value: int = 10
@export var attract_distance: float = 130.0
@export var collect_distance: float = 20.0
@export var move_speed: float = 220.0

var player: Node2D

func _ready():
	body_entered.connect(_on_body_entered)

	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player = players[0]

func _physics_process(delta):
	play_float_animation()

	if player == null or not is_instance_valid(player):
		return

	var distance = global_position.distance_to(player.global_position)

	if distance <= attract_distance:
		var direction = (player.global_position - global_position).normalized()
		global_position += direction * move_speed * delta

	if distance <= collect_distance:
		collect()

func play_float_animation():
	rotation += 0.03

func _on_body_entered(body):
	if body.is_in_group("player"):
		collect()

func collect():
	var main = get_tree().current_scene

	if main != null and main.has_method("add_exp"):
		main.add_exp(exp_value)

	queue_free()
