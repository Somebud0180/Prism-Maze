extends Camera2D

@onready var game_manager = %GameManager

const CAMERA_TWEEN_DURATION : float = 0.5
const BASE_RESOLUTION = Vector2(1280, 720)

@export var ZOOM_PLATFORM : float = 2.0 # Base zoom level for platform mode
@export var ZOOM_MAZE : float = 3.5 # Base zoom level for maze mode

var camera_tween : Tween = null
var initialized = false

func _ready() -> void:
	get_tree().root.size_changed.connect(_on_viewport_size_changed)


func _on_game_manager_loaded():
	initialized = true
	_on_viewport_size_changed()


func _on_viewport_size_changed() -> void:
	if !initialized:
		return
		
	var viewport_size = get_viewport_rect().size
	var aspect_ratio = viewport_size.x / viewport_size.y
	var base_aspect_ratio = BASE_RESOLUTION.x / BASE_RESOLUTION.y
	
	# Adjust zoom based on current game mode
	var base_zoom = ZOOM_MAZE if game_manager.game_mode == 2 else ZOOM_PLATFORM
	
	# Calculate zoom based on aspect ratio comparison
	var zoom_factor = 1.0
	if aspect_ratio > base_aspect_ratio:
		# Wider screen - maintain height and show more horizontally
		zoom_factor = viewport_size.y / BASE_RESOLUTION.y
	else:
		# Taller screen - maintain width
		zoom_factor = viewport_size.x / BASE_RESOLUTION.x
	
	var adjusted_zoom = Vector2.ONE * base_zoom / zoom_factor
	
	# Apply zoom smoothly
	if camera_tween and camera_tween.is_running():
		camera_tween.kill()
	
	camera_tween = create_tween()
	camera_tween.tween_property(self, "zoom", adjusted_zoom, CAMERA_TWEEN_DURATION).set_trans(Tween.TRANS_CUBIC)


func _process(_delta: float) -> void:
	if !initialized:
		return
	
	if not camera_tween or not camera_tween.is_running():
		pass
		_on_viewport_size_changed()


func disable_pos_smoothing() -> void:
	position_smoothing_enabled = false


func enable_pos_smoothing() -> void:
	position_smoothing_enabled = true
