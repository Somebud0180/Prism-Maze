extends HSlider

@onready var menu = get_node("/root/Menu")
@export var marker: VSeparator

func _ready() -> void:
	_position_marker()  # Position the marker once at startup


func _notification(what):
	if what == NOTIFICATION_RESIZED:
		_position_marker()  # Re-position when the slider resizes


func _position_marker():
	var default_value = 0.015
	var range_size = max_value - min_value
	var _ratio = (default_value - min_value) / float(range_size)
	var usable_width = size.x
	marker.position.x = _ratio * usable_width - 7.5


func _update_slider():
	value = menu.upscale_quality
	editable = (RenderingServer.get_current_rendering_method() == "forward_plus")


func _on_value_changed(_value: float) -> void:
	menu.upscale_quality = int(_value)
