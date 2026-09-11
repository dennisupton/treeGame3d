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
const LOADING_SCENE = preload("res://scenes/loading.tscn")
const SLOTS = ["log1","log2"]
const SCENE_TREE = "res://scenes/tree.tscn"
const SCENE_ACORN = "res://scenes/acorn.tscn"
const SCENE_SKETCH = "res://scenes/sketch.tscn"
const SCENE_SLIDE = "res://scenes/slide.tscn"
const SCENE_SHEET = "res://scenes/sheet.tscn"
const SCENE_BARROW = "res://scenes/wheelbarrow.tscn"
const DYNAMIC = [SCENE_TREE, SCENE_ACORN, SCENE_SKETCH, SCENE_SLIDE, SCENE_SHEET, SCENE_BARROW]
const TREE_COUNT = 1800
const AUTOSAVE_SECONDS = 30.0

var loadingScreen = null
var worldReady = false
var autosaveLeft = AUTOSAVE_SECONDS

func _ready() -> void:
	tree = preload("res://scenes/tree.tscn")
	acorn = preload("res://scenes/acorn.tscn")
	await buildWorld()

func buildWorld():
	$player.freeze = true
	loadingScreen = LOADING_SCENE.instantiate()
	add_child(loadingScreen)
	await get_tree().process_frame

	var saved = SaveManager.loadWorld()
	if saved:
		loadingScreen.setStatus("remembering the forest")
		await applyWorld(saved)
	else:
		loadingScreen.setStatus("growing the forest")
		await generateWorld()

	await get_tree().physics_frame
	await get_tree().physics_frame
	loadingScreen.queue_free()
	loadingScreen = null
	$player.freeze = false
	worldReady = true

func progress(done, total, from, span):
	if loadingScreen:
		loadingScreen.setProgress(from + span * (float(done) / max(total, 1)))

func generateWorld():
	for i in range(TREE_COUNT):
		var child = tree.instantiate()
		var pos = Vector3(random.randf_range(-200,200),0,random.randf_range(-200,200))
		while tooClose(pos) or Vector3.ZERO.distance_to(pos) < 28 :
			pos = Vector3(random.randf_range(-200,200),0,random.randf_range(-200,200))
		child.position = pos
		treePositions.append(pos)
		add_child(child)
		child.setAge(4)
		if i % 60 == 0:
			progress(i, TREE_COUNT, 0.0, 1.0)
			await get_tree().process_frame
	progress(1, 1, 0.0, 1.0)

# ---------- world state ----------

func vec(v): return [v.x, v.y, v.z]
func toVec(a): return Vector3(a[0], a[1], a[2])

func treeRecord(t):
	return {"p": vec(t.position), "r": vec(t.rotation), "age": t.age,
		"chopped": t.chopped, "health": t.health}

# builds a tree already in its saved state, parented to the world
func makeTree(rec):
	var t = tree.instantiate()
	add_child(t)
	t.position = toVec(rec["p"])
	t.rotation = toVec(rec["r"])
	t.restore(rec.get("age", 4), rec.get("health", 10), rec.get("chopped", false))
	return t

func gatherWorld() -> Dictionary:
	var data = {"money": money, "trees": [], "acorns": [], "sketches": [],
		"slides": [], "carriers": [], "npcs": {}, "player": {}}
	for c in get_children():
		match c.scene_file_path:
			SCENE_TREE:
				data["trees"].append(treeRecord(c))
			SCENE_ACORN:
				data["acorns"].append({"p": vec(c.position), "r": vec(c.rotation)})
			SCENE_SKETCH:
				data["sketches"].append({"p": vec(c.position), "r": vec(c.rotation)})
			SCENE_SLIDE:
				data["slides"].append({"p": vec(c.position), "r": vec(c.rotation), "trees": c.trees})
			SCENE_SHEET, SCENE_BARROW:
				var logs = []
				for slot in SLOTS:
					var holder = c.get_node_or_null(slot)
					if holder and holder.get_child_count() > 0:
						logs.append(treeRecord(holder.get_child(0)))
					else:
						logs.append(null)
				data["carriers"].append({"scene": c.scene_file_path, "p": vec(c.position),
					"r": vec(c.rotation), "logs": logs})
	for n in $NPCs.get_children():
		data["npcs"][n.name] = {"p": vec(n.position), "r": vec(n.rotation),
			"activity": n.activity, "isIt": n.isIt}
	data["player"] = gatherPlayer()
	return data

