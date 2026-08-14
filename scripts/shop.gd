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
	label.text = ""
	hide()

func start():
	if person:
		show()
		person.lookTarget = null
		person.look_at($"../../player".global_position, Vector3.UP)
		print("start")
		call(person.name)

func stop():
	hide()
	if person:
		person.stopPose()   # back to whichever idle suits where they're stood
	person = null
	$"../../player".freeze = false
	$"../../player".camPos = false

func mayor(dialouge = false):
	if dialouge:
		match dialouge:
			"cantFindPeople":
				if not SaveManager.getItem("kids","met"):
					await say("not everyone in the village lives in a shop")
					await say("maybe try looking around the village area?")
				else:
					await say("i dont know what to tell you sorry")
					await say("i cant magically locate people")
				await say("good luck!")
				stop()
			"meetingGood":
				await say("im glad")
				await say("come back when you've met everyone!")
				await say("i think you will like what i have to tell you")
				stop()
			"meetingBad":
				await say("im sorry to hear that")
				await say("it can be hard to fit in")
				await say("especially when people are so protective of their commuinity")
				await say("but thats what makes a community like this so valluble")
				if SaveManager.getItem("toby","met"):
					await say("and hey listen")
					await say("i know toby can be a little ... rude")
					await say("but just give him a bit and he will lighten up")
					await say("trust me")
				await say("just stay determined")
				stop()
	else:
		if SaveManager.getItem("toby","met") and SaveManager.getItem("enriquez","met") and SaveManager.getItem("dylan","met") and SaveManager.getItem("kids","met"):
			await say("good job! you met everyone")
			await say("now for my end of the deal")
			$"../../audio".overrideMusic(60)
			$"../../audio/music".get_stream_playback().switch_to_clip_by_name("mainTheme")
			await say("you may be wondering why so many people would gather in the middle of nowhere and start a village")
			await say("so allow me to let you in on a secret")
			await say("the well , which stands at the center of it all...")
			await say("has the power to change organic material into money")
			await say("the reason i had you meet all the villagers first is because in the wrong hands this well could be bad")
			await say("but you have proven your worth to me")
			await say("so i allow you to use it")
			await say("but you should never let the knowledge of this well leave the village")
			await say("anyway")
			await say("go try it out!")
			await wait(1)
			stop()
		else:
			await say("hey")
			await say("hows meeting everyone going")
			if SaveManager.getItem("toby","met"):
				await say("i know toby can be a little ... rude")
				await say("but just give him a bit and he will lighten up")
				await say("trust me")
			makeButtons(["i havent met all of them yet?","good","bad"],["cantFindPeople","meetingGood","meetingBad"],mayor)

func enriquez(dialouge = false):
	if dialouge:
		match dialouge:
			"bye":
				person.playAnim("idle")
				await say("see ya [color=pink][wave]darlin[/wave][/color]!")
				stop()
			"who":
				person.setTone(10)
				person.setFace("stare")
				person.playAnim("what")
				await say("WHO AM I?")
				person.setTone(0)
				person.playAnim("heroic")
				person.setFace("heroic")
				person.get_node("spin").play("spin")
				await say("[color=pink][wave]darrrlllingggg[/wave][/color]")
				await say("you are talking to the designer,model and GLOBALLL SUPERSTAR")
				person.setTone(10)
				person.playAnim("pose")
				person.get_node("spin").play("spin")
				await say("ENRIQUEZ")
				person.setTone(0)
				await say("[font s=50]let that sink in[/font]")
				person.playAnim("eyeroll")
				person.setFace("eyeroll")
				await say("anyway")
				person.playAnim("lean")
				person.setFace("normal")
				await say("how can i help you")
				SaveManager.saveItem("enriquez","introduced",true)
				makeButtons(["how can i be fasionable then"],["fasionable"],enriquez)
			"fasionable":
				person.playAnim("what")
				person.setFace("heroic")
				await say("I thought youd never ask")
				person.playAnim("lean")
				person.setFace("eyeroll")
				await say("so since you ran on in here")
				person.setFace("normal")
				await say("how about i hook you up with some running shoes")
				person.playAnim("point")
				await say("BUT")
				await say("dont get to hasty")
				person.get_node("spin").play("spin")
				await say("fashion isnt free [color=pink][wave]darling[/wave][/color]")
				person.playAnim("lean")
				await say("so im going to need to ask for [color=green][wave]30 buckaroos[/wave][/color] in return")
				SaveManager.saveItem("enriquez","offeredShoes",true)
				if not SaveManager.getItem("enriquez","introduced"):
					makeButtons(["who are you?"],["who"],enriquez)
				makeButtons(["can i get the shoes ($30)","bye"],["buyShoes","bye"],enriquez)
			"buyShoes":
				if $"../..".money < 30:
					person.playAnim("think")
					await say("sorry but i dont think thats gonna be enough")
					person.playAnim("eyeroll")
					person.setFace("heroic")
					await say("i wish i could just give them to you")
					person.setFace("stare")
					person.playAnim("what")
					person.setTone(10)
					await say("but then how would i buy more clothes")
					person.setTone(0)
					person.setFace("normal")
					person.playAnim("lean")
					await say("just come back when you got a bit more money")
					makeButtons(["bye"],["bye"],enriquez)
				else:
					await say("thank you so much")
	else:
		if SaveManager.getItem("enriquez","offeredShoes"):
			person.playAnim("lean")
			await say("so you ready to buy those shoes then?")
			if not SaveManager.getItem("enriquez","introduced"):
				makeButtons(["who are you?"],["who"],enriquez)
			makeButtons(["yes ($30)","no, bye"],["buyShoes","bye"],enriquez)
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
			SaveManager.saveItem("enriquez","met",true)
			makeButtons(["who are you?"],["who"],enriquez)


