# Concrete obstacle type backed by a Sprite2D and a CollisionShape2D
# Configured at runtime from an ObstacleProfile resource provided by the PoolManager
class_name Obstacle
extends PoolableEntity

var assigned_track:int

@export var sprite: Sprite2D
@export var collision_shape: CollisionShape2D

func _ready() -> void:
	_configure_obstacle_from_profile(self, "countryside")

# Selects a random profile from the biome and applies it to the obstacle instance
func _configure_obstacle_from_profile(instance: PoolableEntity, biome: String) -> void:
	var profiles: Array = PoolManager.biome_profiles[biome]
	var obstacle: Obstacle = instance as Obstacle
	
	# Pick a random profile only from ones allowed on the obstacle's track
	# e.g. if the obstacle is on track 2, pick only from profiles that allow track 2
	var profiles_allowed_by_track: Array
	for p in profiles:
		if assigned_track in p.allowed_tracks:
			profiles_allowed_by_track.append(p)
	if not profiles_allowed_by_track.is_empty():
		var profile: ObstacleProfile = profiles_allowed_by_track.pick_random()
		obstacle.setup_from_profile(profile)


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
func _on_area_entered(_area: Area2D) -> void:
	if _area is Player:
		print("Player collided with obstacle")
