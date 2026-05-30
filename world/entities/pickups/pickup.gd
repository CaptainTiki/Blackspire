@tool
extends Entity
class_name Pickup

signal collected(actor: Node)

@export var pickup_id: StringName = &"pickup"
@export var display_name := "Pickup"
@export var weight := 0

var is_collected := false

@onready var interactable: Interactable = $Components/Interactable


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

	_apply_to_inventory(inventory)
	is_collected = true
	collected.emit(actor)
	queue_free()


func _apply_to_inventory(_inventory: Node) -> void:
	push_error("Pickup subclass '%s' must implement _apply_to_inventory()." % get_class())


func _apply_display_state() -> void:
	interactable.prompt = "Take %s" % display_name


func _get_player_inventory(actor: Node) -> Node:
	var player := actor as PlayerController
	if not player:
		push_error("Pickup '%s' can only be collected by a PlayerController." % display_name)
		return null

	return player.get_inventory()
