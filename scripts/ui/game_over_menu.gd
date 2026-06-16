extends Control

signal restart_pressed

@onready var final_score_label: Label = $FinalScoreLabel
@onready var restart_button: Button = $RestartButton

func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	restart_button.pressed.connect(_on_restart_button_pressed)

func show_game_over(final_score: int, final_level: int):
	visible = true
	final_score_label.text = "Score: " + str(final_score) + " | Level: " + str(final_level)

func hide_game_over():
	visible = false

func _on_restart_button_pressed():
	restart_pressed.emit()
