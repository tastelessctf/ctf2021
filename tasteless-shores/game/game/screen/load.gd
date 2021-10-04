extends Control

func _ready():
	yield(get_tree(), "idle_frame")
	
	if ('server' in OS.get_cmdline_args()):
		Server.start()
		get_tree().change_scene("res://island/world.tscn")
		return

	get_tree().change_scene("res://game/screen/login.tscn")
