# Data-driven configuration for a single obstacle type
# Artists create .tres instances in the editor to define appearance and collision
# without modifying any script files
class_name ObstacleProfile
extends Resource

# All visual variants for this obstacle type; one is selected at random during setup
@export var texture_variants: Array[Texture2D] = []

# Scale applied to the Sprite2D to normalise assets of different source resolutions
@export var sprite_scale: Vector2 = Vector2(1.0, 1.0)

# Positional offset of the sprite relative to the obstacle's origin
@export var sprite_offset: Vector2 = Vector2.ZERO

# Physics shape assigned to the CollisionShape2D at runtime
@export var collision_shape: Shape2D

# Positional offset of the collision shape relative to the obstacle's origin
@export var collision_offset: Vector2 = Vector2.ZERO

# Tracks (1-indexed) where this obstacle is allowed to spawn (e.g., [2, 3] for cars on the road)
@export var allowed_tracks: Array[int] = [1, 2, 3, 4]
