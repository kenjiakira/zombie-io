extends Area2D

const WeaponDatabase = preload("res://scripts/data/weapon_database.gd")

@export var rare_weapon_id: String = "sniper"

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
	if body != null:
		rotation += 0.04
		body.scale = Vector2.ONE * (1.0 + sin(bob_time * 8.0) * 0.1)

func _setup_visual():
	if body == null:
		return

	body.polygon = PackedVector2Array([
		Vector2(0, -16),
		Vector2(14, 0),
		Vector2(0, 16),
		Vector2(-14, 0)
	])
	body.color = WeaponDatabase.get_weapon_color(rare_weapon_id)

func _on_body_entered(body_hit):
	if body_hit.is_in_group("player"):
		collect()

func collect():
	if player != null and is_instance_valid(player) and player.has_method("pickup_weapon"):
		player.pickup_weapon(rare_weapon_id)
	queue_free()
