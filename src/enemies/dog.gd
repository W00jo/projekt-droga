# Enemy that follows the player and retreats after a fixed number of attacks or
# after colliding with an obstacle
class_name Dog
extends PoolableEntity

enum DogState {
	INACTIVE,
	APPROACHING,
	FOLLOWING,
	ATTACKING,
	RETREATING,
	DEFEATED
}

var current_state: DogState = DogState.INACTIVE

signal state_changed(new_state: DogState)

var id: int

var delay_timer: Timer = Timer.new()
var current_track: int = 2
var attack_cooldown: Timer = Timer.new()
var attack_counter: int = 0

const FOLLOWING_POS_X: float = 227.0
const OFFSCREEN_POS_X: float = -200.0
const MOVEMENT_DELAY: float = 0.25

const ATTACK_LUNGE_DISTANCE: float = 120.0
const ATTACK_LUNGE_DURATION: float = 0.3
const ATTACK_COOLDOWN: float = 5.0
const MAX_ATTACK_COUNT: int = 3
const TIME_PENALTY: float = 8.0
const INVINCIBILITY_DURATION: float = 5.0

const WARNING_START_POS_X: float = 300.0
const FLASH_ANIM_DURATION: float = 5.0
const FLASH_ANIM_FINAL_SPEED: float = 7.0

@onready var level_manager: LevelManager = get_parent().get_parent() as LevelManager
@onready var player: Player = level_manager.get_node("PlayerLevel") as Player
@onready var enemy_spawner: EnemySpawner = level_manager.get_node("EnemySpawner") as EnemySpawner

@export var texture_variants: Array[Texture2D] = [preload("res://src/enemies/dog_dark_sheet.png"),preload("res://src/enemies/dog_light_sheet.png")]
@export var dog_sprite: Sprite2D
@export var warning_sprite: Sprite2D
@export var animation: AnimationPlayer
@export var collision: CollisionShape2D

var _movement_tween_y_axis: Tween
var _movement_tween_x_axis: Tween
var _anim_tween: Tween

func _ready() -> void:
	add_child(delay_timer)
	delay_timer.timeout.connect(_on_delay_timer_timeout)
	delay_timer.wait_time = MOVEMENT_DELAY

	add_child(attack_cooldown)
	attack_cooldown.timeout.connect(attack_cooldown.stop)
	attack_cooldown.wait_time = ATTACK_COOLDOWN

	state_changed.connect(enemy_spawner.manage_enemies.bind(self))

