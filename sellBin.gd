extends StaticBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	checkBin()

func checkBin():
	for i in $Area3D.get_overlapping_bodies():
		if i.is_in_group("tree"):
			i.queue_free()
			$"..".money += 5
			$"../CanvasLayer/Control/Label".text = "$ "+str($"..".money)
			$"../audio/money".play()
