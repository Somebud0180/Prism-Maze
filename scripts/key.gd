extends CharacterBody2D
class_name Key

@onready var game_manager = get_node("/root/Game/GameManager")
@export var key_id = 0
@export var follow_speed = 50
@export var follow_delay = 30
@export var follow_deadzone = 1.0
@export var minimum_distance = 8
var player = null
var picked_up = false
var last_player_pos = Vector2.ZERO

var is_unlocking = false
var target_door = null
var unlock_speed = 100 

var is_stored = false
var color = Color.WHITE
var position_history = [] 

func _physics_process(_delta):
	velocity = Vector2.ZERO

	if is_unlocking and target_door != null:
		# Move towards door center during unlock sequence
		var door_center = target_door.global_position
		var distance = global_position.distance_to(door_center)
		
		if distance > 1.5:  # Go to door until near the center
			velocity = global_position.direction_to(door_center) * unlock_speed
		else:
			# Unlock when at/near the center
			is_unlocking = false
			visible = false  # Hide the key
			
			# Unlock the door
			target_door.key_unlock(key_id)
			target_door = null
	elif player:
		position_history.append(player.position)
		last_player_pos = player.position
		
		# Keep history at consistent size
		if position_history.size() > follow_delay:
			# Follow delayed position
			var target_position = position_history[0]
			position_history.remove_at(0)
			
			var distance = position.distance_to(target_position)
			
			# Calculate velocity based on distance
			var factor = clamp(distance / 16.0, 0.1, 12.0)
			velocity = position.direction_to(target_position) * follow_speed * factor
			
			# Apply deadzone to prevent jittering
			if velocity.length() < follow_deadzone:
				velocity = Vector2.ZERO
	else:
		# Clear history when not following
		position_history.clear()
		
	# Round velocity to eliminate micro movements
	velocity.x = round(velocity.x * 100) / 100
	velocity.y = round(velocity.y * 100) / 100
	
	move_and_slide()


func _ready() -> void:
	get_color()
	%AnimatedSprite2D.self_modulate = color


func _on_key_body_entered(body: Node2D) -> void:
	if !is_stored:
		print("Grabbed Key")
		is_stored = true
	player = body


func get_color() -> void:
	if !game_manager.selected_colors.is_empty:
		for item in game_manager.selected_colors:
			if item["id"] == key_id:
				color = item["color"]
	else:
		color = game_manager.get_color(key_id)


func _on_door_unlock_body_entered(body: Node2D) -> void:
	# Check if colliding with a Door
	if body.get_parent() is Door:
		var door = body.get_parent()
		
		# Check if this key matches the door
		if door.key_check(key_id) and !is_unlocking:
			# Start the unlock sequence
			is_unlocking = true
			target_door = door
			player = null  # Stop following player
			position_history.clear()  # Clear history
