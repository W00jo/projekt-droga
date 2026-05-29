extends StaticBody2D

@export var player: PlayerWASD
@export var garage_door_sprite: AnimatedSprite2D
 
func reset_hub():
	player.position = Vector2(560, 380)
	garage_door_sprite.frame = 0
