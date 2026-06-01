extends CanvasLayer
class_name PlayerEquipmentUI

const EquipmentDefinitionScript := preload("res://data/items/equipment_definition.gd")
const ItemInstanceScript := preload("res://data/items/item_instance.gd")
const StatModifierDefinitionScript := preload("res://data/items/stat_modifier_definition.gd")

const SLOT_ORDER := [
	EquipmentDefinitionScript.EquipmentSlot.PRIMARY_WEAPON,
	EquipmentDefinitionScript.EquipmentSlot.SECONDARY_WEAPON,
	EquipmentDefinitionScript.EquipmentSlot.HEAD,
	EquipmentDefinitionScript.EquipmentSlot.CHEST,
	EquipmentDefinitionScript.EquipmentSlot.HANDS,
	EquipmentDefinitionScript.EquipmentSlot.LEGS,
	EquipmentDefinitionScript.EquipmentSlot.FEET,
	EquipmentDefinitionScript.EquipmentSlot.ACCESSORY,
	EquipmentDefinitionScript.EquipmentSlot.BAG,
]

const SLOT_NAMES := {
	EquipmentDefinitionScript.EquipmentSlot.PRIMARY_WEAPON: "Primary Weapon",
	EquipmentDefinitionScript.EquipmentSlot.SECONDARY_WEAPON: "Secondary Weapon",
	EquipmentDefinitionScript.EquipmentSlot.HEAD: "Head",
	EquipmentDefinitionScript.EquipmentSlot.CHEST: "Chest",
	EquipmentDefinitionScript.EquipmentSlot.HANDS: "Hands",
	EquipmentDefinitionScript.EquipmentSlot.LEGS: "Legs",
	EquipmentDefinitionScript.EquipmentSlot.FEET: "Feet",
	EquipmentDefinitionScript.EquipmentSlot.ACCESSORY: "Accessory",
	EquipmentDefinitionScript.EquipmentSlot.BAG: "Bag",
}

const HOTBAR_INPUT_ACTIONS := [
	"hotbar_slot_1",
	"hotbar_slot_2",
	"hotbar_slot_3",
	"hotbar_slot_4",
]

enum SelectionKind {
	EQUIPMENT,
	BACKPACK,
	HOTBAR,
	DROP,
}

const FULL_SCREEN_PANEL_SIZE := Vector2(1080, 460)
const SPLIT_SCREEN_PANEL_SIZE := Vector2(1060, 300)
const SPLIT_SCREEN_BUTTON_SIZE := Vector2(214, 28)
const SPLIT_SCREEN_HOTBAR_SIZE := Vector2(62, 30)
const CONTROLLER_NAV_DEADZONE := 0.55
const CONTROLLER_NAV_INITIAL_DELAY := 0.32
const CONTROLLER_NAV_REPEAT_DELAY := 0.13

const STAT_NAMES := {
	StatModifierDefinitionScript.StatType.ATTACK_DAMAGE: "Attack Damage",
	StatModifierDefinitionScript.StatType.ARMOR: "Armor",
	StatModifierDefinitionScript.StatType.MAX_HEALTH: "Max Health",
	StatModifierDefinitionScript.StatType.MOVE_SPEED: "Move Speed",
	StatModifierDefinitionScript.StatType.BACKPACK_SLOTS: "Backpack Slots",
	StatModifierDefinitionScript.StatType.HOTBAR_SLOTS: "Hotbar Slots",
}

@export var equipment: Node
@export var inventory: Node
@export var hotbar: Node
@export var melee_attack: Node

var selected_equipment_slot := EquipmentDefinitionScript.EquipmentSlot.PRIMARY_WEAPON
var selected_backpack_slot := -1
var slot_buttons: Dictionary[EquipmentDefinitionScript.EquipmentSlot, Button] = {}
var backpack_slot_buttons: Array[Button] = []
var hotbar_slot_buttons: Array[Button] = []
var current_backpack_slot_count := 0
var current_hotbar_slot_count := 0
var held_item_instance: Resource
var held_backpack_slot_index := -1
var is_controller_holding_item := false
var previous_mouse_mode := Input.MOUSE_MODE_CAPTURED
var feedback_tween: Tween
var player: PlayerController
var is_split_screen_layout := false
var is_controller_selection_mode := false
var selected_kind := SelectionKind.EQUIPMENT
var selected_hotbar_slot := 0
var controller_nav_direction := Vector2i.ZERO
var controller_nav_repeat_timer := 0.0

