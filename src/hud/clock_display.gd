# Handles the visual presentation of the remaining run time
# Connects to the global GameManager to receive state updates
class_name ClockDisplay
extends Control

@onready var time_label: Label = $ClockBackground/TimeLabel as Label

func _ready() -> void:
	GameManager.time_updated.connect(_on_time_updated)
	# Initialise the display immediately to prevent a single-frame blank state
	_on_time_updated(GameManager.current_time)

# Formats the raw float time into a human-readable MM:SS string
func _on_time_updated(time_left: float) -> void:
	# Convert to integer once to avoid expensive floating-point modulo operations
	var total_seconds: int = int(time_left)
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	
	time_label.text = "%02d:%02d" % [minutes, seconds]
