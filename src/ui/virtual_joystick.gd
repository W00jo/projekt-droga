# Virtual joystick for touchscreen devices
# Emulates Input Map actions (move_up, move_down, move_left, move_right) so that
# existing player scripts (PlayerWASD) respond identically to keyboard and touch
#
# Uses _input() rather than _unhandled_input() because the joystick is a global
# UI overlay that must intercept touch events before they propagate to gameplay
# nodes underneath. This prevents accidental movement triggers on the game layer
class_name VirtualJoystick
extends Control

# Radius in pixels that defines the maximum travel distance of the knob
const KNOB_RADIUS: float = 64.0

# Analogue dead zone as a fraction of KNOB_RADIUS (below this, no action fires)
const DEAD_ZONE: float = 0.2

# Duration of the fade animation when switching between touch and keyboard modes
const FADE_DURATION: float = 0.2

# Default resting position for the joystick (bottom-left corner with margin)
const DEFAULT_MARGIN: Vector2 = Vector2(100.0, -100.0)

# Unique device ID used by the joystick to isolate its inputs from physical hardware
const VIRTUAL_DEVICE_ID: int = 67

# The touch index currently driving this joystick (-1 when idle)
var _active_touch_index: int = -1

# Cached reference to the visibility tween to prevent overlapping animations
var _fade_tween: Tween

@onready var _base: TextureRect = $Base
@onready var _knob: TextureRect = $Knob

# Injected reference to the player character to determine active state
var _player: PlayerWASD

# Tracks the current primary input method
var _using_touch_controls: bool = false

# Tracks the local activation state to prevent redundant visibility updates
var _player_active: bool = false

# Tracks actions currently being simulated by the joystick
var _simulated_actions: Array[StringName] = []

func _ready() -> void:
	# Initialise visibility instantly without animation to prevent initial pop-in
	modulate.a = 0.0
	visible = false

	# Position the joystick at the designated resting location
	_reset_to_default_position()

	# Retrieve the player reference dynamically from the scene owner
	if owner and "player" in owner:
		_player = owner.player

	# Set the initial control scheme based on the hardware environment
	_using_touch_controls = DisplayServer.is_touchscreen_available()

func _process(_delta: float) -> void:
	# Monitor the authoritative player state and trigger updates only upon change
	var current_player_active: bool = is_instance_valid(_player) and _player.is_active
	if current_player_active != _player_active:
		_player_active = current_player_active
		_evaluate_visibility()

func _input(event: InputEvent) -> void:
	# If the player is inactive, the joystick ignores all global input events
	if not _player_active:
		return

	# Transition to touch controls upon detecting any touchscreen interaction
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		if not _using_touch_controls:
			_using_touch_controls = true
			_evaluate_visibility()

	# Transition to keyboard controls upon detecting any keyboard interaction
	elif event is InputEventKey:
		if _using_touch_controls:
			_using_touch_controls = false
			_evaluate_visibility()

	# Touch controls handling
	if event is InputEventScreenTouch:
		# Lock onto the first touch event and ignore subsequent multi-touch inputs
		if event.pressed and _active_touch_index == -1:
			_active_touch_index = event.index
			
			# Relocate the entire joystick assembly directly beneath the user's finger
			var half_base: Vector2 = _base.size * 0.5
			_base.global_position = event.position - half_base
			_knob.global_position = event.position - _knob.size * 0.5
			
		# Reset the joystick when the tracked finger is lifted
		elif not event.pressed and event.index == _active_touch_index:
			_release()

	elif event is InputEventScreenDrag:
		# Ignore drag events from fingers other than the one controlling the joystick
		if event.index != _active_touch_index:
			return

		# Calculate the distance between the finger and the centre of the joystick base
		var base_centre: Vector2 = _base.global_position + _base.size * 0.5
		var offset: Vector2 = event.position - base_centre

		# Restrict the knob's movement to the defined circular boundary
		if offset.length() > KNOB_RADIUS:
			offset = offset.normalized() * KNOB_RADIUS

		# Update the visual position of the knob
		_knob.global_position = base_centre + offset - _knob.size * 0.5

		# Translate the physical offset into a normalised directional vector
		var strength: Vector2 = offset / KNOB_RADIUS
		_apply_input(strength)

# Centralised visibility state machine enforcing architectural constraints
func _evaluate_visibility() -> void:
	if _player_active and _using_touch_controls:
		_fade_in()
	else:
		_fade_out()

# Dispatches a simulated action to the event system on a dedicated virtual device
# Allows native input merging to prevent the joystick from overriding physical keys
func _send_action_event(action: StringName, pressed: bool, strength: float = 0.0) -> void:
	var event := InputEventAction.new()
	event.device = VIRTUAL_DEVICE_ID
	event.action = action
	event.pressed = pressed
	event.strength = strength
	Input.parse_input_event(event)

# Translates the joystick vector into virtual key presses that the Input Map
# recognises identically to physical keyboard or gamepad input
func _apply_input(strength: Vector2) -> void:
	# Release all previously simulated directions first to avoid ghosting
	_release_all_actions()

	if strength.length() < DEAD_ZONE:
		return

	# Horizontal axis
	if strength.x > DEAD_ZONE:
		_send_action_event("move_right", true, strength.x)
		_simulated_actions.append("move_right")
	elif strength.x < -DEAD_ZONE:
		_send_action_event("move_left", true, -strength.x)
		_simulated_actions.append("move_left")

	# Vertical axis
	if strength.y > DEAD_ZONE:
		_send_action_event("move_down", true, strength.y)
		_simulated_actions.append("move_down")
	elif strength.y < -DEAD_ZONE:
		_send_action_event("move_up", true, -strength.y)
		_simulated_actions.append("move_up")

# Centres the knob back on the base and releases all emulated actions
func _release() -> void:
	_active_touch_index = -1
	_knob.global_position = _base.global_position + (_base.size - _knob.size) * 0.5
	_release_all_actions()

func _release_all_actions() -> void:
	# Dispatch release events only for actions that this virtual device pressed
	for action in _simulated_actions:
		_send_action_event(action, false)
	_simulated_actions.clear()

# Positions the joystick at the bottom-left corner of the viewport
func _reset_to_default_position() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var base_half: Vector2 = _base.size * 0.5
	_base.global_position = Vector2(
		DEFAULT_MARGIN.x - base_half.x,
		viewport_size.y + DEFAULT_MARGIN.y - base_half.y
	)
	_knob.global_position = _base.global_position + (_base.size - _knob.size) * 0.5

# Smoothly fades the joystick into view
func _fade_in() -> void:
	visible = true
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)

# Smoothly fades the joystick out and releases all actions
func _fade_out() -> void:
	_release()
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	await _fade_tween.finished
	if not is_instance_valid(self) or not is_inside_tree():
		return
	visible = false
	_reset_to_default_position()
