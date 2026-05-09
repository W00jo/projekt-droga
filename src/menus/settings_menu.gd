extends Control

@onready var sound_button: Button = $CenterContainer/SettingsButton/SoundButton
@onready var language_button: Button = $CenterContainer/SettingsButton/LanguageButton
@onready var reset_save_button: Button = $CenterContainer/SettingsButton/ResetSaveButton
@onready var return_button: Button = $CenterContainer/SettingsButton/ReturnButton

func _ready() -> void:
	_settings_buttons()

func _settings_buttons() -> void:
	sound_button.pressed.connect(_on_sound_button_pressed)
	language_button.pressed.connect(_on_language_button_pressed)
	reset_save_button.pressed.connect(_on_reset_save_button_pressed)
	return_button.pressed.connect(_on_return_button_pressed)

func _on_sound_button_pressed() -> void:
	pass # Replace with function body.

func _on_language_button_pressed() -> void:
	pass # Replace with function body.

func _on_reset_save_button_pressed() -> void:
	pass # Replace with function body.

func _on_return_button_pressed() -> void:
	pass # Replace with function body.
