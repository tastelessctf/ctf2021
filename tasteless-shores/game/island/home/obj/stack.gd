extends StaticBody

func data(player, data):
	prints("stack data", player, data)
	var msg = "Stack owned by " + player.unit_name + ": "
	var res = msg.to_ascii()
	res.append_array(data)
	return res

func setdata(data):
	var msg = data.get_string_from_ascii()
	# todo: show owner info
