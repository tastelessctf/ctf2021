extends Node

const Player = preload("res://game/player/player.gd")
const UnitRemote = preload("res://game/unit/unit_remote.gd")
const Game = preload("res://game/game.gd")
const Unit = preload("res://game/unit/unit.gd")
const NPC = preload("res://game/unit/npc.gd")

const PlayerScene = preload("res://game/player/player.tscn")
const PlayerControllerScene = preload("res://game/player/player_controller.tscn")
const SkeletonScene = preload("res://game/unit/skeleton.tscn")

const Conch = preload("res://island/town/conch.gd")
const Hammer = preload("res://island/home/hammer.gd")

const ChestScene = preload("res://objects/chest/chest.tscn")

var socket: StreamPeerTCP
var player: Player
var player_controller
var player_name = "someone"
var id = 0

signal send_join()
signal account_login(player, team)
signal account_chars(shade, color, chars)
signal chatmsg(from, msg)

const MsgClientAuth         = 0x00
const MsgClientJoin         = 0x22
const MsgClientUpdatePlayer = 0x45
const MsgClientAttack       = 0xfe
const MsgClientEquip        = 0x91
const MsgClientFish         = 0x96
const MsgClientTryFlag      = 0x76
const MsgClientChat         = 0x50
const MsgClientInteract     = 0x10
const MsgClientBldPlace     = 0x60
const MsgClientTogglePVP    = 0x77
const MsgClientPing         = 0x44

func connect_to_server(host, port, name, pw):
	player_name = name

	for child in get_children():
		child.queue_free()

	if socket != null:
		socket.disconnect_from_host()

	socket = StreamPeerTCP.new()
	if socket.connect_to_host(host, port) != OK:
		return "unable to connect to server"
	
	prints("connected, logging in")

	while true:
		match socket.get_status():
			StreamPeerTCP.STATUS_CONNECTED:
				break
			StreamPeerTCP.STATUS_CONNECTING:
				pass
			StreamPeerTCP.STATUS_ERROR:
				socket = null
				return "unable to connect"

	socket.set_no_delay(true)

	socket.put_data("pirates!".to_ascii())

	socket.put_u8(MsgClientAuth)
	socket.put_u8(name.length())
	socket.put_data(name.to_ascii())
	socket.put_u8(pw.length())
	socket.put_data(pw.to_ascii())

	for child in get_children():
		child.queue_free()
	if remote_thread != null:
		ending = true
		remote_thread.wait_to_finish()
		ending = false
	remote_thread = Thread.new()
	remote_thread.start(self, "_remote_thread")

	return null

var chars
var color
var shade

func join_local_player(chars, color, shade):
	for child in get_children():
		child.queue_free()

	emit_signal("send_join")
	self.chars = chars
	self.color = color
	self.shade = shade
	socket.put_u8(MsgClientJoin)
	socket.put_u8(chars + (color << 2) + (shade << 4))

var should_update = false
var last_update = Vector3.ZERO
var last_rot = 0.0
var pshade = 0
var pcolor = 0
var pchars = 0
var remote_thread
var ending = false

func _disconnect():
	player = null
	player_controller = null

	for child in get_children():
		child.queue_free()
	if socket != null:
		socket.disconnect_from_host()
	if !ending:
		get_tree().change_scene("res://game/screen/login.tscn")

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
			return
	
		if socket.get_status() == StreamPeerTCP.STATUS_ERROR || socket.get_status() == StreamPeerTCP.STATUS_NONE:
			call_deferred("_disconnect")
			return
	
		if socket.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			continue

		_threadProcess(0)

func _loggedIn(id, x, y, z, name, team):
	player = null
	player_controller = null
	
	for child in get_children():
		child.queue_free()
	player = PlayerScene.instance()
	player.name = "player_" + str(id)
	add_child(player)
	player_controller = PlayerControllerScene.instance()
	player.get_node("Look").add_child(player_controller)
	player.global_transform.origin.x = x
	player.global_transform.origin.y = y
	player.global_transform.origin.z = z
	player.get_node("Character").setchar(shade, color, chars)
	player.collision_layer = 2 | 16
	emit_signal("account_login", name, team)

