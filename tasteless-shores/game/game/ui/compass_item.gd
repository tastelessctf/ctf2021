extends Label

export(int) var deg = 0;

func _process(_delta):
	var cam = get_viewport().get_camera()
	if cam == null:
		return
	var transform = cam.get_camera_transform()
	var y = rad2deg(transform.basis.get_euler().y) * -1
	var target_x = fposmod(180 - y + deg, -360) + 180
	# print(y, target_x)
	if target_x < -120 or target_x > 120:
		visible = false
		return

	visible = true
	rect_position.x = target_x * 2
