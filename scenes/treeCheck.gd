extends Marker3D

@export var noneRadius: float
@export var radius: float
@export var hasOuter = false
@export var outerNoneRadius: float
@export var outerRadius: float

func canSpawnTreeAt(pos: Vector3):
	pos.y = 0
	var distance = pos.distance_to(global_position)
	if distance < noneRadius or (hasOuter and distance > outerNoneRadius):
		return false
	elif pos.distance_to(global_position) < radius or (hasOuter and distance > outerRadius):
		if hasOuter and distance > outerRadius:
			return RandomNumberGenerator.new().randf_range(0,pos.distance_to(global_position)- outerRadius) < 1
		else:
			return RandomNumberGenerator.new().randf_range(0,pos.distance_to(global_position)) < 1
	return true


func canPlace(pos:Vector3):
	pos.y = 0
	var distance = pos.distance_to(global_position)
	if distance < noneRadius or (hasOuter and distance > outerNoneRadius):
		return false
	elif pos.distance_to(global_position) < radius or (hasOuter and distance > outerRadius):
		if hasOuter and distance > outerRadius:
			return false
		else:
			return false
	return true
