extends Area2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	var transition_animation = get_parent().get_node("LevelTransition").get_node("AnimationPlayer")
	
	if body.name == "PlayerWASD":
		transition_animation.play("transition_fadeout")
		await transition_animation.animation_finished
		get_tree().change_scene_to_file.call_deferred("res://src/level/level.tscn")
