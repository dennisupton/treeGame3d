extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if $"../../player" in get_overlapping_bodies() and $"../curtain".scale.x == 1:
		$curtainAnim.play("open")
	elif (not $"../../player" in get_overlapping_bodies()) and $"../curtain".scale.x <= 0.2:
		$curtainAnim.play("close")
