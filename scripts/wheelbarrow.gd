extends CharacterBody3D

# every log marker the scene has, in the order they appear in it: the barrow carries
# four, the sheet two. giving a carrier more capacity is a marker, not a code change.
@onready var slots = get_children().filter(func(c): return c.name.begins_with("log"))

# false = pushed, the player rides it. true = dragged along behind them.
@export var dragged = false

func freeSlot():
	for s in slots:
		if s.get_child_count() == 0:
			return s
	return null

# last one in is the one that comes back out
func topLog():
	for i in range(slots.size() - 1, -1, -1):
		if slots[i].get_child_count() > 0:
			return slots[i].get_child(0)
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

# the logs in the slots are saved as records of their own, so a half-grown or
# half-chopped log comes back exactly as it went in
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
		# loose logs only. one the player is carrying is parented to them, not the
		# world, so this stops the barrow snatching back what was just taken out.
		if i.is_in_group("tree") and i.get_parent() == get_parent():
			pickup(i)
			if not freeSlot():
				return
