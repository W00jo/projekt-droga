extends Area2D
@export var door_animated_sprite:AnimatedSprite2D


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerWASD:
		door_animated_sprite.play("door_open")
		GameManager.main_scene.exit_hub_and_start_run()
