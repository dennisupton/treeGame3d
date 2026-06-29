extends CharacterBody3D


var numOfTrees = 0

func pickup(object):
	object.freeze = true
	object.set_collision_layer_value(1, false)
	get_parent().remove_child(object)
	$player/player/treeHold.add_child(object)
	object.position = Vector3.ZERO
	object.rotation = Vector3.ZERO

func _physics_process(delta: float) -> void:
	for i in $Area3D.get_overlapping_bodies():
		if i.is_in_group("tree") and numOfTrees < 2:
			pickup(i)
			numOfTrees += 1
