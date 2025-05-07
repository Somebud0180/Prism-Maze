extends HSlider

@onready var menu = get_node("/root/Menu")
@export var marker: VSeparator

func _ready() -> void:
	_position_marker()  # Position the marker once at startup


func _notification(what):
	if what == NOTIFICATION_RESIZED:
		_position_marker()  # Re-position when the slider resizes


func _position_marker():
	var default_value = 3.97
	var range_size = max_value - min_value
	var _ratio = (default_value - min_value) / float(range_size)
	var usable_width = size.x
	marker.position.x = _ratio * usable_width - 7.5


func _update_slider():
	value = menu.resolution_scaling


func _on_value_changed(_value: float) -> void:
	menu.resolution_scaling = int(_value)
