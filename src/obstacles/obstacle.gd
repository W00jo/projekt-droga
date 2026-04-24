# W zależności od mechaniki ruchu gracza, to może być Area2D lub StaticBody2D
extends Area2D

var spawn_time:float = randf_range(1, 8)
@onready var spawn_timer:Timer = $SpawnTimer
@onready var area_shape:CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	# Przeszkoda na początku jest niewidoczna i area nie działa
	area_shape.disabled = true
	visible = false
	
	# Na razie timer będzie się od razu włączał, później to odpowiednio zmienimy
	spawn_timer.start(spawn_time)

func _on_spawn_timer_timeout() -> void:
	# Obiekt się spawnuje = zaczyna być widoczny i ma włączoną areę
	area_shape.disabled = false
	visible = true

# W zależności, czy Playera zrobimy jako CharacterBody czy jako Area,
# będzie tu sygnał "body entered" lub "area entered" (podpięte w zakładce Signals)
func _on_area_entered(area: Area2D) -> void:
	print("Player collided with obstacle")
