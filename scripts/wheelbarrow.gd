extends CharacterBody3D


@onready var slots = $logs.get_children()

@export var dragged = false

func freeSlot():
	for s in slots:
		if s.get_child_count() == 0:
			return s
	return null

func topLog():
	for i in range(slots.size() - 1, -1, -1):
		if slots[i].get_child_count() > 0:
			return slots[i].get_child(0)
	return null

func pickup(object):
	var slot = freeSlot()
	if not slot:
		return
	var oldPos = object.global_position
	object.freeze = true
	object.set_collision_layer_value(1, false)
	object.get_parent().remove_child(object)
	slot.add_child(object)
	object.global_position = oldPos
func save():
	var logs = []
	for s in slots:
		logs.append(get_parent().record(s.get_child(0)) if s.get_child_count() > 0 else null)
	return {"logs": logs}

func restore(d):
	for rec in d.get("logs", []):
		var l = get_parent().spawn(rec) if rec else null
		if l:
			pickup(l)

func _physics_process(delta: float) -> void:
	if not freeSlot():
		return
	for i in $Area3D.get_overlapping_bodies():
		if i.is_in_group("tree") and i.get_parent() == get_parent() and i.chopped == true:
			pickup(i)
			if not freeSlot():
				return
	for i in slots:
		if i.get_child_count()> 0:
			var child = i.get_child(0)
			child.position = lerp(child.position,Vector3.ZERO,0.2)
			child.rotation = lerp(child.rotation,Vector3.ZERO,0.2)
