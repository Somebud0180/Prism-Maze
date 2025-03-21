extends CanvasLayer

@onready var camera_2d = %Camera2D
const GAME_RESOLUTION = Vector2(1280, 720)  # Base game resolution

func _ready() -> void:
	_on_window_size_changed()
	get_tree().root.size_changed.connect(_on_window_size_changed)

func _on_window_size_changed() -> void:
	# Update the CanvasLayer offset to center of viewport
	offset = camera_2d.get_viewport_rect().size / 2
