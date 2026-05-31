extends Node
class_name HealthComponent

signal health_changed(current_health: int, max_health: int)
signal damaged(damage_request: Variant, remaining_health: int)
signal died(damage_request: Variant)

@export var max_health := 30
@export var current_health := 30

var is_dead := false


func _ready() -> void:
	current_health = clamp(current_health, 0, max_health)
	is_dead = current_health <= 0
	health_changed.emit(current_health, max_health)


func apply_damage(damage_request: Variant) -> void:
	if is_dead:
		return

	current_health = maxi(current_health - damage_request.amount, 0)
	health_changed.emit(current_health, max_health)
	damaged.emit(damage_request, current_health)

	if current_health == 0:
		is_dead = true
		died.emit(damage_request)


func revive(health_amount: int) -> void:
	current_health = clamp(health_amount, 1, max_health)
	is_dead = false
	health_changed.emit(current_health, max_health)
