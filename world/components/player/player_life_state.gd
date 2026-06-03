extends Node
class_name PlayerLifeState

signal bleeding_out_started(player: PlayerController)
signal died(player: PlayerController)
signal revived(player: PlayerController)
signal life_snapshot_changed(snapshot: Dictionary)

@export var player: PlayerController
@export var health_component: Node
@export var bleed_out_duration := 60.0
@export var revive_health := 25

enum LifeMode {
	DEPLOYING,
	ALIVE,
	DOWNED,
	DEAD,
}

const LIFE_MODE_KEYS := {
	LifeMode.DEPLOYING: "deploying",
	LifeMode.ALIVE: "alive",
	LifeMode.DOWNED: "downed",
	LifeMode.DEAD: "dead",
}

var current_mode := LifeMode.DEPLOYING
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
	player.state_chart.send_event(&"onDowned")
	bleeding_out_started.emit(player)
	_emit_life_snapshot_changed()

	if Level.current_level:
		Level.current_level.notify_player_bleeding_out(player)


func die() -> void:
	if is_dead:
		return

	is_dead = true
	is_bleeding_out = false
	bleed_out_remaining_seconds = 0.0
	player.state_chart.send_event(&"onDead")
	died.emit(player)
	_emit_life_snapshot_changed()

	if Level.current_level:
		Level.current_level.notify_player_died(player)


func revive(health_amount: int = -1) -> void:
	if is_dead:
		return
	if not is_bleeding_out:
		return

	var amount := revive_health if health_amount <= 0 else health_amount
	bleed_out_remaining_seconds = 0.0
	health_component.revive(amount)
	player.state_chart.send_event(&"onAlive")
	revived.emit(player)
	_emit_life_snapshot_changed()


func is_bleeding_out_or_dead() -> bool:
	return is_bleeding_out or is_dead


func enter_deploying() -> void:
	current_mode = LifeMode.DEPLOYING
	_emit_life_snapshot_changed()


func complete_deploying() -> void:
	if current_mode != LifeMode.DEPLOYING:
		return
	player.state_chart.send_event(&"onAlive")


func enter_alive() -> void:
	current_mode = LifeMode.ALIVE
	is_dead = false
	is_bleeding_out = false
	bleed_out_remaining_seconds = 0.0
	player.exit_bleeding_out_state()
	_emit_life_snapshot_changed()


func enter_downed() -> void:
	current_mode = LifeMode.DOWNED
	is_dead = false
	is_bleeding_out = true
	_emit_life_snapshot_changed()


func enter_dead() -> void:
	current_mode = LifeMode.DEAD
	is_dead = true
	is_bleeding_out = false
	bleed_out_remaining_seconds = 0.0
	_emit_life_snapshot_changed()


func get_life_snapshot() -> Dictionary:
	return {
		"life_state": get_life_state_key(),
		"health": health_component.current_health,
		"max_health": health_component.max_health,
		"is_bleeding_out": is_bleeding_out,
		"is_dead": is_dead,
		"bleed_out_remaining_seconds": bleed_out_remaining_seconds,
	}


func get_life_state_key() -> String:
	return LIFE_MODE_KEYS.get(current_mode, "unknown")


func _emit_life_snapshot_changed() -> void:
	life_snapshot_changed.emit(get_life_snapshot())


func _on_health_died(damage_request: Variant) -> void:
	start_bleeding_out(damage_request)
