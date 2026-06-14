extends Node2D

@onready var body: Polygon2D = $Body

func _ready():
	body.polygon = PackedVector2Array([
		Vector2(0, -16),
		Vector2(14, 0),
		Vector2(0, 16),
		Vector2(-14, 0)
	])

	body.color = Color(0.7, 1.0, 0.7, 0.8)

	var tween = create_tween()
	tween.parallel().tween_property(body, "scale", Vector2(2.2, 2.2), 0.18)
	tween.parallel().tween_property(body, "modulate:a", 0.0, 0.18)

	await tween.finished
	queue_free()
