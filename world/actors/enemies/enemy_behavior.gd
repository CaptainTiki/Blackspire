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
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	if not enemy:
		push_error("EnemyBehavior requires an enemy reference.")


func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	_attack_timer = maxf(_attack_timer - delta, 0.0)
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

	if _distance_to_target() > enemy.attack_range:
		_transition_to(State.CHASE)
		return

	enemy.velocity.x = 0.0
	enemy.velocity.z = 0.0
	_apply_gravity_and_move(delta)

	if _attack_timer == 0.0:
		_attack_target()
		_attack_timer = enemy.attack_cooldown


func _attack_target() -> void:
	if not target.has_node("Components/HealthComponent"):
		return

	var damage_request := DamageRequestScript.new(enemy, enemy.attack_damage, target.global_position + Vector3.UP)
	target.get_node("Components/HealthComponent").apply_damage(damage_request)


func _get_target() -> Node3D:
	var closest_player: Node3D
	var closest_distance := INF

	for player in enemy.get_tree().get_nodes_in_group("players"):
		if not player is Node3D:
			continue

		if player.has_node("Components/HealthComponent"):
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