@onready var root_control: Control = $Root
@onready var paper_doll_panel: PanelContainer = $Root/PaperDollPanel
@onready var layout_container: HBoxContainer = $Root/PaperDollPanel/Layout
@onready var feedback_label: Label = $Root/FeedbackLabel
@onready var stats_label: Label = $Root/PaperDollPanel/Layout/StatsPanel/StatsLabel
@onready var stats_panel: VBoxContainer = $Root/PaperDollPanel/Layout/StatsPanel
@onready var slots_panel: VBoxContainer = $Root/PaperDollPanel/Layout/SlotsPanel
@onready var slots_container: VBoxContainer = $Root/PaperDollPanel/Layout/SlotsPanel/SlotButtons
@onready var backpack_panel: VBoxContainer = $Root/PaperDollPanel/Layout/BackpackPanel
@onready var backpack_slots_container: GridContainer = $Root/PaperDollPanel/Layout/BackpackPanel/BackpackSlots
@onready var hotbar_slots_container: HBoxContainer = $Root/PaperDollPanel/Layout/BackpackPanel/HotbarSlots
@onready var drop_button: Button = $Root/PaperDollPanel/Layout/BackpackPanel/DropButton
@onready var details_panel: VBoxContainer = $Root/PaperDollPanel/Layout/DetailsPanel
@onready var item_name_label: Label = $Root/PaperDollPanel/Layout/DetailsPanel/ItemNameLabel
@onready var item_details_label: Label = $Root/PaperDollPanel/Layout/DetailsPanel/ItemDetailsLabel
@onready var held_item_label: Label = Label.new()


func _ready() -> void:
	if not equipment:
		push_error("PlayerEquipmentUI requires an equipment reference.")
	if not inventory:
		push_error("PlayerEquipmentUI requires an inventory reference.")
	if not hotbar:
		push_error("PlayerEquipmentUI requires a hotbar reference.")
	if not melee_attack:
		push_error("PlayerEquipmentUI requires a melee_attack reference.")
	player = get_parent() as PlayerController
	if not player:
		push_error("PlayerEquipmentUI expected to be parented to PlayerController.")

	paper_doll_panel.visible = false
	feedback_label.visible = false
	equipment.equipment_changed.connect(_on_equipment_changed)
	inventory.inventory_changed.connect(_on_inventory_changed)
	inventory.inventory_toast.connect(_show_feedback)
	hotbar.hotbar_changed.connect(_on_hotbar_changed)
	hotbar.hotbar_toast.connect(_show_feedback)
	var life_state := player.get_node("Components/PlayerLifeState") as PlayerLifeState
	life_state.bleeding_out_started.connect(_on_player_became_unable_to_use_inventory)
	life_state.died.connect(_on_player_became_unable_to_use_inventory)
	drop_button.toggle_mode = true
	drop_button.mouse_entered.connect(_select_drop)
	drop_button.pressed.connect(_on_drop_button_pressed)
	_create_held_item_label()
	_create_slot_buttons()
	_refresh()
	set_process(true)


func _input(event: InputEvent) -> void:
	if not player.input_reader.owns_input_event(event):
		return

	if event.is_action_pressed("toggle_equipment"):
		if player.is_bleeding_out_or_dead():
			_show_feedback("Cannot use inventory while downed")
			_set_ui_input_handled()
			return
		_toggle_paper_doll(_should_show_mouse_for_toggle(event))
		_set_ui_input_handled()
		return
	if paper_doll_panel.visible and event.is_action_pressed("inventory_pick_place") and not event is InputEventMouseButton:
		_activate_selected_control(true)
		_set_ui_input_handled()
		return
	if event.is_action_pressed("inventory_cancel_drag") and held_item_instance:
		_show_feedback("Place held item in a slot")
		_set_ui_input_handled()
		return
	for index in HOTBAR_INPUT_ACTIONS.size():
		if event.is_action_pressed(HOTBAR_INPUT_ACTIONS[index]):
			hotbar.activate_slot(index)
			_set_ui_input_handled()
			return


