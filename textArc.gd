@tool
extends RichTextEffect
class_name ArcFX

var bbcode := "arc"
var _max_seen := 0
var _length := 1.0

const SWEEP := deg_to_rad(90.0)
const RADIUS := 120.0

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	if char_fx.relative_index == 0 and _max_seen > 0:
		_length = float(_max_seen)
	_max_seen = maxi(_max_seen, char_fx.relative_index)

	var ratio := clampf(char_fx.relative_index / maxf(_length, 1.0), 0.0, 1.0)
	var angle := SWEEP * (ratio - 0.5)

	char_fx.offset.y -= RADIUS * (cos(angle) - cos(SWEEP * 0.5))

	var origin := char_fx.transform.origin
	char_fx.transform.origin = Vector2.ZERO
	char_fx.transform = char_fx.transform.rotated(angle)
	char_fx.transform.origin = origin
	return true
