extends Control

class MinimapSprite extends Sprite:
	var tracked_id
	var x
	var y

func _process(delta):
	if Client.player == null:
		return

	for child in $TextureRect.get_children():
		var pos = Vector2(Client.player.global_transform.origin.x - child.x, Client.player.global_transform.origin.z - child.y)
		child.position = pos.rotated((Client.player.global_transform.basis.get_euler().y) + deg2rad(180)) + Vector2(75, 75)

func add_track(id, x, y, icon):
	var sprite = MinimapSprite.new()
	sprite.texture = load("res://assets/textures/kenney/cartographypack/PNG/Default/" + icon + ".png")
	sprite.tracked_id = id
	sprite.x = x
	sprite.y = y
	sprite.scale = Vector2(.5, .5)
	$TextureRect.add_child(sprite)

func remove_track(id):
	for child in $TextureRect.get_children():
		if child.tracked_id == id:
			child.queue_free()
			return
