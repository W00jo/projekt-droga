# ProceduralChunk acts as a lightweight, reusable container for a specific segment of the road
# It delegates the "rules" of the layout to the BiomeManager and only handles the physical painting
class_name ProceduralChunk
extends Node2D

@onready var tile_map_layer: TileMapLayer = $TileMapLayer

# The source ID of the atlas within the TileSet, must match the
# sources/N key defined in road_tileset.tres (currently sources/1)
const TILE_SOURCE_ID: int = 1

# Clears the previous tile configuration and paints a new layout based on the provided 2D array
# This enables Object Pooling, as we can recycle old chunks by repainting them with new data
func paint_chunk(chunk_data: Array) -> void:
	tile_map_layer.clear()
	var width: int = chunk_data.size()
	
	for x in range(width):
		var column: Array = chunk_data[x]
		var lanes: int = column.size()
		
		for y in range(lanes):
			var atlas_coords: Vector2i = column[y]
			tile_map_layer.set_cell(Vector2i(x, y), TILE_SOURCE_ID, atlas_coords)
