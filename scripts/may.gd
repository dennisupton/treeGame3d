extends CharacterBody3D


@export var originalMoveSpeed = 5.0

var aimDir = 0.0
var random = RandomNumberGenerator.new()
var grace = 0
@onready var nav = $NavigationAgent3D

func changeDir():
	aimDir = random.randf_range(-PI, PI)

var isIt = true
func it():
	isIt = true

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	if grace > 0:
		grace -= 1
	if isIt:
		# Pathfind toward Colin instead of running straight at him.
		nav.target_position = $"../colin".global_position
		var toNext = nav.get_next_path_position() - global_position
		if Vector2(toNext.x, toNext.z).length() > 0.001:
			var targetAngle = atan2(-toNext.x, -toNext.z)
			rotation.y = lerp_angle(rotation.y, targetAngle, 0.8)
		if position.distance_to($"../colin".position) < 1 and grace <= 0:
			$"../colin".it()
			isIt = false
			$"../colin".grace = 100

	else:
		rotation.y = lerp_angle(rotation.y, aimDir, 0.05)
		if abs(angle_difference(rotation.y, aimDir)) < deg_to_rad(10):
			changeDir()
	var moveSpeed
	if isIt:
		moveSpeed = originalMoveSpeed*1.2
	else:
		moveSpeed = originalMoveSpeed*0.8
	
	if (grace <1 and not isIt) or grace <1:
		if not $AnimationPlayer.current_animation == "run":
			$AnimationPlayer.play("run")
		velocity.x = -sin(rotation.y) * moveSpeed
		velocity.z = -cos(rotation.y) * moveSpeed
	else:
		if $AnimationPlayer.current_animation == "run":
			$AnimationPlayer.stop()
		velocity.x = move_toward(velocity.x, 0, moveSpeed)
		velocity.z = move_toward(velocity.z, 0, moveSpeed)
	move_and_slide()
