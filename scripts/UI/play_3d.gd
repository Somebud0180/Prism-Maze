extends Button

@onready var menu = get_node("/root/Menu")
var normal_highlight = load("res://resources/Theme/button_normal_highlight.tres")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if menu.in_gane_3d:
		add_theme_stylebox_override("normal", normal_highlight)
	else:
		remove_theme_stylebox_override("normal")
	pass # Replace with function body.