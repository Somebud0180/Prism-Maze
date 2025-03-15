extends CanvasLayer
class_name TutorialLayer

@export var level_layer: Node3D
@export var overlay: HBoxContainer
@export var overlay_animation_player: AnimationPlayer

enum InputDevice { KEYBOARD_MOUSE, CONTROLLER }
var current_device = InputDevice.KEYBOARD_MOUSE
var is_animating = false

func _ready():
	# Check if a controller is connected at startup
	check_connected_controllers()
	
	# Process input to detect device changes
	set_process_input(true)


func _input(event):
	# Detect controller input
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if current_device != InputDevice.CONTROLLER:
			current_device = InputDevice.CONTROLLER
			update_control_prompts()
	
	# Detect keyboard or mouse input
	elif event is InputEventKey or event is InputEventMouse:
		if current_device != InputDevice.KEYBOARD_MOUSE:
			current_device = InputDevice.KEYBOARD_MOUSE
			update_control_prompts()


func check_connected_controllers():
	# Check if any controllers are connected
	for i in range(Input.get_connected_joypads().size()):
		current_device = InputDevice.CONTROLLER
		update_control_prompts()
		break


func update_control_prompts():
	# Call your tutorial functions with the current device
	match level_layer.tutorial_state:
		LevelLayer3D.TUTORIAL_STATE.MOVE:
			move_tutorial()
		LevelLayer3D.TUTORIAL_STATE.JUMP:
			jump_tutorial()
		LevelLayer3D.TUTORIAL_STATE.DOUBLE_JUMP:
			double_jump_tutorial()
		LevelLayer3D.TUTORIAL_STATE.WALL_JUMP:
			wall_jump_tutorial()


func reset_tutorial():
	is_animating = true
	await clear_overlay()
	
	overlay_animation_player.play("show_tutorial")
	await overlay_animation_player.animation_finished
	is_animating = false



func move_tutorial():
	is_animating = true
	await clear_overlay()
	
	var new_icon = load("res://resources/Menu/Control Icons/Move.png")
	var control_icon_1
	var control_icon_2
	
	if current_device == InputDevice.KEYBOARD_MOUSE:
		control_icon_1 = load("res://resources/Controls/KBM/keyboard_wasd.png")
		control_icon_2 = load("res://resources/Controls/KBM/keyboard_arrows.png")
	else: # Controller
		control_icon_1 = load("res://resources/Controls/Controllers/stick_l.png")
	
	var new_icon_rect = create_texture_rect(new_icon)
	var control_rect_1 = create_texture_rect(control_icon_1)
	
	overlay.add_child(new_icon_rect)
	overlay.add_child(control_rect_1)
	
	if control_icon_2:
		var control_rect_2 = create_texture_rect(control_icon_2)
		overlay.add_child(control_rect_2)
	
	overlay_animation_player.play("show_tutorial")
	await overlay_animation_player.animation_finished
	is_animating = false


func jump_tutorial():
	is_animating = true
	await clear_overlay()
	
	var new_icon = load("res://resources/Menu/Control Icons/Jump.png")
	var control_icon_1
	var control_icon_2
	
	if current_device == InputDevice.KEYBOARD_MOUSE:
		control_icon_1 = load("res://resources/Controls/KBM/keyboard_space_icon.png")
	else: # Controller
		control_icon_1 = load("res://resources/Controls/Controllers/button_a.png")
		control_icon_2 = load("res://resources/Controls/Controllers/button_b.png")
	
	var new_icon_rect = create_texture_rect(new_icon)
	var control_rect_1 = create_texture_rect(control_icon_1)
	
	overlay.add_child(new_icon_rect)
	overlay.add_child(control_rect_1)
	
	if control_icon_2:
		var control_rect_2 = create_texture_rect(control_icon_2)
		overlay.add_child(control_rect_2)
		
	overlay_animation_player.play("show_tutorial")
	await overlay_animation_player.animation_finished
	is_animating = false


func double_jump_tutorial():
	is_animating = true
	await clear_overlay()
	
	var new_icon = load("res://resources/Menu/Control Icons/DoubleJump.png")
	var new_icon_rect = create_texture_rect(new_icon)
	overlay.add_child(new_icon_rect)
	
	overlay_animation_player.play("show_tutorial")
	await overlay_animation_player.animation_finished
	is_animating = false


func wall_jump_tutorial():
	is_animating = true
	await clear_overlay()
	
	var new_icon = load("res://resources/Menu/Control Icons/WallJump.png")
	var new_icon_rect = create_texture_rect(new_icon)
	overlay.add_child(new_icon_rect)
	
	overlay_animation_player.play("show_tutorial")
	await overlay_animation_player.animation_finished
	is_animating = false


func success_tutorial():
	is_animating = true
	await clear_overlay()
	
	var new_icon = load("res://resources/Menu/Flag.png")
	var new_icon_rect = create_texture_rect(new_icon)
	overlay.add_child(new_icon_rect)
	
	overlay_animation_player.play("show_tutorial")
	await overlay_animation_player.animation_finished
	is_animating = false


func clear_overlay() -> void:
	if overlay.get_child_count() == 0:
		return
	
	overlay_animation_player.play("hide_tutorial")
	await overlay_animation_player.animation_finished
	
	for child in overlay.get_children():
		child.queue_free()


func create_texture_rect(texture: Texture) -> TextureRect:
	var texture_rect = TextureRect.new()
	texture_rect.texture = texture
	texture_rect.custom_minimum_size = Vector2(64, 64)
	texture_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return texture_rect
