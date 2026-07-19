extends Node3D



@export var themeEnd = 3
func getClipArea():
	var area = $"..".getArea()
	if area:
		if area == "townhall":
			return "mayor"
		if area == "blacksmithHouse":
			return "blacksmith"
		if area == "dylansHouse":
			return "dylan"
	return false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if $music.get_stream_playback().get_current_clip_index() >= themeEnd and getClipArea():
		$music.get_stream_playback().switch_to_clip_by_name(getClipArea())
	if $music.get_stream_playback().get_current_clip_index() < themeEnd and !getClipArea() and $"..":
		$music.get_stream_playback().switch_to_clip_by_name("thenaturesurroundsyou")
	
