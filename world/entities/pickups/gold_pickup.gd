@tool
extends "res://world/entities/pickups/pickup.gd"
class_name GoldPickup

@export var coin_amount := 5


func _func_godot_apply_properties(properties: Dictionary) -> void:
	super._func_godot_apply_properties(properties)

	if properties.has("coin_amount"):
		coin_amount = int(properties["coin_amount"])


func _apply_to_inventory(inventory: Node) -> void:
	inventory.add_coins(coin_amount)
