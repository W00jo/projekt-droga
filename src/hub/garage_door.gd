extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerWASD:
		GameManager.main_scene.exit_hub_and_start_run()
		
		#transition_animation.play("transition_fadeout")
		#await transition_animation.animation_finished
		#get_tree().change_scene_to_file.call_deferred("res://src/level/level.tscn")
