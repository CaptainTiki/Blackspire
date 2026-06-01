extends Node3D
class_name InteractionScanner

signal focus_changed(prompt: String)

## Always-active raycast interaction system.
## Attach this under the player's Components node.

@export var interaction_distance: float = 2.0
@export var player_components: PlayerComponents

const INTERACTION_RAY_MASK := 0b000011

var raycast: RayCast3D = null
var current_interactable: Interactable = null

func _ready() -> void:
	if not player_components:
		push_error("InteractionScanner requires a PlayerComponents reference.")
	raycast = player_components.camerarig.ray_cast_3d
	# Configure the raycast
	raycast.target_position = Vector3(0, 0, -interaction_distance)
	raycast.enabled = true
	raycast.collide_with_areas = true
	raycast.collide_with_bodies = true
	raycast.collision_mask = INTERACTION_RAY_MASK

func _physics_process(_delta: float) -> void:
	_update_interactable()

func _update_interactable() -> void:
	var previous: Interactable = null
	if is_instance_valid(current_interactable):
		previous = current_interactable
	else:
		current_interactable = null
	
	var next_interactable: Interactable = null
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		next_interactable = _find_interactable_on_node(collider)

	if not is_instance_valid(next_interactable):
		next_interactable = null

	current_interactable = next_interactable
	
	if current_interactable != previous:
		_on_interactable_changed(previous, current_interactable)

func _find_interactable_on_node(node: Node) -> Interactable:
	if not is_instance_valid(node):
		return null
	
	# Check the collider itself
	if node.has_node("Components/Interactable"):
		var interactable := node.get_node("Components/Interactable") as Interactable
		return interactable if is_instance_valid(interactable) else null
	
	# Also check if the node itself has an Interactable child (more flexible)
	for child in node.get_children():
		if is_instance_valid(child) and child is Interactable:
			return child
	
	return null

func _on_interactable_changed(previous: Interactable, new: Interactable) -> void:
	if is_instance_valid(previous):
		previous.focus_lost.emit()
	
	if is_instance_valid(new):
		new.focus_gained.emit()
		focus_changed.emit(new.prompt)
	else:
		focus_changed.emit("")

func try_interact() -> void:
	if not player_components.player.can_act():
		return

	if current_interactable and is_instance_valid(current_interactable):
		current_interactable.interact(player_components.player)  # Pass the player as the actor

func _unhandled_input(_event: InputEvent) -> void:
	# Input must come through the per-player PlayerInput component.
	# Missing wiring will cause a hard error here — this is intentional ("fail loudly").
	if player_components.input.is_interact_just_pressed():
		try_interact()
