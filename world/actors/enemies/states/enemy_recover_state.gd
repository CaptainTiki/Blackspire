extends "res://world/actors/enemies/enemy_base_state.gd"
class_name EnemyRecoverState

var _recover_timer: float = 0.0


func _on_recover_state_entered() -> void:
	if not enemy:
		return
	enemy.set_is_attacking(true)
	_recover_timer = enemy.attack_cooldown
	enemy.stop_horizontal_movement()
	enemy.set_debug_state("RECOVER")
	# Could play a short "recover" anim or just idle pose; reuse "idle" for proto
	enemy.play_animation(&"idle")


func _on_recover_state_physics_processing(delta: float) -> void:
	if not enemy or not enemy.is_network_authority or enemy.is_dead:
		return

	_recover_timer = maxf(_recover_timer - delta, 0.0)
	enemy.stop_horizontal_movement()
	enemy.move_with_gravity(delta)

	enemy.update_target()

	if _recover_timer <= 0.0:
		enemy.state_chart.send_event.call_deferred(&"onReady")
		if enemy.has_valid_target() and enemy.distance_to_target() <= enemy.attack_range * 1.1:
			enemy.state_chart.send_event.call_deferred(&"onChase")
		else:
			enemy.state_chart.send_event.call_deferred(&"onIdle")
