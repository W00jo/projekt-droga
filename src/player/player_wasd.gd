extends CharacterBody2D

var last_direction: String = "down"
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@export var speed: int = 350

func get_input():
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_direction * speed
	
	if velocity != Vector2.ZERO:
		if input_direction.y > 0:
			anim_player.play("walk_down")
			last_direction = "down"
		elif input_direction.y < 0:
			anim_player.play("walk_up")
			last_direction = "up"
		elif input_direction.x > 0:
			anim_player.play("walk_right")
			last_direction = "right"
		elif input_direction.x < 0:
			anim_player.play("walk_left")
			last_direction = "left"
	else:
		anim_player.stop()
		match last_direction:
			"down": sprite.frame = 1
			"up": sprite.frame = 4
			"right": sprite.frame = 7
			"left": sprite.frame = 10

func _physics_process(_delta):
	get_input()
	move_and_slide()
