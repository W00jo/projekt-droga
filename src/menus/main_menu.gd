extends Control

const HUB_SCENE_PATH := "res://src/hub/hub.tscn"

@onready var start_button: Button = $MenuController/MenuButtons/StartButton
@onready var continue_button: Button = $MenuController/MenuButtons/ContinueButton
@onready var options_button: Button = $MenuController/MenuButtons/OptionsButton
@onready var credits_button: Button = $MenuController/MenuButtons/CreditsButton
@onready var desktop_button: Button = $MenuController/MenuButtons/DesktopButton

func _ready() -> void:
	_menu_buttons()

func _menu_buttons() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	start_button.pressed.connect(_on_start_pressed)
	options_button.pressed.connect(_on_options_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	desktop_button.pressed.connect(_on_desktop_pressed)

func _on_continue_pressed() -> void:
	pass

func _on_start_pressed() -> void:
	var change_result := get_tree().change_scene_to_file(HUB_SCENE_PATH)

func _on_options_pressed() -> void:
	pass

func _on_credits_pressed() -> void:
	pass

func _on_desktop_pressed() -> void:
	get_tree().quit()
