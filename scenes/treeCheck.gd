extends Marker3D

@export var noneRadius: float
@export var radius: float


func canSpawnTreeAt(pos: Vector3):
	pos.y = 0
	if pos.distance_to(global_position) < noneRadius:
		return false
	elif pos.distance_to(global_position) < radius:
		return RandomNumberGenerator.new().randf_range(0,pos.distance_to(global_position)) < 1
	return true
