extends StaticBody3D

var trees = 0
@export var treesNeeded = 4

var startY
var clearY

func _ready() -> void:
	var box = $CSGCombiner3D/CSGBox3D2
	startY = box.position.y
	# lifting the cutting box its own height clears the torus entirely
	clearY = startY + box.size.y
	reveal()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("tree"):
		body.queue_free()
		trees += 1
		reveal()

func reveal():
	var t = float(trees) / max(treesNeeded,1)
	$CSGCombiner3D/CSGBox3D2.position.y = lerp(startY, clearY, clampf(t, 0.0, 1.0))
