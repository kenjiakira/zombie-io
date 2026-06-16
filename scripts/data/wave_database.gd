extends Resource

static func get_wave_config(p_wave: int) -> Dictionary:
	if p_wave <= 2:
		return {
			"total_zombies": 6 + (p_wave - 1) * 2,
			"spawn_interval": maxf(0.9, 1.15 - (p_wave - 1) * 0.12),
			"weights": {"normal": 100}
		}

	if p_wave <= 4:
		return {
			"total_zombies": 10 + (p_wave - 3) * 2,
			"spawn_interval": maxf(0.75, 0.9 - (p_wave - 3) * 0.08),
			"weights": {"normal": 60, "fast": 28, "exploder": 12}
		}

	if p_wave == 5:
		return {
			"total_zombies": 14,
			"spawn_interval": 0.72,
			"weights": {"normal": 40, "fast": 30, "tank": 18, "exploder": 12},
			"boss_type": "mini_boss"
		}

	if p_wave <= 9:
		var tank_weight = 25 + (p_wave - 6) * 10
		var fast_weight = max(15, 35 - (p_wave - 6) * 4)
		var normal_weight = max(10, 40 - (p_wave - 6) * 6)
		var exploder_weight = 10 + (p_wave - 6) * 2
		return {
			"total_zombies": 16 + (p_wave - 6) * 2,
			"spawn_interval": maxf(0.45, 0.68 - (p_wave - 6) * 0.04),
			"weights": {"normal": normal_weight, "fast": fast_weight, "tank": tank_weight, "exploder": exploder_weight}
		}

	if p_wave == 10:
		return {
			"total_zombies": 24,
			"spawn_interval": 0.5,
			"weights": {"normal": 12, "fast": 20, "tank": 48, "exploder": 20},
			"boss_type": "boss"
		}

	var extra_wave = p_wave - 10
	return {
		"total_zombies": 24 + extra_wave * 4,
		"spawn_interval": maxf(0.3, 0.5 - extra_wave * 0.03),
		"weights": {
			"normal": max(5, 15 - extra_wave),
			"fast": max(12, 25 - extra_wave),
			"tank": 50 + extra_wave * 2,
			"exploder": 20 + extra_wave * 2
		}
	}
