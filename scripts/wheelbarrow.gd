extends CharacterBody3D

const SLOTS = ["log1","log2"]

# false = pushed, the player rides it. true = dragged along behind them.
@export var dragged = false

func freeSlot():
	for s in SLOTS:
		if get_node(s).get_child_count() == 0:
			return get_node(s)
	return null

# last one in is the one that comes back out
func topLog():
	for i in range(SLOTS.size() - 1, -1, -1):
		var slot = get_node(SLOTS[i])
		if slot.get_child_count() > 0:
			return slot.get_child(0)
	return null

func pickup(object):
	var slot = freeSlot()
	if not slot:
		return
	object.freeze = true
	object.set_collision_layer_value(1, false)
	object.get_parent().remove_child(object)
	slot.add_child(object)
	object.position = Vector3.ZERO
	object.rotation = Vector3.ZERO

func _physics_process(delta: float) -> void:
	if not freeSlot():
		return
	for i in $Area3D.get_overlapping_bodies():
		# loose logs only. one the player is carrying is parented to them, not the
		# world, so this stops the barrow snatching back what was just taken out.
		if i.is_in_group("tree") and i.get_parent() == get_parent():
			pickup(i)
			if not freeSlot():
				return
