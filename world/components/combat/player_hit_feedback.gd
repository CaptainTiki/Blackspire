extends CanvasLayer
class_name PlayerHitFeedback

@export var health_component: Node
@export var flash_alpha := 0.5
@export var fade_speed := 1.8

@onready var overlay: ColorRect = $Overlay

var _alpha := 0.0
var hit_count := 0


func _ready() -> void:
	if not health_component:
		push_error("PlayerHitFeedback requires a health_component reference.")

	health_component.damaged.connect(_on_health_damaged)
	_set_alpha(0.0)


func _process(delta: float) -> void:
	if _alpha == 0.0:
		return

	_set_alpha(move_toward(_alpha, 0.0, fade_speed * delta))


func _on_health_damaged(_damage_request: Variant, _remaining_health: int) -> void:
	hit_count += 1
	_set_alpha(flash_alpha)


func _set_alpha(value: float) -> void:
	_alpha = clamp(value, 0.0, 1.0)
	var color := overlay.color
	color.a = _alpha
	overlay.color = color
