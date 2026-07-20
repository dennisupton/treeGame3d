extends CharacterBody3D

@export var flySpeed = 5.0
@export var turnSpeed = 6.0
@export var arriveDist = 0.4
@export var facingOffset = PI/2
@export var peckRate = 0.2
@export var arcHeight = 0.2
@export var wanderRange = 40
@export var sitTime = 30.0

var tamed = false
var destination = null
var destTree = false
var flyStart = Vector3.ZERO
var flyCovered = 0.0
var sitTimer = 0.0
var home = Vector3.ZERO
var freeze = false
@onready var anim = $AnimationPlayer

func _ready():
	home = global_position

func setTame():
	tamed = true
	destination = null

func findTree():
	var closest = false
	var closestDist = INF
	for i in $Area3D.get_overlapping_bodies():
		if i.is_in_group("tree") and not i.chopped:
			var d = global_position.distance_squared_to(i.global_position)
			if d < closestDist:
				closestDist = d
				closest = i
	return closest

func groundPoint(spot):
	var query = PhysicsRayQueryParameters3D.create(spot + Vector3.UP * 20.0, spot + Vector3.DOWN * 20.0)
	query.exclude = [get_rid()]
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		return hit.position
	return spot

func pickDestination():
	flyStart = global_position
	flyCovered = 0.0
	sitTimer = 0.0
	destTree = findTree() if tamed else false
	if destTree:
		destination = destTree.get_node("bird").global_position
	else:
		var spot = home + Vector3(randf_range(-wanderRange, wanderRange), 0, randf_range(-wanderRange, wanderRange))
		destination = groundPoint(spot)

func _physics_process(delta: float) -> void:
	if freeze and not tamed:
		return
	if destination == null:
		pickDestination()
		return

	if destTree and (not is_instance_valid(destTree) or destTree.chopped):
		destination = null
		return

	if global_position.distance_to(destination) > arriveDist:
		flyCovered += flySpeed * delta
		var flyLen = maxf(flyStart.distance_to(destination), 0.001)
		var t = clampf(flyCovered / flyLen, 0.0, 1.0)
		global_position = flyStart.lerp(destination, t) + Vector3.UP * flyLen * arcHeight * sin(t * PI)

		if anim.has_animation("fly") and anim.current_animation != "fly":
			anim.play("fly")

		var dir = destination - flyStart
		if Vector2(dir.x, dir.z).length() > 0.001:
			rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z) + facingOffset, turnSpeed * delta)
		rotation.x = lerp_angle(rotation.x, 0.0, turnSpeed * delta)
		rotation.z = lerp_angle(rotation.z, 0.0, turnSpeed * delta)
		return

	global_position = global_position.move_toward(destination, flySpeed * delta)
	if destTree:
		var perch = destTree.get_node("bird").global_transform.basis.get_rotation_quaternion()
		global_transform.basis = global_transform.basis.slerp(Basis(perch), turnSpeed * delta)
		if anim.has_animation("peck"):
			if anim.current_animation != "peck":
				anim.play("peck")
			destTree.health -= peckRate * delta
	else:
		rotation.x = lerp_angle(rotation.x, 0.0, turnSpeed * delta)
		rotation.z = lerp_angle(rotation.z, 0.0, turnSpeed * delta)
		if anim.has_animation("idle") and anim.current_animation != "idle":
			anim.play("idle")
		sitTimer += delta
		if sitTimer >= sitTime:
			destination = null
		for i in $scared.get_overlapping_bodies():
			if i.name == "player":
				pickDestination()
