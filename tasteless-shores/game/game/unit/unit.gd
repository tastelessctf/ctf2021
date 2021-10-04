extends KinematicBody

const Weapon = preload("res://game/items/weapon.gd")
const MeleeWeapon = preload("res://game/items/melee_weapon.gd")
const RangeWeapon = preload("res://game/items/range_weapon.gd")
const Items = preload("res://game/items/items.gd")

signal died
signal attacked(unit)
signal equipped(item)
signal damaged(amount, from)

var health
var type
var remote_id: int = 0
var unit_name = "unknown"
var unit_team = ""
var weapon: Weapon = null
var height = 2.0
var died = false

onready var character = $Character as Character

func _init(itype, iname, ihealth):
	health = ihealth
	type = itype
	unit_name = iname

func _to_string():
	return "Unit[%d / %s (%d) (%d)]" % [type, unit_name, health, remote_id]

func _ready():
	assert(connect("died", self, "_on_died") == OK)
	assert(connect("attacked", self, "_on_attacked") == OK)
	assert(connect("equipped", self, "_on_equipped") == OK)
	assert(connect("damaged", self, "_on_damaged") == OK)

func _on_died():
	character.motion(Character.Animation.DEAD)
	collision_layer = 0

func _on_attacked(unit):
	if weapon == null:
		return
	if weapon is RangeWeapon:
		character.shoot()
	else:
		character.slash()
	if weapon.has_method("_on_attacked"):
		weapon._on_attacked(unit, self)

func _on_equipped(item):
	weapon = Items.by_id(item, Client.player != null && Client.player.remote_id == remote_id)
	if weapon != null && character != null:
		character.equip(weapon)

func _on_damaged(amount, from):
	health = amount
	if health > 0:
		character.hit()

func damage(amount: float, from = null):
	if health <= 0:
		return
	
	health -= amount
	Server.unit_damage(self, health, from)

	if health <= 0:
		die()

func die():
	if !died:
		health = 0
		Server.unit_die(self)
		died = true

func attack(target = null):
	if weapon != null:
		if weapon.attack(target, self):
			Server.unit_attack(self, target)

func equip(item: int):
	weapon = Items.by_id(item)
	if weapon == null:
		return
	Server.unit_equip(self, item)
