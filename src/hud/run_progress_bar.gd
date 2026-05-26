# Updates the progress bar and a child anchor point to sync the player sprite with the fill level
class_name RunProgressBar
extends ProgressBar

# The anchor node that will be moved along the progress bar
# An AnimatedSprite2D or Sprite2D should be placed inside this Control
@export var player_sprite_anchor: Control

func _ready() -> void:
	value = 0.0
	GameManager.progress_updated.connect(_on_progress_updated)

func _on_progress_updated(progress_ratio: float) -> void:
	# Convert the 0.0 - 1.0 ratio to the ProgressBar's configured value range
	value = min_value + (max_value - min_value) * progress_ratio
	
	# Update the anchor's horizontal position to match the fill edge
	# By shifting it back by half its own width, we centre the anchor precisely on the threshold
	player_sprite_anchor.position.x = (size.x * progress_ratio) - (player_sprite_anchor.size.x / 2.0)
