extends CharacterBody2D


const SPEED = 200.0
const JUMP_VELOCITY = -360.0
var GRAVITY_DIRECTION = 1

@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Invert the gravity.
	if Input.is_action_just_pressed("invert_gravity"):
		print("Flipping")
		if GRAVITY_DIRECTION == 1:
			GRAVITY_DIRECTION = -1
			animated_sprite.flip_v = true
		else:
			GRAVITY_DIRECTION = 1
			animated_sprite.flip_v = false
	
	# Add gravity based on gravity direction.
	if GRAVITY_DIRECTION == 1 and not is_on_floor():
		velocity += GRAVITY_DIRECTION * get_gravity() * delta
	elif GRAVITY_DIRECTION == -1 and not is_on_ceiling():
		velocity += GRAVITY_DIRECTION * get_gravity() * delta
	
	# Handle jump based on gravity direction.
	if GRAVITY_DIRECTION == 1 and Input.is_action_just_pressed("jump") and is_on_floor():
		print("Jump Up")
		velocity.y = JUMP_VELOCITY * GRAVITY_DIRECTION
	elif GRAVITY_DIRECTION == -1 and Input.is_action_just_pressed("jump") and is_on_ceiling():
		print("Jump Down")
		velocity.y = JUMP_VELOCITY * GRAVITY_DIRECTION

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
