# LevelManager acts as the orchestrator for the endless treadmill effect
# It manages the Object Pool of ProceduralChunks and controls their continuous scrolling
class_name LevelManager
extends Node2D

const TRACK_COUNT: int = 4
const TRACK_Y_SPACING: float = 90.0
const TRACK_1_POS_Y: float = 350.0

const CHUNK_WIDTH_TILES: int = 12
const TILE_WIDTH_PX: float = 46.0
const CHUNK_SCALE: float = 2.75
const POOL_SIZE: int = 5

# A FIFO queue storing references to our active chunks on screen
var active_chunks: Array[ProceduralChunk] = []

# List of active obstacles currently rendering in the level
var active_obstacles: Array[PoolableObstacle] = []

@onready var chunks_container: Node2D = Node2D.new()
@onready var obstacles_container: Node2D = Node2D.new()
@onready var transition: AnimationPlayer = $"LevelTransition/AnimationPlayer"

var chunk_scene: PackedScene = preload("res://src/level/chunks/procedural_chunk.tscn")

# Configuration for the spatial origin of the endless environment
@export var environment_origin: Vector2 = Vector2(-209, 285)

func _ready() -> void:
	chunks_container.name = "Chunks"
	chunks_container.position = environment_origin
	chunks_container.scale = Vector2(CHUNK_SCALE, CHUNK_SCALE)
	add_child(chunks_container)
	
	# Obstacles live at global scale (1.0) and origin (0,0)
	# to avoid compounding the Obstacle scene's native scale
	obstacles_container.name = "Obstacles"
	add_child(obstacles_container)
	
	_initialise_chunk_pool()
	_spawn_test_obstacles()
	
	transition.play_backwards("transition_fadeout")

func _process(delta: float) -> void:
	_scroll_environment(delta)

# Provides a centralised way for other entities to determine the exact Y coordinate of a lane
func get_track_position_y(track_index: int) -> float:
	var clamped_index: int = clampi(track_index, 1, TRACK_COUNT)
	return (clamped_index - 1) * TRACK_Y_SPACING + TRACK_1_POS_Y



# Pre-allocates a fixed number of chunks at the start of the game
func _initialise_chunk_pool() -> void:
	for i in range(POOL_SIZE):
		var chunk: ProceduralChunk = chunk_scene.instantiate() as ProceduralChunk
		chunks_container.add_child(chunk)
		
		# Align chunks seamlessly along the X axis based on their tile width and pixel size
		chunk.position.x = i * (CHUNK_WIDTH_TILES * TILE_WIDTH_PX)
		chunk.paint_chunk(BiomeManager.get_chunk_layout(CHUNK_WIDTH_TILES, TRACK_COUNT))
		
		active_chunks.append(chunk)

# Translates the global scroll speed to local environment movement (chunks and obstacles)
func _scroll_environment(delta: float) -> void:
	var local_speed: float = GameManager.current_scroll_speed / CHUNK_SCALE
	var global_speed: float = GameManager.current_scroll_speed
	
	for chunk in active_chunks:
		chunk.position.x -= local_speed * delta
		
	var first_chunk: ProceduralChunk = active_chunks[0]
	var last_chunk: ProceduralChunk = active_chunks[-1]
	var chunk_width_local: float = CHUNK_WIDTH_TILES * TILE_WIDTH_PX
	
	# Once the leftmost chunk is completely out of the viewport, snap it to the far right
	if first_chunk.position.x < -chunk_width_local:
		first_chunk.position.x = last_chunk.position.x + chunk_width_local
		first_chunk.paint_chunk(BiomeManager.get_chunk_layout(CHUNK_WIDTH_TILES, TRACK_COUNT))
		
		# Rotate the array to maintain the correct left-to-right order in our tracking logic
		active_chunks.pop_front()
		active_chunks.append(first_chunk)
		
	# Scroll obstacles at global speed and recycle any that leave the viewport
	const OFFSCREEN_THRESHOLD: float = -200.0
	for i in range(active_obstacles.size() - 1, -1, -1):
		var obstacle: PoolableObstacle = active_obstacles[i]
		obstacle.position.x -= global_speed * delta
		
		if obstacle.position.x < OFFSCREEN_THRESHOLD:
			PoolManager.release_instance("obstacle", obstacle)
			active_obstacles.remove_at(i)

# Validates that a new obstacle can be placed at the given position and track
# without overlapping an existing obstacle on the same or adjacent lanes
func can_spawn_obstacle_at(local_x: float, track: int) -> bool:
	const MIN_X_SEPARATION: float = 150.0
	
	for obstacle in active_obstacles:
		if abs(obstacle.position.x - local_x) < MIN_X_SEPARATION:
			# Reject if the existing obstacle is on the same or a neighbouring track
			var existing_track: int = obstacle.z_index
			if abs(existing_track - track) <= 1:
				return false
				
	return true

# Deploys initial test obstacles to verify Z-indexing and depth sorting mechanics
func _spawn_test_obstacles() -> void:
	# Spawning the first obstacle on track 2 (upper road lane)
	var obstacle1: PoolableObstacle = PoolManager.get_instance("obstacle", "countryside")
	obstacles_container.add_child(obstacle1)
	obstacle1.position = Vector2(800.0, get_track_position_y(2))
	obstacle1.z_index = 2
	active_obstacles.append(obstacle1)
	
	# Spawning the second obstacle on track 3 (lower road lane), closer to the camera (higher Z-index)
	# We intentionally bypass the can_spawn_obstacle_at check here to demonstrate visual Z-index overlap
	var obstacle2: PoolableObstacle = PoolManager.get_instance("obstacle", "countryside")
	obstacles_container.add_child(obstacle2)
	obstacle2.position = Vector2(850.0, get_track_position_y(3))
	obstacle2.z_index = 3
	active_obstacles.append(obstacle2)
	
	# Spawn a third obstacle after 5 seconds to verify pool recycling
	await get_tree().create_timer(5.0).timeout
	
	# Guard against dangling coroutine if the level was destroyed during the await
	if not is_instance_valid(self) or not is_inside_tree():
		return
		
	var obstacle3: PoolableObstacle = PoolManager.get_instance("obstacle", "countryside")
	obstacles_container.add_child(obstacle3)
	
	# Spawn outside the screen to the right so it scrolls into view naturally
	obstacle3.position = Vector2(1400.0, get_track_position_y(3))
	obstacle3.z_index = 3
	active_obstacles.append(obstacle3)