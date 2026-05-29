# Handles the player's lane-switching movement, delegating spatial queries
# to the LevelManager and smoothing transitions with Tween animations
class_name Player
extends Area2D

# The lane index the player is currently occupying (1-based, starting from top)
var current_track: int = 2

var stunned: bool = false

# Reference to the parent LevelManager for track position lookups
@onready var level_manager: LevelManager = get_parent() as LevelManager

@export var invincibility_animation: AnimationPlayer
@export var collision: CollisionShape2D

# Minimum vertical drag distance (in pixels) required to register a swipe
const SWIPE_THRESHOLD: float = 30.0

const FLASH_ANIM_FINAL_SPEED: float = 1.0

# Reference to the active tween to prevent animation overlap during rapid inputs
var _movement_tween: Tween

# Tracks whether the current touch gesture has already triggered a lane change,
# preventing a single long swipe from jumping multiple lanes at once
var _swipe_consumed: bool = false

# Tracks the starting Y position of a swipe gesture
var _swipe_start_y: float = 0.0
var _swipe_active: bool = false

func _ready() -> void:
	# Snap to the starting track position without animation on first load
	position.y = level_manager.get_track_position_y(current_track)
	z_index = current_track + 1

# Uses _unhandled_input instead of _input so that UI elements (buttons, menus,
# the virtual joystick) consume their touch events first. Only events that no
# UI node has claimed will reach this function, preventing accidental lane
# changes when the player taps a HUD button or interacts with the joystick
func _unhandled_input(event: InputEvent) -> void:
	# Block all input when the run has concluded or the player is stunned
	var state: GameManager.GameState = GameManager.current_state
	if state in [GameManager.GameState.DECELERATING, GameManager.GameState.FAILED, GameManager.GameState.ARRIVED] or stunned:
		return

	# Keyboard and gamepad: respond to mapped actions from the Input Map
	if event.is_action_pressed("move_up"):
		_move_to_track(current_track - 1)
	elif event.is_action_pressed("move_down"):
		_move_to_track(current_track + 1)

	# Touchscreen swipe: capture the start position when the finger touches
	elif event is InputEventScreenTouch:
		if event.pressed:
			_swipe_start_y = event.position.y
			_swipe_active = true
			_swipe_consumed = false
		else:
			# Finger lifted, reset swipe state
			_swipe_active = false
			_swipe_consumed = false

	# Touchscreen swipe: detect vertical drags that exceed the threshold
	elif event is InputEventScreenDrag:
		if _swipe_active and not _swipe_consumed:
			var swipe_distance: float = event.position.y - _swipe_start_y
			if absf(swipe_distance) > SWIPE_THRESHOLD:
				if swipe_distance < 0.0:
					_move_to_track(current_track - 1)
				else:
					_move_to_track(current_track + 1)
				_swipe_consumed = true

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
		
		z_index = current_track + 1

func force_track_change(target_track: int) -> void:
	_move_to_track(target_track)

# Makes the player unable to move for a certain duration
func stun(stun_time: float) -> void:
	stunned = true

	await get_tree().create_timer(stun_time).timeout
	if not is_instance_valid(self) or not is_inside_tree():
		return

	stunned = false
	
# Makes the player invincible for a certain duration
func invincibility(duration: float) -> void:
	collision.set_deferred("disabled",true)
	invincibility_animation.speed_scale = 5.0
	invincibility_animation.play("i_frame")
	var _anim_tween: Tween = create_tween()
	_anim_tween.tween_property(invincibility_animation, "speed_scale", FLASH_ANIM_FINAL_SPEED, duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await _anim_tween.finished
	if not is_instance_valid(self) or not is_inside_tree():
		return

	invincibility_animation.stop()
	collision.set_deferred("disabled",false)
