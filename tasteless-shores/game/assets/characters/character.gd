tool

class_name Character
extends Spatial

const Weapon = preload("res://game/items/weapon.gd")
const AnimationTreeScene = preload("res://assets/characters/animation_tree.tscn")

enum Animation {
	IDLE
	WALKING
	JUMPING
	RUNNING
	FALLING
	DEAD
}

# signal animation_finished

export(String, FILE, "*.gltf") var character setget set_character
export(String, FILE, "*.tres") var material = "res://assets/materials/texture_01_a.tres" setget set_material

var bone_attachment: BoneAttachment = null
var animation_tree: AnimationTree = null
var animation_player: AnimationPlayer = null

func set_character(character_file):
	for child in get_children():
		child.queue_free()

	character = character_file

	var char_instance = load(character).instance()
	char_instance.name = "Character"
	char_instance.transform.basis = Basis(Vector3.UP, deg2rad(180))
	var skeleton = char_instance.get_node("Armature/Skeleton")
	var mesh = skeleton.get_children()[0]
	mesh.set_surface_material(0, load(material))
	bone_attachment = BoneAttachment.new()
	skeleton.add_child(bone_attachment)
	bone_attachment.bone_name = "RightHandIndex2"
	animation_tree = AnimationTreeScene.instance()
	char_instance.add_child(animation_tree)
	animation_player = char_instance.get_node("AnimationPlayer")
	animation_tree.active = true
	# var offset = rand_range(0, 0.1)
	# animation_tree.advance(offset)
	add_child(char_instance)

func set_material(material_file):
	material = material_file
	if !has_node("Character"):
		return

	var char_instance = get_node("Character")
	var skeleton = char_instance.get_node("Armature/Skeleton")
	var mesh = skeleton.get_children()[0]
	mesh.set_surface_material(0, load(material))

func setchar(shade, color, chars):
	shade = ["c", "b", "a"][shade]
	color = ["1", "2", "3", "4"][color]
	chars = ["unknown", "female", "male"][chars]

	set_material("res://assets/materials/texture_0" + color + "_" + shade + ".tres")
	set_character("res://assets/characters/player_" + chars + ".gltf")

func shoot():
	animation_tree.set("parameters/shoot/active", true)
	# if animation_player != null:
	# 	yield(animation_player, "animation_finished")
	# 	emit_signal("animation_finished")

func hit():
	animation_tree.set("parameters/hit/active", true)
	# yield(animation_player, "animation_finished")
	# emit_signal("animation_finished")

func slash():
	animation_tree.set("parameters/slash/active", true)
	# if animation_player != null:
	# 	yield(animation_player, "animation_finished")
	# 	emit_signal("animation_finished")

var current_anim = -1
func motion(where):
	if Server.socket != null:
		return

	if where == current_anim:
		return
	current_anim = where

	var anim = "idle-loop"
	match where:
		Animation.IDLE:
			anim = "idle-loop"
		Animation.WALKING:
			anim = "walking-loop"
		Animation.JUMPING:
			anim = "falling-loop"  # todo: check
		Animation.FALLING:
			anim = "falling-loop"
		Animation.RUNNING:
			anim = "running-loop"
		Animation.DEAD:
			anim = "dying"
	
	# prints("setting motion", anim)

	animation_tree.get("parameters/motion/playback").travel(anim)

func equip(weapon: Weapon):
	# var ba = ($PlayerChar/Armature/Skeleton/BoneAttachment/Position3D as Position3D)
	for child in bone_attachment.get_children():
		child.queue_free()
	yield(get_tree(), "idle_frame")
	bone_attachment.add_child(weapon.model())
