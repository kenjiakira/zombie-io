extends Control

signal upgrade_selected(upgrade_id: String)

@onready var button_1: Button = $"Upgrade 1"
@onready var button_2: Button = $"Upgrade 2"
@onready var button_3: Button = $"Upgrade 3"
@onready var button_4: Button = $"Upgrade 4"
@onready var button_5: Button = $"Upgrade 5"
@onready var title_label: Label = $TitleLabel
@onready var points_label: Label = $PointsLabel

var upgrade_entries: Array = []
var upgrade_points: int = 0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true

	upgrade_entries = [
		{"id": "bullet_damage", "name": "Bullet Damage", "desc": "Increase bullet damage."},
		{"id": "bullet_speed", "name": "Bullet Speed", "desc": "Increase bullet speed."},
		{"id": "shoot_rate", "name": "Rapid Fire", "desc": "Shoot faster."},
		{"id": "player_speed", "name": "Move Speed", "desc": "Increase movement speed."},
		{"id": "max_hp", "name": "Max HP", "desc": "Increase max HP."}
	]

	button_1.pressed.connect(func(): _choose_upgrade(0))
	button_2.pressed.connect(func(): _choose_upgrade(1))
	button_3.pressed.connect(func(): _choose_upgrade(2))
	button_4.pressed.connect(func(): _choose_upgrade(3))
	button_5.pressed.connect(func(): _choose_upgrade(4))
	_refresh_ui()

func set_upgrade_points(points: int):
	upgrade_points = max(points, 0)
	_refresh_ui()

func add_upgrade_point(amount: int = 1):
	set_upgrade_points(upgrade_points + amount)

func _refresh_ui():
	points_label.text = "Upgrade Points: " + str(upgrade_points)

	button_1.disabled = upgrade_points <= 0
	button_2.disabled = upgrade_points <= 0
	button_3.disabled = upgrade_points <= 0
	button_4.disabled = upgrade_points <= 0
	button_5.disabled = upgrade_points <= 0

	_set_button_text(button_1, upgrade_entries[0])
	_set_button_text(button_2, upgrade_entries[1])
	_set_button_text(button_3, upgrade_entries[2])
	_set_button_text(button_4, upgrade_entries[3])
	_set_button_text(button_5, upgrade_entries[4])

	button_1.visible = true
	button_2.visible = true
	button_3.visible = true
	button_4.visible = true
	button_5.visible = true

func _set_button_text(button: Button, upgrade: Dictionary):
	button.text = upgrade["name"] + "\n" + upgrade["desc"]

func _choose_upgrade(index: int):
	if index < 0 or index >= upgrade_entries.size():
		return

	if upgrade_points <= 0:
		return

	var upgrade = upgrade_entries[index]
	upgrade_selected.emit(upgrade["id"])
