extends StaticBody3D

var trees = 0
@export var treesNeeded = 4
@export var maxHeight = 4


func _ready() -> void:
	reveal()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("tree") and float(trees) / max(treesNeeded,1) < 1:
		body.queue_free()
		trees += 1
		reveal()

func save():
	return {"trees": trees}

func restore(d):
	trees = int(d.get("trees", 0))
	reveal()

func reveal():
	var t = float(trees) / max(treesNeeded,1)
	$solid.get_surface_override_material(0).set_shader_parameter("cut_height",lerp(0, maxHeight, clampf(t, 0.0, 1.0)))
	print(t)
	if t >= 1:
		$sketch.hide()
		SaveManager.saveItem(name,"done",true)
