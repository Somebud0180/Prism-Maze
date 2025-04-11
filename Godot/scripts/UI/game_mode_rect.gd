extends TextureRect

var normal_icon = load("res://resources/Menu/Menu Icons/Play.png")
var infinite_icon = load("res://resources/Menu/Menu Icons/Infinity.png")

func _set_game_mode_rect(infinite: bool):
	print(infinite)
	if infinite:
		texture = infinite_icon
	else:
		texture = normal_icon
