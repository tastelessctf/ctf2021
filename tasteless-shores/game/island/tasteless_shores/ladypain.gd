extends "res://game/unit/npc.gd"

func _init().(Game.Unit.NPC, "Lady Pain", 100.0):
	unit_team = ""
	remote_id = 112

func _ready():
	Server.enemies["player_112"] = self

func interact():
	Ui.ask("I miss Major Payne...\n\nIt's dangerous to go alone! Take this!")
	Client.interact(112)

func server_interact(from):
	Server.add_item(from, Items.IDs.PISTOL1)
