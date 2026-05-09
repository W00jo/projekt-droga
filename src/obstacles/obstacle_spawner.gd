class_name ObstacleSpawner
extends Node2D

# Obstacle profiles grouped by biome; each profile defines texture variants,
# sprite scale/offset, and collision shape/offset for a single obstacle type
var biome_profiles: Dictionary = {
	"countryside": [
		preload("res://src/obstacles/profiles/countryside_car.tres"),
		preload("res://src/obstacles/profiles/bush.tres")
	],
	"city": [
		preload("res://src/obstacles/profiles/city_car.tres")
	]
}

## Selects a random profile from the biome and applies it to the obstacle instance
#func _configure_obstacle_from_profile(instance: PoolableEntity, biome: String) -> void:
	#var profiles: Array = PoolManager.biome_profiles[biome]
	#var obstacle: Obstacle = instance as Obstacle
	#print(obstacle.assigned_track)
	## Pick a random profile only from ones allowed on the obstacle's track
	## e.g. if the obstacle is on track 2, pick only from profiles that allow track 2
	#var profiles_allowed_by_track: Array
	#for p in profiles:
		#if obstacle.assigned_track in p.allowed_tracks:
			#profiles_allowed_by_track.append(p)
	#if not profiles_allowed_by_track.is_empty():
		#var profile: ObstacleProfile = profiles_allowed_by_track.pick_random()
		#obstacle.setup_from_profile(profile)
#
#func _initialise_obstacle_pool():
		#var obstacle_instance: PoolableEntity = PoolManager.get_instance("obstacle", "countryside")
		#
		#_reset_obstacle_position_x(obstacle_instance)
		## Set obstacle's y position to match a track's position
		## All tracks have an equal amount of obstacles
		## e.g. 12 obstacles, 4 tracks = 3 obstacles per track
		#var instances_per_track: int = obstacle_pool_size / TRACK_COUNT
		#var track_to_spawn_on:int = (i / instances_per_track) + 1
		#obstacle_instance.position.y = get_track_position_y(track_to_spawn_on)
		#obstacle_instance.z_index = track_to_spawn_on
		#obstacle_instance.assigned_track = track_to_spawn_on
		#
		#obstacles_container.add_child(obstacle_instance)
		#obstacle_spawner.spawn_obstacles()

# Sets or resets obstacle's x position to be just outside the screen
func _reset_obstacle_position_x(instance):
	# How far the obstacle is from the right screen border (in px)
	var _distance_from_screen: float = 300
	instance.position.x = get_viewport().get_visible_rect().size.x + _distance_from_screen