func _updatePlayer(pid, x, y, z, r, health, weapon):
	if !has_node("player_" + str(pid)):
		prints("client, serverupdateplayer, error, unknown player update", pid)
		return
	var node = get_node("player_" + str(pid))
	node.health = health
	if pid == id:
		return
	if node.weapon == null || node.weapon.id != weapon:
		node.emit_signal("equipped", weapon)
	node.get_node("remote").target_transform = Vector3(x, y, z)
	node.get_node("remote").target_basis = Basis(Vector3.UP, r)
	node.get_node("remote").update()

func _updatePlayers(players):
	for p in players:
		if !has_node("player_" + str(p.pid)):
			prints("client, serverupdateplayer, error, unknown player update", p.pid)
			return
		var node = get_node("player_" + str(p.pid))
		node.health = p.health
		if p.pid == id:
			return
		if node.weapon == null || node.weapon.id != p.weapon:
			node.emit_signal("equipped", p.weapon)
		node.get_node("remote").target_transform = Vector3(p.x, p.y, p.z)
		node.get_node("remote").target_basis = Basis(Vector3.UP, p.r)
		node.get_node("remote").update()

func _join(pid, name, team, pchars, x, y, z, markers):
	if pid == id:
		for marker in markers:
			player.marker[marker] = true
		return
	if has_node("player_" + str(pid)):
		get_node("player_" + str(pid)).queue_free()
	var pi = PlayerScene.instance()
	pi.name = "player_" + str(pid)
	pi.remote_id = pid
	var r = UnitRemote.new()
	r.name = "remote"
	pi.add_child(r)
	add_child(pi)
	pi.global_transform.origin = Vector3(x, y, z)
	var pshade = (pchars >> 4) & 0x03
	var pcolor = (pchars >> 2) & 0x03
	pchars = pchars & 0x03
	pi.unit_name = name
	pi.unit_team = team
	pi.get_node("Character").setchar(pshade, pcolor, pchars)
	for marker in markers:
		pi.marker[marker] = true

func _leave(pid):
	if !has_node("player_" + str(pid)):
		prints("client error, unknown player leave", pid)
		return
	var node = get_node("player_" + str(pid))
	node.queue_free()

func _attack(pid, target):
	if !has_node("player_" + str(pid)):
		prints("client error, unknown player attack", pid)
		return
	var node = get_node("player_" + str(pid))
	node.emit_signal("attacked", target)

func _equip(pid, item):
	if !has_node("player_" + str(pid)):
		prints("client error, unknown player equip", pid)
		return
	var node = get_node("player_" + str(pid))
	node.emit_signal("equipped", item)

func _die(pid):
	if !has_node("player_" + str(pid)):
		prints("client error, unknown player die", pid)
		return
	var node = get_node("player_" + str(pid))
	node.emit_signal("died")

func _damage(pid, amount, from):
	if !has_node("player_" + str(pid)):
		prints("client error, unknown player damage", pid)
		return
	var node = get_node("player_" + str(pid))
	node.emit_signal("damaged", amount, from)

func _item(pid, item):
	player.add_item(item, 1)

func _flag(pid, flag):
	Ui.show_note("Flag: "+ flag)
	emit_signal("chatmsg", "FLAG", "[color=silver]" + flag + "[/color]")

func _chat(pid, whisper, msg):
	if pid == id:
		return
	msg = msg.replace("[", "").replace("]", "")
	if whisper != 0:
		msg = "[color=purple]" + msg + "[/color]"
	if pid == 0:
		emit_signal("chatmsg", "Server", "[color=red]" + msg + "[/color]")
	elif has_node("player_" + str(pid)):
		var name = get_node("player_" + str(pid)).unit_name
		emit_signal("chatmsg", name, msg)

func _spawn(pid, type, x, y, z):
	if has_node("player_" + str(pid)):
		get_node("player_" + str(pid)).queue_free()
		yield(get_tree(), "idle_frame")
	var s = SkeletonScene.instance()
	s.name = "player_" + str(pid)
	add_child(s)
	s.remote_id = pid
	s.target = Vector3(x, y, z)
	s.global_transform.origin = Vector3(x, y, z)

