extends RigidBody3D

var held = false
@export var mesh : Mesh
@export var sketch: PackedScene
var holdRotation = Vector3.ZERO
func preset(p):
	if p == "slide":
		mesh = load("res://scenes/slide.obj")
		sketch = load("res://scenes/slide.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
