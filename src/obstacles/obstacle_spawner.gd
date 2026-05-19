class_name ObstacleSpawner
extends Node2D

# Values for a linear function that goes from START to END,
# which are also randomised from MIN value to MAX value
const START_MIN_TIME: float = 0.75
const END_MIN_TIME: float = 0.2
const START_MAX_TIME: float = 1.25
const END_MAX_TIME: float = 0.35

# TODO: add jitter (slight x pos randomising)

# Obstacle profiles grouped by biome; each profile defines texture variants,
# sprite scale/offset, and collision shape/offset for a single obstacle type
var biome_profiles: Dictionary = {
	"countryside": [
		preload("res://src/obstacles/profiles/countryside_car.tres"),
		preload("res://src/obstacles/profiles/bush.tres"),
		preload("res://src/obstacles/profiles/road_block.tres"),
		preload("res://src/obstacles/profiles/sewer_manhole.tres"),
		preload("res://src/obstacles/profiles/water_puddle.tres"),
		preload("res://src/obstacles/profiles/traffic_cone.tres"),
		preload("res://src/obstacles/profiles/trash_bin.tres"),
		preload("res://src/obstacles/profiles/trash_bags.tres"),
	],
	"city": [
		preload("res://src/obstacles/profiles/city_car.tres")
	]
}

# Level (parent) introduces itself to this script
var level: LevelManager

var spawn_timer: Timer = Timer.new()

var recently_used_tracks: Array[int] = []
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	GameManager.connect("state_changed", manage_spawner_active_time)
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_spawn_obstacle)

func _process(_delta: float) -> void:
	manage_spawner_wait_time()

func manage_spawner_wait_time():
	var progress = clampf(GameManager.distance_travelled / GameManager.target_distance, 0.0, 1.0)
	var min_time = lerpf(START_MIN_TIME, END_MIN_TIME, progress)
	var max_time = lerpf(START_MAX_TIME, END_MAX_TIME, progress)
	spawn_timer.wait_time = randf_range(min_time, max_time)

func manage_spawner_active_time(current_state):
	if current_state == GameManager.GameState.RUNNING:
		print("GAME STATE: RUNNING!")
		spawn_timer.start()
	else:
		spawn_timer.stop()

func _spawn_obstacle():
	var track_id: int = get_diversified_track_id()
	var x_offset_to_right: int = 200
	var obstacle_position_y: int = int(level.get_track_position_y(track_id))
	var obstacle_position_x: int = int(get_viewport().get_visible_rect().size.x + x_offset_to_right)
	if can_spawn_obstacle_at(obstacle_position_x, track_id):
		var new_obstacle: PoolableEntity = PoolManager.get_instance("obstacle", "countryside")
		new_obstacle.activate()
		level.active_obstacles.append(new_obstacle)
		_configure_obstacle_from_profile(new_obstacle, track_id, BiomeManager.current_biome)
		if level.obstacles_container:
			level.obstacles_container.add_child(new_obstacle)
			new_obstacle.position = Vector2(obstacle_position_x, obstacle_position_y)
			new_obstacle.z_index = track_id

# Selects a random profile from the biome and applies it to the obstacle instance
func _configure_obstacle_from_profile(instance: PoolableEntity, track: int, biome: String):
	var profiles: Array = biome_profiles[biome]
	var obstacle: Obstacle = instance as Obstacle
	
	# Picking a random profile only from ones allowed on the obstacle's track
	# e.g. if the obstacle is on track 2, pick only from profiles that allow track 2
	var profiles_allowed_by_track: Array
	for p in profiles:
		if track in p.allowed_tracks:
			profiles_allowed_by_track.append(p)
	if not profiles_allowed_by_track.is_empty():
		var profile: ObstacleProfile = profiles_allowed_by_track.pick_random()
		obstacle.setup_from_profile(profile)

# Returns a pseudorandom track number, by checking recently used tracks
# and applying weights to the RNG accordingly
# e.g. the most recent track id will only have 0.25 chance to get picked,
# while the least recent one will have a 3.0 chance
func get_diversified_track_id() -> int:
	const ALL_TRACKS = [1, 2, 3, 4]
	var weight_values: Dictionary = {
		0: 2.0,
		1: 1.0,
		2: 0.25,
		3: 3.0
	}
	var id: int
	
	if recently_used_tracks.size() == 3:
		var weights: Array[float] = [weight_values[0], weight_values[1], weight_values[2], weight_values[3]]
		
		for i in recently_used_tracks.size():
			swap_array_elements(weights, weight_values[i], ALL_TRACKS.find(recently_used_tracks[i]))
		
		var weights_packed: PackedFloat32Array = PackedFloat32Array(weights)
		id = ALL_TRACKS[rng.rand_weighted(weights_packed)]
		recently_used_tracks.append(id)
		recently_used_tracks.remove_at(0)
		
	else:
		id = ALL_TRACKS.pick_random()
		recently_used_tracks.append(id)
	
	return id

# Swaps an element of an array with another element of target_index index,
# e.g. array = ["one","two","three"]  element = "two"  target_index = 0
# would return: ["two", "one", "three"]
func swap_array_elements(array:Array, element, target_index:int) -> Array:
	var element_at_target_id = array.get(target_index)
	array.set(array.find(element), element_at_target_id)
	array.set(target_index, element)
	return array

# Validates that a new obstacle can be placed at the given position and track
# without overlapping an existing obstacle on the same or adjacent lanes
func can_spawn_obstacle_at(local_x: float, track: int) -> bool:
	const MIN_X_SEPARATION: float = 200.0
	for obstacle in level.active_obstacles:
		if abs(obstacle.position.x - local_x) < MIN_X_SEPARATION:
			# Reject if the existing obstacle is on the same or a neighbouring track
			var existing_track: int = obstacle.z_index
			if abs(existing_track - track) <= 1:
				return false
	return true
