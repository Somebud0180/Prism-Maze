extends Camera2D

@onready var game_manager = %GameManager

const CAMERA_TWEEN_DURATION : float = 0.5

const ZOOM_PLATFORM : Vector2 = Vector2(2.0, 2.0)  # 2x zoom-in
const ZOOM_MAZE : Vector2    = Vector2(4.0, 4.0) # 4x zoom-in

var camera_tween : Tween = null

func _process(_delta: float) -> void:
	if (camera_tween == null or not camera_tween.is_running()):
		# Check game mode and tween to the proper zoom
		if game_manager.game_mode == 1:
			camera_tween = create_tween()
			camera_tween.tween_property(self, "zoom", ZOOM_PLATFORM, CAMERA_TWEEN_DURATION).set_trans(Tween.TRANS_CUBIC)
			
		elif game_manager.game_mode == 2:
			camera_tween = create_tween()
			camera_tween.tween_property(self, "zoom", ZOOM_MAZE, CAMERA_TWEEN_DURATION).set_trans(Tween.TRANS_CUBIC)
