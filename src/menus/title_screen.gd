class_name TitleScreen
extends Control

signal title_screen_killed

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventJoypadButton:
		if event.is_released() and not event.is_echo():
			_transition_to_hub()

func _transition_to_hub() -> void:
	set_process_input(false)
	
	# Request fullscreen universally (Web/Desktop/Mobile) upon initial interaction
	# Browsers require this to be triggered directly by a user interaction event
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	SFXClickManager.play_click()
	
	# This signal is received by the main scene, which then enables hub player movement
	emit_signal("title_screen_killed", true)
	
	await get_tree().create_timer(0.15).timeout
	queue_free()
