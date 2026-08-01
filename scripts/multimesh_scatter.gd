@tool
extends Node3D
## Scatters many copies of a mesh using MultiMesh — one draw call per source mesh,
## regardless of how many copies there are.
##
## Attach to any Node3D, pick a Source Mesh (or Source Scene) and a Shape, then
## tweak the settings in the inspector. Runs in the editor (@tool) for a live
## preview and at runtime, so the layout exists in-game without thousands of
## nodes being saved into the .tscn.
##
## Note: MultiMesh is rendering only — the scattered copies have no collision.
## If you need the player to bump into them, add collision separately.

enum Shape {
	PLANE, ## Random positions inside a flat rectangle centred on this node.
	RING,  ## Evenly spaced around a circle, optionally with a gap.
}

## Mesh to scatter. Takes priority over Source Scene — set this for simple
## primitives (e.g. a SphereMesh).
@export var source_mesh: Mesh = null:
	set(value):
		source_mesh = value
		_meshes_dirty = true
		_queue_rebuild()

## Model to scatter, when the source is an imported scene rather than a bare
## mesh (e.g. a .blend). Every MeshInstance3D inside it is scattered, keeping
## its offset within the scene.
@export var source_scene: PackedScene = null:
	set(value):
		source_scene = value
		_meshes_dirty = true
		_queue_rebuild()

## How the copies are laid out.
@export var shape: Shape = Shape.PLANE:
	set(value):
		shape = value
		_queue_rebuild()
		notify_property_list_changed()

## Height the copies sit at, relative to this node.
@export var height: float = 0.0:
	set(value):
		height = value
		_queue_rebuild()

@export_group("Plane")

## Size of the rectangle to scatter across, in metres (X by Z).
@export var plane_size: Vector2 = Vector2(20.0, 20.0):
	set(value):
		plane_size = value.maxf(0.0)
		_queue_rebuild()

## How many copies to place on the plane.
@export_range(0, 5000, 1, "or_greater") var count: int = 100:
	set(value):
		count = max(value, 0)
		_queue_rebuild()

@export_group("Ring")

## Radius of the circle, in metres.
@export_range(0.0, 100.0, 0.1, "or_greater") var radius: float = 8.0:
	set(value):
		radius = max(value, 0.0)
		_queue_rebuild()

## Distance between neighbours along the circle, in metres.
## Smaller spacing -> more copies -> a denser, more solid wall.
@export_range(0.1, 20.0, 0.1, "or_greater") var spacing: float = 1.5:
	set(value):
		spacing = max(value, 0.05)
		_queue_rebuild()

## Width of an opening (gap) in the ring, in degrees. 0 = a full, closed ring.
@export_range(0.0, 359.0, 1.0) var gap_degrees: float = 0.0:
	set(value):
		gap_degrees = clampf(value, 0.0, 359.0)
		_queue_rebuild()

## Direction the gap faces, in degrees around the circle.
@export_range(-180.0, 180.0, 1.0) var gap_direction_degrees: float = 0.0:
	set(value):
		gap_direction_degrees = value
		_queue_rebuild()

## Rotate each copy to face outward from the centre.
@export var face_outward: bool = true:
	set(value):
		face_outward = value
		_queue_rebuild()

@export_group("Variation")

## Extra yaw applied to every copy (degrees). Use this to correct the model's
## facing so they all point the proper way.
@export_range(-180.0, 180.0, 1.0) var yaw_offset_degrees: float = 0.0:
	set(value):
		yaw_offset_degrees = value
		_queue_rebuild()

## Optional random yaw (degrees) added on top, for a less uniform, more natural
## look. 0 = perfectly uniform.
@export_range(0.0, 180.0, 1.0) var random_yaw_degrees: float = 0.0:
	set(value):
		random_yaw_degrees = value
		_queue_rebuild()

## Random uniform scale range. Set both to 1 for no size variation.
@export var scale_range: Vector2 = Vector2.ONE:
	set(value):
		scale_range = value
		_queue_rebuild()

## Changes the random layout without changing any other setting.
@export var random_seed: int = 0:
	set(value):
		random_seed = value
		_queue_rebuild()

## Tick to force a rebuild (e.g. after editing the source model itself).
@export var rebuild: bool = false:
	set(_value):
		rebuild = false
		_meshes_dirty = true
		_queue_rebuild()

const _CHILD_PREFIX := "_Scatter"

