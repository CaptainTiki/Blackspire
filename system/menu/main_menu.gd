extends Control

## Extremely minimal main menu for Phase 1.
## Functionality will be wired up over time.

@onready var single_player_button: Button = $VBoxContainer/SinglePlayerButton
@onready var local_coop_button: Button   = $VBoxContainer/LocalCoopButton
@onready var host_game_button: Button    = $VBoxContainer/HostGameButton
@onready var join_game_button: Button    = $VBoxContainer/JoinGameButton
@onready var exit_button: Button         = $VBoxContainer/ExitButton
@onready var join_popup: PopupPanel      = $JoinPopup
@onready var join_address_input: LineEdit = $JoinPopup/MarginContainer/VBoxContainer/AddressInput
@onready var join_port_input: SpinBox    = $JoinPopup/MarginContainer/VBoxContainer/PortInput
@onready var join_confirm_button: Button = $JoinPopup/MarginContainer/VBoxContainer/ButtonRow/JoinButton
@onready var join_cancel_button: Button  = $JoinPopup/MarginContainer/VBoxContainer/ButtonRow/CancelButton

signal start_single_player_requested
signal start_local_coop_requested
signal host_game_requested
signal join_game_requested(address: String, port: int)
signal exit_requested

func _ready() -> void:
	single_player_button.pressed.connect(func(): start_single_player_requested.emit())
	local_coop_button.pressed.connect(  func(): start_local_coop_requested.emit())
	host_game_button.pressed.connect(   func(): host_game_requested.emit())
	join_game_button.pressed.connect(_show_join_popup)
	join_confirm_button.pressed.connect(_confirm_join_game)
	join_cancel_button.pressed.connect(func(): join_popup.hide())
	exit_button.pressed.connect(        func(): exit_requested.emit())

	print("MainMenu: Ready (very basic version)")


func _show_join_popup() -> void:
	join_address_input.text = "127.0.0.1"
	join_port_input.value = 24545
	join_popup.popup_centered()
	join_address_input.grab_focus()
	join_address_input.select_all()


func _confirm_join_game() -> void:
	var address := join_address_input.text.strip_edges()
	if address.is_empty():
		address = "127.0.0.1"

	join_popup.hide()
	join_game_requested.emit(address, int(join_port_input.value))
