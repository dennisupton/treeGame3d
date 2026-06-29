extends Node3D

var introPlayed = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if $"../player" in $mayor/Area3D.get_overlapping_bodies() and not introPlayed:
		$cutscene.play("introduction")
		introPlayed = true
