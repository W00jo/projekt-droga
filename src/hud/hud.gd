# Serves as the root controller for the Heads-Up Display
# Manages its own visibility lifecycle based on global game states
class_name HUD
extends Control

const HIDDEN_OFFSET_Y: float = -200.0
const SLIDE_DURATION: float = 0.5

func _ready() -> void:
	# The HUD is hidden completely above the screen until the RUNNING state
	position.y = HIDDEN_OFFSET_Y
	GameManager.state_changed.connect(_on_state_changed)

func _on_state_changed(new_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.RUNNING:
			_slide_to(0.0)
		GameManager.GameState.COASTING, GameManager.GameState.DECELERATING, GameManager.GameState.FAILED:
			_slide_to(HIDDEN_OFFSET_Y)

# Animates the vertical position to smoothly slide the HUD in and out of the screen
func _slide_to(target_y: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "position:y", target_y, SLIDE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
