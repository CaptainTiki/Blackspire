extends Node3D
class_name Main

## Main is the true root of the application.
## It owns the menu system and can create/destroy Game sessions.

@export var main_menu_scene: PackedScene = preload("res://system/menu/main_menu.tscn")

var current_menu: Control
var current_game: Game

func _ready() -> void:
	_show_main_menu()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Allow escaping the mouse for now during development
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

## Shows the main menu
func _show_main_menu() -> void:
	if current_game:
		current_game.queue_free()
		current_game = null

	if main_menu_scene:
		current_menu = main_menu_scene.instantiate()
		add_child(current_menu)

		# Connect menu signals (we'll expand these)
		if current_menu.has_signal("start_single_player_requested"):
			current_menu.start_single_player_requested.connect(_on_start_single_player)
		if current_menu.has_signal("start_local_coop_requested"):
			current_menu.start_local_coop_requested.connect(_on_start_local_coop)
		if current_menu.has_signal("host_game_requested"):
			current_menu.host_game_requested.connect(_on_host_game)
		if current_menu.has_signal("join_game_requested"):
			current_menu.join_game_requested.connect(_on_join_game)
		if current_menu.has_signal("exit_requested"):
			current_menu.exit_requested.connect(_on_exit_requested)
	else:
		push_error("Main: No main_menu_scene assigned!")

func _on_start_single_player() -> void:
	print("Main: Starting Single Player session")
	_start_game_session(GameSessionConfig.SessionType.SINGLE_PLAYER, 1)

func _on_start_local_coop() -> void:
	print("Main: Starting Local Co-op session (2 players)")
	_start_game_session(GameSessionConfig.SessionType.LOCAL_COOP, 2)

func _on_host_game() -> void:
	print("Main: Starting Multiplayer Host session")
	_start_game_session(GameSessionConfig.SessionType.MULTIPLAYER_HOST, 1)

func _on_join_game(address: String, port: int) -> void:
	print("Main: Starting Multiplayer Client session for %s:%d" % [address, port])
	var config := _create_session_config(GameSessionConfig.SessionType.MULTIPLAYER_CLIENT, 1)
	config.host_address = address
	config.host_port = port
	_start_configured_game_session(config)

func _on_exit_requested() -> void:
	get_tree().quit()

func _start_game_session(session_type: GameSessionConfig.SessionType, player_count: int) -> void:
	var config := _create_session_config(session_type, player_count)
	_start_configured_game_session(config)


func _create_session_config(session_type: GameSessionConfig.SessionType, player_count: int) -> GameSessionConfig:
	var config := GameSessionConfig.new()
	config.session_type = session_type
	config.local_player_count = player_count
	if session_type == GameSessionConfig.SessionType.LOCAL_COOP:
		config.max_player_count = max(config.max_player_count, player_count)
	return config


func _start_configured_game_session(config: GameSessionConfig) -> void:
	# Remove menu
	if current_menu:
		current_menu.queue_free()
		current_menu = null

	# Load the Game scene
	var game_scene := preload("res://system/game/game.tscn")
	current_game = game_scene.instantiate() as Game
	add_child(current_game)

	current_game.start_session(config)
