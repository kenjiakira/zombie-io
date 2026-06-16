extends Resource

const UPGRADES := [
	{
		"id": "bullet_damage",
		"name": "Bullet Damage",
		"desc": "Increase bullet damage."
	},
	{
		"id": "bullet_speed",
		"name": "Bullet Speed",
		"desc": "Increase bullet speed."
	},
	{
		"id": "shoot_rate",
		"name": "Rapid Fire",
		"desc": "Shoot faster."
	},
	{
		"id": "player_speed",
		"name": "Move Speed",
		"desc": "Increase movement speed."
	},
	{
		"id": "max_hp",
		"name": "Max HP",
		"desc": "Increase max HP."
	}
]

static func get_upgrades() -> Array:
	return UPGRADES.duplicate(true)