# Meshes pulled out of the source, with each one's offset inside the source
# scene. Cached so tweaking a slider doesn't re-instantiate the model.
var _meshes: Array[Mesh] = []
var _mesh_offsets: Array[Transform3D] = []
var _mesh_overrides: Array[Material] = []
var _meshes_dirty := true
var _rebuild_queued := false
var _source_has_collision := false


func _ready() -> void:
	_meshes_dirty = true
	_queue_rebuild()


# Collapses a burst of setter calls (or a whole scene load) into one rebuild.
func _queue_rebuild() -> void:
	if _rebuild_queued or not is_inside_tree():
		return
	_rebuild_queued = true
	_do_rebuild.call_deferred()


func _do_rebuild() -> void:
	_rebuild_queued = false
	if not is_inside_tree():
		return

	if _meshes_dirty:
		_collect_meshes()
		_meshes_dirty = false
		update_configuration_warnings()

	var transforms := _build_transforms()
	_apply(transforms)


## Pulls every mesh out of the source, along with where it sits inside the
## source scene, so a multi-part model scatters correctly.
func _collect_meshes() -> void:
	_meshes.clear()
	_mesh_offsets.clear()
	_mesh_overrides.clear()
	_source_has_collision = false

	if source_mesh != null:
		_meshes.append(source_mesh)
		_mesh_offsets.append(Transform3D.IDENTITY)
		_mesh_overrides.append(null)
		return

	if source_scene == null:
		return

	# Instantiated once and thrown away — we only want the mesh resources.
	var probe := source_scene.instantiate()
	_walk(probe, probe, Transform3D.IDENTITY)
	probe.free()


func _walk(node: Node, root: Node, accumulated: Transform3D) -> void:
	var here := accumulated
	if node is Node3D and node != root:
		here = accumulated * (node as Node3D).transform

	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			_meshes.append(mi.mesh)
			_mesh_offsets.append(here)
			_mesh_overrides.append(mi.material_override)
	elif node is CollisionObject3D or node is CollisionShape3D:
		_source_has_collision = true

	for child in node.get_children():
		_walk(child, root, here)


func _build_transforms() -> Array[Transform3D]:
	match shape:
		Shape.RING:
			return _ring_transforms()
		_:
			return _plane_transforms()


func _plane_transforms() -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3(plane_size.x, plane_size.y, float(random_seed)))

	var half := plane_size * 0.5
	for i in count:
		var pos := Vector3(rng.randf_range(-half.x, half.x), height, rng.randf_range(-half.y, half.y))
		result.append(Transform3D(_orientation(Basis(), rng), pos))
	return result


func _ring_transforms() -> Array[Transform3D]:
	var result: Array[Transform3D] = []

	# The copies fill the circle minus the gap; spacing stays consistent.
	var gap := clampf(deg_to_rad(gap_degrees), 0.0, TAU)
	var arc := TAU - gap
	var closed := gap <= 0.0
	# A closed ring wraps around with no seam; an open arc places a copy at each
	# end so the wall finishes cleanly on both edges of the gap.
	var ring_count := int(round(arc * radius / spacing))
	ring_count = max(ring_count, 3) if closed else max(ring_count + 1, 2)
	# Start at one edge of the gap and sweep across the arc to the other edge.
	var start := deg_to_rad(gap_direction_degrees) + gap / 2.0

	# Stable jitter: the same settings always produce the same layout.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3(radius, spacing, float(random_seed)))

	for i in ring_count:
		var t := float(i) / float(ring_count) if closed else float(i) / float(ring_count - 1)
		var angle := start + arc * t
		var dir := Vector3(cos(angle), 0.0, sin(angle))

		var facing := Basis.looking_at(dir) if face_outward else Basis()
		result.append(Transform3D(_orientation(facing, rng), dir * radius + Vector3(0.0, height, 0.0)))
	return result


## Applies the shared yaw / random yaw / random scale on top of a base basis.
## Yaw is pre-multiplied so it rotates around this node's up axis, matching
## Node3D.rotate_y().
func _orientation(from: Basis, rng: RandomNumberGenerator) -> Basis:
	var result := from
	if yaw_offset_degrees != 0.0:
		result = Basis(Vector3.UP, deg_to_rad(yaw_offset_degrees)) * result
	if random_yaw_degrees > 0.0:
		var jitter := deg_to_rad(random_yaw_degrees)
		result = Basis(Vector3.UP, rng.randf_range(-jitter, jitter)) * result
	if scale_range != Vector2.ONE:
		result = result.scaled(Vector3.ONE * rng.randf_range(scale_range.x, scale_range.y))
	return result


