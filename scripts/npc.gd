extends CharacterBody3D


@export_category("Main")
@export_enum("idle", "tag", "townHall","blacksmithHouse","dylansHouse","fashionHouse") var activity: String = "idle"
@export var moveSpeed = 5.0
@export var rotationSpeed = 0.5
@export var lookAtPlayer = false   # head-tracks the player with IK when within lookRange
@export var lookRange = 6.0
@export var bodyTurnAngle = 60.0   # degrees off-forward before the body turns to help the head
@export var animBlendTime = 0.3

@export_category("Idle")
# which house this npc runs, if any. while they're stood at it they use shopIdle —
# behind the counter, ready to serve — and anywhere else they use idleAnim.
@export_enum("none", "townHall", "blacksmithHouse", "dylansHouse", "fashionHouse") var shop: String = "none"
@export var idleAnim = "idle"
@export var shopIdle = "shopIdle"
@export var shopRange = 4.0   # how far from the shop marker still counts as being there

@export_category("It")
@export var target: NodePath      # the other tag player to chase
@export var startsIt = false
@export var itSpeed = 1.0         # speed multiplier while "it"
@export var notItSpeed = 1.0      # speed multiplier while running away

@export_category("Talking")
@export var syllables: Array[AudioStream]
@export var pitchRange: Vector2
@export var talkSpeed = 80    # ms between letters — lower = faster typing
@export var soundSpeed = 160  # ms between speaking blips — lower = faster sounds
@export var faces: Dictionary[String,Texture]
# after the last letter lands, a line keeps the floor for a beat so it can actually be
# read before the next one starts: readBase + readPerLetter per character, capped.
@export var readBase = 0.35
@export var readPerLetter = 0.025
@export var readPauseMax = 1.5
@export var bubbleHold = 0.8  # seconds the bubble lingers on after losing the floor
@export var bubbleRange = 14.0 # how close the player must be for the bubble to show at all


const BubbleScene = preload("res://scenes/bubble.tscn")
const HOUSES = ["townHall", "blacksmithHouse", "dylansHouse", "fashionHouse"]
const NAV_TARGETS = {
	"player": "player",
	"townHall": "townhall/Marker3D",
	"blacksmithHouse": "blacksmithHouse/Marker3D",
	"dylansHouse": "dylansHouse/Marker3D",
	"fashionHouse": "fashionHouse/Marker3D",
	"may": "NPCs/may",
	"colin": "NPCs/colin",
}

# ---- tag state ----
var aimDir = 0.0
var isIt = false
var grace = 0

# ---- talking / cutscene state ----
var whereTo = ""
var talking = false
var letterTimer = 0.0   # ms accumulated toward the next letter
var soundTimer = 0.0    # ms accumulated toward the next blip
var lookTarget = null   # a node to face instead of the player, or null
var wantsBubble = false # there's something worth showing, range permitting
var bubbleShown = false # whether the bubble is currently popped in
var scene = null        # the Cutscene driving this npc right now, or null
var speedScale = 1.0    # set by that scene; 0 while it's gated out
var sayId = 0           # bumped per line, so a superseded say() stops waiting
var gotoId = 0
var readTimer = 0.0     # seconds left of the read beat after the last letter
var holdTimer = 0.0     # seconds left before a finished bubble hides
var gotoPending = 0     # frames until the arrived check arms (see navStep)
var remainingText = ""
var typed = ""
var tone = 0
var moveAnim = "walk"
var bubble

# ---- idle state ----
var posed = false      # a cutscene or shop line is driving the animation; idle stays off it
var idlePlaying = ""   # the idle currently handed to the animation player, or ""

@onready var nav = $NavigationAgent3D
@onready var main = get_tree().current_scene
@onready var player = main.get_node("player")
@onready var audioPlayer = get_node_or_null("AudioStreamPlayer3D")
# node names differ per character, so pick them once based on who this is
@onready var animPlayer = ($mayor/charAnim if name == "mayor" else $AnimationPlayer)
@onready var lookAt = get_node_or_null("Armature/Skeleton3D/LookAtModifier3D")

func _ready() -> void:
	applyActivity()
	if lookAtPlayer and lookAt:
		lookAway()
		lookAt.influence = 0.0

