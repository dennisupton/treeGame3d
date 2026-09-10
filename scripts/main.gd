extends Node3D

var money = 0
var random = RandomNumberGenerator.new()
var acorn
var tree
var treePositions = []
var seperation = 3**2



@onready var theme = preload("res://theme.tres")
@onready var glyph = preload("res://scenes/glyph.tscn")

func tooClose(pos):
	for i in treePositions:
		if i.distance_squared_to(pos) < seperation:
			return true
	return false
func reloadCollision():
	$NavigationRegion3D.bake_navigation_mesh(true)
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
	await get_tree().physics_frame
	await get_tree().physics_frame
	#$NavigationRegion3D.bake_navigation_mesh(true)
func _process(delta: float) -> void:
	$CanvasLayer/bubbles.visible = not $player.freeze
	spawnGlyphs()
func trySpawnTree(pos):
	if not tooClose(pos):
		spawnTree(pos)
		return true
	return false
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

var shownGlyphs = []
var glyphState = []

func spawnGlyphs():
	var state = [InputManager.current_device, InputManager.controllerType, shownGlyphs.duplicate(true)]
	if state == glyphState:
		return
	glyphState = state
	for i in $CanvasLayer/glyphs.get_children():
		i.queue_free()
	for i in shownGlyphs:
		var child = glyph.instantiate()
		var events = InputMap.action_get_events(i[0])
		for event in events:
			if InputManager.current_device == InputManager.Device.KEYBOARD_MOUSE:
				if event is InputEventMouseButton:
					child.type = "mouse"
				elif event is InputEventKey:
					child.type = "keyboard"
				else:
					continue
			elif InputManager.current_device == InputManager.Device.GAMEPAD:
				if event is InputEventJoypadMotion:
					child.joystick = true
				elif not (event is InputEventJoypadButton):
					continue
				child.type = InputManager.controllerType
			child.glyph = event
			break
		if not child.glyph:
			child.queue_free()
			continue
		var label = Label.new()
		label.theme = theme
		label.add_child(child)
		child.position = Vector2(-32,35)
		label.name = i[0]
		label.text = i[1]
		label.label_settings = LabelSettings.new()
		label.label_settings.font_size = 50
		$CanvasLayer/glyphs.add_child(label)
