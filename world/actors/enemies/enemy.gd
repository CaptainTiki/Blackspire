extends CharacterBody3D
class_name Enemy

## New base class for state-machine driven enemies (Slime and future types).
## Mirrors the player controller + state chart + mirrored state machine pattern.
## Current temporary BasicEnemy and EnemyBehavior remain untouched for now.

const FloatingDamageNumber := preload("res://world/components/combat/floating_damage_number_3d.gd")

@export var move_speed: float = 2.4
@export var attack_damage: int = 10
@export var attack_range: float = 2.75
@export var attack_cooldown: float = 1.0
@export var attack_windup: float = 0.35
@export var attack_lunge_distance: float = 3.25
@export var attack_lunge_duration: float = 0.35
@export var attack_lunge_jump_velocity: float = 2.2
@export var attack_hit_range: float = 1.65
@export var attack_hit_cone_degrees: float = 70.0
@export var aggro_range: float = 8.0
@export var death_cleanup_delay: float = 0.5

@onready var health: Node = $Components/HealthComponent
@onready var hurtbox_collision_shape: CollisionShape3D = $Components/Hurtbox/CollisionShape3D
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_chart: StateChart = %StateChart
@onready var debug_label: Label3D = $DebugStateLabel
@onready var death_timer: Timer = $DeathTimer

var network_enemy_id: int = -1
var is_dead: bool = false
var is_network_authority: bool = true

var target: Node3D
var _feedback_tween: Tween
var _base_mesh_position: Vector3 = Vector3.ZERO
var _base_mesh_scale: Vector3 = Vector3.ONE
var _base_mesh_rotation: Vector3 = Vector3.ZERO
var _base_albedo_color: Color = Color(0.5, 0.5, 0.5, 1.0)
var _mesh_material: StandardMaterial3D
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var _is_attacking := false


func is_attacking() -> bool:
	return _is_attacking


func set_is_attacking(attacking: bool) -> void:
	_is_attacking = attacking

# --- Animation Contract (enforced for all state-machine enemies) ---
# All enemies MUST have a child AnimationPlayer at $AnimationPlayer.
# Standard animation names (play via enemy.play_animation("idle") or direct):
#   "idle"     - when entering Idle state
#   "move"     - when chasing / moving
#   "windup"   - attack tell / windup
#   "lunge"    - committed attack lunge
#   "hurt"     - on taking damage (optional, can be quick)
#   "death"    - on death (or use "die")
# States and logic should always use these names for consistency across enemy types.
# The base provides play_animation() helper that warns on missing clips.

func _ready() -> void:
	add_to_group("enemies")

	_base_mesh_position = mesh.position
	_base_mesh_scale = mesh.scale
	_base_mesh_rotation = mesh.rotation
	_setup_material()

	if not animation_player:
		push_error("Enemy requires an AnimationPlayer child at $AnimationPlayer (see animation contract in README).")
	if not state_chart:
		push_error("Enemy requires a StateChart at %StateChart (unique name).")
	if not health:
		push_error("Enemy requires HealthComponent under Components/HealthComponent.")

	death_timer.timeout.connect(_on_death_timer_timeout)
	health.damaged.connect(_on_health_damaged)
	health.damaged.connect(_on_health_damaged_for_state)
	health.died.connect(_on_health_died)

	play_animation(&"idle")
	set_debug_state("IDLE")


func _setup_material() -> void:
	if mesh and mesh.material_override is StandardMaterial3D:
		_mesh_material = (mesh.material_override as StandardMaterial3D).duplicate()
		_base_albedo_color = _mesh_material.albedo_color
		mesh.material_override = _mesh_material
	else:
		_mesh_material = StandardMaterial3D.new()
		_base_albedo_color = Color(0.5, 0.5, 0.5, 1)


# --- Animation Contract Helper ---
func play_animation(anim_name: StringName) -> void:
	if not animation_player:
		return
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
	else:
		push_warning("Enemy '%s' animation contract violation: no animation named '%s' (expected by states)." % [name, anim_name])


# --- Target / Perception helpers (used by states and expression properties) ---
func update_target() -> void:
	target = _find_closest_valid_player()


