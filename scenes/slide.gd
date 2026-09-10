extends StaticBody3D

var trees = 0
@export var treesNeeded = 4

var startY
var clearY

func _ready() -> void:
	var box = $CSGCombiner3D/CSGBox3D2
	var torus = $CSGCombiner3D/CSGTorus3D
	startY = box.position.y
	var top = torus.position.y + (torus.outer_radius - torus.inner_radius) / 2.0
	clearY = top + box.size.y / 2.0
	reveal()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("tree") and float(trees) / max(treesNeeded,1) < 1:
		body.queue_free()
		trees += 1
		reveal()

func reveal():
	var t = float(trees) / max(treesNeeded,1)
	$CSGCombiner3D/CSGBox3D2.position.y = lerp(startY, clearY, clampf(t, 0.0, 1.0))
	print(t)
	if t >= 1:
		SaveManager.saveItem("slide","done",true)
