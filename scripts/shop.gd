extends Control

@export var talkSpeed = 50    # ms between letters — lower = faster typing
@export var soundSpeed = 85  # ms between speaking blips — lower = faster sounds

# after the last letter lands, a line holds for a beat so it can actually be read
@export var readBase = 0.35
@export var readPerLetter = 0.025
@export var readPauseMax = 1.5

var person   # the npc being shopped from; owns the voice and the AudioStreamPlayer3D

var sayId = 0   # bumped per line, so a superseded say() stops waiting
var fx

@onready var label = $talking/MarginContainer/RichTextLabel
@onready var button = preload("res://scenes/choice.tscn")
func _ready() -> void:
	fx = BounceFX.new()
	label.install_effect(fx)
	label.install_effect(ArcFX.new())
	label.text = ""
	hide()

func start():
	if person:
		show()
		person.lookTarget = null
		person.look_at($"../../player".global_position, Vector3.UP)
		print("start")
		call(person.name)

func mayor(dialouge = false):
	if dialouge:
		pass
	else:
		pass


func enriquez(dialouge = false):
	print(dialouge)
	if dialouge:
		match dialouge:
			"who":
				person.setTone(10)
				person.setFace("stare")
				person.playAnim("what")
				await say("WHO AM I?")
				person.setTone(0)
				person.playAnim("eyeroll")
				person.setFace("eyeroll")
				await say("[color=pink][wave]darrrlllingggg[/wave][/color]")
				await say("you are talking to the designer,model and GLOBALLL SUPERSTAR")
				person.setTone(10)
				await say("ENRIQUEZ")
				person.setTone(0)
	else:
		person.setFace("stare")
		person.playAnim("shock")
		person.setTone(10)
		await say("what on earth are you wearing")
		person.playAnim("idle")
		#person.setFace("shocked")
		person.setTone(0)
		await say("we gotta get you fixed up [color=pink][wave]darling[/wave][/color]")
		person.playAnim("heroic")
		person.setFace("heroic")
		person.get_node("spin").play("spin")
		await say("no one in my town will ever be non-[rainbow freq=1.0 sat=0.8 val=0.8 speed=1.0]fabulouseoue!!![/rainbow]")
		person.playAnim("eyeroll")
		person.setFace("eyeroll")
		await say("except [color=brown]Toby[/color] maybe")
		person.playAnim("idle")
		person.setFace("normal")
		await say("hes kinda a lost cause")
		person.playAnim("eyeroll")
		person.setFace("eyeroll")
		await say("ANYWAYYY")
		person.playAnim("lean")
		person.setFace("eyeroll")
		await say("other than your desperate need for clothes")
		person.setFace("normal")
		await say("what brings you to my humble abode?")
		makeButtons(["who are you?"],["who"],enriquez)

func toby(dialouge = false):
	if dialouge:
		pass
	else:
		pass

func dylan(dialouge = false):
	if dialouge:
		pass
	else:
		pass


func makeButtons(text,binds,function):
	var idx = 0
	for i in text:
		var child = button.instantiate()
		child.text = i
		child.set_script(load("res://scripts/button.gd"))
		child.pressed.connect(function.bind(binds[idx]))
		$speechOptions.add_child(child)
		idx += 1



func say(text: String) -> void:
	fx.reset()
	sayId += 1
	var id = sayId

	# set the full (bbcode-parsed) text up front, then reveal it letter by
	# letter with visible_characters, which skips tag markup on its own
	label.visible_characters = 0
	label.text = "[bounce]" + text + "[/bounce]"
	var totalVisible = label.get_total_character_count()

	var revealed = 0
	var letterTimer = 0.0
	var soundTimer = 0.0
	while revealed < totalVisible and sayId == id:
		await get_tree().process_frame
		var delta = get_process_delta_time()
		soundTimer += delta * 1000.0
		if soundTimer > soundSpeed:
			soundTimer = 0.0
			playBlip()

		letterTimer += delta * 1000.0
		if letterTimer > talkSpeed:
			letterTimer = 0.0
			revealed += 1
			label.visible_characters = revealed
	label.visible_characters = -1
	# hold the floor for a beat once fully revealed, so the line can be read
	var readTimer = minf(readBase + text.length() * readPerLetter, readPauseMax)
	while readTimer > 0.0 and sayId == id:
		await get_tree().process_frame
		readTimer -= get_process_delta_time()

func playBlip() -> void:
	if not person:
		return
	var audioPlayer = person.get_node_or_null("AudioStreamPlayer3D")
	if not audioPlayer or person.syllables.is_empty():
		return
	audioPlayer.stream = person.syllables.pick_random()
	audioPlayer.pitch_scale = randf_range(person.pitchRange.x, person.pitchRange.y) + person.tone / 10.0
	audioPlayer.play()
	person.pop()
