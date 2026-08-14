extends AnimatedSprite2D

var base = {
	"keyboard": 0,
	"xbox":1,
	"playstation":1,
	"mouse":2
}
var glyphs ={
	"keyboard":{
		KEY_W:12,
		KEY_A:0,
		KEY_S:9,
		KEY_D:3,
		KEY_Q:7,
		KEY_E:4,
	},
	"xbox":{
		JOY_BUTTON_A: 1,
		JOY_BUTTON_B: 2,
		JOY_BUTTON_X: 13,
		JOY_BUTTON_Y: 14,
	},
	"playstation":{
		JOY_BUTTON_A: 13,
		JOY_BUTTON_B: 6,
		JOY_BUTTON_X: 10,
		JOY_BUTTON_Y: 11,
	},
	"mouse":{
		MOUSE_BUTTON_LEFT:5,
		MOUSE_BUTTON_RIGHT:8,
	}
}
var type
var glyph
var joystick = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if type and glyph:
		if not base.has(type):
			type = "xbox"
		frame = base[type]
		if joystick:
			$AnimationPlayer.play("spin")
			$glyph.frame = 15
			return
		var index
		if glyph is InputEventMouseButton or glyph is InputEventJoypadButton:
			index = glyph.button_index
		elif glyph is InputEventKey:
			index = keycodeOf(glyph)
		if index in glyphs[type].keys():
			$glyph.frame = glyphs[type][index]
		elif glyph is InputEventKey:
			var text = OS.get_keycode_string(keycodeOf(glyph))
			if text != "":
				$glyph.hide()
				$Label.show()
				$Label.text = text
	else:
		print("invalid glyph params")
		queue_free()

func keycodeOf(event):
	return event.physical_keycode if event.physical_keycode != 0 else event.keycode
