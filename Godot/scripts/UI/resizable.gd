extends CheckButton

@onready var menu = get_node("/root/Menu")

func _update_button() -> void:
	button_pressed = menu.resizable


func _on_toggled(toggled_on: bool) -> void:
	menu.resizable = toggled_on
