extends CharacterBody3D

var player = null
var state_machine

const SPEED = 4.0
const ATTACK_RANGE = 2.5

@export var player_path := "/root/World/Map/Player"  # ปรับพาธให้ตรงกับตำแหน่ง Player

@onready var nav_agent = $NavigationAgent3D
@onready var anim_tree = $AnimationTree

# Called when the node enters the scene tree for the first time.
func _ready():
	player = get_node(player_path)  # ใช้ player_path
	state_machine = anim_tree.get("parameters/playback")
	if player == null:
		print("Error: Player node not found at ", player_path)  # เพิ่มการดีบั๊ก

# Called every frame. 'delta' is elapsed time since the previous frame.
func _process(delta):
	print("Current state: ", state_machine.get_current_node())  # เพิ่มนี้
	velocity = Vector3.ZERO
	# โค้ดเดิมต่อ
	
	match state_machine.get_current_node():
		"RUN":
			# Navigation
			if player != null:  # ตรวจสอบก่อนใช้
				nav_agent.set_target_position(player.global_transform.origin)
				var next_nav_point = nav_agent.get_next_path_position()
				velocity = (next_nav_point - global_transform.origin).normalized() * SPEED
				rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), delta * 10.0)
		"ATTACK":
			if player != null:  # ตรวจสอบก่อนใช้
				look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
	
	# Conditions
	anim_tree.set("parameters/conditions/attack", _target_in_range())
	anim_tree.set("parameters/conditions/run", !_target_in_range())
	
	anim_tree.get("parameters/playback")
	
	move_and_slide()

func _target_in_range():
	if player == null:
		return false  # ป้องกันข้อผิดพลาดถ้า player ไม่มี
	return global_position.distance_to(player.global_position) < ATTACK_RANGE

func _hit_finished():
	if player != null and global_position.distance_to(player.global_position) < ATTACK_RANGE + 1.0:
		var dir = global_position.direction_to(player.global_position)
		player.hit(dir)