func _process(delta: float) -> void:
	if held_item_instance and not is_controller_holding_item:
		held_item_label.global_position = root_control.get_global_mouse_position() + Vector2(16, 16)
	if paper_doll_panel.visible and is_controller_selection_mode:
		_process_controller_navigation(delta)


func _toggle_paper_doll(show_mouse_cursor: bool = true) -> void:
	paper_doll_panel.visible = not paper_doll_panel.visible

	if paper_doll_panel.visible:
		previous_mouse_mode = Input.get_mouse_mode()
		is_controller_selection_mode = not show_mouse_cursor
		controller_nav_direction = Vector2i.ZERO
		controller_nav_repeat_timer = 0.0
		if show_mouse_cursor:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		player.set_gameplay_input_enabled(false)
		player.set_controller_look_enabled(false)
		_refresh_mouse_filters()
		_refresh()
	else:
		if held_item_instance:
			_show_feedback("Place held item before closing")
			paper_doll_panel.visible = true
			return
		is_controller_selection_mode = false
		_refresh_mouse_filters()
		player.set_gameplay_input_enabled(true)
		player.set_controller_look_enabled(true)
		Input.set_mouse_mode(previous_mouse_mode)


func _close_paper_doll_for_life_state() -> void:
	if held_item_instance:
		if held_backpack_slot_index >= 0:
			held_item_instance = inventory.place_item_at(held_backpack_slot_index, held_item_instance)
		else:
			player.drop_item_instance(held_item_instance)
			held_item_instance = null
		if not held_item_instance:
			held_backpack_slot_index = -1
		is_controller_holding_item = false
		_update_held_item_label()
	if not paper_doll_panel.visible:
		return

	paper_doll_panel.visible = false
	is_controller_selection_mode = false
	_refresh_mouse_filters()
	player.set_gameplay_input_enabled(true)
	player.set_controller_look_enabled(true)
	Input.set_mouse_mode(previous_mouse_mode)


func _should_show_mouse_for_toggle(event: InputEvent) -> bool:
	return event is InputEventKey or event is InputEventMouseButton


func _create_held_item_label() -> void:
	held_item_label.visible = false
	held_item_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	held_item_label.z_index = 20
	root_control.add_child(held_item_label)


func _create_slot_buttons() -> void:
	for slot in SLOT_ORDER:
		var button := Button.new()
		button.text = _get_slot_button_text(slot)
		button.custom_minimum_size = _get_button_size()
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		button.mouse_entered.connect(_on_slot_mouse_entered.bind(slot))
		button.pressed.connect(_on_equipment_slot_pressed.bind(slot))
		slots_container.add_child(button)
		slot_buttons[slot] = button


func _sync_backpack_slots() -> void:
	var slot_count: int = inventory.get_backpack_slot_count()
	if slot_count == current_backpack_slot_count:
		return

	for button in backpack_slot_buttons:
		button.queue_free()
	backpack_slot_buttons.clear()
	current_backpack_slot_count = slot_count
	selected_backpack_slot = _clamp_backpack_slot(selected_backpack_slot)

	for index in slot_count:
		var button := Button.new()
		button.custom_minimum_size = _get_button_size()
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		button.mouse_entered.connect(_on_backpack_slot_mouse_entered.bind(index))
		button.pressed.connect(_on_backpack_slot_pressed.bind(index))
		backpack_slots_container.add_child(button)
		backpack_slot_buttons.append(button)


