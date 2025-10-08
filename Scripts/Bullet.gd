extends Node3D

@export var SPEED: float = 40.0
@export var LIFETIME: float = 3.0   # bullet หายไปเองถ้าไม่ชนภายในเวลา

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var ray: RayCast3D = $RayCast3D
@onready var particles: GPUParticles3D = $GPUParticles3D

var _traveled := 0.0
var _max_distance := SPEED * LIFETIME
var _hit := false

func _ready() -> void:
	# ตั้ง RayCast ให้เปิดเสมอ
	ray.enabled = true
	# fail-safe ถ้าไม่ชนเลย
	await get_tree().create_timer(LIFETIME).timeout
	if not _hit:
		queue_free()

func _process(delta: float) -> void:
	if _hit:
		return

	# เดินทางข้างหน้า (แกน -Z ของตัวเอง)
	global_position += -transform.basis.z * SPEED * delta
	_traveled += SPEED * delta

	if _traveled > _max_distance:
		queue_free()
		return

	ray.force_raycast_update()
	if ray.is_colliding():
		_on_bullet_hit(ray.get_collider())

func _on_bullet_hit(collider: Object) -> void:
	_hit = true
	mesh.visible = false
	particles.emitting = true
	ray.enabled = false

	if collider and collider.is_in_group("enemy"):
		# collider อาจเป็น Area3D ของร่างกาย -> มีฟังก์ชัน hit()
		if collider.has_method("hit"):
			collider.hit()

	# รอให้ particles เล่นจบก่อนลบ
	await get_tree().create_timer(1.0).timeout
	queue_free()
