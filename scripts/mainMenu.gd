extends Control

var random = RandomNumberGenerator.new()
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
	for i in range(4000):
		var child = tree.instantiate()
		var pos = Vector3(random.randf_range(-200,200),0,random.randf_range(-200,200))
		while tooClose(pos) or Vector3.ZERO.distance_to(pos) < 2 :
			pos = Vector3(random.randf_range(-200,200),0,random.randf_range(-200,200))
		child.position = pos
		treePositions.append(pos)
		add_child(child)
		child.setAge(4)
		child.still = true
	# "continue" is a GDScript keyword, so this one has to be fetched by string
	var cont = get_node("VBoxContainer/CenterContainer/VBoxContainer/continue")
	var canContinue = SaveManager.hasWorld()
	cont.disabled = not canContinue
	if canContinue:
		cont.grab_focus(true)
	else:
		$VBoxContainer/CenterContainer/VBoxContainer/newGame.grab_focus(true)
func _process(delta: float) -> void:
	$Node3D/Path3D/PathFollow3D.progress += 0.005


func _on_continue_pressed() -> void:
	# main.tscn rebuilds the saved world itself on _ready
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_new_game_pressed() -> void:
	SaveManager.makeSave()
	get_tree().change_scene_to_file("res://scenes/office.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_settings_pressed() -> void:
	$AnimationPlayer.play("enterSettings")