func _sync_hotbar_slots() -> void:
	var slot_count: int = inventory.get_hotbar_slot_count()
	if slot_count == current_hotbar_slot_count:
		return

	for button in hotbar_slot_buttons:
		button.queue_free()
	hotbar_slot_buttons.clear()
	current_hotbar_slot_count = slot_count

	for index in slot_count:
		var button := Button.new()
		button.custom_minimum_size = _get_hotbar_button_size()
		button.focus_mode = Control.FOCUS_NONE
		button.toggle_mode = true
		button.mouse_entered.connect(_on_hotbar_slot_mouse_entered.bind(index))
		button.pressed.connect(_on_hotbar_slot_pressed.bind(index))
		hotbar_slots_container.add_child(button)
		hotbar_slot_buttons.append(button)

	selected_hotbar_slot = _clamp_hotbar_slot(selected_hotbar_slot)
	_refresh_mouse_filters()


func _on_slot_mouse_entered(slot: int) -> void:
	if not _accepts_mouse_interaction():
		return

	_set_selection(SelectionKind.EQUIPMENT, slot)


func _on_equipment_slot_pressed(slot: int) -> void:
	if not _accepts_mouse_interaction():
		return

	_activate_equipment_slot(slot, false)


func _on_backpack_slot_mouse_entered(index: int) -> void:
	if not _accepts_mouse_interaction():
		return

	_set_selection(SelectionKind.BACKPACK, index)


func _on_backpack_slot_pressed(index: int) -> void:
	if not _accepts_mouse_interaction():
		return

	_activate_backpack_slot(index, false)


func _on_hotbar_slot_mouse_entered(index: int) -> void:
	if not _accepts_mouse_interaction():
		return

	_set_selection(SelectionKind.HOTBAR, index)


func _on_hotbar_slot_pressed(index: int) -> void:
	if not _accepts_mouse_interaction():
		return

	_activate_hotbar_slot(index, false)


func _select_drop() -> void:
	if not _accepts_mouse_interaction():
		return

	_set_selection(SelectionKind.DROP, 0)


func _on_drop_button_pressed() -> void:
	if not _accepts_mouse_interaction():
		return

	_drop_held_item()


func _set_selection(kind: int, value: int = 0) -> void:
	selected_kind = kind
	match selected_kind:
		SelectionKind.EQUIPMENT:
			selected_equipment_slot = value
		SelectionKind.BACKPACK:
			selected_backpack_slot = _clamp_backpack_slot(value)
		SelectionKind.HOTBAR:
			selected_hotbar_slot = _clamp_hotbar_slot(value)
		SelectionKind.DROP:
			pass
	_refresh()


func _select_slot(slot: int) -> void:
	_set_selection(SelectionKind.EQUIPMENT, slot)


func _select_backpack_slot(index: int) -> void:
	_set_selection(SelectionKind.BACKPACK, index)


func _activate_backpack_slot(index: int, from_controller: bool = false) -> void:
	selected_kind = SelectionKind.BACKPACK
	selected_backpack_slot = _clamp_backpack_slot(index)
	if held_item_instance:
		held_item_instance = inventory.place_item_at(index, held_item_instance)
		held_backpack_slot_index = index if held_item_instance else -1
		if not held_item_instance:
			is_controller_holding_item = false
		_update_held_item_label()
		_refresh()
		return

	held_item_instance = inventory.take_item_at(index)
	held_backpack_slot_index = index if held_item_instance else -1
	is_controller_holding_item = from_controller and held_item_instance != null
	_update_held_item_label()
	_refresh()


func _activate_equipment_slot(slot: int, from_controller: bool = false) -> void:
	selected_kind = SelectionKind.EQUIPMENT
	selected_equipment_slot = slot

	if held_item_instance:
		_place_held_item_in_equipment_slot(slot)
	else:
		_take_equipped_item(slot)
		is_controller_holding_item = from_controller and held_item_instance != null

	_update_held_item_label()
	_refresh()


func _activate_hotbar_slot(index: int, _from_controller: bool = false) -> void:
	selected_kind = SelectionKind.HOTBAR
	selected_hotbar_slot = _clamp_hotbar_slot(index)
	if held_item_instance:
		var item_instance_to_bind := _return_held_item_to_backpack()
		if item_instance_to_bind and hotbar.bind_item(index, item_instance_to_bind):
			_refresh()
		return

	hotbar.activate_slot(index)
	_refresh()


