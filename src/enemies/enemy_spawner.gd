class_name EnemySpawner
extends Node2D

var level: LevelManager
var spawn_timer: Timer = Timer.new()
var enemy_id_counter: int = 0

const MAX_WAIT_TIME: float = 6.0
const MIN_WAIT_TIME: float = 2.0

func _ready() -> void:
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_spawn_enemy)
	

func _process(_delta: float) -> void:
	spawner_manage_active_time()

func spawner_manage_active_time() -> void:
	if GameManager.current_state == GameManager.GameState.RUNNING and level.active_enemies.is_empty():
		if spawn_timer.is_stopped():
			spawn_timer.wait_time = randf_range(MIN_WAIT_TIME, MAX_WAIT_TIME)
			spawn_timer.start()
	else:
		spawn_timer.stop()
		
func _spawn_enemy() -> void:
	var new_enemy: PoolableEntity = PoolManager.get_instance("dog")
	new_enemy.activate()
	level.active_enemies.append(new_enemy)
	if level.enemies_container:
		level.enemies_container.add_child(new_enemy)
		new_enemy.current_track = randi_range(1,level.TRACK_COUNT)
		new_enemy.id = enemy_id_counter
		enemy_id_counter += 1
		new_enemy.start_approach_sequence()
	spawn_timer.stop()

# Recycles enemies that get deactivated
func manage_enemies(new_state: Dog.DogState, target_enemy: Dog) -> void:
	if new_state == Dog.DogState.INACTIVE:
		PoolManager.release_instance("dog", target_enemy)
		level.active_enemies.erase(target_enemy)
