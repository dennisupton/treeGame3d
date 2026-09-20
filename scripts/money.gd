extends Label

# the counter chases the real balance rather than jumping to it, but the rate scales
# with how far it has to go, so five dollars and five hundred both land in about the
# same beat. MIN_RATE keeps the last couple ticking over instead of snapping.
const SETTLE = 0.35      # seconds to close most of the gap
const MIN_RATE = 15.0    # dollars a second

var dispAmount = 0.0
var speed = 0.0
var shadow = 0.0   # shadow_size is an int, so the easing needs somewhere with decimals to live

func balance():
	return float($"../../..".money)

# the counter ticking over is the point when you earn or spend money, and very much
# not the point when a save is loaded. this jumps it straight to the total.
func snap():
	dispAmount = balance()
	speed = 0.0
	shadow = 0.0
	label_settings.shadow_size = 0

func _process(delta: float) -> void:
	var goal = balance()
	var falling = goal < dispAmount
	var gap = absf(goal - dispAmount)
	dispAmount = move_toward(dispAmount, goal, maxf(gap / SETTLE, MIN_RATE) * delta)
	# truncated rather than rounded: rounding up would show money you don't have yet
	text = "$" + str(int(dispAmount))
	visible = goal > 0 or gap > 0.5   # don't blink out halfway through spending it all

	var moving = gap > 0.01
	var t = 1.0 - exp(-20.0 * delta)   # same feel as the old 0.3 lerp, minus the framerate tie
	# a loss shakes harder and sits lower than a gain, so the two read apart at a glance
	speed = lerp(speed, (2.2 if falling else 1.4) if moving else 0.0, t)
	shadow = lerp(shadow, 50.0 if moving else 0.0, t)
	label_settings.shadow_size = int(shadow)
	offset_transform_position = lerp(offset_transform_position,
		Vector2(0, 6) if moving and falling else Vector2.ZERO, t)
	material.set_shader_parameter("speed", speed)