func _activate_selected_control(from_controller: bool = false) -> void:
	match selected_kind:
		SelectionKind.EQUIPMENT:
			_activate_equipment_slot(selected_equipment_slot, from_controller)
		SelectionKind.BACKPACK:
			_activate_backpack_slot(selected_backpack_slot, from_controller)
		SelectionKind.HOTBAR:
			_activate_hotbar_slot(selected_hotbar_slot, from_controller)
		SelectionKind.DROP:
			_drop_held_item()


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
		_move_selection_horizontal(direction.x)
	else:
		_move_selection_vertical(direction.y)


func _move_selection_horizontal(direction: int) -> void:
	var column := _get_selection_column()
	var next_column := clampi(column + direction, 0, 2)
	if next_column == column:
		return

	match next_column:
		0:
			_set_selection(SelectionKind.EQUIPMENT, selected_equipment_slot)
		1:
			_set_selection(SelectionKind.BACKPACK, selected_backpack_slot)
		2:
			if inventory.get_hotbar_slot_count() > 0:
				_set_selection(SelectionKind.HOTBAR, selected_hotbar_slot)
			else:
				_set_selection(SelectionKind.DROP, 0)


func _move_selection_vertical(direction: int) -> void:
	match selected_kind:
		SelectionKind.EQUIPMENT:
			var slot_index := SLOT_ORDER.find(selected_equipment_slot)
			slot_index = clampi(slot_index + direction, 0, SLOT_ORDER.size() - 1)
			_set_selection(SelectionKind.EQUIPMENT, SLOT_ORDER[slot_index])
		SelectionKind.BACKPACK:
			_set_selection(SelectionKind.BACKPACK, selected_backpack_slot + direction)
		SelectionKind.HOTBAR:
			var hotbar_count: int = inventory.get_hotbar_slot_count()
			var next_hotbar_slot: int = selected_hotbar_slot + direction
			if direction > 0 and next_hotbar_slot >= hotbar_count:
				_set_selection(SelectionKind.DROP, 0)
			else:
				_set_selection(SelectionKind.HOTBAR, next_hotbar_slot)
		SelectionKind.DROP:
			if direction < 0 and inventory.get_hotbar_slot_count() > 0:
				_set_selection(SelectionKind.HOTBAR, inventory.get_hotbar_slot_count() - 1)


func _get_selection_column() -> int:
	match selected_kind:
		SelectionKind.EQUIPMENT:
			return 0
		SelectionKind.BACKPACK:
			return 1
		_:
			return 2


func _drop_held_item() -> void:
	if not held_item_instance:
		_show_feedback("Hold a backpack item to drop it")
		return
	if held_backpack_slot_index < 0:
		_show_feedback("Place equipment in backpack before dropping")
		return

	var item_instance_to_drop: Resource = held_item_instance
	held_item_instance = null
	held_backpack_slot_index = -1
	is_controller_holding_item = false
	_update_held_item_label()
	hotbar.clear_bindings_for_item(item_instance_to_drop)
	if player:
		player.drop_item_instance(item_instance_to_drop)
	else:
		push_error("PlayerEquipmentUI expected to be parented to PlayerController.")
	_show_feedback("Dropped %s" % item_instance_to_drop.get_display_name())
	_refresh()


func _refresh() -> void:
	_sync_backpack_slots()
	_sync_hotbar_slots()
	selected_backpack_slot = _clamp_backpack_slot(selected_backpack_slot)
	selected_hotbar_slot = _clamp_hotbar_slot(selected_hotbar_slot)
	_refresh_slot_buttons()
	_refresh_backpack_slots()
	_refresh_hotbar_slots()
	_refresh_stats()
	_refresh_item_details()


func _refresh_slot_buttons() -> void:
	for slot in SLOT_ORDER:
		var button := slot_buttons[slot] as Button
		button.text = _get_slot_button_text(slot)
		button.button_pressed = selected_kind == SelectionKind.EQUIPMENT and slot == selected_equipment_slot


