extends TextureRect

@export var animation_player: AnimationPlayer
var normal_icon = load("res://resources/Menu/Menu Icons/Finite.png")
var infinite_icon = load("res://resources/Menu/Menu Icons/Infinity.png")

func _set_game_mode_rect(infinite: bool):
	if infinite:
		texture = infinite_icon
	else:
		texture = normal_icon
