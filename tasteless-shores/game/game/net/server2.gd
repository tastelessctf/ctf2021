extends Node

const Unit = preload("res://game/unit/unit.gd")
const NPC = preload("res://game/unit/npc.gd")
const Hammer = preload("res://island/home/hammer.gd")

const PlayerScene = preload("res://game/player/player.tscn")

var socket: StreamPeerTCP

const MsgServerUpdatePlayer  = 0xff
const MsgServerUpdatePlayers = 0xfe
const MsgServerJoin          = 0x11
const MsgServerLeave         = 0x99
const MsgServerAttack        = 0x4b
const MsgServerLoggedIn      = 0x66
const MsgServerFrame         = 0xcc
const MsgServerDie           = 0x01
const MsgServerEquip         = 0x02
const MsgServerDamage        = 0x33
const MsgServerItem          = 0x74
const MsgServerFish          = 0xb0
const MsgServerSolo          = 0x0b
const MsgServerTryFlag       = 0x67
const MsgServerFlag          = 0x68
const MsgServerChat          = 0x51
const MsgServerBld           = 0x61
const MsgServerBlds          = 0x62
const MsgServerSpawn         = 0x6f
const MsgServerTarget        = 0x6e
const MsgServerSpawnChest    = 0x90
const MsgServerMark          = 0x98
const MsgServerConch         = 0x91
const MsgServerInteract      = 0x20
const MsgServerAccount       = 0x03
const MsgServerTogglePVP     = 0x55
const MsgServerChangeArea    = 0x56

var enemies = {}
var flags = {}
var remote_thread
var ending = false

signal connected
signal connecting

func start():
	yield(get_tree(), "idle_frame")

	socket = StreamPeerTCP.new()
	prints("connecting", socket.connect_to_host("localhost", 33330))

	emit_signal("connecting")

	while true:
		match socket.get_status():
			StreamPeerTCP.STATUS_CONNECTED:
				break
			StreamPeerTCP.STATUS_CONNECTING:
				pass
			StreamPeerTCP.STATUS_ERROR:
				socket = null
				call_deferred("start")
				return "unable to connect"

	socket.set_no_delay(true)
	
	remote_thread = Thread.new()
	remote_thread.start(self, "_remote_thread")
	
	emit_signal("connected")

	return true

func _exit_tree():
	ending = true
	if socket != null:
		socket.disconnect_from_host()
		socket = null
	if remote_thread != null:
		remote_thread.wait_to_finish()

func _remote_thread(_userdata):
	while !ending:
		if socket == null:
			call_deferred("start")
			return

		if socket.get_status() == StreamPeerTCP.STATUS_ERROR || socket.get_status() == StreamPeerTCP.STATUS_NONE:
			socket = null
			call_deferred("start")
			return
	
		if socket.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			continue

		_threadProcess(0)
	call_deferred("start")

func _handleUpdatePlayer(pid, x, y, z):
	if !has_node("player_" + str(pid)):
		prints("error, unknown player update", pid)
		return
	var node = get_node("player_" + str(pid))
	node.global_transform.origin = Vector3(x, y, z)

func _handleUpdatePlayers(players):
	for p in players:
		if !has_node("player_" + str(p.pid)):
			prints("error, unknown player update", p.pid)
			continue
		var node = get_node("player_" + str(p.pid))
		node.global_transform.origin = Vector3(p.x, p.y, p.z)
	
func _handleJoin(pid, name, team, chars, x, y, z, markers):
	if has_node("player_" + str(pid)):
		get_node("player_" + str(pid)).queue_free()
		yield(get_tree(), "idle_frame")
	var player = PlayerScene.instance()
	player.name = "player_" + str(pid)
	player.remote_id = pid
	player.unit_name = name
	player.unit_team = team
	add_child(player)
	player.global_transform.origin = Vector3(x, y, z)
	for marker in markers:
		player.marker[marker] = true
		if marker in flags:
			spawn_chest(player, marker, flags[marker].global_transform.origin, false)

func _handleLeave(pid):
	if !has_node("player_" + str(pid)):
		prints("error, unknown player leave", pid)
		return
	var node = get_node("player_" + str(pid))
	node.queue_free()

func _handleAttack(pid, target):
	if !has_node("player_" + str(pid)):
		prints("error, unknown player attack", pid)
		return
	var node = get_node("player_" + str(pid))
	if has_node("player_" + str(target)):
		node.attack(get_node("player_" + str(target)))
	elif "player_" + str(target) in enemies:
		node.attack(enemies["player_" + str(target)])
	else:
		node.attack(null)

func _handleEquip(pid, item):
	if !has_node("player_" + str(pid)):
		prints("error, unknown player equip", pid)
		return
	var node = get_node("player_" + str(pid))
	node.equip(item)

