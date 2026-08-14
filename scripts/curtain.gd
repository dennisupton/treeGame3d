extends Area3D

var playerInside = false


func _process(delta: float) -> void:
	var inside = $"../../player" in get_overlapping_bodies()
	if inside == playerInside:
		return
	playerInside = inside
	if inside:
		$curtainAnim.play("open")
	else:
		$curtainAnim.play("close")
