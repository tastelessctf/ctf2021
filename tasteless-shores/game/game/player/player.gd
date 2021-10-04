extends "res://game/unit/unit.gd"

const Game = preload("res://game/game.gd")
const Unit = preload("res://game/unit/unit.gd")

signal water_entered
signal water_exited

onready var boatMesh: MeshInstance = $Boat

var boat = false
var drowning = false
var marker = {
	"FLAG_EYES": true,
}
var buildings = []
var pvp = false

func _init().(Game.Unit.PLAYER, "", 100.0):
	pass

func damage(amount: float, from = null):
	if !pvp && from.type == Game.Unit.PLAYER:
		return
	.damage(amount, from)

func _ready():
	boatMesh.hide()

func _process(delta):
	if drowning:
		health -= delta * 10
		if Server.socket != null:
			Server.unit_damage(self, health, null)
		if health <= 0 && Server.socket != null:
			die()

func _setBoat(entered: bool):
	if Server.socket != null:
		return

	boat = entered
	if entered:
		emit_signal("water_entered")
		boatMesh.show()
	else:
		emit_signal("water_exited")
		boatMesh.hide()

func _on_Water_water_entered():
	if 'FLAG_BOAT' in marker:
		_setBoat(true)
	else:
		drowning = true
		if Client.player == self:
			Ui.show_note("I can't swim")

func _on_Water_water_exited():
	if 'FLAG_BOAT' in marker:
		_setBoat(false)
	else:
		drowning = false

func add_item(item: int, amount: int):
	Ui.inventory.add_item(Items.new().by_id(item))

func start_equip(item):
	Client.start_equip(item)

func start_attack(collider):
	if collider == null:
		Client.start_attack(0)
	else:
		Client.start_attack(collider.remote_id)
