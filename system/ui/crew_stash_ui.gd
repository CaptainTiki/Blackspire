extends Control
class_name CrewStashUI

signal closed

enum SelectionColumn {
	PLAYER,
	STASH,
}

enum HeldSource {
	NONE,
	PLAYER,
	STASH,
}

const PLAYER_COLUMN_COUNT := 2
const STASH_COLUMN_COUNT := 4
const SLOT_BUTTON_SIZE := Vector2(118, 30)
const PANEL_SIZE := Vector2(760, 390)
const CONTROLLER_NAV_DEADZONE := 0.55
const CONTROLLER_NAV_INITIAL_DELAY := 0.32
const CONTROLLER_NAV_REPEAT_DELAY := 0.13

var player: PlayerController
var player_inventory: PlayerInventory
var player_hotbar: PlayerHotbar
var stash_inventory: Node
var is_controller_mode := false
var previous_mouse_mode := Input.MOUSE_MODE_CAPTURED

var selected_column := SelectionColumn.PLAYER
var selected_player_slot := 0
var selected_stash_slot := 0
var held_item_instance: Resource
var held_source := HeldSource.NONE
var held_source_slot := -1
var controller_nav_direction := Vector2i.ZERO
var controller_nav_repeat_timer := 0.0

var player_slot_buttons: Array[Button] = []
var stash_slot_buttons: Array[Button] = []
var held_label: Label
var details_label: Label
var feedback_label: Label


func configure(for_player: PlayerController, crew_stash: Node, controller_mode: bool) -> void:
	player = for_player
	player_inventory = player.inventory as PlayerInventory
	player_hotbar = player.hotbar as PlayerHotbar
	stash_inventory = crew_stash
	is_controller_mode = controller_mode

	if not player_inventory:
		push_error("CrewStashUI requires the player to have a PlayerInventory.")
	if not player_hotbar:
		push_error("CrewStashUI requires the player to have a PlayerHotbar.")
	if not stash_inventory:
		push_error("CrewStashUI requires a CrewStashInventory.")

	_build_ui()
	player_inventory.inventory_changed.connect(_refresh)
	stash_inventory.stash_changed.connect(_refresh)
	previous_mouse_mode = Input.get_mouse_mode()
	if not is_controller_mode:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	player.set_gameplay_input_enabled(false)
	player.set_controller_look_enabled(false)
	set_process(true)
	_refresh()


func _exit_tree() -> void:
	if is_instance_valid(player):
		player.set_gameplay_input_enabled(true)
		player.set_controller_look_enabled(true)
	if not is_controller_mode:
		Input.set_mouse_mode(previous_mouse_mode)


func _input(event: InputEvent) -> void:
	if not is_instance_valid(player):
		return
	if not player.input_reader.owns_input_event(event):
		return

	if event.is_action_pressed("inventory_pick_place") and not event is InputEventMouseButton:
		_activate_selected_slot()
		accept_event()
		return
	if event.is_action_pressed("inventory_cancel_drag") or event.is_action_pressed("toggle_equipment"):
		_try_close()
		accept_event()


func _process(delta: float) -> void:
	if held_item_instance:
		held_label.global_position = get_global_mouse_position() + Vector2(16, 16)
	if is_controller_mode:
		_process_controller_navigation(delta)


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var backdrop := ColorRect.new()
	backdrop.color = Color(0, 0, 0, 0.68)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = PANEL_SIZE
	center.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	panel.add_child(layout)

	var title_row := HBoxContainer.new()
	layout.add_child(title_row)

	var title := Label.new()
	title.text = "Crew Stash"
	title.add_theme_font_size_override("font_size", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	var close_button := Button.new()
	close_button.text = "Close"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(_try_close)
	title_row.add_child(close_button)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 14)
	layout.add_child(columns)

	columns.add_child(_build_slot_column("Backpack", PLAYER_COLUMN_COUNT, true))
	columns.add_child(_build_slot_column("Stash", STASH_COLUMN_COUNT, false))

	details_label = Label.new()
	details_label.text = "Select an item"
	details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_label.custom_minimum_size = Vector2(720, 42)
	layout.add_child(details_label)

	feedback_label = Label.new()
	feedback_label.visible = false
	layout.add_child(feedback_label)

	held_label = Label.new()
	held_label.visible = false
	held_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	held_label.z_index = 50
	add_child(held_label)


