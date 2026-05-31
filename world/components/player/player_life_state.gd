extends Node
class_name PlayerLifeState

signal bleeding_out_started(player: PlayerController)
signal died(player: PlayerController)
signal revived(player: PlayerController)

@export var player: PlayerController
@export var health_component: Node
@export var bleed_out_duration := 60.0
@export var revive_health := 25

var is_bleeding_out := false
var is_dead := false
var bleed_out_remaining_seconds := 0.0


func _ready() -> void:
	if not player:
		push_error("PlayerLifeState requires a player reference.")
	if not health_component:
		push_error("PlayerLifeState requires a health_component reference.")

	health_component.died.connect(_on_health_died)


func _process(delta: float) -> void:
	if not is_bleeding_out:
		return

	bleed_out_remaining_seconds = maxf(bleed_out_remaining_seconds - delta, 0.0)
	if bleed_out_remaining_seconds == 0.0:
		die()


func start_bleeding_out(_damage_request: Variant) -> void:
	if is_bleeding_out or is_dead:
		return

	is_bleeding_out = true
	bleed_out_remaining_seconds = bleed_out_duration
	player.enter_bleeding_out_state()
	bleeding_out_started.emit(player)

	if Level.current_level:
		Level.current_level.notify_player_bleeding_out(player)


func die() -> void:
	if is_dead:
		return

	is_dead = true
	is_bleeding_out = false
	bleed_out_remaining_seconds = 0.0
	player.enter_dead_state()
	died.emit(player)

	if Level.current_level:
		Level.current_level.notify_player_died(player)


func revive(health_amount: int = -1) -> void:
	if not is_bleeding_out and not is_dead:
		return

	var amount := revive_health if health_amount <= 0 else health_amount
	is_dead = false
	is_bleeding_out = false
	bleed_out_remaining_seconds = 0.0
	health_component.revive(amount)
	player.exit_bleeding_out_state()
	revived.emit(player)


func is_bleeding_out_or_dead() -> bool:
	return is_bleeding_out or is_dead


func _on_health_died(damage_request: Variant) -> void:
	start_bleeding_out(damage_request)
