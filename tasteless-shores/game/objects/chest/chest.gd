extends StaticBody

export var flag: String
export var hidden: bool

func _ready():
	if Client.socket != null && hidden:
		queue_free()
	Server.connect("connected", self, "_on_Server_connected")

func _on_Server_connected():
	if Server.socket != null:
		Server.flags[flag] = self

func interact():
	Ui.show_note("looks nice and shiny inside")
	Client.try_flag(flag)
