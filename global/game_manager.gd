extends Node

enum GameState {
	INACTIVE,     # The run hasn't started
	ACCELERATING, # The run begins; the player is building up to the target speed
	RUNNING,      # The player is at the target speed; obstacles and enemies spawn normally
	COASTING,     # The player has reached the target distance
	DECELERATING, # The player is slowing down to the bus stop
	FAILED        # The timer has run out before reaching the target distance
}

signal state_changed(new_state: GameState)
signal speed_changed(new_speed: float)
signal time_updated(new_time: float)
signal time_deducted(amount: float)
signal currency_updated(new_currency: float)

# Emitted with the raw distance values for numerical displays or debugging
signal distance_updated(current_distance: float, target_distance: float)
# Emitted with a normalised value (0.0 to 1.0), suitable for driving a progress bar
signal progress_updated(progress_ratio: float)

var current_state: GameState = GameState.INACTIVE
var current_scroll_speed: float = 0.0
var target_scroll_speed: float = 600.0
var acceleration_rate: float = 150.0

var current_time: float = 300.0
var current_currency: float = 50.0

# Conversion factor translating raw pixel speed into logical distance units (metres)
# At target_scroll_speed = 400.0 px/s, the player covers 8.0 metres per second (400 / 50)
# 8.0 m/s equals roughly 28.8 km/h, approximating realistic human sprinting speed
const PIXELS_PER_METRE: float = 50.0

var distance_travelled: float = 0.0
# The required distance (in logical distance units/metres) to reach the bus stop and complete the run
var target_distance: float = 300.0

var main_scene: MainScene

var level: LevelManager

func _process(delta: float) -> void:
	_handle_movement_state(delta)
	_process_time(delta)

func _process_time(delta: float) -> void:
	# Only count down time during an active run; the clock is frozen once
	# the player has won (DECELERATING) or lost (FAILED)
	if current_state in [GameState.ACCELERATING, GameState.RUNNING]:
		if current_time > 0.0:
			current_time = max(0.0, current_time - delta)
			time_updated.emit(current_time)

		# Failure condition: the timer has expired before the player covered
		# the required distance, meaning the bus was not reached in time
		if current_time <= 0.0 and distance_travelled < target_distance:
			change_state(GameState.FAILED)

func _handle_movement_state(delta: float) -> void:
	match current_state:
		GameState.ACCELERATING:
			current_scroll_speed = move_toward(current_scroll_speed, target_scroll_speed, acceleration_rate * delta)
			speed_changed.emit(current_scroll_speed)

			# Transition: the player has reached cruising speed
			if is_equal_approx(current_scroll_speed, target_scroll_speed):
				change_state(GameState.RUNNING)

		GameState.RUNNING:
			_update_distance(delta)

			# Win condition: the player has reached or exceeded the required distance
			if distance_travelled >= target_distance:
				change_state(GameState.COASTING)

		GameState.COASTING:
			while not level.active_obstacles.is_empty() or not level.active_enemies.is_empty():
				await get_tree().create_timer(0.1).timeout
			change_state(GameState.DECELERATING)

		GameState.DECELERATING:
			current_scroll_speed = move_toward(current_scroll_speed, 0.0, acceleration_rate * delta)
			speed_changed.emit(current_scroll_speed)

		GameState.FAILED:
			# Decelerate at triple the normal rate to convey urgency
			current_scroll_speed = move_toward(current_scroll_speed, 0.0, (acceleration_rate * 3) * delta)
			speed_changed.emit(current_scroll_speed)

# Accumulates distance covered this frame and emits progress signals
func _update_distance(delta: float) -> void:
	if current_scroll_speed > 0.0:
		# Convert pixel velocity to logical metres before accumulating
		distance_travelled += (current_scroll_speed / PIXELS_PER_METRE) * delta

		# Clamp to 1.0 to prevent overflow if the player slightly overshoots the target
		var ratio: float = clampf(distance_travelled / target_distance, 0.0, 1.0)

		distance_updated.emit(distance_travelled, target_distance)
		progress_updated.emit(ratio)

func change_state(new_state: GameState) -> void:
	if current_state != new_state:
		current_state = new_state
		state_changed.emit(current_state)

func deduct_currency(amount: float) -> void:
	current_currency = max(0.0, current_currency - amount)
	currency_updated.emit(current_currency)

func deduct_time(amount: float) -> void:
	current_time = max(0.0, current_time - amount)
	time_updated.emit(current_time)
	time_deducted.emit(amount)
