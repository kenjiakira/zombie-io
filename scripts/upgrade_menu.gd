extends Control

signal upgrade_selected(upgrade_id: String)

@onready var button_1: Button = $"Upgrade 1"
@onready var button_2: Button = $"Upgrade 2"
@onready var button_3: Button = $"Upgrade 3"

var current_upgrades: Array = []

func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	
	button_1.pressed.connect(func(): _choose_upgrade(0))
	button_2.pressed.connect(func(): _choose_upgrade(1))
	button_3.pressed.connect(func(): _choose_upgrade(2))

func show_upgrades(upgrades: Array):
	current_upgrades = upgrades
	visible = true
	
	button_1.visible = upgrades.size() > 0
	button_2.visible = upgrades.size() > 1
	button_3.visible = upgrades.size() > 2

	if upgrades.size() > 0:
		_set_button_text(button_1, upgrades[0])
	if upgrades.size() > 1:
		_set_button_text(button_2, upgrades[1])
	if upgrades.size() > 2:
		_set_button_text(button_3, upgrades[2])

func hide_upgrades():
	visible = false

func _set_button_text(button: Button, upgrade: Dictionary):
	button.text = upgrade["name"] + "\n" + upgrade["desc"]

func _choose_upgrade(index: int):
	if index < 0 or index >= current_upgrades.size():
		return
	
	var upgrade = current_upgrades[index]
	upgrade_selected.emit(upgrade["id"])
