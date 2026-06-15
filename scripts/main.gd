extends Node3D

var money = 0
var random = RandomNumberGenerator.new()
var acorn
var tree
var treePositions = []
var seperation = 3**2

func tooClose(pos):
	for i in treePositions:
		if i.distance_squared_to(pos) < seperation:
			return true
	return false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tree = preload("res://scenes/tree.tscn")
	acorn = preload("res://scenes/acorn.tscn")

	for i in range(500):
		var child = tree.instantiate()
		var pos = Vector3(random.randf_range(-100,100),0,random.randf_range(-100,100))
		while tooClose(pos):
			pos = Vector3(random.randf_range(-100,100),0,random.randf_range(-100,100))
		child.position = pos
		treePositions.append(pos)
		add_child(child)
		child.setAge(4)

func spawnTree(pos):
	var child = tree.instantiate()
	pos.y = 0
	treePositions.append(pos)
	child.position = pos
	add_child(child)

func spawnAcorn(pos):
	var child = acorn.instantiate()
	child.position = pos
	add_child(child)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
