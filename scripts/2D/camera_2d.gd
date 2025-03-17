extends Camera2D

@onready var game_manager = %GameManager

const CAMERA_TWEEN_DURATION : float = 0.5

@export var ZOOM_PLATFORM : Vector2 = Vector2(2.0, 2.0)  # 2x zoom-in
@export var ZOOM_MAZE : Vector2    = Vector2(3.5, 3.5) # 4x zoom-in

var camera_tween : Tween = null
var initialized = false

func _on_game_manager_loaded():
	initialized = true

func _process(_delta: float) -> void:
	if !initialized:
		return
	
	if not camera_tween or not camera_tween.is_running():
		var desired_zoom = Vector2.ZERO
		
		if game_manager.game_mode == 1:
			desired_zoom = ZOOM_PLATFORM
		elif game_manager.game_mode == 2:
			desired_zoom = ZOOM_MAZE
		
		camera_tween = create_tween()
		camera_tween.tween_property(self, "zoom", desired_zoom, CAMERA_TWEEN_DURATION).set_trans(Tween.TRANS_CUBIC)


func disable_pos_smoothing() -> void:
	position_smoothing_enabled = false


func enable_pos_smoothing() -> void:
	position_smoothing_enabled = true
