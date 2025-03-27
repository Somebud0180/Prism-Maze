extends Button

@onready var menu = get_node("/root/Menu")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_manage_visibility()


func _on_pressed():
	var menu_event = InputEventAction.new()
	menu_event.action = "ui_cancel"
	menu_event.pressed = true
	Input.parse_input_event(menu_event)
	_manage_visibility()
	print("Menu Button Pressed")


func _manage_visibility():
	if (menu.menu_state == Menu.STATE.GAME or menu.menu_state == Menu.STATE.GAME3D or menu.menu_state == Menu.STATE.GAMEMIXED):
		visible = true
	else:
		visible = false