func _refresh_backpack_slots() -> void:
	for index in backpack_slot_buttons.size():
		var button := backpack_slot_buttons[index]
		button.text = _get_backpack_slot_text(index)
		button.button_pressed = selected_kind == SelectionKind.BACKPACK and index == selected_backpack_slot
		if is_controller_holding_item and held_backpack_slot_index == index:
			button.text = "%d: [Held] %s" % [index + 1, held_item_instance.get_display_name()]


func _refresh_hotbar_slots() -> void:
	for index in hotbar_slot_buttons.size():
		var button := hotbar_slot_buttons[index]
		button.text = _get_hotbar_slot_text(index)
		button.button_pressed = selected_kind == SelectionKind.HOTBAR and index == selected_hotbar_slot
	drop_button.button_pressed = selected_kind == SelectionKind.DROP


func _refresh_stats() -> void:
	var armor: float = equipment.get_armor()
	var move_speed: float = equipment.get_move_speed_modifier()
	var max_health: float = equipment.get_max_health_modifier()

	stats_label.text = "Attack Damage: %d\nArmor: %s\nMax Health: %s\nMove Speed: %s\nBackpack Slots: %d/%d\nHotbar Slots: %d" % [
		melee_attack.get_attack_damage(),
		_format_number(armor),
		_format_signed_number(max_health),
		_format_signed_number(move_speed),
		inventory.get_used_backpack_slot_count(),
		inventory.get_backpack_slot_count(),
		inventory.get_hotbar_slot_count(),
	]


func _refresh_item_details() -> void:
	match selected_kind:
		SelectionKind.BACKPACK:
			var item_instance: Resource = inventory.get_item_at(selected_backpack_slot)
			if not item_instance:
				item_name_label.text = "Backpack Slot %d" % (selected_backpack_slot + 1)
				item_details_label.text = "Empty slot"
				return

			var item_definition: Resource = item_instance.item_definition
			item_name_label.text = item_instance.get_display_name()
			item_details_label.text = _get_item_instance_detail_text(item_instance, item_definition)
			return
		SelectionKind.HOTBAR:
			var binding: Resource = hotbar.get_binding(selected_hotbar_slot)
			item_name_label.text = "Hotbar Slot %d" % (selected_hotbar_slot + 1)
			item_details_label.text = binding.get_display_name() if binding else "Empty hotbar slot"
			return
		SelectionKind.DROP:
			item_name_label.text = "Drop"
			item_details_label.text = "Hold a backpack item, then activate Drop to toss it into the world."
			return

	var equipped_item: Resource = equipment.get_equipped(selected_equipment_slot)
	if not equipped_item:
		item_name_label.text = SLOT_NAMES[selected_equipment_slot]
		item_details_label.text = "Empty slot"
		return

	item_name_label.text = equipped_item.display_name
	item_details_label.text = _get_modifier_text(equipped_item)


func _get_slot_button_text(slot: int) -> String:
	var equipped_item: Resource = equipment.get_equipped(slot)
	if not equipped_item:
		return "%s: Empty" % SLOT_NAMES[slot]

	return "%s: %s" % [SLOT_NAMES[slot], equipped_item.display_name]


func _get_backpack_slot_text(index: int) -> String:
	var item_instance: Resource = inventory.get_item_at(index)
	if not item_instance:
		return "%d: Empty" % (index + 1)

	var quantity_text := ""
	if item_instance.quantity > 1:
		quantity_text = " x%d" % item_instance.quantity

	return "%d: %s%s" % [index + 1, item_instance.get_display_name(), quantity_text]


func _get_item_instance_detail_text(item_instance: Resource, item_definition: Resource) -> String:
	var lines: Array[String] = ["Quantity: %d" % item_instance.quantity]

	if item_definition and item_definition.has_method("get_stat_modifier_total"):
		var modifier_text := _get_modifier_text(item_definition)
		if not modifier_text.is_empty():
			lines.append("")
			lines.append(modifier_text)

	return "\n".join(lines)


func _get_hotbar_slot_text(index: int) -> String:
	var binding: Resource = hotbar.get_binding(index)
	if not binding:
		return "H%d\nEmpty" % (index + 1)

	return "H%d\n%s" % [index + 1, binding.get_display_name()]