func _target(pid, x, y, z):
	if has_node("player_" + str(pid)):
		get_node("player_" + str(pid)).target = Vector3(x, y, z)

func _mark(pid, mark):
	if has_node("player_" + str(pid)):
		get_node("player_" + str(pid)).marker[mark] = true

func _spawnChest(pid, chest, x, y, z):
	if !has_node("chest_" + chest):
		var cs = ChestScene.instance()
		cs.name = "chest_" + chest
		cs.flag = chest
		cs.hidden = false
		add_child(cs)
		cs.global_transform.origin = Vector3(x, y, z)
		player.marker[chest] = true

func _conch(pid, distance):
	Conch.conch(distance)

func _buildings(_pid, data):
	if has_node("buildings"):
		get_node("buildings").queue_free()
	yield(get_tree(), "idle_frame")
	var b = Spatial.new()
	add_child(b)
	var reader = StreamPeerBuffer.new()
	reader.set_data_array(data)
	while reader.get_available_bytes() > 0:
		var bldid = reader.get_u64()
		var x = reader.get_double()
		var y = reader.get_double()
		var z = reader.get_double()
		var r = reader.get_double()
		var l = reader.get_u8()
		var bd = reader.get_string(l)
		var building = Hammer.items[bldid].instance()
		b.add_child(building)
		building.global_transform.origin = Vector3(x, y, z)
		building.global_transform.basis = Basis(Vector3.UP, r)

func _account(chars):
	pshade = (chars >> 4) & 0x03
	pcolor = (chars >> 2) & 0x03
	pchars = chars & 0x03
	emit_signal("account_chars", pshade, pcolor, pchars)

func _threadProcess(_delta):
	var packets = 0
	while socket.get_available_bytes() > 0:
		packets += 1

		# should_update = true
		var action = socket.get_u8()

		match action:
			Server.MsgServerLoggedIn:
				id = socket.get_u64()
				var x = socket.get_double()
				var y = socket.get_double()
				var z = socket.get_double()
				var length = socket.get_u8()
				var name = socket.get_string(length)
				length = socket.get_u8()
				var team = socket.get_string(length)
				call_deferred("_loggedIn", id, x, y, z, name, team)
				should_update = true

			Server.MsgServerUpdatePlayer:
				var pid = socket.get_u64()
				var x = socket.get_double()
				var y = socket.get_double()
				var z = socket.get_double()
				var r = socket.get_double()
				var health = socket.get_double()
				var item = socket.get_u8()
				call_deferred("_updatePlayer", pid, x, y, z, r, health, item)
				should_update = true

			Server.MsgServerUpdatePlayers:
				var length = socket.get_u8()
				var players = []
				for i in range(length):
					var pid = socket.get_u64()
					var x = socket.get_double()
					var y = socket.get_double()
					var z = socket.get_double()
					var r = socket.get_double()
					var health = socket.get_double()
					var item = socket.get_u8()
					players.append({"pid": pid, "x": x, "y": y, "z": z, "r": r, "health": health, "weapon": item})
				call_deferred("_updatePlayers", players)
				should_update = true

			Server.MsgServerJoin:
				var pid = socket.get_u64()
				var length = socket.get_u8()
				var name = socket.get_string(length)
				length = socket.get_u8()
				var team = socket.get_string(length)
				var pchars = socket.get_u8()
				var x = socket.get_double()
				var y = socket.get_double()
				var z = socket.get_double()
				var sl = socket.get_u8()
				var markers = []
				for i in range(0, sl):
					length = socket.get_u8()
					var marker = socket.get_string(length)
					markers.append(marker)
				call_deferred("_join", pid, name, team, pchars, x, y, z, markers)
				should_update = true

			Server.MsgServerLeave:
				var pid = socket.get_u64()
				call_deferred("_leave", pid)

			Server.MsgServerAttack:
				var pid = socket.get_u64()
				var target = socket.get_u64()
				call_deferred("_attack", pid, target)
				
			Server.MsgServerEquip:
				var pid = socket.get_u64()
				var item = socket.get_u8()
				call_deferred("_equip", pid, item)
				
			Server.MsgServerDie:
				var pid = socket.get_u64()
				call_deferred("_die", pid)
				
			Server.MsgServerDamage:
				var pid = socket.get_u64()
				var amount = socket.get_double()
				var from = socket.get_u64()
				call_deferred("_damage", pid, amount, from)
				
			Server.MsgServerItem:
				var pid = socket.get_u64()
				var item = socket.get_u64()
				call_deferred("_item", pid, item)
				
			Server.MsgServerFlag:
				var pid = socket.get_u64()
				var length = socket.get_u8()
				var flag = socket.get_string(length)
				call_deferred("_flag", pid, flag)
				
			Server.MsgServerChat:
				var pid = socket.get_u64()
				var whisper = socket.get_u64()
				var length = socket.get_u8()
				var msg = socket.get_string(length)
				call_deferred("_chat", pid, whisper, msg)
				
			Server.MsgServerSpawn:
				var pid = socket.get_u64()
				var type = socket.get_u64()
				var x = socket.get_double()
				var y = socket.get_double()
				var z = socket.get_double()
				call_deferred("_spawn", pid, type, x, y, z)
				
			Server.MsgServerTarget:
				var pid = socket.get_u64()
				var x = socket.get_double()
				var y = socket.get_double()
				var z = socket.get_double()
				call_deferred("_target", pid, x, y, z)
				
			Server.MsgServerSpawnChest:
				var pid = socket.get_u64()
				var length = socket.get_u8()
				var chest = socket.get_string(length)
				var x = socket.get_double()
				var y = socket.get_double()
				var z = socket.get_double()
				call_deferred("_spawnChest", pid, chest, x, y, z)

			Server.MsgServerMark:
				var pid = socket.get_u64()
				var length = socket.get_u8()
				var marker = socket.get_string(length)
				call_deferred("_mark", pid, marker)
				
			Server.MsgServerConch:
				var pid = socket.get_u64()
				var distance = socket.get_double()
				call_deferred("_conch", pid, distance)

			Server.MsgServerBlds:
				var pid = socket.get_u64()
				var length = socket.get_u64()
				var data = socket.get_data(length)[1]
				call_deferred("_buildings", pid, data)

			Server.MsgServerAccount:
				var chars = socket.get_u8()
				call_deferred("_account", chars)
				
			_:
				prints("unknown command", action)

