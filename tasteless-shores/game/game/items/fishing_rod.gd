extends Spatial

var cast = 0.0
var attackRate = 2.0;
var lastAttackTime = 0

func name() -> String:
	return "Fishing Rod"

func use(collider, from):
	if OS.get_ticks_msec() - lastAttackTime < attackRate * 1000:
		return false
	lastAttackTime = OS.get_ticks_msec()

	return true

func _on_attacked(collider, from):
	if Client != null && from == Client.player:
		cast = attackRate
		Client.player_controller.paused = true

func _process(delta):
	if cast <= 0:
		return
	cast -= delta
	if cast <= 0:
		fish()

func fish():
	Client.player_controller.paused = false
	for area in $FishArea.get_overlapping_areas():
		if area.has_method("lake'o'despair") or true:
			Ui.show_note("Now I am a true fisher")
			Client.start_fish(area.call("lake'o'despair"))
		else:
			Ui.show_note("Only small fish here...")
		return
