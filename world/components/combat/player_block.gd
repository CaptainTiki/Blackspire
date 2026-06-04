extends Node
class_name PlayerBlock

signal block_started(player: PlayerController)
signal block_finished(player: PlayerController)

const EquipmentDefinitionScript := preload("res://data/items/equipment_definition.gd")
const StatModifierDefinitionScript := preload("res://data/items/stat_modifier_definition.gd")
const PlayerEquipmentScript := preload("res://world/components/player/player_equipment.gd")

@export var player_components: PlayerComponents

var _is_blocking := false
var _pose_tween: Tween
var _sword_pivot: Node3D
var _original_rotation := Vector3.ZERO
var _shield_pivot: Node3D
var _shield_original_rotation := Vector3.ZERO
var current_shield_instance: Node = null

func _ready() -> void:
	if not player_components:
		push_error("PlayerBlock requires a PlayerComponents reference.")
	_find_sword_pivot()
	_find_shield_pivot()

	# Connect for secondary shield visuals (primary is handled in MeleeAttack)
	if player_components and player_components.equipment:
		var eq = player_components.equipment
		if eq.has_signal("equipment_changed"):
			if not eq.equipment_changed.is_connected(_on_equipment_changed):
				eq.equipment_changed.connect(_on_equipment_changed)
		# Check initial
		call_deferred("_check_initial_shield")

func _find_sword_pivot() -> void:
	if not player_components or not player_components.camerarig:
		return
	var ray := player_components.camerarig.ray_cast_3d
	if not ray:
		return
	var camera := ray.get_parent() as Camera3D
	if not camera:
		return
	_sword_pivot = camera.get_node_or_null("WeaponRoot/SwordPivot") as Node3D
	if _sword_pivot:
		_original_rotation = _sword_pivot.rotation

func _find_shield_pivot() -> void:
	if not player_components or not player_components.camerarig:
		return
	var ray := player_components.camerarig.ray_cast_3d
	if not ray:
		return
	var camera := ray.get_parent() as Camera3D
	if not camera:
		return
	_shield_pivot = camera.get_node_or_null("WeaponRoot/ShieldPivot") as Node3D
	if _shield_pivot:
		_shield_original_rotation = _shield_pivot.rotation

func can_block() -> bool:
	if _is_blocking:
		return false
	if not player_components or not player_components.player:
		return false
	if not player_components.player.can_act():
		return false
	var eq := player_components.equipment as PlayerEquipmentScript
	if not eq:
		return false
	var has_primary := eq.get_equipped(EquipmentDefinitionScript.EquipmentSlot.PRIMARY_WEAPON) != null
	var has_secondary := eq.get_equipped(EquipmentDefinitionScript.EquipmentSlot.SECONDARY_WEAPON) != null
	return has_primary or has_secondary

func start_block() -> bool:
	if not can_block():
		return false
	_is_blocking = true
	_start_pose()
	block_started.emit(player_components.player)
	return true

func stop_block() -> void:
	if not _is_blocking:
		return
	_is_blocking = false
	_stop_pose()
	block_finished.emit(player_components.player)

func cancel_block() -> void:
	if not _is_blocking:
		return
	_is_blocking = false
	if _pose_tween:
		_pose_tween.kill()
		_pose_tween = null
	if _sword_pivot:
		_sword_pivot.rotation = _original_rotation
	if _shield_pivot:
		_shield_pivot.rotation = _shield_original_rotation
	if current_shield_instance:
		# shield visual stays equipped, just restore pose
		pass
	block_finished.emit(player_components.player)

func is_blocking() -> bool:
	return _is_blocking

func apply_block_mitigation(incoming_after_armor: int) -> int:
	if not _is_blocking or incoming_after_armor <= 0:
		return incoming_after_armor
	var frac := _compute_block_fraction()
	if frac <= 0.0:
		return incoming_after_armor
	var reduced := roundi(float(incoming_after_armor) * (1.0 - frac))
	return maxi(reduced, 0)

func play_block_presentation() -> void:
	# Called on remote/presentation actors to show the pose without affecting authority mitigation.
	_start_pose()

func stop_block_presentation() -> void:
	_stop_pose()

