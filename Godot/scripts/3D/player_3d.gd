extends CharacterBody3D

@export var SPEED = 0.0
@export var FRICTION = 0.2
@export var JUMP_VELOCITY = 0.0
@export var WALL_JUMP_FORCE = 0.0
@export var WALL_SLIDE_FACTOR = 0.3
@export var ROTATION_SPEED = 0.0

var conveyor_velocity = Vector3.ZERO
var player_controlled

var was_on_wall = false:
	set(value):
		play_wall_grab(value, was_on_wall)
		was_on_wall = value

var is_in_air = false:
	set(value):
		play_floor_hit(value, is_in_air)
		is_in_air = value

var last_wall_normal: Vector3 = Vector3.ZERO
var jump_credit = 2
var game_initialized = false
var gravity_direction = 1: # 1 for normal, -1 for upside-down
	set(value):
		_gravity_change(gravity_direction, value)
		gravity_direction = value

var is_in_subviewport = false
var subviewport

@onready var menu = get_node("/root/Menu")
@onready var animation_player = %AnimationPlayer
@onready var pivot = %CameraPivot
@onready var camera = %ThirdPersonCamera
@onready var audio_player = %AudioStreamPlayer3D

var fall_sound = load("res://resources/Sound/Player/Fall.wav")
var jump_sound = load("res://resources/Sound/Player/Jump.wav")
var grab_sound = load("res://resources/Sound/Player/Grab.wav")

func hide_on_death() -> void:
	menu = get_node("/root/Menu")
	if menu.character_life <= 0:
		hide()


func play_floor_hit(new_value: bool, old_value: bool) -> void:
	if !new_value and new_value != old_value:
		audio_player.stream = fall_sound
		audio_player.volume_db = menu.sfx_volume
		audio_player.play()


func play_wall_grab(new_value: bool, old_value: bool) -> void:
	if new_value and new_value != old_value:
		audio_player.stream = grab_sound
		audio_player.volume_db = menu.sfx_volume
		audio_player.play()


func _ready() -> void:
	# Disable obect interaction before loading
	call_deferred("set_collision_layer_value", 2, false)


func _on_game_loaded():
	game_initialized = true
	call_deferred("set_collision_layer_value", 2, true)

func _gravity_change(oldValue: int, newValue: int):
	if newValue == 1 and oldValue != 1:
		animation_player.play("normalize_player")
		await animation_player.animation_finished
		animation_player.play("PlayerAction")
	elif newValue == -1 and oldValue != -1:
		animation_player.play("invert_player")
		await animation_player.animation_finished
		animation_player.play("PlayerAction")


func _gravity(delta: float):
	# Add gravity based on gravity direction.
		if (gravity_direction == 1 and not is_on_floor()) or (gravity_direction == -1 and not is_on_ceiling()):
			is_in_air = true
			if is_valid_wall():
				if (gravity_direction == 1 and velocity.y < 0) or (gravity_direction == -1 and velocity.y > 0):
					# Apply reduced gravity for wall sliding only when falling
					velocity += clamp(gravity_direction * get_gravity() * WALL_SLIDE_FACTOR * delta, Vector3(0.0, -30.0, 0.0), Vector3(0.0, 20.0, 0.0))
				else:
					# Normal gravity when moving upward on wall
					velocity += gravity_direction * get_gravity() * delta
				
				var collision = get_slide_collision(0)
				if collision:
					var current_normal = collision.get_normal().normalized()
					# Only refill jump if it's a 180° flip
					if last_wall_normal == Vector3.ZERO:
						if jump_credit <= 0:
							jump_credit = 1
						was_on_wall = true
						last_wall_normal = current_normal
					elif current_normal.dot(last_wall_normal.normalized()) <= -0.99:
						if jump_credit <= 0:
							jump_credit = 1
						was_on_wall = true
						last_wall_normal = current_normal
			else:
				velocity += gravity_direction * get_gravity() * delta
				was_on_wall = false


func is_valid_wall() -> bool:
	if !is_on_wall():
		return false
	
	if get_slide_collision_count() > 0 and is_on_wall_only():
		var collision = get_slide_collision(0)
		var collider = collision.get_collider()
		
		# Check if collider is a GridMap
		if collider is GridMap:
			# Only allow wall jump on normal walls (item 0)
			var is_barrier = collider.get_collision_layer_value(3)
			return !is_barrier
		else:
			return false
	return false


func _physics_process(delta: float) -> void:
	# Don't process physics until we're properly initialized
	if !game_initialized or menu.menu_state != Menu.STATE.GAME3D:
		# Keep gravity if in 2D-in-3D mode
		if menu.menu_state == Menu.STATE.GAMEMIXED and is_in_air:
			_gravity(delta)
			move_and_slide()
		
		return
	
	# Add gravity based on gravity direction.
	_gravity(delta)
	
	# Check if is on floor and restore double jump
	if (gravity_direction == 1 and is_on_floor()) or (gravity_direction == -1 and is_on_ceiling()):
		is_in_air = false
		jump_credit = 2
		was_on_wall = false
		last_wall_normal = Vector3.ZERO
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and jump_credit > 0:
		audio_player.stream = jump_sound
		audio_player.play()
		jump_credit -= 1
		
		if was_on_wall:
			# Push away from the wall
			velocity += -last_wall_normal * WALL_JUMP_FORCE
		
		velocity.y = JUMP_VELOCITY * gravity_direction
	
	# Invert the gravity.
	if Input.is_action_just_pressed("invert_gravity"):
		if gravity_direction == 1:
			gravity_direction = -1
		else:
			gravity_direction = 1
	
	# Get the input direction
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Get camera direction vectors 
	var camera_forward = camera.get_front_direction()
	var camera_right = camera.get_right_direction()
	
	# Calculate the movement direction based on camera orientation
	var direction = Vector3(camera_right.x * input_dir.x - camera_forward.x * input_dir.y, 0.0, camera_right.z * input_dir.x - camera_forward.z * input_dir.y)
	
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


func _process(delta: float) -> void:
	RenderingServer.global_shader_parameter_set("character_position", position)


func _input(_event: InputEvent) -> void:
	if Input.is_action_pressed("camera_hold"):
		camera.mouse_follow = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		camera.mouse_follow = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _handle_input_mode_switch():
	for player in get_tree().get_nodes_in_group("Player"):
		player.game_initialized = false
		player.set_process_input(false)
	
	if is_in_subviewport:
		# Switch to 2D controls
		if subviewport:
			print("Enabling 2D Input")
			subviewport.handle_input_locally = true
			subviewport.gui_disable_input = false
			
			# Enable 2D player input
			if player_controlled:
				player_controlled.game_initialized = true
				player_controlled.set_process_input(true)
	else:
		# Switch back to 3D controls
		if subviewport:
			print("Enabling 3D Input")
			subviewport.handle_input_locally = false
			subviewport.gui_disable_input = true
			
			# Disable 2D player input
			if player_controlled:
				player_controlled.game_initialized = false
				player_controlled.set_process_input(false)
