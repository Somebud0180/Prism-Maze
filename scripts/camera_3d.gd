extends Camera3D

@onready var pivot = %CameraPivot

var look_sensitivity: float = 0.005
var zoom_sensitivity: float = 5.0
var min_fov: float = 10.0
var max_fov: float = 90.0
var is_holding: bool = false

func _ready() -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			is_holding = true
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # Lock the mouse to the viewport
		elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			is_holding = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Lock the mouse to the viewport
	
	if is_holding:
		if event is InputEventMouseMotion:
			# Vertical look on the camera itself
			rotate_x(-event.relative.y * look_sensitivity)
			
			# Horizontal look on the pivot so the camera orbits around pivot origin (the player)
			pivot.rotation.y -= event.relative.x * look_sensitivity
			
			# Prevent Z roll on the camera
			rotation.z = 0

	if event is InputEventMouseButton:
			# Zoom in/out with the scroll wheel
			if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
				fov = clamp(fov - zoom_sensitivity, min_fov, max_fov)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
				fov = clamp(fov + zoom_sensitivity, min_fov, max_fov)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
