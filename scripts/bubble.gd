extends PanelContainer

# One speech bubble, owned by a single npc. It follows its own target in screen space
# and owns its own bounce effect, so two npcs talking at once can't reset each other's
# glyph timings or fight over one label.
#
# Showing and hiding spring rather than snap, using the same TRANS_BACK / EASE_OUT
# feel as the menu dropdown's pop-in (see dropdown.gd::_pop_in).

const BounceFXScript = preload("res://scripts/rich_text_bounce.gd")

@export var offset = Vector2(0, -40)
## Scale it springs out from, and collapses back down to.
@export var popFrom = Vector2(0.55, 0.6)
@export var popTime = 0.24
@export var popOutTime = 0.14

var target: Node3D      # the npc's textBoxPos marker
var cam: Camera3D
var fx
var tween: Tween

@onready var label = $MarginContainer/RichTextLabel

func _ready() -> void:
	fx = BounceFXScript.new()
	label.install_effect(fx)
	label.text = ""
	modulate.a = 0.0
	hide()

# point this bubble at an npc; called once when the npc first speaks
func follow(marker: Node3D, camera: Camera3D) -> void:
	target = marker
	cam = camera

func setText(bbcode: String) -> void:
	label.text = bbcode

func clear() -> void:
	label.text = ""
	fx.reset()

# springs up out of the speaker's head
func popIn() -> void:
	refit()
	show()
	if tween: tween.kill()
	scale = popFrom
	tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, popTime).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, popTime * 0.5)

func popOut() -> void:
	if not visible:
		return
	if tween: tween.kill()
	tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", popFrom, popOutTime).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, popOutTime)
	tween.chain().tween_callback(hide)

# straight off, no animation — for a cancelled cutscene
func hideNow() -> void:
	if tween: tween.kill()
	modulate.a = 0.0
	hide()

# re-fit to the current text (top-level controls don't auto-shrink) and keep the pivot
# at the bottom middle, so it scales up out of the speaker instead of out of its own
# top-left corner
func refit() -> void:
	size = Vector2.ZERO
	pivot_offset = Vector2(size.x * 0.5, size.y)

func _process(_delta: float) -> void:
	if not visible or not target or not cam:
		return
	refit()
	position = offset + cam.unproject_position(target.global_position) - size / 2.0
