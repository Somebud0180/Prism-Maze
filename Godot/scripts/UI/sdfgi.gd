extends CheckButton

@onready var menu = get_node("/root/Menu")
@onready var sdfgi_full_toggle = %SDFGI_Full
var stored_text = ""

func _ready() -> void:
	stored_text = text

func _update_button() -> void:
	button_pressed = menu.sdfgi_enabled
	
	if menu.text_enabled:
		text = stored_text
		icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	else:
		text = ""
		icon_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _on_toggled(toggled_on: bool) -> void:
	# Restore button state in case of config load
	menu.sdfgi_enabled = toggled_on
	sdfgi_full_toggle.disabled = !toggled_on
