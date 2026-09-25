extends RigidBody3D

var held = false
@export var mesh : Mesh
@export var sketch: PackedScene
var holdRotation = Vector3.ZERO
@export var sketchName = "nothing"   # which building, saved so a dropped one survives
func preset(p):
	sketchName = p
	mesh = load("res://models/%s.obj" % p)
	sketch = load("res://scenes/%s.tscn" % p)

func save():
	return {"name": sketchName}

func restore(d):
	preset(str(d.get("name", sketchName)))
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
