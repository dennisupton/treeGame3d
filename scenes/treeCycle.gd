extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for i in get_overlapping_bodies():
		if i.is_in_group("tree"):
			$"..".money += 10
			i.queue_free()
		elif i is RigidBody3D:
			i.position = $respawn.global_position