func _handleFish(pid):
	if !has_node("player_" + str(pid)):
		prints("error, unknown player fish", pid)
		return
	var node = get_node("player_" + str(pid))
	spawn_chest(node, 'FLAG_BOAT', flags['FLAG_BOAT'].global_transform.origin)

func _handleTryFlag(pid, flag):
	if !has_node("player_" + str(pid)):
		prints("error, unknown player try flag", pid)
		return
	var node = get_node("player_" + str(pid))
	try_flag(node, flag)

func _handleChat(pid, whisper, msg):
	if "player_" + str(whisper) in enemies:
		if enemies["player_" + str(whisper)].has_method("chat"):
			enemies["player_" + str(whisper)].chat(get_node("player_" + str(pid)), msg)

func _handleBld(pid, bldid, x, y, z, r, data):
	if !has_node("player_" + str(pid)):
		prints("error, unknown player building", pid)
		return
	var node = get_node("player_" + str(pid))
	if bldid == 0x1337:
		spawn_chest(node, 'FLAG_HOME', flags['FLAG_HOME'].global_transform.origin)
	if bldid >= Hammer.items.size():
		return
	if node.buildings.size() < 20:
		node.buildings.push_back({"id": bldid, "x": x, "y": y, "z": z, "r": r, "data": data})
	player_buildings(node)

func _handleInteract(pid, tid):
	if "player_" + str(tid) in enemies:
		if enemies["player_" + str(tid)].has_method("server_interact"):
			enemies["player_" + str(tid)].server_interact(get_node("player_" + str(pid)))

func _handleTogglePVP(pid):
	if has_node("player_" + str(pid)):
		var node = get_node("player_" + str(pid))
		node.pvp = !node.pvp
		if node.pvp:
			chat(0, 0, node.unit_name + " enabled pvp")
		else:
			chat(0, 0, node.unit_name + " disabled pvp")

func _threadProcess(_delta):
	var start = OS.get_ticks_msec()
	var updates = 0
	while socket.get_available_bytes() > 0:
		updates += 1
		var start1 = OS.get_ticks_msec()
		var action = socket.get_u8()
		match action:
			MsgServerUpdatePlayer:
				var pid = socket.get_u64()
				var x = socket.get_double()
				var y = socket.get_double()
				var z = socket.get_double()
				socket.get_double()
				socket.get_double()
				socket.get_u8()
				call_deferred("_handleUpdatePlayer", pid, x, y, z)
			MsgServerUpdatePlayers:
				var length = socket.get_u8()
				var players = []
				for i in range(length):
					var pid = socket.get_u64()
					var x = socket.get_double()
					var y = socket.get_double()
					var z = socket.get_double()
					socket.get_double()
					socket.get_double()
					socket.get_u8()
					players.append({"pid": pid, "x": x, "y": y, "z": z})
				call_deferred("_handleUpdatePlayers", players)
			MsgServerJoin:
				var pid = socket.get_u64()
				var length = socket.get_u8()
				var name = socket.get_string(length)
				length = socket.get_u8()
				var team = socket.get_string(length)
				var chars = socket.get_u8()
				var x = socket.get_double()
				var y = socket.get_double()
				var z = socket.get_double()
				var sl = socket.get_u8()
				var markers = []
				for i in range(0, sl):
					length = socket.get_u8()
					var marker = socket.get_string(length)
					markers.append(marker)
				call_deferred("_handleJoin", pid, name, team, chars, x, y, z, markers)
			MsgServerLeave:
				var pid = socket.get_u64()
				call_deferred("_handleLeave", pid)
			MsgServerAttack:
				var pid = socket.get_u64()
				var target = socket.get_u64()
				call_deferred("_handleAttack", pid, target)
			MsgServerEquip:
				var pid = socket.get_u64()
				var item = socket.get_u8()
				call_deferred("_handleEquip", pid, item)
			MsgServerFish:
				var pid = socket.get_u64()
				call_deferred("_handleFish", pid)
			MsgServerTryFlag:
				var pid = socket.get_u64()
				var length = socket.get_u8()
				var flag = socket.get_string(length)
				call_deferred("_handleTryFlag", pid, flag)
			MsgServerChat:
				var pid = socket.get_u64()
				var whisper = socket.get_u64()
				var length = socket.get_u8()
				var msg = socket.get_string(length)
				call_deferred("_handleChat", pid, whisper, msg)
			MsgServerBld:
				var pid = socket.get_u64()
				var bldid = socket.get_u64()
				var x = socket.get_double()
				var y = socket.get_double()
				var z = socket.get_double()
				var r = socket.get_double()
				var length = socket.get_u8()
				var data = socket.get_data(length)[1]
				call_deferred("_handleBld", pid, bldid, x, y, z, r, data)
			MsgServerInteract:
				var pid = socket.get_u64()
				var tid = socket.get_u64()
				call_deferred("_handleInteract", pid, tid)
			MsgServerTogglePVP:
				var pid = socket.get_u64()
				call_deferred("_handlePVP", pid)
			_:
				prints("server error unknown paket: ", action)
		# prints("process", action, "in", OS.get_ticks_msec() - start1)
	# prints("overall processed ", updates, "in", OS.get_ticks_msec() - start)
	if updates > 0:
		call_deferred("_notifyFrame")

