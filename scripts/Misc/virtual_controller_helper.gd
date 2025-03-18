extends Node

class_name VirtualControllerHelper

# Define the method as static
static func get_virtual_controller():
	if Input.has_method("get_virtual_controller"):
		return Input.get_virtual_controller()
	else:
		return null