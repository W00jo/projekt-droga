extends StaticBody2D

@export var player: PlayerWASD
@export var garage_door_sprite: AnimatedSprite2D
@export var monitor_menu: CanvasLayer
 
func reset_hub():
	player.position = Vector2(560, 380)
	garage_door_sprite.frame = 0


func _on_area_monitor_body_entered(body: PlayerWASD) -> void:
	monitor_menu.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	player.is_active = false
	
