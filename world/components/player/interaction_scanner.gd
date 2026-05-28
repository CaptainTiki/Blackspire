extends Node3D
class_name InteractionScanner

## Always-active raycast interaction system.
## Attach this under the player's Components node.

@export var interaction_distance: float = 2.0
@export var player_components: PlayerComponents

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

func _physics_process(_delta: float) -> void:
	_update_interactable()

func _update_interactable() -> void:
	var previous = current_interactable
	
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		current_interactable = _find_interactable_on_node(collider)
	else:
		current_interactable = null
	
	if current_interactable != previous:
		_on_interactable_changed(previous, current_interactable)

func _find_interactable_on_node(node: Node) -> Interactable:
	if not node:
		return null
	
	# Check the collider itself
	if node.has_node("Components/Interactable"):
		return node.get_node("Components/Interactable") as Interactable
	
	# Also check if the node itself has an Interactable child (more flexible)
	for child in node.get_children():
		if child is Interactable:
			return child
	
	return null

func _on_interactable_changed(previous: Interactable, new: Interactable) -> void:
	if previous:
		previous.focus_lost.emit()
	
	if new:
		new.focus_gained.emit()
		# TODO: Show interaction prompt in UI

func try_interact() -> void:
	if current_interactable and is_instance_valid(current_interactable):
		current_interactable.interact(player_components.player)  # Pass the player as the actor

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		try_interact()
