extends "res://game/items/weapon.gd"

var _name = "melee-weapon"
var damage = []

func _init(itemid: int, name: String, model: String, idamage = [0, 0]).(itemid, null, 2.0):
	_name = name
	_model = MeshInstance.new()
	_model.mesh = load("res://assets/weapons/SM_Wep_" + model + ".obj")
	_model.set_surface_material(0, load("res://assets/materials/texture_01_a.tres"))
	_model.rotation_degrees = Vector3(60, -180, 90)
	id = itemid
	damage = idamage
	lastAttackTime = OS.get_ticks_msec()
	_icon = load("res://assets/weapons/" + model + ".png")

func distance() -> float:
	return 2.0

var attackRate = 2.0;
var lastAttackTime = 0;

func attack(collider, from) -> bool:
	if OS.get_ticks_msec() - lastAttackTime < attackRate * 1000:
		return false
	lastAttackTime = OS.get_ticks_msec()

	if collider != null:
		collider.damage(rand_range(damage[0], damage[1]), from)
	return true

func name() -> String:
	return _name