func playAnim(anim):
	posed = true
	idlePlaying = ""
	animPlayer.play(anim, animBlendTime)

# hand the animation back to the idle system once a cutscene or shop line is done posing them
func stopPose() -> void:
	posed = false
	idlePlaying = ""

func _physics_process(delta: float) -> void:
	handleTalking(delta)
	updateBubble()

	if not is_on_floor():
		velocity += get_gravity() * delta

	if activity == "tag":
		tagStep()
	else:
		navStep()
		if hasLookTarget():
			turnTo(lookTarget.global_position, rotationSpeed * 0.5)

	updateLookIK(delta)

#activity

# change what this npc is doing; safe to call any time during the game
func setActivity(next: String):
	activity = next
	applyActivity()

# set up whatever the current activity needs (also run once on _ready)
func applyActivity():
	whereTo = ""
	nav.target_position = global_position   # drop any leftover path
	if activity == "tag":
		isIt = startsIt
		changeDir()
	elif activity in HOUSES:
		goto(activity)

#things cutscenes call

func it():
	isIt = true

func setTone(t):
	tone = t


func lookAtNode(who) -> void:
	lookTarget = who
	if lookAt and who:
		var marker = who.get_node_or_null("textBoxPos")
		lookAt.target_node = lookAt.get_path_to(marker if marker else who)

func lookAway() -> void:
	lookTarget = null
	if lookAt:
		lookAt.target_node = lookAt.get_path_to(player)

func hasLookTarget() -> bool:
	return lookTarget != null and is_instance_valid(lookTarget)

func stopTalking():
	holdTimer = 0.0
	wantsBubble = false

func nearPlayer(dist: float) -> bool:
	return global_position.distance_to(player.global_position) < dist

func updateLookIK(delta: float) -> void:
	if not lookAt:
		return

	if hasLookTarget():
		lookAt.influence = move_toward(lookAt.influence, 1.0, delta * 4.0)
	elif lookAtPlayer:
		if activity == "idle":
			# at their shop the head lets go once the player rounds past the body turn
			# angle, so they settle back to forward rather than the body chasing after
			var want = 1.0 if nearPlayer(lookRange) and not pastShopLookLimit() else 0.0
			lookAt.influence = move_toward(lookAt.influence, want, delta * 4.0)
		else:
			lookAt.influence = 0.0

# the bubble is only up when there's something worth showing AND the player is close
# enough to read it. both directions animate, so walking in and out of range pops it
# rather than blinking it.
func updateBubble() -> void:
	if not bubble:
		return
	var wanted = wantsBubble and nearPlayer(bubbleRange)
	if wanted == bubbleShown:
		return
	bubbleShown = wanted
	if wanted:
		bubble.popIn()
	else:
		bubble.popOut()

# this npc's own bubble, made the first time it speaks
func getBubble():
	if bubble:
		return bubble
	var host = main.get_node_or_null("CanvasLayer/bubbles")
	if not host:
		return null
	bubble = BubbleScene.instantiate()
	bubble.name = name + "Bubble"   # so it's identifiable in the remote inspector
	host.add_child(bubble)
	bubble.follow(get_node("textBoxPos"), player.get_node("camPivot/Camera3D"))
	return bubble

# `await npc.say("hi")` waits for the line to finish typing; a bare `npc.say("hi")`
# fires it off and returns straight away.
func say(text: String) -> void:
	if sceneStopped():
		return   # leftover line from a scene that's been stopped
	var b = getBubble()
	if b:
		b.clear()
		b.move_to_front()   # sibling order is draw order, so whoever spoke last is on top
	wantsBubble = true      # updateBubble() does the actual pop, once range allows
	typed = ""
	letterTimer = 0.0
	soundTimer = 0.0
	holdTimer = 0.0
	readTimer = minf(readBase + text.length() * readPerLetter, readPauseMax)
	remainingText = text
	talking = true
	sayId += 1
	var id = sayId
	while talking and sayId == id and not sceneStopped():
		await get_tree().process_frame

