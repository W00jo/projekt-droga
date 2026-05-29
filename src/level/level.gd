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
var active_obstacles: Array[PoolableEntity] = []

# List of active enemies currently rendering in the level
var active_enemies: Array[PoolableEntity] = []

@onready var chunks_container: Node2D = Node2D.new()
@onready var obstacles_container: Node2D = Node2D.new()
@onready var obstacle_spawner: ObstacleSpawner = $ObstacleSpawner
@onready var enemies_container: Node2D = Node2D.new()
@onready var enemy_spawner: EnemySpawner = $EnemySpawner

@export var player: Player
@export var bus_stop: Sprite2D
@export var bus: AnimatedSprite2D
@export var bus_animation: AnimationPlayer 
@export var win_screen: Control
@export var lose_screen: Control

var chunk_scene: PackedScene = preload("res://src/level/chunks/procedural_chunk.tscn")

# Configuration for the spatial origin of the endless environment
@export var environment_origin: Vector2 = Vector2(-209, 285)

func start_run() -> void:
	GameManager.change_state(GameManager.GameState.ACCELERATING)
	chunks_container.name = "Chunks"
	chunks_container.position = environment_origin
	chunks_container.scale = Vector2(CHUNK_SCALE, CHUNK_SCALE)
	add_child(chunks_container)
	
	# Obstacles live at global scale (1.0) and origin (0,0)
	# to avoid compounding the Obstacle scene's native scale
	obstacles_container.name = "Obstacles"
	add_child(obstacles_container)
	
	enemies_container.name = "Enemies"
	add_child(enemies_container)
	
	obstacle_spawner.level = self
	enemy_spawner.level = self
	GameManager.level = self
	
	_initialise_chunk_pool()
	
	#GameManager.state_changed.connect(_bus_arrive_sequence)
	GameManager.state_changed.connect(_on_state_changed)

func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.INACTIVE:
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
		var obstacle: PoolableEntity = active_obstacles[i]
		obstacle.position.x -= global_speed * delta
		
		if obstacle.position.x < OFFSCREEN_THRESHOLD:
			PoolManager.release_instance("obstacle", obstacle)
			active_obstacles.remove_at(i)
			
	if GameManager.current_state == GameManager.GameState.DECELERATING:
		bus_stop.position.x -= global_speed * delta

func _on_state_changed(new_state: GameManager.GameState) -> void:
	if new_state == GameManager.GameState.DECELERATING:
		_show_bus_stop()
	elif new_state == GameManager.GameState.ARRIVED:
		_bus_arrive_sequence()
	elif new_state == GameManager.GameState.FAILED:
		player.sprite_animation.play("idle")
		await get_tree().create_timer(3).timeout
		lose_screen.show_popup_and_cursor()

func _show_bus_stop() -> void:
		bus_stop.visible = true
		bus.visible = true
		while player.current_track != 1:
			player.force_track_change(player.current_track-1)
			await get_tree().create_timer(0.3).timeout
			if not is_instance_valid(self) or not is_inside_tree():
				return

func _bus_arrive_sequence() -> void:
		player.sprite_animation.play("idle")
		bus_animation.play("bus_arrive")
		await bus_animation.animation_finished
		if not is_instance_valid(self) or not is_inside_tree():
			return
		
		player.visible = false
		bus_animation.play("bus_depart")
		await bus_animation.animation_finished
		win_screen.show_popup_and_cursor()
		win_screen.display_completion_time()

func reset_level() -> void:
	pass
