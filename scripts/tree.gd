extends RigidBody3D

var chopped = false
var startingHealth = 10
var health = 0
var age = 0
var growTime = 5
var random = RandomNumberGenerator.new()
@export var still = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health = startingHealth
	contact_monitor = true
	max_contacts_reported = 1  
	body_entered.connect(_on_body_entered)
	setAge(0)
	$growthTimer.wait_time = growTime + random.randf_range(0-growTime/2,growTime/2)
	$growthTimer.start()
	if still:
		setAge(4)

func setAge(newAge):
	if chopped:
		return
	age = newAge
	remove_from_group("tree")
	$Hole.hide()
	$age1.hide()
	$age2.hide()
	$age2leaves.hide()
	$age3trunk.hide()
	$age3leaves.hide()
	$trunk.hide()
	$leaves.hide()
	$CollisionShape3D.disabled = true
	if age == 0:
		$Hole.show()
	elif age == 1:
		$Hole.show()
		$age1.show()
	elif age == 2:
		$CollisionShape3D.disabled = false
		$Hole.show()
		$age2.show()
		$age2leaves.show()
	elif age==3:
		$CollisionShape3D.disabled = false
		$Hole.show()
		$age3trunk.show()
		$age3leaves.show()
	elif age>=4:
		add_to_group("tree")
		$CollisionShape3D.disabled = false
		$trunk.show()
		$leaves.show()
		$growthTimer.stop()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if still:
		return
	if health <= 0 and not chopped:
		freeze = false
		chopped = true
		$growthTimer.stop()
		angular_velocity.x += PI
		for child in get_children():
			if child.is_in_group("leave"):
				child.hide()
			if child is CPUParticles3D:
				child.emitting = true
		$"..".treePositions.erase(position)
		for i in range($"..".random.randi_range(0,2)):
			$"..".spawnAcorn($acornSpawn.global_position)


func _on_body_entered(body):
	var impact = linear_velocity.length()
	if impact < 0.5:
		return

	$fall.volume_db = lerp(-20.0, 0.0, clamp(impact / 10.0, 0.0, 1.0))
	$fall.pitch_scale = randf_range(0.9, 1.1) 
	$fall.play()
func getForceSum():
	return linear_velocity.length_squared() + angular_velocity.length_squared()


func _on_growth_timer_timeout() -> void:
	setAge(age+1)
	$growthTimer.wait_time = growTime + random.randf_range(0-growTime/2,growTime/2)
