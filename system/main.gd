extends Node3D
class_name Main

## Main bootstrapper for the game.
## Responsibilities:
## - Load the current level/world
## - Spawn the player
## - Handle global input (mouse capture, quit, etc.)

@export var starting_level: PackedScene = preload("res://world/levels/test_level.tscn")
@export var player_scene: PackedScene = preload("res://world/actors/player/Player.tscn")

var current_level: BaseLevel
var player: PlayerController

func _ready() -> void:
	# Capture mouse on game start
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	_load_starting_level()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			get_tree().quit()

func _load_starting_level() -> void:
	if not starting_level:
		push_error("No starting level assigned in Main!")
		return
	
	current_level = starting_level.instantiate() as BaseLevel
	if not current_level:
		push_error("Starting level is not a BaseLevel!")
		return
	
	add_child(current_level)
	
	# Wait until the level says it's ready
	if current_level.has_signal("level_ready"):
		current_level.level_ready.connect(_on_level_ready, CONNECT_ONE_SHOT)
	else:
		# Fallback if signal doesn't exist
		call_deferred("_on_level_ready")

func _on_level_ready() -> void:
	# Delegate player spawning to the level (keeps spawn logic with the world)
	if current_level and player_scene:
		player = current_level.spawn_player(player_scene)
		if player:
			print("Player successfully spawned by level: ", current_level.level_name)
		else:
			push_warning("Level did not spawn a player.")
	else:
		push_error("Cannot spawn player - missing level or player scene.")
