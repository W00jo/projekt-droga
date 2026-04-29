# Manages the scrolling speed of all Parallax2D layers based on the global treadmill speed
# Each layer receives a depth-appropriate fraction of the base velocity
class_name DynamicParallax
extends Node2D

@export var speed_scale: float = 1.0

# References to the parallax layers, ordered from the furthest background to the closest foreground
@export var layer_far_background: Parallax2D
@export var layer_mid_background: Parallax2D
@export var layer_near_background: Parallax2D
@export var layer_foreground: Parallax2D

# Parallax multipliers to create a depth effect through differential scrolling
# Layers further from the camera move slower; the foreground matches the track speed
const MULTIPLIER_FAR_BACKGROUND: float = 0.1   # E.g., Sky
const MULTIPLIER_MID_BACKGROUND: float = 0.25  # E.g., Horizon/Mountains
const MULTIPLIER_NEAR_BACKGROUND: float = 0.75 # E.g., Grass/Hills
const MULTIPLIER_FOREGROUND: float = 1.0       # E.g., Fence/Trees next to the road

func _process(_delta: float) -> void:
	# Read the current treadmill speed from the global state
	var base_speed: float = GameManager.current_scroll_speed * speed_scale
	
	# Update the autoscroll property for each layer
	# We use negative values because the background must move left to simulate forward motion
	if layer_far_background:
		layer_far_background.autoscroll.x = -base_speed * MULTIPLIER_FAR_BACKGROUND
	if layer_mid_background:
		layer_mid_background.autoscroll.x = -base_speed * MULTIPLIER_MID_BACKGROUND
	if layer_near_background:
		layer_near_background.autoscroll.x = -base_speed * MULTIPLIER_NEAR_BACKGROUND
	if layer_foreground:
		layer_foreground.autoscroll.x = -base_speed * MULTIPLIER_FOREGROUND
