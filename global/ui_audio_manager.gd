extends AudioStreamPlayer

const CLICK_SFX = preload("res://assets/button_click.ogg")

func play_click() -> void:
	stream = CLICK_SFX
	pitch_scale = randf_range(0.9, 1.1) 
	play()
