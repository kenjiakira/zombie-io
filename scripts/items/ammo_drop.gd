extends Area2D

@export var ammo_amount: int = 12
@export var attract_distance: float = 130.0
@export var collect_distance: float = 20.0
@export var move_speed: float = 220.0

var player: Node2D
var bob_time: float = 0.0

@onready var body: Polygon2D = $Body

func _ready():
	body_entered.connect(_on_body_entered)

	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player = players[0]

	_setup_visual()

func _physics_process(delta):
	bob_time += delta
	play_float_animation()

	if player == null or not is_instance_valid(player):
		return

	var distance = global_position.distance_to(player.global_position)
	if distance <= attract_distance:
		var direction = (player.global_position - global_position).normalized()
		global_position += direction * move_speed * delta

	if distance <= collect_distance:
		collect()

func _setup_visual():
	if body == null:
		return

	body.polygon = PackedVector2Array([
		Vector2(-10, -8),
		Vector2(10, -8),
		Vector2(14, 0),
		Vector2(10, 8),
		Vector2(-10, 8),
		Vector2(-14, 0)
	])
	body.color = Color(0.35, 0.85, 1.0)

func play_float_animation():
	rotation += 0.025
	if body != null:
		var pulse = 1.0 + sin(bob_time * 7.0) * 0.08
		body.scale = Vector2.ONE * pulse

func _on_body_entered(body_hit):
	if body_hit.is_in_group("player"):
		collect()

func collect():
	var main = get_tree().current_scene
	if main != null and main.has_method("add_player_ammo"):
		main.add_player_ammo(ammo_amount)
	queue_free()
