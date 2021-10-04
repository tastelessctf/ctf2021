extends Control

func savePw(content):
	var file = File.new()
	file.open("user://login.dat", File.WRITE)
	file.store_string(content)
	file.close()

func loadPw():
	var file = File.new()
	file.open("user://login.dat", File.READ)
	var content = file.get_as_text()
	file.close()
	return content

func _ready():
	Ui.game_ui.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	$Server.add_item("127.0.0.1")
	$Server.add_item("eu1.ts.tasteless.eu")

	if !('local' in OS.get_cmdline_args()):
		$Server/HTTPRequest.request("http://ts.tasteless.eu:13380/server")

	Client.connect("account_chars", self, "_on_Client_account_chars")

	var data = loadPw()
	if data != null && data != "":
		var d = data.split(":")
		username.text = d[0]
		password.text = d[1]

onready var username = $Username/UsernameInput as LineEdit
onready var password = $Password/PasswordInput as LineEdit
onready var error = $Error as Label

func _on_Client_account_chars(_a, _b, _c):
	get_tree().change_scene("res://game/screen/character.tscn")

func _on_CreditsButton_pressed():
	get_tree().change_scene("res://game/screen/credits.tscn")

func _on_LoginButton_pressed():
	var err = Client.connect_to_server($Server.get_item_text($Server.get_selected_id()), 31337, username.text, password.text)
	if err == null:
		savePw(username.text + ":" + password.text)
	else:
		error.text = "Error logging in: " + str(err)

func _on_HTTPRequest_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	var response = parse_json(body.get_string_from_utf8())
	if response == null:
		return
	$Server.clear()
	for server in response['servers']:
		$Server.add_item(server)
	$Server.selected = randi() % $Server.get_item_count()
