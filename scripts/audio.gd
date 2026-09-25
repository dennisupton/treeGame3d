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
@export var musicFade = 1.2       # seconds for a whole cross between two tracks
const MUSIC_SILENT = -60.0

@onready var musicVolume = $music.volume_db   # the level the track is meant to sit at
var musicTween: Tween
var musicTarget = ""              # clip the running fade is heading for

# one tween at a time, so a new request cancels whatever was mid-fade
func musicFadeTo(db, time) -> Tween:
	if musicTween and musicTween.is_valid():
		musicTween.kill()
	musicTween = create_tween()
	musicTween.tween_property($music, "volume_db", db, time)
	return musicTween

func applyClip(clipName) -> void:
	$music.get_stream_playback().switch_to_clip_by_name(clipName)
	if not $music.playing:
		$music.playing = true

# down to silence, swap the clip, back up. never cuts.
func crossTo(clipName) -> void:
	if musicTarget == clipName:
		return                      # already heading there; _process asks every frame
	musicTarget = clipName
	var t = musicFadeTo(MUSIC_SILENT, musicFade * 0.5)
	t.tween_callback(applyClip.bind(clipName))
	t.tween_property($music, "volume_db", musicVolume, musicFade * 0.5)

# fade the whole way out and stop
func silenceMusic(time = -1.0) -> void:
	musicTarget = ""
	var t = musicFadeTo(MUSIC_SILENT, musicFade if time < 0.0 else time)
	t.tween_callback(func(): $music.playing = false)

# start again from nothing
func resumeMusic() -> void:
	if $music.playing:
		musicFadeTo(musicVolume, musicFade)
		return
	$music.volume_db = MUSIC_SILENT
	$music.playing = true
	musicFadeTo(musicVolume, musicFade)

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
		if area == "seedmanAlley":
			return "seedman"
	return false

var wasWhistling = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not musicOverride:
		if not $music.playing:
			resumeMusic()
		if $music.get_stream_playback().get_current_clip_index() >= themeEnd and getClipArea():
			crossTo(getClipArea())
		if $music.get_stream_playback().get_current_clip_index() < themeEnd and !getClipArea() and $"..":
			crossTo("thenaturesurroundsyou")
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


func stopOverride():
	$musicOverride.stop()
	musicOverride = false
	musicTarget = ""
	resumeMusic()

func playTrack(clipName, time):
	overrideMusic(time)
	crossTo(clipName)

func _on_music_override_timeout() -> void:
	stopOverride()
