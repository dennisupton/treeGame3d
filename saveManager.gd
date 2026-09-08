extends Node

const SAVE_PATH = "user://save.cfg"
const TEMP_PATH = "user://save.tmp"
const BACKUP_PATH = "user://save.bak"
const SAVE_DELAY = 2.0

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
