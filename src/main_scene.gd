class_name MainScene
extends Node2D

@export var hub: StaticBody2D
@export var level: LevelManager
@export var transition_scene: CanvasLayer
@export var title_screen: TitleScreen

func _ready() -> void:
	GameManager.main_scene = self
	title_screen.connect("title_screen_killed", toggle_hub_player_movement)
	
	hub.show()
	level.hide()

func exit_hub_and_start_run() -> void:
	var transition_anim_player: AnimationPlayer = transition_scene.get_node("AnimationPlayer")
	
	transition_anim_player.play("transition_fadeout")
	await transition_anim_player.animation_finished
	
	hub.hide()
	toggle_hub_player_movement(false)
	
	level.show()
	transition_anim_player.play_backwards("transition_fadeout")
	level.start_run()

func toggle_hub_player_movement(toggle: bool) -> void:
	hub.player.is_active = toggle
