extends Control

onready var textEdit = $TextEdit as TextEdit
onready var text = $RichTextLabel as RichTextLabel

func _ready():
	Client.connect("chatmsg", self, "_on_Client_chat")

func _unhandled_input(event):
	if event.is_action_pressed("chat"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		textEdit.grab_focus()

func _on_TextEdit_gui_input(event: InputEvent):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_ESCAPE:
			textEdit.text = ""
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			textEdit.release_focus()
		elif event.pressed and event.scancode == KEY_ENTER:
			var t = textEdit.text.strip_edges()
			if t != "":
				Client.chat(0, t)
				text.newline()
				text.append_bbcode("[color=aqua]{0}: {1}[/color]".format([Client.player_name, t]))
			textEdit.text = ""
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			textEdit.release_focus()

func _on_Client_chat(from, msg):
	text.newline()
	text.append_bbcode("{0}: {1}".format([from, msg]))
