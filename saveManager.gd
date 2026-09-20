extends Node

const SAVE_PATH = "user://save.cfg"
const TEMP_PATH = "user://save.tmp"
const BACKUP_PATH = "user://save.bak"
const SAVE_DELAY = 2.0

# world state (trees, npcs, items) lives apart from the flags: it is far bigger
# and only written at checkpoints, not on every flag change
const WORLD_PATH = "user://world.json"
const WORLD_TEMP = "user://world.tmp"
const WORLD_BACKUP = "user://world.bak"
const WORLD_VERSION = 2

# handed out once, the first time a save is missing them
const STARTING = {
	"Wooden Axe":{
		"has": true,
		"selected": true,
		},
	}

var playerName = "dennis"
var data = {}
var dirty = false
var saveTimer

func _ready() -> void:
	saveTimer = Timer.new()
	saveTimer.wait_time = SAVE_DELAY
	saveTimer.one_shot = true
	saveTimer.process_mode = Node.PROCESS_MODE_ALWAYS
	saveTimer.timeout.connect(flush)
	add_child(saveTimer)
	loadSave()

func _notification(what) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		flush()

func loadSave():
	data = {}
	for path in [SAVE_PATH,TEMP_PATH,BACKUP_PATH]:
		var config = ConfigFile.new()
		if config.load(path) != OK:
			continue
		for cat in config.get_sections():
			data[cat] = {}
			for item in config.get_section_keys(cat):
				data[cat][item] = config.get_value(cat,item)
		break
	seedDefaults()

func seedDefaults():
	for cat in STARTING:
		for item in STARTING[cat]:
			if not cat in data or not item in data[cat]:
				saveItem(cat,item,STARTING[cat][item])

func makeSave():
	data = {}
	seedDefaults()
	dirty = true
	flush()
	clearWorld()   # otherwise a new game loads the previous forest

func saveItem(cat,item,value):
	if not cat in data:
		data[cat] = {}
	data[cat][item] = value
	dirty = true
	saveTimer.start()

func getItem(cat,item):
	if not cat in data:
		return false
	return data[cat].get(item,false)

func flush():
	if not dirty:
		return
	var config = ConfigFile.new()
	for cat in data:
		for item in data[cat]:
			config.set_value(cat,item,data[cat][item])
	if config.save(TEMP_PATH) != OK:
		return
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.rename_absolute(SAVE_PATH,BACKUP_PATH)
	DirAccess.rename_absolute(TEMP_PATH,SAVE_PATH)
	dirty = false

# ---------- world state ----------
#
# The world (trees, npcs, items) is far bigger than the flags and only written at
# checkpoints, so it lives in its own file. The new one is written to a temp path
# and read back before it is allowed to replace anything, so a failed or truncated
# write leaves the previous save and its backup untouched.

func readWorld(path):
	if not FileAccess.file_exists(path):
		return null
	var payload = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(payload) != TYPE_DICTIONARY:
		return null
	if int(payload.get("v", 0)) != WORLD_VERSION:
		return null   # written by an older layout: better to regrow than half-load it
	return payload

func saveWorld(payload: Dictionary) -> bool:
	payload["v"] = WORLD_VERSION
	var f = FileAccess.open(WORLD_TEMP, FileAccess.WRITE)
	if not f:
		push_warning("could not open the world temp file for writing")
		return false
	f.store_string(JSON.stringify(payload))
	f.close()
	if readWorld(WORLD_TEMP) == null:
		push_warning("world save did not read back cleanly, keeping the previous save")
		return false
	if FileAccess.file_exists(WORLD_PATH):
		DirAccess.rename_absolute(WORLD_PATH, WORLD_BACKUP)
	DirAccess.rename_absolute(WORLD_TEMP, WORLD_PATH)
	return true

# newest first; each is parsed before it is accepted
func loadWorld():
	for path in [WORLD_PATH, WORLD_BACKUP]:
		var payload = readWorld(path)
		if payload != null:
			return payload
	return null

func hasWorld() -> bool:
	return loadWorld() != null

func clearWorld():
	for path in [WORLD_PATH, WORLD_TEMP, WORLD_BACKUP]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
