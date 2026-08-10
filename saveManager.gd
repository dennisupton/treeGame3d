extends Node

const SAVE_PATH = "user://save.cfg"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func makeSave():
	var config = ConfigFile.new()
	config.save(SAVE_PATH)

func saveItem(cat,item,value):
	var config = ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value(cat,item,value)
	config.save(SAVE_PATH)

func getItem(cat,item):
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err != OK:
		return false
	return config.get_value(cat,item, false)
