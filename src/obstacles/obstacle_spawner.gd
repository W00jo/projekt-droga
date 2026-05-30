class_name ObstacleSpawner
extends Node2D

# Values for a linear function that goes from START to END,
# which are also randomised from MIN value to MAX value
const START_MIN_TIME: float = 0.5
const END_MIN_TIME: float = 0.2
const START_MAX_TIME: float = 1.0
const END_MAX_TIME: float = 0.5



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
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	GameManager.connect("state_changed", manage_spawner_active_time)
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_spawn_obstacle)

func _process(_delta: float) -> void:
	manage_spawner_wait_time()

# Adjusts the wait time of the spawner dynamically based on the player's progress
func manage_spawner_wait_time() -> void:
	var progress: float = clampf(GameManager.distance_travelled / GameManager.target_distance, 0.0, 1.0)
	var min_time: float = lerpf(START_MIN_TIME, END_MIN_TIME, progress)
	var max_time: float = lerpf(START_MAX_TIME, END_MAX_TIME, progress)
	spawn_timer.wait_time = randf_range(min_time, max_time)

# Starts or stops the spawner depending on the global game state
func manage_spawner_active_time(current_state: GameManager.GameState) -> void:
	if current_state == GameManager.GameState.RUNNING:
		spawn_timer.start()
	else:
		spawn_timer.stop()

# Clears the spawner's internal state to ensure consecutive runs start fresh
func reset_spawner() -> void:
	recently_used_tracks.clear()
	spawn_timer.stop()

# Generates an organic cluster of obstacles, anchored by a diversified track ID
# to prevent empty lanes, while randomising adjacent tracks and horizontal jitter
func _spawn_obstacle() -> void:
	var cluster_size: int = rng.randi_range(1, 3)
	var primary_track: int = get_diversified_track_id()
	var chosen_tracks: Array[int] = [primary_track]
	
	var available_others: Array[int] = [1, 2, 3, 4]
	available_others.erase(primary_track)
	available_others.shuffle()
	
	for i in range(cluster_size - 1):
		chosen_tracks.append(available_others[i])
	
	const BASE_OFFSET: float = 200.0
	var biome: String = BiomeManager.current_biome
	var biome_profile_list: Array[ObstacleProfile] = []
	biome_profile_list.assign(biome_profiles[biome])
	
	for track_id in chosen_tracks:
		# Apply horizontal jitter so obstacles within a cluster don't form a vertical line
		var jitter: float = rng.randf_range(-60.0, 140.0)
		var obstacle_position_y: int = int(level.get_track_position_y(track_id))
		var obstacle_position_x: int = int(get_viewport().get_visible_rect().size.x + BASE_OFFSET + jitter)
		
		# Filter profiles to only those allowed on this track
		var profiles_allowed: Array[ObstacleProfile] = []
		for p in biome_profile_list:
			if track_id in p.allowed_tracks:
				profiles_allowed.append(p)
				
		if profiles_allowed.is_empty():
			continue
			
		# Pre-select the profile to determine its height before confirming the spawn
		var profile: ObstacleProfile = profiles_allowed.pick_random()
		
		if can_spawn_obstacle_at(obstacle_position_x, track_id, profile.is_tall):
			var new_obstacle: PoolableEntity = PoolManager.get_instance("obstacle", biome)
			new_obstacle.activate()
			level.active_obstacles.append(new_obstacle)
			
			var obstacle: Obstacle = new_obstacle as Obstacle
			obstacle.setup_from_profile(profile)
			
			if level.obstacles_container:
				level.obstacles_container.add_child(new_obstacle)
				new_obstacle.position = Vector2(obstacle_position_x, obstacle_position_y)
				new_obstacle.z_index = track_id



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
func swap_array_elements(array: Array, element: Variant, target_index: int) -> Array:
	var element_at_target_id: Variant = array.get(target_index)
	array.set(array.find(element), element_at_target_id)
	array.set(target_index, element)
	return array

# Validates that a new obstacle can be placed at the given position and track
# without visually occluding or physically overlapping existing obstacles
func can_spawn_obstacle_at(local_x: float, track: int, is_tall: bool) -> bool:
	const SAME_LANE_SEPARATION: float = 280.0
	const ADJACENT_LANE_SEPARATION: float = 100.0
	const OCCLUSION_SEPARATION: float = 140.0
	
	for obstacle in level.active_obstacles:
		var existing_track: int = obstacle.z_index
		var x_dist: float = abs(obstacle.position.x - local_x)
		
		# Reject if too close on the exact same lane
		if existing_track == track and x_dist < SAME_LANE_SEPARATION:
			return false
			
		# Reject if too physically close on adjacent lanes (prevents overlapping hitboxes)
		if abs(existing_track - track) == 1 and x_dist < ADJACENT_LANE_SEPARATION:
			return false
			
		# Occlusion Check 1: The NEW obstacle is flat, but a TALL obstacle already exists on the track below it
		if not is_tall and obstacle.get("is_tall") == true:
			if existing_track == track + 1 and x_dist < OCCLUSION_SEPARATION:
				return false
				
		# Occlusion Check 2: The NEW obstacle is tall, and it would spawn directly in front of an existing FLAT obstacle
		if is_tall and obstacle.get("is_tall") == false:
			if track == existing_track + 1 and x_dist < OCCLUSION_SEPARATION:
				return false
				
	return true
