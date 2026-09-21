extends Control

@export var talkSpeed = 50    # ms between letters — lower = faster typing
@export var soundSpeed = 85  # ms between speaking blips — lower = faster sounds

# after the last letter lands, a line holds for a beat so it can actually be read
@export var readBase = 0.35
@export var readPerLetter = 0.025
@export var readPauseMax = 1.5

var person   # the npc being shopped from; owns the voice and the AudioStreamPlayer3D

var sayId = 0   # bumped per line, so a superseded say() stops waiting
var skipWanted = false   # a click waiting to be spent on the current line
var fx

@onready var label = $talking/MarginContainer/RichTextLabel
@onready var button = preload("res://scenes/choice.tscn")
func _ready() -> void:
	fx = BounceFX.new()
	label.install_effect(fx)
	label.text = ""
	hide()

func _input(event):
	if visible and event.is_action_pressed("Chop"):
		skipWanted = true

func takeSkip() -> bool:
	if not skipWanted:
		return false
	skipWanted = false
	return true

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
			"whatSecret":
				await say("hahaha")
				await say("nice try")
				await say("is it really that hard to help the people around you?")
				makeButtons(["kinda","no"],["hardToHelp","bye"],mayor)
			"hardToHelp":
				await say("im sure you will find a way")
				if SaveManager.getItem("kids","seenSlide"):
					await say("you seemed fine helping the kids with their slide")
				stop()
	else:
		if SaveManager.getItem("mrgray","gathered2"):
			await say("thank you for coming")
		elif SaveManager.getItem("mayor","metEveryone"):
			await say("hey, whats up?")
			makeButtons(["so whats the next secret","nothing much"],["whatSecret","bye"],mayor)
		elif SaveManager.getItem("toby","met") and SaveManager.getItem("enriquez","met") and SaveManager.getItem("dylan","met") and SaveManager.getItem("kids","met"):
			await say("good job! you met everyone")
			await say("now for my end of the deal")
			$"../../audio".overrideMusic(90)
			$"../../audio/music".get_stream_playback().switch_to_clip_by_name("mainTheme")
			await say("you may be wondering why so many people would gather in the middle of nowhere and start a village")
			await say("so allow me to let you in on a secret")
			await say("the well , which stands at the center of it all...")
			await say("has the power to change organic material into money")
			await say("the reason i had you meet all the villagers first is because in the wrong hands this well could be bad")
			await say("but you have proven your worth to me")
			await say("so i allow you to use it")
			await say("and if you would like to know more about the secrets of our valley")
			await say("you will need to continue to help the people in it")
			await say("but you should never let the knowledge of this well leave the village")
			await say("anyway")
			await say("go try it out!")
			await wait(1)
			await say("hold on")
			await say("before you go")
			await say("colin and may left something for you")
			SaveManager.saveItem("mayor","metEveryone",true)
			var child = load("res://scenes/sketch.tscn").instantiate()
			$"../..".add_child(child)
			child.position = $"../../townhall/itemSpawn".global_position
			await say("some kind of drawing?")
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
					person.setFace("stare")
					person.playAnim("what")
					await say("wow you actually had the money")
					person.setFace("normal")
					person.playAnim("lean")
					await say("to be honest with you")
					await say("i didnt think you were gonna have enough")
					await say("considering your clothing situation")
					await say("but anyway")
					await say("i left the shoes in that dressing room over there")
					await say("have fun!")
					SaveManager.saveItem("Trainers","has",true)
					makeButtons(["bye"],["bye"],enriquez)
			"buyGloves":
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
					$"../..".money -= 30
					await say("thank you!")
					await say("ive left them in the changing room again")
					await say("because me personally")
					await say("i refrain from changing gloves in public")
					await say("anyway have fun!")
					SaveManager.saveItem("Gloves","has",true)
					person.playAnim("idle")
					stop()
			"buyHat":
				if $"../..".money >= 100:
					$"../..".money -= 100
					await say("i see you have true taste darling")
					await say("not a lot of people have that these days")
					await say("so as your magnificento reward")
					await say("i present...")
					await say("le chapeau")
					await wait(2)
					await say("wait")
					await say("WHERE IS IT")
					await say("NONONONOONONONONONONONONONONONO")
					await say("oh wait")
					await say("its in the wardrobe")
					await say("oops")
					SaveManager.saveItem("Hat","has",true)
					stop()
				else:
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
		# TELL PLAYER ENRIQUEZ GAVE FLOWER
		if SaveManager.getItem("enriquez","gotFlower"):
			await say("i havent managed to give her the flower yet darling")
			await say("but when i do i will let you know!")
			stop()
		elif SaveManager.saveItem("enriquez","toldToGetFlower",true):
			if $"../../player/player/hold".get_child(0).name == "blueFlower":
				await say("thank you!")
				await say("i was kinda sending you on a wild goose chase")
				await say("since last i checked there were none")
				await say("but you found one!")
				await say("il make sure to mention you when i give this to holly")
				await say("shes gonna love it")
				SaveManager.saveItem("enriquez","gotFlower",true)
				stop()
			else:
				await say("i know youre busy darling")
				await say("but i would really like it if you got that flower for holly")
				await say("remember its just east of here by the river")
				stop()
		elif SaveManager.getItem("seedman","givenOak"):
			await say("i need a favour from you")
			await say("its a very very small favour")
			await say("so you know how holly is not doing so great")
			await say("and i want to make her feel better")
			await say("the only problem is...")
			await say("i cant leave the village")
			await say("because i might get my precious legs dirty")
			await say("so i wanted to see if you could grab something for me")
			await say("ages ago before she got ill")
			await say("holly and i would create fabulous outfits and show eachother")
			await say("and through that she showed me this amazing technique")
			await say("when making her dresses")
			await say("she would put all sorts of random things from the ground into he dress")
			await say("flowers , grass,  leaves and all sorts")
			await say("and it resulted in these magical dresses")
			await say("that melted your eyes when you saw them")
			await say("it was weird to me")
			await say("as the things she put in her dress were things i saw everyday")
			await say("were things i saw everyday and didnt think much about")
			await say("but somewho by crafting them together")
			await say("they looked so different")
			await say("the only problem was")
			await say("that after a while the flowers and such would wilt and die")
			await wait(1)
			await say("but that "+SaveManager.playerName)
			await wait(1)
			await say("is what made it truely special")
			await wait(1)
			await say("anyway")
			await say("one of her favourite flowers to do it with was this beautiful blue one")
			await say("that grows east of here by the river")
			await say("can you grab it and bring it back to me?")
			await say("good luck!")
			SaveManager.saveItem("enriquez","toldToGetFlower",true)
			stop()

		elif SaveManager.getItem("Hat","has"):
			if not SaveManager.getItem("Hat","selected"):
				await say("i am INSULTED")
				await say("i spent years conceptualizing and designing le chapeau")
				await say("just for you to not even wear it")
				await say("no, no excuses")
				await say("i need a moment")
				stop()
			else:
				await say("darling, you look FABULOUS")
				await say("if i were you, i would not go into a bar with that on")
				await say("you might get crushed by all the people swarming you")
				await say("stay magneficent darling")
				stop()
		if SaveManager.getItem("enriquez","offeredHat"):
			await say("so are you ready for ...")
			await say("le chapeau")
			await say("yet?")
			makeButtons(["yes (100$)","no"],["buyHat","bye"],enriquez)
		elif SaveManager.getItem("mrgray","gathered"):
			await say("i see you have to come to see my new fashion statement")
			await say("it is called ...")
			await say("le chapeau")
			await say("which is french for the hat")
			await say("fancy right")
			await say("although toby called it a lumberjack hat")
			await say("IT IS NOT A LUMBERJACK HAT")
			await say("it is a fashion statement that looks similar to a lumberjack hat")
			await say("and its yours for the low price of 100")
			SaveManager.saveItem("enriquez","offeredHat",true)
			makeButtons(["il buy it (100$)","im okay"],["buyHat","bye"],enriquez)
		elif SaveManager.getItem("Gloves","has"):
			await say("now that your hands are all fixed up")
			await say("you should try nail polish")
			await say("i think you would look fabulous")
			await say("anyway right now im working on a new fashion statement")
			await say("its not done yet so i cant show you")
			await say("and NO PEEKING")
			await say("so run along")
			stop()
		elif SaveManager.getItem("enriquez","offeredGloves"):
			await say("ive gotta say")
			await say("those hands are looking worse by the day")
			await say("oop!")
			await say("im a poet and i didnt even know it!")
			await say("hahaha")
			await say("so you ready to get your hands protected?")
			makeButtons(["yes! (100$)","no"],["buyGloves","bye"],enriquez)
		elif SaveManager.getItem("Trainers","has") and SaveManager.getItem("kids","seenSlide"):
			person.playAnim("lean")
			await say("welcome back darling")
			await say("might i add...")
			await say("those shoes look fabulous on you")
			await say("who gave them to you")
			await say("hahahaha")
			await say("the one thing i was noticing though")
			await say("do you really cut trees with your bare hands ")
			await say("like with an axe or whatever")
			await say("but hon you need gloves")
			await say("lucky for you")
			await say("ive got the perfect pair")
			await say("they will help you chop faster and they are only 100 bucks")
			makeButtons(["yeah sure il get them","im alright"],["buyGloves","bye"],enriquez)
		elif SaveManager.getItem("Trainers","has"):
			await say("so how are those new shoes working out for you")
			if SaveManager.getItem("Trainers","selected"):
				await say("they look quite nice on you")
			await say("you should pop back here in a bit")
			await say("ive got a little something for you")
			await say("but ive gotta go now")
			await say("so see ya!")
			stop()
		elif SaveManager.getItem("enriquez","offeredShoes"):
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
		match dialouge:
			"bye":
				await say("ok bye")
				stop()
			"buyCopperAxe":
				if $"../..".money >= 150:
					$"../..".money -= 150
					await say("thank you!")
					await say("i left the axe on the rack over there for you!")
					SaveManager.saveItem("Copper Axe","has",true)
					stop()
				else:
					await say("uhh")
					await say("in order to buy the axe")
					await say("you kinda of need to have the money")
					await say("sorry")
					stop()
			"i knew":
				await say("oh well")
				await say("cant hurt to hear it again huh")
			"i didnt know":
				await say("the more you know!")
				await say("you pick up a surpising amount of random facts being a blacksmith")
				stop()
			"cant donate":
				await say("dont worry about it")
				await say("honestly")
				await say("but if someday you think you can")
				await say("you can always come back")
				await say("thank you for considering")
				$"../../audio".stopOverride()
				stop()
			"donate":
				if $"../..".money >= 400:
					$"../..".money -= 400
					await say("thank you so so much")
					await say("honestly i dont know what i would do without you")
					await say("have a great day")
					SaveManager.saveItem("toby","donated",true)
					stop()
				else:
					await say("as much as i would love to take any amount")
					await say("i just cant because it makes it more complicated")
					await say("it sounds odd")
					await say("i dont know how to explain it")
					await say("but if someday you think you can help out")
					await say("you can always come back")
					stop()
				$"../../audio".stopOverride()
	else:
		if SaveManager.getItem("toby","donated"):
			await say("thanks again for the money")
			await say("the doctors said that its looking much better for her")
			await say("staying alive wise")
			stop()
		elif SaveManager.getItem("toby","donationOffered"):
			await say("hey um")
			await say("did you manage to pull together any money for hollys medicine?")
			makeButtons(["i would be glad (400)","i cant sorry"],["donate","cant donate"],toby)
		elif SaveManager.getItem("seedman","givenOak"):
			await say("hey um")
			await say("this is kind of weird to ask")
			await say("and im sorry if this insults you")
			await say("but...")
			$"../../audio".playTrack("medicine", 99999999999)
			await say("as you know my wife holly is quite ill")
			await say("and its been very hard looking after her")
			await say("but now the doctor said he has a new medication he thinks will help")
			await say("the only problem is...")
			await say("it is quite pricey")
			await say("now i completely understand if you cant help out")
			await say("and i wont hold it against you")
			await say("but if you did ...")
			await say("it would really help me out")
			SaveManager.saveItem("toby","donationOffered",true)
			makeButtons(["i would be glad (400)","i cant sorry"],["donate","cant donate"],toby)

		elif SaveManager.getItem("Copper Axe","has"):
			await say("did you know that the reason copper is orange")
			await say("is because the metal absorbs blue and green light")
			await say("which means that its mostly redness that hits our eyes")
			makeButtons(["yes i knew that","no"],["i knew","i didnt know"],toby)
		elif SaveManager.getItem("toby","offeredCopperAxe"):
			await say("hey hows it going")
			await say("no chance you remember that axe i offered")
			await say("you up for buying it?")
			makeButtons(["sure (150)","nah not today"],["buyCopperAxe","bye"],toby)
		elif SaveManager.getItem("mrgray","gathered"):
			await say("hey "+SaveManager.playerName)
			await say("i gotta come clean")
			await say("that axe i gave you...")
			await say("was kinda just whatever i had lying around")
			await say("so ive been working on a new axe for you thats made of copper")
			await say("and its a lot stronger")
			await say("so whaddya say")
			await say("for 150 its yours")
			SaveManager.saveItem("toby","offeredCopperAxe",true)
			makeButtons(["sure (150)","im okay thanks"],["buyCopperAxe","bye"],toby)
		elif SaveManager.getItem("kids","seenSlide") and SaveManager.getItem("Copper Axe","has"):
			await say("thank you for forgiving me")
			await say("i know that if i was in your shoes i wouldnt have")
			await say("by the way!")
			await say("im working on a new axe at the moment so you should come check back later!")
			stop()
		elif SaveManager.getItem("kids","seenSlide"):
			await say("thank you")
			await say("i heard you made my kids that slide")
			await say("i dont think you will ever understand the importance of your action")
			await say("its not just about the kindness")
			$"../../audio".playTrack("medicine", 120)
			await say("its just ...")
			await say("my life has been a sea storm")
			await say("ever since my wife holly got ill")
			await say("and you")
			await say("are the lighthouse")
			await say("showing me that these still land")
			#await say("holly used to say 'a flower to a fox is a peculiar sight but a flower for a bee is food for its whole family'")
			await say("sorry to get all fancy with my words")
			await say("i tend to get like this in situations like these")
			await say("i would like to appologize for before")
			await say("i wasnt having the best time")
			await say("but thats no excuse to be rude to a customer")
			$"../../audio".stopOverride()
			await say("how about i replace that that axe of yours")
			await say("i dont think ive ever seen an axe only made of wood before")
			await say("how does that even function?")
			await say("anyway ive left an axe on the rack over there for you")
			await say("i know i said it before but...")
			await say("thank you")
			SaveManager.saveItem("Bronze Axe","has",true)
			stop()
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
			"carryingSlow":
				await say("i have just the thing for you!")
				await say("a true marvel of engineering")
				await say("it is called ...")
				await say("a sheet")
				await say("hehe im just kidding")
				await say("but its actually quite useful")
				await say("basically you can use it to carry two logs along at once")
				await say("genius right?")
				await say("anywho its gonna set you back [color=green][wave]60[/wave][/color]")
				SaveManager.saveItem("dylan","offeredSheet",true)
				makeButtons(["sounds good!","im good"],["buySheet","bye"],dylan)
			"buySheet":
				if $"../..".money >= 60:
					$"../..".money -= 60
					await say("okie doke thank you very much")
					await say("ive left it outside for you!")
					var child = load("res://scenes/sheet.tscn").instantiate()
					$"../..".add_child(child)
					child.position = $"../../dylansHouse2/itemSpawn".global_position
					await say("hope it helps")
					await say("and remember")
					await say("if you run into any more problems")
					await say("im your guy!")
					SaveManager.saveItem("dylan","givenSheet",true)
					stop()
				else:
					await say("sorry i dont think thats enough")
					await say("dont worry though")
					await say("i know youl get there eventually!")
					stop()
			"buyWheelbarrow":
				if $"../..".money >= 600:
					$"../..".money -= 600
					await say("great!")
					await say("your gonna love it")
					await say("its right outside")
					var child = load("res://scenes/wheelbarrow.tscn").instantiate()
					$"../..".add_child(child)
					child.position = $"../../dylansHouse2/itemSpawn".global_position
					SaveManager.saveItem("dylan","givenWheelbarrow",true)
					stop()
				else:
					await say("sorry i dont think thats enough")
					await say("dont worry though")
					await say("i know youl get there eventually!")
					stop()
			"likeWheelbarrow":
				await say("aww thank you!")
				stop()
			"dislikeWheelbarrow":
				await say("oh okay")
				await say("dont worry though")
				await say("im working on bigger and better things")
				await say("trust me")
				stop()

	else:
		if SaveManager.getItem("extension","built"):
			await say("it looks amazing!")
			await say("thank you so much!")
			await say("im gonna get to work with it immedeatly")
			stop()
		elif SaveManager.getItem("dylan","givenSketch"):
			await say("so umm")
			await say("i dont mean to uhh")
			await say("hows the uhh extension going")
			await say("okay sorry i shouldnt have asked")
		elif SaveManager.getItem("toby","donated"):
			await say("thank goodness your here")
			await say("so ive been trying to design a better solution to help your carry stuff")
			await say("but my workshop is just so cramped")
			await say("and i know this is a lot to ask...")
			await say("but could you help me build an extension")
			await say("here i even have the design")
			#give design
			await say("also if you build this")
			await say("i think i will be able to help you out a lot more")
			await say("let me know when you finish")
			SaveManager.saveItem("dylan","givenSketch",true)
			stop()
		elif SaveManager.getItem("dylan","givenWheelbarrow"):
			await say("isnt that wheelbarrow just great")
			await say("im really proud of it")
			makeButtons(["yes!","no"],["likeWheelbarrow","dislikeWheelbarrow"],dylan)
		elif SaveManager.getItem("seedman","givenOak"):
			await say("guess who finshed their project!")
			await wait(2)
			await say("no like actualy take a guess")
			await wait(1)
			await say("tough crowd")
			await say("the answer was me")
			await say("i finished my project")
			await say("i made a wheelbarrow can hold 4 logs!")
			await say("which should be leagues better than that sheet")
			await say("so you ready to put it to work?")
			makeButtons(["yes! (600)","later"],["buyWheelbarrow","bye"],dylan)
		elif SaveManager.getItem("dylan","workingOnWheelbarrow"):
			await say("im still working on it, sorry")
			await say("come back later!")
			stop()
		elif SaveManager.getItem("dylan","toldToGetWheel"):
			if $"../../player/player/hold".get_child(0).name == "wheel":
				await say("wow you found it!")
				await say("its not finished yet so your gonna have to wait")
				await say("but please check in")
				SaveManager.saveItem("dylan","workingOnWheelbarrow",true)
				stop()
			else:
				await say("hows that wheel coming along")
				await say("remember, its just north of here")
				await say("cant miss it")
				stop()
		elif SaveManager.getItem("dylan","givenSheet") and SaveManager.getItem("Bronze Axe","has"):
			await say("youve come at the perfect time!")
			await say("ive come up with a new way for you to move logs!")
			await say("theres one problem tho...")
			await say("i need a wheel")
			await say("and i dont have one at the moment")
			await say("so i was wondering if you could grab me one")
			await say("theres one next to a house not far from here")
			await say("now im gonna be honest with you")
			await say("the house kinda scares me")
			await say("someone lives there but no one really knows who he is")
			await say("the house is just a bit north from here")
			await say("you cant miss it")
			await say("good luck!")
			SaveManager.saveItem("dylan","toldToGetWheel",true)
			stop()
		elif SaveManager.getItem("dylan","givenSheet"):
			await say("by the way")
			await say("be careful with that sheet")
			await say("it isnt the strongest")
			stop()
		elif SaveManager.getItem("dylan","offeredSheet"):
			await say("you ready to buy that sheet?")
			makeButtons(["yes! (60$)","im good"],["buySheet","bye"],dylan)
		elif SaveManager.getItem("dylan","met"):
			await say("welcome back!") 
			await say("so is there anything i can help you with?")
			if SaveManager.getItem("player","choppedTree"):
				makeButtons(["carrying logs is so slow"],["carryingSlow"],dylan)
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


