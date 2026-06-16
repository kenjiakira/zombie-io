extends Resource

const ENEMIES := {
	"normal": {
		"name": "Normal",
		"speed": 90.0,
		"max_hp": 50,
		"damage": 10,
		"exp_value": 1,
		"score_value": 1,
		"knockback_strength": 300.0,
		"attack_cooldown": 0.8,
		"attack_range": 32.0,
		"weapon_drop_chance": 0.10,
		"weapon_drop_weights": {"pistol": 60, "smg": 25, "shotgun": 15},
		"visual_scale": Vector2.ONE,
		"color": Color(0.25, 0.9, 0.35)
	},
	"fast": {
		"name": "Fast",
		"speed": 150.0,
		"max_hp": 35,
		"damage": 8,
		"exp_value": 1,
		"score_value": 1,
		"knockback_strength": 260.0,
		"attack_cooldown": 0.65,
		"attack_range": 28.0,
		"weapon_drop_chance": 0.12,
		"weapon_drop_weights": {"pistol": 20, "smg": 45, "shotgun": 35},
		"visual_scale": Vector2(0.9, 0.9),
		"color": Color(0.9, 0.8, 0.25)
	},
	"tank": {
		"name": "Tank",
		"speed": 60.0,
		"max_hp": 120,
		"damage": 18,
		"exp_value": 3,
		"score_value": 3,
		"knockback_strength": 390.0,
		"attack_cooldown": 1.0,
		"attack_range": 36.0,
		"weapon_drop_chance": 0.18,
		"weapon_drop_weights": {"smg": 15, "shotgun": 45, "rifle": 40},
		"visual_scale": Vector2(1.2, 1.2),
		"color": Color(0.75, 0.3, 0.85)
	},
	"exploder": {
		"name": "Exploder",
		"speed": 175.0,
		"max_hp": 70,
		"damage": 0,
		"exp_value": 2,
		"score_value": 2,
		"knockback_strength": 280.0,
		"attack_cooldown": 0.0,
		"attack_range": 0.0,
		"weapon_drop_chance": 0.0,
		"weapon_drop_weights": {},
		"visual_scale": Vector2(1.05, 1.05),
		"color": Color(1.0, 0.55, 0.15),
		"explode_distance": 54.0,
		"explosion_radius": 62.0,
		"explosion_damage": 18
	},
	"mini_boss": {
		"name": "Mini Boss",
		"speed": 70.0,
		"max_hp": 280,
		"damage": 22,
		"exp_value": 8,
		"score_value": 10,
		"knockback_strength": 460.0,
		"attack_cooldown": 1.1,
		"attack_range": 42.0,
		"weapon_drop_chance": 1.0,
		"weapon_drop_weights": {"shotgun": 35, "smg": 35, "rifle": 30},
		"visual_scale": Vector2(1.55, 1.55),
		"color": Color(0.95, 0.45, 0.2),
		"charge_speed": 260.0,
		"charge_damage": 22,
		"charge_duration": 0.65,
		"slam_damage": 28,
		"slam_radius": 90.0,
		"slam_windup": 0.4,
		"summon_count": 3,
		"summon_uses": 2,
		"attack_interval": 2.4,
		"recover_time": 0.45,
		"summon_types": ["normal", "normal", "fast"]
	},
	"boss": {
		"name": "Boss",
		"speed": 55.0,
		"max_hp": 700,
		"damage": 35,
		"exp_value": 25,
		"score_value": 40,
		"knockback_strength": 560.0,
		"attack_cooldown": 1.25,
		"attack_range": 48.0,
		"weapon_drop_chance": 1.0,
		"weapon_drop_weights": {"shotgun": 20, "smg": 30, "rifle": 50},
		"visual_scale": Vector2(2.1, 2.1),
		"color": Color(0.95, 0.2, 0.2),
		"charge_speed": 330.0,
		"charge_damage": 34,
		"charge_duration": 0.8,
		"slam_damage": 44,
		"slam_radius": 120.0,
		"slam_windup": 0.5,
		"summon_count": 4,
		"summon_uses": 4,
		"attack_interval": 2.0,
		"recover_time": 0.5,
		"summon_types": ["normal", "fast", "fast", "tank"]
	}
}

static func get_enemy_data(enemy_id: String) -> Dictionary:
	return ENEMIES.get(enemy_id, ENEMIES["normal"]).duplicate(true)

static func has_enemy(enemy_id: String) -> bool:
	return ENEMIES.has(enemy_id)

static func get_enemy_ids() -> Array:
	return ENEMIES.keys()
