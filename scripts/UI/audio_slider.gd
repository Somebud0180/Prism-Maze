extends HSlider

@onready var menu = get_node("/root/Menu")
@export var target_property: StringName
@export var marker: VSeparator

func _ready() -> void:
	connect("value_changed", _on_value_changed)
	_position_marker()  # Position the marker once at startup


func _notification(what):
	if what == NOTIFICATION_RESIZED:
		_position_marker()  # Re-position when the slider resizes


func _position_marker():
	var default_value = 0.0
	var range_size = max_value - min_value
	var ratio = (default_value - min_value) / float(range_size)
	var usable_width = size.x
	marker.position.x = ratio * usable_width - 11.5


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fine_control"):
		step = 1.25
	elif event.is_action_released("fine_control"):
		step = 5.0

func _on_value_changed(_value: float) -> void:
	if _value == -30.0:
		menu.set(target_property, -80)
	else:
		menu.set(target_property, _value)
