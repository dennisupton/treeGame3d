extends Node3D


const CutsceneScript = preload("res://scripts/cutscene.gd")
const Shop = preload("res://scripts/shop.gd")   # for cash(), so money is one green everywhere


var scenes = []   # cutscenes currently running




@onready var colin = $colin
@onready var may = $may
@onready var mayor = $mayor
@onready var toby = $toby
@onready var dylan = $dylan
@onready var enriquez = $enriquez

func _ready() -> void:
	await get_tree().process_frame
	while not get_parent().worldReady:
		await get_tree().process_frame
	if SaveManager.getItem("seedman","introduced") and not has_node("seedman"):
		var sm = load("res://scenes/seedman.tscn").instantiate()
		sm.position = $seedmanSpawn.position
		add_child(sm)
	if not SaveManager.getItem("mayor","introPlayed"):
		play("introduction")
	
	if SaveManager.getItem("kids","met"):
		if not SaveManager.getItem("kids","seenSlide") and SaveManager.getItem("slide","done"):
			play("kidsThanksForSlide")
		else:
			play("kidsPlayTag")
	else:
		play("kidsArgue")
		play("kidsIntro")
		play("kidsThanksForSlide")


func _process(_delta: float) -> void:
	for s in scenes:
		s.tick()
	if SaveManager.getItem("dylan","toldToGetWheel") and $"../player".position.distance_to($"../noTree/scaryHouse".position) < 25 and not "mrgray" in get_children().map(func(c): return c.name) and not SaveManager.getItem("mrgray","gathered"):
		play("evil1")
	if SaveManager.getItem("extension","built") and SaveManager.getItem("toby","donated") and SaveManager.getItem("enriquez","gotFlower") and $"../player".position.distance_to($"../noTree/village".position) > 25 and not "mrgray" in get_children().map(func(c): return c.name) and not SaveManager.getItem("mrgray","gathered2"):
		play("evil2")
	if $"../player".position.distance_to($seedmanSpawn.position) > 25 and SaveManager.getItem("Copper Axe","has") and not SaveManager.getItem("seedman","introduced"):
		play("seedmanIntro")
func play(sceneName: String, loop = false) -> void:
	while true:
		var s = CutsceneScript.new(self, sceneName)
		scenes.append(s)
		await call(sceneName, s)
		var takenOver = s.stopped   # someone else claimed the cast; don't barge back in
		s.release()
		scenes.erase(s)
		if not loop or takenOver:
			return
		await get_tree().process_frame


func freeNpc(npc) -> void:
	for s in scenes.duplicate():
		if npc in s.cast:
			s.stop()
			scenes.erase(s)
	npc.speedScale = 1.0
	npc.shutUp()


func faceEachOther(a, b) -> void:
	a.lookAtNode(b)
	b.lookAtNode(a)

func stopFacing(a, b) -> void:
	a.lookAway()
	b.lookAway()



func gather(s, crowd: Array, where: String, patience = 45.0) -> void:
	var spacing = {}
	var closest = {}
	for i in crowd.size():
		var npc = crowd[i]
		spacing[npc] = npc.nav.target_desired_distance
		npc.nav.target_desired_distance = 3.0 + i * 0.7
		closest[npc] = INF
		s.lane(func(): await npc.goto(where))

	var left = patience
	var still = 0.0   # seconds since anyone last made any ground
	while left > 0.0 and still < 3.0 and not s.stopped:
		await get_tree().process_frame
		var step = get_process_delta_time()
		left -= step
		still += step
		var spot = crowd[0].navPoint(where)
		for npc in crowd:
			# flat, so somebody stood below the navmesh doesn't read as short of it
			var d = npc.flatTo(spot).length()
			if d < closest[npc] - 0.1:
				closest[npc] = d
				still = 0.0

	for npc in crowd:
		stopWalking(npc)
		npc.nav.target_desired_distance = spacing[npc]

# drop a goto wherever they have got to, the same way arriving does
func stopWalking(npc) -> void:
	npc.whereTo = ""
	npc.gotoPending = 0
	npc.gotoId += 1
	npc.nav.target_position = npc.global_position


func waitUntil(cond: Callable) -> void:
	while not cond.call():
		await get_tree().process_frame

func playerNear(npc) -> bool:
	var area = npc.get_node_or_null("Area3D")
	return area != null and $"../player" in area.get_overlapping_bodies()



