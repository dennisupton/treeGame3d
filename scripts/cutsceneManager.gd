extends Node3D


const CutsceneScript = preload("res://scripts/cutscene.gd")


var scenes = []   # cutscenes currently running




@onready var colin = $colin
@onready var may = $may
@onready var mayor = $mayor
@onready var toby = $toby
@onready var dylan = $dylan
@onready var enriquez = $enriquez

func _ready() -> void:
	await get_tree().process_frame
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
