# Crosshair.gd
extends Control

@export var arm_len: float = 8.0       # เดิมชื่อ size → เปลี่ยนชื่อกันชนกับ Control.size
@export var gap: float = 6.0
@export var thickness: float = 2.0
@export var cross_color: Color = Color(1, 1, 1, 0.9)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT) # ให้ครอบเต็มจอ
	set_process(true)

func _draw() -> void:
	var center: Vector2 = size * 0.5          # ใช้ property size ของ Control
	var half_thick := thickness * 0.5
	# บน
	draw_rect(Rect2(center.x - half_thick, center.y - (gap + arm_len), thickness, arm_len), cross_color, true)
	# ล่าง
	draw_rect(Rect2(center.x - half_thick, center.y + gap, thickness, arm_len), cross_color, true)
	# ซ้าย
	draw_rect(Rect2(center.x - (gap + arm_len), center.y - half_thick, arm_len, thickness), cross_color, true)
	# ขวา
	draw_rect(Rect2(center.x + gap, center.y - half_thick, arm_len, thickness), cross_color, true)

func _process(_delta: float) -> void:
	queue_redraw()  # Godot 4 ใช้ฟังก์ชันนี้แทน update()