func has_valid_target() -> bool:
	return is_instance_valid(target) and not _is_target_down(target)


func distance_to_target() -> float:
	if not has_valid_target():
		return INF
	return global_position.distance_to(target.global_position)


func _find_closest_valid_player() -> Node3D:
	var closest: Node3D = null
	var closest_dist: float = INF
	for player in get_tree().get_nodes_in_group("players"):
		if not is_instance_valid(player) or not player is Node3D:
			continue
		if _is_target_down(player):
			continue
		var d: float = global_position.distance_to(player.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = player
	return closest


func _is_target_down(candidate: Node) -> bool:
	var hc: Node = candidate.get_node_or_null("Components/HealthComponent")
	if hc == null:
		return false
	if hc.has_method("is_dead"):
		return hc.is_dead()
	# HealthComponent uses public var is_dead (no method); fallback for compatibility
	return hc.get("is_dead") == true


# --- Motor / Movement verbs (states call these) ---
func face_target() -> void:
	if not has_valid_target():
		return
	var dir: Vector3 = (target.global_position - global_position)
	dir.y = 0.0
	if dir.length_squared() > 0.0001:
		look_at(global_position + dir.normalized(), Vector3.UP)


func apply_horizontal_velocity(direction: Vector3, speed: float) -> void:
	var dir: Vector3 = direction
	dir.y = 0.0
	if dir.length_squared() > 0.0001:
		dir = dir.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed


func stop_horizontal_movement() -> void:
	velocity.x = 0.0
	velocity.z = 0.0


func move_with_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	move_and_slide()


# --- Combat verbs (called from states or externally) ---
func apply_damage(damage_request: Variant) -> void:
	if not is_network_authority:
		return
	if health and health.has_method("apply_damage"):
		health.apply_damage(damage_request)


func play_attack_tell(target_actor: Node3D) -> void:
	_restart_feedback_tween()
	var backward: Vector3 = (global_position - target_actor.global_position).normalized() * 0.12
	backward.y = 0.0
	_feedback_tween.tween_property(mesh, "position", _base_mesh_position + backward + Vector3(0.0, -0.05, 0.0), attack_windup).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_feedback_tween.parallel().tween_property(mesh, "scale", Vector3(1.12, 0.75, 1.12), attack_windup).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_feedback_tween.parallel().tween_property(mesh, "rotation", _base_mesh_rotation + Vector3(deg_to_rad(-14.0), 0.0, 0.0), attack_windup).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_flash_material(Color(0.95, 0.58, 0.18, 1.0), attack_windup)
	play_animation(&"windup")


func play_attack_lunge(_target_actor: Node3D) -> void:
	_restart_feedback_tween()
	_feedback_tween.tween_property(mesh, "scale", Vector3(1.15, 1.15, 1.15), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_feedback_tween.parallel().tween_property(mesh, "rotation", _base_mesh_rotation, attack_lunge_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_feedback_tween.tween_property(mesh, "position", _base_mesh_position, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_feedback_tween.parallel().tween_property(mesh, "scale", _base_mesh_scale, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	play_animation(&"lunge")


# --- Lifecycle ---
func die(damage_request: Variant) -> void:
	if is_dead:
		return
	if state_chart:
		state_chart.send_event.call_deferred(&"onDying")
	# Visuals, collision disable, animation, and timer are handled in the
	# DyingState via start_death_sequence() so the Life branch owns the sequence.


func decompose() -> void:
	if Level.current_level:
		Level.current_level.spawned_enemies.erase(self)
	queue_free()


func alert_to_player(player: Node3D) -> void:
	if not is_network_authority or is_dead:
		return
	target = player
	if state_chart:
		state_chart.send_event(&"onChase")


# --- Network authority / replication support (matches BasicEnemy interface for Level compatibility) ---
func set_network_enemy_id(enemy_id: int) -> void:
	network_enemy_id = enemy_id


func set_network_authority_enabled(is_enabled: bool) -> void:
	is_network_authority = is_enabled
	# Old behavior stopped its _physics; we rely on states checking the flag.
	if not is_enabled:
		velocity = Vector3.ZERO
		if has_node("CollisionShape3D"):
			get_node("CollisionShape3D").disabled = true


func get_network_state() -> Dictionary:
	return {
		"enemy_id": network_enemy_id,
		"position": global_position,
		"body_yaw": rotation.y,
		"is_dead": is_dead,
	}


func apply_network_state(_position: Vector3, body_yaw: float, replicated_is_dead: bool) -> void:
	if replicated_is_dead:
		apply_network_death()
		return
	global_position = _position
	rotation.y = body_yaw
	velocity = Vector3.ZERO


func apply_network_death() -> void:
	if is_dead:
		return
	is_dead = true
	if has_node("CollisionShape3D"):
		get_node("CollisionShape3D").disabled = true
	if hurtbox_collision_shape:
		hurtbox_collision_shape.disabled = true
	if mesh:
		mesh.visible = false
	if debug_label:
		debug_label.visible = false
	if _feedback_tween:
		_feedback_tween.kill()


func start_death_sequence() -> void:
	# Called from DyingState. Sets is_dead, hides visuals, plays death anim,
	# disables collisions, and starts the cleanup timer.
	# The timer timeout will then send "onDead" to Life.Dead and decompose.
	if is_dead:
		return
	is_dead = true
	if has_node("CollisionShape3D"):
		get_node("CollisionShape3D").disabled = true
	if hurtbox_collision_shape:
		hurtbox_collision_shape.disabled = true
	if mesh:
		mesh.visible = false
	if debug_label:
		debug_label.visible = false
	if _feedback_tween:
		_feedback_tween.kill()

	play_animation(&"death")

	death_timer.start(death_cleanup_delay)


# --- Debug ---
func set_debug_state(state_name: String) -> void:
	if debug_label:
		debug_label.text = state_name


# --- Internal ---
func _on_health_damaged(damage_request: Variant, _remaining: int) -> void:
	_play_hit_reaction()
	var damage_number: FloatingDamageNumber = FloatingDamageNumber.new()
	damage_number.setup(damage_request.amount)
	_get_feedback_parent().add_child(damage_number)
	var hit_position: Vector3 = damage_request.hit_position
	if hit_position == Vector3.ZERO:
		hit_position = global_position + Vector3.UP
	damage_number.global_position = hit_position + Vector3(0.0, 0.3, 0.0)
	play_animation(&"hurt")


func _on_health_died(_damage_request: Variant) -> void:
	# Life branch (parallel) owns death sequence. Send event to Dying.
	if state_chart:
		state_chart.send_event.call_deferred(&"onDying")


func _on_death_timer_timeout() -> void:
	# Send to Life.Dead then clean up.
	if state_chart:
		state_chart.send_event.call_deferred(&"onDead")
	decompose()


func _get_feedback_parent() -> Node:
	if Level.current_level and Level.current_level.has_node("Junk"):
		return Level.current_level.get_node("Junk")
	return get_parent()


func _restart_feedback_tween() -> void:
	if _feedback_tween:
		_feedback_tween.kill()
	if mesh:
		mesh.position = _base_mesh_position
		mesh.scale = _base_mesh_scale
		mesh.rotation = _base_mesh_rotation
	_feedback_tween = create_tween()


func _flash_material(color: Color, duration: float) -> void:
	if not _mesh_material or not mesh:
		return
	_mesh_material.albedo_color = color
	_feedback_tween.parallel().tween_property(_mesh_material, "albedo_color", _base_albedo_color, duration)


func _play_hit_reaction() -> void:
	if is_dead or not mesh:
		return
	_restart_feedback_tween()
	_feedback_tween.tween_property(mesh, "scale", Vector3(1.22, 0.75, 1.22), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_feedback_tween.tween_property(mesh, "scale", _base_mesh_scale, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_flash_material(Color(1.0, 0.16, 0.1, 1.0), 0.16)


func _on_health_damaged_for_state(_damage_request: Variant, _remaining: int) -> void:
	if is_dead or not state_chart or not is_network_authority:
		return
	state_chart.send_event(&"onHurt")


# Note: BasicEnemy compatibility uses direct "CollisionShape3D" child. New enemies use the same.