var tobyIntroTimes = 0
func toby(dialouge = false):
	if dialouge:
		pass
	else:
		person.playAnim("lean")
		if tobyIntroTimes == 0:
			await say("...")
			await say("sorry but were closed")
			SaveManager.saveItem("toby","met",true)
			#await say("this town already has enough [color=#3D94C0][wave]weird folk[/wave][/color]")
		elif tobyIntroTimes == 1:
			await say("...")
			await say("please leave")
		elif tobyIntroTimes == 2:
			await say("leave...")
		elif tobyIntroTimes >= 3:
			await say("leave.")
		tobyIntroTimes += 1
		stop()

func dylan(dialouge = false):
	if dialouge:
		match dialouge:
			"bye":
				await say("see ya!")
				stop()
			"youGood":
				await say("okay yay!")
				await say("that must mean holly's advice is working!")
				await say("anyway what im meant to say next is")
				await say("what brings you to our town?")
				makeButtons(["i wish to destroy you","i needed to escape"],["executeDylan","escape"],dylan)
			"youBad":
				await say("okay")
				await say("il try and do better next time!")
				await say("so what brings you to our little town?")
				makeButtons(["i wish to destroy you","i needed to escape"],["executeDylan","escape"],dylan)
			"executeDylan":
				await say("haha!")
				await say("[shake rate=20.0 level=5][font s=60]youre joking right?[/font][/shake]")
				await wait(1)
				await say("of course youre joking!")
				await say("[shake rate=20.0 level=5][font s=60]i hope[/font][/shake]")
				await say("so how can i help you with destorying me?")
				makeButtons(["what do you do around here"],["whatDoYouDo"],dylan)
			"escape":
				await say("yeah we all did")
				await say("no one comes here for no reason")
				await say("legend has it theres some kind of spirit bringing us here")
				await say("but i dont believe it")
				await say("because we all came here of our own free will!")
				await say("right")
				await say("anyway enough of that spooky stuff")
				await say("is there anything i can help you with?")
				makeButtons(["what do you do around here"],["whatDoYouDo"],dylan)
			"whatDoYouDo":
				await say("oh me?")
				await say("its kinda weird")
				await say("but i like building stuff")
				await say("nothing in particular")
				await say("just whatever comes to mind")
				await say("or stuff to help people out")
				await say("so if you ever need something to help you out")
				await say("let me know!")
				await say("and il see what i can cook up")
				await say("have you got anything i can help you with?")
				await say("its okay if you dont")
				await say("i mean you just got here")
				makeButtons(["not really"],["bye"],dylan)

	else:
		if SaveManager.getItem("dylan","met"):
			await say("welcome back!") 
			await say("so is there anything i can help you with?")
			makeButtons(["not yet"],["bye"],dylan)

		else:
			await say("[shake rate=20.0 level=5]hello![/shake]")
			await wait(1)
			await say("[shake rate=20.0 level=5]nice to meet you![/shake]")
			await wait(1)
			await say("[shake rate=20.0 level=5]my name is dylan[/shake]")
			await say("sorry")
			await say("i get nervous meeting new people") 
			await say("[font s=60]did i do good?[/font]")
			SaveManager.saveItem("dylan","met",true)
			makeButtons(["you did fine","it was kinda awkward"],["youGood","youBad"],dylan)


func makeButtons(text,binds,function):
	var idx = 0
	for i in text:
		var child = button.instantiate()
		child.text = i
		child.set_script(load("res://scripts/button.gd"))
		child.pressed.connect(function.bind(binds[idx]))
		child.pressed.connect(removeButtons)
		$speechOptions.add_child(child)
		idx += 1

func removeButtons():
	for i in $speechOptions.get_children():
		$speechOptions.remove_child(i)

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

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
	audioPlayer.volume_db = person.volume
	audioPlayer.pitch_scale = randf_range(person.pitchRange.x, person.pitchRange.y) + person.tone / 10.0
	audioPlayer.play()
	person.pop()
