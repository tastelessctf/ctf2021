extends "res://game/unit/npc.gd"

func _init().(Game.Unit.NPC, "McHammer", 100):
	unit_team = "Island Owner"
	remote_id = 333

func _ready():
	Server.enemies["player_333"] = self

func interact():
	Ui.ask("It's hammertime.\n\nWe need to secure our Island, can you help?\n\nThis hammer should be helpful.")
	Client.interact(333)

func server_interact(from):
	Server.add_item(from, Items.IDs.HAMMER)
