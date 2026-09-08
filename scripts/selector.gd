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
	"axe":{
		"name": "Axe Rack",
		"items": {
			"Wooden Axe":{
				"image": preload("res://images/shoes.png"),
				},
			"Iron Axe":{
				"image": preload("res://images/shoes.png"),
				},
			},
		},
	}
@onready var item = preload("res://scenes/selectorItem.tscn")

var place = ""
var showing = false


func open(newPlace):
	if place == newPlace:
		return
	place = newPlace
	for i in $VBoxContainer.get_children():
		if i is CheckBox:
			i.queue_free()
	$VBoxContainer/Label.text = items[place]["name"]
	var owned = 0
	for itemName in items[place]["items"]:
		if not SaveManager.getItem(itemName,"has"):
			continue
		var child = item.instantiate()
		child.icon = items[place]["items"][itemName]["image"]
		child.text = itemName
		child.button_pressed = SaveManager.getItem(itemName,"selected")
		child.pressed.connect(pressed.bind(itemName,child))
		$VBoxContainer.add_child(child)
		owned += 1
	if owned > 0:
		showing = true
		show()
		$AnimationPlayer.play("in")

func pressed(itemName,button):
	SaveManager.saveItem(itemName,"selected",button.button_pressed)

func close():
	if place == "":
		return
	place = ""
	if not showing:
		return
	showing = false
	$AnimationPlayer.play("out")
	$"../../player".reloadEquipped()
