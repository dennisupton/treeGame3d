extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var moveSpeed = 5
@export var rotationSpeed = 0.2
var whereTo = false
var needToStartCutscene = false


var lastLetter = 0
var talkSpeed = 50
var remainingText = ""
var typed = ""
var tone = 0
@onready var audioPlayer = $AudioStreamPlayer
@onready var textBox = $"../../CanvasLayer/speech/MarginContainer/RichTextLabel"
@export var syllables: Array[AudioStream]
@export var pitchRange: Vector2
const BounceFXScript = preload("res://scripts/rich_text_bounce.gd")
var bounceFX

func _ready() -> void:
	if textBox.custom_effects.is_empty():
		bounceFX = BounceFXScript.new()
		textBox.install_effect(bounceFX)
	else:
		bounceFX = textBox.custom_effects[0]

func setTone(t):
	tone = t

func say(text:String, wait:bool = false):
	$"../../CanvasLayer/speech".show()
	textBox.text = ""
	typed = ""
	if bounceFX: bounceFX.reset()
	lastLetter = 0
	remainingText = text
	$"../..".whoIsTalking = self
	if wait:
		$"../cutscene".speed_scale = 0
		needToStartCutscene = true
func goto(where: String, wait:bool = false):
	whereTo = "player"
	if where == "player":
		$NavigationAgent3D.target_position = $"../../player".position
	if wait:
		$"../cutscene".speed_scale = 0
		needToStartCutscene = true
func _physics_process(delta: float) -> void:
	$mayor/Icosphere.position.y = lerpf($mayor/Icosphere.position.y, 0,0.2)
	$mayor/Torus.position.y = lerpf($mayor/Torus.position.y, 0,0.1)

	if len(remainingText) > 0 and Time.get_ticks_msec()-lastLetter > talkSpeed:
		var letter = remainingText[0]
		remainingText = remainingText.substr(1) 
		if (not letter == " ") and len(remainingText)%2 == 0:
			audioPlayer.stream = syllables.pick_random()
			audioPlayer.pitch_scale = randf_range(pitchRange.x, pitchRange.y) + (float(tone)/10)
			audioPlayer.play()
			$mayor/Icosphere.position.y = 0.1
			$mayor/Torus.position.y = 0.15
		typed += letter
		textBox.text = "[bounce]" + typed + "[/bounce]"
		lastLetter = Time.get_ticks_msec()
		var direction = $"../../player".position - global_position
		direction.y = 0
		direction = direction.normalized()
		if direction.length() > 0.1:
			rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), rotationSpeed)

	if not is_on_floor():
		velocity += get_gravity() * delta
	if $NavigationAgent3D.is_navigation_finished() and needToStartCutscene and len(remainingText) == 0 :
		needToStartCutscene = false
		$"../cutscene".speed_scale = 1
	if not $NavigationAgent3D.is_navigation_finished():
		if whereTo and whereTo == "player":
			$NavigationAgent3D.target_position = $"../../player".position
		var direction = $NavigationAgent3D.get_next_path_position() - global_position
		direction.y = 0
		direction = direction.normalized()
		if direction.length() > 0.1:
			rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), rotationSpeed)
		if not $mayor/charAnim.current_animation == "walk":
			$mayor/charAnim.play("walk")

		velocity.x = direction.x * moveSpeed
		velocity.z = direction.z * moveSpeed

		move_and_slide()
	elif $mayor/charAnim.current_animation == "walk":
		$mayor/charAnim.stop()
		velocity.x = move_toward(velocity.x, 0, moveSpeed)
		velocity.z = move_toward(velocity.z, 0, moveSpeed)
	else:
		velocity.x = move_toward(velocity.x, 0, moveSpeed)
		velocity.z = move_toward(velocity.z, 0, moveSpeed)
	if $"../../player" in $Area3D.get_overlapping_bodies() and not $"../../audio/music".get_stream_playback().get_current_clip_index() == 1:
		$"../../audio/music".get_stream_playback().switch_to_clip_by_name("mayor")
