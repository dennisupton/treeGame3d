extends CharacterBody3D

@export var rotationSpeed = 0.2
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var holding = false
var random = RandomNumberGenerator.new()
var inShop = false
func chop():
	for i in $player/Area3D.get_overlapping_bodies():
		if i.is_in_group("tree"):
			if not i.chopped:
				i.health -= 1
			return

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
		if input_dir.y > 0:
			$player.rotation.y = lerp_angle($player.rotation.y,PI + input_dir.x * 0.5*PI,rotationSpeed)
		else:
			$player.rotation.y = lerp_angle($player.rotation.y, input_dir.x * -0.5*PI,rotationSpeed)
	elif $AnimationPlayer.current_animation == "walk":
		$AnimationPlayer.stop()
		
	if Input.is_action_pressed("Chop") and not $AnimationPlayer.current_animation and not holding:
		var isTree = false
		for i in $player/Area3D.get_overlapping_bodies():
			if i.is_in_group("tree") and i.getForceSum()< 0.5:
				isTree = true
				if i.chopped:
					i.freeze = true
					i.set_collision_layer_value(1, false)
					$player/hands.show()
					get_parent().remove_child(i)
					$player/hold.add_child(i)
					i.position = Vector3.ZERO
					i.rotation = Vector3.ZERO
					holding = true
		if isTree and not holding:
			$AnimationPlayer.stop()
			$"../audio/chop".pitch_scale = random.randf_range(0.8,1.2)
			$AnimationPlayer.play("chop")
	elif Input.is_action_just_pressed("Chop") and holding:
		var tree = $player/hold.get_child(0)
		$player/hold.remove_child(tree)
		get_parent().add_child(tree)
		tree.freeze = false
		tree.position = $player/hold.global_position
		tree.rotation = $player/hold.global_rotation
		tree.set_collision_layer_value(1, true)
		tree.linear_velocity = velocity*2
		holding = false
		$player/hands.hide()
	
	if Input.is_action_just_pressed("Enter"):
		for i in $player/Area3D.get_overlapping_bodies():
			if i.is_in_group("shop"):
				inShop = true
				$"../store/AnimationPlayer".play("enter")
				$"../store/AnimationPlayer".queue("idle")
	elif Input.is_action_just_pressed("Exit"):
		if inShop:
			inShop = false
			$"../store/AnimationPlayer".play("leave")
			$"../store/AnimationPlayer".queue("idle")

	if inShop:
		$camPivot/Camera3D.global_position = lerp($camPivot/Camera3D.global_position,$"../store/camera".global_position,0.2)
		$camPivot/Camera3D.global_rotation = lerp($camPivot/Camera3D.global_rotation, $"../store/camera".global_rotation,0.2)
	else:
		$camPivot/Camera3D.position = lerp($camPivot/Camera3D.position,Vector3(3.802,6.334,0),0.2)
		$camPivot/Camera3D.rotation_degrees = lerp($camPivot/Camera3D.rotation_degrees,Vector3(-49,90,1),0.2)
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction and not inShop:
		velocity.x = -sin($player.rotation.y) * SPEED
		velocity.z = -cos($player.rotation.y) * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