func gatherPlayer():
	var pl = $player
	# holding is false when empty-handed, so it has to be forced to a string
	# before comparing: bool == String is an error, not just false
	var kind = str(pl.holding) if pl.holding else ""
	var out = {"p": vec(pl.position), "r": pl.get_node("player").rotation.y,
		"holding": kind, "held": null}
	if kind == "tree":
		var h = pl.get_node("player/treeHold")
		if h.get_child_count() > 0:
			out["held"] = treeRecord(h.get_child(0))
	elif kind == "acorn" or kind == "sketch":
		out["held"] = {}   # nothing to keep beyond the fact one is in hand
	return out

func clearDynamic():
	for c in get_children():
		if c.scene_file_path in DYNAMIC:
			remove_child(c)
			c.queue_free()
	for path in ["player/treeHold", "player/hold", "player/sketchHold"]:
		var holder = $player.get_node_or_null(path)
		if holder:
			for c in holder.get_children():
				holder.remove_child(c)
				c.queue_free()
	$player.holding = false
	$player.get_node("player/hands").hide()
	$player.get_node("player/hands2").hide()
	$player.get_node("player/sketchMesh").hide()
	treePositions.clear()

func applyWorld(data):
	clearDynamic()
	money = int(data.get("money", 0))
	var counter = get_node_or_null("CanvasLayer/Control/money")
	if counter:
		counter.snap()

	var trees = data.get("trees", [])
	for i in trees.size():
		var t = makeTree(trees[i])
		if not t.chopped:
			treePositions.append(t.position)
		if i % 60 == 0:
			progress(i, trees.size(), 0.0, 0.8)
			await get_tree().process_frame
	progress(1, 1, 0.0, 0.8)

	if loadingScreen:
		loadingScreen.setStatus("putting everything back")
	for rec in data.get("acorns", []):
		var a = acorn.instantiate()
		add_child(a)
		a.position = toVec(rec["p"])
		a.rotation = toVec(rec["r"])
	for rec in data.get("sketches", []):
		var k = load(SCENE_SKETCH).instantiate()
		add_child(k)
		k.position = toVec(rec["p"])
		k.rotation = toVec(rec["r"])
	for rec in data.get("slides", []):
		var sl = load(SCENE_SLIDE).instantiate()
		add_child(sl)
		sl.position = toVec(rec["p"])
		sl.rotation = toVec(rec["r"])
		sl.trees = int(rec.get("trees", 0))
		sl.reveal()
	await get_tree().process_frame

	for rec in data.get("carriers", []):
		var path = str(rec.get("scene", SCENE_BARROW))
		if not ResourceLoader.exists(path):
			continue
		var car = load(path).instantiate()
		add_child(car)
		car.position = toVec(rec["p"])
		car.rotation = toVec(rec["r"])
		for logRec in rec.get("logs", []):
			if logRec == null:
				continue
			car.pickup(makeTree(logRec))

	var npcs = data.get("npcs", {})
	for n in $NPCs.get_children():
		if not n.name in npcs:
			continue
		var rec = npcs[n.name]
		n.position = toVec(rec["p"])
		n.rotation = toVec(rec["r"])
		n.isIt = bool(rec.get("isIt", false))
		n.setActivity(str(rec.get("activity", "idle")))

	applyPlayer(data.get("player", {}))
	progress(1, 1, 0.0, 1.0)

func applyPlayer(rec):
	if rec.is_empty():
		return
	var pl = $player
	pl.position = toVec(rec["p"])
	pl.get_node("player").rotation.y = float(rec.get("r", 0.0))
	var held = rec.get("held", null)
	var kind = str(rec.get("holding", ""))
	if kind == "tree" and held != null:
		pl.pickup(makeTree(held))
		pl.holding = "tree"
	elif kind == "acorn":
		var a = acorn.instantiate()
		add_child(a)
		a.position = pl.position
		pl.pickup(a)
		a.held = true
		pl.holding = "acorn"
	elif kind == "sketch":
		var k = load(SCENE_SKETCH).instantiate()
		add_child(k)
		k.position = pl.position
		pl.pickup(k)
		k.held = true
		pl.holding = "sketch"

func saveWorldNow() -> bool:
	if not worldReady:
		return false
	return SaveManager.saveWorld(gatherWorld())

func _notification(what) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		saveWorldNow()
	#$NavigationRegion3D.bake_navigation_mesh(true)
func _process(delta: float) -> void:
	if not worldReady:
		return
	autosaveLeft -= delta
	if autosaveLeft <= 0.0:
		autosaveLeft = AUTOSAVE_SECONDS
		saveWorldNow()
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
