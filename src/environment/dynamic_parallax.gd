# Manages the scrolling speed of all Parallax2D layers based on the global treadmill speed
# Each layer receives a depth-appropriate fraction of the base velocity
class_name DynamicParallax
extends Node2D

@export var speed_scale: float = 1.0

# References to the parallax layers, ordered from the furthest background to the closest foreground
@export var layer_sky: Parallax2D
@export var layer_forest_far: Parallax2D
@export var layer_forest_near: Parallax2D
@export var layer_field: Parallax2D
@export var layer_items: Parallax2D
@export var layer_houses: Parallax2D
@export var layer_fence: Parallax2D
@export var layer_grass: Parallax2D

# Parallax multipliers to create a depth effect through differential scrolling
# Layers further from the camera move slower; the foreground matches the track speed
const MULTIPLIER_SKY: float = 0.1   # E.g., Sky
const MULTIPLIER_FOREST_FAR: float = 0.15  # Darker forest on the horizon
const MULTIPLIER_FOREST_NEAR: float = 0.25 # Lighter forest on the horizon
const MULTIPLIER_FIELD: float = 0.45       # Field and bushes
const MULTIPLIER_ITEMS: float = 0.75       # E.g., buildings, trees, tractors etc.
const MULTIPLIER_HOUSES: float = 0.75      # Houses
const MULTIPLIER_FENCE: float = 1.0        # Fences and very near items
const MULTIPLIER_GRASS: float = 1.0        # Grass in the front

func _process(_delta: float) -> void:
	# Read the current treadmill speed from the global state
	var base_speed: float = GameManager.current_scroll_speed * speed_scale
	
	# Update the autoscroll property for each layer
	# We use negative values because the background must move left to simulate forward motion
	layer_sky.autoscroll.x = -base_speed * MULTIPLIER_SKY
	layer_forest_far.autoscroll.x = -base_speed * MULTIPLIER_FOREST_FAR
	layer_forest_near.autoscroll.x = -base_speed * MULTIPLIER_FOREST_NEAR
	layer_field.autoscroll.x = -base_speed * MULTIPLIER_FIELD
	layer_items.autoscroll.x = -base_speed * MULTIPLIER_ITEMS
	layer_houses.autoscroll.x = -base_speed * MULTIPLIER_HOUSES
	layer_fence.autoscroll.x = -base_speed * MULTIPLIER_FENCE
	layer_grass.autoscroll.x = -base_speed * MULTIPLIER_GRASS
