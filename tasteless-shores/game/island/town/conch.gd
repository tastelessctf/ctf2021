extends Spatial

var attackRate = 2.0;
var lastAttackTime = 0

var rabbit: Vector3

func name() -> String:
	return "Conch"

func _init():
	rabbit = Vector3(rand_range(-100, 100), rand_range(-100, 100), rand_range(-100, 100))
	# rabbit = Vector3(1, 3.2, 1)

const rabbit_distance = 0.1

func use(collider, from):
	if OS.get_ticks_msec() - lastAttackTime < attackRate * 1000:
		return false
	lastAttackTime = OS.get_ticks_msec()

	Server.conch(from, from.global_transform.origin.distance_to(rabbit))
	if from.global_transform.origin.distance_to(rabbit) < rabbit_distance:
		Server.spawn_chest(from, "FLAG_CONCH", rabbit)

	return true

static func conch(distance):
	prints("conch", distance)
	Ui.show_note("Oh, Magic Conch Shell, where is the kelp forest?")
	yield(Ui.center_notification.timer, "timeout")
	if distance > 50:
		Ui.show_note("... very far ...")
	elif distance > 1:
		Ui.show_note("... not so far ...")
	else:
		Ui.show_note("... totally totally not far ...")