func introduction(s) -> void:
	await waitUntil(func(): return playerNear(mayor))
	SaveManager.saveItem("mayor","introPlayed",true)
	await s.take([mayor])
	s.gate = mayor 
	mayor.playAnim("jump")
	await mayor.goto("player")
	await s.wait(1.5)
	await mayor.say("are you lost?")
	await s.wait(1.5)
	await mayor.say("or right where you need to be?")
	await s.wait(1.5)
	await mayor.say("im the mayor by the way")
	await mayor.say("i got something to show you")
	await mayor.say("but first")
	await mayor.say("you might wanna introduce yourself to the community")
	await mayor.say("because who wants a stranger wandering round")
	await mayor.say("let me know when you are done")
	await mayor.say("ill be in the town hall")
	mayor.stopTalking()
	s.gate = null
	mayor.goto("townHall")

func kidsIntro(s):
	await waitUntil(func(): return playerNear(colin))
	await s.take([colin, may])
	await s.wait(1.5)   
	s.gate = colin
	await colin.goto("player")
	await may.goto("player")
	await s.wait(1.5)
	await colin.say("hello im may!")
	await may.say("and im colin")
	await s.wait(1.5)   
	faceEachOther(colin, may)
	await s.wait(0.5)   
	await colin.say("do you think we got him")
	await may.say("they TOTALLY thought i was you")
	may.setTone(10)
	colin.setTone(10)
	may.say("hehehehehehe")
	await colin.say("hehehehehehe")
	may.setTone(0)
	colin.setTone(0)
	stopFacing(colin, may)
	await may.say("so whats your name axe guy")
	faceEachOther(colin, may)
	await colin.say("the mayor said it was "+SaveManager.playerName)
	may.setTone(10)
	await may.say("SHUT UP")
	await may.say("the mayor said specifically")
	await may.say("that we needed to ask him for his name")
	await colin.say("yeah well why not")
	may.setTone(0)
	await may.say("i dont know")
	await colin.say("so why you telling me to shut up then")
	await may.say("because you should")
	await colin.say("meanie")
	stopFacing(colin, may)
	await colin.say("so mr tree guy")
	await colin.say("why do you like cutting trees")
	if SaveManager.getItem("player","choppedTree"):
		await colin.say("do you like to watch them bleed that gooey stuff")
		await may.say("ew colin dont be so disgusting")
		await colin.say("im just joking")
	else:
		await colin.say("wait you havent even chopped a tree yet")
		await colin.say("you should try it")
		await colin.say("just go up to a tree and whack it")
		await colin.say("its really fun")
	await may.say("okay but remember to replant")
	await may.say("trees drop acorns and if you put them in the ground...")
	await may.say("they make a whole other tree!!")
	await colin.say("may you know you can just leave them there")
	await colin.say("and they will eventually plant themselves")
	may.setTone(5)
	await may.say("but i like planting them!")
	colin.setTone(5)
	await colin.say("MAY I JUST HAD AN IDEA")
	faceEachOther(colin, may)
	may.setTone(-5)
	colin.setTone(-5)
	may.say("pspspspspspspsps")
	await colin.say("pspspspspspspsp")
	stopFacing(colin, may)
	may.setTone(0)
	colin.setTone(0)
	may.say("okay basically")
	await colin.say("our dad said he was gonna make us a climbing frame")
	may.setTone(5)
	await may.say("hey dont interupt me!")
	may.setTone(0)
	await colin.say("sowey")
	await may.say("okay basically")
	await may.say("our dad said he was gonna make us a climbing frame")
	await colin.say("hes the big guy who smashes metal together")
	may.setTone(5)
	await may.say("COLIN!")
	may.setTone(0)
	await colin.say("sowey")
	await may.say("but since our mom is very ill and buisness stuff")
	await may.say("he said he doesnt have the time")
	await colin.say("so we were thinking")
	await colin.say("since you are REALLY nice")
	await colin.say("and you cut down trees")
	await colin.say("what if you made us a slide")
	await may.say("we even made a drawing for you to make")
	may.say("PWEASEEEEEEEEEEE")
	await colin.say("PWEASEEEEEEEEEE")
	await colin.say("we also think it will make our dad gooder friends with you")
	await may.say("hes really mean to new people but after a bit hes really nice")
	await may.say("i promise")
	await colin.say("if you manage we would be really happy")
	await may.say("colin give him the drawing!")
	await colin.say("uhh")
	faceEachOther(colin, may)
	await may.say("what...")
	await colin.say("i left it in the town hall")
	may.setTone(5)
	await may.say("colinnnnnnn")
	may.setTone(0)
	stopFacing(colin,may)
	await colin.say("its okay "+SaveManager.playerName+" youre just gonna have to ask the mayor for it")
	await colin.say("sorry")
	await may.say("in the meantime we have some buisness to get to")
	SaveManager.saveItem("kids","met",true)
	colin.target = colin.get_path_to(may)
	may.target = may.get_path_to(colin)
	colin.startsIt = false
	may.startsIt = true
	colin.setActivity("tag")
	may.setActivity("tag")