## Pushes the transforms into one MultiMeshInstance3D per source mesh. Children
## are reused rather than recreated, so dragging a slider only rewrites the
## transform buffer.
func _apply(transforms: Array[Transform3D]) -> void:
	var existing := _scatter_children()

	# Drop any children left over from a source with more meshes than this one.
	# Removed from the tree immediately so a same-frame rebuild can't find them.
	for i in range(_meshes.size(), existing.size()):
		remove_child(existing[i])
		existing[i].queue_free()

	for i in _meshes.size():
		var mmi: MultiMeshInstance3D
		if i < existing.size():
			mmi = existing[i]
		else:
			mmi = MultiMeshInstance3D.new()
			mmi.name = "%s%d" % [_CHILD_PREFIX, i]
			# owner intentionally left unset, so the generated nodes are
			# regenerated on load instead of being baked into the .tscn.
			add_child(mmi)

		var mm := mmi.multimesh
		if mm == null:
			mm = MultiMesh.new()
			mmi.multimesh = mm

		# transform_format and mesh must be set before instance_count, and
		# instance_count before buffer, or the buffer gets discarded.
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _meshes[i]
		mm.instance_count = transforms.size()
		if transforms.size() > 0:
			mm.buffer = _pack(transforms, _mesh_offsets[i])
			# Set explicitly: a bulk buffer assignment doesn't always leave the
			# renderer with bounds covering every instance, which shows up as
			# the whole batch vanishing when the camera looks away.
			mm.custom_aabb = _bounds(transforms, _mesh_offsets[i], _meshes[i])
		mmi.material_override = _mesh_overrides[i]


func _scatter_children() -> Array[MultiMeshInstance3D]:
	var found: Array[MultiMeshInstance3D] = []
	for child in get_children():
		if child is MultiMeshInstance3D and child.name.begins_with(_CHILD_PREFIX):
			found.append(child)
	return found


## Flattens transforms into the row-major 3x4 layout MultiMesh.buffer expects.
## One bulk assignment beats N set_instance_transform() calls.
func _pack(transforms: Array[Transform3D], offset: Transform3D) -> PackedFloat32Array:
	var buffer := PackedFloat32Array()
	buffer.resize(transforms.size() * 12)
	var i := 0
	for placement in transforms:
		var t := placement * offset
		buffer[i + 0] = t.basis.x.x
		buffer[i + 1] = t.basis.y.x
		buffer[i + 2] = t.basis.z.x
		buffer[i + 3] = t.origin.x
		buffer[i + 4] = t.basis.x.y
		buffer[i + 5] = t.basis.y.y
		buffer[i + 6] = t.basis.z.y
		buffer[i + 7] = t.origin.y
		buffer[i + 8] = t.basis.x.z
		buffer[i + 9] = t.basis.y.z
		buffer[i + 10] = t.basis.z.z
		buffer[i + 11] = t.origin.z
		i += 12
	return buffer


## Bounding box covering every placed copy, for culling.
func _bounds(transforms: Array[Transform3D], offset: Transform3D, mesh: Mesh) -> AABB:
	var local := mesh.get_aabb()
	var result := AABB()
	for i in transforms.size():
		var placed := (transforms[i] * offset) * local
		result = placed if i == 0 else result.merge(placed)
	return result


## Hides the settings that don't apply to the chosen Shape.
func _validate_property(property: Dictionary) -> void:
	var plane_only := ["plane_size", "count"]
	var ring_only := ["radius", "spacing", "gap_degrees", "gap_direction_degrees", "face_outward"]
	var hidden := ring_only if shape == Shape.PLANE else plane_only
	if property.name in hidden:
		property.usage &= ~PROPERTY_USAGE_EDITOR


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if source_mesh == null and source_scene == null:
		warnings.append("Set a Source Mesh or a Source Scene to scatter.")
	elif _meshes.is_empty():
		warnings.append("The source contains no MeshInstance3D with a mesh — nothing to scatter.")
	if _source_has_collision:
		warnings.append("The source scene has collision, which MultiMesh cannot reproduce. The scattered copies will not be solid.")
	return warnings