func _place_held_item_in_equipment_slot(slot: int) -> void:
	var item_definition: Resource = held_item_instance.item_definition
	if not item_definition or not item_definition.has_method("get_stat_modifier_total"):
		_show_feedback("That item cannot be equipped")
		return
	if item_definition.equipment_slot != slot:
		_show_feedback("%s goes in %s" % [item_definition.display_name, SLOT_NAMES.get(item_definition.equipment_slot, "another slot")])
		return

	var current_equipped: Resource = equipment.get_equipped(slot)
	if not inventory.can_change_equipped_item(current_equipped, item_definition):
		_show_feedback("Not enough backpack space to change equipment")
		return

	var replaced_item: Resource = equipment.equip_and_return_replaced(item_definition)
	held_item_instance = _make_item_instance(replaced_item)
	held_backpack_slot_index = -1


func _take_equipped_item(slot: int) -> void:
	var equipped_item: Resource = equipment.get_equipped(slot)
	if not equipped_item:
		return
	if not inventory.can_change_equipped_item(equipped_item):
		_show_feedback("Empty backpack slots before removing %s" % equipped_item.display_name)
		return

	var unequipped_item: Resource = equipment.unequip(slot)
	held_item_instance = _make_item_instance(unequipped_item)
	held_backpack_slot_index = -1


func _make_item_instance(item_definition: Resource) -> Resource:
	if not item_definition:
		return null

	var item_instance := ItemInstanceScript.new()
	item_instance.setup(item_definition, 1)
	return item_instance


func _return_held_item_to_backpack() -> Resource:
	if not held_item_instance:
		return null
	if held_backpack_slot_index < 0:
		_show_feedback("Only backpack items can be bound to hotbar")
		return null

	var item_instance_to_place: Resource = held_item_instance
	var displaced_item: Resource = inventory.place_item_at(held_backpack_slot_index, item_instance_to_place)
	if displaced_item:
		held_item_instance = displaced_item
		is_controller_holding_item = false
		_update_held_item_label()
		_show_feedback("Clear the backpack slot before binding")
		return null

	held_item_instance = null
	held_backpack_slot_index = -1
	is_controller_holding_item = false
	_update_held_item_label()
	return item_instance_to_place


func _update_held_item_label() -> void:
	if not held_item_instance or is_controller_holding_item:
		held_item_label.visible = false
		return

	held_item_label.text = held_item_instance.get_display_name()
	if held_item_instance.quantity > 1:
		held_item_label.text += " x%d" % held_item_instance.quantity
	held_item_label.visible = true


func _get_modifier_text(equipment_definition: Resource) -> String:
	if equipment_definition.stat_modifiers.is_empty():
		return "No stat modifiers"

	var lines: Array[String] = []
	for stat_modifier in equipment_definition.stat_modifiers:
		if not stat_modifier:
			continue
		lines.append("%s %s" % [STAT_NAMES.get(stat_modifier.stat_type, "Unknown Stat"), _format_signed_number(stat_modifier.value)])

	return "\n".join(lines)


func _on_equipment_changed(slot: int, equipment_definition: Resource) -> void:
	selected_kind = SelectionKind.EQUIPMENT
	selected_equipment_slot = slot
	if equipment_definition:
		_show_feedback("Equipped %s" % equipment_definition.display_name)
	_refresh()


func _on_inventory_changed() -> void:
	_refresh()


func _on_hotbar_changed() -> void:
	_refresh()


func _on_player_became_unable_to_use_inventory(_player: PlayerController) -> void:
	_close_paper_doll_for_life_state()
	_show_feedback("Cannot use inventory while downed")


func _show_feedback(message: String) -> void:
	if feedback_tween:
		feedback_tween.kill()

	feedback_label.text = message
	feedback_label.modulate.a = 1.0
	feedback_label.visible = true

	feedback_tween = create_tween()
	feedback_tween.tween_interval(1.6)
	feedback_tween.tween_property(feedback_label, "modulate:a", 0.0, 0.45)
	feedback_tween.tween_callback(func() -> void: feedback_label.visible = false)


