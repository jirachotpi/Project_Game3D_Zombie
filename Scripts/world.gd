extends Node3D

@onready var hit_rect = $UI/HitRect
@onready var spawns = $Map/Spawns
@onready var enemies_parent = $Map/Enemies
@onready var navigation_region = $Map/NavigationRegion3D

var zombie = load("res://Scenes/zombie.tscn")

func _ready():
	randomize()

func _on_player_player_hit():
	hit_rect.visible = true
	await get_tree().create_timer(0.2).timeout
	hit_rect.visible = false

func _get_random_child(parent_node):
	var random_id = randi() % parent_node.get_child_count()
	return parent_node.get_child(random_id)

func _on_zombie_spawn_timer_timeout() -> void:
	var spawn_node = _get_random_child(spawns)
	if not spawn_node.is_inside_tree():
		await spawn_node.ready  # รอให้ node เข้า tree ก่อน
	var spawn_point = spawn_node.global_position
	var instance = zombie.instantiate()
	instance.global_position = spawn_point
	enemies_parent.add_child(instance)
