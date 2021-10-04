class_name UnitSpawner
extends Position3D

const Enemy = preload("res://game/unit/enemy.gd")
const Game = preload("res://game/game.gd")

export(int, 0, 20) var num_units = 5
export(PackedScene) var unit_scene: PackedScene
export(int) var respawn_intervall = 5

func _ready():
	Server.connect("connecting", self, "_on_Server_connecting")
	Server.connect("connected", self, "_on_Server_connected")

func _on_Server_connecting():
	for child in get_children():
		child.queue_free()

func _on_Server_connected():
	var timer = Timer.new()
	add_child(timer)
	timer.connect("timeout", self, "_on_timeout")
	timer.start(respawn_intervall)

func _on_timeout():
	if Server.socket == null:
		return

	if get_children().size() < (num_units + 1):
		spawn_unit()

# func _process(_delta):
# 	if Server.socket == null:
# 		return

# 	for unit in alive:
# 		if unit.target.distance_to(unit.global_transform.origin) < 0.1:
# 			unit.target = global_transform.origin + Vector3(rand_range(-5, 5), 0, rand_range(-5, 5))
# 			Server.unit_target(unit)

func spawn_unit():
	var unit = unit_scene.instance() as Enemy
	add_child(unit)
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	unit.remote_id = rng.randi_range(0, 12312312)
	
	unit.global_transform.origin = global_transform.origin + Vector3(rand_range(-5, 5), 0, rand_range(-5, 5))
	unit.target = unit.global_transform.origin
	unit.spawn = global_transform.origin

	Server.unit_spawn(unit)
