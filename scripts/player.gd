extends CharacterBody3D

@export var rotationSpeed = 0.2
@export var SPEED = 5.0
@export var CARRY_SPEED = 2.0
@export var speedMulti = 1.0
@export var axeSpeed = 1.0
@export var wheelbarrowTurnSpeed = 5.0  # how fast the wheelbarrow pivots toward a new direction

const JUMP_VELOCITY = 4.5
var holding = false
var random = RandomNumberGenerator.new()
var freeze = false
var damage = 1.0
var driving = false
var controlling = self
var defaultCamBasis  # follow-camera orientation, restored when leaving a fixed-cam area

var whistling = false
@onready var camPos = false
var shop = false

func _ready() -> void:
	defaultCamBasis = $camPivot/Camera3D.transform.basis
func chop():
	for i in $player/Area3D.get_overlapping_bodies():
		if i.is_in_group("tree"):
			if not i.chopped:
				i.health -= damage
			return

func hasBodyInGroup(bodies,group):
	for i in bodies:
		if i.is_in_group(group):
			return i
	return false

func pickup(object):
	object.freeze = true
	#object.set_collision_layer_value(1, false)
	$player/hands.show()
	get_parent().remove_child(object)
	if object.is_in_group("tree"):
		$player/treeHold.add_child(object)
	else:
		$player/hold.add_child(object)
	object.position = Vector3.ZERO
	object.rotation = Vector3.ZERO

