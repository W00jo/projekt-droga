# Handles the visual presentation of the remaining run time
# Connects to the global GameManager to receive state updates
class_name ClockDisplay
extends Control

@onready var time_label: Label = $ClockBackground/TimeLabel as Label

const FLOATING_TEXT_START_OFFSET_Y: float = 50.0
const FLOATING_TEXT_STEP_Y: float = 30.0
const FLOATING_TEXT_SLIDE_DURATION: float = 0.4
const FLOATING_TEXT_FADE_DELAY: float = 1.5
const FLOATING_TEXT_FADE_DURATION: float = 0.5

var active_floating_texts: Array[Label] = []

func _ready() -> void:
	GameManager.time_updated.connect(_on_time_updated)
	GameManager.time_deducted.connect(_on_time_deducted)
	GameManager.state_changed.connect(_on_state_changed)
	# Initialise the display immediately to prevent a single-frame blank state
	_on_time_updated(GameManager.current_time)

func _on_state_changed(new_state: GameManager.GameState) -> void:
	if new_state == GameManager.GameState.INACTIVE:
		for label in active_floating_texts:
			if is_instance_valid(label):
				label.queue_free()
		active_floating_texts.clear()

# Formats the raw float time into a human-readable MM:SS string
func _on_time_updated(time_left: float) -> void:
	# Convert to integer once to avoid expensive floating-point modulo operations
	var total_seconds: int = int(time_left)
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	
	time_label.text = "%02d:%02d" % [minutes, seconds]

# Spawns and manages floating text when time is deducted
func _on_time_deducted(amount: float) -> void:
	var floating_label: Label = Label.new()
	# Duplicate to allow modifying the colour without affecting the main clock
	floating_label.label_settings = time_label.label_settings.duplicate()
	# Pink-Red font colour
	floating_label.label_settings.font_color = Color("ff4d6d")
	
	floating_label.text = "-%.0f S" % amount
	floating_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floating_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	floating_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var bg: TextureRect = $ClockBackground as TextureRect
	bg.add_child(floating_label)
	
	# Start precisely over the clock text
	floating_label.size = bg.size
	floating_label.position = Vector2.ZERO
	
	active_floating_texts.push_front(floating_label)
	
	# Cascade all active floating texts downwards
	for i in range(active_floating_texts.size()):
		var label_to_move: Label = active_floating_texts[i]
		var target_y: float = FLOATING_TEXT_START_OFFSET_Y + (i * FLOATING_TEXT_STEP_Y)
		
		# Bind the tween to the specific label to ensure lifecycle safety
		var slide_tween: Tween = label_to_move.create_tween()
		slide_tween.tween_property(label_to_move, "position:y", target_y, FLOATING_TEXT_SLIDE_DURATION)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)
			
	# Fade out and destroy this label independently
	var fade_tween: Tween = floating_label.create_tween()
	fade_tween.tween_property(floating_label, "modulate:a", 0.0, FLOATING_TEXT_FADE_DURATION).set_delay(FLOATING_TEXT_FADE_DELAY)
	fade_tween.finished.connect(func() -> void:
		active_floating_texts.erase(floating_label)
		floating_label.queue_free()
	)
