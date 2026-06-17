extends Resource

const WEAPON_ORDER := [
	"pistol",
	"shotgun",
	"smg",
	"rifle",
	"revolver",
	"burst_rifle",
	"minigun",
	"sniper",
	"sawed_off",
	"laser_carbine"
]

const WEAPONS := {
	"pistol": {
		"name": "Pistol",
		"shoot_rate": 0.45,
		"bullet_speed": 650.0,
		"bullet_damage": 25,
		"bullet_life_time": 1.2,
		"projectile_count": 1,
		"spread_degrees": 0.0,
		"magazine_size": 12,
		"reserve_ammo": 72,
		"reload_time": 1.0,
		"color": Color(0.65, 0.75, 0.9)
	},
	"shotgun": {
		"name": "Shotgun",
		"shoot_rate": 0.95,
		"bullet_speed": 560.0,
		"bullet_damage": 16,
		"bullet_life_time": 0.95,
		"projectile_count": 5,
		"spread_degrees": 18.0,
		"magazine_size": 6,
		"reserve_ammo": 30,
		"reload_time": 1.35,
		"color": Color(0.95, 0.62, 0.28)
	},
	"smg": {
		"name": "SMG",
		"shoot_rate": 0.14,
		"bullet_speed": 610.0,
		"bullet_damage": 11,
		"bullet_life_time": 1.0,
		"projectile_count": 1,
		"spread_degrees": 4.0,
		"magazine_size": 24,
		"reserve_ammo": 120,
		"reload_time": 1.15,
		"color": Color(0.35, 0.9, 0.45)
	},
	"rifle": {
		"name": "Rifle",
		"shoot_rate": 0.22,
		"bullet_speed": 780.0,
		"bullet_damage": 18,
		"bullet_life_time": 1.35,
		"projectile_count": 1,
		"spread_degrees": 0.0,
		"magazine_size": 20,
		"reserve_ammo": 100,
		"reload_time": 1.1,
		"color": Color(0.4, 0.7, 1.0)
	},
	"revolver": {
		"name": "Revolver",
		"shoot_rate": 0.6,
		"bullet_speed": 720.0,
		"bullet_damage": 34,
		"bullet_life_time": 1.25,
		"projectile_count": 1,
		"spread_degrees": 0.0,
		"magazine_size": 6,
		"reserve_ammo": 36,
		"reload_time": 1.45,
		"color": Color(0.95, 0.45, 0.35)
	},
	"burst_rifle": {
		"name": "Burst Rifle",
		"shoot_rate": 0.28,
		"bullet_speed": 760.0,
		"bullet_damage": 14,
		"bullet_life_time": 1.25,
		"projectile_count": 3,
		"spread_degrees": 6.0,
		"magazine_size": 18,
		"reserve_ammo": 90,
		"reload_time": 1.18,
		"color": Color(0.55, 0.9, 0.95)
	},
	"minigun": {
		"name": "Minigun",
		"shoot_rate": 0.08,
		"bullet_speed": 580.0,
		"bullet_damage": 8,
		"bullet_life_time": 0.95,
		"projectile_count": 1,
		"spread_degrees": 7.0,
		"magazine_size": 60,
		"reserve_ammo": 240,
		"reload_time": 1.75,
		"color": Color(0.25, 0.95, 0.75)
	},
	"sniper": {
		"name": "Sniper",
		"shoot_rate": 1.15,
		"bullet_speed": 980.0,
		"bullet_damage": 60,
		"bullet_life_time": 1.6,
		"projectile_count": 1,
		"spread_degrees": 0.0,
		"magazine_size": 5,
		"reserve_ammo": 25,
		"reload_time": 1.65,
		"color": Color(1.0, 0.95, 0.55)
	},
	"sawed_off": {
		"name": "Sawed-Off",
		"shoot_rate": 0.75,
		"bullet_speed": 500.0,
		"bullet_damage": 26,
		"bullet_life_time": 0.85,
		"projectile_count": 6,
		"spread_degrees": 24.0,
		"magazine_size": 2,
		"reserve_ammo": 16,
		"reload_time": 1.25,
		"color": Color(1.0, 0.72, 0.38)
	},
	"laser_carbine": {
		"name": "Laser Carbine",
		"shoot_rate": 0.18,
		"bullet_speed": 900.0,
		"bullet_damage": 16,
		"bullet_life_time": 1.4,
		"projectile_count": 1,
		"spread_degrees": 1.5,
		"magazine_size": 30,
		"reserve_ammo": 150,
		"reload_time": 1.05,
		"color": Color(0.75, 0.55, 1.0)
	}
}

static func get_weapon_data(weapon_id: String) -> Dictionary:
	return WEAPONS.get(weapon_id, WEAPONS["pistol"]).duplicate(true)

static func has_weapon(weapon_id: String) -> bool:
	return WEAPONS.has(weapon_id)

static func get_weapon_ids() -> Array:
	return WEAPON_ORDER.duplicate()

static func get_weapon_color(weapon_id: String) -> Color:
	return Color(WEAPONS.get(weapon_id, WEAPONS["pistol"]).get("color", Color(0.65, 0.75, 0.9)))
