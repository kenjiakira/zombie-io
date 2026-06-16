extends Node

func apply_upgrade(player: Node, upgrade_id: String) -> void:
	if player == null:
		return

	match upgrade_id:
		"bullet_damage":
			if player.has_method("upgrade_current_weapon_damage"):
				player.upgrade_current_weapon_damage(10)
		"bullet_speed":
			if player.has_method("upgrade_current_weapon_speed"):
				player.upgrade_current_weapon_speed(120.0)
		"shoot_rate":
			if player.has_method("upgrade_current_weapon_fire_rate"):
				player.upgrade_current_weapon_fire_rate(0.05)
		"player_speed":
			player.speed += 12
		"max_hp":
			player.max_hp += 20
			player.hp = min(player.hp + 20, player.max_hp)
		_:
			return
