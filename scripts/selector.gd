extends PanelContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

@onready var items = {
	"fashion":{
		"name": "Dressing Room",
		"items": {
			"Trainers":{
				"image": preload("res://images/shoes.png"),
				},
			},
		},
	}
@onready var item = preload("res://scenes/selectorItem.tscn")

var place = ""


func open(newPlace):
	if place == newPlace:
		return
	place = newPlace
	for i in $VBoxContainer.get_children():
		if i is CheckBox:
			i.queue_free()
	$VBoxContainer/Label.text = items[place]["name"]
	for itemName in items[place]["items"]:
		var child = item.instantiate()
		if SaveManager.getItem(itemName,"has"):
			child.icon = items[place]["items"][itemName]["image"]
			child.text = itemName
			child.pressed = SaveManager.getItem(itemName,"selected")
			$VBoxContainer.add_child(child)
	if $VBoxContainer.get_child_count() > 1:
		show()
	$AnimationPlayer.play("in")


func close():
	if place == "":
		return
	place = ""
	$AnimationPlayer.play("out")
