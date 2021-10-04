extends "res://game/unit/npc.gd"

var spawn : Vector3

func _init(type=Game.Unit.NPC, unit_name=">enemy<", health = 100.0).(type, unit_name, health):
	assert(connect("died", self, "_on_enemy_died") == OK)

func _on_enemy_died():
	var timer = Timer.new()
	add_child(timer)
	timer.connect("timeout", self, "queue_free")
	timer.start(15)

func die():
	.die()
	_on_enemy_died()
