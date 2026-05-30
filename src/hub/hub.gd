extends StaticBody2D

@export var player: PlayerWASD
@export var garage_door_sprite: AnimatedSprite2D
@export var monitor_menu: CanvasLayer
@export var music_player: AudioStreamPlayer
 
func reset_hub():
	player.position = Vector2(560, 380)
	player.last_direction = "down"
	player.sprite.frame = 1
	garage_door_sprite.frame = 0

func _on_area_monitor_body_entered(body: Node2D) -> void:
	if body is PlayerWASD:
		monitor_menu.show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		player.is_active = false
