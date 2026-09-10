extends StaticBody3D

var trees = 0
@export var treesNeeded = 4

var startY
var clearY

func _ready() -> void:
	var box = $CSGCombiner3D/CSGBox3D2
	var torus = $CSGCombiner3D/CSGTorus3D
	startY = box.position.y
	# the box only has to rise until its underside clears the top of the mesh it
	# hides — travelling its own height overshoots and finishes the fill early
	var top = torus.position.y + (torus.outer_radius - torus.inner_radius) / 2.0
	clearY = top + box.size.y / 2.0
	reveal()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("tree"):
		body.queue_free()
		trees += 1
		reveal()

func reveal():
	var t = float(trees) / max(treesNeeded,1)
	$CSGCombiner3D/CSGBox3D2.position.y = lerp(startY, clearY, clampf(t, 0.0, 1.0))
