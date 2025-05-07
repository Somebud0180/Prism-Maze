extends CanvasLayer

@onready var menu = get_node("/root/Menu")
@export var animation_player: AnimationPlayer

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("hide_gui") and !animation_player.is_playing():
		if (menu.menu_state == Menu.STATE.GAME or menu.menu_state == Menu.STATE.GAME3D or menu.menu_state == Menu.STATE.GAMEMIXED):
			if visible:
				animation_player.play("hide_overlay")
				await animation_player.animation_finished
				visible = false
			else:
				visible = true
				animation_player.play("show_overlay")
