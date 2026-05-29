extends Label3D
class_name FloatingDamageNumber3D

@export var lifetime := 0.75
@export var float_speed := 0.65

var _age := 0.0


func setup(amount: int) -> void:
	text = str(amount)
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	pixel_size = 0.003
	font_size = 48
	outline_size = 6
	modulate = Color(1.0, 0.88, 0.42, 1.0)


func _process(delta: float) -> void:
	_age += delta
	position.y += float_speed * delta

	var remaining_alpha: float = 1.0 - clamp(_age / lifetime, 0.0, 1.0)
	modulate.a = remaining_alpha

	if _age >= lifetime:
		queue_free()
