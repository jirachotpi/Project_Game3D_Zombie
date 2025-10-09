extends Node3D

@onready var hit_rect = $UI/HitRect
@onready var spawns = $Map/Spawns
@onready var enemies_parent = $Map/Enemies
@onready var navigation_region = $Map/NavigationRegion3D
@onready var player = $Map/Player
@onready var spawn_timer := $ZombieSpawnTimer

# HUD
@onready var hud_time := $UI/HUD/TimeLabel
@onready var hud_hp := $UI/HUD/HealthBar
@onready var crosshair := $UI/HUD/Crosshair

# Menus
@onready var menu_start := $UI/StartMenu
@onready var menu_settings := $UI/Settings
@onready var menu_over := $UI/GameOver
@onready var over_time_label := $UI/GameOver/Panel/LabelTimeSurvived

var zombie = load("res://Scenes/zombie.tscn")

# -- survival time
var _running := false
var _start_time_sec := 0.0
var _elapsed_sec := 0.0

# -- spawn scaling
@export var base_spawn_wait := 5.0   # 5s (ค่าปัจจุบันของคุณ)
@export var min_spawn_wait := 0.0    # ต่ำสุด
@export var spawn_decay_rate := 0.02 # วินาที/วินาที: ลด 0.02s ต่อ 1s
# สูตร: wait_time = max(min_spawn_wait, base_spawn_wait - elapsed * spawn_decay_rate)
@onready var bgm := $Audio/BGM
@onready var sfx_shoot := $Audio/SFX_Shoot
@onready var sfx_zombie := $Audio/SFX_Zombie

func _ready():
	randomize()
	# signals
	if not player.is_connected("player_hit", Callable(self, "_on_player_player_hit")):
		player.connect("player_hit", Callable(self, "_on_player_player_hit"))
	if not player.is_connected("player_died", Callable(self, "_on_player_died")):
		player.connect("player_died", Callable(self, "_on_player_died"))

	# Settings UI wiring
	_bind_settings_ui()
	
	# เริ่มที่หน้า Start
	_show_start_menu()


func _process(delta: float) -> void:
	if not _running:
		return
	_elapsed_sec = Time.get_ticks_msec() / 1000.0 - _start_time_sec
	_update_hud()
	_update_spawn_rate()

func _update_hud() -> void:
	# เวลา
	var t := int(_elapsed_sec)
	var m := t / 60
	var s := t % 60
	hud_time.text = "%02d:%02d" % [m, s]
	# HP
	if hud_hp:
		hud_hp.value = float(player.hp) / float(player.MAX_HP) * 100.0

func _update_spawn_rate() -> void:
	var new_wait : float = max(min_spawn_wait, base_spawn_wait - _elapsed_sec * spawn_decay_rate)
	if abs(spawn_timer.wait_time - new_wait) > 0.05:
		spawn_timer.wait_time = new_wait

func _on_player_player_hit():
	hit_rect.visible = true
	await get_tree().create_timer(0.2).timeout
	hit_rect.visible = false

func _on_player_died():
	_running = false
	get_tree().paused = true
	menu_over.visible = true
	var t := int(_elapsed_sec)
	over_time_label.text = "You survived %02d:%02d" % [t/60, t%60]
	if crosshair: crosshair.visible = false

func _get_random_child(parent_node):
	var random_id = randi() % parent_node.get_child_count()
	return parent_node.get_child(random_id)

func _on_zombie_spawn_timer_timeout() -> void:
	if not _running:
		return
	var spawn_node = _get_random_child(spawns)
	if not is_instance_valid(spawn_node):
		return

	var spawn_point: Vector3
	if spawns.is_inside_tree():
		spawn_point = spawns.to_global(spawn_node.position)
	else:
		spawn_point = spawn_node.global_position  # fallback ถ้า spawns ยังไม่ ready

	var instance = zombie.instantiate()
	instance.global_position = spawn_point
	enemies_parent.add_child(instance)

# ---------- Menus ----------
func _show_start_menu() -> void:
	get_tree().paused = true
	menu_start.visible = true
	menu_settings.visible = false
	menu_over.visible = false
	_running = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if crosshair: crosshair.visible = false

func _start_game() -> void:
	get_tree().paused = false
	menu_start.visible = false
	menu_settings.visible = false
	menu_over.visible = false
	_running = true
	_start_time_sec = Time.get_ticks_msec() / 1000.0
	_elapsed_sec = 0.0
	spawn_timer.wait_time = base_spawn_wait
	player.hp = player.MAX_HP
	player.set_process(true)
	player.set_physics_process(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if crosshair: crosshair.visible = true

func _restart_game() -> void:
	get_tree().reload_current_scene()

# ---------- Settings ----------
func _bind_settings_ui() -> void:
	if player == null:
		await get_tree().process_frame
		player = $Map/Player
	# ปุ่มจาก StartMenu
	var btn_start := $UI/StartMenu/Panel/ButtonStart
	var btn_settings := $UI/StartMenu/Panel/ButtonSettings
	var btn_quit := $UI/StartMenu/Panel/ButtonQuit
	btn_start.pressed.connect(_start_game)
	btn_settings.pressed.connect(func(): menu_settings.visible = true; menu_start.visible = false)
	btn_quit.pressed.connect(func(): get_tree().quit())

	# Settings sliders
	var s_mouse := $UI/Settings/Panel/SliderMouse
	var s_volume := $UI/Settings/Panel/SliderVolume
	var btn_back := $UI/Settings/Panel/ButtonBack

	# ค่าเริ่มต้น
	s_mouse.min_value = player.SENS_MIN
	s_mouse.max_value = player.SENS_MAX
	s_mouse.value = player.MOUSE_SENSITIVITY

	s_volume.min_value = 0.0
	s_volume.max_value = 1.0
	s_volume.value = 1.0  # เริ่มที่ 100%

	s_mouse.value_changed.connect(func(v): player.set_mouse_sensitivity(v))
	s_volume.value_changed.connect(func(v):
		var db := linear_to_db(v) # 0..1 -> dB
		var idx := AudioServer.get_bus_index("Master")
		AudioServer.set_bus_volume_db(idx, db)
	)

	btn_back.pressed.connect(func():
		menu_settings.visible = false
		menu_start.visible = true
	)

	# ปุ่ม GameOver
	var btn_restart := $UI/GameOver/Panel/ButtonRestart
	btn_restart.pressed.connect(_restart_game)

# helper
func linear_to_db(v: float) -> float:
	# ป้องกัน -inf
	if v <= 0.0001:
		return -60.0
	# 0..1 -> -30..0 dB (นุ่มหู)
	return lerp(-30.0, 0.0, clampf(v, 0.0, 1.0))
