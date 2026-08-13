extends GPUParticles3D

# Drives shaders/moneyFlow.gdshader — the green circles that spiral out of the well and
# up into the money counter.
#
# The counter is a Control on a CanvasLayer, so it has no world position, and no
# particle attractor can reach it (every GPUParticlesAttractor class is 3D-only). So we
# aim at the world point that PROJECTS onto it: take the label's screen position, push
# it back out in front of the camera with project_position(), hand that to the shader as
# `target`. Refreshed every frame while a burst is in flight, so the circles keep
# tracking the counter as the camera moves.

@export var labelPath: NodePath        # the money counter
@export var camPath: NodePath
@export var moneyHolder: NodePath      # the node that owns `money` (main)

@export var targetDepth = 6.0     
@export var circlesPerCash = 1.5
@export var minCircles = 5
@export var maxCircles = 200
@export var punchScale = 1.3        
@export var punchTime = 0.2

@onready var label: Control = get_node(labelPath)
@onready var cam: Camera3D = get_node(camPath)
@onready var holder = get_node(moneyHolder)
@onready var mat: ShaderMaterial = process_material

var flying = 0.0  

func _ready() -> void:
	one_shot = true
	emitting = false

func _process(delta: float) -> void:
	if flying <= 0.0:
		return
	flying -= delta
	mat.set_shader_parameter("target", targetPoint())

func targetPoint() -> Vector3:
	return cam.project_position(label.global_position + label.size * 0.5, targetDepth)

func burst(cash: int) -> void:
	amount = clampi(int(cash * circlesPerCash), minCircles, maxCircles)
	mat.set_shader_parameter("target", targetPoint())
	flying = lifetime
	restart()
	await get_tree().create_timer(lifetime * 0.88).timeout
	land(cash)

func land(cash: int) -> void:
	$"../..".money += cash

	var sfx = holder.get_node_or_null("audio/money")
	if sfx:
		sfx.play()
