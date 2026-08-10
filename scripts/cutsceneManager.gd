extends Node3D


const CutsceneScript = preload("res://scripts/cutscene.gd")


var scenes = []   # cutscenes currently running

var introPlayed = false

@onready var colin = $colin
@onready var may = $may
@onready var mayor = $mayor
@onready var toby = $toby
@onready var dylan = $dylan
@onready var enriquez = $enriquez

func _ready() -> void:
	await get_tree().process_frame
	#play("introduction")
	play("kidsPlayTag")


func _process(_delta: float) -> void:
	for s in scenes:
		s.tick()

func play(sceneName: String) -> void:
	var s = CutsceneScript.new(self, sceneName)
	scenes.append(s)
	await call(sceneName, s)
	s.release()
	scenes.erase(s)


func freeNpc(npc) -> void:
	for s in scenes.duplicate():
		if npc in s.cast:
			s.stop()
			scenes.erase(s)
	npc.speedScale = 1.0
	npc.shutUp()

# stop everything currently running
func stopAll() -> void:
	for s in scenes.duplicate():
		s.stop()
	scenes.clear()

func faceEachOther(a, b) -> void:
	a.lookAtNode(b)
	b.lookAtNode(a)

func stopFacing(a, b) -> void:
	a.lookAway()
	b.lookAway()

func introduction(s) -> void:
	await $"../player" in $mayor/Area3D.get_overlapping_bodies() and not introPlayed
	introPlayed = true
	s.take([mayor])
	s.gate = mayor   # pause if the player wanders off, the way setLeader() used to
	mayor.playAnim("jump")
	await mayor.goto("player")
	await mayor.say("are you lost?")
	await mayor.say("or right where you need to be?")
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


# kid stuff
func kidsArgue(s) -> void:
	s.take([colin, may])
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
	s.take([colin, may])
	colin.target = colin.get_path_to(may)
	may.target = may.get_path_to(colin)
	colin.startsIt = false
	may.startsIt = true
	colin.setActivity("tag")
	may.setActivity("tag")
