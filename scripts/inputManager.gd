extends Node

enum Device { KEYBOARD_MOUSE, GAMEPAD }

var current_device: Device = Device.KEYBOARD_MOUSE
var controllerType
signal device_changed(device: Device)

func _ready():
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_update_controller_type()

func _on_joy_connection_changed(device_id: int, connected: bool):
	_update_controller_type()

func _input(event: InputEvent) -> void:
	var new_device := current_device

	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		new_device = Device.KEYBOARD_MOUSE
	elif event is InputEventJoypadButton:
		new_device = Device.GAMEPAD
	elif event is InputEventJoypadMotion:
		if absf(event.axis_value) > 0.5:   
			new_device = Device.GAMEPAD

	if new_device != current_device:
		current_device = new_device
		device_changed.emit(current_device)


func _update_controller_type():
	if Input.get_connected_joypads().is_empty():
		return
	var deviceID = Input.get_connected_joypads()[0]
	controllerType = get_controller_type(deviceID)

func get_controller_type(deviceID: int) -> String:
	var name = Input.get_joy_name(deviceID).to_lower()
	if "xbox" in name:
		return "xbox"
	elif "playstation" in name or "dualshock" in name or "dualsense" in name or "wireless controller" in name:
		return "playstation"
	elif "switch" in name or "joy-con" in name:
		return "nintendo"
	else:
		return "xbox"
