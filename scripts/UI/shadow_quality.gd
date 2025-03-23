extends HSlider

@onready var menu = get_node("/root/Menu")

func _ready() -> void:
	add_to_group("Sliders")


func _update_slider():
	editable = menu.shadow_enabled
	value = menu.shadow_quality


func _on_value_changed(value: float) -> void:
	menu.shadow_quality = int(value)
