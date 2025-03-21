extends HBoxContainer

@export var icon: Texture
@export var icon_cross: Texture

@export var slider: Slider
@export var texture_rect: TextureRect

func _process(delta: float) -> void:
	if slider.value <= -30:
		if texture_rect.texture != icon_cross:
			texture_rect.texture = icon_cross
	else:
		if texture_rect.texture != icon:
			texture_rect.texture = icon
