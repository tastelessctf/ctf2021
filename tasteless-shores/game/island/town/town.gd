extends Spatial


func island_name():
	return "Ring 0"

func _ready():
	$Water.hide()

func _on_Area_body_entered(body: Node):
	if Server.socket != null:
		Server.solo(body)

func _on_Area_body_exited(body: Node):
	if Server.socket != null:
		Server.solo(body)
