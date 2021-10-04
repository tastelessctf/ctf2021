extends "res://game/unit/enemy.gd"

const Player = preload("res://game/player/player.gd")

enum State {
	IDLE
	CHASE
	ATTACK
	DEAD
}

const PATH_UPDATE_TIME = 1000

var _state = State.IDLE
var _target: Spatial = null
var _nearby: Array = []
var attackRate = 1;  # try to attack once per second
var lastAttackTime = 0;
var path_updated = 0;

onready var sense = $Sense as Area

func _init(type=Game.Unit.SKELETON, unit_name="Pirate Skeleton", health = 50.0).(type, unit_name, health):
	pass

func _ready():
	emit_signal("equipped", Items.IDs.CUTLASS1)

	if Server.socket == null:
		return

	sense.connect("body_entered", self, "_on_Sense_body_entered")
	sense.connect("body_exited", self, "_on_Sense_body_exited")
	yield(get_tree(), "idle_frame")
	weapon = Items.by_id(Items.IDs.CUTLASS1)

func die():
	.die()
	_state = State.DEAD
	_target = null
	vel = Vector3.ZERO

func damage(damage, from=null):
	.damage(damage, from)
	if Server.socket != null and _state != State.DEAD:
		if from != null:
			_state = State.CHASE
			_target = from
			# notify friends about attack
			for i in range(_nearby.size()):
				if _nearby[i] != null && _nearby[i] is get_script():
					_nearby[i].help_me(from)

func help_me(from):
	if _state == State.IDLE:
		_state = State.CHASE
		_target = from

func _process(_delta):
	if _state == State.DEAD:
		return

	if Server.socket != null:
		if spawn.distance_to(global_transform.origin) > 50:
			target = spawn
			Server.unit_target(self)
		match _state:
			State.IDLE:
				for i in range(_nearby.size()):
					# prints(_nearby[i], _nearby[i].get_script())
					if _nearby[i] == null:
						_nearby.remove(i)
						return
					if _nearby[i] is Player and _nearby[i].health > 0:
						prints("starting to chase", _nearby[i])
						_state = State.CHASE
						_target = _nearby[i]
						target = _nearby[i].global_transform.origin
						Server.unit_target(self)
						return
				if target.distance_to(global_transform.origin) < 0.1:
					target = spawn + Vector3(rand_range(-10, 10), 0, rand_range(-10, 10))
					Server.unit_target(self)
			State.CHASE:
				if !_target || _target.health <= 0:
					_state = State.IDLE
					_target == null
					# set_path([])
					# target = global_transform.origin
					return
				var distance = global_transform.origin.distance_to(_target.global_transform.origin)
				if distance > 30:
					_target = null
					_state = State.IDLE
					# set_path([])
					# target = global_transform.origin
				elif distance <= weapon.distance():
					if OS.get_ticks_msec() - lastAttackTime < attackRate * 1000:
						return
					lastAttackTime = OS.get_ticks_msec()
					attack(_target)
				else:
					if OS.get_ticks_msec() > (path_updated + PATH_UPDATE_TIME):
						path_updated = OS.get_ticks_msec()
						target = _target.global_transform.origin
						Server.unit_target(self)

func _on_Sense_body_entered(body: Node):
	# prints("sense entered", body)
	_nearby.append(body)

func _on_Sense_body_exited(body: Node):
	# prints("sense exited", body)
	_nearby.erase(body)
	if _target == body:
		_target = null
		_state = State.IDLE
