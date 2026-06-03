extends "res://world/actors/enemies/enemy_base_state.gd"
class_name EnemyLungeState

var _lunge_timer: float = 0.0
var _lunge_direction: Vector3 = Vector3.ZERO
var _has_hit: bool = false


func _on_lunge_state_entered() -> void:
	if not enemy:
		return
	enemy.set_is_attacking(true)
	_lunge_timer = enemy.attack_lunge_duration
	_has_hit = false
	if enemy.has_valid_target():
		_lunge_direction = (enemy.target.global_position - enemy.global_position)
		_lunge_direction.y = 0.0
		if _lunge_direction.length_squared() > 0.0001:
			_lunge_direction = _lunge_direction.normalized()
		enemy.velocity.y = enemy.attack_lunge_jump_velocity
		enemy.play_attack_lunge(enemy.target)
	enemy.set_debug_state("LUNGE")


func _on_lunge_state_physics_processing(delta: float) -> void:
	if not enemy or not enemy.is_network_authority or enemy.is_dead:
		return

	_lunge_timer = maxf(_lunge_timer - delta, 0.0)

	var lunge_speed: float = enemy.attack_lunge_distance / maxf(enemy.attack_lunge_duration, 0.01)
	enemy.velocity.x = _lunge_direction.x * lunge_speed
	enemy.velocity.z = _lunge_direction.z * lunge_speed
	enemy.move_with_gravity(delta)

	_try_hit()

	if _lunge_timer <= 0.0:
		_try_hit()
		enemy.state_chart.send_event.call_deferred(&"onRecover")


func _try_hit() -> void:
	if _has_hit or not enemy or not enemy.has_valid_target():
		return
	var to_target: Vector3 = enemy.target.global_position - enemy.global_position
	to_target.y = 0.0
	var dist: float = to_target.length()
	if dist > enemy.attack_hit_range:
		return
	var min_dot: float = cos(deg_to_rad(enemy.attack_hit_cone_degrees * 0.5))
	if _lunge_direction.dot(to_target.normalized()) < min_dot and dist > 0.1:
		return
	_has_hit = true
	_attack_target()


func _attack_target() -> void:
	if not enemy or not enemy.has_valid_target():
		return
	var dmg: DamageRequest = DamageRequest.new(enemy, enemy.attack_damage, enemy.target.global_position + Vector3.UP)
	if enemy.target.has_method("apply_damage"):
		enemy.target.apply_damage(dmg)
	else:
		push_error("Enemy target missing apply_damage: %s" % enemy.target.name)
