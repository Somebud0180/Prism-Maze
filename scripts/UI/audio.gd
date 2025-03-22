extends HBoxContainer

@onready var menu = get_node("/root/Menu")

## The variable to get the slider value from on start
@export var target_property: StringName

@export var icon: Texture
@export var icon_cross: Texture

@export var slider: Slider
@export var texture_rect: TextureRect

func _ready() -> void:
	add_to_group("Sliders")

func _update_slider() -> void:
	slider.value = menu.get(target_property)


func _process(_delta: float) -> void:
	if slider.value <= -30:
		if texture_rect.texture != icon_cross:
			texture_rect.texture = icon_cross
	else:
		if texture_rect.texture != icon:
			texture_rect.texture = icon
