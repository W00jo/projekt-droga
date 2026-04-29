# Handles the player's lane-switching movement, delegating spatial queries
# to the LevelManager and smoothing transitions with Tween animations
extends Area2D

# The lane index the player is currently occupying (1-based, starting from top)
var current_track: int = 2

# Reference to the parent LevelManager for track position lookups
@onready var level_manager: LevelManager = get_parent() as LevelManager

func _ready() -> void:
	# Snap to the starting track position without animation on first load
	if level_manager:
		position.y = level_manager.get_track_position_y(current_track)
		z_index = current_track

func _process(_delta: float) -> void:
	# Block input when the LevelManager is missing or the run has ended
	if not level_manager or GameManager.current_state == GameManager.GameState.DECELERATING:
		return
		
	if Input.is_action_just_pressed("move_up"):
		_move_to_track(current_track - 1)
	if Input.is_action_just_pressed("move_down"):
		_move_to_track(current_track + 1)

# Smoothly transitions the player from the current lane to the target lane
func _move_to_track(target_track: int) -> void:
	# Clamp to valid track range to prevent the player from leaving the roadway
	target_track = clampi(target_track, 1, level_manager.TRACK_COUNT)
	
	if target_track != current_track:
		current_track = target_track
		var target_y: float = level_manager.get_track_position_y(current_track)
		
		# Tween the Y position with a SINE ease-out for smooth deceleration
		var tween: Tween = create_tween()
		tween.tween_property(self, "position:y", target_y, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		z_index = current_track
