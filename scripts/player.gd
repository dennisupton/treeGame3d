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
var inShop = false
var damage = 1.0
var driving = false
var controlling = self
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
	object.set_collision_layer_value(1, false)
	$player/hands.show()
	get_parent().remove_child(object)
	if object.is_in_group("tree"):
		$player/treeHold.add_child(object)
	else:
		$player/hold.add_child(object)
	object.position = Vector3.ZERO
	object.rotation = Vector3.ZERO


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("Left", "Right", "Forward", "Back")
	if input_dir:
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
	
	if Input.is_action_just_pressed("Enter"):
		if hasBodyInGroup($player/Area3D.get_overlapping_bodies(),"shop") and not inShop:
			for i in $player/Area3D.get_overlapping_bodies():
				if i.is_in_group("shop"):
					$"../CanvasLayer/Control/Shop".makeButtons()
					inShop = true
					$"../store/AnimationPlayer".play("enter")
					$"../store/AnimationPlayer".queue("idle")
		elif holding and holding == "acorn" and not $"..".tooClose(position):
			var item = $player/hold.get_child(0)
			item.queue_free()
			holding = false
			$player/hands.hide()
			$"..".spawnTree(position)
	
	if Input.is_action_just_pressed("Exit"):
		if inShop:
			inShop = false
			$"../store/AnimationPlayer".play("leave")
			$"../store/AnimationPlayer".queue("idle")
			if get_viewport().gui_get_focus_owner():
				get_viewport().gui_get_focus_owner().release_focus()


	if inShop:
		$camPivot/Camera3D.global_position = lerp($camPivot/Camera3D.global_position,$"../store/camera".global_position,0.2)
		$camPivot/Camera3D.global_rotation = lerp($camPivot/Camera3D.global_rotation, $"../store/camera".global_rotation,0.2)
		if InputManager.current_device == InputManager.Device.KEYBOARD_MOUSE and get_viewport().gui_get_focus_owner() and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			get_viewport().gui_get_focus_owner().release_focus()
		elif InputManager.current_device == InputManager.Device.GAMEPAD and not get_viewport().gui_get_focus_owner() and $"../CanvasLayer/Control/Shop/Items".get_child_count()>0:
			$"../CanvasLayer/Control/Shop/Items".get_child(0).grab_focus()

	else:
		$camPivot/Camera3D.position = lerp($camPivot/Camera3D.position,Vector3(3.802,6.334,0),0.2)
		$camPivot/Camera3D.rotation_degrees = lerp($camPivot/Camera3D.rotation_degrees,Vector3(-49,90,1),0.2)

	var moveSpeed = (CARRY_SPEED if holding else SPEED) * speedMulti
	if holding:
		moveSpeed = CARRY_SPEED
	else:
		moveSpeed = SPEED

	moveSpeed *= speedMulti
	
	if controlling == self:
		if input_dir and not inShop:
			controlling.velocity.x = -sin($player.rotation.y) * moveSpeed
			controlling.velocity.z = -cos($player.rotation.y) * moveSpeed
		else:
			controlling.velocity.x = move_toward(velocity.x, 0, moveSpeed)
			controlling.velocity.z = move_toward(velocity.z, 0, moveSpeed)
	else:
		if input_dir and not inShop:
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
