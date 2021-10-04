extends "res://game/unit/unit.gd"

const Game = preload("res://game/game.gd")

var vel: Vector3 = Vector3.ZERO
var target: Vector3 = Vector3.ZERO
var speed = 0.5

func _init(type=Game.Unit.NPC, unit_name=">npc<", health = 100.0).(type, unit_name, health):
	connect("died", self, "_on_npc_died")

func _on_npc_died():
	target = Vector3.ZERO
	died = true

func _physics_process(delta):
	if health <= 0 || died:
		return

	vel.x = 0
	vel.z = 0

	var step_size = delta * speed * 100

	var target_anim = Character.Animation.IDLE

	target.y = global_transform.origin.y
	
	if target.x != 0 && target.z != 0 && target.distance_to(global_transform.origin) > 0.1:
		var direction = target - global_transform.origin
		# direction.y = 0

		# if step_size > direction.length():
		# 	step_size = direction.length()

		direction = direction.normalized() * step_size
		
		var look_at_point = global_transform.origin + direction.normalized()
		look_at(look_at_point, Vector3.UP)

		vel.x = direction.x
		vel.z = direction.z
		target_anim = Character.Animation.WALKING

	vel.y += -9.8 * delta
	vel = move_and_slide(vel, Vector3.UP, true)
	if !is_on_floor():
		target_anim = Character.Animation.FALLING
	character.motion(target_anim)
