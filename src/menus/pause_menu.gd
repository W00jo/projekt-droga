extends CanvasLayer

@onready var phone_background = $PhoneBackground
@onready var dim_screen = $DimScreen
@onready var continue_button = $PhoneBackground/VBoxContainer/ContinueButton
@onready var volume_slider = $PhoneBackground/VBoxContainer/MasterSoundSlide
@onready var exit_button = $PhoneBackground/VBoxContainer/ExitGameButton

var master_bus_index: int

func _ready() -> void:
	hide()
	
	master_bus_index = AudioServer.get_bus_index("Master")
	
	continue_button.pressed.connect(_on_continue_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)
	
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus_index))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()

func _toggle_pause() -> void:
	var is_paused = get_tree().paused
	
	get_tree().paused = !is_paused
	
	if get_tree().paused:
		show()
	else:
		hide()

func _on_continue_pressed() -> void:
	SFXClickManager.play_click()
	_toggle_pause()

func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value))

func _on_exit_pressed() -> void:
	SFXClickManager.play_click()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()
