extends Node

enum Device { KEYBOARD_MOUSE, GAMEPAD }

var current_device: Device = Device.KEYBOARD_MOUSE
signal device_changed(device: Device)

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