func _notifyFrame():
	if socket != null:
		# prints("serverframe")
		socket.put_u8(MsgServerFrame)
	else:
		prints("socket is null")

func unit_die(unit: Unit):
	socket.put_u8(MsgServerDie)
	socket.put_u64(unit.remote_id)
	if "player_" + str(unit.remote_id) in enemies:
		enemies.erase("player_" + str(unit.remote_id))

func unit_attack(unit: Unit, target: Unit):
	socket.put_u8(MsgServerAttack)
	socket.put_u64(unit.remote_id)
	if target == null:
		socket.put_u64(0)
	else:
		socket.put_u64(target.remote_id)

func unit_spawn(unit: NPC):
	enemies["player_" + str(unit.remote_id)] = unit
	socket.put_u8(MsgServerSpawn)
	socket.put_u64(unit.remote_id)
	socket.put_u64(unit.type)
	socket.put_double(unit.global_transform.origin.x)
	socket.put_double(unit.global_transform.origin.y)
	socket.put_double(unit.global_transform.origin.z)

func unit_target(unit: NPC):
	socket.put_u8(MsgServerTarget)
	socket.put_u64(unit.remote_id)
	socket.put_double(unit.target.x)
	socket.put_double(unit.target.y)
	socket.put_double(unit.target.z)

func unit_equip(unit: Unit, item: int):
	socket.put_u8(MsgServerEquip)
	socket.put_u64(unit.remote_id)
	socket.put_u8(item)

func unit_damage(unit: Unit, amount, from: Unit):
	socket.put_u8(MsgServerDamage)
	socket.put_u64(unit.remote_id)
	socket.put_double(amount)
	if from == null:
		socket.put_u64(0)
	else:
		socket.put_u64(from.remote_id)

func try_flag(node, flag):
	if !(flag in node.marker):
		prints(node, node.marker)
		return
		
	if flag != "FLAG_CONCH" && node.global_transform.origin.distance_to(flags[flag].global_transform.origin) > 3:
		prints("too far away", node, node.global_transform.origin, flags[flag].global_transform.origin, node.global_transform.origin.distance_to(flags[flag].global_transform.origin))
		return

	if OS.get_environment(flag) != "":
		flag = OS.get_environment(flag)
	else:
		flag = "tstlss{" + flag + "}"

	socket.put_u8(MsgServerFlag)
	socket.put_u64(node.remote_id)
	socket.put_u8(flag.length())
	socket.put_data(flag.to_ascii())

func solo(unit: Unit):
	socket.put_u8(MsgServerSolo)
	socket.put_u64(unit.remote_id)

func chat(from, whisper, msg):
	socket.put_u8(MsgServerChat)
	socket.put_u64(from)
	socket.put_u64(whisper)
	socket.put_u8(msg.length())
	socket.put_data(msg.to_ascii())

func marker(player, marker):
	player.marker[marker] = true
	socket.put_u8(MsgServerMark)
	socket.put_u64(player.remote_id)
	socket.put_u8(marker.length())
	socket.put_data(marker.to_ascii())

func spawn_chest(player, chest, pos, should_mark = true):
	if should_mark:
		marker(player, chest)
	socket.put_u8(MsgServerSpawnChest)
	socket.put_u64(player.remote_id)
	socket.put_u8(chest.length())
	socket.put_data(chest.to_ascii())
	socket.put_double(pos.x)
	socket.put_double(pos.y)
	socket.put_double(pos.z)

func conch(player, distance):
	socket.put_u8(MsgServerConch)
	socket.put_u64(player.remote_id)
	socket.put_double(distance)

func add_item(player, item):
	socket.put_u8(MsgServerItem)
	socket.put_u64(player.remote_id)
	socket.put_u64(item)

func player_buildings(player):
	var buildings = player.buildings
	var writer = StreamPeerBuffer.new()
	for building in buildings:
		writer.put_u64(building.id)
		writer.put_double(building.x)
		writer.put_double(building.y)
		writer.put_double(building.z)
		writer.put_double(building.r)
		var d = Hammer.data(player, building.id, building.data)
		writer.put_u8(d.size())
		writer.put_data(d)

	var data = writer.get_data_array()
	socket.put_u8(MsgServerBlds)
	socket.put_u64(player.remote_id)
	socket.put_u64(data.size())
	socket.put_data(data)

func change_area(player, area):
	socket.put_u8(MsgServerChangeArea)
	socket.put_u64(player.remote_id)
	socket.put_u8(area)
