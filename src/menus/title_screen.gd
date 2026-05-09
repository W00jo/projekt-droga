extends Control

const HUB_SCENE_PATH := "res://src/hub/hub.tscn"

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		if event.is_pressed() and not event.is_echo():
			_transition_to_hub()

func _transition_to_hub() -> void:
	set_process_input(false)
	
	SFXClickManager.play_click()
	
	await get_tree().create_timer(0.15).timeout
	
	var change_result := get_tree().change_scene_to_file(HUB_SCENE_PATH)
	
	if change_result != OK:
		push_error("Sprawdź UID ;)")
