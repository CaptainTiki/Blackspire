extends Node3D
class_name InteractionScanner

signal focus_changed(prompt: String)

@export var interaction_distance: float = 2.0
@export var player_components: PlayerComponents

const WORLD_LAYER_MASK := 1 << 0
const INTERACTABLE_LAYER_MASK := 1 << 1
const PLAYER_LAYER_MASK := 1 << 4
const INTERACTION_RAY_MASK := WORLD_LAYER_MASK | INTERACTABLE_LAYER_MASK | PLAYER_LAYER_MASK
const INTERACTION_NONE := &"none"
const INTERACTION_INTERACT := &"interact"
const INTERACTION_REVIVE := &"revive"
const INTERACTION_EXTRACT := &"extract"

var raycast: RayCast3D = null
var current_interactable: Interactable = null
var current_revive_target: PlayerController = null


func _ready() -> void:
	if not player_components:
		push_error("InteractionScanner requires a PlayerComponents reference.")
	raycast = player_components.camerarig.ray_cast_3d
	raycast.target_position = Vector3(0, 0, -interaction_distance)
	raycast.enabled = true
	raycast.collide_with_areas = true
	raycast.collide_with_bodies = true
	raycast.collision_mask = INTERACTION_RAY_MASK
	raycast.add_exception(player_components.player)


func _physics_process(_delta: float) -> void:
	_update_interactable()


func _update_interactable() -> void:
	var previous: Interactable = null
	if is_instance_valid(current_interactable):
		previous = current_interactable
	else:
		current_interactable = null

	var previous_revive_target: PlayerController = null
	if is_instance_valid(current_revive_target):
		previous_revive_target = current_revive_target
	else:
		current_revive_target = null

	var next_interactable: Interactable = null
	var next_revive_target: PlayerController = null
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		next_revive_target = _find_revive_target_on_node(collider)
		if not next_revive_target:
			next_interactable = _find_interactable_on_node(collider)

	if not is_instance_valid(next_interactable):
		next_interactable = null
	if not is_instance_valid(next_revive_target):
		next_revive_target = null

	current_interactable = next_interactable
	current_revive_target = next_revive_target

	if current_interactable != previous or current_revive_target != previous_revive_target:
		_on_focus_target_changed(previous, current_interactable, previous_revive_target, current_revive_target)


func _find_interactable_on_node(node: Node) -> Interactable:
	if not is_instance_valid(node):
		return null

	if node.has_node("Components/Interactable"):
		var interactable := node.get_node("Components/Interactable") as Interactable
		return interactable if is_instance_valid(interactable) else null

	for child in node.get_children():
		if is_instance_valid(child) and child is Interactable:
			return child

	return null


func _find_revive_target_on_node(node: Node) -> PlayerController:
	var player := node as PlayerController
	if not player:
		player = node.get_parent() as PlayerController
	if not player:
		return null
	if player == player_components.player:
		return null
	if not player.life_state.is_bleeding_out:
		return null

	return player


func _on_focus_target_changed(previous: Interactable, new: Interactable, _previous_revive_target: PlayerController, new_revive_target: PlayerController) -> void:
	if is_instance_valid(previous):
		previous.focus_lost.emit()

	if is_instance_valid(new_revive_target):
		focus_changed.emit("Revive %s" % new_revive_target.name)
		return

	if is_instance_valid(new):
		new.focus_gained.emit()
		focus_changed.emit(new.prompt)
	else:
		focus_changed.emit("")


func try_interact() -> void:
	match get_current_interaction_kind():
		INTERACTION_REVIVE:
			try_revive()
		INTERACTION_EXTRACT:
			try_extract()
		INTERACTION_INTERACT:
			try_standard_interact()


func try_standard_interact() -> void:
	if not can_standard_interact():
		return

	current_interactable.interact(player_components.player)


func try_revive() -> void:
	if not can_revive():
		return

	current_revive_target.life_state.revive()


func try_extract() -> void:
	if not can_extract():
		return

	current_interactable.interact(player_components.player)


func can_interact() -> bool:
	return get_current_interaction_kind() != INTERACTION_NONE


func can_standard_interact() -> bool:
	return (
		player_components.player.can_act()
		and current_interactable
		and is_instance_valid(current_interactable)
		and not can_extract()
	)


func can_revive() -> bool:
	return (
		player_components.player.can_act()
		and current_revive_target
		and is_instance_valid(current_revive_target)
	)


func can_extract() -> bool:
	if not player_components.player.can_act():
		return false
	if not current_interactable or not is_instance_valid(current_interactable):
		return false

	return current_interactable.get_parent_entity() is ExitPortal


func get_current_interaction_kind() -> StringName:
	if can_revive():
		return INTERACTION_REVIVE
	if can_extract():
		return INTERACTION_EXTRACT
	if can_standard_interact():
		return INTERACTION_INTERACT

	return INTERACTION_NONE
