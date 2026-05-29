extends Node
class_name EnemyBehavior

const DamageRequestScript := preload("res://world/components/combat/damage_request.gd")

enum State {
	IDLE,
	CHASE,
	ATTACK,
	DEAD,
}

@export var enemy: Node

var current_state := State.IDLE
var target: Node3D
var _attack_timer := 0.0
var _windup_timer := 0.0
var _is_winding_up := false
var _lunge_timer := 0.0
var _is_lunging := false
var _lunge_direction := Vector3.ZERO
var _has_hit_during_lunge := false
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	if not enemy:
		push_error("EnemyBehavior requires an enemy reference.")


func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_windup_timer = maxf(_windup_timer - delta, 0.0)
	_lunge_timer = maxf(_lunge_timer - delta, 0.0)
	target = _get_target()

	match current_state:
		State.IDLE:
			_process_idle()
		State.CHASE:
			_process_chase(delta)
		State.ATTACK:
			_process_attack(delta)


func set_dead() -> void:
	_transition_to(State.DEAD)
	enemy.velocity = Vector3.ZERO


func _process_idle() -> void:
	enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, enemy.move_speed)
	enemy.velocity.z = move_toward(enemy.velocity.z, 0.0, enemy.move_speed)
	_apply_gravity_and_move(0.0)

	if target and _distance_to_target() <= enemy.aggro_range:
		_transition_to(State.CHASE)


func _process_chase(delta: float) -> void:
	if not target:
		_transition_to(State.IDLE)
		return

	if _distance_to_target() <= enemy.attack_range:
		_transition_to(State.ATTACK)
		return

	var direction: Vector3 = target.global_position - enemy.global_position
	direction.y = 0.0
	direction = direction.normalized()

	enemy.velocity.x = direction.x * enemy.move_speed
	enemy.velocity.z = direction.z * enemy.move_speed
	enemy.look_at(enemy.global_position + direction, Vector3.UP)
	_apply_gravity_and_move(delta)


func _process_attack(delta: float) -> void:
	if not target:
		_transition_to(State.IDLE)
		return

	if _is_lunging:
		_process_attack_lunge(delta)
		return

	enemy.velocity.x = 0.0
	enemy.velocity.z = 0.0
	_apply_gravity_and_move(delta)

	if _is_winding_up:
		enemy.look_at(target.global_position, Vector3.UP)
		if _windup_timer == 0.0:
			_start_attack_lunge()
		return

	if _distance_to_target() > enemy.attack_range:
		_transition_to(State.CHASE)
		return

	if _attack_timer == 0.0:
		_start_attack_windup()


func _start_attack_windup() -> void:
	_is_winding_up = true
	_windup_timer = enemy.attack_windup
	enemy.play_attack_tell(target)


func _start_attack_lunge() -> void:
	_is_winding_up = false
	_is_lunging = true
	_lunge_timer = enemy.attack_lunge_duration
	_lunge_direction = target.global_position - enemy.global_position
	_lunge_direction.y = 0.0
	_lunge_direction = _lunge_direction.normalized()
	_has_hit_during_lunge = false
	enemy.velocity.y = enemy.attack_lunge_jump_velocity
	enemy.play_attack_lunge(target)


func _process_attack_lunge(delta: float) -> void:
	var lunge_speed: float = enemy.attack_lunge_distance / enemy.attack_lunge_duration
	enemy.velocity.x = _lunge_direction.x * lunge_speed
	enemy.velocity.z = _lunge_direction.z * lunge_speed
	_apply_gravity_and_move(delta)
	_try_attack_hit()

	if _lunge_timer == 0.0:
		_finish_attack()


func _finish_attack() -> void:
	_is_lunging = false
	enemy.velocity.x = 0.0
	enemy.velocity.z = 0.0
	_try_attack_hit()

	_attack_timer = enemy.attack_cooldown


func _try_attack_hit() -> void:
	if _has_hit_during_lunge:
		return

	if not target:
		return

	if not _is_target_in_attack_cone():
		return

	_has_hit_during_lunge = true
	_attack_target()


func _is_target_in_attack_cone() -> bool:
	var to_target: Vector3 = target.global_position - enemy.global_position
	to_target.y = 0.0

	var distance := to_target.length()
	if distance > enemy.attack_hit_range:
		return false

	if distance == 0.0:
		return true

	var target_direction := to_target.normalized()
	var minimum_dot := cos(deg_to_rad(enemy.attack_hit_cone_degrees * 0.5))
	return _lunge_direction.dot(target_direction) >= minimum_dot


func _attack_target() -> void:
	var damage_request := DamageRequestScript.new(enemy, enemy.attack_damage, target.global_position + Vector3.UP)
	target.get_node("Components/HealthComponent").apply_damage(damage_request)


func _get_target() -> Node3D:
	var closest_player: Node3D
	var closest_distance := INF

	for player in enemy.get_tree().get_nodes_in_group("players"):
		if not player is Node3D:
			continue

		var health := player.get_node("Components/HealthComponent")
		if health.is_dead:
			continue

		var distance: float = enemy.global_position.distance_to(player.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_player = player

	return closest_player


func _distance_to_target() -> float:
	if not target:
		return INF

	return enemy.global_position.distance_to(target.global_position)


func _apply_gravity_and_move(delta: float) -> void:
	if not enemy.is_on_floor():
		enemy.velocity.y -= _gravity * delta

	enemy.move_and_slide()


func _transition_to(next_state: int) -> void:
	if current_state == next_state:
		return

	current_state = next_state
	_is_winding_up = false
	_is_lunging = false
	_windup_timer = 0.0
	_lunge_timer = 0.0
	_lunge_direction = Vector3.ZERO
	_has_hit_during_lunge = false
	enemy.set_debug_state(State.keys()[current_state])
