extends Spatial

const Unit = preload("res://game/unit/unit.gd")
const Player = preload("res://game/player/player.gd")
const Items = preload("res://game/items/items.gd")

onready var player: Player = get_parent().get_parent() as Player
onready var placeRayCast = $PlaceRayCast as RayCast
onready var placePivot = $placepivot as Position3D

var moveSpeed : float = 2.0
var jumpForce : float = 5.0
var boatSpeed : float = 25.0
var currentSpeed : float = moveSpeed
var vel : Vector3 = Vector3()
var paused = false

func _ready():
	if true:
		moveSpeed = 5.0
		jumpForce = 10.0
		boatSpeed = 50.0
	currentSpeed = moveSpeed
	yield(get_tree(), "idle_frame")
	($SpringArm/Camera as Camera).make_current()
	assert(player.connect("died", self, "player_died") == OK)
	assert(player.connect("water_entered", self, "_on_Player_water_entered") == OK)
	assert(player.connect("water_exited", self, "_on_Player_water_exited") == OK)
	assert(player.connect("equipped", self, "_on_Player_equipped") == OK)
	placePivot.hide()

func enable_placement():
	placeRayCast.enabled = true

func disable_placement():
	placeRayCast.enabled = false
	placePivot.hide()

func _process(_delta):
	if player.health <= 0:
		return
	
	if paused:
		return

	var collider = $InteractRayCast.get_collider()
	Ui.interactable(collider)

	collider = $AttackRayCast.get_collider() as Unit
	if collider == null:
		Ui.attackable("")
	else:
		Ui.attackable(collider.unit_name + "\n[" + String(collider.health) + "]")

	if abs(vel.y) > 2:
		player.character.motion(Character.Animation.FALLING)
	elif vel.distance_to(Vector3.ZERO) > 0.1:
		player.character.motion(Character.Animation.WALKING)
	else:
		player.character.motion(Character.Animation.IDLE)

	if placeRayCast.enabled && placeRayCast.get_collision_point() != Vector3.ZERO:
		placePivot.global_transform.origin = placeRayCast.get_collision_point()
		placePivot.global_transform.basis = player.global_transform.basis
		placePivot.show()
	else:
		placePivot.hide()

func _unhandled_input(event):
	var collider = $InteractRayCast.get_collider()
	if collider != null and event.is_action_pressed("interact"):
		collider.interact()

	collider = $AttackRayCast.get_collider() as Unit
	if event.is_action_pressed("attack"):
		player.start_attack(collider)

func _physics_process(delta):
	vel.x = 0
	vel.z = 0
	
	var input = Vector3()

	vel.y += -9.8 * delta

	if player.health > 0 && !paused && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# movement inputs
		if Input.is_action_pressed("ui_up"):
			input.z -= 1
		if Input.is_action_pressed("ui_down"):
			input.z += 1
		if Input.is_action_pressed("ui_left"):
			input.x -= 1
		if Input.is_action_pressed("ui_right"):
			input.x += 1
		
		if Input.is_action_pressed("jump") and player.is_on_floor() and !player.boat and !player.drowning:
			vel.y = jumpForce

	# normalize the input vector to prevent increased diagonal speed
	input = input.normalized()
	
	# get the relative direction
	var dir = (player.transform.basis.z * input.z + player.transform.basis.x * input.x)
	
	# apply the direction to our velocity
	vel.x = dir.x * currentSpeed * delta * 100
	vel.z = dir.z * currentSpeed * delta * 100
	
	vel = player.move_and_slide(vel, Vector3.UP, true)
	if vel.y > jumpForce:
		vel.y = jumpForce

func _on_Area_body_entered(body: Node):
	if body is Unit:
		if body.unit_team != "":
			Ui.world_label.add(body.unit_name + "\n<" + body.unit_team + ">", body)
		else:
			Ui.world_label.add(body.unit_name, body)

func _on_Area_body_exited(body: Node):
	if body is Unit:
		Ui.world_label.remove(body)

func player_died():
	player.character.motion(Character.Animation.DEAD)
	Ui.dead()

func _on_Player_water_entered():
	currentSpeed = boatSpeed

func _on_Player_water_exited():
	currentSpeed = moveSpeed

func _on_Player_equipped(item):
	if Items.by_id(item) == null:
		return
	$AttackRayCast.cast_to.z = -Items.by_id(item).distance()

func _on_Map_area_shape_entered(id, area, area_shape, local_shape):
	Ui.minimap.add_track(id, area.global_transform.origin.x, area.global_transform.origin.z, area.name)
	
func _on_Map_area_shape_exited(id, area, area_shape, local_shape):
	Ui.minimap.remove_track(id)
