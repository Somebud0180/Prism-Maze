extends GridMap

signal door_close_animation_finished
var is_door_open = false


func _ready() -> void:
	_hide()
	
	var viewport = $SubViewport
	if viewport != null:
		# Clear the viewport.
		$SubViewport.set_clear_mode(SubViewport.CLEAR_MODE_ONCE)

		# Retrieve the texture and set it to the viewport quad.
		$ViewportQuad.material_override.albedo_texture = viewport.get_texture()


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
		shape.disabled = not enable


func open_door():
	# Return if door is already open
	if is_door_open:
		return
		
	var animation_player: AnimationPlayer = get_node("Door3D/Door/AnimationPlayer")
	is_door_open = true
	animation_player.play("open_door")


func close_door(speed_multiplier: float = 1.0):
	# Return if door is already closed
	if not is_door_open:
		return
	
	var animation_player: AnimationPlayer = get_node("Door3D/Door/AnimationPlayer")
	is_door_open = false
	animation_player.play("open_door", -1, -1.0 * speed_multiplier, true)
	
	await animation_player.animation_finished
	emit_signal("door_close_animation_finished")
