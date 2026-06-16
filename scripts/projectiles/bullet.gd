extends Area2D

@export var speed: float = 650.0
@export var damage: int = 25
@export var life_time: float = 1.2
@export var critical_chance: float = 0.1
@export var critical_multiplier: float = 2.0
@export var damage_number_scene: PackedScene

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
	if body == null:
		return

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

	if body != null:
		body.rotation = move_dir.angle()
		var pulse = 1.0 + sin(anim_time * 20.0) * 0.15
		body.scale = Vector2.ONE * pulse

func _on_body_entered(body_hit):
	if not body_hit.is_in_group("zombie"):
		return

	var is_critical = randf() <= critical_chance
	var dealt_damage = damage
	if is_critical:
		dealt_damage = int(round(float(damage) * critical_multiplier))

	if body_hit.has_method("take_damage"):
		body_hit.take_damage(dealt_damage, direction)

	_spawn_damage_number(body_hit.global_position, dealt_damage, is_critical)
	queue_free()

func _spawn_damage_number(world_position: Vector2, amount: int, is_critical: bool):
	var main = get_tree().current_scene
	if main != null and main.has_method("spawn_damage_number"):
		main.spawn_damage_number(world_position, amount, is_critical)
		return

	if damage_number_scene == null:
		return

	var damage_number = damage_number_scene.instantiate()
	damage_number.global_position = world_position
	if damage_number.has_method("setup"):
		var damage_text = "-" + str(amount)
		if is_critical:
			damage_text = "CRIT " + damage_text
		damage_number.setup(damage_text, is_critical)
	get_tree().current_scene.add_child(damage_number)
