extends Resource

const WEAPONS := {
	"pistol": {
		"name": "Pistol",
		"shoot_rate": 0.45,
		"bullet_speed": 650.0,
		"bullet_damage": 25,
		"bullet_life_time": 1.2,
		"projectile_count": 1,
		"spread_degrees": 0.0
	},
	"shotgun": {
		"name": "Shotgun",
		"shoot_rate": 0.95,
		"bullet_speed": 560.0,
		"bullet_damage": 16,
		"bullet_life_time": 0.95,
		"projectile_count": 5,
		"spread_degrees": 18.0
	},
	"smg": {
		"name": "SMG",
		"shoot_rate": 0.14,
		"bullet_speed": 610.0,
		"bullet_damage": 11,
		"bullet_life_time": 1.0,
		"projectile_count": 1,
		"spread_degrees": 4.0
	},
	"rifle": {
		"name": "Rifle",
		"shoot_rate": 0.22,
		"bullet_speed": 780.0,
		"bullet_damage": 18,
		"bullet_life_time": 1.35,
		"projectile_count": 1,
		"spread_degrees": 0.0
	}
}

static func get_weapon_data(weapon_id: String) -> Dictionary:
	return WEAPONS.get(weapon_id, WEAPONS["pistol"]).duplicate(true)

static func has_weapon(weapon_id: String) -> bool:
	return WEAPONS.has(weapon_id)

static func get_weapon_ids() -> Array:
	return WEAPONS.keys()
