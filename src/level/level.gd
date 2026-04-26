extends Node2D
@onready var transition = $"LevelTransition/AnimationPlayer"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	transition.play_backwards("transition_fadeout")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
