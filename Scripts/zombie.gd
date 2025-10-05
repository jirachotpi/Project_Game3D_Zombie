extends CharacterBody3D

const SPEED = 4.0
const ATTACK_RANGE = 2.5

var player: Node3D
var state_machine

@onready var nav_agent = $NavigationAgent3D
@onready var anim_tree = $AnimationTree

func _ready():
	player = get_tree().get_root().get_node("World/Map/Player")
	if player == null:
		push_error("Zombie.gd: Player node not found. Check the path World/Map/Player.")
	state_machine = anim_tree.get("parameters/playback")

func _process(delta):
	if player == null:
		return
	
	velocity = Vector3.ZERO

	match state_machine.get_current_node():
		"RUN":
			nav_agent.set_target_position(player.global_transform.origin)
			var next_nav_point = nav_agent.get_next_path_position()
			velocity = (next_nav_point - global_transform.origin).normalized() * SPEED
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
		"ATTACK":
			look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)

	anim_tree.set("parameters/conditions/attack", _target_in_range())
	anim_tree.set("parameters/conditions/run", !_target_in_range())

	move_and_slide()

func _target_in_range() -> bool:
	return global_position.distance_to(player.global_position) < ATTACK_RANGE if player else false

func _hit_finished():
	if player and global_position.distance_to(player.global_position) < ATTACK_RANGE + 1.0:
		var dir = global_position.direction_to(player.global_position)
		player.hit(dir)