func goto(where: String) -> void:
	if sceneStopped():
		return
	whereTo = where
	nav.target_position = navPoint(where)
	gotoPending = 2
	gotoId += 1
	var id = gotoId
	while gotoPending > 0 and gotoId == id and not sceneStopped():
		await get_tree().process_frame

func shutUp() -> void:
	remainingText = ""
	talking = false
	readTimer = 0.0
	holdTimer = 0.0
	gotoPending = 0
	sayId += 1
	gotoId += 1
	wantsBubble = false
	bubbleShown = false
	lookAway()
	stopPose()
	if bubble:
		bubble.clear()
		bubble.hideNow()

func sceneStopped() -> bool:
	return scene != null and scene.stopped

func navPoint(where) -> Vector3:
	if not where in NAV_TARGETS:
		return global_position
	var node = main.get_node_or_null(NAV_TARGETS[where])
	if not node:
		return global_position
	return node.global_position

# ---------- shared movement ----------

# flat (height-ignoring) offset from here to a world point
func flatTo(pos: Vector3) -> Vector3:
	var dir = pos - global_position
	dir.y = 0
	return dir

func faceDir(dir: Vector3, weight: float) -> void:
	rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), weight)

func turnTo(pos: Vector3, weight: float) -> void:
	var dir = flatTo(pos)
	if dir.length() >= 0.1:
		faceDir(dir, weight)

# turn toward the next point on the current nav path; returns the flat direction to it
func steer(turnWeight) -> Vector3:
	var dir = flatTo(nav.get_next_path_position())
	if dir.length() > 0.001:
		dir = dir.normalized()
		faceDir(dir, turnWeight)
	return dir

func playMove():
	posed = false   # walking off ends whatever pose they were holding
	idlePlaying = ""
	if animPlayer.current_animation != moveAnim:
		animPlayer.play(moveAnim)

func stopMove(decel):
	# settle into an idle if there's one to settle into, otherwise drop the walk cycle
	# and hold the rest pose, the way this always did
	if not playIdle() and animPlayer.current_animation == moveAnim:
		animPlayer.stop()
	velocity.x = move_toward(velocity.x, 0, decel)
	velocity.z = move_toward(velocity.z, 0, decel)

# ---------- idling ----------

# stood at the marker they walk to for their own shop, however they got there — their
# starting activity, a cutscene goto, or just never having left. being near it isn't
# enough: walking in still counts as away until they've actually stopped, otherwise
# they'd read as open for business while crossing the last few metres, or while a path
# to somewhere else happened to take them past their own door.
func atShop() -> bool:
	if not shop in HOUSES or not nav.is_navigation_finished():
		return false
	# flat, because the shop markers sit well above the floor by varying amounts
	return flatTo(navPoint(shop)).length() < shopRange

# the idle that suits where they're stood right now. falls back to the normal one while
# a shop idle hasn't been animated for them yet.
func idleFor() -> String:
	if atShop() and animPlayer.has_animation(shopIdle):
		return shopIdle
	return idleAnim

# returns false when there's no idle to play, so stopMove() knows to fall back
func playIdle() -> bool:
	if posed:
		return true   # a cutscene or shop line has the floor
	var anim = idleFor()
	if anim.is_empty() or not animPlayer.has_animation(anim):
		idlePlaying = ""
		return false
	if idlePlaying != anim:
		idlePlaying = anim
		animPlayer.play(anim, animBlendTime)
	elif not animPlayer.is_playing():
		animPlayer.play(anim, animBlendTime)   # idle isn't marked as looping; go round again
	return true

# walk along the current nav path; returns true while still travelling
func navMove() -> bool:
	if nav.is_navigation_finished():
		return false
	var dir = steer(rotationSpeed)
	playMove()
	velocity.x = dir.x * moveSpeed
	velocity.z = dir.z * moveSpeed
	move_and_slide()
	return true

# ---------- helpers ----------

func changeDir():
	aimDir = randf_range(-PI, PI)

# how far round from their own forward the player is, in radians
func playerOffAngle() -> float:
	var dir = flatTo(player.global_position)
	if dir.length() < 0.1:
		return 0.0
	return abs(angle_difference(rotation.y, atan2(-dir.x, -dir.z)))