var last_update_ts = 0
func _process(_delta):
	if player == null:
		return

	if should_update || (last_update_ts + 10000) < OS.get_ticks_msec():
		var rot = player.global_transform.basis.get_euler().y
		# prints("send update")
		should_update = false
		last_update = player.global_transform.origin
		last_rot = rot
		socket.put_u8(MsgClientUpdatePlayer)
		socket.put_double(player.global_transform.origin.x)
		socket.put_double(player.global_transform.origin.y)
		socket.put_double(player.global_transform.origin.z)
		socket.put_double(rot)
		last_update_ts = OS.get_ticks_msec()

func start_equip(item):
	socket.put_u8(MsgClientEquip)
	socket.put_u8(item)
	
func start_attack(target):
	socket.put_u8(MsgClientAttack)
	socket.put_u64(target)

func start_fish(target):
	socket.put_u8(MsgClientFish)

func try_flag(flag):
	socket.put_u8(MsgClientTryFlag)
	socket.put_u8(flag.length())
	socket.put_data(flag.to_ascii())

func chat(whisper, msg):
	socket.put_u8(MsgClientChat)
	socket.put_u64(whisper)
	socket.put_u8(msg.length())
	socket.put_data(msg.to_ascii())

func interact(id):
	socket.put_u8(MsgClientInteract)
	socket.put_u64(id)

func start_respawn():
	join_local_player(chars, color, shade)

func place_building(bldid, x, y, z, r):
	socket.put_u8(MsgClientBldPlace)
	socket.put_u64(bldid)
	socket.put_double(x)
	socket.put_double(y)
	socket.put_double(z)
	socket.put_double(r)
	socket.put_u8(0)

func toggle_pvp():
	socket.put_u8(MsgClientTogglePVP)

func ping():
	socket.put_u8(MsgClientPing)
