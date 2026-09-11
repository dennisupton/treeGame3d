extends CanvasLayer

@onready var bar = $center/box/ProgressBar
@onready var status = $center/box/status

func setStatus(text):
	status.text = text

func setProgress(value):
	bar.value = clampf(value, 0.0, 1.0) * 100.0
