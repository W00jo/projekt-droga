extends Control

func show_popup_and_cursor() -> void:
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func display_completion_time() -> void:
	# Elapsed time = starting budget minus whatever remained on the clock at completion
	var total_seconds: int = int(GameManager.STARTING_TIME - GameManager.current_time)
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	
	%TimeLabel.text = "%02d:%02d" % [minutes, seconds]

func _on_play_again_button_pressed() -> void:
	%ButtonSFX.play()
	GameManager.main_scene.return_to_hub()
	hide()
