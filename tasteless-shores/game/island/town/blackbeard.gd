extends "res://game/unit/npc.gd"

var player_damage = {}

func _init().(Game.Unit.NPC, "BlackBeard", 1000.0):
	remote_id = 666
	height = 4.0

func _ready():
	Server.enemies["player_666"] = self
	character.equip(Items.by_id(Items.IDs.AXE1))

func damage(amount: float, from = null):
	if from == null:
		return

	if !(from.remote_id in player_damage):
		player_damage[from.remote_id] = 0
	
	player_damage[from.remote_id] += amount

	Server.unit_damage(self, 1000-player_damage[from.remote_id], from)

	if player_damage[from.remote_id] > 1000:
		Server.spawn_chest(from, "FLAG_BLACKBEARD", Server.flags["FLAG_BLACKBEARD"].global_transform.origin)
		player_damage.erase(from.remote_id)

func _process(delta):
	if Client.socket != null:
		if 'FLAG_BLACKBEARD' in Client.player.marker and !died:
			emit_signal("died")
			died = true
	if Server.socket != null:
		for p in player_damage.keys():
			player_damage[p] -= delta * 100 # heal fast
			Server.unit_damage(self, 1000-player_damage[p], null)
			if player_damage[p] <= 0:
				player_damage.erase(p)
