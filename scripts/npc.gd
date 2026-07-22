extends CharacterBody3D


@export_category("Main")
@export_enum("idle", "tag", "townHall","blacksmithHouse","dylansHouse","fashionHouse") var activity: String = "idle"
@export var moveSpeed = 5.0
@export var rotationSpeed = 0.5
@export var lookAtPlayer = false   # head-tracks the player with IK when within lookRange
@export var lookRange = 6.0
@export var bodyTurnAngle = 60.0   # degrees off-forward before the body turns to help the head

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

# ---- tag state ----
var aimDir = 0.0
var isIt = false
var grace = 0
var random = RandomNumberGenerator.new()

# ---- talking / cutscene state ----
var whereTo = false
var needToStartCutscene = false
var lastLetter = 0
var lastSound = 0
var remainingText = ""
var typed = ""
var tone = 0
var bounceFX
const BounceFXScript = preload("res://scripts/rich_text_bounce.gd")

@onready var nav = $NavigationAgent3D
@onready var main = get_tree().current_scene
@onready var cutscene = get_node_or_null("../cutscene")
@onready var audioPlayer = get_node_or_null("AudioStreamPlayer3D")
@onready var textBox = main.get_node_or_null("CanvasLayer/speech/MarginContainer/RichTextLabel")
# node names differ per character, so pick them once based on who this is
@onready var animPlayer = ($mayor/charAnim if name == "mayor" else $AnimationPlayer)
@onready var moveAnim = "walk"
@onready var lookAt = get_node_or_null("Armature/Skeleton3D/LookAtModifier3D")

func _ready() -> void:
	random.randomize()
	# share one bounce effect across whoever talks
	if textBox and textBox.custom_effects.is_empty():
		bounceFX = BounceFXScript.new()
		textBox.install_effect(bounceFX)
	elif textBox:
		bounceFX = textBox.custom_effects[0]
	applyActivity()
	# aim the look-at IK at the player, faded out until they come close
	if lookAtPlayer and lookAt:
		lookAt.target_node = lookAt.get_path_to(main.get_node("player"))
		lookAt.influence = 0.0

func _physics_process(delta: float) -> void:
	handleTalking()

	if not is_on_floor():
		velocity += get_gravity() * delta

	if activity == "tag":
		tagStep()
	else:
		navStep()

	if lookAtPlayer and lookAt and activity == "idle":
		var lookNear = global_position.distance_to(main.get_node("player").global_position) < lookRange
		lookAt.influence = move_toward(lookAt.influence, 1.0 if lookNear else 0.0, delta * 4.0)
	elif lookAtPlayer and lookAt:
		lookAt.influence = 0.0

#activity

# change what this npc is doing; safe to call any time during the game
func setActivity(next: String):
	activity = next
	applyActivity()

# set up whatever the current activity needs (also run once on _ready)
func applyActivity():
	whereTo = false
	nav.target_position = global_position   # drop any leftover path
	if activity == "tag":
		isIt = startsIt
		changeDir()
	elif activity in ["townHall","blacksmithHouse","dylansHouse","fashionHouse"]:
		goto(activity)

#things cutscenes call

func it():
	isIt = true

func setTone(t):
	tone = t

func stopTalking():
	main.whoIsTalking = false

func say(text: String, wait: bool = false):
	main.get_node("CanvasLayer/speech").show()
	textBox.text = ""
	typed = ""
	if bounceFX: bounceFX.reset()
	lastLetter = 0
	lastSound = 0
	remainingText = text
	main.whoIsTalking = self
	if wait:
		if cutscene: cutscene.speed_scale = 0
		needToStartCutscene = true

func goto(where: String, wait: bool = false):
	whereTo = where
	nav.target_position = navPoint(where)
	if wait:
		if cutscene: cutscene.speed_scale = 0
		needToStartCutscene = true

func navPoint(where):
	if where == "player":
		return main.get_node("player").position
	elif where == "townHall":
		return main.get_node("townhall/Marker3D").global_position
	elif where == "fashionHouse":
		return main.get_node("fashionHouse/Marker3D").global_position
	elif where == "blacksmithHouse":
		return main.get_node("blacksmithHouse/Marker3D").global_position
	elif where == "dylansHouse":
		return main.get_node("dylansHouse/Marker3D").global_position
	return global_position

# ---------- shared movement ----------

