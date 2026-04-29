# Concrete obstacle type backed by a Sprite2D and a CollisionShape2D
# Receives its texture at runtime from the PoolManager based on the current biome
extends PoolableObstacle

@export var sprite: Sprite2D
@export var collision_shape: CollisionShape2D

func _ready() -> void:
	# Only disable if we haven't been explicitly activated by setup() yet
	# This prevents _ready from hiding the obstacle when it first enters the scene tree
	if not is_active:
		if collision_shape:
			collision_shape.disabled = true
		visible = false

func setup(texture: Texture2D) -> void:
	super.setup(texture)
	
	if sprite and texture:
		sprite.texture = texture
		
	if collision_shape:
		collision_shape.set_deferred("disabled", false)

func disable_collision() -> void:
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

# Collision callback triggered when the player enters the obstacle's area
func _on_area_entered(_area: Area2D) -> void:
	print("Player collided with obstacle")
