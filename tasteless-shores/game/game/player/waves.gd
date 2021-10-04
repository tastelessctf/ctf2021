extends MeshInstance

export var player: NodePath
var tracked: Spatial

# signal water_entered
# signal water_exited

func _ready():
	# tracked = get_node(player)
	tracked = get_parent()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	# print(tracked.global_transform.origin)
	var dx = fmod(tracked.global_transform.origin.x, 2*PI)
	var dz = fmod(tracked.global_transform.origin.z, 2*PI)
	global_transform.origin.x = tracked.global_transform.origin.x - dx
	global_transform.origin.z = tracked.global_transform.origin.z - dz
	global_transform.origin.y = 0
	global_transform.basis = Basis.IDENTITY
	# print(global_transform.origin)
