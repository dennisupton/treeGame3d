class_name Cutscene
extends RefCounted

var director
var player
var sceneName = ""

var running = 0     # lanes currently in flight, for THIS scene
var gate = null     # npc whose Area3D the player must stay inside, or null
var speed = 1.0     # 0 while gated out; pushed onto everyone in the cast
var cast = []       # npcs this scene is driving
var stopped = false

func _init(d, who: String) -> void:
	director = d
	sceneName = who
	player = d.get_parent().get_node_or_null("player")



func take(npcs: Array) -> void:
	if stopped:
		return   # a dying scene doesn't get to steal anyone on its way out
	# stopping someone takes a few frames, and another scene can claim them while we
	# wait — so keep clearing until nobody else is holding anyone we asked for
	while true:
		var dying = []
		for npc in npcs:
			if npc.scene != null and npc.scene != self and not npc.scene in dying:
				dying.append(npc.scene)
		if dying.is_empty():
			break
		for other in dying:
			await other.stop()
		if stopped:
			return   # something killed us while we waited
	for npc in npcs:
		if not npc in cast:
			npc.shutUp()   # start clean: no half-typed line, no bubble left hanging
			cast.append(npc)
		npc.scene = self
		npc.speedScale = speed


# stop this scene where it stands; every lane unwinds on its next frame.
# the cast stays bound for a few frames afterwards on purpose: a stopped scene's
# coroutines are still alive and will issue another say() or two as they unwind, and
# npc.say() ignores those precisely because the npc still points back at this scene.
func stop() -> void:
	stopped = true
	for npc in cast:
		npc.shutUp()
	for i in 3:
		await director.get_tree().process_frame
	release()

func release() -> void:
	for npc in cast:
		if npc.scene == self:
			npc.scene = null
			npc.speedScale = 1.0
	cast.clear()

# run steps as a second thread of this scene; returns immediately
func lane(steps: Callable) -> void:
	running += 1
	await steps.call()
	running = maxi(running - 1, 0)

# wait for every lane started with lane() to finish
func join() -> void:
	while running > 0 and not stopped:
		await director.get_tree().process_frame

# seconds, but honours this scene's speed so a gated cutscene actually stops
func wait(seconds: float) -> void:
	var left = seconds
	while left > 0.0 and not stopped:
		await director.get_tree().process_frame
		left -= director.get_process_delta_time() * speed

# called once a frame by the director
func tick() -> void:
	if gate:
		var area = gate.get_node_or_null("Area3D")
		speed = 1.0 if area and player and player in area.get_overlapping_bodies() else 0.0
	else:
		speed = 1.0
	for npc in cast:
		npc.speedScale = speed
