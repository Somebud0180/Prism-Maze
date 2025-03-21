extends HSlider

@onready var menu = get_node("/root/Menu")
@export var target_property: StringName

func _ready() -> void:
	connect("value_changed", _on_value_changed)


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
