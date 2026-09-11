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
const WORLD_VERSION = 1

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
# Every write is wrapped as {version, hash, data} where data is the payload as a
# JSON string and hash is its sha256. That makes a truncated or corrupted file
# detectable rather than silently loading as half a world.
#
# The good save is never touched until the new one has been written AND read back
# AND verified, so a failure at any point leaves the previous save intact.

func wrapWorld(payload: Dictionary) -> String:
	var text = JSON.stringify(payload)
	return JSON.stringify({
		"version": WORLD_VERSION,
		"hash": text.sha256_text(),
		"data": text,
	})

# returns the payload, or null if the file is missing, unreadable, truncated,
# corrupted, or from a version we do not understand
func readWorld(path):
	if not FileAccess.file_exists(path):
		return null
	var f = FileAccess.open(path, FileAccess.READ)
	if not f:
		return null
	var raw = f.get_as_text()
	f.close()
	if raw.is_empty():
		return null
	var outer = JSON.parse_string(raw)
	if typeof(outer) != TYPE_DICTIONARY:
		return null
	if not ("version" in outer and "hash" in outer and "data" in outer):
		return null
	if int(outer["version"]) != WORLD_VERSION:
		return null
	if typeof(outer["data"]) != TYPE_STRING:
		return null
	if outer["data"].sha256_text() != outer["hash"]:
		push_warning("world save failed its checksum: " + path)
		return null
	var payload = JSON.parse_string(outer["data"])
	if typeof(payload) != TYPE_DICTIONARY:
		return null
	return payload

func saveWorld(payload: Dictionary) -> bool:
	var f = FileAccess.open(WORLD_TEMP, FileAccess.WRITE)
	if not f:
		push_warning("could not open the world temp file for writing")
		return false
	f.store_string(wrapWorld(payload))
	f.close()

	# read the new file back before it is allowed to replace anything. if this
	# fails we still have both the old save and its backup untouched.
	if readWorld(WORLD_TEMP) == null:
		push_warning("world save did not read back cleanly, keeping the previous save")
		return false

	if FileAccess.file_exists(WORLD_PATH):
		DirAccess.rename_absolute(WORLD_PATH, WORLD_BACKUP)
	DirAccess.rename_absolute(WORLD_TEMP, WORLD_PATH)
	return true

# newest first; each is fully verified before it is accepted
func loadWorld():
	for path in [WORLD_PATH, WORLD_TEMP, WORLD_BACKUP]:
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
