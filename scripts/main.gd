extends Node3D

var money = 0
var random = RandomNumberGenerator.new()
var acorn
var tree
var treePositions = []
var seperation = 3**2

var whoIsTalking = false
var animationLeader = false
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
		while tooClose(pos) or Vector3.ZERO.distance_to(pos) < 58 :
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

func getArea():
	if $player in $townhall/Area3D.get_overlapping_bodies():
		return "townhall"
	elif $player in $blacksmithHouse/Area3D.get_overlapping_bodies():
		return "blacksmithHouse"
	elif $player in $dylansHouse/Area3D.get_overlapping_bodies():
		return "dylansHouse"
	return false

func setLeader(NPC: String):
	animationLeader = $NPCs.get_node(NPC)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if whoIsTalking:
		$CanvasLayer/speech.size = Vector2.ZERO # re-fit to current text (top-level controls don't auto-shrink)
		var screen_pos = $player/camPivot/Camera3D.unproject_position(whoIsTalking.get_node("textBoxPos").global_position)
		$CanvasLayer/speech.position = Vector2(0,-40) + screen_pos - $CanvasLayer/speech.size/2.0
	if animationLeader:
		if not $player in animationLeader.get_node("Area3D").get_overlapping_bodies():
			$NPCs/cutscene.speed_scale = 0
		elif not animationLeader.needToStartCutscene:
			$NPCs/cutscene.speed_scale = 1
