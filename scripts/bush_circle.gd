@tool
extends Node3D
## Places bush instances evenly around a circle to form a circular wall / hedge.
##
## Attach to a Node3D and tweak Radius / Spacing in the inspector — the ring
## rebuilds itself instantly. Runs in the editor (@tool) for a live preview and
## also at runtime, so the wall exists in-game without the nodes being saved
## into the .tscn.

## Scene placed around the circle (defaults to the bush model).
@export var bush_scene: PackedScene = preload("res://models/bush.blend"):
	set(value):
		bush_scene = value
		_rebuild()

## Radius of the circle, in metres.
@export_range(0.0, 100.0, 0.1, "or_greater") var radius: float = 8.0:
	set(value):
		radius = max(value, 0.0)
		_rebuild()

## Distance between neighbouring bushes along the circle, in metres.
## Smaller spacing -> more bushes -> a denser, more solid wall.
@export_range(0.1, 20.0, 0.1, "or_greater") var spacing: float = 1.5:
	set(value):
		spacing = max(value, 0.05)
		_rebuild()

## Width of an opening (gap) in the wall, in degrees. 0 = a full, closed ring.
@export_range(0.0, 359.0, 1.0) var gap_degrees: float = 0.0:
	set(value):
		gap_degrees = clampf(value, 0.0, 359.0)
		_rebuild()

## Direction the gap faces, in degrees around the circle. Rotate this to move
## the opening to whichever side you want.
@export_range(-180.0, 180.0, 1.0) var gap_direction_degrees: float = 0.0:
	set(value):
		gap_direction_degrees = value
		_rebuild()

## Height the bushes sit at (lifts the model up onto the ground).
@export var height: float = 0.7446475:
	set(value):
		height = value
		_rebuild()

## Rotate each bush to face outward from the centre.
@export var face_outward: bool = true:
	set(value):
		face_outward = value
		_rebuild()

## Extra yaw applied to every bush (degrees). Use this to correct the model's
## facing so they all point the proper way.
@export_range(-180.0, 180.0, 1.0) var yaw_offset_degrees: float = 0.0:
	set(value):
		yaw_offset_degrees = value
		_rebuild()

## Optional random yaw (degrees) added on top, for a less uniform, more
## natural-looking hedge. 0 = perfectly uniform.
@export_range(0.0, 180.0, 1.0) var random_yaw_degrees: float = 0.0:
	set(value):
		random_yaw_degrees = value
		_rebuild()

## Tick to force a rebuild (e.g. after editing the bush model itself).
@export var rebuild: bool = false:
	set(_value):
		rebuild = false
		_rebuild()

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	# Setters fire while the scene is still loading; wait until we're in the tree.
	if not is_inside_tree() or bush_scene == null:
		return

	# Clear any bushes from a previous build.
	for child in get_children():
		remove_child(child)
		child.queue_free()

	# The bushes fill the circle minus the gap; spacing stays consistent.
	var gap := clampf(deg_to_rad(gap_degrees), 0.0, TAU)
	var arc := TAU - gap
	var closed := gap <= 0.0
	# A closed ring wraps around with no seam; an open arc places a bush at each
	# end so the wall finishes cleanly on both edges of the gap.
	var count := int(round(arc * radius / spacing))
	count = max(count, 3) if closed else max(count + 1, 2)
	# Start at one edge of the gap and sweep across the arc to the other edge.
	var start := deg_to_rad(gap_direction_degrees) + gap / 2.0

	# Stable jitter: the same settings always produce the same layout.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2(radius, spacing))

	for i in count:
		var t := float(i) / float(count) if closed else float(i) / float(count - 1)
		var angle := start + arc * t
		var dir := Vector3(cos(angle), 0.0, sin(angle))

		var bush := bush_scene.instantiate()
		add_child(bush)
		bush.name = "Bush%d" % i
		bush.position = dir * radius + Vector3(0.0, height, 0.0)

		if face_outward:
			bush.basis = Basis.looking_at(dir)
		if yaw_offset_degrees != 0.0:
			bush.rotate_y(deg_to_rad(yaw_offset_degrees))
		if random_yaw_degrees > 0.0:
			bush.rotate_y(deg_to_rad(rng.randf_range(-random_yaw_degrees, random_yaw_degrees)))

	# Note: owner is intentionally left unset, so the generated bushes are
	# regenerated on load instead of being baked into (and bloating) the scene.
