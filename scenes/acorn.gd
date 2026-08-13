extends RigidBody3D

var held = false

func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_timer_timeout() -> void:
	if not held and get_parent().trySpawnTree(position):
		queue_free()
	$Timer.start()
