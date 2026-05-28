extends Panel

var items := {
	"stoneAxe": {
		"name": "Stone Axe",
		"price": 8,
		"description": "A axe made of stone",
		"type": "axe",
		"owned": false,
	},
	"ironAxe": {
		"name": "Iron Axe",
		"price": 20,
		"description": "A axe made of iron",
		"type": "axe",
		"owned": false,
	},
	"shoes": {
		"name": "Shoes",
		"price": 30,
		"description": "Increases speed",
		"type": "movement",
		"owned": false,
	},
	"gloves": {
		"name": "Gloves",
		"price": 45,
		"description": "Lets you chop faster",
		"type": "movement",
		"owned": false,
	},
	"wheelbarrow": {
		"name": "Wheelbarrow",
		"price": 50,
		"description": "not implemented yet",#"Allows you to carry 2 trees at once",
		"type": "movement",
		"owned": false,
	},
}
var axeIcon
var moveIcon

func _ready() -> void:
	axeIcon = preload("res://axe.png")
	moveIcon = preload("res://move.png")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func makeButtons():
	for i in $Items.get_children():
		i.name = "not"+i.name
		i.queue_free()
	var idx = 0
	for i in items:
		if idx < 3 and not items[i].owned:
			var child = Button.new()
			print(i)
			if items[i].type == "axe":
				child.icon = axeIcon
			elif items[i].type == "movement":
				child.icon = moveIcon
			child.text = items[i].name + "\n" + str(items[i].price)+ "\n" + str(items[i].description)
			child.disabled = items[i].price >$"../../..".money
			child.connect("pressed",buyButtonPressed,CONNECT_APPEND_SOURCE_OBJECT)
			$Items.add_child(child)
			child.name = i
			idx += 1

func buyButtonPressed(source: BaseButton) -> void:
	print(source.name)
	if source.name == "stoneAxe":
		$"../../../player".damage = 2
	if source.name == "ironAxe":
		$"../../../player".damage = 3
	if source.name == "shoes":
		$"../../../player".speedMulti = 1.5
	if source.name == "gloves":
		$"../../../player".axeSpeed = 1.5
	items[source.name].owned = true
	$"../../..".money -= items[source.name].price
	$"../../../CanvasLayer/Control/Label".text = "$ "+str($"../../..".money)
	$"../../../audio/money".play()
	makeButtons()
