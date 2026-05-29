extends Node
class_name HealthComponent

signal damaged(damage_request: Variant, remaining_health: int)
signal died(damage_request: Variant)

@export var max_health := 30
@export var current_health := 30

var is_dead := false


func _ready() -> void:
	current_health = clamp(current_health, 0, max_health)
	is_dead = current_health <= 0


func apply_damage(damage_request: Variant) -> void:
	if is_dead:
		return

	current_health = maxi(current_health - damage_request.amount, 0)
	damaged.emit(damage_request, current_health)

	if current_health == 0:
		is_dead = true
		died.emit(damage_request)
