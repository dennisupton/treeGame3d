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

	for i in range(1800):
		var child = tree.instantiate()
		var pos = Vector3(random.randf_range(-200,200),0,random.randf_range(-200,200))
		while tooClose(pos) or Vector3.ZERO.distance_to(pos) < 28 :
			pos = Vector3(random.randf_range(-200,200),0,random.randf_range(-200,200))
		child.position = pos
		treePositions.append(pos)
		add_child(child)
		child.setAge(4)

func _process(delta: float) -> void:
	$CanvasLayer/bubbles.visible = not $player.freeze
	
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

func getArea():
	if $player in $townhall/Area3D.get_overlapping_bodies():
		return "townhall"
	elif $player in $blacksmithHouse/Area3D.get_overlapping_bodies():
		return "blacksmithHouse"
	elif $player in $dylansHouse/Area3D.get_overlapping_bodies():
		return "dylansHouse"
	elif $player in $fashionHouse/Area3D.get_overlapping_bodies():
		return "fashionHouse"
	return false
