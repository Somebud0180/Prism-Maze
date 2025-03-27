extends CheckButton

@onready var menu = get_node("/root/Menu")

func _update_button() -> void:
	button_pressed = menu.sdfgi_full_res


func _on_toggled(toggled_on: bool) -> void:
	# Restore button state in case of config load
	button_pressed = toggled_on
	menu.sdfgi_full_res = toggled_on
