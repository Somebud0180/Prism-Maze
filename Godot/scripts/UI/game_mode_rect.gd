extends TextureRect

@export var animation_player: AnimationPlayer
var normal_icon = load("res://resources/Menu/Menu Icons/Play.png")
var infinite_icon = load("res://resources/Menu/Menu Icons/Infinity.png")

func _set_game_mode_rect(infinite: bool):
	if infinite:
		texture = infinite_icon
	else:
		texture = normal_icon


func manage_animation(menu_state: Menu.STATE):
	if offset_left != 54 and (menu_state == Menu.STATE.GAME or menu_state == Menu.STATE.GAME3D or menu_state == Menu.STATE.GAMEMIXED):
		animation_player.play("mode_right")
	else:
		animation_player.play("mode_left")
