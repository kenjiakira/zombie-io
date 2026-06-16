extends Area2D

const WEAPON_COLORS := {
	"pistol": Color(0.65, 0.75, 0.9),
	"shotgun": Color(0.95, 0.62, 0.28),
	"smg": Color(0.35, 0.9, 0.45),
	"rifle": Color(0.4, 0.7, 1.0)
}

@export var weapon_id: String = "pistol"

@onready var body: Polygon2D = $Body

var player: Node2D
var bob_time: float = 0.0

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

func _setup_visual():
	if body == null:
		return

	var color = WEAPON_COLORS.get(weapon_id, WEAPON_COLORS["pistol"])
	body.color = color
	body.polygon = PackedVector2Array([
		Vector2(0, -14),
		Vector2(12, 0),
		Vector2(0, 14),
		Vector2(-12, 0)
	])

func play_float_animation():
	rotation += 0.035
	if body != null:
		var pulse = 1.0 + sin(bob_time * 7.0) * 0.08
		body.scale = Vector2.ONE * pulse

func _on_body_entered(body_hit):
	if body_hit.is_in_group("player"):
		collect()

func collect():
	if player != null and is_instance_valid(player) and player.has_method("pickup_weapon"):
		player.pickup_weapon(weapon_id)
	else:
		var main = get_tree().current_scene
		if main != null and main.has_node("Player"):
			var player_node = main.get_node("Player")
			if player_node != null and player_node.has_method("pickup_weapon"):
				player_node.pickup_weapon(weapon_id)

	queue_free()
