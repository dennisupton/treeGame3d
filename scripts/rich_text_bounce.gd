@tool
extends RichTextEffect
class_name BounceFX

# Use as [bounce]...[/bounce]. Each glyph hops up once when it first appears,
# then settles. Call reset() when starting a new message so indices re-bounce.
var bbcode := "bounce"

var birth := {}   # glyph index -> time (seconds) it was first seen

func reset() -> void:
	birth.clear()

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var i: int = char_fx.range.x
	var now: float = Time.get_ticks_msec() / 1000.0
	if not birth.has(i):
		birth[i] = now

	var dur := 0.3                    # how long the hop lasts (seconds)
	var height := 8.0                 # hop height in pixels
	var age: float = now - birth[i]
	if age < dur:
		var t := age / dur
		char_fx.offset.y -= height * (1.0 - t) * sin(t * PI)
	return true
