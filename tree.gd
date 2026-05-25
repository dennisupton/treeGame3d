extends RigidBody3D

var chopped = false
var startingHealth = 10
var health = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health = startingHealth


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if health <= 0 and not chopped:
		freeze = false
		chopped = true
		angular_velocity.x += PI
		for child in get_children():
			if child.is_in_group("leave"):
				child.hide()
			if child is CPUParticles3D:
				child.emitting = true

func getForceSum():
	return linear_velocity.length_squared() + angular_velocity.length_squared()
