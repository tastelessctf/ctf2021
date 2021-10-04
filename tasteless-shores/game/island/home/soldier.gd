extends "res://game/unit/npc.gd"

const phrases = [
	"Blackbeard took over our fort, can you help us?",
	"Blackbeard is too strong for us",
	"Help us, I'm unable to kill a simple boss",
	"Blackbeard here, blackbeard there, nobody cares about us",
	"I used to be a pirate like you, then I took an arrow in the knee.",
]

const phrases_solve = [
	"Wohoo, finally we can get some flags",
	"Anyone here able to operate that arrow out of my knee?",
	"Are you sure he's dead now?",
	"Ding-Dong! The Boss Is Dead!",
]

func _init().(Game.Unit.NPC, "Soldier", 100.0):
	unit_team = "Fort Guard"

func interact():
	if 'FLAG_BLACKBEARD' in Client.player.marker:
		Ui.ask(phrases_solve[randi() % phrases_solve.size()])
	else:
		Ui.ask(phrases[randi() % phrases.size()])
