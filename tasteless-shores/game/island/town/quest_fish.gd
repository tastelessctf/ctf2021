extends "res://game/unit/npc.gd"

func _init().(Game.Unit.NPC, "Fishermans Friend", 100.0):
	remote_id = 222

func _ready():
	Server.enemies["player_222"] = self

func interact():
	Ui.ask("The white sea rabbit is hiding in the kelp forest... Can you find it for me?", self, "start_quest")
	Client.interact(222)

func server_interact(from):
	Server.add_item(from, Items.IDs.CONCH)
