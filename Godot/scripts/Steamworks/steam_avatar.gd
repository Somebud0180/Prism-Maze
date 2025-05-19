extends TextureButton

func _ready() -> void:
	if !Steamworks.is_steam_enabled():
		queue_free()
	else:
		Steamworks.steam_api.getPlayerAvatar(2, Steamworks.steam_id)
		Steamworks.steam_api.avatar_loaded.connect(_on_loaded_avatar)


func _on_pressed() -> void:
	if Steamworks.is_steam_enabled():
		Steamworks.steam_api.activateGameOverlay()


func _on_loaded_avatar(user_id: int, avatar_size: int, avatar_buffer: PackedByteArray) -> void:
	print("Avatar for user: %s" % user_id)
	print("Size: %s" % avatar_size)
	
	# Create the image and texture for loading
	var avatar_image: Image = Image.create_from_data(avatar_size, avatar_size, false, Image.FORMAT_RGBA8, avatar_buffer)
	
	# Optionally resize the image if it is too large
	if avatar_size > 128:
		avatar_image.resize(128, 128, Image.INTERPOLATE_LANCZOS)
		
	# Apply the image to a texture
	var avatar_texture: ImageTexture = ImageTexture.create_from_image(avatar_image)
	
	# Set the texture to a Sprite, TextureRect, etc.
	texture_normal = avatar_texture
	texture_focused = create_border_texture(avatar_image)
	
	show()


func create_border_texture(original_image: Image) -> ImageTexture:
	var bordered_image := original_image.duplicate()
	var w = bordered_image.get_width()
	var h = bordered_image.get_height()
	var border_color = Color8(0xEE, 0xEE, 0xEE, 0xFF)
	
	# Draw top/bottom border
	for x in range(w):
		bordered_image.set_pixel(x, 0, border_color)
		bordered_image.set_pixel(x, 1, border_color)
		bordered_image.set_pixel(x, h - 1, border_color)
		bordered_image.set_pixel(x, h - 2, border_color)
	# Draw left/right border
	for y in range(h):
		bordered_image.set_pixel(0, y, border_color)
		bordered_image.set_pixel(1, y, border_color)
		bordered_image.set_pixel(w - 1, y, border_color)
		bordered_image.set_pixel(w - 2, y, border_color)
	
	return ImageTexture.create_from_image(bordered_image)