func _compute_block_fraction() -> float:
	if not player_components or not player_components.equipment:
		return 0.0
	var eq := player_components.equipment as PlayerEquipmentScript
	# Secondary (shield) takes precedence
	var sec := eq.get_equipped(EquipmentDefinitionScript.EquipmentSlot.SECONDARY_WEAPON)
	if sec and sec.has_method("get_stat_modifier_total"):
		var b: float = sec.get_stat_modifier_total(StatModifierDefinitionScript.StatType.BLOCK)
		if b > 0.001:
			return clampf(b, 0.0, 1.0)
		return 0.5  # default for any item in secondary slot (bronze buckler baseline)
	# Primary weapon block
	var pri := eq.get_equipped(EquipmentDefinitionScript.EquipmentSlot.PRIMARY_WEAPON)
	if pri and pri.has_method("get_stat_modifier_total"):
		var b: float = pri.get_stat_modifier_total(StatModifierDefinitionScript.StatType.BLOCK)
		if b > 0.001:
			return clampf(b, 0.0, 1.0)
		return 0.25
	return 0.0

# --- Secondary shield visual support (for BLOCK in secondary slot) ---

func _on_equipment_changed(slot: int, definition: Resource) -> void:
	if slot == EquipmentDefinitionScript.EquipmentSlot.SECONDARY_WEAPON:
		_equip_shield(definition)

func _check_initial_shield() -> void:
	if not player_components or not player_components.equipment:
		return
	var eq := player_components.equipment as PlayerEquipmentScript
	if not eq:
		return
	var sec := eq.get_equipped(EquipmentDefinitionScript.EquipmentSlot.SECONDARY_WEAPON)
	if sec:
		_equip_shield(sec)

func _equip_shield(definition: Resource) -> void:
	if current_shield_instance:
		current_shield_instance.queue_free()
		current_shield_instance = null

	if not definition:
		return
	if not definition.has_method("get") or not "wielded_scene_path" in definition:
		return

	var wield_val: Variant = definition.get("wielded_scene_path")
	var wield_path: String = "" if wield_val == null else str(wield_val)
	if wield_path.is_empty():
		return

	var scn := load(wield_path) as PackedScene
	if not scn:
		push_error("PlayerBlock: Failed to load shield wielded scene '%s'." % wield_path)
		return

	if not _shield_pivot:
		_find_shield_pivot()
	if not _shield_pivot:
		push_error("PlayerBlock: No ShieldPivot found to attach shield visual.")
		return

	current_shield_instance = scn.instantiate()
	_shield_pivot.add_child(current_shield_instance)

func _is_using_shield_for_block() -> bool:
	if not player_components or not player_components.equipment:
		return false
	var eq := player_components.equipment as PlayerEquipmentScript
	var sec := eq.get_equipped(EquipmentDefinitionScript.EquipmentSlot.SECONDARY_WEAPON)
	if sec and sec.has_method("get_stat_modifier_total"):
		var b: float = sec.get_stat_modifier_total(StatModifierDefinitionScript.StatType.BLOCK)
		return b > 0.001
	return false

func _start_pose() -> void:
	if _is_using_shield_for_block():
		_start_shield_pose()
	else:
		_start_sword_pose()

func _start_sword_pose() -> void:
	if not _sword_pivot:
		_find_sword_pivot()
	if not _sword_pivot:
		return
	if _pose_tween:
		_pose_tween.kill()
	_pose_tween = create_tween()
	var target := Vector3(deg_to_rad(-52.0), deg_to_rad(18.0), 0.0)
	_pose_tween.tween_property(_sword_pivot, "rotation", target, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _start_shield_pose() -> void:
	if not _shield_pivot:
		_find_shield_pivot()
	if not _shield_pivot:
		return
	if _pose_tween:
		_pose_tween.kill()
	_pose_tween = create_tween()
	# Small round buckler: hold bottom/grip, top (face) toward enemies (forward).
	# Pose brings it up in front, face out. Adjust for left-hand offhand position.
	var target := Vector3(deg_to_rad(-25.0), deg_to_rad(-40.0), deg_to_rad(10.0))
	_pose_tween.tween_property(_shield_pivot, "rotation", target, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _stop_pose() -> void:
	if _pose_tween:
		_pose_tween.kill()
		_pose_tween = null
	if _is_using_shield_for_block() and _shield_pivot:
		_pose_tween = create_tween()
		_pose_tween.tween_property(_shield_pivot, "rotation", _shield_original_rotation, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	elif _sword_pivot:
		_pose_tween = create_tween()
		_pose_tween.tween_property(_sword_pivot, "rotation", _original_rotation, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
