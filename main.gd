extends Node3D

var money = 0
var random = RandomNumberGenerator.new()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tree = preload("res://tree.tscn")
	for i in range(500):
		var child = tree.instantiate()
		child.position = Vector3(random.randf_range(-100,100),0,random.randf_range(-100,100))
		add_child(child)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
