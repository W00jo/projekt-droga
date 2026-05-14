extends Node


# Configuration for multi-pools
# To add a new poolable type, define its scene and initial size here
var _pool_configs: Dictionary = {
	"obstacle": {
		"scene": preload("res://src/obstacles/obstacle.tscn"),
		"initial_size": 10
	}
	# Example for future enemies:
	# "dog": { "scene": preload("res://src/enemies/dog.tscn"), "initial_size": 1 }
}

# Active pools mapping type_id to an Array of PoolableEntity
var _active_pools: Dictionary = {}

func _ready() -> void:
	_initialise_pools()

# Pre-allocates a fixed number of instances per pool type at startup
func _initialise_pools() -> void:
	for type_id in _pool_configs.keys():
		_active_pools[type_id] = []
		var config: Dictionary = _pool_configs[type_id]
		var scene: PackedScene = config["scene"]
		var size: int = config.get("initial_size", 5)
		
		for i in range(size):
			var instance: PoolableEntity = scene.instantiate() as PoolableEntity
			_active_pools[type_id].append(instance)

# Retrieves an instance from the specified pool and configures it for the given biome
@warning_ignore("unused_parameter")
func get_instance(type_id: String, biome: String = "countryside") -> PoolableEntity:
	if not _active_pools.has(type_id):
		push_error("PoolManager: No pool configured for type_id '%s'" % type_id)
		return null
	
	var pool: Array = _active_pools[type_id]
	var instance: PoolableEntity

	if pool.is_empty():
		var config: Dictionary = _pool_configs[type_id]
		var scene: PackedScene = config["scene"]
		instance = scene.instantiate() as PoolableEntity
	else:
		instance = pool.pop_back() as PoolableEntity
	
	return instance

# Resets the instance and returns it to its respective pool for reuse
func release_instance(type_id: String, instance: PoolableEntity) -> void:
	if not _active_pools.has(type_id):
		push_error("PoolManager: Cannot release instance to unknown type_id '%s'" % type_id)
		instance.queue_free()
		return
	
	if instance.get_parent():
		instance.get_parent().remove_child(instance)
	
	instance.position = Vector2.ZERO
	instance.deactivate()
	
	_active_pools[type_id].append(instance)
