extends RigidBody3D

var held = false
@export var type = "basic"
var holdRotation = Vector3.ZERO
func _ready() -> void:
	applyType()

func applyType():
	var mat = $Icosphere.get_surface_override_material(0)
	if mat and type == "oak":
		mat = mat.duplicate()
		mat.albedo_color = Color("925a3e")
		$Icosphere.set_surface_override_material(0, mat)

func save():
	return {"type": type}

func restore(d):
	type = str(d.get("type", "basic"))
	applyType()

func _on_timer_timeout() -> void:
	if not held and get_parent().trySpawnTree(position, type):
		queue_free()
	$Timer.start()
