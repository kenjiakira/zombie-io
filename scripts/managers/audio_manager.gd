extends Node

var sfx_enabled: bool = true
var music_enabled: bool = true

func play_sfx(_sfx_id: String) -> void:
	if not sfx_enabled:
		return

func play_music(_music_id: String) -> void:
	if not music_enabled:
		return

func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled

func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