func _build_slot_column(title_text: String, columns: int, is_player_column: bool) -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)

	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 18)
	column.add_child(title)

	var grid := GridContainer.new()
	grid.columns = columns
	column.add_child(grid)

	var slot_count: int = player_inventory.get_backpack_slot_count() if is_player_column else stash_inventory.get_slot_count()
	for index in slot_count:
		var button := Button.new()
		button.custom_minimum_size = SLOT_BUTTON_SIZE
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		if is_player_column:
			button.mouse_entered.connect(_select_player_slot.bind(index))
			button.pressed.connect(_activate_player_slot.bind(index))
			player_slot_buttons.append(button)
		else:
			button.mouse_entered.connect(_select_stash_slot.bind(index))
			button.pressed.connect(_activate_stash_slot.bind(index))
			stash_slot_buttons.append(button)
		grid.add_child(button)

	return column


func _select_player_slot(index: int) -> void:
	if not _accepts_mouse_interaction():
		return
	selected_column = SelectionColumn.PLAYER
	selected_player_slot = index
	_refresh()


func _select_stash_slot(index: int) -> void:
	if not _accepts_mouse_interaction():
		return
	selected_column = SelectionColumn.STASH
	selected_stash_slot = index
	_refresh()


func _activate_player_slot(index: int) -> void:
	if not _accepts_mouse_interaction():
		return
	selected_column = SelectionColumn.PLAYER
	selected_player_slot = index
	_activate_selected_slot()


func _activate_stash_slot(index: int) -> void:
	if not _accepts_mouse_interaction():
		return
	selected_column = SelectionColumn.STASH
	selected_stash_slot = index
	_activate_selected_slot()


func _activate_selected_slot() -> void:
	match selected_column:
		SelectionColumn.PLAYER:
			_activate_player_inventory_slot(selected_player_slot)
		SelectionColumn.STASH:
			_activate_stash_inventory_slot(selected_stash_slot)
	_refresh()


func _activate_player_inventory_slot(index: int) -> void:
	if held_item_instance:
		held_item_instance = player_inventory.place_item_at(index, held_item_instance)
		if held_item_instance:
			held_source = HeldSource.PLAYER
			held_source_slot = index
		else:
			_clear_held()
		return

	held_item_instance = player_inventory.take_item_at(index)
	if held_item_instance:
		held_source = HeldSource.PLAYER
		held_source_slot = index
		player_hotbar.clear_bindings_for_item(held_item_instance)
	_update_held_label()


func _activate_stash_inventory_slot(index: int) -> void:
	if held_item_instance:
		held_item_instance = stash_inventory.place_item_at(index, held_item_instance)
		if held_item_instance:
			held_source = HeldSource.STASH
			held_source_slot = index
		else:
			_clear_held()
		return

	held_item_instance = stash_inventory.take_item_at(index)
	if held_item_instance:
		held_source = HeldSource.STASH
		held_source_slot = index
	_update_held_label()


func _try_close() -> void:
	if held_item_instance:
		_show_feedback("Place held item before closing")
		return

	closed.emit()
	queue_free()


func _process_controller_navigation(delta: float) -> void:
	var direction := _get_controller_navigation_direction()
	if direction == Vector2i.ZERO:
		controller_nav_direction = Vector2i.ZERO
		controller_nav_repeat_timer = 0.0
		return

	if direction != controller_nav_direction:
		controller_nav_direction = direction
		controller_nav_repeat_timer = CONTROLLER_NAV_INITIAL_DELAY
		_move_controller_selection(direction)
		return

	controller_nav_repeat_timer -= delta
	if controller_nav_repeat_timer <= 0.0:
		controller_nav_repeat_timer = CONTROLLER_NAV_REPEAT_DELAY
		_move_controller_selection(direction)


