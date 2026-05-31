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

var selected_slot := EquipmentDefinitionScript.EquipmentSlot.PRIMARY_WEAPON
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

@onready var root_control: Control = $Root
@onready var paper_doll_panel: PanelContainer = $Root/PaperDollPanel
@onready var feedback_label: Label = $Root/FeedbackLabel
@onready var stats_label: Label = $Root/PaperDollPanel/Layout/StatsPanel/StatsLabel
@onready var slots_container: VBoxContainer = $Root/PaperDollPanel/Layout/SlotsPanel/SlotButtons
@onready var backpack_slots_container: GridContainer = $Root/PaperDollPanel/Layout/BackpackPanel/BackpackSlots
@onready var hotbar_slots_container: HBoxContainer = $Root/PaperDollPanel/Layout/BackpackPanel/HotbarSlots
@onready var drop_button: Button = $Root/PaperDollPanel/Layout/BackpackPanel/DropButton
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
	drop_button.pressed.connect(_drop_held_item)
	_create_held_item_label()
	_create_slot_buttons()
	_refresh()
	set_process(false)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_equipment"):
		_toggle_paper_doll(_should_show_mouse_for_toggle(event))
		get_viewport().set_input_as_handled()
		return
	if paper_doll_panel.visible and event.is_action_pressed("inventory_pick_place") and not event is InputEventMouseButton:
		_activate_focused_control(true)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("inventory_cancel_drag") and held_item_instance:
		_show_feedback("Place held item in a slot")
		get_viewport().set_input_as_handled()
		return
	for index in HOTBAR_INPUT_ACTIONS.size():
		if event.is_action_pressed(HOTBAR_INPUT_ACTIONS[index]):
			hotbar.activate_slot(index)
			get_viewport().set_input_as_handled()
			return


func _process(_delta: float) -> void:
	held_item_label.global_position = root_control.get_global_mouse_position() + Vector2(16, 16)


func _toggle_paper_doll(show_mouse_cursor: bool = true) -> void:
	paper_doll_panel.visible = not paper_doll_panel.visible

	if paper_doll_panel.visible:
		previous_mouse_mode = Input.get_mouse_mode()
		if show_mouse_cursor:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		player.set_gameplay_input_enabled(false)
		player.set_controller_look_enabled(false)
		_refresh()
		var selected_button := slot_buttons[selected_slot] as Button
		selected_button.grab_focus()
	else:
		if held_item_instance:
			_show_feedback("Place held item before closing")
			paper_doll_panel.visible = true
			return
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
		button.custom_minimum_size = Vector2(230, 34)
		button.focus_mode = Control.FOCUS_ALL
		button.toggle_mode = true
		button.mouse_entered.connect(_select_slot.bind(slot))
		button.focus_entered.connect(_select_slot.bind(slot))
		button.pressed.connect(_activate_equipment_slot.bind(slot, false))
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
	selected_backpack_slot = -1

	for index in slot_count:
		var button := Button.new()
		button.custom_minimum_size = Vector2(230, 38)
		button.focus_mode = Control.FOCUS_ALL
		button.toggle_mode = true
		button.mouse_entered.connect(_select_backpack_slot.bind(index))
		button.focus_entered.connect(_select_backpack_slot.bind(index))
		button.pressed.connect(_activate_backpack_slot.bind(index, false))
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
		button.custom_minimum_size = Vector2(70, 38)
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_activate_hotbar_slot.bind(index, false))
		hotbar_slots_container.add_child(button)
		hotbar_slot_buttons.append(button)


func _select_slot(slot: int) -> void:
	selected_slot = slot
	selected_backpack_slot = -1
	_refresh()


func _select_backpack_slot(index: int) -> void:
	selected_backpack_slot = index
	_refresh()


func _activate_backpack_slot(index: int, from_controller: bool = false) -> void:
	selected_backpack_slot = index
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
	selected_slot = slot
	selected_backpack_slot = -1

	if held_item_instance:
		_place_held_item_in_equipment_slot(slot)
	else:
		_take_equipped_item(slot)
		is_controller_holding_item = from_controller and held_item_instance != null

	_update_held_item_label()
	_refresh()


func _activate_hotbar_slot(index: int, _from_controller: bool = false) -> void:
	if held_item_instance:
		var item_instance_to_bind := _return_held_item_to_backpack()
		if item_instance_to_bind and hotbar.bind_item(index, item_instance_to_bind):
			_refresh()
		return

	hotbar.activate_slot(index)
	_refresh()


func _activate_focused_control(from_controller: bool = false) -> void:
	var focused_control := get_viewport().gui_get_focus_owner()
	if not focused_control:
		_show_feedback("Select an inventory slot")
		return

	for slot in SLOT_ORDER:
		if slot_buttons[slot] == focused_control:
			_activate_equipment_slot(slot, from_controller)
			return

	var backpack_index := backpack_slot_buttons.find(focused_control)
	if backpack_index >= 0:
		_activate_backpack_slot(backpack_index, from_controller)
		return

	var hotbar_index := hotbar_slot_buttons.find(focused_control)
	if hotbar_index >= 0:
		_activate_hotbar_slot(hotbar_index, from_controller)
		return

	if focused_control == drop_button:
		_drop_held_item()
		return

	_show_feedback("Select an inventory slot")


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
	_refresh_slot_buttons()
	_refresh_backpack_slots()
	_refresh_hotbar_slots()
	_refresh_stats()
	_refresh_item_details()


func _refresh_slot_buttons() -> void:
	for slot in SLOT_ORDER:
		var button := slot_buttons[slot] as Button
		button.text = _get_slot_button_text(slot)
		button.button_pressed = slot == selected_slot


func _refresh_backpack_slots() -> void:
	for index in backpack_slot_buttons.size():
		var button := backpack_slot_buttons[index]
		button.text = _get_backpack_slot_text(index)
		button.button_pressed = index == selected_backpack_slot
		if is_controller_holding_item and held_backpack_slot_index == index:
			button.text = "%d: [Held] %s" % [index + 1, held_item_instance.get_display_name()]


func _refresh_hotbar_slots() -> void:
	for index in hotbar_slot_buttons.size():
		var button := hotbar_slot_buttons[index]
		button.text = _get_hotbar_slot_text(index)


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
	if selected_backpack_slot >= 0:
		var item_instance: Resource = inventory.get_item_at(selected_backpack_slot)
		if not item_instance:
			item_name_label.text = "Backpack Slot %d" % (selected_backpack_slot + 1)
			item_details_label.text = "Empty slot"
			return

		var item_definition: Resource = item_instance.item_definition
		item_name_label.text = item_instance.get_display_name()
		item_details_label.text = _get_item_instance_detail_text(item_instance, item_definition)
		return

	var equipped_item: Resource = equipment.get_equipped(selected_slot)
	if not equipped_item:
		item_name_label.text = SLOT_NAMES[selected_slot]
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
		set_process(false)
		return

	held_item_label.text = held_item_instance.get_display_name()
	if held_item_instance.quantity > 1:
		held_item_label.text += " x%d" % held_item_instance.quantity
	held_item_label.visible = true
	set_process(true)


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
	selected_slot = slot
	selected_backpack_slot = -1
	if equipment_definition:
		_show_feedback("Equipped %s" % equipment_definition.display_name)
	_refresh()


func _on_inventory_changed() -> void:
	_refresh()


func _on_hotbar_changed() -> void:
	_refresh()


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
