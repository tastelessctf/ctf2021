extends SpringArm

var lookSensitivity : float = 15.0
var minLookAngle : float = -85.0
var maxLookAngle : float = 85.0

var mouseDelta : Vector2 = Vector2()

onready var parent = get_parent()

func _unhandled_input(event):
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		mouseDelta = event.relative

func _process(delta):
	var rot = Vector3(mouseDelta.y, mouseDelta.x, 0) * lookSensitivity * delta
	
	parent.player.get_node("Look").rotation_degrees.x -= rot.x
	parent.player.get_node("Look").rotation_degrees.x = clamp(parent.player.get_node("Look").rotation_degrees.x, minLookAngle, maxLookAngle)
	
	parent.player.rotation_degrees.y -= rot.y
	# parent.player.get_node("Look").rotation_degrees.x = rotation_degrees.x

	mouseDelta = Vector2()