func _format_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%d" % roundi(value)

	return "%.1f" % value


func _format_signed_number(value: float) -> String:
	var prefix := "+" if value >= 0.0 else ""
	return "%s%s" % [prefix, _format_number(value)]


func _accepts_mouse_interaction() -> bool:
	if not paper_doll_panel.visible:
		return false
	if is_controller_selection_mode:
		return false
	if not player or not player.input_reader:
		return false

	return player.input_reader.owns_mouse


func _clamp_backpack_slot(index: int) -> int:
	return clampi(index, 0, maxi(inventory.get_backpack_slot_count() - 1, 0))


func _clamp_hotbar_slot(index: int) -> int:
	return clampi(index, 0, maxi(inventory.get_hotbar_slot_count() - 1, 0))


func _get_ui_viewport() -> Viewport:
	if custom_viewport:
		return custom_viewport

	return get_viewport()


func _set_ui_input_handled() -> void:
	_get_ui_viewport().set_input_as_handled()


func configure_for_split_screen() -> void:
	is_split_screen_layout = true
	paper_doll_panel.custom_minimum_size = SPLIT_SCREEN_PANEL_SIZE
	paper_doll_panel.anchor_left = 0.5
	paper_doll_panel.anchor_top = 0.0
	paper_doll_panel.anchor_right = 0.5
	paper_doll_panel.anchor_bottom = 0.0
	paper_doll_panel.offset_left = -SPLIT_SCREEN_PANEL_SIZE.x * 0.5
	paper_doll_panel.offset_top = 10.0
	paper_doll_panel.offset_right = SPLIT_SCREEN_PANEL_SIZE.x * 0.5
	paper_doll_panel.offset_bottom = SPLIT_SCREEN_PANEL_SIZE.y + 10.0

	feedback_label.offset_top = 18.0
	feedback_label.offset_bottom = 48.0
	layout_container.add_theme_constant_override("separation", 8)
	slots_container.add_theme_constant_override("separation", 2)
	backpack_panel.add_theme_constant_override("separation", 2)
	backpack_slots_container.add_theme_constant_override("v_separation", 2)
	hotbar_slots_container.add_theme_constant_override("separation", 2)

	stats_panel.custom_minimum_size = Vector2(210, 0)
	slots_panel.custom_minimum_size = Vector2(245, 0)
	backpack_panel.custom_minimum_size = Vector2(245, 0)
	details_panel.custom_minimum_size = Vector2(245, 0)
	drop_button.custom_minimum_size = _get_button_size()

	_refresh_button_sizes()
	_refresh_mouse_filters()


func _refresh_button_sizes() -> void:
	for button in slot_buttons.values():
		button.custom_minimum_size = _get_button_size()
	for button in backpack_slot_buttons:
		button.custom_minimum_size = _get_button_size()
	for button in hotbar_slot_buttons:
		button.custom_minimum_size = _get_hotbar_button_size()


func _refresh_mouse_filters() -> void:
	var mouse_filter := Control.MOUSE_FILTER_STOP if _accepts_mouse_interaction() else Control.MOUSE_FILTER_IGNORE
	root_control.mouse_filter = mouse_filter
	paper_doll_panel.mouse_filter = mouse_filter
	layout_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slots_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slots_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backpack_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backpack_slots_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hotbar_slots_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_details_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drop_button.mouse_filter = mouse_filter
	for button in slot_buttons.values():
		button.mouse_filter = mouse_filter
	for button in backpack_slot_buttons:
		button.mouse_filter = mouse_filter
	for button in hotbar_slot_buttons:
		button.mouse_filter = mouse_filter


func _get_button_size() -> Vector2:
	if is_split_screen_layout:
		return SPLIT_SCREEN_BUTTON_SIZE

	return Vector2(230, 34)


func _get_hotbar_button_size() -> Vector2:
	if is_split_screen_layout:
		return SPLIT_SCREEN_HOTBAR_SIZE

	return Vector2(70, 38)
