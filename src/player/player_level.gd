extends Area2D

# Pozycja Y gracza, gdy jest na pierwszym (górnym) torze
var track_1_pos_y:float = 350

# O ile pozycja Y gracza różni się między torami
# (np.: jeśli track_1_pos_y = 330, a track_y_spacing = 90,
# to na drugim torze pozycja Y gracza to 330 + 90 czyli 420, na trzecim 510 itd.)
var track_y_spacing:float = 90

# Ilość torów do poruszania się
var number_of_tracks:int = 4

# Numer toru na którym gracz zaczyna (licząc od góry), a potem na którym jest obecnie
var current_track:int = 2

func _ready() -> void:
	place_player_on_track(current_track)

func place_player_on_track(target_track:int) -> void:
	if target_track >= 1 and target_track <= number_of_tracks:
		
		# np. jeśli target_track = 2, a track_1_pos_y = 350:
		# position.y = 1 * 90 + 350 czyli 420 (pozycja Y gracza na torze nr 2)
		position.y = (target_track-1) * 90 + track_1_pos_y
		
		current_track = target_track

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("move_up"):
		place_player_on_track(current_track-1)
	if Input.is_action_just_pressed("move_down"):
		place_player_on_track(current_track+1)
