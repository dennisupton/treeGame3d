extends Label

var dispAmount = 0
var speed = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	dispAmount = move_toward(dispAmount,float($"../../..".money),0.1)
	visible =  int(dispAmount) >0
	text = "$"+str(int(dispAmount))
	if dispAmount == $"../../..".money:
		offset_transform_position = lerp(offset_transform_position,Vector2.ZERO,0.03)
		label_settings.shadow_size = lerp(label_settings.shadow_size,0,0.3)
		speed = lerp(speed,0.0,0.3)
	else:
		offset_transform_position = lerp(offset_transform_position,Vector2(0,-0),0.1)
		label_settings.shadow_size = lerp(label_settings.shadow_size,50,0.3)
		speed = lerp(speed,1.4,0.3)
	material.set_shader_parameter("speed",speed)
