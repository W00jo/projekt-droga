extends Area2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func _on_body_entered(body: Node2D) -> void:
	if body.name == "PlayerWASD":
		get_node("SpriteDoor").frame = 0
		get_node("SpriteHubWall").visible = true
	
func _on_body_exited(body: Node2D) -> void:
	if body.name == "PlayerWASD":
		get_node("SpriteDoor").frame = 1
		get_node("SpriteHubWall").visible = false

func _on_area_game_exit_body_entered(body: Node2D) -> void:
	if body.name == "PlayerWASD":
		get_tree().quit()
