extends Entity
class_name Pedestal

## Pedestal that dispenses a configured item when interacted with.
## Keeps a rotating preview of the item on top.
## Has limited stock (or unlimited if -1).

@export var item_definition : Resource

@export var stock: int = -1 :
	set(value):
		stock = value
		if is_inside_tree():
			_remaining_stock = stock
			_update_display_visibility()

@export var rotation_speed: float = 1.5
@export var toss_impulse: float = 8.0
@export var toss_up_impulse: float = 4.0
@export var spawn_offset: Vector3 = Vector3(0, 1.0, 0.5)

var _remaining_stock: int = -1

@onready var interactable: Interactable = $Components/Interactable
@onready var item_display: Node3D = $ItemDisplay


func _ready() -> void:
	_remaining_stock = stock
	_apply_item_definition()
	_update_display_visibility()
	set_process(stock == -1 or _remaining_stock > 0)


func _process(delta: float) -> void:
	if item_display:
		item_display.rotate_y(delta * rotation_speed)


func _on_interact(_interactable: Interactable, actor: Node) -> void:
	if not _can_dispense():
		return
	print("remaining: ", _remaining_stock)
	_spawn_tossed_item()

	if stock != -1:
		_remaining_stock -= 1
		if _remaining_stock <= 0:
			_update_display_visibility()
			set_process(false)


func _can_dispense() -> bool:
	if stock == -1:
		return true
	return _remaining_stock > 0


func _apply_item_definition() -> void:
	_clear_item_display()

	if not item_definition:
		return
	var path_val: Variant = item_definition.get("world_pickup_scene_path")
	var has_path := path_val != null and str(path_val) != ""
	if not has_path:
		push_error("Pedestal %s: item_definition must have a world_pickup_scene_path." % get_path())
		return

	var path: String = str(path_val)
	if path.is_empty():
		push_warning("Pedestal %s: item_definition has no world_pickup_scene_path." % get_path())
		return

	var scene := load(path) as PackedScene
	if not scene:
		push_error("Pedestal %s: Failed to load pickup scene '%s'." % [get_path(), path])
		return

	var inst := scene.instantiate()
	item_display.add_child(inst)

	# Reset transform so the preview is centered and oriented nicely on the pedestal top,
	# regardless of the pickup scene's ground orientation. Meshes inside keep relative pose.
	inst.transform = Transform3D.IDENTITY

	# Make it a static display only (strip physics and interaction)
	if inst is RigidBody3D:
		inst.freeze = true
		inst.collision_layer = 0
		inst.collision_mask = 0

	# Disable any collision shapes
	for cs in inst.find_children("*", "CollisionShape3D", true, false):
		if cs is CollisionShape3D:
			cs.disabled = true

	# Remove the interactable component so it doesn't fight with the pedestal's
	var components := inst.get_node_or_null("Components")
	if components:
		var inter := components.get_node_or_null("Interactable")
		if inter:
			inter.queue_free()

	# Optional: update prompt from item
	if interactable:
		var dname := ""
		if item_definition:
			var dn = item_definition.get("display_name")
			if dn != null:
				dname = str(dn)
		interactable.prompt = "Take %s" % dname if dname != "" else "Acquire Item"


func _clear_item_display() -> void:
	for child in item_display.get_children():
		child.queue_free()


func _update_display_visibility() -> void:
	if item_display:
		var show := stock == -1 or _remaining_stock > 0
		item_display.visible = show


func _spawn_tossed_item() -> void:
	if not item_definition:
		push_error("Pedestal %s has no item_definition to spawn." % get_path())
		return

	var path_val2: Variant = item_definition.get("world_pickup_scene_path")
	var path: String = "" if path_val2 == null else str(path_val2)
	if path.is_empty():
		push_error("Pedestal %s item has no world_pickup_scene_path." % get_path())
		return

	var scene := load(path) as PackedScene
	if not scene:
		push_error("Pedestal %s: Failed to load spawn scene '%s'." % [get_path(), path])
		return

	var pickup := scene.instantiate() as Node3D
	if not pickup:
		return

	var parent := get_parent()
	if not parent:
		parent = get_tree().current_scene
	parent.add_child(pickup)

	var forward := -global_transform.basis.z.normalized()
	var spawn_pos := global_position + spawn_offset + forward * 0.3
	pickup.global_position = spawn_pos
	# Keep roughly the orientation of the pedestal or let the pickup have its own

	if pickup is RigidBody3D:
		var body := pickup as RigidBody3D
		body.freeze = false
		var impulse := forward * toss_impulse + Vector3.UP * toss_up_impulse
		body.apply_central_impulse(impulse)
		# Add a little spin for nice toss
		body.apply_torque_impulse(Vector3(
			randf_range(-1.5, 1.5),
			randf_range(4.0, 7.0),
			randf_range(-1.5, 1.5)
		))
