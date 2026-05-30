extends CanvasLayer

@export var button_sound_player: AudioStreamPlayer
@export var music_volume_slider: HSlider
@export var sounds_volume_slider: HSlider

func _on_close_button_pressed() -> void:
	button_sound_player.play()
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	GameManager.main_scene.toggle_hub_player_movement(true)

func _on_music_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(value))

func _on_sounds_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(1, linear_to_db(value))
