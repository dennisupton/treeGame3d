extends Button

@export var hover_scale := Vector2(1.13, 1.13)
@export var press_scale := Vector2(1.04, 0.88) # squish
@export var hover_tilt := 0.045
@export var hover_time := 0.34
@export var press_time := 0.07
@export var release_time := 0.4
@export var audio : AudioStreamPlayer
var random = RandomNumberGenerator.new()
var _tween: Tween


func _ready() -> void:
	_center_pivot()
	resized.connect(_center_pivot)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)


## Control scales from its top-left corner unless the pivot is moved.
func _center_pivot() -> void:
	pivot_offset = size / 2.0


## Odd siblings lean the other way, so a row of buttons fans out.
func _tilt() -> float:
	return hover_tilt if get_index() % 2 == 0 else -hover_tilt


func _spring_to(target_scale: Vector2, target_rot: float, time: float, trans: Tween.TransitionType) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "scale", target_scale, time).set_trans(trans).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "rotation", target_rot, time).set_trans(trans).set_ease(Tween.EASE_OUT)


func _on_mouse_entered() -> void:
	if disabled:
		return
	if audio:
		audio.pitch_scale = random.randf_range(0.8,1.2)
		audio.play()
	_spring_to(hover_scale, _tilt(), hover_time, Tween.TRANS_ELASTIC)


func _on_mouse_exited() -> void:
	if disabled:
		return
	_spring_to(Vector2.ONE, 0.0, hover_time * 0.7, Tween.TRANS_BACK)


func _on_button_down() -> void:
	_spring_to(press_scale, _tilt() * 0.4, press_time, Tween.TRANS_QUAD)


func _on_button_up() -> void:
	if is_hovered():
		_spring_to(hover_scale, _tilt(), release_time, Tween.TRANS_ELASTIC)
	else:
		_spring_to(Vector2.ONE, 0.0, release_time, Tween.TRANS_ELASTIC)
