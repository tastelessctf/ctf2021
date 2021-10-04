extends Object

const Weapon = preload("res://game/items/weapon.gd")
const MeleeWeapon = preload("res://game/items/melee_weapon.gd")
const RangeWeapon = preload("res://game/items/range_weapon.gd")

const Conch = preload("res://island/town/conch.tscn")
const Hammer = preload("res://island/home/hammer.tscn")
const FishingRodScene = preload("res://game/items/fishing_rod.tscn")

enum IDs {
	NONE
	AXE1
	CUTLASS1
	SABRE1
	PISTOL1
	MUSKET1
	FISHINGROD1
	CONCH
	HAMMER
}

static func by_id(id: int, active = false) -> Weapon:
	match id:
		IDs.NONE:
			return null
		IDs.AXE1:
			return MeleeWeapon.new(IDs.AXE1, "Axe", "Axe_01", [10, 15])
		IDs.CUTLASS1:
			return MeleeWeapon.new(IDs.CUTLASS1, "Cutlass", "Cutlass_01", [15, 20])
		IDs.SABRE1:
			return MeleeWeapon.new(IDs.SABRE1, "Sabre", "Sabre_01", [20, 25])
		IDs.PISTOL1:
			return RangeWeapon.new(IDs.PISTOL1, "Pistol", "Pistol_01", [30, 50])
		IDs.MUSKET1:
			return RangeWeapon.new(IDs.MUSKET1, "Musket", "MusketPistol_01", [50, 75])
		IDs.FISHINGROD1:
			var rod = FishingRodScene.instance()
			return Weapon.new(IDs.FISHINGROD1, rod, 10.0, f)
		IDs.CONCH:
			var conch = Conch.instance()
			return Weapon.new(IDs.CONCH, conch, 1.0, c)
		IDs.HAMMER:
			var hammer = Hammer.instance()
			hammer.active = active
			return Weapon.new(IDs.HAMMER, hammer, 1.0, h)
	return null

const f = preload("res://assets/weapons/FishingRod.png")
const c = preload("res://assets/weapons/Conch.png")
const h = preload("res://assets/weapons/Hammer.png")
