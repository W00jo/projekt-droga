extends Node

# Dictionary mapping biome names to their specific obstacle configurations
var _biome_obstacle_configs: Dictionary = {
	"countryside": [
		"res://src/obstacles/cars/car_red.png",
		"res://src/obstacles/cars/car_blue.png",
		"res://src/obstacles/cars/car_green.png"
	],
	"city": [
		"res://src/obstacles/cars/car_orange.png",
		"res://src/obstacles/cars/car_yellow.png",
		"res://src/obstacles/cars/car_beige.png"
	]
}

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

# Cache for preloaded textures to avoid stuttering during gameplay
var _loaded_textures: Dictionary = {}

# Active pools mapping type_id to an Array of PoolableObstacle
var _active_pools: Dictionary = {}

func _ready() -> void:
	_preload_textures()
	_initialise_pools()

func _preload_textures() -> void:
	for biome in _biome_obstacle_configs.keys():
		_loaded_textures[biome] = []
		var paths: Array = _biome_obstacle_configs[biome]
		for path in paths:
			var texture: Texture2D = load(path) as Texture2D
			if texture:
				_loaded_textures[biome].append(texture)

func _initialise_pools() -> void:
	for type_id in _pool_configs.keys():
		_active_pools[type_id] = []
		var config: Dictionary = _pool_configs[type_id]
		var scene: PackedScene = config.get("scene") as PackedScene
		var size: int = config.get("initial_size", 5) as int
		
		if scene:
			for i in range(size):
				var instance: PoolableObstacle = scene.instantiate() as PoolableObstacle
				if instance:
					_active_pools[type_id].append(instance)

# Retrieves an instance from the specified pool and configures it for the given biome
func get_instance(type_id: String, biome: String = "countryside") -> PoolableObstacle:
	if not _active_pools.has(type_id):
		push_error("PoolManager: No pool configured for type_id '%s'" % type_id)
		return null
		
	var pool: Array = _active_pools[type_id]
	var instance: PoolableObstacle
	
	if pool.is_empty():
		var config: Dictionary = _pool_configs[type_id]
		var scene: PackedScene = config.get("scene") as PackedScene
		instance = scene.instantiate() as PoolableObstacle
	else:
		instance = pool.pop_back() as PoolableObstacle
		
	# Only apply biome textures for the generic "obstacle" type
	# Other poolable types (e.g., dog) rely on their own internal setup
	if type_id == "obstacle":
		_configure_obstacle_biome(instance, biome)
	else:
		instance.setup(null)
		
	return instance

# Resets the instance and returns it to its respective pool for reuse
func release_instance(type_id: String, instance: PoolableObstacle) -> void:
	if not _active_pools.has(type_id):
		push_error("PoolManager: Cannot release instance to unknown type_id '%s'" % type_id)
		instance.queue_free()
		return
		
	if instance.get_parent():
		instance.get_parent().remove_child(instance)
	
	instance.position = Vector2.ZERO
	instance.visible = false
	instance.is_active = false
	instance.disable_collision()
		
	_active_pools[type_id].append(instance)

func _configure_obstacle_biome(instance: PoolableObstacle, biome: String) -> void:
	var textures: Array = _loaded_textures.get(biome, _loaded_textures.get("countryside", []))
	if not textures.is_empty():
		var random_texture: Texture2D = textures.pick_random()
		instance.setup(random_texture)
	else:
		instance.setup(null)
