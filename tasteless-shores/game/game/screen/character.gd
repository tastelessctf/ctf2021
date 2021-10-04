extends Control

var shade = 0 setget set_shade
var color = 0 setget set_color
var chars = 0 setget set_char

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# yield(get_tree(), "idle_frame")

	# var rng = RandomNumberGenerator.new()
	# rng.randomize()

	# shade = rng.randi_range(0, 2)
	# color = rng.randi_range(0, 3)
	# chars = rng.randi_range(0, 2)
	# update_char()

	yield(get_tree(), "idle_frame")

	# if OS.has_feature('editor'):
	# 	_on_ButtonEnter_pressed()

	Client.connect("account_chars", self, "_on_account_chars")
	_on_account_chars(Client.pshade, Client.pcolor, Client.pchars)

func _on_account_chars(pshade, pcolor, pchars):
	shade = pshade
	color = pcolor
	chars = pchars
	update_char()

func update_char():
	$Spatial/Character.setchar(shade, color, chars)

func set_shade(new_shade):
	shade = new_shade
	update_char()

func set_color(new_color):
	color = new_color
	update_char()

func set_char(new_char):
	chars = new_char
	update_char()

func _on_Unknown_pressed():
	set_char(0)

func _on_Female_pressed():
	set_char(1)

func _on_Male_pressed():
	set_char(2)

func _on_Color1_pressed():
	set_color(0)

func _on_Color2_pressed():
	set_color(1)

func _on_Color3_pressed():
	set_color(2)

func _on_Color4_pressed():
	set_color(3)

func _on_ShadeA_pressed():
	set_shade(0)
	
func _on_ShadeB_pressed():
	set_shade(1)

func _on_ShadeC_pressed():
	set_shade(2)

func _on_ButtonEnter_pressed():
	Client.join_local_player(chars, color, shade)
	get_tree().change_scene("res://island/world.tscn")

func _on_Timer_timeout():
	Client.ping()
