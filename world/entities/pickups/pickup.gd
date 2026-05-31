@tool
extends Entity
class_name Pickup

signal collected(actor: Node)

@export var pickup_id: StringName = &"pickup"
@export var display_name := "Pickup"
@export var weight := 0

var is_collected := false

@onready var interactable: Interactable = $Components/Interactable


func setup_from_item_instance(item_instance: Resource) -> void:
	if not item_instance:
		push_error("Pickup.setup_from_item_instance requires an item instance.")
		return
	if not item_instance.item_definition:
		push_error("Pickup.setup_from_item_instance requires an item definition.")
		return

	pickup_id = item_instance.item_definition.id
	display_name = item_instance.item_definition.display_name
	_apply_display_state()


func _ready() -> void:
	_apply_display_state()


func _func_godot_apply_properties(properties: Dictionary) -> void:
	if properties.has("pickup_id"):
		pickup_id = StringName(properties["pickup_id"])
	if properties.has("display_name"):
		display_name = str(properties["display_name"])
	if properties.has("weight"):
		weight = int(properties["weight"])

	if interactable:
		_apply_display_state()


func _on_interact(_interactable: Interactable, actor: Node) -> void:
	collect(actor)


func collect(actor: Node) -> void:
	if is_collected:
		return

	var inventory := _get_player_inventory(actor)
	if not inventory:
		return

	if not _apply_to_inventory(inventory):
		return

	is_collected = true
	collected.emit(actor)
	queue_free()


func _apply_to_inventory(_inventory: Node) -> bool:
	push_error("Pickup subclass '%s' must implement _apply_to_inventory()." % get_class())
	return false


func _apply_display_state() -> void:
	if not interactable:
		return

	interactable.prompt = "Take %s" % display_name


func _get_player_inventory(actor: Node) -> Node:
	var player := actor as PlayerController
	if not player:
		push_error("Pickup '%s' can only be collected by a PlayerController." % display_name)
		return null

	return player.get_inventory()
