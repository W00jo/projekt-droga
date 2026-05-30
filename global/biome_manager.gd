extends Node

# Atlas coordinates mapped from the road_tileset.tres
# These define the exact graphical pieces used to construct the seamless track
const TILE_SIDEWALK: Vector2i = Vector2i(1, 2)
const TILE_ROAD_TOP: Vector2i = Vector2i(0, 1)
const TILE_ROAD_BOTTOM: Vector2i = Vector2i(0, 2)
const TILE_DIRT_LEFT: Vector2i = Vector2i(0, 0)
const TILE_DIRT_MID: Vector2i = Vector2i(1, 0)
const TILE_DIRT_RIGHT: Vector2i = Vector2i(2, 0)

# Configuration for procedural dirt shoulder generation
const DIRT_SPAWN_PROBABILITY: float = 0.05
const DIRT_MIN_TILES: int = 3
const DIRT_MAX_TILES: int = 8

# State variables to track continuous features across multiple chunk generations
# This ensures that a dirt section smoothly spans across chunk boundaries
var _is_in_dirt_section: bool = false
var _dirt_tiles_left: int = 0

var current_biome: String = "countryside"

# Clears internal state so consecutive runs don't inherit lingering features (like dirt shoulders)
func reset_biome() -> void:
	_is_in_dirt_section = false
	_dirt_tiles_left = 0

# Generates a 2D array (columns of lanes) representing the tile layout for a single chunk
func get_chunk_layout(width_in_tiles: int, number_of_lanes: int) -> Array:
	var layout: Array = []
	
	for x in range(width_in_tiles):
		var column: Array = []
		
		# Top lane (Y=0) dynamically transitions between paved sidewalk and
		# dirt shoulder using a stateful approach that spans across chunk boundaries
		var top_lane_tile: Vector2i = TILE_SIDEWALK
		
		if _is_in_dirt_section:
			# Continue the dirt section if we have more than 1 tile remaining
			if _dirt_tiles_left > 1:
				top_lane_tile = TILE_DIRT_MID
				_dirt_tiles_left -= 1
			# Cap off the dirt section with the right-edge transition tile
			elif _dirt_tiles_left == 1:
				top_lane_tile = TILE_DIRT_RIGHT
				_is_in_dirt_section = false
				_dirt_tiles_left = 0
		else:
			# Chance per tile to begin a new dirt section while on the sidewalk
			if randf() < DIRT_SPAWN_PROBABILITY:
				_is_in_dirt_section = true
				# Total length of the dirt shoulder
				_dirt_tiles_left = randi_range(DIRT_MIN_TILES, DIRT_MAX_TILES)
				# Start the section with the left-edge transition tile
				top_lane_tile = TILE_DIRT_LEFT
			else:
				top_lane_tile = TILE_SIDEWALK
		
		# Assemble the column top-to-bottom
		for y in range(number_of_lanes):
			var tile_coords: Vector2i = TILE_SIDEWALK
			
			if y == 0:
				tile_coords = top_lane_tile
			elif y == 1:
				# The upper half of the asphalt road
				tile_coords = TILE_ROAD_TOP
			elif y == 2:
				# The lower half of the asphalt road
				tile_coords = TILE_ROAD_BOTTOM
			elif y == 3:
				# The bottom shoulder is strictly paved for now
				tile_coords = TILE_SIDEWALK
				
			column.append(tile_coords)
			
		layout.append(column)
		
	return layout