# turn toward the next point on the current nav path; returns the flat direction to it
func steer(turnWeight) -> Vector3:
	var dir = nav.get_next_path_position() - global_position
	dir.y = 0
	if dir.length() > 0.001:
		dir = dir.normalized()
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), turnWeight)
	return dir

func playMove():
	if not animPlayer.current_animation == moveAnim:
		animPlayer.play(moveAnim)

func stopMove(decel):
	if animPlayer.current_animation == moveAnim:
		animPlayer.stop()
	velocity.x = move_toward(velocity.x, 0, decel)
	velocity.z = move_toward(velocity.z, 0, decel)

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
	aimDir = random.randf_range(-PI, PI)

# turn to look at the player when they're close (or lean the body to help the head IK)
func facePlayerWhenNear():
	if not main.get_node("player") in main.get_node("player/player/Area3D").get_overlapping_bodies():
		return
	var direction = main.get_node("player").position - global_position
	direction.y = 0
	if direction.length() < 0.1:
		return
	direction = direction.normalized()
	var targetYaw = atan2(-direction.x, -direction.z)
	if not lookAtPlayer:
		rotation.y = lerp_angle(rotation.y, targetYaw, 0.2)
	elif abs(angle_difference(rotation.y, targetYaw)) > deg_to_rad(bodyTurnAngle):
		# ramp the turn in from 0 at the threshold so it never snaps on/off (that was the chop)
		var excess = abs(angle_difference(rotation.y, targetYaw)) - deg_to_rad(bodyTurnAngle)
		rotation.y = lerp_angle(rotation.y, targetYaw, clampf(excess, 0.0, 0.12))

# ---------- behaviours ----------

func handleTalking():
	# talking animations
	if name == "mayor":
		$mayor/Icosphere.position.y = lerpf($mayor/Icosphere.position.y, 0, 0.2)
		$mayor/Torus.position.y = lerpf($mayor/Torus.position.y, 0, 0.1)

	if len(remainingText) == 0:
		return

	# speaking blips play on their own timer
	if Time.get_ticks_msec() - lastSound > soundSpeed:
		lastSound = Time.get_ticks_msec()
		if audioPlayer:
			audioPlayer.stream = syllables.pick_random()
			audioPlayer.pitch_scale = randf_range(pitchRange.x, pitchRange.y) + (float(tone) / 10)
			audioPlayer.play()
		# talking animations
		if name == "mayor":
			$mayor/Icosphere.position.y = 0.1
			$mayor/Torus.position.y = 0.15

	# letters reveal on their own timer
	if Time.get_ticks_msec() - lastLetter > talkSpeed:
		var letter = remainingText[0]
		remainingText = remainingText.substr(1)
		typed += letter
		textBox.text = "[bounce]" + typed + "[/bounce]"
		lastLetter = Time.get_ticks_msec()
		var direction = main.get_node("player").position - global_position
		direction.y = 0
		if direction.length() > 0.1:
			direction = direction.normalized()
			rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), rotationSpeed)

func tagStep():
	if grace > 0:
		grace -= 1
	var other = get_node(target)
	if isIt:
		nav.target_position = other.global_position
		steer(0.8)
		if position.distance_to(other.position) < 1 and grace <= 0:
			other.it()
			isIt = false
			other.grace = 100
			say("it", false)
	else:
		rotation.y = lerp_angle(rotation.y, aimDir, 0.05)
		if abs(angle_difference(rotation.y, aimDir)) < deg_to_rad(10):
			changeDir()

	var speed = moveSpeed * (itSpeed if isIt else notItSpeed)
	if grace < 1:
		playMove()
		velocity.x = -sin(rotation.y) * speed
		velocity.z = -cos(rotation.y) * speed
	else:
		stopMove(speed)
	move_and_slide()

# idle, townHall and cutscene "goto" all share this nav-driven step
func navStep():
	# resume a paused cutscene once we've arrived and finished talking
	if nav.is_navigation_finished() and needToStartCutscene and len(remainingText) == 0:
		needToStartCutscene = false
		if cutscene: cutscene.speed_scale = 1

	# keep following a moving goto target (e.g. the player)
	if whereTo:
		nav.target_position = navPoint(whereTo)

	if navMove():
		return

	# arrived / standing still
	stopMove(moveSpeed)
	if activity in ["townHall","blacksmithHouse","dylansHouse","fashionHouse"]:
		setActivity("idle")  
	elif activity == "idle":
		facePlayerWhenNear()
