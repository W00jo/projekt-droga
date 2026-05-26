extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerWASD:
		GameManager.main_scene.exit_hub_and_start_run()
