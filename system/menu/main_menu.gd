extends Control

## Extremely minimal main menu for Phase 1.
## Just four buttons. Functionality will be wired up over time.

@onready var single_player_button: Button = $VBoxContainer/SinglePlayerButton
@onready var local_coop_button: Button   = $VBoxContainer/LocalCoopButton
@onready var host_game_button: Button    = $VBoxContainer/HostGameButton
@onready var exit_button: Button         = $VBoxContainer/ExitButton

signal start_single_player_requested
signal start_local_coop_requested
signal host_game_requested
signal exit_requested

func _ready() -> void:
	single_player_button.pressed.connect(func(): start_single_player_requested.emit())
	local_coop_button.pressed.connect(  func(): start_local_coop_requested.emit())
	host_game_button.pressed.connect(   func(): host_game_requested.emit())
	exit_button.pressed.connect(        func(): exit_requested.emit())

	print("MainMenu: Ready (very basic version)")
