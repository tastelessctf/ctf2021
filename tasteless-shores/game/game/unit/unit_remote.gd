extends Spatial

const Unit = preload("res://game/unit/unit.gd")

onready var target_transform = global_transform.origin
onready var target_basis = global_transform.basis
onready var parent = get_parent()

const irate = .2

func _ready():
	# find parent
	while !parent is Unit:
		parent = parent.get_parent()

var last_update = 0
func update():
	last_update = OS.get_ticks_msec()
	parent.show()

func _process(_delta):
	if parent.health <= 0:
		return

	if parent.global_transform.origin == Vector3.ZERO:
		parent.global_transform.origin = target_transform

	var to = parent.global_transform.origin.linear_interpolate(target_transform, irate)
	if abs(parent.global_transform.origin.y - to.y) > 0.05:
		parent.character.motion(Character.Animation.FALLING)
	elif parent.global_transform.origin.distance_to(to) > 0.05:
		parent.character.motion(Character.Animation.WALKING)
	else:
		parent.character.motion(Character.Animation.IDLE)

	parent.global_transform.origin = to
	parent.global_transform.basis = parent.global_transform.basis.slerp(target_basis, irate)

	if parent.global_transform.origin.distance_to(Client.player.global_transform.origin) > 30.0 || OS.get_ticks_msec() > last_update+5000:
		parent.hide()
