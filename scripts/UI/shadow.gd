extends CheckButton

@onready var menu = get_node("/root/Menu")

func _update_button() -> void:
	button_pressed = menu.shadow_enabled


func _on_toggled(toggled_on: bool) -> void:
	%Shadow_Quality.editable = toggled_on
	menu.shadow_enabled = toggled_on
