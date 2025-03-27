extends CheckButton

@onready var menu = get_node("/root/Menu")
@onready var sdfgi_full_toggle = %SDFGI_Full

func _update_button() -> void:
	button_pressed = menu.sdfgi_enabled


func _on_toggled(toggled_on: bool) -> void:
	# Restore button state in case of config load
	menu.sdfgi_enabled = toggled_on
	sdfgi_full_toggle.disabled = !toggled_on
