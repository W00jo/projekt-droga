extends Control

var run_time: float

func _ready() -> void:
	run_time = GameManager.current_time

func show_popup_and_cursor() -> void:
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func display_completion_time() -> void:
	# Convert to integer once to avoid expensive floating-point modulo operations
	var total_seconds: int = int(run_time - GameManager.current_time)
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	
	%TimeLabel.text = "%02d:%02d" % [minutes, seconds]


func _on_play_again_button_pressed() -> void:
	print("RETURNING TO HUB...")
	GameManager.main_scene.return_to_hub()
	hide()
	get_tree().create_timer(0.1).timeout
	hide()
