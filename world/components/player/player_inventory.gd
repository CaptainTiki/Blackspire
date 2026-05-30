extends Node
class_name PlayerInventory

signal coins_changed(coins: int)

var coins := 0


func add_coins(amount: int) -> void:
	if amount <= 0:
		push_error("PlayerInventory.add_coins requires a positive amount.")
		return

	coins += amount
	coins_changed.emit(coins)
	print("PlayerInventory: coins = ", coins)


func get_level_exit_summary() -> String:
	return "Loot Secured: %d gold" % coins
