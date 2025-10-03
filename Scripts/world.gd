extends Node3D

@onready var hit_rect = $UI/HitRect
@onready var spawns = $Map/Spawns
@onready var navigation_region = $NavigationRegion3D  # เปลี่ยนจาก $Map/NavigationRegion3D

var zombie = load("res://Scenes/zombie.tscn")
var instance

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
		
	
# Called every frame. 'delta' is the elapsed time sice the previous frame.
func _process(delta):
	pass


func _on_player_player_hit():
	hit_rect.visible = true
	await get_tree().create_timer(0.2).timeout
	hit_rect.visible = false


func _get_random_child(parent_node):
	var random_id = randi() % parent_node.get_child_count()
	return parent_node.get_child(random_id)


func _on_zombie_spawn_timer_timeout() -> void:
	var spawn_point = _get_random_child(spawns).global_position
	instance = zombie.instantiate()
	if instance != null:  # ตรวจสอบว่าอินสแตนซ์สำเร็จ
		instance.position = spawn_point
		add_child(instance)  # เปลี่ยนจาก navigation_region.add_child ไปใช้ add_child
		print("Zombie spawned at: ", spawn_point)  # เพิ่มการดีบั๊ก
	else:
		print("Error: Failed to instantiate zombie from ", zombie)
