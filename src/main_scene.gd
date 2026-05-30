class_name MainScene
extends Node2D

@export var hub: StaticBody2D
@export var level: LevelManager
@export var transition_scene: CanvasLayer
@export var title_screen: TitleScreen
@export var title_screen_click_sfx: AudioStreamPlayer

func _ready() -> void:
	GameManager.main_scene = self
	title_screen.connect("title_screen_killed", _on_title_screen_killed)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	hub.show()
	level.hide()

func _on_title_screen_killed() -> void:
	title_screen_click_sfx.play()
	toggle_hub_player_movement(true)
	hub.music_player.play()

func exit_hub_and_start_run() -> void:
	var transition_anim_player: AnimationPlayer = transition_scene.get_node("AnimationPlayer")
	
	transition_anim_player.play("transition_fadeout")
	await transition_anim_player.animation_finished
	
	hub.hide()
	toggle_hub_player_movement(false)
	hub.music_player.stop()
	
	level.show()
	transition_anim_player.play_backwards("transition_fadeout")
	level.start_run()
	level.music_player.play()

func toggle_hub_player_movement(toggle: bool) -> void:
	hub.player.is_active = toggle

func return_to_hub() -> void:
	level.music_player.stop()
	hub.music_player.play()
	
	hub.show()
	level.hide()
	
	hub.reset_hub()
	toggle_hub_player_movement(true)
	
	level.reset_level()
