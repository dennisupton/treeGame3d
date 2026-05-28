extends RigidBody3D

var chopped = false
var startingHealth = 10
var health = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health = startingHealth
	contact_monitor = true
	max_contacts_reported = 1  
	body_entered.connect(_on_body_entered)

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


func _on_body_entered(body):
	var impact = linear_velocity.length()
	if impact < 0.5:
		return

	$fall.volume_db = lerp(-20.0, 0.0, clamp(impact / 10.0, 0.0, 1.0))
	$fall.pitch_scale = randf_range(0.9, 1.1) 
	$fall.play()
func getForceSum():
	return linear_velocity.length_squared() + angular_velocity.length_squared()