func kidsArgue(s) -> void:
	await s.take([colin, may])
	colin.goto("may")
	faceEachOther(colin, may)
	await s.wait(0.5)   
	await colin.say("you smell")
	await may.say("no i dont!")
	await may.say("you smell!")
	await colin.say("yeah but not as bad as you!")
	await may.say("so you admit you smell?")
	await colin.say("no")
	await may.say("but you do")
	await s.wait(1.0)
	stopFacing(colin, may)

func kidsPlayTag(s):
	await s.take([colin, may])
	colin.target = colin.get_path_to(may)
	may.target = may.get_path_to(colin)
	colin.startsIt = false
	may.startsIt = true
	colin.setActivity("tag")
	may.setActivity("tag")

func kidsThanksForSlide(s):
	await waitUntil(func(): return SaveManager.getItem("slide","done"))
	SaveManager.saveItem("kids","met",true)
	await s.take([colin, may])
	stopFacing(colin, may)
	s.gate = colin
	await colin.goto("player")
	await may.goto("player")
	await s.wait(1.5)
	may.say("THANK YOU")
	await colin.say("THANK YOU")
	await may.say("you're the best tree guy!")
	await colin.say("look how tall it is may!")
	await may.say("i know right!")
	await colin.say("oh by the way")
	await colin.say("you should go see our dad")
	await colin.say("he probably got over whatever he didnt like you for")
	await colin.say("hes just like that sometimes")
	await may.say("colin get on the slide with meeeeeee")
	SaveManager.saveItem("kids","seenSlide",true)
	# start slide play here

func evil1(s) -> void:
	var mrgray = load("res://scenes/mrgray.tscn").instantiate()
	add_child(mrgray)
	mrgray.global_position = $graySpawn.global_position
	s.gate = mrgray
	var crowd = [mayor, toby, dylan, enriquez]
	await s.take(crowd + [mrgray])
	for npc in crowd + [mrgray]:
		npc.setActivity("idle")
	await gather(s, crowd, "mrgray")
	for npc in crowd:
		npc.lookAtNode(mrgray)
	mrgray.lookAtNode(s.player)
	await s.wait(2.0)
	await mrgray.say("what a lovely day it is today")
	await mayor.say("then it should be obvious why we arent leaving")
	await mrgray.say("oh come on")
	await mrgray.say("stop acting like you guys have a choice")
	await mrgray.say("as soon as i get the deed to the land it will be mine")
	await dylan.say("you mean bribe the goverment into giving you protected land")
	await mrgray.say("well either way the land will still be mine")
	await mrgray.say("so you guys better get to packing")
	await toby.say("we arent leaving")
	await mrgray.say("and what makes you think that")
	await toby.say("we built this town")
	await toby.say("with our own two hands")
	await mrgray.say("and im going to build even more")
	await mrgray.say("with even more hands!")
	await enriquez.say("mr gay read the room")
	await enriquez.say("its time for you to leave")
	await mrgray.say("MY NAME IS MY GRAY NOT MR GAY")
	await enriquez.say("oops i guess i was getting the wrong vibe")
	await enriquez.say("anyway")
	await enriquez.say("its time for you to leave")
	await mrgray.say("fine")
	await mrgray.say("but il be back")
	await mrgray.say("with bulldozers and trucks")
	await mrgray.say("bye bye!")
	for npc in crowd:
		npc.lookAway()
	mrgray.lookAway()
	mrgray.goto("npcExit")
	s.gate = null
	for npc in crowd:
		if npc != mayor and npc.shop in npc.HOUSES:
			npc.setActivity(npc.shop)
	await s.wait(2.0)
	await mayor.goto("player")
	s.gate = mayor
	await mayor.say("im sorry you had to see that")
	await mayor.say("weve tried everything")
	await mayor.say("but their lawers are just too powerfull")
	await mayor.say("and they just keep harrasing us")
	await mayor.say("so at this point in time")
	await mayor.say("i dont know what to do")
	await mayor.say("anyway apollogies for the distubance")
	await mayor.say("il let you get back to what you were doing")
	SaveManager.saveItem("mrgray","gathered",true)
	s.gate = null
	mayor.goto("townHall")
	await mrgray.goto("npcExit")
	mrgray.queue_free()

