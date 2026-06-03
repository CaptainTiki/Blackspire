extends CanvasLayer
class_name PlayerHUD

@export var health_component: Node

@onready var health_label: Label = $HealthLabel

var is_split_screen_layout := false


func _ready() -> void:
	if not health_component:
		push_error("PlayerHUD requires a health_component reference.")

	health_label.add_theme_font_size_override("font_size", 24)
	health_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.82, 1.0))
	health_component.health_changed.connect(_on_health_changed)
	_update_health()
	_create_crosshair()


func _on_health_changed(_current_health: int, _max_health: int) -> void:
	_update_health()


func _update_health() -> void:
	health_label.text = "HP %d/%d" % [health_component.current_health, health_component.max_health]


func configure_for_split_screen() -> void:
	is_split_screen_layout = true
	health_label.add_theme_font_size_override("font_size", 18)
	health_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	health_label.offset_left = 12.0
	health_label.offset_top = -34.0
	health_label.offset_right = 160.0
	health_label.offset_bottom = -8.0

	var cross := get_node_or_null("Crosshair")
	if cross:
		cross.scale = Vector2(0.7, 0.7)


func _create_crosshair() -> void:
	var cross := Control.new()
	cross.name = "Crosshair"
	cross.set_anchors_preset(Control.PRESET_CENTER)
	cross.size = Vector2(17, 17)
	cross.pivot_offset = Vector2(8.5, 8.5)
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cross)

	var color := Color(0.95, 0.92, 0.82, 0.85)

	# Horizontal left arm
	var h_left := ColorRect.new()
	h_left.color = color
	h_left.size = Vector2(5, 1)
	h_left.position = Vector2(2, 8)
	cross.add_child(h_left)

	# Horizontal right arm
	var h_right := ColorRect.new()
	h_right.color = color
	h_right.size = Vector2(5, 1)
	h_right.position = Vector2(10, 8)
	cross.add_child(h_right)

	# Vertical top arm
	var v_top := ColorRect.new()
	v_top.color = color
	v_top.size = Vector2(1, 5)
	v_top.position = Vector2(8, 2)
	cross.add_child(v_top)

	# Vertical bottom arm
	var v_bottom := ColorRect.new()
	v_bottom.color = color
	v_bottom.size = Vector2(1, 5)
	v_bottom.position = Vector2(8, 10)
	cross.add_child(v_bottom)
