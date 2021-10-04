extends PanelContainer

const Item = preload("res://game/items/item.gd")
const Player = preload("res://game/player/player.gd")
const Weapon = preload("res://game/items/weapon.gd")

onready var item_list = $ItemList as ItemList

var items = []
var player: Player = null

func _ready():
	Client.connect("send_join", self, "_on_Client_send_join")
	(get_parent().get_node("CrossHair/ProgressBar/AnimationPlayer") as AnimationPlayer).play("fill", -1, 1)

func _on_Client_send_join():
	items.clear()
	item_list.clear()

func add_item(item: Item):
	if items.has(item):
		return
	items.append(item)
	item_list.add_item(item.name(), item.icon())
	Ui.show_note("Received " + item.name())

func _on_ItemList_item_selected(index: int):
	player = Client.player

	var item = items[index]
	if item is Weapon:
		item_list.hide()
		player.start_equip(item.id)
		(get_parent().get_node("CrossHair/ProgressBar/AnimationPlayer") as AnimationPlayer).play("fill", -1, 1)
		hide()
		Ui.game_mouse()
		yield(player, "equipped")
		item_list.show()
