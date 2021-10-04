extends Control

onready var health_bar = $HealthBar as ProgressBar

func _process(_delta):
	if Client.player == null:
		return
	
	health_bar.value = Client.player.health
