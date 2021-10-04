extends Spatial

var island: Node
export var id: int
export var solo = false

func _ready():
	for c in get_children():
		if c.has_method("island_name"):
			island = c
			break
	assert(island != null, "no island child found")

func _on_Area_body_entered(body: Node):
	if Server.socket != null:
		Server.change_area(body, id)
		if solo:
			Server.solo(body)
	elif Client.player != null && body == Client.player:
		Ui.show_note("Entering\n" + island.island_name())

func _on_Area_body_exited(body: Node):
	if Server.socket != null && solo:
		Server.solo(body)
