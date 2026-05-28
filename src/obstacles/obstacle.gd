# Concrete obstacle type backed by a Sprite2D and a CollisionShape2D
# Configured at runtime from an ObstacleProfile resource provided by the PoolManager
class_name Obstacle
extends PoolableEntity

var assigned_track:int

@export var sprite: Sprite2D
@export var collision_shape: CollisionShape2D

const INVINCIBILITY_DURATION: float = 3.0

# Applies all visual and physical properties from the given profile
func setup_from_profile(profile: ObstacleProfile) -> void:
	activate()

	sprite.texture = profile.texture_variants.pick_random()
	sprite.scale = profile.sprite_scale
	sprite.position = profile.sprite_offset

	collision_shape.shape = profile.collision_shape
	collision_shape.position = profile.collision_offset
	collision_shape.set_deferred("disabled", false)

func disable_collision() -> void:
	collision_shape.set_deferred("disabled", true)

# Collision callback triggered when the player enters the obstacle's area
func _on_area_entered(area: Area2D) -> void:
	if area is Player:
		area.invincibility(INVINCIBILITY_DURATION)
		GameManager.deduct_time(10)
		print("Player collided with obstacle")
