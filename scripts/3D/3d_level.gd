extends GridMap

signal door_close_animation_finished

@onready var audio_player = get_node("Door3D/Door/AudioStreamPlayer3D")
@onready var viewport = get_node_or_null("SubViewport")
@onready var viewport_quad = get_node_or_null("ViewportQuad")
@onready var viewport_area = get_node_or_null("ViewportQuad/ViewportArea")
@onready var barrier_map = get_node_or_null("BarrierMap")

var is_door_open = false
var is_viewport_active = false
var handle_subviewport_input = false
var player3D
var player_3d

var finish_sound = [load("res://resources/Sound/Level/SFX/Finish.wav"), load("res://resources/Sound/Level/SFX/Finish 2.wav"), load("res://resources/Sound/Level/SFX/Finish 3.wav")]


func _ready() -> void:
	_hide()
	
	player3D = get_tree().get_nodes_in_group("Player3D")
	if player3D.size() > 0:
		player_3d = player3D[0]
	
	if viewport and viewport_quad and player_3d:
		# Advertise self to global group
		add_to_group("3DLevel")
		
		# Setup viewport
		viewport.handle_input_locally = false
		viewport.gui_disable_input = true
		player_3d.subviewport = viewport
		
		# Clear the viewport
		viewport.set_clear_mode(SubViewport.CLEAR_MODE_ONCE)
		
		# Set the viewport texture
		viewport_quad.material_override.albedo_texture = viewport.get_texture()
		
		# Connect viewport area signals
		viewport_area.input_event.connect(_on_viewport_input_event)


func _on_viewport_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if viewport and player_3d and player_3d.is_in_subviewport:
		if not event.is_action("interact"):
			viewport.push_input(event)


func _on_visibility_changed():
	if self.visible:
		set_collision_layer_value(1, true)
		set_process(true)
		toggle_area_collisions(true)
	else:
		set_collision_layer_value(1, false)
		set_process(false)
		toggle_area_collisions(false)


func _show():
	show()
	_on_visibility_changed()


func _hide():
	hide()
	_on_visibility_changed()


func toggle_area_collisions(enable: bool) -> void:
	# 1) Grab the Area3D node itself
	var killzone_area = get_node("Killzone 3D") as Area3D
	if killzone_area:
		killzone_area.monitoring = enable
	
	# 2) Grab the child CollisionShape3D
	var shape = get_node("Killzone 3D/CollisionShape3D") as CollisionShape3D
	if shape:
		shape.call_deferred("set_disabled", not enable)


func open_door():
	# Return if door is already open
	if is_door_open:
		return
		
	var animation_player: AnimationPlayer = get_node("Door3D/Door/AnimationPlayer")
	is_door_open = true
	animation_player.play("open_door")
	audio_player.stream = finish_sound[randi_range(0, finish_sound.size() - 1)]
	audio_player.play()


func close_door(speed_multiplier: float = 1.0):
	# Return if door is already closed
	if not is_door_open:
		return
	
	var animation_player: AnimationPlayer = get_node("Door3D/Door/AnimationPlayer")
	is_door_open = false
	animation_player.play("open_door", -1, -1.0 * speed_multiplier, true)
	
	await animation_player.animation_finished
	emit_signal("door_close_animation_finished")
