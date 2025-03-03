extends CharacterBody3D

@export var SPEED = 0.0
@export var JUMP_VELOCITY = 0.0
@export var ROTATION_SPEED = 0.0

var look_sensitivity: float = 0.002
var is_holding: bool = false
var gravity_direction = 1: # 1 for normal, -1 for upside-down
	set(value):
		_gravity_change(gravity_direction, value)
		gravity_direction = value

@onready var animation_player = %AnimationPlayer
@onready var pivot = %CameraPivot
@onready var camera = %ThirdPersonCamera

var camera_horizontal_rotation_variation


func _gravity_change(oldValue: int, newValue: int):
	if newValue == 1 and oldValue != 1:
		animation_player.play("normalize_player")
		await animation_player.animation_finished
		animation_player.play("PlayerAction")
	elif newValue == -1 and oldValue != -1:
		animation_player.play("invert_player")
		await animation_player.animation_finished
		animation_player.play("PlayerAction")


func _physics_process(delta: float) -> void:
	# Invert the gravity.
	if Input.is_action_just_pressed("invert_gravity"):
		if gravity_direction == 1:
			gravity_direction = -1
		else:
			gravity_direction = 1
	
	# Add gravity based on gravity direction.
	if gravity_direction == 1 and not is_on_floor():
		velocity += gravity_direction * get_gravity() * delta
	elif gravity_direction == -1 and not is_on_ceiling():
		velocity += gravity_direction * get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Get camera direction vectors (flattened to ignore Y component for movement)
	var camera_forward = camera.get_front_direction()
	var camera_right = camera.get_right_direction()
	
	# Calculate the movement direction based on camera orientation
	var direction = (camera_forward * -input_dir.y + camera_right * input_dir.x).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# Rotate the player to face the movement direction
		if input_dir.length() > 0.1:
			var target_rotation = atan2(direction.x, direction.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, delta * ROTATION_SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			camera.mouse_follow = true
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # Lock the mouse to the viewport
		elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			camera.mouse_follow = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Lock the mouse to the viewport
