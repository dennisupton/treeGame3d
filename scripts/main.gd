extends Node3D

var money: int = 0:
	set(value):
		money = value
		SaveManager.saveItem("player","money",value)
var random = RandomNumberGenerator.new()
var acorn
var tree
var treePositions = []
var seperation = 3**2



@onready var theme = preload("res://theme.tres")
@onready var glyph = preload("res://scenes/glyph.tscn")

func tooClose(pos):
	for i in $noTree.get_children():
		if not i.canSpawnTreeAt(pos):
			return true
	for i in treePositions:
		if i.distance_squared_to(pos) < seperation:
			return true
	return false
func reloadCollision():
	$NavigationRegion3D.bake_navigation_mesh(true)
# Called when the node enters the scene tree for the first time.
const LOADING_SCENE = preload("res://scenes/loading.tscn")
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
	# money saves on every change with the rest of the flags, so a shop flag can never
	# be written without the price having come off too
	money = int(SaveManager.getItem("player","money"))
	$CanvasLayer/Control/money.snap()
	await buildWorld()

func buildWorld():
	$player.freeze = true
	loadingScreen = LOADING_SCENE.instantiate()
	add_child(loadingScreen)
	await get_tree().process_frame

	var saved = SaveManager.loadWorld()
	if saved:
		loadingScreen.setStatus("remembering")
		await applyWorld(saved)
	else:
		loadingScreen.setStatus("growing")
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
		add_child(child)
		child.position = pos
		while tooClose(pos):
			pos = Vector3(random.randf_range(-200,200),0,random.randf_range(-200,200))
			child.position = pos
		treePositions.append(pos)
		child.setAge(4)
		if i % 60 == 0:
			progress(i, TREE_COUNT, 0.0, 1.0)
			await get_tree().process_frame
	progress(1, 1, 0.0, 1.0)

# ---------- world state ----------
#
# One record per thing: the scene it came from, where it is, and whatever the thing
# itself chooses to remember through its own save()/restore(). Nothing down here
# knows what a tree or a barrow or an acorn is, so a new kind of thing only needs
# those two methods on its own script and nothing changes in this file.

func vec(v): return [v.x, v.y, v.z]
func toVec(a): return Vector3(a[0], a[1], a[2])

func record(n) -> Dictionary:
	var rec = {"s": n.scene_file_path, "n": str(n.name), "p": vec(n.position), "r": vec(n.rotation)}
	if n.has_method("save"):
		rec["d"] = n.save()
	return rec

# rebuild one record. `reuse` (and anything with no scene behind it, like the wheel)
# means the one already standing in main.tscn gets moved back instead of duplicated.
func spawn(rec, parent = self, reuse = false):
	var path = str(rec.get("s", ""))
	var n = parent.get_node_or_null(str(rec.get("n", ""))) if reuse or path.is_empty() else null
	if not n:
		if not ResourceLoader.exists(path):
			return null
		n = load(path).instantiate()
		parent.add_child(n)
	n.position = toVec(rec["p"])
	n.rotation = toVec(rec["r"])
	if n.has_method("restore"):
		n.restore(rec.get("d", {}))
	return n

func gatherWorld() -> Dictionary:
	var data = {"items": [], "npcs": [], "player": gatherPlayer()}
	for c in get_children():
		if c.scene_file_path in DYNAMIC or c.is_in_group("thing"):
			data["items"].append(record(c))
	for n in $NPCs.get_children():
		# the spawn markers live under here too and have none of this on them
		if n is CharacterBody3D:
			data["npcs"].append(record(n))
	return data

func gatherPlayer():
	var pl = $player
	# holding is false when empty-handed, so it has to be forced to a string before
	# comparing: bool == String is an error, not just false
	var out = {"p": vec(pl.position), "r": pl.get_node("player").rotation.y,
		"holding": str(pl.holding) if pl.holding else "", "held": null}
	for holder in ["player/treeHold", "player/hold", "player/sketchHold"]:
		var h = pl.get_node(holder)
		if h.get_child_count() > 0:
			out["held"] = record(h.get_child(0))
	return out

func clearDynamic():
	for holder in [self, $player.get_node("player/treeHold"), $player.get_node("player/hold"),
		$player.get_node("player/sketchHold")]:
		for c in holder.get_children():
			if c.scene_file_path in DYNAMIC:
				holder.remove_child(c)
				c.queue_free()
			elif holder != self:
				c.reparent(self)   # hand-placed props like the wheel are not ours to destroy
	$player.holding = false
	$player.get_node("player/hands").hide()
	$player.get_node("player/hands2").hide()
	$player.get_node("player/sketchMesh").hide()
	treePositions.clear()

func applyWorld(data):
	clearDynamic()
	var items = data.get("items", [])
	for i in items.size():
		var n = spawn(items[i])
		if n and n.scene_file_path == SCENE_TREE and not n.chopped:
			treePositions.append(n.position)
		if i % 60 == 0:
			progress(i, items.size(), 0.0, 0.9)
			await get_tree().process_frame

	if loadingScreen:
		loadingScreen.setStatus("putting everyone back")
	await get_tree().process_frame
	# villagers who start in main.tscn are moved back; anyone who turned up mid-game,
	# like the seedman, is built from the scene he was saved with
	for rec in data.get("npcs", []):
		spawn(rec, $NPCs, true)
	applyPlayer(data.get("player", {}))
	progress(1, 1, 0.0, 1.0)

func applyPlayer(rec):
	if rec.is_empty():
		return
	var pl = $player
	pl.position = toVec(rec["p"])
	pl.get_node("player").rotation.y = float(rec.get("r", 0.0))
	var held = rec.get("held", null)
	if held == null:
		return
	var n = spawn(held)
	if not n:
		return
	if "held" in n:
		n.held = true
	pl.pickup(n)
	pl.holding = str(rec.get("holding", ""))


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
func trySpawnTree(pos, kind = "basic"):
	if not tooClose(pos):
		spawnTree(pos, kind)
		return true
	return false
func spawnTree(pos, kind = "basic"):
	var child = tree.instantiate()
	child.type = kind
	pos.y = 0
	treePositions.append(pos)
	child.position = pos
	add_child(child)

func spawnAcorn(pos, kind = "basic"):
	var child = acorn.instantiate()
	child.type = kind
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
	elif $player in $seedmanAlley/Area3D.get_overlapping_bodies():
		return "seedmanAlley"
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
