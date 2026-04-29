# Abstract base class for any obstacle managed by the PoolManager
# Subclasses override setup() and disable_collision() to handle their specific node bindings
class_name PoolableObstacle
extends Area2D

# Tracks whether this instance is currently in use or idle in the pool
var is_active: bool = false

# Configures the obstacle for display; override in subclasses to bind textures and shapes
func setup(_texture: Texture2D) -> void:
	is_active = true
	visible = true

# Disables collision boundaries when returned to the pool; override to target specific shapes
func disable_collision() -> void:
	pass
