extends Node3D

var _busFades := {}
var musicOverride = false

func fadeBus(bus_name: String, target_db: float, duration := 2.0) -> Tween:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		push_warning("fadeBus: no bus named '%s'" % bus_name)
		return null
	var running = _busFades.get(idx)
	if running and running.is_valid():
		running.kill()
	AudioServer.set_bus_mute(idx, false)
	var tween := create_tween()
	_busFades[idx] = tween
	tween.tween_method(
		func(db): AudioServer.set_bus_volume_db(idx, db),
		AudioServer.get_bus_volume_db(idx), target_db, duration)
	return tween


func fadeInBus(bus_name := "Master", duration := 2.0, from_silence := true) -> void:
	if from_silence:
		var idx := AudioServer.get_bus_index(bus_name)
		if idx != -1:
			AudioServer.set_bus_volume_db(idx, -80.0)
	fadeBus(bus_name, 0.0, duration)

## Fade out to silence. `mute_after` mutes the bus once silent.
func fadeOutBus(bus_name := "Master", duration := 2.0, mute_after := false) -> void:
	var tween := fadeBus(bus_name, -80.0, duration)
	if tween and mute_after:
		var idx := AudioServer.get_bus_index(bus_name)
		tween.tween_callback(func(): AudioServer.set_bus_mute(idx, true))

@export var themeEnd = 4
func getClipArea():
	var area = $"..".getArea()
	if area:
		if area == "townhall":
			return "mayor"
		if area == "blacksmithHouse":
			return "blacksmith"
		if area == "dylansHouse":
			return "dylan"
		if area == "fashionHouse":
			return "fashion"
	return false

var wasWhistling = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not musicOverride:
		if $music.get_stream_playback().get_current_clip_index() >= themeEnd and getClipArea():
			$music.get_stream_playback().switch_to_clip_by_name(getClipArea())
		if $music.get_stream_playback().get_current_clip_index() < themeEnd and !getClipArea() and $"..":
			$music.get_stream_playback().switch_to_clip_by_name("thenaturesurroundsyou")
	if $"../player".whistling:
		fadeOutBus("SFX",3)
		fadeOutBus("Music",3)
		wasWhistling = true
	elif wasWhistling:
		wasWhistling = false
		fadeInBus("SFX",1.5)
		fadeInBus("Music",1.5)

func overrideMusic(time):
	musicOverride = true
	$musicOverride.wait_time = time
	$musicOverride.start()

func _on_music_override_timeout() -> void:
	musicOverride = false