func seedman(dialouge = false):
	if dialouge:
		match dialouge:
			"bye":
				await say("interesting...")
				await say("goodbye")
				stop()
			"buyOakSeed":
				if $"../..".money >= 500:
					$"../..".money -= 500
					await say("interestinggg")
					await say("veryyyy interestinggg")
					await say("i think il keep this")
					await say("...")
					await say("")
					await say("oh and completely unrelated, i have this random thing")
					await say("that im just gonna drop right here")
					await say("i hope you DONT take it...")
					var child = load("res://scenes/acorn.tscn").instantiate()
					child.type = "oak"
					$"../..".add_child(child)
					child.position = $"../../seedmanAlley/seedSpawn".global_position
					SaveManager.saveItem("seedman","givenOak",true)
					stop()
				else:
					await say("i think that money is a little too maybe potencially perhaps")
					stop()
			"lostOak":
				await say("how could you..")
				await say("its the size of your head!")
				await say("ok fine.")
				await say("i think i have another")
				await say("BUT THIS IS MY VERY LAST ONE")
				await say("its gonna be the same price as before")
				await say("but before we go any further ...")
				await say("since we are on the verge of blowing my cover")
				await say("we are going to need to act EXACTLY like we did before..")
				await say("so,")
				await say("do you maybe potencially perhaps have 500?")
				makeButtons(["maybe","potencially","perhaps","no"],["buyOakSeed","buyOakSeed","buyOakSeed","bye"],seedman)
			"didntLoseIt":
				await say("okay few")
				await say("i was scared you blew my cover for a second")
				await say("that could have been bad")
				await say("anyway go away before anyone sees!!!")
				stop()
	else:
		if SaveManager.getItem("seedman","givenOak"):
			await say("remember")
			await say("dont tell anyone")
			await say("not even the acorn")
			await say("it cant know its being trafficked")
			await say("hold on...")
			await say("dont tell me you lost it")
			await say("and not just like its grown into a tree")
			await say("like you lost it lost it")
			makeButtons(["maybe","potencially","perhaps","no"],["lostOak","lostOak","lostOak","didntLoseIt"],seedman)
		elif SaveManager.getItem("seedman","offeredOak2"):
			await say("shhhhhh")
			await say("there could be someone watching")
			await say("anyway")
			await say("do you maybe potencially perhaps have 500 now?")
			makeButtons(["maybe","potencially","perhaps","no"],["buyOakSeed","buyOakSeed","buyOakSeed","bye"],seedman)
		else:
			await say("so you decided to induge hmm?")
			await say("remember to keep this between us")
			await say("lets just say if you had 500 bucks...")
			await say("i could , potencially have something for you")
			await say("so,")
			await say("do you maybe potencially perhaps have 500?")
			SaveManager.saveItem("seedman","offeredOak2",true)
			makeButtons(["maybe","potencially","perhaps","no"],["buyOakSeed","buyOakSeed","buyOakSeed","bye"],seedman)
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
	skipWanted = false
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
		# first click fills the line in, but it still gets its full read beat
		if takeSkip():
			break
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
		# a second click cuts the beat short and moves on
		if takeSkip():
			return
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
