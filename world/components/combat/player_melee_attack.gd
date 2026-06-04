extends Node
class_name PlayerMeleeAttack

signal primary_action_started(player: PlayerController)
signal attack_presentation_started(player: PlayerController)
signal attack_finished(player: PlayerController)
signal damage_area_hit(player: PlayerController, area: Area3D, damage_amount: int, hit_position: Vector3)

const DamageRequestScript := preload("res://world/components/combat/damage_request.gd")
const EquipmentDefinitionScript := preload("res://data/items/equipment_definition.gd")
const PlayerEquipmentScript := preload("res://world/components/player/player_equipment.gd")

@export var player_components: PlayerComponents
@export var attack_damage := 10
@export var active_delay := 0.08
@export var active_duration := 0.16

const COMBAT_HURTBOX_LAYER := 0b000100
const WEAPON_HITBOX_LAYER := 0b001000

@onready var camera: Camera3D = player_components.camerarig.ray_cast_3d.get_parent()
@onready var animation_player: AnimationPlayer = camera.get_node("WeaponRoot/AnimationPlayer")

var hitbox: Area3D = null
var current_wielded_instance: Node = null

var _is_attacking := false
var _hit_targets: Array[Node] = []
var _attack_sequence := 0


func _ready() -> void:
	if not player_components:
		push_error("PlayerMeleeAttack requires a PlayerComponents reference.")

	# Hitbox and visual are provided dynamically when a primary weapon is equipped.
	# Connect to equipment changes so we can show/hide/instantiate the wielded sword + hitbox.
	if player_components.equipment:
		var eq := player_components.equipment
		if eq.has_signal("equipment_changed"):
			if not eq.equipment_changed.is_connected(_on_equipment_changed):
				eq.equipment_changed.connect(_on_equipment_changed)

	# Check if something is already equipped (e.g. debug setups or future starting gear).
	call_deferred("_check_initial_primary_weapon")


func can_attack() -> bool:
	if _is_attacking:
		return false
	if not player_components or not player_components.player:
		return false
	if not player_components.player.can_act():
		return false
	if not hitbox or not current_wielded_instance:
		# No primary weapon equipped in the slot -> no visual/functional sword in hand.
		return false
	return true


func attack() -> bool:
	if not can_attack():
		return false

	_run_attack()
	return true


func play_attack_presentation() -> void:
	if _is_attacking:
		return

	_is_attacking = true
	_attack_sequence += 1
	var attack_sequence := _attack_sequence
	animation_player.play("attack")
	attack_presentation_started.emit(player_components.player)
	await animation_player.animation_finished
	if attack_sequence != _attack_sequence:
		return
	_is_attacking = false


func cancel_attack() -> void:
	if not _is_attacking:
		if hitbox:
			hitbox.monitoring = false
		return

	_attack_sequence += 1
	_is_attacking = false
	_hit_targets.clear()
	if hitbox:
		hitbox.monitoring = false
	animation_player.stop()
	attack_finished.emit(player_components.player)


func is_attacking() -> bool:
	return _is_attacking


func _run_attack() -> void:
	_is_attacking = true
	_attack_sequence += 1
	var attack_sequence := _attack_sequence
	_hit_targets.clear()
	primary_action_started.emit(player_components.player)
	animation_player.play("attack")
	attack_presentation_started.emit(player_components.player)

	await get_tree().create_timer(active_delay).timeout
	if attack_sequence != _attack_sequence:
		return
	if hitbox:
		hitbox.monitoring = true
	await get_tree().physics_frame
	if attack_sequence != _attack_sequence:
		return

	if hitbox:
		for area in hitbox.get_overlapping_areas():
			_try_damage_area(area)

	await get_tree().create_timer(active_duration).timeout
	if attack_sequence != _attack_sequence:
		return
	if hitbox:
		hitbox.monitoring = false

	await animation_player.animation_finished
	if attack_sequence != _attack_sequence:
		return
	_is_attacking = false
	attack_finished.emit(player_components.player)