func start_approach_sequence() -> void:
	change_state(DogState.APPROACHING)
	position.x = OFFSCREEN_POS_X
	position.y = level_manager.get_track_position_y(current_track)
	z_index = current_track

	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()

	warning_sprite.position.x = WARNING_START_POS_X
	warning_sprite.visible = true
	_anim_tween = create_tween()
	animation.play("warning_flash")
	_anim_tween.tween_property(animation, "speed_scale", FLASH_ANIM_FINAL_SPEED, FLASH_ANIM_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await _anim_tween.finished
	if not is_instance_valid(self) or not is_inside_tree():
		return

	warning_sprite.visible = false

	animation.speed_scale = 1.0
	animation.play("dog_running")
	dog_sprite.texture = texture_variants.pick_random()
	_movement_tween_x_axis = create_tween()
	_movement_tween_x_axis.tween_property(self, "position:x", FOLLOWING_POS_X, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await _movement_tween_x_axis.finished
	if not is_instance_valid(self) or not is_inside_tree():
		return

	change_state(DogState.FOLLOWING)
	collision.set_deferred("disabled", false)

	attack_counter = 0
	attack_cooldown.start()

func _process(delta: float) -> void:
	match current_state:
		DogState.APPROACHING:
			if current_track != player.current_track and delay_timer.is_stopped():
				delay_timer.start()
			if GameManager.current_state != GameManager.GameState.RUNNING and warning_sprite.visible:
				deactivate()
				change_state(DogState.INACTIVE)

		DogState.FOLLOWING:
			if attack_counter >= MAX_ATTACK_COUNT or GameManager.current_state != GameManager.GameState.RUNNING:
				_retreat()
			elif is_equal_approx(position.y, level_manager.get_track_position_y(player.current_track)) and attack_cooldown.is_stopped():
				_attack()
			elif current_track != player.current_track and delay_timer.is_stopped():
				delay_timer.start()

		DogState.ATTACKING:
			if GameManager.current_state != GameManager.GameState.RUNNING:
				_retreat()

# Scrolls the enemy at global speed then deactivates it after it leaves the viewport 
		DogState.DEFEATED:
			position.x -= GameManager.current_scroll_speed * delta
			if position.x <= OFFSCREEN_POS_X:
				deactivate()
				change_state(DogState.INACTIVE)

# Checks if the enemy is still on a different track than the player
# and that it is in a state that allows for following the player after the movement delay timer timeout
func _on_delay_timer_timeout() -> void:
	if current_track != player.current_track and current_state in [DogState.FOLLOWING, DogState.APPROACHING]:
		if player.current_track >= current_track:
			_move_to_track(current_track + 1)
		else:
			_move_to_track(current_track - 1)
	delay_timer.stop()

# Makes the enemy lunge forward on the horizontal axis
# Increments the attack counter and starts the attack cooldown timer
func _attack() -> void:
	change_state(DogState.ATTACKING)
	player.stun(ATTACK_LUNGE_DURATION * 2)

	_movement_tween_x_axis = create_tween()
	_movement_tween_x_axis.tween_property(self, "position:x", FOLLOWING_POS_X + ATTACK_LUNGE_DISTANCE, ATTACK_LUNGE_DURATION).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await _movement_tween_x_axis.finished
	if not is_instance_valid(self) or not is_inside_tree():
		return

	_movement_tween_x_axis = create_tween()
	_movement_tween_x_axis.tween_property(self, "position:x", FOLLOWING_POS_X, ATTACK_LUNGE_DURATION).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await _movement_tween_x_axis.finished
	if not is_instance_valid(self) or not is_inside_tree():
		return

	attack_counter += 1
	attack_cooldown.start()
	change_state(DogState.FOLLOWING)

# Makes the enemy move offscreen on the horizontal axis then deactivates it
func _retreat() -> void:
	change_state(DogState.RETREATING)
	disable_collision()
	if _movement_tween_x_axis and _movement_tween_x_axis.is_running():
		_movement_tween_x_axis.kill()

	_movement_tween_x_axis = create_tween()
	_movement_tween_x_axis.tween_property(self, "position:x", OFFSCREEN_POS_X, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await _movement_tween_x_axis.finished
	if not is_instance_valid(self) or not is_inside_tree():
		return
	
	deactivate()
	change_state(DogState.INACTIVE)

# Smoothly transitions the enemy from the current lane to the target lane
func _move_to_track(target_track: int) -> void:
	# Clamp to valid track range to prevent the enemy from leaving the roadway
	target_track = clampi(target_track, 1, level_manager.TRACK_COUNT)

	if target_track != current_track:
		current_track = target_track
		var target_y: float = level_manager.get_track_position_y(current_track)

		if _movement_tween_y_axis and _movement_tween_y_axis.is_running():
			_movement_tween_y_axis.kill()

		# Tween the Y position with a SINE ease-out for smooth deceleration
		_movement_tween_y_axis = create_tween()
		_movement_tween_y_axis.tween_property(self, "position:y", target_y, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		z_index = current_track

# Collision callback triggered when the player or an obstacle enters the enemy's area
func _on_area_entered(area: Area2D) -> void:
	# Randomly selects a lane to move the player to if the player is on one of the middle lanes
	if area is Player:
		if player.current_track == 1:
			player.force_track_change(2)
		elif player.current_track == level_manager.TRACK_COUNT:
			player.force_track_change(level_manager.TRACK_COUNT - 1)
		else:
			player.force_track_change(player.current_track + [1,-1].pick_random())

		player.invincibility(INVINCIBILITY_DURATION)
		GameManager.deduct_time(TIME_PENALTY)

	if area is Obstacle:
		if _movement_tween_x_axis and _movement_tween_x_axis.is_running():
			_movement_tween_x_axis.kill()
		if _movement_tween_y_axis and _movement_tween_y_axis.is_running():
			_movement_tween_y_axis.kill()

		animation.play("RESET")
		change_state(DogState.DEFEATED)

func change_state(new_state: DogState) -> void:
	if current_state != new_state:
		current_state = new_state
		state_changed.emit(current_state)

func disable_collision() -> void: 
	collision.set_deferred("disabled", true)

func deactivate() -> void:
	super()
	if _movement_tween_x_axis and _movement_tween_x_axis.is_valid():
		_movement_tween_x_axis.kill()
	if _movement_tween_y_axis and _movement_tween_y_axis.is_valid():
		_movement_tween_y_axis.kill()
	if _anim_tween and _anim_tween.is_valid():
		_anim_tween.kill()
	
	delay_timer.stop()
	attack_cooldown.stop()
	warning_sprite.visible = false
	
	animation.stop()
	animation.play("RESET")
	animation.advance(0)
