extends Spatial

func name() -> String:
	return "Hammer"

var item = 0
const items = [preload("res://island/home/obj/cannon.tscn"), preload("res://island/home/obj/stack.tscn"), preload("res://island/home/obj/barrel.tscn"), preload("res://island/home/obj/balls.tscn")]

var active = false

static func data(player, bid, data):
	var inst = items[bid].instance()
	if inst.has_method("data"):
		return inst.data(player, data)
	else:
		return "".to_ascii()

func _process(_delta):
	if !active:
		return
	if Input.is_action_just_pressed("secondary"):
		item = (item + 1) % items.size()
		pcupdate()

func pcupdate():
	if !active:
		return
	for child in Client.player_controller.placePivot.get_children():
		child.queue_free()
	var current = items[item].instance()
	# current.collision_layer = 0
	Client.player_controller.placePivot.add_child(current)

func _on_attacked(collider, from):
	if !active:
		return
	if Client != null && from == Client.player:
		var pos = Client.player_controller.placeRayCast.get_collision_point()
		if pos != Vector3.ZERO:
			Client.place_building(item, pos.x, pos.y, pos.z, Client.player.global_transform.basis.get_euler().y)

func use(collider, from):
	return true

func _ready():
	if !active:
		return
	if Client != null:
		Client.player_controller.enable_placement()
		pcupdate()

func _exit_tree():
	if !active:
		return
	if Client != null && Client.player_controller != null:
		Client.player_controller.disable_placement()
