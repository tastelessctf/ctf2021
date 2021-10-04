extends "res://game/unit/npc.gd"

func _init().(Game.Unit.NPC, "Leaky Luke", 100.0):
	unit_team = "Fisher Guild"
	remote_id = 111

func _ready():
	Server.enemies["player_111"] = self

func interact():
	if 'FLAG_BOAT' in Client.player.marker:
		Ui.ask("That is some real leet fishing skillz you got. You have a boat now to enter the water.")
	else:
		Ui.ask("I've been a fisher myself, young lad...\n\nBut to get a boat, you need to prove yourself.\n\nThere is fish in the west, but you gotta fish in the Lake'o'despair to prove yourself being worth it.")
		Client.interact(111)

func server_interact(from):
	Server.add_item(from, Items.IDs.FISHINGROD1)
