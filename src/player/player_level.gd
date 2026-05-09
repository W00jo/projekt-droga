# Handles the player's lane-switching movement, delegating spatial queries
# to the LevelManager and smoothing transitions with Tween animations
class_name Player
extends Area2D

# The lane index the player is currently occupying (1-based, starting from top)
var current_track: int = 2

# Reference to the parent LevelManager for track position lookups
@onready var level_manager: LevelManager = get_parent() as LevelManager

# Reference to the active tween to prevent animation overlap during rapid inputs
var _movement_tween: Tween

func _ready() -> void:
	# Snap to the starting track position without animation on first load
	position.y = level_manager.get_track_position_y(current_track)
	z_index = current_track

func _process(_delta: float) -> void:
	# Block input when the run has concluded
	var state: GameManager.GameState = GameManager.current_state
	if state == GameManager.GameState.DECELERATING or state == GameManager.GameState.FAILED:
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
		
		if _movement_tween and _movement_tween.is_running():
			_movement_tween.kill()
			
		# Tween the Y position with a SINE ease-out for smooth deceleration
		_movement_tween = create_tween()
		_movement_tween.tween_property(self, "position:y", target_y, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		z_index = current_track
