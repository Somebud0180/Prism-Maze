extends CharacterBody2D
class_name Player2D

signal player_loaded

const speed = 200.0
const jump_velocity = -360.0
var jump_credit = 1
var collisions = []
var gravity_direction = 1: # 1 for normal, -1 for upside-down
	set(value):
		gravity_direction = value
		_gravity_change()

@export var animated_sprite: AnimatedSprite2D
@export var audio_player: AudioStreamPlayer2D

@onready var menu = get_node("/root/Menu")
@onready var game_manager = $"../GameManager"

var killable = false
var jump_sound = load("res://resources/Sound/Player/Jump.wav")
var fall_sound = load("res://resources/Sound/Player/Fall.wav")

var game_initialized = false:
	set(value):
		game_initialized = value
		if value == true:
			await get_tree().create_timer(1).timeout
			killable = true
		else:
			killable = false

var is_in_air = false:
	set(value):
		play_floor_hit(value, is_in_air)
		is_in_air = value


func go_to(input_position: Vector2):
	position = input_position


func change_color():
	var selected_color = menu.player_color
	animated_sprite.modulate = selected_color


func _gravity_change():
	if gravity_direction == 1:
		animated_sprite.flip_v = false
	else:
		animated_sprite.flip_v = true


func hide_on_death() -> void:
	if menu.character_life <= 0:
		hide()


func play_floor_hit(new_value: bool, old_value: bool) -> void:
	if !new_value and new_value != old_value:
		audio_player.stream.set_stream(0, fall_sound)
		audio_player.volume_db = menu.sfx_volume
		audio_player.play()


func _gravity(delta: float):
	# Add gravity based on gravity direction.
		if gravity_direction == 1 and not is_on_floor() or gravity_direction == -1 and not is_on_ceiling():
			velocity += gravity_direction * get_gravity() * delta
			is_in_air = true
		elif gravity_direction == 1 and is_on_floor() or gravity_direction == -1 and is_on_ceiling():
			is_in_air = false


func _ready():
	change_color()
	
	# Emit signal that we're loaded
	call_deferred("emit_signal", "player_loaded")


func _on_game_manager_loaded():
	game_initialized = true
	$Camera2D._on_game_manager_loaded()


func _physics_process(delta: float) -> void:
	# Don't process physics until we're properly initialized
	if !game_initialized or (menu.menu_state != Menu.STATE.GAME and menu.menu_state != Menu.STATE.GAMEMIXED):
		if menu.menu_state == Menu.STATE.GAME3D and game_manager.game_mode == 1 and is_in_air:
			_gravity(delta)
			move_and_slide()
		
		return
	
	if game_manager.game_mode == 1:
		_gravity(delta)
		
		if (gravity_direction == 1 and is_on_floor()) or (gravity_direction == -1 and is_on_ceiling()):
			jump_credit = 1
		
		# Handle jump based on gravity direction.
		if Input.is_action_just_pressed("jump") and jump_credit > 0:
			audio_player.stream.set_stream(0, jump_sound)
			audio_player.play()
			jump_credit -= 1 
			velocity.y = jump_velocity * gravity_direction
		
		# Invert the gravity.
		if Input.is_action_just_pressed("invert_gravity"):
			if gravity_direction == 1:
				gravity_direction = -1
			else:
				gravity_direction = 1
		
		# Get the input direction and handle the movement/deceleration.
		var direction := Input.get_axis("move_left", "move_right")
		if direction:
			velocity.x = direction * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
		
		move_and_slide()
	elif game_manager.game_mode == 2:
		# TOP-DOWN MODE
		# For top-down movement, use four directional input.
		var input_vector := Vector2(
			Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
			Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
		)
		
		# Normalize the input vector so diagonal movement isn't faster.
		if input_vector.length() > 0:
			input_vector = input_vector.normalized()
		
		velocity = input_vector * speed
		move_and_slide()


func _process(_delta: float) -> void:
	if killable and game_manager.game_mode == 1:
		collisions.clear()
		
		for i in get_slide_collision_count() - 1:
			if get_slide_collision(i).get_collider() == Killzone2D:
				collisions.append("Killzone")
		
		if collisions.size() > 0 and !collisions.has("Killzone"):
			menu.character_life -= 1
			velocity.x = 0
			velocity.y = 0
			position = Vector2i(0,0)