func _get_controller_navigation_direction() -> Vector2i:
	var movement := player.input_reader.get_movement_vector()
	if absf(movement.x) >= absf(movement.y):
		if movement.x > CONTROLLER_NAV_DEADZONE:
			return Vector2i.RIGHT
		if movement.x < -CONTROLLER_NAV_DEADZONE:
			return Vector2i.LEFT
	else:
		if movement.y > CONTROLLER_NAV_DEADZONE:
			return Vector2i.DOWN
		if movement.y < -CONTROLLER_NAV_DEADZONE:
			return Vector2i.UP

	return Vector2i.ZERO


func _move_controller_selection(direction: Vector2i) -> void:
	if direction.x != 0:
		selected_column = SelectionColumn.STASH if selected_column == SelectionColumn.PLAYER else SelectionColumn.PLAYER
	elif selected_column == SelectionColumn.PLAYER:
		selected_player_slot = _move_grid_index(selected_player_slot, direction.y, PLAYER_COLUMN_COUNT, player_slot_buttons.size())
	else:
		selected_stash_slot = _move_grid_index(selected_stash_slot, direction.y, STASH_COLUMN_COUNT, stash_slot_buttons.size())
	_refresh()


func _move_grid_index(index: int, direction: int, columns: int, item_count: int) -> int:
	return clampi(index + direction * columns, 0, item_count - 1)


func _refresh() -> void:
	for index in player_slot_buttons.size():
		var button := player_slot_buttons[index]
		button.text = _get_item_button_text(index, player_inventory.get_item_at(index))
		button.button_pressed = selected_column == SelectionColumn.PLAYER and selected_player_slot == index

	for index in stash_slot_buttons.size():
		var button := stash_slot_buttons[index]
		button.text = _get_item_button_text(index, stash_inventory.get_item_at(index))
		button.button_pressed = selected_column == SelectionColumn.STASH and selected_stash_slot == index

	_refresh_details()
	_update_held_label()


func _refresh_details() -> void:
	var item_instance: Resource = player_inventory.get_item_at(selected_player_slot) if selected_column == SelectionColumn.PLAYER else stash_inventory.get_item_at(selected_stash_slot)
	var slot_label := "Backpack" if selected_column == SelectionColumn.PLAYER else "Stash"
	var slot_index := selected_player_slot if selected_column == SelectionColumn.PLAYER else selected_stash_slot
	if not item_instance:
		details_label.text = "%s Slot %d\nEmpty slot" % [slot_label, slot_index + 1]
		return

	details_label.text = "%s Slot %d\n%s" % [slot_label, slot_index + 1, _format_item_instance(item_instance)]


func _get_item_button_text(index: int, item_instance: Resource) -> String:
	if not item_instance:
		return "%d: Empty" % (index + 1)

	return "%d: %s" % [index + 1, _format_item_instance(item_instance)]


func _format_item_instance(item_instance: Resource) -> String:
	if item_instance.quantity > 1:
		return "%s x%d" % [item_instance.get_display_name(), item_instance.quantity]

	return item_instance.get_display_name()


func _clear_held() -> void:
	held_item_instance = null
	held_source = HeldSource.NONE
	held_source_slot = -1
	_update_held_label()


func _update_held_label() -> void:
	if not held_label:
		return
	if not held_item_instance:
		held_label.visible = false
		held_label.text = ""
		return

	held_label.visible = not is_controller_mode
	held_label.text = "Holding %s" % _format_item_instance(held_item_instance)


func _show_feedback(message: String) -> void:
	feedback_label.text = message
	feedback_label.visible = true


func _accepts_mouse_interaction() -> bool:
	return player.input_reader.owns_mouse
