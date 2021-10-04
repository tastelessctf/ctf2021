extends Control

const Unit = preload("res://game/unit/unit.gd")

var items = []

class WLItem:
	var label: Label
	var tracked

func add(label: String, tracked: Unit):
	var item = WLItem.new()
	item.tracked = tracked

	item.label = Label.new()
	item.label.text = label
	item.label.valign = Label.VALIGN_CENTER
	item.label.align = Label.ALIGN_CENTER
	item.label.grow_horizontal = Label.GROW_DIRECTION_BOTH
	item.label.grow_vertical = Label.GROW_DIRECTION_BEGIN
	add_child(item.label)
	items.append(item)

func remove(tracked: Spatial):
	for item in items:
		if item.tracked == tracked:
			item.label.queue_free()
			items.erase(item)
			return

func _process(_delta):
	var cam = get_viewport().get_camera()
	for item in items:
		var tpos = item.tracked.global_transform.translated(Vector3.UP * item.tracked.height).origin
		if cam.is_position_behind(tpos):
			item.label.hide()
		else:
			item.label.show()
			var pos = cam.unproject_position(tpos)
			item.label.rect_position = pos - Vector2(item.label.rect_size.x / 2, 20)