func getClosestTameable():
	for i in $player/tameRange.get_overlapping_bodies():
		if i.is_in_group("tameable") and not i.tamed:
			return i
	return false

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("Left", "Right", "Forward", "Back")
	if input_dir and not freeze:
		$player/Axe.hide()
		$AnimationPlayer.play("walk")
		if controlling == self:
			if input_dir.y > 0:
				$player.rotation.y = lerp_angle($player.rotation.y,PI + input_dir.x * 0.5*PI,rotationSpeed)
			else:
				$player.rotation.y = lerp_angle($player.rotation.y, input_dir.x * -0.5*PI,rotationSpeed)
		else:
			$player.rotation.y = lerp_angle($player.rotation.y, 0.0, rotationSpeed)
	elif $AnimationPlayer.current_animation == "walk":
		$AnimationPlayer.stop()
		
	if Input.is_action_pressed("Chop") and not holding:
		var isItem = false
		for i in $player/Area3D.get_overlapping_bodies():
			if i.is_in_group("tree") and i.getForceSum()< 0.5 and not holding:
				isItem = true
				if i.chopped:
					pickup(i)
					holding = "tree"
			elif i.is_in_group("acorn") and not holding:
				pickup(i)
				holding = "acorn"
			elif i.name == "wheelbarrow":
				driving = "wheelbarrow"
				controlling = i
				set_collision_layer_value(1, false)
		if isItem and not holding and not $AnimationPlayer.current_animation:
			$AnimationPlayer.stop()
			$"../audio/chop".pitch_scale = random.randf_range(0.8,1.2)
			$AnimationPlayer.speed_scale = axeSpeed
			$AnimationPlayer.play("chop")
			$AnimationPlayer.speed_scale = 1
	elif Input.is_action_just_pressed("Chop") and holding:
		var item
		if holding == "tree":
			item = $player/treeHold.get_child(0)
			$player/treeHold.remove_child(item)
			get_parent().add_child(item)
			item.position = $player/treeHold.global_position
			item.rotation = $player/treeHold.global_rotation
		else:
			item = $player/hold.get_child(0)
			$player/hold.remove_child(item)
			get_parent().add_child(item) 
			item.position = $player/hold.global_position
			item.rotation = $player/hold.global_rotation
		item.freeze = false
		item.set_collision_layer_value(1, true)
		item.linear_velocity = velocity*4 + Vector3.UP*2
		holding = false
		$player/hands.hide()
	if Input.is_action_just_pressed("Enter") and not freeze:
		if hasBodyInGroup($player/Area3D.get_overlapping_areas(),"shop") and not freeze:
			freeze = true
			var place = hasBodyInGroup($player/Area3D.get_overlapping_areas(),"shop")
			camPos = place.get_parent().get_node("talking")
			if place.get_parent().name == "fashionHouse":
				$"../CanvasLayer/shop".person = $"../NPCs/enriquez"
			if place.get_parent().name == "blacksmithHouse":
				$"../CanvasLayer/shop".person = $"../NPCs/toby"
			if place.get_parent().name == "dylansHouse":
				$"../CanvasLayer/shop".person = $"../NPCs/dylan"
			if place.get_parent().name == "townhall":
				$"../CanvasLayer/shop".person = $"../NPCs/mayor"
			$"../CanvasLayer/shop".start()
		elif holding and holding == "acorn" and not $"..".tooClose(position):
			var item = $player/hold.get_child(0)
			item.queue_free()
			holding = false
			$player/hands.hide()
			$"..".spawnTree(position)
	
	if Input.is_action_pressed("whistle") and not holding and not whistling:
		freeze = true
		whistling = true
		$AnimationPlayer.play("whistle")
	elif not Input.is_action_pressed("whistle") and not $AnimationPlayer.current_animation == "whistleSuccess" and whistling:
		freeze = false
		whistling = false

		if $AnimationPlayer.current_animation == "whistle":
			$AnimationPlayer.stop()
		$player/hands2.hide()
	'''
	if InputManager.current_device == InputManager.Device.KEYBOARD_MOUSE and get_viewport().gui_get_focus_owner() and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		get_viewport().gui_get_focus_owner().release_focus()
	elif InputManager.current_device == InputManager.Device.GAMEPAD and not get_viewport().gui_get_focus_owner() and $"../CanvasLayer/Control/Shop/Items".get_child_count()>0:
		$"../CanvasLayer/Control/Shop/Items".get_child(0).grab_focus()
	'''
	
	var moveSpeed = (CARRY_SPEED if holding else SPEED) * speedMulti
	
	if controlling == self:
		if input_dir and not freeze:
			controlling.velocity.x = -sin($player.rotation.y) * moveSpeed
			controlling.velocity.z = -cos($player.rotation.y) * moveSpeed
		else:
			controlling.velocity.x = move_toward(velocity.x, 0, moveSpeed)
			controlling.velocity.z = move_toward(velocity.z, 0, moveSpeed)
	else:
		if input_dir and not freeze:
			var target_yaw
			if input_dir.y > 0:
				target_yaw = PI + input_dir.x * 0.5 * PI
			else:
				target_yaw = input_dir.x * -0.5 * PI
			controlling.rotation.y = lerp_angle(controlling.rotation.y, target_yaw, wheelbarrowTurnSpeed * delta)
			var align = clampf(cos(angle_difference(controlling.rotation.y, target_yaw)), 0.0, 1.0)
			controlling.velocity.x = -sin(controlling.rotation.y) * moveSpeed * align
			controlling.velocity.z = -cos(controlling.rotation.y) * moveSpeed * align
		else:
			controlling.velocity.x = move_toward(controlling.velocity.x, 0, moveSpeed)
			controlling.velocity.z = move_toward(controlling.velocity.z, 0, moveSpeed)

	controlling.move_and_slide()
	
	if not controlling == self:
		position = controlling.get_node("player").global_position
		$player.rotation = controlling.get_node("player").global_rotation

	# CAMERA
	var area = $"..".getArea()
	var cam = $camPivot/Camera3D
	if camPos:
		cam.global_position = lerp(cam.global_position,camPos.global_position,0.2)
		cam.global_rotation = lerp(cam.global_rotation,camPos.global_rotation,0.2)
	elif area:
		var desPos = cam.global_position
		if area == "townhall":
			desPos = $"../townhall/cam".global_position
		elif area == "blacksmithHouse":
			desPos = $"../blacksmithHouse/Area3D/cam".global_position
		elif area == "dylansHouse":
			desPos = $"../dylansHouse/Area3D/cam".global_position
		elif area == "fashionHouse":
			desPos = $"../fashionHouse/Area3D/cam".global_position
		desPos.x = global_position.x
		if cam.global_position.distance_to(desPos) < 1:
			cam.global_position = desPos
		else:
			cam.global_position = lerp(cam.global_position,desPos,0.2)
		# point the fixed camera towards the player
		var lookTarget = global_position + Vector3.UP
		var targetBasis = cam.global_transform.looking_at(lookTarget, Vector3.UP).basis
		cam.global_transform.basis = cam.global_transform.basis.slerp(targetBasis, 0.2)

	else:
		cam.position = lerp(cam.position,Vector3(3.802,6.334,0),0.2)
		cam.transform.basis = cam.transform.basis.slerp(defaultCamBasis, 0.2)


func animDone(anim_name: StringName) -> void:
	if whistling and anim_name == "whistle":
		var animal = getClosestTameable()
		if animal:# and random.randi_range(0,1) == 0:
			$AnimationPlayer.play("whistleSuccess")
			animal.freeze = true
			animal.get_node("AnimationPlayer").play("whistle")
			faceEachOther(animal)
		else:
			$AnimationPlayer.play("whistle")


func faceEachOther(animal: Node3D, duration := 0.4, animalYawOffset := PI/2) -> void:
	var toAnimal := animal.global_position - global_position
	toAnimal.y = 0.0                       # yaw only, don't tilt
	if toAnimal.length() < 0.001:
		return
	var playerYaw := atan2(-toAnimal.x, -toAnimal.z)
	var animalYaw := atan2(toAnimal.x, toAnimal.z) + animalYawOffset   # opposite direction

	var pStart = $player.rotation.y
	var aStart = animal.rotation.y
	var tween = create_tween().set_parallel(true)
	tween.tween_method(func(t): $player.rotation.y = lerp_angle(pStart, playerYaw, t), 0.0, 1.0, duration)
	tween.tween_method(func(t): animal.rotation.y = lerp_angle(aStart, animalYaw, t), 0.0, 1.0, duration)

func setCamPos(node):
	if node:
		camPos = get_node(node)
	else:
		camPos = false