func evil2(s) -> void:
	var mrgray = load("res://scenes/mrgray.tscn").instantiate()
	add_child(mrgray)
	mrgray.global_position = $graySpawn.global_position
	SaveManager.saveItem("mrgray","gathered2",true)
	s.gate = mrgray
	var crowd = [mayor, toby, dylan, enriquez,may,colin]
	await s.take(crowd + [mrgray])
	for npc in crowd + [mrgray]:
		npc.setActivity("idle")
	await gather(s, crowd, "mrgray")
	for npc in crowd:
		npc.lookAtNode(mrgray)
	mrgray.lookAtNode(s.player)
	await s.wait(2.0)
	await mrgray.say("hello again")
	await mrgray.say("i can tell by the look on all of your faces that you all missed me!")
	may.say("mr gray")
	await colin.say("mr gray")
	may.say("go away")
	await colin.say("go away")
	may.say("mr gray")
	await colin.say("mr gray")
	may.say("go away")
	await colin.say("go away")
	await mrgray.say("adorable")
	await enriquez.say("i dont think they are playing around")
	await mayor.say("so leave!")
	await mrgray.say("hold on,")
	await mrgray.say("lets not be to hasty now")
	await mrgray.say("ive got something for you guys")
	await mayor.say("what")
	await mrgray.say("if you guys leave")
	await mrgray.say("i will give you each " + Shop.cash("10,000"))
	for i in crowd:
		i.say("no")
	await mayor.say("no")
	await mrgray.say("okay fine")
	await mrgray.say(Shop.cash("100,000"))
	for i in crowd:
		i.say("no")
	await mayor.say("youre pushing it")
	await mrgray.say("but the most i can do is")
	await mrgray.say(Shop.cash("1,000,000"))
	await mrgray.say("final offer")
	await toby.say("when are you going to understand")
	await toby.say("this isnt about money")
	await mrgray.say(Shop.cash("5,000,000") + "?")
	await toby.say("do you understand me?")
	await mrgray.say("but you guys use money here all the time")
	await mrgray.say("so whats the issue")
	await toby.say("theres a difference between the way we see money and the way you see it")
	await toby.say("money here is a custom")
	await toby.say("people only use it to reward other for their hard work")
	await toby.say("but")
	await toby.say("in your world")
	await toby.say("money is the strings on a puppets back")
	await toby.say("you use it to control people")
	await mrgray.say("i still dont see the difference")
	await toby.say("maybe one day you will understand but for now")
	await toby.say("you arent welcome here")
	await mrgray.say("whatever you say but il be back with a bigger and better deal")
	for npc in crowd:
		npc.lookAway()
	mrgray.lookAway()
	mrgray.goto("npcExit")
	s.gate = null
	for npc in crowd:
		if npc != mayor and npc.shop in npc.HOUSES:
			npc.setActivity(npc.shop)
	await s.wait(2.0)
	await mayor.goto("player")
	s.gate = mayor
	await mayor.say("he just wont go away will he")
	await mayor.say("its so weird")
	await mayor.say("his whole concept of money")
	await mayor.say("hold on!")
	await mayor.say("dont think your efforts have gone unnoticed")
	await mayor.say("when you have a minute come see me in the hall")
	s.gate = null
	mayor.goto("townHall")
	await mrgray.goto("npcExit")
	mrgray.queue_free()

