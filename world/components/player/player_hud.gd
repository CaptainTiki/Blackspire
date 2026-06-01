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
