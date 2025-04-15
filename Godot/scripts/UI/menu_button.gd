extends Button

@onready var menu = get_node("/root/Menu")

func _on_pressed():
	var menu_event = InputEventAction.new()
	menu_event.action = "ui_cancel"
	menu_event.pressed = true
	Input.parse_input_event(menu_event)
