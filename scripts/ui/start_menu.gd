extends Control

signal start_pressed

@onready var start_button: Button = $StartButton

func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = true
	start_button.pressed.connect(_on_start_button_pressed)

func show_start_menu():
	visible = true

func hide_start_menu():
	visible = false

func _on_start_button_pressed():
	start_pressed.emit()
