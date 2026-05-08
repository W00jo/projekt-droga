# Abstract base class for any entity managed by the PoolManager
# Subclasses override disable_collision() and add type-specific setup methods
@abstract
class_name PoolableEntity
extends Area2D

# Tracks whether this instance is currently in use or idle in the pool
var is_active: bool = false

# Marks the instance as active and visible; called at the start of every spawn cycle
func activate() -> void:
	is_active = true
	visible = true

# Resets the instance to its idle state for return to the pool
func deactivate() -> void:
	is_active = false
	visible = false
	disable_collision()

# Disables collision boundaries when returned to the pool
# Also called independently when the entity is hit but should remain visible
# (e.g., during a destruction animation before returning to the pool)
@abstract
func disable_collision() -> void
