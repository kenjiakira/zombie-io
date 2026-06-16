extends Node2D

@export var life_time: float = 0.5
@export var normal_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var critical_color: Color = Color(1.0, 0.35, 0.2, 1.0)
@export var normal_font_size: int = 22
@export var critical_font_size: int = 30

@onready var label: Label = $Label

var text: String = "-10"
var critical: bool = false

func setup(p_text: String, p_critical: bool = false):
	text = p_text
	critical = p_critical
	_apply_visual()

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_visual()
	_play_float_animation()

func _apply_visual():
	if label == null:
		return

	label.text = text
	label.add_theme_font_size_override("font_size", critical_font_size if critical else normal_font_size)
	label.add_theme_color_override("font_color", critical_color if critical else normal_color)

func _play_float_animation():
	var tween = create_tween()
	tween.set_parallel(true)
	var target_position = position + Vector2(0, -12)
	tween.tween_property(self, "position", target_position, life_time)
	tween.tween_property(self, "modulate:a", 0.0, life_time)
	await tween.finished
	queue_free()
