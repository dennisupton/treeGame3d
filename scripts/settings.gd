extends VBoxContainer

const languages = ["english"]
const resolutions = [
	Vector2i(800, 1280),
	Vector2i(1280, 720),
	Vector2i(1280, 800),
	Vector2i(1280, 1024),
	Vector2i(1360, 768),
	Vector2i(1366, 768),
	Vector2i(1440, 900),
	Vector2i(1600, 900),
	Vector2i(1680, 1050),
	Vector2i(1920, 1080),
	Vector2i(1920, 1200),
	Vector2i(2560, 1080),
	Vector2i(2560, 1440),
	Vector2i(2560, 1600),
	Vector2i(2880, 1800),
	Vector2i(3440, 1440),
	Vector2i(3840, 2160),
	Vector2i(5120, 1440),
]
var fullscreen = [DisplayServer.WINDOW_MODE_WINDOWED,DisplayServer.WINDOW_MODE_FULLSCREEN]
var selectors

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	selectors = {
		"language": $MarginContainer/PanelContainer/VBoxContainer/TabContainer/Game/Language/Language,
		"resolution": $MarginContainer/PanelContainer/VBoxContainer/TabContainer/Video/Resolution/OptionButton,
		"fullscreen": $MarginContainer/PanelContainer/VBoxContainer/TabContainer/Video/Fullscreen/CheckBox,
		"mainVolume": $MarginContainer/PanelContainer/VBoxContainer/TabContainer/Audio/mainVolume/HSlider,
		"music": $MarginContainer/PanelContainer/VBoxContainer/TabContainer/Audio/Music/HSlider,
		"SFX" : $MarginContainer/PanelContainer/VBoxContainer/TabContainer/Audio/SFX/HSlider
	}
	if not FileAccess.file_exists("user://settings.cfg"): # never booted game before
		var screen_size = DisplayServer.screen_get_size()
		var best = resolutions[0]
		var best_diff = INF
		for r in resolutions:
			var diff = (r - screen_size).length_squared()
			if diff < best_diff:
				best_diff = diff
				best = r
			best_diff = best_diff
		saveVal("video","resolution",resolutions.find(best))
		saveVal("video","fullscreen",true)
		DisplayServer.window_set_size(best)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	#load lists
	for i in languages:
		selectors["language"].add_item(i)
	
	for i in resolutions:
		selectors["resolution"].add_item(str(i.x)+"x"+str(i.y))
	
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		selectors["language"].selected = int(config.get_value("game", "language", 0))
		selectors["resolution"].selected = int(config.get_value("video", "resolution", 0))
		selectors["fullscreen"].button_pressed = bool(config.get_value("video", "fullscreen", 1))
		selectors["mainVolume"].value = config.get_value("audio", "mainVolume", 50)
	
	AudioServer.set_bus_volume_db(0, config.get_value("audio", "mainVolume", 50)-50)
	DisplayServer.window_set_size(resolutions[selectors["resolution"].selected])
	DisplayServer.window_set_mode(fullscreen[int(selectors["fullscreen"].button_pressed)])
func saveVal(category, field, val):
	var config = ConfigFile.new()
	config.set_value(category, field, val)
	config.save("user://settings.cfg")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_language_item_selected(index: int) -> void:
	saveVal("game","language",index)


func _on_apply_pressed() -> void:
	saveVal("video","resolution",selectors["resolution"].selected)
	saveVal("video","fullscreen",int(selectors["fullscreen"].button_pressed))
	DisplayServer.window_set_size(resolutions[selectors["resolution"].selected])
	DisplayServer.window_set_mode(fullscreen[int(selectors["fullscreen"].button_pressed)])

func volumeChanged(_value):
	saveVal("audio","mainVolume",selectors["mainVolume"].value)
	AudioServer.set_bus_volume_db(0, selectors["mainVolume"].value-50)


func _on_back_pressed() -> void:
	$"../AnimationPlayer".play("leaveSettings")
