extends "res://game/items/weapon.gd"

var _name = "range-weapon"
var damage

var attackRate = 2.5
var lastAttackTime = 0

const m = {
	"Axe_01": preload("res://assets/weapons/SM_Wep_Axe_01.obj"),
	"Cutlass_01": preload("res://assets/weapons/SM_Wep_Cutlass_01.obj"),
	"Sabre_01": preload("res://assets/weapons/SM_Wep_Sabre_01.obj"),
	"Pistol_01": preload("res://assets/weapons/SM_Wep_Pistol_01.obj"),
	"MusketPistol_01": preload("res://assets/weapons/SM_Wep_MusketPistol_01.obj"),
}

const _asdicon = {
	"Axe_01": preload("res://assets/weapons/Axe_01.png"),
	"Cutlass_01": preload("res://assets/weapons/Cutlass_01.png"),
	"Sabre_01": preload("res://assets/weapons/Sabre_01.png"),
	"Pistol_01": preload("res://assets/weapons/Pistol_01.png"),
	"MusketPistol_01": preload("res://assets/weapons/MusketPistol_01.png"),
}

func _init(itemid: int, name: String, model: String, idamage = [0, 0]).(itemid, null, 50.0):
	_name = name
	_model = MeshInstance.new()
	_model.mesh = m[model]
	_model.set_surface_material(0, preload("res://assets/materials/texture_01_a.tres"))
	_model.rotation_degrees = Vector3(60, 60, -30)
	id = itemid
	damage = idamage
	_icon = _asdicon[model]

func attack(collider, from) -> bool:
	if lastAttackTime + attackRate * 1000 > OS.get_ticks_msec():
		return false
	lastAttackTime = OS.get_ticks_msec()

	if collider != null:
		collider.damage(rand_range(damage[0], damage[1]), from)
	return true

func distance() -> float:
	return 50.0

func name() -> String:
	return _name