func _on_hitbox_area_entered(area: Area3D) -> void:
	_try_damage_area(area)


func _try_damage_area(area: Area3D) -> void:
	if not area.has_method("apply_damage"):
		return

	if _hit_targets.has(area):
		return

	_hit_targets.append(area)
	var hit_position := _get_feedback_hit_position(area)
	var damage_amount := get_attack_damage()
	var damage_request := DamageRequestScript.new(player_components.player, damage_amount, hit_position)
	area.apply_damage(damage_request)
	damage_area_hit.emit(player_components.player, area, damage_amount, hit_position)


func get_attack_damage() -> int:
	var total_damage := float(attack_damage)

	if player_components.equipment:
		total_damage += player_components.equipment.get_attack_damage_modifier()

	return maxi(roundi(total_damage), 0)


func equip_primary_weapon(definition: Resource) -> void:
	# Cleanup previous wielded visual + hitbox.
	if current_wielded_instance:
		current_wielded_instance.queue_free()
		current_wielded_instance = null
	_setup_hitbox(null)

	if not definition:
		return
	if not definition.has_method("get_stat_modifier_total") or not "wielded_scene_path" in definition:
		return

	var wield_path: String = definition.wielded_scene_path
	if wield_path.is_empty():
		return

	var scn := load(wield_path) as PackedScene
	if not scn:
		push_error("PlayerMeleeAttack: Failed to load wielded scene '%s' for primary weapon." % wield_path)
		return

	# Find the pivot (SwordPivot is the animated attachment point).
	var pivot := camera.get_node_or_null("WeaponRoot/SwordPivot") as Node3D
	if not pivot:
		push_error("PlayerMeleeAttack: No SwordPivot found under WeaponRoot to attach wielded weapon visual.")
		return

	current_wielded_instance = scn.instantiate()
	pivot.add_child(current_wielded_instance)

	# The wielded scene should contain a "SwordHitbox" (Area3D) as a direct or findable child.
	var new_hitbox := current_wielded_instance.find_child("SwordHitbox", true, false) as Area3D
	if not new_hitbox:
		new_hitbox = current_wielded_instance.find_child("*Hitbox*", true, false) as Area3D

	if new_hitbox:
		_setup_hitbox(new_hitbox)
	else:
		push_warning("PlayerMeleeAttack: Wielded scene '%s' did not provide a SwordHitbox child." % wield_path)


func _on_equipment_changed(slot: int, definition: Resource) -> void:
	if slot != EquipmentDefinitionScript.EquipmentSlot.PRIMARY_WEAPON:
		return
	equip_primary_weapon(definition)


func _check_initial_primary_weapon() -> void:
	if not player_components or not player_components.equipment:
		return
	var eq := player_components.equipment as PlayerEquipmentScript
	if not eq:
		return
	var primary := eq.get_equipped(EquipmentDefinitionScript.EquipmentSlot.PRIMARY_WEAPON)
	if primary:
		equip_primary_weapon(primary)


func _setup_hitbox(new_hitbox: Area3D) -> void:
	if hitbox and hitbox.area_entered.is_connected(_on_hitbox_area_entered):
		hitbox.area_entered.disconnect(_on_hitbox_area_entered)

	hitbox = new_hitbox
	if hitbox:
		hitbox.monitoring = false
		hitbox.monitorable = false
		hitbox.collision_layer = WEAPON_HITBOX_LAYER
		hitbox.collision_mask = COMBAT_HURTBOX_LAYER
		if not hitbox.area_entered.is_connected(_on_hitbox_area_entered):
			hitbox.area_entered.connect(_on_hitbox_area_entered)


func _get_feedback_hit_position(area: Area3D) -> Vector3:
	var hit_position := area.global_position
	var collision_shape := area.find_child("CollisionShape3D", false, false) as CollisionShape3D
	if collision_shape:
		hit_position = collision_shape.global_position

	var from_camera := (camera.global_position - hit_position).normalized()
	return hit_position + (from_camera * 0.35)
