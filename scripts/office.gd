extends Control

# Proxy properties so the "escape" animation can fade the audio buses.
# Buses aren't in the scene tree, so the AnimationPlayer animates these
# properties on `main` and the setters forward the value to the AudioServer.
@export var music_db: float = -40.0:
	set(value):
		music_db = value
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), value)
@export var sfx_db: float = 0.0:
	set(value):
		sfx_db = value
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), value)

# Email content lives in email_data.gd (class_name EmailData).
var emails = EmailData.EMAILS
var geraldEmails = EmailData.GERALD
var escapeEmails = EmailData.ESCAPE

var escapeSongs = [
	{"stream": preload("res://music/escape1.ogg"), "volume": -16},
	{"stream": preload("res://music/escape2.ogg"), "volume": -16},
	{"stream": preload("res://music/escape3.ogg"), "volume": -16},
	{"stream": preload("res://music/escape4.ogg"), "volume": -16},
	{"stream": preload("res://music/escape5.ogg"), "volume": -16},
]

var index = -1
var geraldIndex = -1
# True when the next Gerald email is allowed to spawn (the previous one has
# been read, or none has been sent yet).
var geraldReady = true
var random = RandomNumberGenerator.new()
var email
var escapeIndex = 0
var escapeReady = true
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	email = preload("res://scenes/email.tscn")
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	$OS/split/Content/Content.email_opened.connect(_on_email_opened)
	# Apply the starting bus levels: music quiet, sfx full (until escape fades them).
	music_db = music_db
	sfx_db = sfx_db

func go():
	get_tree().change_scene_to_file("res://scenes/transition.tscn")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Chop"):
		$click.play()


func _on_email_timer_timeout() -> void:
	$emailTimer.wait_time = 2+(random.randi_range(5,8)/((index+2)*0.5))
	$emailTimer.start()
	if $OS/split/Inbox/Emails.get_child_count()<8 and escapeReady:
		if index>10+escapeIndex*2:
			spawn_email(escapeEmails[escapeIndex])
			escapeIndex += 1
			$AnimationPlayer.speed_scale = 1
			$AnimationPlayer.play("escape")
			playEscape(escapeIndex-1)
			escapeReady = false
			lock_inbox(true)
		if geraldReady and len(geraldEmails) > geraldIndex+1 and random.randi_range(1,2) == 2 and index>2:
			geraldIndex += 1
			geraldReady = false
			spawn_email(geraldEmails[geraldIndex])
			$new.play()
		elif len(emails) > index+1:
			index += 1
			spawn_email(emails[index])

			$new.play()


func playEscape(song_index: int) -> void:
	var song = escapeSongs[song_index]
	$escape.stream = song["stream"]
	$escape.volume_db = song["volume"]
	$escape.play()


func spawn_email(data) -> void:
	var child = email.instantiate()
	child.text = data["subject"]
	child.set_meta("data", data)
	if not data["urgent"]:
		child.icon = null
	if data["subject"] == "[NO SUBJECT]":
		child.z_index = 2
		# Match the green whisper styling on the inbox button text too.
		child.add_theme_color_override("font_color", Color("#2e7d32"))
		child.add_theme_color_override("font_hover_color", Color("#2e7d32"))
		child.add_theme_color_override("font_pressed_color", Color("#2e7d32"))
		child.add_theme_color_override("font_focus_color", Color("#2e7d32"))
	child.pressed.connect($OS/split/Content/Content.open_email.bind(child))
	$OS/split/Inbox/Emails.add_child(child)
	if not escapeReady and data["subject"] != "[NO SUBJECT]":
		child.disabled = true


func lock_inbox(locked: bool) -> void:
	# Disable every inbox button except the escape ([NO SUBJECT]) ones.
	for child in $OS/split/Inbox/Emails.get_children():
		if child is Button:
			child.disabled = locked and child.get_meta("data")["subject"] != "[NO SUBJECT]"


func _on_email_opened(data) -> void:
	# Reading the current Gerald email unlocks the next one.
	if data.get("boss", false):
		geraldReady = true
	if data.get("subject") == "[NO SUBJECT]":
		escapeReady = true
		lock_inbox(false)
		$OS/split/Content/Content.clear()
		$escape.stop()
		$AnimationPlayer.speed_scale = -1
		$AnimationPlayer.play("escape")
