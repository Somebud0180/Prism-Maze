extends CharacterBody2D


const SPEED = 200.0
const JUMP_VELOCITY = -360.0
var GRAVITY_DIRECTION = 1

@onready var animated_sprite = $AnimatedSprite2D
@onready var game_manager = %GameManager

func _physics_process(delta: float) -> void:
	if game_manager.GAME_MODE == 1:
		# Invert the gravity.
		if Input.is_action_just_pressed("invert_gravity"):
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
			velocity.y = JUMP_VELOCITY * GRAVITY_DIRECTION
		elif GRAVITY_DIRECTION == -1 and Input.is_action_just_pressed("jump") and is_on_ceiling():
			velocity.y = JUMP_VELOCITY * GRAVITY_DIRECTION

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var direction := Input.get_axis("move_left", "move_right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		move_and_slide()
	elif game_manager.GAME_MODE == 2:
		# TOP-DOWN MODE
		# For top-down movement, we use full directional input.
		# You can define the actions: move_up, move_down, move_left, move_right.
		var input_vector := Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
		)
		
		# Normalize the input vector so diagonal movement isn't faster.
		if input_vector.length() > 0:
			input_vector = input_vector.normalized()
		
		velocity = input_vector * SPEED
		move_and_slide()