func seedmanIntro(s) -> void:
	var child = load("res://scenes/seedman.tscn").instantiate()
	child.position = $seedmanSpawn.position
	add_child(child)
	SaveManager.saveItem("seedman","introduced",true)
	var seedman = $seedman
	await waitUntil(func(): return playerNear(seedman))
	$"../audio".overrideMusic(10)
	$"../audio".silenceMusic()
	await seedman.say("pssst")
	await seedman.say("hey you")
	await seedman.say("come over here")
	await s.wait(2.0)
	s.gate = seedman
	await waitUntil(func(): return playerNear(seedman))
	$"../audio".overrideMusic(20)
	$"../audio".silenceMusic()
	await seedman.say("ive got a deal for you")
	await seedman.say("a deal you cant turn down")
	await s.wait(1.0)
	await seedman.say("lets just say ive got some black market seeds")
	await seedman.say("so come talk to me if you want to learn more")
	s.gate = null
	$"../audio".stopOverride()
	SaveManager.saveItem("seedman","offeredOakSeed",true)

func mayorBench(s):
	var bench = $"../bench"
	if not bench:
		return
	await s.take([mayor])
	s.gate = mayor
	# he walks the whole way, however far the bench was built. a flat timeout made him
	# pop onto the seat on a long walk, so this waits on progress instead: he keeps
	# going as long as he is getting closer, and only gives up once he has been stuck
	# for a few seconds (a bench somewhere he genuinely cannot path to).
	var seat = bench.get_node("mayorSeat")
	mayor.goto("bench")
	var closest = INF
	var still = 0.0
	var left = 180.0
	while left > 0.0 and still < 4.0:
		var gap = mayor.flatTo(seat.global_position).length()
		if gap < 0.8:
			break
		await get_tree().process_frame
		var step = get_process_delta_time()
		left -= step
		still += step
		if gap < closest - 0.1:
			closest = gap
			still = 0.0
	mayor.sitAt(seat)
	await waitUntil(func(): return $"../player".sitting)
	# nothing but the river from here. the override goes on first, or audio.gd sees a
	# stopped track next frame and starts it again.
	$"../audio".overrideMusic(900)
	$"../audio".silenceMusic()
	await s.wait(1.5)
	'''
	await mayor.say("thank you for joining me here")
	await s.wait(1)
	await mayor.say("wow this bench is really good ")
	await mayor.say("nice job")
	await s.wait(3)
	await mayor.say("theres something just so beautiful about the river")
	await mayor.say("it just silences my mind")
	await mayor.say("the chaos of water just flowing through")
	await s.wait(3)
	await mayor.say("a wise woman once told me")
	await mayor.say("'your family arent just the people your related to'")
	await mayor.say("which to me, says a lot about you")
	await s.wait(1)
	await mayor.say("you came here and people were kind of reluctant towards you")
	await mayor.say("but now everyone treats you like their own")
	await s.wait(1)
	await mayor.say("community is something you just cant take away from someone")
	await mayor.say("no matter the upsets or people that want to split you")
	await mayor.say("it persists")
	await s.wait(1)
	await mayor.say("and theres something special about that")
	await mayor.say("just that feeling of being wanted")
	await mayor.say("and if im honest with you ")
	await mayor.say("before you got here")
	await mayor.say("things in the village werent going to well")
	await mayor.say("and tensions were high")
	await mayor.say("ever since holly got ill, the village just lost a part of itself")
	await mayor.say("holly was the glue that held this village together")
	await mayor.say("i hope she has a fast recovery so everything can go back to normal")
	await mayor.say("but regardless")
	await mayor.say("since you arrived it seems people have become a lot more chill")
	await mayor.say("and toby seems like hes starting cope a lot better")
	await s.wait(2)
	await mayor.say("i know that mr gray is destined to come back here")
	await mayor.say("and he will probably keep doing so till the day he drops")
	await mayor.say("but theres something special about this valley")
	await mayor.say("almost supernatural")
	await mayor.say("so i will fight tooth and nail to keep it ")
	await mayor.say("and im sure other will join me")
	await s.wait(2)
	await mayor.say("i hope you decide to stay with us")
	await mayor.say("i know it can be quite rocky sometimes")
	await mayor.say("but its looking up")
	await mayor.say("i heard that dylan is working desining a bridge to help us cross this river")
	await mayor.say("and toby is working on an engine which sounds quite cool")
	await mayor.say("but for now i must say goodbye")
	await s.wait(2)
	await mayor.say("thank you for helping us")'''
	await s.wait(2)
	#credits roll
	$"../player".camPos = bench.get_node("camera")
	$"../AnimationPlayer".play("end")
	$"../audio/music".play("mainTheme")
	
