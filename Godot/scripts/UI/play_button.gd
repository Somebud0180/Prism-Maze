extends Button

@onready var menu = get_node("/root/Menu")
@export var modifier: StringName
var stored_text = ""
var normal_style
var hover_style
var pressed_style

func _ready() -> void:
	stored_text = text
	normal_style = get_theme_stylebox("normal").duplicate()
	hover_style = get_theme_stylebox("hover").duplicate()
	pressed_style = get_theme_stylebox("pressed").duplicate()


func _update_button() -> void:
	normal_style.border_color = menu.player_color
	hover_style.border_color = menu.player_color
	pressed_style.border_color = menu.player_color
	
	if menu.text_enabled:
		text = stored_text
		icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	else:
		text = ""
		icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	if menu.get(modifier):
		add_theme_stylebox_override("normal", normal_style)
		add_theme_stylebox_override("hover", hover_style)
		add_theme_stylebox_override("pressed", pressed_style)
	else:
		remove_theme_stylebox_override("normal")
		remove_theme_stylebox_override("hover")
		remove_theme_stylebox_override("pressed")