# behind their own counter they're planted, so once the player gets further round than the
# body would normally turn to follow they give up and face front again instead of
# swivelling. away from the shop there's nothing keeping them put, so the body helps out.
func pastShopLookLimit() -> bool:
	return atShop() and playerOffAngle() > deg_to_rad(bodyTurnAngle)

# turn to look at the player when they're close (or lean the body to help the head IK)
func facePlayerWhenNear():
	if hasLookTarget():
		return   # busy looking at someone else
	var area = player.get_node("player/Area3D")
	if not player in area.get_overlapping_bodies():
		return
	var dir = flatTo(player.global_position)
	if dir.length() < 0.1:
		return

	var targetYaw = atan2(-dir.x, -dir.z)
	var off = abs(angle_difference(rotation.y, targetYaw))
	var limit = deg_to_rad(bodyTurnAngle)
	if not lookAtPlayer:
		rotation.y = lerp_angle(rotation.y, targetYaw, 0.2)
	elif off > limit and not atShop():
		rotation.y = lerp_angle(rotation.y, targetYaw, clampf(off - limit, 0.0, 0.12))

func rest():
	if name == "mayor":
		$mayor/Icosphere.position.y = lerpf($mayor/Icosphere.position.y, 0, 0.2)
		$mayor/Torus.position.y = lerpf($mayor/Torus.position.y, 0, 0.1)

func pop():
	if name == "mayor":
		$mayor/Icosphere.position.y = 0.1
		$mayor/Torus.position.y = 0.15
	if name == "enriquez":
		$Armature/Skeleton3D/ModifierBoneTarget3D/mouthAnim.play("open")
func playBlip():
	if not audioPlayer:
		return
	audioPlayer.stream = syllables.pick_random()
	audioPlayer.pitch_scale = randf_range(pitchRange.x, pitchRange.y) + tone / 10.0
	audioPlayer.play()

func setFace(face):
	if faces.has(face):
		$Armature/Skeleton3D/ModifierBoneTarget3D/Decal.texture_albedo = faces[face]

func handleTalking(delta: float):
	rest()
	var step = delta * speedScale

	if remainingText.is_empty():
		if talking:
			readTimer -= step
			if readTimer <= 0.0:
				talking = false
				holdTimer = bubbleHold
		elif holdTimer > 0.0:
			holdTimer -= step
			if holdTimer <= 0.0:
				wantsBubble = false
		return

	# speaking blips play on their own timer
	soundTimer += step * 1000.0
	if soundTimer > soundSpeed:
		soundTimer = 0.0
		playBlip()
		pop()
	letterTimer += step * 1000.0
	if letterTimer > talkSpeed:
		letterTimer = 0.0
		typed += remainingText[0]
		remainingText = remainingText.substr(1)
		if bubble: bubble.setText("[bounce]" + typed + "[/bounce]")
		if not hasLookTarget():
			turnTo(player.global_position, rotationSpeed)

func tagStep():
	grace = maxi(grace - 1, 0)
	var other = get_node(target)
	if isIt:
		nav.target_position = other.global_position
		steer(0.8)
		if position.distance_to(other.position) < 1 and grace == 0:
			other.it()
			isIt = false
			other.grace = 100
			say("it")
	else:
		rotation.y = lerp_angle(rotation.y, aimDir, 0.05)
		if abs(angle_difference(rotation.y, aimDir)) < deg_to_rad(10):
			changeDir()

	var speed = moveSpeed * (itSpeed if isIt else notItSpeed)
	if grace == 0:
		playMove()
		velocity.x = -sin(rotation.y) * speed
		velocity.z = -cos(rotation.y) * speed
	else:
		stopMove(speed)
	move_and_slide()

func navStep():
	if gotoPending > 1:
		gotoPending -= 1
	elif gotoPending == 1 and nav.is_navigation_finished():
		gotoPending = 0
		whereTo = ""
		nav.target_position = global_position
	if whereTo:
		nav.target_position = navPoint(whereTo)

	if navMove():
		return
	# done
	stopMove(moveSpeed)
	if activity in HOUSES:
		setActivity("idle")
	elif activity == "idle":
		facePlayerWhenNear()
