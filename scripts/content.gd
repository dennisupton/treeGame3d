extends VBoxContainer

signal email_opened(data)

@onready var title: Label = $Label
@onready var body: RichTextLabel = $RichTextLabel

const REPLY_SPEED = 0.05

var replyIdx = 0
var replyTimer = 0.0
var data
var currentEmail


func open_email(email: Button) -> void:
	currentEmail = email
	data = email.get_meta("data")
	title.text = data["subject"]
	if data["type"] == "escape1" or data["type"] == "escape5":
		title.label_settings.font_color = Color("#2e7d32")
		body.text = "[shake rate=6 level=3][color=#2e7d32]%s[/color][/shake]" % data["content"]
		body.visible_ratio = 0.0
		var tw = create_tween()
		if data["type"] == "escape1":
			tw.tween_property(body, "visible_ratio", 1.0, data["content"].length() * REPLY_SPEED*2)
			tw.tween_callback($Read.show)
		else:
			tw.tween_property(body, "visible_ratio", 1.0, data["content"].length() * REPLY_SPEED*10)
			tw.tween_callback($go.show)
	else:
		title.label_settings.font_color = Color.BLACK
		body.text = data["content"]
		body.visible_ratio = 1.0
	replyIdx = 0
	replyTimer = 0.0
	$response.text = ""
	if data["type"] == "respond":
		$Respond.show()
		$Read.hide()
	elif data["type"] == "read":
		$Read.show()
		$Respond.hide()
	if data["type"] == "escape1" or data["type"] == "escape5":
		$Read.hide()
		$Respond.hide()

func _process(delta: float) -> void:
	if $Respond.button_pressed and $Respond.visible:
		if not $"../../../../typing".playing:
			$"../../../../typing".play()
		replyTimer += delta
		if replyTimer >= REPLY_SPEED:
			replyTimer -= REPLY_SPEED
			if replyIdx < len(data["response"]):
				$response.text += data["response"][replyIdx]
				replyIdx += 1
			else:
				email_opened.emit(data)
				$"../../../../send".play()
				currentEmail.queue_free()
				$Respond.hide()
	else:
		$"../../../../typing".stop()

func clear():
	body.text = ""
	title.text = ""
func _on_read_pressed() -> void:
	if currentEmail:
		email_opened.emit(data)
		currentEmail.queue_free()
		$Read.hide()


func _on_go_pressed() -> void:
	$"../../../../AnimationPlayer".play("go")
