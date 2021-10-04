extends Spatial

func _ready():
	if Server.socket != null:
		queue_free()
