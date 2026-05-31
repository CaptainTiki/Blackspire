extends CanvasLayer
class_name PlayerEquipmentUI

const EquipmentDefinitionScript := preload("res://data/items/equipment_definition.gd")
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
}

const STAT_NAMES := {
	StatModifierDefinitionScript.StatType.ATTACK_DAMAGE: "Attack Damage",
	StatModifierDefinitionScript.StatType.ARMOR: "Armor",
	StatModifierDefinitionScript.StatType.MAX_HEALTH: "Max Health",
	StatModifierDefinitionScript.StatType.MOVE_SPEED: "Move Speed",
}

@export var equipment: Node
@export var melee_attack: Node

var selected_slot := EquipmentDefinitionScript.EquipmentSlot.PRIMARY_WEAPON
var slot_buttons: Dictionary = {}
var previous_mouse_mode := Input.MOUSE_MODE_CAPTURED
var feedback_tween: Tween

@onready var paper_doll_panel: PanelContainer = $Root/PaperDollPanel
@onready var feedback_label: Label = $Root/FeedbackLabel
@onready var stats_label: Label = $Root/PaperDollPanel/Layout/StatsPanel/StatsLabel
@onready var slots_container: VBoxContainer = $Root/PaperDollPanel/Layout/SlotsPanel/SlotButtons
@onready var item_name_label: Label = $Root/PaperDollPanel/Layout/DetailsPanel/ItemNameLabel
@onready var item_details_label: Label = $Root/PaperDollPanel/Layout/DetailsPanel/ItemDetailsLabel


func _ready() -> void:
	if not equipment:
		push_error("PlayerEquipmentUI requires an equipment reference.")
	if not melee_attack:
		push_error("PlayerEquipmentUI requires a melee_attack reference.")

	paper_doll_panel.visible = false
	feedback_label.visible = false
	equipment.equipment_changed.connect(_on_equipment_changed)
	_create_slot_buttons()
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_equipment"):
		_toggle_paper_doll()
		get_viewport().set_input_as_handled()


func _toggle_paper_doll() -> void:
	paper_doll_panel.visible = not paper_doll_panel.visible

	if paper_doll_panel.visible:
		previous_mouse_mode = Input.get_mouse_mode()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_refresh()
		var selected_button := slot_buttons[selected_slot] as Button
		selected_button.grab_focus()
	else:
		Input.set_mouse_mode(previous_mouse_mode)


func _create_slot_buttons() -> void:
	for slot in SLOT_ORDER:
		var button := Button.new()
		button.text = _get_slot_button_text(slot)
		button.custom_minimum_size = Vector2(230, 34)
		button.focus_mode = Control.FOCUS_ALL
		button.toggle_mode = true
		button.mouse_entered.connect(_select_slot.bind(slot))
		button.focus_entered.connect(_select_slot.bind(slot))
		button.pressed.connect(_select_slot.bind(slot))
		slots_container.add_child(button)
		slot_buttons[slot] = button


func _select_slot(slot: int) -> void:
	selected_slot = slot
	_refresh()


func _refresh() -> void:
	_refresh_slot_buttons()
	_refresh_stats()
	_refresh_item_details()


func _refresh_slot_buttons() -> void:
	for slot in SLOT_ORDER:
		var button := slot_buttons[slot] as Button
		button.text = _get_slot_button_text(slot)
		button.button_pressed = slot == selected_slot


func _refresh_stats() -> void:
	var armor: float = equipment.get_stat_modifier_total(StatModifierDefinitionScript.StatType.ARMOR)
	var move_speed: float = equipment.get_stat_modifier_total(StatModifierDefinitionScript.StatType.MOVE_SPEED)
	var max_health: float = equipment.get_stat_modifier_total(StatModifierDefinitionScript.StatType.MAX_HEALTH)

	stats_label.text = "Attack Damage: %d\nArmor: %s\nMax Health: %s\nMove Speed: %s" % [
		melee_attack.get_attack_damage(),
		_format_number(armor),
		_format_signed_number(max_health),
		_format_signed_number(move_speed),
	]


func _refresh_item_details() -> void:
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
	_show_feedback("Equipped %s" % equipment_definition.display_name)
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
