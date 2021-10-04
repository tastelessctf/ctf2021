extends MeshInstance

signal water_entered
signal water_exited

func _ready():
	# connect("water_entered", tracked, "_on_Water_water_entered")
	# connect("water_exited", tracked, "_on_Water_water_exited")
	pass

func _on_WaterArea_body_entered(body: Node):
	# emit_signal("water_entered")
	# print("water entered", body)
	if body.has_method("_on_Water_water_entered"):
		body._on_Water_water_entered()

func _on_WaterArea_body_exited(body: Node):
	# emit_signal("water_exited")
	# print("water exited", body)
	if body.has_method("_on_Water_water_exited"):
		body._on_Water_water_exited()
