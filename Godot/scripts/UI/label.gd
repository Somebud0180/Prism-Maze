extends Label

@onready var menu = get_node("/root/Menu")
var stored_text = ""
var min_height_label = 0

func _ready() -> void:
	stored_text = text
	min_height_label = $"../..".custom_minimum_size.y

func _update_label() -> void:
	if menu.text_enabled:
		visible = true
		$"../..".custom_minimum_size.y = min_height_label
	else:
		visible = false
		$"../..".custom_minimum_size.y -= 24
