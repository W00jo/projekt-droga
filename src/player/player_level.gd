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
@export var sprite_animation: AnimationPlayer

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

func _process(_delta: float) -> void:
	if sprite_animation.current_animation == "run":
		# The run animation remains at standard speed until we reach the bus stop
		if GameManager.current_state == GameManager.GameState.DECELERATING:
			var speed_ratio: float = GameManager.current_scroll_speed / GameManager.target_scroll_speed
			
			# Transition to the exhausted animation early so the player slides to a halt naturally
			if speed_ratio < 0.2:
				sprite_animation.play("stop")
				sprite_animation.speed_scale = 1.0
			else:
				# Scale down the animation to match the background slowing down
				sprite_animation.speed_scale = max(0.1, speed_ratio)
		else:
			sprite_animation.speed_scale = 1.0
	else:
		sprite_animation.speed_scale = 1.0

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

var _invincibility_tween: Tween

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
	var state: GameManager.GameState = GameManager.current_state
	if state in [GameManager.GameState.DECELERATING, GameManager.GameState.FAILED, GameManager.GameState.ARRIVED]:
		return
		
	if _invincibility_tween and _invincibility_tween.is_valid():
		_invincibility_tween.kill()
		
	collision.set_deferred("disabled", true)
	invincibility_animation.speed_scale = 5.0
	invincibility_animation.play("i_frame")
	_invincibility_tween = create_tween()
	_invincibility_tween.tween_property(invincibility_animation, "speed_scale", FLASH_ANIM_FINAL_SPEED, duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await _invincibility_tween.finished
	if not is_instance_valid(self) or not is_inside_tree():
		return

	cancel_invincibility()

func cancel_invincibility() -> void:
	if _invincibility_tween and _invincibility_tween.is_valid():
		_invincibility_tween.kill()
	
	invincibility_animation.stop()
	# Applying the RESET animation manually immediately updates all tracks to default values
	invincibility_animation.play("RESET")
	invincibility_animation.advance(0)
	
	var state: GameManager.GameState = GameManager.current_state
	if state not in [GameManager.GameState.DECELERATING, GameManager.GameState.FAILED, GameManager.GameState.ARRIVED]:
		collision.set_deferred("disabled", false)

# Fully resets the player's position, state, and cleans up any running tweens
func reset_player() -> void:
	if _movement_tween and _movement_tween.is_valid():
		_movement_tween.kill()
		
	cancel_invincibility()

	_swipe_active = false
	_swipe_consumed = false
	current_track = 2
	position = Vector2(285, level_manager.get_track_position_y(current_track))
	z_index = current_track + 1
	stunned = false
	visible = true
	collision.set_deferred("disabled", false)
	
	sprite_animation.play("run")
	sprite_animation.speed_scale = 1.0
