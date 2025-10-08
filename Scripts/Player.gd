extends CharacterBody3D

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5
const HIT_STAGGER = 8.0

# -- mouse sensitivity (ปรับได้จาก Settings)
@export var MOUSE_SENSITIVITY := 0.004
const SENS_MIN := 0.001
const SENS_MAX := 0.02

# -- Health
@export var MAX_HP := 100
var hp := MAX_HP
@export var INVINCIBLE_TIME := 0.5
var _invincible_until := 0.0

# bob/fov (เดิม)
const BOB_FREQ = 2.4
const BOB_AMP = 0.08
var t_bob = 0.0
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

signal player_hit
signal player_died

var gravity = 9.8

var bullet = load("res://Scenes/Bullet.tscn")
var instance

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var gun_anim = $Head/Camera3D/Rifle/AnimationPlayer
@onready var gun_barrel = $Head/Camera3D/Rifle/RayCast3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func set_mouse_sensitivity(v: float) -> void:
	MOUSE_SENSITIVITY = clampf(v, SENS_MIN, SENS_MAX)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	if Input.is_action_just_pressed("shoot"):
		if !gun_anim.is_playing():
			gun_anim.play("Shoot")
			instance = bullet.instantiate()
			instance.position = gun_barrel.global_position
			instance.transform.basis = gun_barrel.global_transform.basis
			get_parent().add_child(instance)
			var world = get_tree().get_root().get_node("World")
			if world and world.has_node("Audio/SFX_Shoot"):
				world.get_node("Audio/SFX_Shoot").play()

	move_and_slide()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

# -- รับความเสียหาย + ช่วงอมตะ
func hit(dir: Vector3, damage: int = 10) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now < _invincible_until:
		return
	_invincible_until = now + INVINCIBLE_TIME

	emit_signal("player_hit")
	velocity += dir * HIT_STAGGER
	_apply_damage(damage)

func _apply_damage(dmg: int) -> void:
	hp = max(hp - dmg, 0)
	if hp <= 0:
		_die()

func _die() -> void:
	emit_signal("player_died")
	set_process(false)
	set_physics_process(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
