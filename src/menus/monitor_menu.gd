extends CanvasLayer


func _on_close_button_pressed() -> void:
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	GameManager.main_scene.toggle_hub_player_movement(true)
